//! main.rs — Entry point do gst-interp
//!
//! Inicializa GStreamer, registra o elemento InterpElement como plugin,
//! monta o pipeline e roda o main loop.
//!
//! Uso:
//!   gst-interp --file ~/Videos/sample.mkv
//!   gst-interp --file ~/Videos/sample.mkv --fps-target 120 --alpha 0.5
//!   gst-interp --file ~/Videos/sample.mkv --passthrough   (sem interpolação, só valida pipeline)
//!   GST_DEBUG=3 gst-interp --file sample.mkv              (debug GStreamer)

use anyhow::{Context, Result};
use clap::Parser;
use log::{error, info};

mod compute;
mod interp_element;
mod pipeline;
mod vk_context;

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

/// gst-interp — Zero-copy frame interpolation via GStreamer + Vulkan Compute
#[derive(Parser, Debug)]
#[command(
    name = "gst-interp",
    version = env!("CARGO_PKG_VERSION"),
    about = "Interpolação de frames zero-copy: VA-API → VkImage → Compute Shader → vulkansink"
)]
pub struct Cli {
    /// Arquivo de vídeo a reproduzir (H.264/H.265 recomendado para VA-API)
    #[arg(short, long)]
    pub file: String,

    /// FPS alvo de saída (ex: 60, 120). Determina quantos frames interpolados
    /// são inseridos entre cada par de frames originais.
    /// Default: 2× a taxa original do arquivo (ex: 24fps → 48fps)
    #[arg(long, default_value = "0")]
    pub fps_target: u32,

    /// Fator de interpolação para o frame sintético [0.0, 1.0].
    /// 0.5 = exatamente no meio entre N e N+1.
    #[arg(long, default_value = "0.5")]
    pub alpha: f32,

    /// Modo passthrough: desativa interpolação, apenas valida o pipeline zero-copy.
    /// Útil para medir o overhead base do pipeline GStreamer+Vulkan.
    #[arg(long, default_value_t = false)]
    pub passthrough: bool,

    /// Habilita Vulkan validation layers (requer VK_LAYER_KHRONOS_validation instalado).
    /// Útil durante desenvolvimento. NUNCA usar em produção — overhead massivo.
    #[arg(long, default_value_t = false)]
    pub vk_validation: bool,

    /// Desabilita VA-API (decodificação por software). Útil para testar sem GPU decode.
    #[arg(long, default_value_t = false)]
    pub no_vaapi: bool,
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

fn main() -> Result<()> {
    // Inicializa env_logger. Respeita GST_DEBUG para o GStreamer.
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    let cli = Cli::parse();

    info!("gst-interp v{} inicializando...", env!("CARGO_PKG_VERSION"));
    info!("Arquivo: {}", cli.file);
    info!(
        "Modo: {}",
        if cli.passthrough { "passthrough (validação)" } else { "interpolação (mix)" }
    );

    // --- Inicializa GStreamer ---
    gstreamer::init().context("Falha ao inicializar GStreamer")?;
    info!(
        "GStreamer {} inicializado",
        gstreamer::version_string()
    );

    // --- Registra nosso elemento como plugin embutido ---
    // Isso o torna disponível no registry do GStreamer desta sessão.
    interp_element::register_plugin()
        .context("Falha ao registrar o plugin InterpElement")?;
    info!("Plugin 'interpfilter' registrado com sucesso");

    // --- Monta e executa o pipeline ---
    let config = pipeline::PipelineConfig {
        file_path: cli.file.clone(),
        alpha: cli.alpha,
        passthrough: cli.passthrough,
        use_vaapi: !cli.no_vaapi,
    };

    pipeline::run(config).context("Erro durante execução do pipeline")?;

    info!("gst-interp encerrado normalmente.");
    Ok(())
}
