use gstreamer as gst;
use gst::glib;
use std::sync::Mutex;

use ash::vk;
use gst::glib::subclass::prelude::*;
use gst::subclass::prelude::*;
use gstreamer_base as gst_base;
use gst_base::subclass::prelude::*;
use gst_base::subclass::BaseTransformMode;
use gstreamer_vulkan::prelude::*;
use log::{error, info, debug};
use anyhow::Result;

use crate::compute::ComputePipeline;
use crate::vk_context::VkContext;

#[derive(Clone)]
pub struct InterpSettings {
    pub alpha: f32,
    pub passthrough: bool,
}

impl Default for InterpSettings {
    fn default() -> Self {
        Self {
            alpha: 0.5,
            passthrough: false,
        }
    }
}

#[derive(Default)]
struct State {
    vk_ctx: Option<VkContext>,
    vk_device: Option<gstreamer_vulkan::VulkanDevice>,
    compute: Option<ComputePipeline>,
    prev_buf: Option<gst::Buffer>,
    interp_pool: Option<gst::BufferPool>,
    pending_interp: Option<gst::Buffer>,
}

#[derive(Default)]
pub struct InterpElement {
    settings: Mutex<InterpSettings>,
    state: Mutex<State>,
}

#[glib::object_subclass]
impl ObjectSubclass for InterpElement {
    const NAME: &'static str = "InterpElement";
    type Type = super::InterpElement;
    type ParentType = gst_base::BaseTransform;
}

impl ObjectImpl for InterpElement {
    fn properties() -> &'static [glib::ParamSpec] {
        static PROPERTIES: std::sync::OnceLock<Vec<glib::ParamSpec>> =
            std::sync::OnceLock::new();

        PROPERTIES.get_or_init(|| {
            vec![
                glib::ParamSpecFloat::builder("alpha")
                    .nick("Alpha")
                    .blurb("Fator de interpolação (0.0 = N-1, 1.0 = N)")
                    .minimum(0.0)
                    .maximum(1.0)
                    .default_value(0.5)
                    .mutable_ready()
                    .mutable_playing()
                    .build(),
                glib::ParamSpecBoolean::builder("passthrough")
                    .nick("Passthrough")
                    .blurb("Se true, apenas copia os frames sem interpolar")
                    .default_value(false)
                    .mutable_ready()
                    .mutable_playing()
                    .build(),
            ]
        })
    }

    fn set_property(&self, id: usize, value: &glib::Value, _pspec: &glib::ParamSpec) {
        let mut settings = self.settings.lock().unwrap();
        match id {
            1 => settings.alpha = value.get().unwrap(),
            2 => settings.passthrough = value.get().unwrap(),
            _ => unimplemented!(),
        }
    }

    fn property(&self, id: usize, _pspec: &glib::ParamSpec) -> glib::Value {
        let settings = self.settings.lock().unwrap();
        match id {
            1 => settings.alpha.to_value(),
            2 => settings.passthrough.to_value(),
            _ => unimplemented!(),
        }
    }
}

impl GstObjectImpl for InterpElement {}

impl ElementImpl for InterpElement {
    fn metadata() -> Option<&'static gst::subclass::ElementMetadata> {
        static ELEMENT_METADATA: std::sync::OnceLock<gst::subclass::ElementMetadata> =
            std::sync::OnceLock::new();

        Some(ELEMENT_METADATA.get_or_init(|| {
            gst::subclass::ElementMetadata::new(
                "Vulkan Frame Interpolator (1-in/2-out)",
                "Filter/Effect/Video",
                "Interpola frames de video dobrando o framerate usando RDNA4 Vulkan",
                "Alice",
            )
        }))
    }

    fn pad_templates() -> &'static [gst::PadTemplate] {
        static PAD_TEMPLATES: std::sync::OnceLock<Vec<gst::PadTemplate>> =
            std::sync::OnceLock::new();

        PAD_TEMPLATES.get_or_init(|| {
            let caps = gst::Caps::builder("video/x-raw")
                .features(["memory:VulkanImage"])
                .field("format", "RGBA")
                .build();

            vec![
                gst::PadTemplate::new(
                    "sink",
                    gst::PadDirection::Sink,
                    gst::PadPresence::Always,
                    &caps,
                )
                .unwrap(),
                gst::PadTemplate::new(
                    "src",
                    gst::PadDirection::Src,
                    gst::PadPresence::Always,
                    &caps,
                )
                .unwrap(),
            ]
        })
    }

    fn set_context(&self, context: &gst::Context) {
        if context.has_context_type("gst.vulkan.device") {
            let mut state = self.state.lock().unwrap();
            let device = context.structure().get::<gstreamer_vulkan::VulkanDevice>("device").ok();
            if let Some(dev) = device {
                state.vk_device = Some(dev);
            }
        }
        self.parent_set_context(context);
    }
}

