use gstreamer_vulkan::prelude::*;
use anyhow::{Context, Result};
use ash::vk;
use std::ffi::CStr;

// Represents the push constants sent to the shader
#[repr(C)]
#[derive(Clone, Copy)]
pub struct PushConstants {
    pub alpha: f32,
    pub width: u32,
    pub height: u32,
    pub flags: u32,
}

pub struct ComputePipeline {
    gst_device: gstreamer_vulkan::VulkanDevice,
    ash_device: ash::Device,
    descriptor_set_layout: vk::DescriptorSetLayout,
    descriptor_pool: vk::DescriptorPool,
    descriptor_set: vk::DescriptorSet,
    pipeline_layout: vk::PipelineLayout,
    pipeline: vk::Pipeline,
    cmd_pool: vk::CommandPool,
    cmd_buf: vk::CommandBuffer,
    fence: vk::Fence,
    compute_queue: vk::Queue,
    queue_family_index: u32,
    width: u32,
    height: u32,
}

impl ComputePipeline {
    pub fn new(
        gst_device: gstreamer_vulkan::VulkanDevice,
        ash_device: ash::Device,
        compute_queue: vk::Queue,
        queue_family_index: u32,
    ) -> Result<Self> {
        
        let bindings = [
            vk::DescriptorSetLayoutBinding::default()
                .binding(0)
                .descriptor_type(vk::DescriptorType::STORAGE_IMAGE)
                .descriptor_count(1)
                .stage_flags(vk::ShaderStageFlags::COMPUTE),
            vk::DescriptorSetLayoutBinding::default()
                .binding(1)
                .descriptor_type(vk::DescriptorType::STORAGE_IMAGE)
                .descriptor_count(1)
                .stage_flags(vk::ShaderStageFlags::COMPUTE),
            vk::DescriptorSetLayoutBinding::default()
                .binding(2)
                .descriptor_type(vk::DescriptorType::STORAGE_IMAGE)
                .descriptor_count(1)
                .stage_flags(vk::ShaderStageFlags::COMPUTE),
            vk::DescriptorSetLayoutBinding::default()
                .binding(3)
                .descriptor_type(vk::DescriptorType::STORAGE_IMAGE)
                .descriptor_count(1)
                .stage_flags(vk::ShaderStageFlags::COMPUTE),
        ];

        let layout_info = vk::DescriptorSetLayoutCreateInfo::default().bindings(&bindings);
        let descriptor_set_layout = unsafe { ash_device.create_descriptor_set_layout(&layout_info, None) }?;

        let pool_sizes = [vk::DescriptorPoolSize::default()
            .ty(vk::DescriptorType::STORAGE_IMAGE)
            .descriptor_count(4)];
        let pool_info = vk::DescriptorPoolCreateInfo::default()
            .pool_sizes(&pool_sizes)
            .max_sets(1);
        let descriptor_pool = unsafe { ash_device.create_descriptor_pool(&pool_info, None) }?;

        let alloc_info = vk::DescriptorSetAllocateInfo::default()
            .descriptor_pool(descriptor_pool)
            .set_layouts(std::slice::from_ref(&descriptor_set_layout));
        let descriptor_set = unsafe { ash_device.allocate_descriptor_sets(&alloc_info) }?[0];

        let pc_range = vk::PushConstantRange::default()
            .stage_flags(vk::ShaderStageFlags::COMPUTE)
            .offset(0)
            .size(std::mem::size_of::<PushConstants>() as u32);

        let pipeline_layout_info = vk::PipelineLayoutCreateInfo::default()
            .set_layouts(std::slice::from_ref(&descriptor_set_layout))
            .push_constant_ranges(std::slice::from_ref(&pc_range));
        let pipeline_layout = unsafe { ash_device.create_pipeline_layout(&pipeline_layout_info, None) }?;

        let shader_spv = include_bytes!(concat!(env!("OUT_DIR"), "/interpolate.comp.spv"));
        let shader_module = Self::create_shader_module(&ash_device, shader_spv)?;

        let main_name = CStr::from_bytes_with_nul(b"main\0").unwrap();
        let stage_info = vk::PipelineShaderStageCreateInfo::default()
            .stage(vk::ShaderStageFlags::COMPUTE)
            .module(shader_module)
            .name(main_name);

        let pipeline_info = vk::ComputePipelineCreateInfo::default()
            .stage(stage_info)
            .layout(pipeline_layout);
        let pipeline = unsafe {
            ash_device.create_compute_pipelines(vk::PipelineCache::null(), &[pipeline_info], None)
        }.map_err(|e| anyhow::anyhow!("Compute pipeline error: {:?}", e))?[0];

        unsafe { ash_device.destroy_shader_module(shader_module, None) };

        let cmd_pool_info = vk::CommandPoolCreateInfo::default()
            .queue_family_index(queue_family_index)
            .flags(vk::CommandPoolCreateFlags::RESET_COMMAND_BUFFER);
        let cmd_pool = unsafe { ash_device.create_command_pool(&cmd_pool_info, None) }?;

        let cmd_buf_info = vk::CommandBufferAllocateInfo::default()
            .command_pool(cmd_pool)
            .level(vk::CommandBufferLevel::PRIMARY)
            .command_buffer_count(1);
        let cmd_buf = unsafe { ash_device.allocate_command_buffers(&cmd_buf_info) }?[0];

        let fence_info = vk::FenceCreateInfo::default().flags(vk::FenceCreateFlags::SIGNALED);
        let fence = unsafe { ash_device.create_fence(&fence_info, None) }?;

        Ok(Self {
            gst_device,
            ash_device,
            descriptor_set_layout,
            descriptor_pool,
            descriptor_set,
            pipeline_layout,
            pipeline,
            cmd_pool,
            cmd_buf,
            fence,
            compute_queue,
            queue_family_index,
            width: 1920,
            height: 1080,
        })
    }

