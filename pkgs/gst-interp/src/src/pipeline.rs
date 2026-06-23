//! pipeline.rs — Monta e gerencia o pipeline GStreamer
//!
//! Pipeline Phase 1 (testes — vulkansink):
//!
//!   filesrc → parsebin → [vah264dec | avdec_h264] → videoconvert
//!           → vulkanupload → vulkancolorconvert → interpfilter → vulkansink
//!
//!   ┌─────────┐   ┌─────────┐   ┌───────────┐   ┌──────────────┐
//!   │ filesrc │──▶│parsebin │──▶│ vah264dec │──▶│videoconvert  │
//!   └─────────┘   └─────────┘   └───────────┘   └──────┬───────┘
//!                                                        │ NV12 / I420
//!                                               ┌────────▼───────┐
//!                                               │  vulkanupload  │  ← DMA-BUF → VkImage
//!                                               └────────┬───────┘
//!                                                        │ VkImage (NV12)
//!                                               ┌────────▼────────────┐
//!                                               │vulkancolorconvert   │  ← NV12 → RGBA8 (GPU)
//!                                               └────────┬────────────┘
//!                                                        │ VkImage (RGBA8)
//!                                               ┌────────▼───────┐
//!                                               │ interpfilter   │  ← nosso elemento
//!                                               └────────┬───────┘
//!                                                        │ VkImage (RGBA8, interpolado)
//!                                               ┌────────▼───────┐
//!                                               │  vulkansink    │  ← exibe via Wayland
//!                                               └────────────────┘
//!
//! Pipeline Phase 2 (produção — DMA-BUF export para mpv):
//!   Substituir vulkansink por exportação de DMA-BUF de volta ao mpv (vo=gpu-next).
//!   TODO: implementar após validação da fase 1.

use anyhow::{bail, Context, Result};
use gstreamer::prelude::*;
use log::{error, info, warn};

/// Configuração do pipeline passada pelo main.
pub struct PipelineConfig {
    pub file_path: String,
    /// Fator de interpolação [0.0, 1.0] — passado como property para o elemento.
    pub alpha: f32,
    /// Se true, o InterpElement opera em passthrough (sem interpolação real).
    pub passthrough: bool,
    /// Se true, usa VA-API para decodificação hardware. False = software (avdec_*).
    pub use_vaapi: bool,
}