impl BaseTransformImpl for InterpElement {
    const MODE: BaseTransformMode = BaseTransformMode::NeverInPlace;
    const PASSTHROUGH_ON_SAME_CAPS: bool = false;
    const TRANSFORM_IP_ON_PASSTHROUGH: bool = false;

    fn transform_caps(
        &self,
        direction: gst::PadDirection,
        caps: &gst::Caps,
        filter: Option<&gst::Caps>,
    ) -> Option<gst::Caps> {
        let mut out_caps = gst::Caps::new_empty();
        
        for s in caps.iter() {
            let mut s_new = s.to_owned();
            if let Ok(fps) = s_new.get::<gst::Fraction>("framerate") {
                if direction == gst::PadDirection::Sink {
                    s_new.set("framerate", gst::Fraction::new(fps.numer() * 2, fps.denom()));
                } else {
                    s_new.set("framerate", gst::Fraction::new(fps.numer() / 2, fps.denom()));
                }
            }
            out_caps.get_mut().unwrap().append_structure(s_new);
        }

        if let Some(filter) = filter {
            Some(out_caps.intersect(filter))
        } else {
            Some(out_caps)
        }
    }

    fn decide_allocation(
        &self,
        query: &mut gst::query::Allocation,
    ) -> Result<(), gst::LoggableError> {
        let _ = self.parent_decide_allocation(query);
        let caps = query.caps().expect("Allocation query sem caps");
        let caps_owned = caps.to_owned();

        let mut has_vulkan_pool = false;
        for (pool, _, _, _) in query.allocation_pools() {
            if let Some(p) = pool {
                if p.type_() == gstreamer_vulkan::VulkanImageBufferPool::static_type() {
                    has_vulkan_pool = true;
                    break;
                }
            }
        }

        let mut state = self.state.lock().unwrap();

        if !has_vulkan_pool {
            if let Some(vk_device) = &state.vk_device {
                let pool = gstreamer_vulkan::VulkanImageBufferPool::new(vk_device);
                let mut config = pool.config();
                config.set_params(Some(&caps_owned), 0, 2, 0); 
                pool.set_config(config).map_err(|_| gst::loggable_error!(gst::CAT_DEFAULT, "Falha pool"))?;
                query.add_allocation_pool(Some(&pool), 0, 2, 0);
            } else {
                error!("has_vulkan_pool=false e vk_device nao disponivel em decide_allocation!");
            }
        }
        
        for (pool, _, _, _) in query.allocation_pools() {
            if let Some(pool) = pool {
                if pool.type_() == gstreamer_vulkan::VulkanImageBufferPool::static_type() {
                    if !pool.is_active() {
                        let _ = pool.set_active(true);
                    }
                    state.interp_pool = Some(pool);
                    break;
                }
            }
        }

        Ok(())
    }

    fn transform(
        &self,
        inbuf: &gst::Buffer,
        outbuf: &mut gst::BufferRef,
    ) -> Result<gst::FlowSuccess, gst::FlowError> {
        let mut state = self.state.lock().unwrap();
        
        if state.vk_ctx.is_none() {
            let (_, gst_device) = extract_vulkan_image(inbuf)?;
            let vk_ctx = VkContext::new(&gst_device).map_err(|e| {
                error!("Falha VkContext: {:?}", e);
                gst::FlowError::Error
            })?;
            
            let compute = ComputePipeline::new(
                gst_device.clone(),
                vk_ctx.ash_device.clone(),
                vk_ctx.compute_queue,
                vk_ctx.compute_queue_family,
            ).map_err(|e| {
                error!("Falha ComputePipeline: {:?}", e);
                gst::FlowError::Error
            })?;
            
            state.vk_ctx = Some(vk_ctx);
            state.compute = Some(compute);
        }
        
        let settings = self.settings.lock().unwrap().clone();
        
        let (vk_image_in, _) = extract_vulkan_image(inbuf)?;
        let (vk_image_out, _) = extract_vulkan_image_mut(outbuf)?;
        
        let duration = inbuf.duration().expect("Frame sem duração");
        let pts = inbuf.pts().expect("Frame sem PTS");
        let half_duration = duration / 2;
        
        let prev_buf_opt = state.prev_buf.clone();
        
        let view_n = {
            let compute = state.compute.as_mut().unwrap();
            compute.create_view(vk_image_in).map_err(|_| gst::FlowError::Error)?
        };
        let view_out = {
            let compute = state.compute.as_mut().unwrap();
            compute.create_view(vk_image_out).map_err(|_| gst::FlowError::Error)?
        };
        
        if let Some(prev) = &prev_buf_opt {
            if settings.passthrough {
                let compute = state.compute.as_mut().unwrap();
                compute.dispatch(view_n, view_n, view_n, view_out, 0.0, 1)
                    .map_err(|_| gst::FlowError::Error)?;
            } else {
                let (vk_image_prev, _) = extract_vulkan_image(prev)?;
                let compute = state.compute.as_mut().unwrap();
                let view_nm1 = compute.create_view(vk_image_prev).map_err(|_| gst::FlowError::Error)?;
                
                compute.dispatch(view_nm1, view_nm1, view_n, view_out, settings.alpha, 0)
                    .map_err(|e| {
                        error!("Shader error: {:?}", e);
                        gst::FlowError::Error
                    })?;
                    
                compute.destroy_view(view_nm1);
            }
            
            outbuf.set_pts(pts);
            outbuf.set_duration(half_duration);
            
            let mut original_buf = inbuf.copy();
            {
                let original_mut = original_buf.make_mut();
                original_mut.set_pts(pts + half_duration);
                original_mut.set_duration(half_duration);
            }
            state.pending_interp = Some(original_buf);
            
        } else {
            let compute = state.compute.as_mut().unwrap();
            compute.dispatch(view_n, view_n, view_n, view_out, 0.0, 1)
                .map_err(|_| gst::FlowError::Error)?;
                
            outbuf.set_pts(pts);
            outbuf.set_duration(duration);
            state.pending_interp = None;
        }
        
        {
            let compute = state.compute.as_mut().unwrap();
            compute.destroy_view(view_n);
            compute.destroy_view(view_out);
        }
        
        state.prev_buf = Some(inbuf.clone());
        
        Ok(gst::FlowSuccess::Ok)
    }