    fn create_shader_module(device: &ash::Device, spv: &[u8]) -> Result<vk::ShaderModule> {
        let mut spv_u32 = vec![0u32; spv.len() / 4];
        unsafe {
            std::ptr::copy_nonoverlapping(
                spv.as_ptr(),
                spv_u32.as_mut_ptr() as *mut u8,
                spv.len(),
            );
        }
        let create_info = vk::ShaderModuleCreateInfo::default().code(&spv_u32);
        unsafe { device.create_shader_module(&create_info, None) }.map_err(Into::into)
    }

    pub fn set_dimensions(&mut self, width: u32, height: u32) {
        self.width = width;
        self.height = height;
    }

    pub fn create_view(&self, image: vk::Image) -> Result<vk::ImageView> {
        let ash_device = &self.ash_device;
        let create_info = vk::ImageViewCreateInfo::default()
            .image(image)
            .view_type(vk::ImageViewType::TYPE_2D)
            .format(vk::Format::R8G8B8A8_UNORM)
            .components(vk::ComponentMapping::default())
            .subresource_range(vk::ImageSubresourceRange::default()
                .aspect_mask(vk::ImageAspectFlags::COLOR)
                .base_mip_level(0)
                .level_count(1)
                .base_array_layer(0)
                .layer_count(1));
        unsafe { ash_device.create_image_view(&create_info, None) }.map_err(Into::into)
    }

    pub fn destroy_view(&self, view: vk::ImageView) {
        let ash_device = &self.ash_device;
        unsafe { ash_device.destroy_image_view(view, None) };
    }

    pub fn dispatch(
        &self,
        view_nm1: vk::ImageView,
        view_n: vk::ImageView,
        view_np1: vk::ImageView,
        view_out: vk::ImageView,
        alpha: f32,
        flags: u32,
    ) -> Result<()> {
        let ash_device = &self.ash_device;

        unsafe {
            ash_device.wait_for_fences(&[self.fence], true, u64::MAX)?;
            ash_device.reset_fences(&[self.fence])?;
        }

        let views = [view_nm1, view_n, view_np1, view_out];
        let image_infos: Vec<vk::DescriptorImageInfo> = views.iter().map(|&view| {
            vk::DescriptorImageInfo::default()
                .image_view(view)
                .image_layout(vk::ImageLayout::GENERAL)
        }).collect();

        let writes: Vec<vk::WriteDescriptorSet> = image_infos.iter().enumerate().map(|(i, info)| {
            vk::WriteDescriptorSet::default()
                .dst_set(self.descriptor_set)
                .dst_binding(i as u32)
                .descriptor_type(vk::DescriptorType::STORAGE_IMAGE)
                .image_info(std::slice::from_ref(info))
        }).collect();

        unsafe { ash_device.update_descriptor_sets(&writes, &[]) };

        let begin_info = vk::CommandBufferBeginInfo::default()
            .flags(vk::CommandBufferUsageFlags::ONE_TIME_SUBMIT);
        
        unsafe {
            ash_device.begin_command_buffer(self.cmd_buf, &begin_info)?;
            ash_device.cmd_bind_pipeline(self.cmd_buf, vk::PipelineBindPoint::COMPUTE, self.pipeline);
            ash_device.cmd_bind_descriptor_sets(
                self.cmd_buf,
                vk::PipelineBindPoint::COMPUTE,
                self.pipeline_layout,
                0,
                &[self.descriptor_set],
                &[],
            );

            let pc = PushConstants { alpha, width: self.width, height: self.height, flags };
            let pc_bytes = unsafe {
                std::slice::from_raw_parts(
                    &pc as *const _ as *const u8,
                    std::mem::size_of::<PushConstants>(),
                )
            };

            unsafe {
                ash_device.cmd_push_constants(
                    self.cmd_buf,
                    self.pipeline_layout,
                    vk::ShaderStageFlags::COMPUTE,
                    0,
                    pc_bytes,
                );

                let groups_x = (self.width + 7) / 8;
                let groups_y = (self.height + 7) / 8;
                ash_device.cmd_dispatch(self.cmd_buf, groups_x, groups_y, 1);
            }
            ash_device.end_command_buffer(self.cmd_buf)?;
        }

        let submit_info = vk::SubmitInfo::default().command_buffers(std::slice::from_ref(&self.cmd_buf));
        
        unsafe {
            let gst_queue = self.gst_device.queue(self.queue_family_index, 0);
            let _guard = gst_queue.submit_lock();
            self.ash_device.queue_submit(self.compute_queue, &[submit_info], self.fence)?;
        }

        Ok(())
    }
}