/// Monta o pipeline, bloqueia no main loop e retorna ao fim do vídeo.
pub fn run(config: PipelineConfig) -> Result<()> {
    // --- Constrói o pipeline usando playbin3 para ter áudio e suporte a resize ---
    let pipeline = gstreamer::ElementFactory::make("playbin3")
        .build()
        .context("Falha ao criar playbin3")?;

    let pipeline = pipeline
        .downcast::<gstreamer::Pipeline>()
        .map_err(|_| anyhow::anyhow!("playbin3 não é um Pipeline"))?;

    let abs_path = std::fs::canonicalize(&config.file_path)
        .with_context(|| format!("Arquivo não encontrado: {}", config.file_path))?;
    pipeline.set_property("uri", format!("file://{}", abs_path.display()));

    // Cria o bin customizado para a parte Vulkan
    let filter_bin = gstreamer::Bin::with_name("vulkan_sink_bin");
    
    let upload = gstreamer::ElementFactory::make("vulkanupload").build()?;
    let color = gstreamer::ElementFactory::make("vulkancolorconvert").build()?;
    
    // Força RGBA antes do nosso filtro
    let capsfilter = gstreamer::ElementFactory::make("capsfilter").build()?;
    let caps = gstreamer::Caps::builder("video/x-raw")
        .features(["memory:VulkanImage"])
        .field("format", "RGBA")
        .build();
    capsfilter.set_property("caps", &caps);
    
    let filter = gstreamer::ElementFactory::make("interpfilter").name("interp").build()?;
    let color2 = gstreamer::ElementFactory::make("vulkancolorconvert").build()?;
    
    filter.set_property("alpha", config.alpha);
    filter.set_property("passthrough", config.passthrough);
    
    // Zero-copy topology: end directly in vulkansink
    let vulkansink = gstreamer::ElementFactory::make("vulkansink").build()?;
    // Disable QoS to prevent the sink from dropping our interpolated 48fps frames 
    // since the negotiated caps are still 24fps.
    vulkansink.set_property("qos", false);
    
    // Adicionamos fpsdisplaysink para overlay de FPS e drops
    let fps_sink = gstreamer::ElementFactory::make("fpsdisplaysink").build()?;
    fps_sink.set_property("video-sink", &vulkansink);
    fps_sink.set_property("text-overlay", true);
    fps_sink.set_property("signal-fps-measurements", true);
    
    filter_bin.add_many([&upload, &color, &capsfilter, &filter, &color2, &fps_sink])?;
    gstreamer::Element::link_many([&upload, &color, &capsfilter, &filter, &color2, &fps_sink])?;

    // Adiciona o GhostPad
    let pad = upload.static_pad("sink").unwrap();
    filter_bin.add_pad(&gstreamer::GhostPad::with_target(&pad).unwrap())?;

    pipeline.set_property("video-sink", &filter_bin);

    // --- State: NULL → PLAYING ---
    pipeline
        .set_state(gstreamer::State::Playing)
        .context("Falha ao colocar o pipeline em estado PLAYING")?;

    info!("Pipeline em PLAYING. Reproduzindo via playbin3: {}", abs_path.display());

    // Tentar mover o overlay para o topo (o fpsdisplaysink cria o textoverlay dinamicamente)
    if let Ok(bin) = fps_sink.clone().downcast::<gstreamer::Bin>() {
        // Para os que já foram criados
        for child in bin.children() {
            if child.name().contains("text") || child.name().contains("overlay") {
                child.set_property_from_str("valignment", "top");
                child.set_property_from_str("halignment", "left");
            }
        }
        // Para os que forem criados depois
        bin.connect_deep_element_added(|_, _, child| {
            if child.name().contains("text") || child.name().contains("overlay") {
                child.set_property_from_str("valignment", "top");
                child.set_property_from_str("halignment", "left");
            }
        });
    }

    // --- Captura de teclado via Wayland Navigation Events ---
    let sink_pad = fps_sink.static_pad("sink").unwrap();
    let fps_sink_clone = fps_sink.clone();
    sink_pad.add_probe(gstreamer::PadProbeType::EVENT_UPSTREAM, move |_, info| {
        if let Some(gstreamer::PadProbeData::Event(ev)) = &info.data {
            if ev.type_() == gstreamer::EventType::Navigation {
                if let Some(s) = ev.structure() {
                    if s.name() == "application/x-gst-navigation" {
                        if let Ok(event_type) = s.get::<&str>("event") {
                            if event_type == "key-press" {
                                if let Ok(key) = s.get::<&str>("key") {
                                    if key == "i" || key == "I" {
                                        let current: bool = fps_sink_clone.property("text-overlay");
                                        fps_sink_clone.set_property("text-overlay", !current);
                                        log::info!("Overlay alternado para: {}", !current);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        gstreamer::PadProbeReturn::Ok
    });

    info!(">>> ATENÇÃO: Pressione a tecla 'i' na janela do vídeo para alternar o overlay de status <<<");

    // --- Main Loop: bloqueia e processa mensagens do bus ---
    let bus = pipeline.bus().expect("Pipeline sem bus");
    run_main_loop(&bus, &pipeline)?;

    // --- Cleanup ---
    pipeline
        .set_state(gstreamer::State::Null)
        .context("Falha ao voltar para NULL")?;

    Ok(())
}

/// Processa mensagens do bus até EOS ou Error.
fn run_main_loop(
    bus: &gstreamer::Bus,
    pipeline: &gstreamer::Pipeline,
) -> Result<()> {
    for msg in bus.iter_timed(gstreamer::ClockTime::NONE) {
        use gstreamer::MessageView;

        match msg.view() {
            MessageView::Eos(_) => {
                info!("EOS recebido — fim do arquivo.");
                break;
            }

            MessageView::Error(err) => {
                let src_name = msg
                    .src()
                    .map(|s| s.name().to_string())
                    .unwrap_or_else(|| "?".to_string());

                error!(
                    "Erro no pipeline (src={}): {}\nDebug: {}",
                    src_name,
                    err.error(),
                    err.debug().unwrap_or_default()
                );

                bail!(
                    "Erro GStreamer em '{}': {}",
                    src_name,
                    err.error()
                );
            }

            MessageView::Warning(warn_msg) => {
                warn!(
                    "Warning: {}",
                    warn_msg.error()
                );
            }

            MessageView::StateChanged(sc) => {
                if msg.src().as_ref().map(|o| o.as_ptr()) == Some(pipeline.upcast_ref::<gstreamer::Object>().as_ptr()) {
                    info!(
                        "Pipeline: {:?} → {:?}",
                        sc.old(),
                        sc.current()
                    );
                }
            }

            _ => {}
        }
    }

    Ok(())
}
