//! interp_element/mod.rs — API pública do elemento GStreamer customizado
//!
//! Registra o elemento "interpfilter" no registry do GStreamer.
//! O pipeline referencia este elemento pelo nome: `interpfilter name=interp`.

use anyhow::Result;
use gstreamer as gst;
use gstreamer_base as gst_base;
use gst::glib;
use gst::glib::prelude::*;
use gst::prelude::*;

pub mod imp;

// ---------------------------------------------------------------------------
// glib::wrapper! — gera o tipo GObject que encapsula nossa implementação
// ---------------------------------------------------------------------------
glib::wrapper! {
    /// InterpElement: GstBaseTransform customizado que:
    /// 1. Recebe GstBuffer com GstVulkanImageMemory (frame decodificado como VkImage)
    /// 2. Empurra o frame para o PingPongBuffer circular na VRAM
    /// 3. Quando tem N e N+1, despacha o Compute Shader de interpolação
    /// 4. Emite o frame interpolado como novo GstBuffer para o sink
    pub struct InterpElement(ObjectSubclass<imp::InterpElement>)
        @extends gst_base::BaseTransform,
                 gst::Element,
                 gst::Object;
}

// SAFETY: InterpElement é thread-safe (state interno protegido por Mutex).
unsafe impl Send for InterpElement {}
unsafe impl Sync for InterpElement {}

// ---------------------------------------------------------------------------
// Plugin registration
// ---------------------------------------------------------------------------

use gstreamer::prelude::*;

gstreamer::plugin_define!(
    gst_interp,
    env!("CARGO_PKG_DESCRIPTION"),
    plugin_init,
    env!("CARGO_PKG_VERSION"),
    "MIT/X11",
    env!("CARGO_PKG_NAME"),
    env!("CARGO_PKG_NAME"),
    env!("CARGO_PKG_REPOSITORY"),
    "2026-06-21"
);

/// Registra o InterpElement como plugin embutido no GStreamer registry.
///
/// Chamado uma vez em main() antes de montar o pipeline.
pub fn register_plugin() -> Result<()> {
    plugin_register_static().expect("Falha ao registrar plugin estático gst_interp");
    Ok(())
}

/// Inicializa o plugin: registra todos os tipos de elemento.
fn plugin_init(plugin: &gstreamer::Plugin) -> Result<(), glib::BoolError> {
    // Registra o elemento com o nome de factory "interpfilter"
    gstreamer::Element::register(
        Some(plugin),
        "interpfilter",
        gstreamer::Rank::NONE,
        InterpElement::static_type(),
    )?;
    Ok(())
}
