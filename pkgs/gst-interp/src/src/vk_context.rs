use gstreamer as gst;
use gst::glib;
use anyhow::{Context, Result};
use ash::vk;
use gstreamer_vulkan::prelude::*;
use gst::glib::prelude::*;
use gst::prelude::*;

pub struct VkContext {
    pub gst_device: gstreamer_vulkan::VulkanDevice,
    pub ash_instance: ash::Instance,
    pub ash_device: ash::Device,
    pub compute_queue: vk::Queue,
    pub compute_queue_family: u32,
}

#[repr(C)]
struct CustomGstVulkanInstance {
    parent: gst::ffi::GstObject,
    instance: ash::vk::Instance,
}

#[repr(C)]
struct CustomGstVulkanPhysicalDevice {
    parent: gst::ffi::GstObject,
    instance: *mut CustomGstVulkanInstance,
    device_index: u32,
    device: ash::vk::PhysicalDevice,
}

#[repr(C)]
struct CustomGstVulkanDevice {
    parent: gst::ffi::GstObject,
    instance: *mut CustomGstVulkanInstance,
    physical_device: *mut CustomGstVulkanPhysicalDevice,
    device: ash::vk::Device,
}

impl VkContext {
    pub fn new(gst_device: &gstreamer_vulkan::VulkanDevice) -> Result<Self> {
        let (ash_instance, ash_device, pdev_handle) = unsafe {
            let vk_dev_ptr = gst_device.as_ptr() as *const CustomGstVulkanDevice;
            
            let inst_ptr = (*vk_dev_ptr).instance;
            let pdev_ptr = (*vk_dev_ptr).physical_device;
            
            let device_handle = (*vk_dev_ptr).device;
            let pdev_handle = (*pdev_ptr).device;
            let inst_handle = (*inst_ptr).instance;

            let entry = ash::Entry::load().context("Falha ao carregar vulkan library")?;
            let ash_instance = ash::Instance::load(entry.static_fn(), inst_handle);
            let ash_device = ash::Device::load(ash_instance.fp_v1_0(), device_handle);
            
            (ash_instance, ash_device, pdev_handle)
        };

        // Find a queue family that supports COMPUTE
        let queue_family_props = unsafe {
            ash_instance.get_physical_device_queue_family_properties(pdev_handle)
        };

        let compute_queue_family = queue_family_props
            .iter()
            .enumerate()
            .find_map(|(index, info)| {
                if info.queue_flags.contains(vk::QueueFlags::COMPUTE) {
                    Some(index as u32)
                } else {
                    None
                }
            })
            .context("Não foi possível encontrar uma Queue Family com suporte a COMPUTE")?;

        let compute_queue = unsafe {
            ash_device.get_device_queue(compute_queue_family, 0)
        };

        Ok(Self {
            gst_device: gst_device.clone(),
            ash_instance,
            ash_device,
            compute_queue,
            compute_queue_family,
        })
    }
}