    fn generate_output(&self) -> Result<gst_base::subclass::base_transform::GenerateOutputSuccess, gst::FlowError> {
        let res = self.parent_generate_output()?;
        
        if let gst_base::subclass::base_transform::GenerateOutputSuccess::Buffer(interp_buf) = res {
            let obj = self.obj();
            let pad = obj.src_pad();
            let mut state = self.state.lock().unwrap();
            
            if let Some(original_buf) = state.pending_interp.take() {
                drop(state);
                
                if let Err(e) = pad.push(interp_buf) {
                    error!("Erro ao fazer push do frame interpolado: {:?}", e);
                    return Err(gst::FlowError::Error);
                }
                
                return Ok(gst_base::subclass::base_transform::GenerateOutputSuccess::Buffer(original_buf));
            } else {
                return Ok(gst_base::subclass::base_transform::GenerateOutputSuccess::Buffer(interp_buf));
            }
        }
        Ok(res)
    }
}

// Helpers para extrair o ash::vk::Image do GstBuffer
fn extract_vulkan_image(buf: &gst::Buffer) -> Result<(ash::vk::Image, gstreamer_vulkan::VulkanDevice), gst::FlowError> {
    extract_vulkan_image_internal(buf.as_ref())
}

fn extract_vulkan_image_mut(buf: &gst::BufferRef) -> Result<(ash::vk::Image, gstreamer_vulkan::VulkanDevice), gst::FlowError> {
    extract_vulkan_image_internal(buf)
}

fn extract_vulkan_image_internal(buf: &gst::BufferRef) -> Result<(ash::vk::Image, gstreamer_vulkan::VulkanDevice), gst::FlowError> {
    let mem = buf.peek_memory(0);

    unsafe {
        let mem_ptr = mem.as_ptr() as *mut gst::ffi::GstMemory;
        
        if gstreamer_vulkan::ffi::gst_is_vulkan_image_memory(mem_ptr) == glib::ffi::GFALSE {
            let allocator = (*mem_ptr).allocator;
            let allocator_name = if !allocator.is_null() {
                let name_ptr = (*allocator).mem_type;
                if !name_ptr.is_null() {
                    std::ffi::CStr::from_ptr(name_ptr).to_string_lossy().into_owned()
                } else {
                    "unknown".to_string()
                }
            } else {
                "none".to_string()
            };
            error!("Buffer não contém VulkanImageMemory. Allocator usado: {}", allocator_name);
            return Err(gst::FlowError::Error);
        }
        
        #[repr(C)]
        struct CustomGstVulkanImageMemory {
            parent: gst::ffi::GstMemory,
            device: *mut gstreamer_vulkan::ffi::GstVulkanDevice,
            image: ash::vk::Image,
        }

        let vk_mem = mem_ptr as *const CustomGstVulkanImageMemory;
        let gst_device = glib::translate::FromGlibPtrNone::from_glib_none((*vk_mem).device);
        Ok(((*vk_mem).image, gst_device))
    }
}
