using System;
using System.Diagnostics;

using Bulkan;
using static Bulkan.VulkanNative;

// Ported from https://github.com/ocornut/imgui - commit 5854da10e664312e51acec618267d06b1294ac0b

// dear imgui: Renderer Backend for Vulkan
// This needs to be used along with a Platform Backend (e.g. GLFW, SDL, Win32, custom..)

// Implemented features:
//  [X] Renderer: Support for large meshes (64k+ vertices) with 16-bit indices.
//  [!] Renderer: User texture binding. Use 'VkDescriptorSet' as ImTextureID. Read the FAQ about ImTextureID! See https://github.com/ocornut/imgui/pull/914 for discussions.

// Important: on 32-bit systems, user texture binding is only supported if your imconfig file has '#define ImTextureID ImU64'.
// See imgui_impl_vulkan.cpp file for details.

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// If you are new to Dear ImGui, read documentation from the docs/ folder + read the top of imgui.cpp.
// Read online: https://github.com/ocornut/imgui/tree/master/docs

// The aim of imgui_impl_vulkan.h/.cpp is to be usable in your engine without any modification.
// IF YOU FEEL YOU NEED TO MAKE ANY CHANGE TO THIS CODE, please share them and your feedback at https://github.com/ocornut/imgui/

// Important note to the reader who wish to integrate imgui_impl_vulkan.cpp/.h in their own engine/app.
// - Common ImGui_ImplVulkan_XXX functions and structures are used to interface with imgui_impl_vulkan.cpp/.h.
//   You will use those if you want to use this rendering backend in your engine/app.
// - Helper ImGui_ImplVulkanH_XXX functions and structures are only used by this example (main.cpp) and by
//   the backend itself (imgui_impl_vulkan.cpp), but should PROBABLY NOT be used by your own engine/app code.
// Read comments in imgui_impl_vulkan.h.

namespace ImGui {
	static class ImGuiImplVulkan {
		public typealias InitInfo = ImGui_ImplVulkan_InitInfo;
		public typealias Window = ImGui_ImplVulkanH_Window;
		public typealias Frame = ImGui_ImplVulkanH_Frame;
		public typealias FrameSemaphores = ImGui_ImplVulkanH_FrameSemaphores;

		// Initialization data, for ImGui_ImplVulkan_Init()
		// [Please zero-clear before use!]
		struct ImGui_ImplVulkan_InitInfo
		{
		    public VkInstance                      Instance;
		    public VkPhysicalDevice                PhysicalDevice;
		    public VkDevice                        Device;
		    public uint32                          QueueFamily;
		    public VkQueue                         Queue;
		    public VkPipelineCache                 PipelineCache;
		    public VkDescriptorPool                DescriptorPool;
		    public uint32                          Subpass;
		    public uint32                          MinImageCount;          // >= 2
		    public uint32                          ImageCount;             // >= MinImageCount
		    public VkSampleCountFlags              MSAASamples;            // >= VK_SAMPLE_COUNT_1_BIT (0 -> default to VK_SAMPLE_COUNT_1_BIT)
		    public VkAllocationCallbacks*          Allocator;
			public function void(VkResult err)     CheckVkResultFn;
		};
		
		// Called by user code
		public static bool         Init(InitInfo* info, VkRenderPass render_pass) => ImGui_ImplVulkan_Init(info, render_pass);
		public static void         Shutdown() => ImGui_ImplVulkan_Shutdown();
		public static void         NewFrame() => ImGui_ImplVulkan_NewFrame();
		public static void         RenderDrawData(ImGui.DrawData* draw_data, VkCommandBuffer command_buffer, VkPipeline pipeline = .Null) => ImGui_ImplVulkan_RenderDrawData(draw_data, command_buffer, pipeline);
		public static bool         CreateFontsTexture(VkCommandBuffer command_buffer) => ImGui_ImplVulkan_CreateFontsTexture(command_buffer);
		public static void         DestroyFontUploadObjects() => ImGui_ImplVulkan_DestroyFontUploadObjects();
		public static void         SetMinImageCount(uint32 min_image_count) => ImGui_ImplVulkan_SetMinImageCount(min_image_count); // To override MinImageCount after initialization (e.g. if swap chain is recreated)

		// Register a texture (VkDescriptorSet == ImTextureID)
		// FIXME: This is experimental in the sense that we are unsure how to best design/tackle this problem, please post to https://github.com/ocornut/imgui/pull/914 if you have suggestions.
		public static VkDescriptorSet AddTexture(VkSampler sampler, VkImageView image_view, VkImageLayout image_layout) => ImGui_ImplVulkan_AddTexture(sampler, image_view, image_layout);

		//-------------------------------------------------------------------------
		// Internal / Miscellaneous Vulkan Helpers
		// (Used by example's main.cpp. Used by multi-viewport features. PROBABLY NOT used by your own engine/app.)
		//-------------------------------------------------------------------------
		// You probably do NOT need to use or care about those functions.
		// Those functions only exist because:
		//   1) they facilitate the readability and maintenance of the multiple main.cpp examples files.
		//   2) the upcoming multi-viewport feature will need them internally.
		// Generally we avoid exposing any kind of superfluous high-level helpers in the backends,
		// but it is too much code to duplicate everywhere so we exceptionally expose them.
		//
		// Your engine/app will likely _already_ have code to setup all that stuff (swap chain, render pass, frame buffers, etc.).
		// You may read this code to learn about Vulkan, but it is recommended you use you own custom tailored code to do equivalent work.
		// (The ImGui_ImplVulkanH_XXX functions do not interact with any of the state used by the regular ImGui_ImplVulkan_XXX functions)
		//-------------------------------------------------------------------------

		// Helpers
		public static void                 CreateOrResizeWindow(VkInstance instance, VkPhysicalDevice physical_device, VkDevice device, Window* wnd, uint32 queue_family, VkAllocationCallbacks* allocator, int w, int h, uint32 min_image_count) => ImGui_ImplVulkanH_CreateOrResizeWindow(instance, physical_device, device, wnd, queue_family, allocator, w, h, min_image_count);
		public static void                 DestroyWindow(VkInstance instance, VkDevice device, Window* wnd, VkAllocationCallbacks* allocator) => ImGui_ImplVulkanH_DestroyWindow(instance, device, wnd, allocator);
		public static VkSurfaceFormatKHR   SelectSurfaceFormat(VkPhysicalDevice physical_device, VkSurfaceKHR surface, VkFormat* request_formats, int request_formats_count, VkColorSpaceKHR request_color_space) => ImGui_ImplVulkanH_SelectSurfaceFormat(physical_device, surface, request_formats, request_formats_count, request_color_space);
		public static VkPresentModeKHR     SelectPresentMode(VkPhysicalDevice physical_device, VkSurfaceKHR surface, VkPresentModeKHR* request_modes, int request_modes_count) => ImGui_ImplVulkanH_SelectPresentMode(physical_device, surface, request_modes, request_modes_count);
		public static int                  GetMinImageCountFromPresentMode(VkPresentModeKHR present_mode) => ImGui_ImplVulkanH_GetMinImageCountFromPresentMode(present_mode);

		// Helper structure to hold the data needed by one rendering frame
		// (Used by example's main.cpp. Used by multi-viewport features. Probably NOT used by your own engine/app.)
		// [Please zero-clear before use!]
		struct ImGui_ImplVulkanH_Frame
		{
		    public VkCommandPool       CommandPool;
		    public VkCommandBuffer     CommandBuffer;
		    public VkFence             Fence;
		    public VkImage             Backbuffer;
		    public VkImageView         BackbufferView;
		    public VkFramebuffer       Framebuffer;
		};

		struct ImGui_ImplVulkanH_FrameSemaphores
		{
		    public VkSemaphore         ImageAcquiredSemaphore;
		    public VkSemaphore         RenderCompleteSemaphore;
		};

		// Helper structure to hold the data needed by one rendering context into one OS window
		// (Used by example's main.cpp. Used by multi-viewport features. Probably NOT used by your own engine/app.)
		struct ImGui_ImplVulkanH_Window
		{
		    public int                 Width;
		    public int                 Height;
		    public VkSwapchainKHR      Swapchain;
		    public VkSurfaceKHR        Surface;
		    public VkSurfaceFormatKHR  SurfaceFormat;
		    public VkPresentModeKHR    PresentMode;
		    public VkRenderPass        RenderPass;
		    public VkPipeline          Pipeline;               // The window pipeline may uses a different VkRenderPass than the one passed in ImGui_ImplVulkan_InitInfo
		    public bool                ClearEnable;
		    public VkClearValue        ClearValue;
		    public uint32              FrameIndex;             // Current frame being rendered to (0 <= FrameIndex < FrameInFlightCount)
		    public uint32              ImageCount;             // Number of simultaneous in-flight frames (returned by vkGetSwapchainImagesKHR, usually derived from min_image_count)
		    public uint32              SemaphoreIndex;         // Current set of swapchain wait semaphores we're using (needs to be distinct from per frame data)
		    public Frame*              Frames;
		    public FrameSemaphores*    FrameSemaphores;

		    public this()
		    {
				this = ?;

		        Internal.MemSet(&this, 0, sizeof(ImGui_ImplVulkanH_Window));
		        //PresentMode = .VK_PRESENT_MODE_MAX_ENUM_KHR; // TODO: Idk
		        ClearEnable = true;
		    }
		};

		// Reusable buffers used for rendering 1 current in-flight frame, for ImGui_ImplVulkan_RenderDrawData()
		// [Please zero-clear before use!]
		struct ImGui_ImplVulkanH_FrameRenderBuffers
		{
		    public VkDeviceMemory      VertexBufferMemory;
		    public VkDeviceMemory      IndexBufferMemory;
		    public VkDeviceSize        VertexBufferSize;
		    public VkDeviceSize        IndexBufferSize;
		    public VkBuffer            VertexBuffer;
		    public VkBuffer            IndexBuffer;
		};

		// Each viewport will hold 1 ImGui_ImplVulkanH_WindowRenderBuffers
		// [Please zero-clear before use!]
		struct ImGui_ImplVulkanH_WindowRenderBuffers
		{
		    public uint32            Index;
		    public uint32            Count;
		    public ImGui_ImplVulkanH_FrameRenderBuffers*   FrameRenderBuffers;
		};

		// Vulkan data
		struct ImGui_ImplVulkan_Data
		{
		    public ImGui_ImplVulkan_InitInfo   VulkanInitInfo;
		    public VkRenderPass                RenderPass;
		    public VkDeviceSize                BufferMemoryAlignment;
		    public VkPipelineCreateFlags       PipelineCreateFlags;
		    public VkDescriptorSetLayout       DescriptorSetLayout;
		    public VkPipelineLayout            PipelineLayout;
		    public VkPipeline                  Pipeline;
		    public uint32                      Subpass;
		    public VkShaderModule              ShaderModuleVert;
		    public VkShaderModule              ShaderModuleFrag;

		    // Font data
		    public VkSampler                   FontSampler;
		    public VkDeviceMemory              FontMemory;
		    public VkImage                     FontImage;
		    public VkImageView                 FontView;
		    public VkDescriptorSet             FontDescriptorSet;
		    public VkDeviceMemory              UploadBufferMemory;
		    public VkBuffer                    UploadBuffer;

		    // Render buffers
		    public ImGui_ImplVulkanH_WindowRenderBuffers MainWindowRenderBuffers;

		    public this()
		    {
				this = ?;

		        Internal.MemSet(&this, 0, sizeof(ImGui_ImplVulkan_Data));
		        BufferMemoryAlignment = (.) 256;
		    }
		};

		//-----------------------------------------------------------------------------
		// SHADERS
		//-----------------------------------------------------------------------------

		// glsl_shader.vert, compiled with:
		// # glslangValidator -V -x -o glsl_shader.vert.u32 glsl_shader.vert
		/*
		#version 450 core
		layout(location = 0) in vec2 aPos;
		layout(location = 1) in vec2 aUV;
		layout(location = 2) in vec4 aColor;
		layout(push_constant) uniform uPushConstant { vec2 uScale; vec2 uTranslate; } pc;
		out gl_PerVertex { vec4 gl_Position; };
		layout(location = 0) out struct { vec4 Color; vec2 UV; } Out;
		void main()
		{
		    Out.Color = aColor;
		    Out.UV = aUV;
		    gl_Position = vec4(aPos * pc.uScale + pc.uTranslate, 0, 1);
		}
		*/
		static uint32[?] __glsl_shader_vert_spv =
		.(
		    0x07230203,0x00010000,0x00080001,0x0000002e,0x00000000,0x00020011,0x00000001,0x0006000b,
		    0x00000001,0x4c534c47,0x6474732e,0x3035342e,0x00000000,0x0003000e,0x00000000,0x00000001,
		    0x000a000f,0x00000000,0x00000004,0x6e69616d,0x00000000,0x0000000b,0x0000000f,0x00000015,
		    0x0000001b,0x0000001c,0x00030003,0x00000002,0x000001c2,0x00040005,0x00000004,0x6e69616d,
		    0x00000000,0x00030005,0x00000009,0x00000000,0x00050006,0x00000009,0x00000000,0x6f6c6f43,
		    0x00000072,0x00040006,0x00000009,0x00000001,0x00005655,0x00030005,0x0000000b,0x0074754f,
		    0x00040005,0x0000000f,0x6c6f4361,0x0000726f,0x00030005,0x00000015,0x00565561,0x00060005,
		    0x00000019,0x505f6c67,0x65567265,0x78657472,0x00000000,0x00060006,0x00000019,0x00000000,
		    0x505f6c67,0x7469736f,0x006e6f69,0x00030005,0x0000001b,0x00000000,0x00040005,0x0000001c,
		    0x736f5061,0x00000000,0x00060005,0x0000001e,0x73755075,0x6e6f4368,0x6e617473,0x00000074,
		    0x00050006,0x0000001e,0x00000000,0x61635375,0x0000656c,0x00060006,0x0000001e,0x00000001,
		    0x61725475,0x616c736e,0x00006574,0x00030005,0x00000020,0x00006370,0x00040047,0x0000000b,
		    0x0000001e,0x00000000,0x00040047,0x0000000f,0x0000001e,0x00000002,0x00040047,0x00000015,
		    0x0000001e,0x00000001,0x00050048,0x00000019,0x00000000,0x0000000b,0x00000000,0x00030047,
		    0x00000019,0x00000002,0x00040047,0x0000001c,0x0000001e,0x00000000,0x00050048,0x0000001e,
		    0x00000000,0x00000023,0x00000000,0x00050048,0x0000001e,0x00000001,0x00000023,0x00000008,
		    0x00030047,0x0000001e,0x00000002,0x00020013,0x00000002,0x00030021,0x00000003,0x00000002,
		    0x00030016,0x00000006,0x00000020,0x00040017,0x00000007,0x00000006,0x00000004,0x00040017,
		    0x00000008,0x00000006,0x00000002,0x0004001e,0x00000009,0x00000007,0x00000008,0x00040020,
		    0x0000000a,0x00000003,0x00000009,0x0004003b,0x0000000a,0x0000000b,0x00000003,0x00040015,
		    0x0000000c,0x00000020,0x00000001,0x0004002b,0x0000000c,0x0000000d,0x00000000,0x00040020,
		    0x0000000e,0x00000001,0x00000007,0x0004003b,0x0000000e,0x0000000f,0x00000001,0x00040020,
		    0x00000011,0x00000003,0x00000007,0x0004002b,0x0000000c,0x00000013,0x00000001,0x00040020,
		    0x00000014,0x00000001,0x00000008,0x0004003b,0x00000014,0x00000015,0x00000001,0x00040020,
		    0x00000017,0x00000003,0x00000008,0x0003001e,0x00000019,0x00000007,0x00040020,0x0000001a,
		    0x00000003,0x00000019,0x0004003b,0x0000001a,0x0000001b,0x00000003,0x0004003b,0x00000014,
		    0x0000001c,0x00000001,0x0004001e,0x0000001e,0x00000008,0x00000008,0x00040020,0x0000001f,
		    0x00000009,0x0000001e,0x0004003b,0x0000001f,0x00000020,0x00000009,0x00040020,0x00000021,
		    0x00000009,0x00000008,0x0004002b,0x00000006,0x00000028,0x00000000,0x0004002b,0x00000006,
		    0x00000029,0x3f800000,0x00050036,0x00000002,0x00000004,0x00000000,0x00000003,0x000200f8,
		    0x00000005,0x0004003d,0x00000007,0x00000010,0x0000000f,0x00050041,0x00000011,0x00000012,
		    0x0000000b,0x0000000d,0x0003003e,0x00000012,0x00000010,0x0004003d,0x00000008,0x00000016,
		    0x00000015,0x00050041,0x00000017,0x00000018,0x0000000b,0x00000013,0x0003003e,0x00000018,
		    0x00000016,0x0004003d,0x00000008,0x0000001d,0x0000001c,0x00050041,0x00000021,0x00000022,
		    0x00000020,0x0000000d,0x0004003d,0x00000008,0x00000023,0x00000022,0x00050085,0x00000008,
		    0x00000024,0x0000001d,0x00000023,0x00050041,0x00000021,0x00000025,0x00000020,0x00000013,
		    0x0004003d,0x00000008,0x00000026,0x00000025,0x00050081,0x00000008,0x00000027,0x00000024,
		    0x00000026,0x00050051,0x00000006,0x0000002a,0x00000027,0x00000000,0x00050051,0x00000006,
		    0x0000002b,0x00000027,0x00000001,0x00070050,0x00000007,0x0000002c,0x0000002a,0x0000002b,
		    0x00000028,0x00000029,0x00050041,0x00000011,0x0000002d,0x0000001b,0x0000000d,0x0003003e,
		    0x0000002d,0x0000002c,0x000100fd,0x00010038
		);

		// glsl_shader.frag, compiled with:
		// # glslangValidator -V -x -o glsl_shader.frag.u32 glsl_shader.frag
		/*
		#version 450 core
		layout(location = 0) out vec4 fColor;
		layout(set=0, binding=0) uniform sampler2D sTexture;
		layout(location = 0) in struct { vec4 Color; vec2 UV; } In;
		void main()
		{
		    fColor = In.Color * texture(sTexture, In.UV.st);
		}
		*/
		static uint32[?] __glsl_shader_frag_spv =
		.(
		    0x07230203,0x00010000,0x00080001,0x0000001e,0x00000000,0x00020011,0x00000001,0x0006000b,
		    0x00000001,0x4c534c47,0x6474732e,0x3035342e,0x00000000,0x0003000e,0x00000000,0x00000001,
		    0x0007000f,0x00000004,0x00000004,0x6e69616d,0x00000000,0x00000009,0x0000000d,0x00030010,
		    0x00000004,0x00000007,0x00030003,0x00000002,0x000001c2,0x00040005,0x00000004,0x6e69616d,
		    0x00000000,0x00040005,0x00000009,0x6c6f4366,0x0000726f,0x00030005,0x0000000b,0x00000000,
		    0x00050006,0x0000000b,0x00000000,0x6f6c6f43,0x00000072,0x00040006,0x0000000b,0x00000001,
		    0x00005655,0x00030005,0x0000000d,0x00006e49,0x00050005,0x00000016,0x78655473,0x65727574,
		    0x00000000,0x00040047,0x00000009,0x0000001e,0x00000000,0x00040047,0x0000000d,0x0000001e,
		    0x00000000,0x00040047,0x00000016,0x00000022,0x00000000,0x00040047,0x00000016,0x00000021,
		    0x00000000,0x00020013,0x00000002,0x00030021,0x00000003,0x00000002,0x00030016,0x00000006,
		    0x00000020,0x00040017,0x00000007,0x00000006,0x00000004,0x00040020,0x00000008,0x00000003,
		    0x00000007,0x0004003b,0x00000008,0x00000009,0x00000003,0x00040017,0x0000000a,0x00000006,
		    0x00000002,0x0004001e,0x0000000b,0x00000007,0x0000000a,0x00040020,0x0000000c,0x00000001,
		    0x0000000b,0x0004003b,0x0000000c,0x0000000d,0x00000001,0x00040015,0x0000000e,0x00000020,
		    0x00000001,0x0004002b,0x0000000e,0x0000000f,0x00000000,0x00040020,0x00000010,0x00000001,
		    0x00000007,0x00090019,0x00000013,0x00000006,0x00000001,0x00000000,0x00000000,0x00000000,
		    0x00000001,0x00000000,0x0003001b,0x00000014,0x00000013,0x00040020,0x00000015,0x00000000,
		    0x00000014,0x0004003b,0x00000015,0x00000016,0x00000000,0x0004002b,0x0000000e,0x00000018,
		    0x00000001,0x00040020,0x00000019,0x00000001,0x0000000a,0x00050036,0x00000002,0x00000004,
		    0x00000000,0x00000003,0x000200f8,0x00000005,0x00050041,0x00000010,0x00000011,0x0000000d,
		    0x0000000f,0x0004003d,0x00000007,0x00000012,0x00000011,0x0004003d,0x00000014,0x00000017,
		    0x00000016,0x00050041,0x00000019,0x0000001a,0x0000000d,0x00000018,0x0004003d,0x0000000a,
		    0x0000001b,0x0000001a,0x00050057,0x00000007,0x0000001c,0x00000017,0x0000001b,0x00050085,
		    0x00000007,0x0000001d,0x00000012,0x0000001c,0x0003003e,0x00000009,0x0000001d,0x000100fd,
		    0x00010038
		);

		//-----------------------------------------------------------------------------
		// FUNCTIONS
		//-----------------------------------------------------------------------------

		// Backend data stored in io.BackendRendererUserData to allow support for multiple Dear ImGui contexts
		// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
		// FIXME: multi-context support is not tested and probably dysfunctional in this backend.
		static ImGui_ImplVulkan_Data* ImGui_ImplVulkan_GetBackendData()
		{
		    return ImGui.GetCurrentContext() != null ? (ImGui_ImplVulkan_Data*)ImGui.GetIO().BackendRendererUserData : null;
		}

		static uint32 ImGui_ImplVulkan_MemoryType(VkMemoryPropertyFlags properties, uint32 type_bits)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;
		    VkPhysicalDeviceMemoryProperties prop = ?;
		    vkGetPhysicalDeviceMemoryProperties(v.PhysicalDevice, &prop);
		    for (uint32 i = 0; i < prop.memoryTypeCount; i++)
		        if ((prop.memoryTypes[i].propertyFlags & properties) == properties && (type_bits & (1 << i)) > 0)
		            return i;
		    return 0xFFFFFFFF; // Unable to find memoryType
		}

		static void check_vk_result(VkResult err)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    if (bd == null)
		        return;
		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;
		    if (v.CheckVkResultFn != null)
		        v.CheckVkResultFn(err);
		}

		static void CreateOrResizeBuffer(ref VkBuffer buffer, ref VkDeviceMemory buffer_memory, ref VkDeviceSize p_buffer_size, uint new_size, VkBufferUsageFlags usage)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;
		    VkResult err;
		    if (buffer != .Null)
		        vkDestroyBuffer(v.Device, buffer, v.Allocator);
		    if (buffer_memory != .Null)
		        vkFreeMemory(v.Device, buffer_memory, v.Allocator);

		    VkDeviceSize vertex_buffer_size_aligned = ((.) (new_size - 1) / bd.BufferMemoryAlignment + (.) 1) * bd.BufferMemoryAlignment;
		    VkBufferCreateInfo buffer_info = .();
		    buffer_info.sType = .VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
		    buffer_info.size = vertex_buffer_size_aligned;
		    buffer_info.usage = usage;
		    buffer_info.sharingMode = .VK_SHARING_MODE_EXCLUSIVE;
		    err = vkCreateBuffer(v.Device, &buffer_info, v.Allocator, &buffer);
		    check_vk_result(err);

		    VkMemoryRequirements req = ?;
		    vkGetBufferMemoryRequirements(v.Device, buffer, &req);
		    bd.BufferMemoryAlignment = (bd.BufferMemoryAlignment > (.) req.alignment) ? bd.BufferMemoryAlignment : (.) req.alignment;
		    VkMemoryAllocateInfo alloc_info = .();
		    alloc_info.sType = .VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		    alloc_info.allocationSize = req.size;
		    alloc_info.memoryTypeIndex = ImGui_ImplVulkan_MemoryType(.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, req.memoryTypeBits);
		    err = vkAllocateMemory(v.Device, &alloc_info, v.Allocator, &buffer_memory);
		    check_vk_result(err);

		    err = vkBindBufferMemory(v.Device, buffer, buffer_memory, 0);
		    check_vk_result(err);
		    p_buffer_size = (.) req.size;
		}

		static void ImGui_ImplVulkan_SetupRenderState(ImGui.DrawData* draw_data, VkPipeline pipeline, VkCommandBuffer command_buffer, ImGui_ImplVulkanH_FrameRenderBuffers* rb, int fb_width, int fb_height)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();

		    // Bind pipeline:
		    {
		        vkCmdBindPipeline(command_buffer, .VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);
		    }

		    // Bind Vertex And Index Buffer:
		    if (draw_data.TotalVtxCount > 0)
		    {
		        VkBuffer[1] vertex_buffers = .( rb.VertexBuffer );
		        uint64[1] vertex_offset = .( 0 );
		        vkCmdBindVertexBuffers(command_buffer, 0, 1, &vertex_buffers, &vertex_offset);
		        vkCmdBindIndexBuffer(command_buffer, rb.IndexBuffer, 0, sizeof(ImGui.DrawIdx) == 2 ? .VK_INDEX_TYPE_UINT16 : .VK_INDEX_TYPE_UINT32);
		    }

		    // Setup viewport:
		    {
		        VkViewport viewport;
		        viewport.x = 0;
		        viewport.y = 0;
		        viewport.width = (float)fb_width;
		        viewport.height = (float)fb_height;
		        viewport.minDepth = 0.0f;
		        viewport.maxDepth = 1.0f;
		        vkCmdSetViewport(command_buffer, 0, 1, &viewport);
		    }

		    // Setup scale and translation:
		    // Our visible imgui space lies from draw_data.DisplayPps (top left) to draw_data.DisplayPos+data_data.DisplaySize (bottom right). DisplayPos is (0,0) for single viewport apps.
		    {
		        float[2] scale;
		        scale[0] = 2.0f / draw_data.DisplaySize.x;
		        scale[1] = 2.0f / draw_data.DisplaySize.y;
		        float[2] translate;
		        translate[0] = -1.0f - draw_data.DisplayPos.x * scale[0];
		        translate[1] = -1.0f - draw_data.DisplayPos.y * scale[1];
		        vkCmdPushConstants(command_buffer, bd.PipelineLayout, .VK_SHADER_STAGE_VERTEX_BIT, sizeof(float) * 0, sizeof(float) * 2, &scale);
		        vkCmdPushConstants(command_buffer, bd.PipelineLayout, .VK_SHADER_STAGE_VERTEX_BIT, sizeof(float) * 2, sizeof(float) * 2, &translate);
		    }
		}

		// Render function
		static void ImGui_ImplVulkan_RenderDrawData(ImGui.DrawData* draw_data, VkCommandBuffer command_buffer, VkPipeline pipeline)
		{
			var pipeline;

		    // Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
		    int fb_width = (int)(draw_data.DisplaySize.x * draw_data.FramebufferScale.x);
		    int fb_height = (int)(draw_data.DisplaySize.y * draw_data.FramebufferScale.y);
		    if (fb_width <= 0 || fb_height <= 0)
		        return;

		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;
		    if (pipeline == .Null)
		        pipeline = bd.Pipeline;

		    // Allocate array to store enough vertex/index buffers
		    ImGui_ImplVulkanH_WindowRenderBuffers* wrb = &bd.MainWindowRenderBuffers;
		    if (wrb.FrameRenderBuffers == null)
		    {
		        wrb.Index = 0;
		        wrb.Count = v.ImageCount;
		        wrb.FrameRenderBuffers = (ImGui_ImplVulkanH_FrameRenderBuffers*)new uint8[sizeof(ImGui_ImplVulkanH_FrameRenderBuffers) * wrb.Count]*;
		        Internal.MemSet(wrb.FrameRenderBuffers, 0, sizeof(ImGui_ImplVulkanH_FrameRenderBuffers) * wrb.Count);
		    }
		    Debug.Assert(wrb.Count == v.ImageCount);
		    wrb.Index = (wrb.Index + 1) % wrb.Count;
		    ImGui_ImplVulkanH_FrameRenderBuffers* rb = &wrb.FrameRenderBuffers[wrb.Index];

		    if (draw_data.TotalVtxCount > 0)
		    {
		        // Create or resize the vertex/index buffers
		        uint vertex_size = (.) draw_data.TotalVtxCount * sizeof(ImGui.DrawVert);
		        uint index_size = (.) draw_data.TotalIdxCount * sizeof(ImGui.DrawIdx);
		        if (rb.VertexBuffer == .Null || rb.VertexBufferSize < (.) vertex_size)
		            CreateOrResizeBuffer(ref rb.VertexBuffer, ref rb.VertexBufferMemory, ref rb.VertexBufferSize, vertex_size, .VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);
		        if (rb.IndexBuffer == .Null || rb.IndexBufferSize < (.) index_size)
		            CreateOrResizeBuffer(ref rb.IndexBuffer, ref rb.IndexBufferMemory, ref rb.IndexBufferSize, index_size, .VK_BUFFER_USAGE_INDEX_BUFFER_BIT);

		        // Upload vertex/index data into a single contiguous GPU buffer
		        ImGui.DrawVert* vtx_dst = null;
		        ImGui.DrawIdx* idx_dst = null;
		        VkResult err = vkMapMemory(v.Device, rb.VertexBufferMemory, 0, rb.VertexBufferSize, 0, (void**)(&vtx_dst));
		        check_vk_result(err);
		        err = vkMapMemory(v.Device, rb.IndexBufferMemory, 0, rb.IndexBufferSize, 0, (void**)(&idx_dst));
		        check_vk_result(err);
		        for (int n = 0; n < draw_data.CmdListsCount; n++)
		        {
		            ImGui.DrawList* cmd_list = draw_data.CmdLists[n];
		            Internal.MemCpy(vtx_dst, cmd_list.VtxBuffer.Data, cmd_list.VtxBuffer.Size * sizeof(ImGui.DrawVert));
		            Internal.MemCpy(idx_dst, cmd_list.IdxBuffer.Data, cmd_list.IdxBuffer.Size * sizeof(ImGui.DrawIdx));
		            vtx_dst += cmd_list.VtxBuffer.Size;
		            idx_dst += cmd_list.IdxBuffer.Size;
		        }
		        VkMappedMemoryRange[2] range = .();
		        range[0].sType = .VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
		        range[0].memory = rb.VertexBufferMemory;
		        range[0].size = VK_WHOLE_SIZE;
		        range[1].sType = .VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
		        range[1].memory = rb.IndexBufferMemory;
		        range[1].size = VK_WHOLE_SIZE;
		        err = vkFlushMappedMemoryRanges(v.Device, 2, &range);
		        check_vk_result(err);
		        vkUnmapMemory(v.Device, rb.VertexBufferMemory);
		        vkUnmapMemory(v.Device, rb.IndexBufferMemory);
		    }

		    // Setup desired Vulkan state
		    ImGui_ImplVulkan_SetupRenderState(draw_data, pipeline, command_buffer, rb, fb_width, fb_height);

		    // Will project scissor/clipping rectangles into framebuffer space
		    ImGui.Vec2 clip_off = draw_data.DisplayPos;         // (0,0) unless using multi-viewports
		    ImGui.Vec2 clip_scale = draw_data.FramebufferScale; // (1,1) unless using retina display which are often (2,2)

		    // Render command lists
		    // (Because we merged all buffers into a single one, we maintain our own offset into them)
		    int global_vtx_offset = 0;
		    int global_idx_offset = 0;
		    for (int n = 0; n < draw_data.CmdListsCount; n++)
		    {
		        ImGui.DrawList* cmd_list = draw_data.CmdLists[n];
		        for (int cmd_i = 0; cmd_i < cmd_list.CmdBuffer.Size; cmd_i++)
		        {
		            ImGui.DrawCmd* pcmd = &cmd_list.CmdBuffer.Data[cmd_i];
		            if (pcmd.UserCallback != null)
		            {
		                // User callback, registered via ImDrawList::AddCallback()
		                // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
		                if (pcmd.UserCallback == *ImGui.DrawCallback_ResetRenderState)
		                    ImGui_ImplVulkan_SetupRenderState(draw_data, pipeline, command_buffer, rb, fb_width, fb_height);
		                else
		                    pcmd.UserCallback(cmd_list, pcmd);
		            }
		            else
		            {
		                // Project scissor/clipping rectangles into framebuffer space
		                ImGui.Vec2 clip_min = .((pcmd.ClipRect.x - clip_off.x) * clip_scale.x, (pcmd.ClipRect.y - clip_off.y) * clip_scale.y);
		                ImGui.Vec2 clip_max = .((pcmd.ClipRect.z - clip_off.x) * clip_scale.x, (pcmd.ClipRect.w - clip_off.y) * clip_scale.y);

		                // Clamp to viewport as vkCmdSetScissor() won't accept values that are off bounds
		                if (clip_min.x < 0.0f) { clip_min.x = 0.0f; }
		                if (clip_min.y < 0.0f) { clip_min.y = 0.0f; }
		                if (clip_max.x > fb_width) { clip_max.x = (float)fb_width; }
		                if (clip_max.y > fb_height) { clip_max.y = (float)fb_height; }
		                if (clip_max.x <= clip_min.x || clip_max.y <= clip_min.y)
		                    continue;

		                // Apply scissor/clipping rectangle
		                VkRect2D scissor;
		                scissor.offset.x = (int32)(clip_min.x);
		                scissor.offset.y = (int32)(clip_min.y);
		                scissor.extent.width = (uint32)(clip_max.x - clip_min.x);
		                scissor.extent.height = (uint32)(clip_max.y - clip_min.y);
		                vkCmdSetScissor(command_buffer, 0, 1, &scissor);

		                // Bind DescriptorSet with font or user texture
		                VkDescriptorSet[1] desc_set = .( *(VkDescriptorSet*)pcmd.TextureId );
		                if (sizeof(ImGui.TextureID) < sizeof(ImGui.U64))
		                {
		                    // We don't support texture switches if ImTextureID hasn't been redefined to be 64-bit. Do a flaky check that other textures haven't been used.
		                    Debug.Assert(pcmd.TextureId == (ImGui.TextureID)&bd.FontDescriptorSet);
		                    desc_set[0] = bd.FontDescriptorSet;
		                }
		                vkCmdBindDescriptorSets(command_buffer, .VK_PIPELINE_BIND_POINT_GRAPHICS, bd.PipelineLayout, 0, 1, &desc_set, 0, null);

		                // Draw
		                vkCmdDrawIndexed(command_buffer, pcmd.ElemCount, 1, (.) (pcmd.IdxOffset + global_idx_offset), (.) (pcmd.VtxOffset + global_vtx_offset), 0);
		            }
		        }
		        global_idx_offset += cmd_list.IdxBuffer.Size;
		        global_vtx_offset += cmd_list.VtxBuffer.Size;
		    }

		    // Note: at this point both vkCmdSetViewport() and vkCmdSetScissor() have been called.
		    // Our last values will leak into user/application rendering IF:
		    // - Your app uses a pipeline with VK_DYNAMIC_STATE_VIEWPORT or VK_DYNAMIC_STATE_SCISSOR dynamic state
		    // - And you forgot to call vkCmdSetViewport() and vkCmdSetScissor() yourself to explicitely set that state.
		    // If you use VK_DYNAMIC_STATE_VIEWPORT or VK_DYNAMIC_STATE_SCISSOR you are responsible for setting the values before rendering.
		    // In theory we should aim to backup/restore those values but I am not sure this is possible.
		    // We perform a call to vkCmdSetScissor() to set back a full viewport which is likely to fix things for 99% users but technically this is not perfect. (See github #4644)
		    VkRect2D scissor = .( .( 0, 0 ), .( (uint32)fb_width, (uint32)fb_height ) );
		    vkCmdSetScissor(command_buffer, 0, 1, &scissor);
		}

		static bool ImGui_ImplVulkan_CreateFontsTexture(VkCommandBuffer command_buffer)
		{
		    ImGui.IO* io = ImGui.GetIO();
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;

		    uint8* pixels = ?;
		    int32 width, height;
		    io.Fonts.GetTexDataAsRGBA32(out pixels, out width, out height);
		    uint upload_size = (.) (width * height * 4 * sizeof(uint8));

		    VkResult err;

		    // Create the Image:
		    {
		        VkImageCreateInfo info = .();
		        info.sType = .VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
		        info.imageType = .VK_IMAGE_TYPE_2D;
		        info.format = .VK_FORMAT_R8G8B8A8_UNORM;
		        info.extent.width = (.) width;
		        info.extent.height = (.) height;
		        info.extent.depth = 1;
		        info.mipLevels = 1;
		        info.arrayLayers = 1;
		        info.samples = .VK_SAMPLE_COUNT_1_BIT;
		        info.tiling = .VK_IMAGE_TILING_OPTIMAL;
		        info.usage = .VK_IMAGE_USAGE_SAMPLED_BIT | .VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		        info.sharingMode = .VK_SHARING_MODE_EXCLUSIVE;
		        info.initialLayout = .VK_IMAGE_LAYOUT_UNDEFINED;
		        err = vkCreateImage(v.Device, &info, v.Allocator, &bd.FontImage);
		        check_vk_result(err);
		        VkMemoryRequirements req = ?;
		        vkGetImageMemoryRequirements(v.Device, bd.FontImage, &req);
		        VkMemoryAllocateInfo alloc_info = .();
		        alloc_info.sType = .VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		        alloc_info.allocationSize = req.size;
		        alloc_info.memoryTypeIndex = ImGui_ImplVulkan_MemoryType(.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, req.memoryTypeBits);
		        err = vkAllocateMemory(v.Device, &alloc_info, v.Allocator, &bd.FontMemory);
		        check_vk_result(err);
		        err = vkBindImageMemory(v.Device, bd.FontImage, bd.FontMemory, 0);
		        check_vk_result(err);
		    }

		    // Create the Image View:
		    {
		        VkImageViewCreateInfo info = .();
		        info.sType = .VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		        info.image = bd.FontImage;
		        info.viewType = .VK_IMAGE_VIEW_TYPE_2D;
		        info.format = .VK_FORMAT_R8G8B8A8_UNORM;
		        info.subresourceRange.aspectMask = .VK_IMAGE_ASPECT_COLOR_BIT;
		        info.subresourceRange.levelCount = 1;
		        info.subresourceRange.layerCount = 1;
		        err = vkCreateImageView(v.Device, &info, v.Allocator, &bd.FontView);
		        check_vk_result(err);
		    }

		    // Create the Descriptor Set:
		    bd.FontDescriptorSet = (VkDescriptorSet)ImGui_ImplVulkan_AddTexture(bd.FontSampler, bd.FontView, .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

		    // Create the Upload Buffer:
		    {
		        VkBufferCreateInfo buffer_info = .();
		        buffer_info.sType = .VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
		        buffer_info.size = upload_size;
		        buffer_info.usage = .VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
		        buffer_info.sharingMode = .VK_SHARING_MODE_EXCLUSIVE;
		        err = vkCreateBuffer(v.Device, &buffer_info, v.Allocator, &bd.UploadBuffer);
		        check_vk_result(err);
		        VkMemoryRequirements req = ?;
		        vkGetBufferMemoryRequirements(v.Device, bd.UploadBuffer, &req);
		        bd.BufferMemoryAlignment = (bd.BufferMemoryAlignment > (.) req.alignment) ? bd.BufferMemoryAlignment : (.) req.alignment;
		        VkMemoryAllocateInfo alloc_info = .();
		        alloc_info.sType = .VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		        alloc_info.allocationSize = req.size;
		        alloc_info.memoryTypeIndex = ImGui_ImplVulkan_MemoryType(.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, req.memoryTypeBits);
		        err = vkAllocateMemory(v.Device, &alloc_info, v.Allocator, &bd.UploadBufferMemory);
		        check_vk_result(err);
		        err = vkBindBufferMemory(v.Device, bd.UploadBuffer, bd.UploadBufferMemory, 0);
		        check_vk_result(err);
		    }

		    // Upload to Buffer:
		    {
		        uint8* map = null;
		        err = vkMapMemory(v.Device, bd.UploadBufferMemory, 0, upload_size, 0, (void**)(&map));
		        check_vk_result(err);
		        Internal.MemCpy(map, pixels, (.) upload_size);
		        VkMappedMemoryRange[1] range;
		        range[0].sType = .VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
		        range[0].memory = bd.UploadBufferMemory;
		        range[0].size = upload_size;
		        err = vkFlushMappedMemoryRanges(v.Device, 1, &range);
		        check_vk_result(err);
		        vkUnmapMemory(v.Device, bd.UploadBufferMemory);
		    }

		    // Copy to Image:
		    {
		        VkImageMemoryBarrier[1] copy_barrier;
		        copy_barrier[0].sType = .VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
		        copy_barrier[0].dstAccessMask = .VK_ACCESS_TRANSFER_WRITE_BIT;
		        copy_barrier[0].oldLayout = .VK_IMAGE_LAYOUT_UNDEFINED;
		        copy_barrier[0].newLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
		        copy_barrier[0].srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		        copy_barrier[0].dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		        copy_barrier[0].image = bd.FontImage;
		        copy_barrier[0].subresourceRange.aspectMask = .VK_IMAGE_ASPECT_COLOR_BIT;
		        copy_barrier[0].subresourceRange.levelCount = 1;
		        copy_barrier[0].subresourceRange.layerCount = 1;
		        vkCmdPipelineBarrier(command_buffer, .VK_PIPELINE_STAGE_HOST_BIT, .VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, null, 0, null, 1, &copy_barrier);

		        VkBufferImageCopy region = .();
		        region.imageSubresource.aspectMask = .VK_IMAGE_ASPECT_COLOR_BIT;
		        region.imageSubresource.layerCount = 1;
		        region.imageExtent.width = (.) width;
		        region.imageExtent.height = (.) height;
		        region.imageExtent.depth = 1;
		        vkCmdCopyBufferToImage(command_buffer, bd.UploadBuffer, bd.FontImage, .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

		        VkImageMemoryBarrier[1] use_barrier;
		        use_barrier[0].sType = .VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
		        use_barrier[0].srcAccessMask = .VK_ACCESS_TRANSFER_WRITE_BIT;
		        use_barrier[0].dstAccessMask = .VK_ACCESS_SHADER_READ_BIT;
		        use_barrier[0].oldLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
		        use_barrier[0].newLayout = .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		        use_barrier[0].srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		        use_barrier[0].dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		        use_barrier[0].image = bd.FontImage;
		        use_barrier[0].subresourceRange.aspectMask = .VK_IMAGE_ASPECT_COLOR_BIT;
		        use_barrier[0].subresourceRange.levelCount = 1;
		        use_barrier[0].subresourceRange.layerCount = 1;
		        vkCmdPipelineBarrier(command_buffer, .VK_PIPELINE_STAGE_TRANSFER_BIT, .VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, null, 0, null, 1, &use_barrier);
		    }

		    // Store our identifier
		    io.Fonts.SetTexID((ImGui.TextureID)&bd.FontDescriptorSet);

		    return true;
		}

		static void ImGui_ImplVulkan_CreateShaderModules(VkDevice device, VkAllocationCallbacks* allocator)
		{
		    // Create the shader modules
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    if (bd.ShaderModuleVert == .Null)
		    {
		        VkShaderModuleCreateInfo vert_info = .();
		        vert_info.sType = .VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
		        vert_info.codeSize = __glsl_shader_vert_spv.Count * sizeof(uint32);
		        vert_info.pCode = (uint32*)&__glsl_shader_vert_spv;
		        VkResult err = vkCreateShaderModule(device, &vert_info, allocator, &bd.ShaderModuleVert);
		        check_vk_result(err);
		    }
		    if (bd.ShaderModuleFrag == .Null)
		    {
		        VkShaderModuleCreateInfo frag_info = .();
		        frag_info.sType = .VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
		        frag_info.codeSize = __glsl_shader_frag_spv.Count * sizeof(uint32);
		        frag_info.pCode = (uint32*)&__glsl_shader_frag_spv;
		        VkResult err = vkCreateShaderModule(device, &frag_info, allocator, &bd.ShaderModuleFrag);
		        check_vk_result(err);
		    }
		}

		static void ImGui_ImplVulkan_CreateFontSampler(VkDevice device, VkAllocationCallbacks* allocator)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    if (bd.FontSampler != .Null)
		        return;

		    VkSamplerCreateInfo info = .();
		    info.sType = .VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
		    info.magFilter = .VK_FILTER_LINEAR;
		    info.minFilter = .VK_FILTER_LINEAR;
		    info.mipmapMode = .VK_SAMPLER_MIPMAP_MODE_LINEAR;
		    info.addressModeU = .VK_SAMPLER_ADDRESS_MODE_REPEAT;
		    info.addressModeV = .VK_SAMPLER_ADDRESS_MODE_REPEAT;
		    info.addressModeW = .VK_SAMPLER_ADDRESS_MODE_REPEAT;
		    info.minLod = -1000;
		    info.maxLod = 1000;
		    info.maxAnisotropy = 1.0f;
		    VkResult err = vkCreateSampler(device, &info, allocator, &bd.FontSampler);
		    check_vk_result(err);
		}

		static void ImGui_ImplVulkan_CreateDescriptorSetLayout(VkDevice device, VkAllocationCallbacks* allocator)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    if (bd.DescriptorSetLayout != .Null)
		        return;

		    ImGui_ImplVulkan_CreateFontSampler(device, allocator);
		    VkSampler[1] sampler = .( bd.FontSampler );
		    VkDescriptorSetLayoutBinding[1] binding;
		    binding[0].descriptorType = .VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
		    binding[0].descriptorCount = 1;
		    binding[0].stageFlags = .VK_SHADER_STAGE_FRAGMENT_BIT;
		    binding[0].pImmutableSamplers = &sampler;
		    VkDescriptorSetLayoutCreateInfo info = .();
		    info.sType = .VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
		    info.bindingCount = 1;
		    info.pBindings = &binding;
		    VkResult err = vkCreateDescriptorSetLayout(device, &info, allocator, &bd.DescriptorSetLayout);
		    check_vk_result(err);
		}

		static void ImGui_ImplVulkan_CreatePipelineLayout(VkDevice device, VkAllocationCallbacks* allocator)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    if (bd.PipelineLayout != .Null)
		        return;

		    // Constants: we are using 'vec2 offset' and 'vec2 scale' instead of a full 3d projection matrix
		    ImGui_ImplVulkan_CreateDescriptorSetLayout(device, allocator);
		    VkPushConstantRange[1] push_constants;
		    push_constants[0].stageFlags = .VK_SHADER_STAGE_VERTEX_BIT;
		    push_constants[0].offset = sizeof(float) * 0;
		    push_constants[0].size = sizeof(float) * 4;
		    VkDescriptorSetLayout[1] set_layout = .( bd.DescriptorSetLayout );
		    VkPipelineLayoutCreateInfo layout_info = .();
		    layout_info.sType = .VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
		    layout_info.setLayoutCount = 1;
		    layout_info.pSetLayouts = &set_layout;
		    layout_info.pushConstantRangeCount = 1;
		    layout_info.pPushConstantRanges = &push_constants;
		    VkResult  err = vkCreatePipelineLayout(device, &layout_info, allocator, &bd.PipelineLayout);
		    check_vk_result(err);
		}

		static void ImGui_ImplVulkan_CreatePipeline(VkDevice device, VkAllocationCallbacks* allocator, VkPipelineCache pipelineCache, VkRenderPass renderPass, VkSampleCountFlags MSAASamples, VkPipeline* pipeline, uint32 subpass)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    ImGui_ImplVulkan_CreateShaderModules(device, allocator);

		    VkPipelineShaderStageCreateInfo[2] stage;
		    stage[0].sType = .VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
		    stage[0].stage = .VK_SHADER_STAGE_VERTEX_BIT;
		    stage[0].module = bd.ShaderModuleVert;
		    stage[0].pName = "main";
		    stage[1].sType = .VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
		    stage[1].stage = .VK_SHADER_STAGE_FRAGMENT_BIT;
		    stage[1].module = bd.ShaderModuleFrag;
		    stage[1].pName = "main";

		    VkVertexInputBindingDescription[1] binding_desc = .();
		    binding_desc[0].stride = sizeof(ImGui.DrawVert);
		    binding_desc[0].inputRate = .VK_VERTEX_INPUT_RATE_VERTEX;

		    VkVertexInputAttributeDescription[3] attribute_desc;
		    attribute_desc[0].location = 0;
		    attribute_desc[0].binding = binding_desc[0].binding;
		    attribute_desc[0].format = .VK_FORMAT_R32G32_SFLOAT;
		    attribute_desc[0].offset = offsetof(ImGui.DrawVert, pos);
		    attribute_desc[1].location = 1;
		    attribute_desc[1].binding = binding_desc[0].binding;
		    attribute_desc[1].format = .VK_FORMAT_R32G32_SFLOAT;
		    attribute_desc[1].offset = offsetof(ImGui.DrawVert, uv);
		    attribute_desc[2].location = 2;
		    attribute_desc[2].binding = binding_desc[0].binding;
		    attribute_desc[2].format = .VK_FORMAT_R8G8B8A8_UNORM;
		    attribute_desc[2].offset = offsetof(ImGui.DrawVert, col);

		    VkPipelineVertexInputStateCreateInfo vertex_info = .();
		    vertex_info.sType = .VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
		    vertex_info.vertexBindingDescriptionCount = 1;
		    vertex_info.pVertexBindingDescriptions = &binding_desc;
		    vertex_info.vertexAttributeDescriptionCount = 3;
		    vertex_info.pVertexAttributeDescriptions = &attribute_desc;

		    VkPipelineInputAssemblyStateCreateInfo ia_info = .();
		    ia_info.sType = .VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
		    ia_info.topology = .VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;

		    VkPipelineViewportStateCreateInfo viewport_info = .();
		    viewport_info.sType = .VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
		    viewport_info.viewportCount = 1;
		    viewport_info.scissorCount = 1;

		    VkPipelineRasterizationStateCreateInfo raster_info = .();
		    raster_info.sType = .VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
		    raster_info.polygonMode = .VK_POLYGON_MODE_FILL;
		    raster_info.cullMode = .VK_CULL_MODE_NONE;
		    raster_info.frontFace = .VK_FRONT_FACE_COUNTER_CLOCKWISE;
		    raster_info.lineWidth = 1.0f;

		    VkPipelineMultisampleStateCreateInfo ms_info = .();
		    ms_info.sType = .VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
		    ms_info.rasterizationSamples = (MSAASamples != 0) ? MSAASamples : .VK_SAMPLE_COUNT_1_BIT;

		    VkPipelineColorBlendAttachmentState[1] color_attachment;
		    color_attachment[0].blendEnable = VK_TRUE;
		    color_attachment[0].srcColorBlendFactor = .VK_BLEND_FACTOR_SRC_ALPHA;
		    color_attachment[0].dstColorBlendFactor = .VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
		    color_attachment[0].colorBlendOp = .VK_BLEND_OP_ADD;
		    color_attachment[0].srcAlphaBlendFactor = .VK_BLEND_FACTOR_ONE;
		    color_attachment[0].dstAlphaBlendFactor = .VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
		    color_attachment[0].alphaBlendOp = .VK_BLEND_OP_ADD;
		    color_attachment[0].colorWriteMask = .VK_COLOR_COMPONENT_R_BIT | .VK_COLOR_COMPONENT_G_BIT | .VK_COLOR_COMPONENT_B_BIT | .VK_COLOR_COMPONENT_A_BIT;

		    VkPipelineDepthStencilStateCreateInfo depth_info = .();
		    depth_info.sType = .VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;

		    VkPipelineColorBlendStateCreateInfo blend_info = .();
		    blend_info.sType = .VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
		    blend_info.attachmentCount = 1;
		    blend_info.pAttachments = &color_attachment;

		    VkDynamicState[2] dynamic_states = .( .VK_DYNAMIC_STATE_VIEWPORT, .VK_DYNAMIC_STATE_SCISSOR );
		    VkPipelineDynamicStateCreateInfo dynamic_state = .();
		    dynamic_state.sType = .VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
		    dynamic_state.dynamicStateCount = (uint32)dynamic_states.Count;
		    dynamic_state.pDynamicStates = &dynamic_states;

		    ImGui_ImplVulkan_CreatePipelineLayout(device, allocator);

		    VkGraphicsPipelineCreateInfo info = .();
		    info.sType = .VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
		    info.flags = bd.PipelineCreateFlags;
		    info.stageCount = 2;
		    info.pStages = &stage;
		    info.pVertexInputState = &vertex_info;
		    info.pInputAssemblyState = &ia_info;
		    info.pViewportState = &viewport_info;
		    info.pRasterizationState = &raster_info;
		    info.pMultisampleState = &ms_info;
		    info.pDepthStencilState = &depth_info;
		    info.pColorBlendState = &blend_info;
		    info.pDynamicState = &dynamic_state;
		    info.layout = bd.PipelineLayout;
		    info.renderPass = renderPass;
		    info.subpass = subpass;
		    VkResult err = vkCreateGraphicsPipelines(device, pipelineCache, 1, &info, allocator, pipeline);
		    check_vk_result(err);
		}

		static bool ImGui_ImplVulkan_CreateDeviceObjects()
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;
		    VkResult err;

		    if (bd.FontSampler == .Null)
		    {
		        VkSamplerCreateInfo info = .();
		        info.sType = .VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
		        info.magFilter = .VK_FILTER_LINEAR;
		        info.minFilter = .VK_FILTER_LINEAR;
		        info.mipmapMode = .VK_SAMPLER_MIPMAP_MODE_LINEAR;
		        info.addressModeU = .VK_SAMPLER_ADDRESS_MODE_REPEAT;
		        info.addressModeV = .VK_SAMPLER_ADDRESS_MODE_REPEAT;
		        info.addressModeW = .VK_SAMPLER_ADDRESS_MODE_REPEAT;
		        info.minLod = -1000;
		        info.maxLod = 1000;
		        info.maxAnisotropy = 1.0f;
		        err = vkCreateSampler(v.Device, &info, v.Allocator, &bd.FontSampler);
		        check_vk_result(err);
		    }

		    if (bd.DescriptorSetLayout == .Null)
		    {
		        VkSampler[1] sampler = .(bd.FontSampler);
		        VkDescriptorSetLayoutBinding[1] binding;
		        binding[0].descriptorType = .VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
		        binding[0].descriptorCount = 1;
		        binding[0].stageFlags = .VK_SHADER_STAGE_FRAGMENT_BIT;
		        binding[0].pImmutableSamplers = &sampler;
		        VkDescriptorSetLayoutCreateInfo info = .();
		        info.sType = .VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
		        info.bindingCount = 1;
		        info.pBindings = &binding;
		        err = vkCreateDescriptorSetLayout(v.Device, &info, v.Allocator, &bd.DescriptorSetLayout);
		        check_vk_result(err);
		    }

		    if (bd.PipelineLayout == .Null)
		    {
		        // Constants: we are using 'vec2 offset' and 'vec2 scale' instead of a full 3d projection matrix
		        VkPushConstantRange[1] push_constants;
		        push_constants[0].stageFlags = .VK_SHADER_STAGE_VERTEX_BIT;
		        push_constants[0].offset = sizeof(float) * 0;
		        push_constants[0].size = sizeof(float) * 4;
		        VkDescriptorSetLayout[1] set_layout = .( bd.DescriptorSetLayout );
		        VkPipelineLayoutCreateInfo layout_info = .();
		        layout_info.sType = .VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
		        layout_info.setLayoutCount = 1;
		        layout_info.pSetLayouts = &set_layout;
		        layout_info.pushConstantRangeCount = 1;
		        layout_info.pPushConstantRanges = &push_constants;
		        err = vkCreatePipelineLayout(v.Device, &layout_info, v.Allocator, &bd.PipelineLayout);
		        check_vk_result(err);
		    }

		    ImGui_ImplVulkan_CreatePipeline(v.Device, v.Allocator, v.PipelineCache, bd.RenderPass, v.MSAASamples, &bd.Pipeline, bd.Subpass);

		    return true;
		}

		static void    ImGui_ImplVulkan_DestroyFontUploadObjects()
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;
		    if (bd.UploadBuffer != .Null)
		    {
		        vkDestroyBuffer(v.Device, bd.UploadBuffer, v.Allocator);
		        bd.UploadBuffer = .Null;
		    }
		    if (bd.UploadBufferMemory != .Null)
		    {
		        vkFreeMemory(v.Device, bd.UploadBufferMemory, v.Allocator);
		        bd.UploadBufferMemory = .Null;
		    }
		}

		static void    ImGui_ImplVulkan_DestroyDeviceObjects()
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;
		    ImGui_ImplVulkanH_DestroyWindowRenderBuffers(v.Device, &bd.MainWindowRenderBuffers, v.Allocator);
		    ImGui_ImplVulkan_DestroyFontUploadObjects();

		    if (bd.ShaderModuleVert != .Null)     { vkDestroyShaderModule(v.Device, bd.ShaderModuleVert, v.Allocator); bd.ShaderModuleVert = .Null; }
		    if (bd.ShaderModuleFrag != .Null)     { vkDestroyShaderModule(v.Device, bd.ShaderModuleFrag, v.Allocator); bd.ShaderModuleFrag = .Null; }
		    if (bd.FontView != .Null)             { vkDestroyImageView(v.Device, bd.FontView, v.Allocator); bd.FontView = .Null; }
		    if (bd.FontImage != .Null)            { vkDestroyImage(v.Device, bd.FontImage, v.Allocator); bd.FontImage = .Null; }
		    if (bd.FontMemory != .Null)           { vkFreeMemory(v.Device, bd.FontMemory, v.Allocator); bd.FontMemory = .Null; }
		    if (bd.FontSampler != .Null)          { vkDestroySampler(v.Device, bd.FontSampler, v.Allocator); bd.FontSampler = .Null; }
		    if (bd.DescriptorSetLayout != .Null)  { vkDestroyDescriptorSetLayout(v.Device, bd.DescriptorSetLayout, v.Allocator); bd.DescriptorSetLayout = .Null; }
		    if (bd.PipelineLayout != .Null)       { vkDestroyPipelineLayout(v.Device, bd.PipelineLayout, v.Allocator); bd.PipelineLayout = .Null; }
		    if (bd.Pipeline != .Null)             { vkDestroyPipeline(v.Device, bd.Pipeline, v.Allocator); bd.Pipeline = .Null; }
		}

		static bool    ImGui_ImplVulkan_Init(ImGui_ImplVulkan_InitInfo* info, VkRenderPass render_pass)
		{
		    //Debug.Assert(g_FunctionsLoaded, "Need to call ImGui_ImplVulkan_LoadFunctions() if IMGUI_IMPL_VULKAN_NO_PROTOTYPES or VK_NO_PROTOTYPES are set!");

		    ImGui.IO* io = ImGui.GetIO();
		    Debug.Assert(io.BackendRendererUserData == null, "Already initialized a renderer backend!");

		    // Setup backend capabilities flags
		    ImGui_ImplVulkan_Data* bd = new ImGui_ImplVulkan_Data();
		    io.BackendRendererUserData = (void*)bd;
		    io.BackendRendererName = "imgui_impl_vulkan";
		    io.BackendFlags |= .RendererHasVtxOffset;  // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.

		    Debug.Assert(info.Instance != .Null);
		    Debug.Assert(info.PhysicalDevice != .Null);
		    Debug.Assert(info.Device != .Null);
		    Debug.Assert(info.Queue != .Null);
		    Debug.Assert(info.DescriptorPool != .Null);
		    Debug.Assert(info.MinImageCount >= 2);
		    Debug.Assert(info.ImageCount >= info.MinImageCount);
		    Debug.Assert(render_pass != .Null);

		    bd.VulkanInitInfo = *info;
		    bd.RenderPass = render_pass;
		    bd.Subpass = info.Subpass;

		    ImGui_ImplVulkan_CreateDeviceObjects();

		    return true;
		}

		static void ImGui_ImplVulkan_Shutdown()
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    Debug.Assert(bd != null, "No renderer backend to shutdown, or already shutdown?");
		    ImGui.IO* io = ImGui.GetIO();

		    ImGui_ImplVulkan_DestroyDeviceObjects();
		    io.BackendRendererName = null;
		    io.BackendRendererUserData = null;
		    delete bd;
		}

		static void ImGui_ImplVulkan_NewFrame()
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    Debug.Assert(bd != null, "Did you call ImGui_ImplVulkan_Init()?");
		}

		static void ImGui_ImplVulkan_SetMinImageCount(uint32 min_image_count)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    Debug.Assert(min_image_count >= 2);
		    if (bd.VulkanInitInfo.MinImageCount == min_image_count)
		        return;

		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;
		    VkResult err = vkDeviceWaitIdle(v.Device);
		    check_vk_result(err);
		    ImGui_ImplVulkanH_DestroyWindowRenderBuffers(v.Device, &bd.MainWindowRenderBuffers, v.Allocator);
		    bd.VulkanInitInfo.MinImageCount = min_image_count;
		}

		// Register a texture
		// FIXME: This is experimental in the sense that we are unsure how to best design/tackle this problem, please post to https://github.com/ocornut/imgui/pull/914 if you have suggestions.
		static VkDescriptorSet ImGui_ImplVulkan_AddTexture(VkSampler sampler, VkImageView image_view, VkImageLayout image_layout)
		{
		    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
		    ImGui_ImplVulkan_InitInfo* v = &bd.VulkanInitInfo;

		    // Create Descriptor Set:
		    VkDescriptorSet descriptor_set = ?;
		    {
		        VkDescriptorSetAllocateInfo alloc_info = .();
		        alloc_info.sType = .VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
		        alloc_info.descriptorPool = v.DescriptorPool;
		        alloc_info.descriptorSetCount = 1;
		        alloc_info.pSetLayouts = &bd.DescriptorSetLayout;
		        VkResult err = vkAllocateDescriptorSets(v.Device, &alloc_info, &descriptor_set);
		        check_vk_result(err);
		    }

		    // Update the Descriptor Set:
		    {
		        VkDescriptorImageInfo[1] desc_image;
		        desc_image[0].sampler = sampler;
		        desc_image[0].imageView = image_view;
		        desc_image[0].imageLayout = image_layout;
		        VkWriteDescriptorSet[1] write_desc;
		        write_desc[0].sType = .VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
		        write_desc[0].dstSet = descriptor_set;
		        write_desc[0].descriptorCount = 1;
		        write_desc[0].descriptorType = .VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
		        write_desc[0].pImageInfo = &desc_image;
		        vkUpdateDescriptorSets(v.Device, 1, &write_desc, 0, null);
		    }
		    return descriptor_set;
		}

		//-------------------------------------------------------------------------
		// Internal / Miscellaneous Vulkan Helpers
		// (Used by example's main.cpp. Used by multi-viewport features. PROBABLY NOT used by your own app.)
		//-------------------------------------------------------------------------
		// You probably do NOT need to use or care about those functions.
		// Those functions only exist because:
		//   1) they facilitate the readability and maintenance of the multiple main.cpp examples files.
		//   2) the upcoming multi-viewport feature will need them internally.
		// Generally we avoid exposing any kind of superfluous high-level helpers in the backends,
		// but it is too much code to duplicate everywhere so we exceptionally expose them.
		//
		// Your engine/app will likely _already_ have code to setup all that stuff (swap chain, render pass, frame buffers, etc.).
		// You may read this code to learn about Vulkan, but it is recommended you use you own custom tailored code to do equivalent work.
		// (The ImGui_ImplVulkanH_XXX functions do not interact with any of the state used by the regular ImGui_ImplVulkan_XXX functions)
		//-------------------------------------------------------------------------

		static VkSurfaceFormatKHR ImGui_ImplVulkanH_SelectSurfaceFormat(VkPhysicalDevice physical_device, VkSurfaceKHR surface, VkFormat* request_formats, int request_formats_count, VkColorSpaceKHR request_color_space)
		{
		    //Debug.Assert(g_FunctionsLoaded && "Need to call ImGui_ImplVulkan_LoadFunctions() if IMGUI_IMPL_VULKAN_NO_PROTOTYPES or VK_NO_PROTOTYPES are set!");
		    Debug.Assert(request_formats != null);
		    Debug.Assert(request_formats_count > 0);

		    // Per Spec Format and View Format are expected to be the same unless VK_IMAGE_CREATE_MUTABLE_BIT was set at image creation
		    // Assuming that the default behavior is without setting this bit, there is no need for separate Swapchain image and image view format
		    // Additionally several new color spaces were introduced with Vulkan Spec v1.0.40,
		    // hence we must make sure that a format with the mostly available color space, VK_COLOR_SPACE_SRGB_NONLINEAR_KHR, is found and used.
		    uint32 avail_count = ?;
		    vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &avail_count, null);
		    ImGui.Vector<VkSurfaceFormatKHR> avail_format = ?;
		    avail_format.Resize((.)avail_count);
		    vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &avail_count, avail_format.Data);

		    // First check if only one format, VK_FORMAT_UNDEFINED, is available, which would imply that any format is available
		    if (avail_count == 1)
		    {
		        if (avail_format.Data[0].format == .VK_FORMAT_UNDEFINED)
		        {
		            VkSurfaceFormatKHR ret;
		            ret.format = request_formats[0];
		            ret.colorSpace = request_color_space;
		            return ret;
		        }
		        else
		        {
		            // No point in searching another format
		            return avail_format.Data[0];
		        }
		    }
		    else
		    {
		        // Request several formats, the first found will be used
		        for (int request_i = 0; request_i < request_formats_count; request_i++)
		            for (uint32 avail_i = 0; avail_i < avail_count; avail_i++)
		                if (avail_format.Data[avail_i].format == request_formats[request_i] && avail_format.Data[avail_i].colorSpace == request_color_space)
		                    return avail_format.Data[avail_i];

		        // If none of the requested image formats could be found, use the first available
		        return avail_format.Data[0];
		    }
		}

		static VkPresentModeKHR ImGui_ImplVulkanH_SelectPresentMode(VkPhysicalDevice physical_device, VkSurfaceKHR surface, VkPresentModeKHR* request_modes, int request_modes_count)
		{
		    //Debug.Assert(g_FunctionsLoaded && "Need to call ImGui_ImplVulkan_LoadFunctions() if IMGUI_IMPL_VULKAN_NO_PROTOTYPES or VK_NO_PROTOTYPES are set!");
		    Debug.Assert(request_modes != null);
		    Debug.Assert(request_modes_count > 0);

		    // Request a certain mode and confirm that it is available. If not use VK_PRESENT_MODE_FIFO_KHR which is mandatory
		    uint32 avail_count = 0;
		    vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &avail_count, null);
		    ImGui.Vector<VkPresentModeKHR> avail_modes = ?;
		    avail_modes.Resize((.)avail_count);
		    vkGetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &avail_count, avail_modes.Data);
		    //for (uint32_t avail_i = 0; avail_i < avail_count; avail_i++)
		    //    printf("[vulkan] avail_modes[%d] = %d\n", avail_i, avail_modes[avail_i]);

		    for (int request_i = 0; request_i < request_modes_count; request_i++)
		        for (uint32 avail_i = 0; avail_i < avail_count; avail_i++)
		            if (request_modes[request_i] == avail_modes.Data[avail_i])
		                return request_modes[request_i];

		    return .VK_PRESENT_MODE_FIFO_KHR; // Always available
		}

		static void ImGui_ImplVulkanH_CreateWindowCommandBuffers(VkPhysicalDevice physical_device, VkDevice device, ImGui_ImplVulkanH_Window* wd, uint32 queue_family, VkAllocationCallbacks* allocator)
		{
		    Debug.Assert(physical_device != .Null && device != .Null);
		    (void)physical_device;
		    (void)allocator;

		    // Create Command Buffers
		    VkResult err;
		    for (uint32 i = 0; i < wd.ImageCount; i++)
		    {
		        ImGui_ImplVulkanH_Frame* fd = &wd.Frames[i];
		        ImGui_ImplVulkanH_FrameSemaphores* fsd = &wd.FrameSemaphores[i];
		        {
		            VkCommandPoolCreateInfo info = .();
		            info.sType = .VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
		            info.flags = .VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
		            info.queueFamilyIndex = queue_family;
		            err = vkCreateCommandPool(device, &info, allocator, &fd.CommandPool);
		            check_vk_result(err);
		        }
		        {
		            VkCommandBufferAllocateInfo info = .();
		            info.sType = .VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
		            info.commandPool = fd.CommandPool;
		            info.level = .VK_COMMAND_BUFFER_LEVEL_PRIMARY;
		            info.commandBufferCount = 1;
		            err = vkAllocateCommandBuffers(device, &info, &fd.CommandBuffer);
		            check_vk_result(err);
		        }
		        {
		            VkFenceCreateInfo info = .();
		            info.sType = .VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
		            info.flags = .VK_FENCE_CREATE_SIGNALED_BIT;
		            err = vkCreateFence(device, &info, allocator, &fd.Fence);
		            check_vk_result(err);
		        }
		        {
		            VkSemaphoreCreateInfo info = .();
		            info.sType = .VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
		            err = vkCreateSemaphore(device, &info, allocator, &fsd.ImageAcquiredSemaphore);
		            check_vk_result(err);
		            err = vkCreateSemaphore(device, &info, allocator, &fsd.RenderCompleteSemaphore);
		            check_vk_result(err);
		        }
		    }
		}

		static int ImGui_ImplVulkanH_GetMinImageCountFromPresentMode(VkPresentModeKHR present_mode)
		{
		    if (present_mode == .VK_PRESENT_MODE_MAILBOX_KHR)
		        return 3;
		    if (present_mode == .VK_PRESENT_MODE_FIFO_KHR || present_mode == .VK_PRESENT_MODE_FIFO_RELAXED_KHR)
		        return 2;
		    if (present_mode == .VK_PRESENT_MODE_IMMEDIATE_KHR)
		        return 1;
		    return 1;
		}

		// Also destroy old swap chain and in-flight frames data, if any.
		static void ImGui_ImplVulkanH_CreateWindowSwapChain(VkPhysicalDevice physical_device, VkDevice device, ImGui_ImplVulkanH_Window* wd, VkAllocationCallbacks* allocator, int w, int h, uint32 min_image_count)
		{
			var min_image_count;

		    VkResult err;
		    VkSwapchainKHR old_swapchain = wd.Swapchain;
		    wd.Swapchain = .Null;
		    err = vkDeviceWaitIdle(device);
		    check_vk_result(err);

		    // We don't use ImGui_ImplVulkanH_DestroyWindow() because we want to preserve the old swapchain to create the new one.
		    // Destroy old Framebuffer
		    for (uint32 i = 0; i < wd.ImageCount; i++)
		    {
		        ImGui_ImplVulkanH_DestroyFrame(device, &wd.Frames[i], allocator);
		        ImGui_ImplVulkanH_DestroyFrameSemaphores(device, &wd.FrameSemaphores[i], allocator);
		    }
		    delete wd.Frames;
		    delete wd.FrameSemaphores;
		    wd.Frames = null;
		    wd.FrameSemaphores = null;
		    wd.ImageCount = 0;
		    if (wd.RenderPass != .Null)
		        vkDestroyRenderPass(device, wd.RenderPass, allocator);
		    if (wd.Pipeline != .Null)
		        vkDestroyPipeline(device, wd.Pipeline, allocator);

		    // If min image count was not specified, request different count of images dependent on selected present mode
		    if (min_image_count == 0)
		        min_image_count = (.) ImGui_ImplVulkanH_GetMinImageCountFromPresentMode(wd.PresentMode);

		    // Create Swapchain
		    {
		        VkSwapchainCreateInfoKHR info = .();
		        info.sType = .VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
		        info.surface = wd.Surface;
		        info.minImageCount = min_image_count;
		        info.imageFormat = wd.SurfaceFormat.format;
		        info.imageColorSpace = wd.SurfaceFormat.colorSpace;
		        info.imageArrayLayers = 1;
		        info.imageUsage = .VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		        info.imageSharingMode = .VK_SHARING_MODE_EXCLUSIVE;           // Assume that graphics family == present family
		        info.preTransform = .VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
		        info.compositeAlpha = .VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
		        info.presentMode = wd.PresentMode;
		        info.clipped = VK_TRUE;
		        info.oldSwapchain = old_swapchain;
		        VkSurfaceCapabilitiesKHR cap = ?;
		        err = vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, wd.Surface, &cap);
		        check_vk_result(err);
		        if (info.minImageCount < cap.minImageCount)
		            info.minImageCount = cap.minImageCount;
		        else if (cap.maxImageCount != 0 && info.minImageCount > cap.maxImageCount)
		            info.minImageCount = cap.maxImageCount;

		        if (cap.currentExtent.width == 0xffffffff)
		        {
		            info.imageExtent.width = (.) (wd.Width = w);
		            info.imageExtent.height = (.) (wd.Height = h);
		        }
		        else
		        {
		            info.imageExtent.width = (.) (wd.Width = cap.currentExtent.width);
		            info.imageExtent.height = (.) (wd.Height = cap.currentExtent.height);
		        }
		        err = vkCreateSwapchainKHR(device, &info, allocator, &wd.Swapchain);
		        check_vk_result(err);
		        err = vkGetSwapchainImagesKHR(device, wd.Swapchain, &wd.ImageCount, null);
		        check_vk_result(err);
		        VkImage[16] backbuffers = .();
		        Debug.Assert(wd.ImageCount >= min_image_count);
		        Debug.Assert(wd.ImageCount < backbuffers.Count);
		        err = vkGetSwapchainImagesKHR(device, wd.Swapchain, &wd.ImageCount, &backbuffers);
		        check_vk_result(err);

		        Debug.Assert(wd.Frames == null);
		        wd.Frames = (ImGui_ImplVulkanH_Frame*)new uint8[sizeof(ImGui_ImplVulkanH_Frame) * wd.ImageCount]*;
		        wd.FrameSemaphores = (ImGui_ImplVulkanH_FrameSemaphores*)new uint8[sizeof(ImGui_ImplVulkanH_FrameSemaphores) * wd.ImageCount]*;
		        Internal.MemSet(wd.Frames, 0, sizeof(ImGui_ImplVulkanH_Frame) * wd.ImageCount);
		        Internal.MemSet(wd.FrameSemaphores, 0, sizeof(ImGui_ImplVulkanH_FrameSemaphores) * wd.ImageCount);
		        for (uint32 i = 0; i < wd.ImageCount; i++)
		            wd.Frames[i].Backbuffer = backbuffers[i];
		    }
		    if (old_swapchain != .Null)
		        vkDestroySwapchainKHR(device, old_swapchain, allocator);

		    // Create the Render Pass
		    {
		        VkAttachmentDescription attachment = .();
		        attachment.format = wd.SurfaceFormat.format;
		        attachment.samples = .VK_SAMPLE_COUNT_1_BIT;
		        attachment.loadOp = wd.ClearEnable ? .VK_ATTACHMENT_LOAD_OP_CLEAR : .VK_ATTACHMENT_LOAD_OP_DONT_CARE;
		        attachment.storeOp = .VK_ATTACHMENT_STORE_OP_STORE;
		        attachment.stencilLoadOp = .VK_ATTACHMENT_LOAD_OP_DONT_CARE;
		        attachment.stencilStoreOp = .VK_ATTACHMENT_STORE_OP_DONT_CARE;
		        attachment.initialLayout = .VK_IMAGE_LAYOUT_UNDEFINED;
		        attachment.finalLayout = .VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
		        VkAttachmentReference color_attachment = .();
		        color_attachment.attachment = 0;
		        color_attachment.layout = .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
		        VkSubpassDescription subpass = .();
		        subpass.pipelineBindPoint = .VK_PIPELINE_BIND_POINT_GRAPHICS;
		        subpass.colorAttachmentCount = 1;
		        subpass.pColorAttachments = &color_attachment;
		        VkSubpassDependency dependency = .();
		        dependency.srcSubpass = VK_SUBPASS_EXTERNAL;
		        dependency.dstSubpass = 0;
		        dependency.srcStageMask = .VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
		        dependency.dstStageMask = .VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
		        dependency.srcAccessMask = 0;
		        dependency.dstAccessMask = .VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
		        VkRenderPassCreateInfo info = .();
		        info.sType = .VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
		        info.attachmentCount = 1;
		        info.pAttachments = &attachment;
		        info.subpassCount = 1;
		        info.pSubpasses = &subpass;
		        info.dependencyCount = 1;
		        info.pDependencies = &dependency;
		        err = vkCreateRenderPass(device, &info, allocator, &wd.RenderPass);
		        check_vk_result(err);

		        // We do not create a pipeline by default as this is also used by examples' main.cpp,
		        // but secondary viewport in multi-viewport mode may want to create one with:
		        //ImGui_ImplVulkan_CreatePipeline(device, allocator, VK_NULL_HANDLE, wd.RenderPass, VK_SAMPLE_COUNT_1_BIT, &wd.Pipeline, bd.Subpass);
		    }

		    // Create The Image Views
		    {
		        VkImageViewCreateInfo info = .();
		        info.sType = .VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		        info.viewType = .VK_IMAGE_VIEW_TYPE_2D;
		        info.format = wd.SurfaceFormat.format;
		        info.components.r = .VK_COMPONENT_SWIZZLE_R;
		        info.components.g = .VK_COMPONENT_SWIZZLE_G;
		        info.components.b = .VK_COMPONENT_SWIZZLE_B;
		        info.components.a = .VK_COMPONENT_SWIZZLE_A;
		        VkImageSubresourceRange image_range = .() { aspectMask = .VK_IMAGE_ASPECT_COLOR_BIT, baseMipLevel = 0, levelCount = 1, baseArrayLayer = 0, layerCount = 1 };
		        info.subresourceRange = image_range;
		        for (uint32 i = 0; i < wd.ImageCount; i++)
		        {
		            ImGui_ImplVulkanH_Frame* fd = &wd.Frames[i];
		            info.image = fd.Backbuffer;
		            err = vkCreateImageView(device, &info, allocator, &fd.BackbufferView);
		            check_vk_result(err);
		        }
		    }

		    // Create Framebuffer
		    {
		        VkImageView[1] attachment;
		        VkFramebufferCreateInfo info = .();
		        info.sType = .VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
		        info.renderPass = wd.RenderPass;
		        info.attachmentCount = 1;
		        info.pAttachments = &attachment;
		        info.width = (.) wd.Width;
		        info.height = (.) wd.Height;
		        info.layers = 1;
		        for (uint32 i = 0; i < wd.ImageCount; i++)
		        {
		            ImGui_ImplVulkanH_Frame* fd = &wd.Frames[i];
		            attachment[0] = fd.BackbufferView;
		            err = vkCreateFramebuffer(device, &info, allocator, &fd.Framebuffer);
		            check_vk_result(err);
		        }
		    }
		}

		// Create or resize window
		static void ImGui_ImplVulkanH_CreateOrResizeWindow(VkInstance instance, VkPhysicalDevice physical_device, VkDevice device, ImGui_ImplVulkanH_Window* wd, uint32 queue_family, VkAllocationCallbacks* allocator, int width, int height, uint32 min_image_count)
		{
		    //Debug.Assert(g_FunctionsLoaded && "Need to call ImGui_ImplVulkan_LoadFunctions() if IMGUI_IMPL_VULKAN_NO_PROTOTYPES or VK_NO_PROTOTYPES are set!");
		    (void)instance;
		    ImGui_ImplVulkanH_CreateWindowSwapChain(physical_device, device, wd, allocator, width, height, min_image_count);
		    ImGui_ImplVulkanH_CreateWindowCommandBuffers(physical_device, device, wd, queue_family, allocator);
		}

		static void ImGui_ImplVulkanH_DestroyWindow(VkInstance instance, VkDevice device, ImGui_ImplVulkanH_Window* wd, VkAllocationCallbacks* allocator)
		{
		    vkDeviceWaitIdle(device); // FIXME: We could wait on the Queue if we had the queue in wd. (otherwise VulkanH functions can't use globals)
		    //vkQueueWaitIdle(bd.Queue);

		    for (uint32 i = 0; i < wd.ImageCount; i++)
		    {
		        ImGui_ImplVulkanH_DestroyFrame(device, &wd.Frames[i], allocator);
		        ImGui_ImplVulkanH_DestroyFrameSemaphores(device, &wd.FrameSemaphores[i], allocator);
		    }
		    delete wd.Frames;
		    delete wd.FrameSemaphores;
		    wd.Frames = null;
		    wd.FrameSemaphores = null;
		    vkDestroyPipeline(device, wd.Pipeline, allocator);
		    vkDestroyRenderPass(device, wd.RenderPass, allocator);
		    vkDestroySwapchainKHR(device, wd.Swapchain, allocator);
		    vkDestroySurfaceKHR(instance, wd.Surface, allocator);

		    *wd = ImGui_ImplVulkanH_Window();
		}

		static void ImGui_ImplVulkanH_DestroyFrame(VkDevice device, ImGui_ImplVulkanH_Frame* fd, VkAllocationCallbacks* allocator)
		{
		    vkDestroyFence(device, fd.Fence, allocator);
		    vkFreeCommandBuffers(device, fd.CommandPool, 1, &fd.CommandBuffer);
		    vkDestroyCommandPool(device, fd.CommandPool, allocator);
		    fd.Fence = .Null;
		    fd.CommandBuffer = .Null;
		    fd.CommandPool = .Null;

		    vkDestroyImageView(device, fd.BackbufferView, allocator);
		    vkDestroyFramebuffer(device, fd.Framebuffer, allocator);
		}

		static void ImGui_ImplVulkanH_DestroyFrameSemaphores(VkDevice device, ImGui_ImplVulkanH_FrameSemaphores* fsd, VkAllocationCallbacks* allocator)
		{
		    vkDestroySemaphore(device, fsd.ImageAcquiredSemaphore, allocator);
		    vkDestroySemaphore(device, fsd.RenderCompleteSemaphore, allocator);
		    fsd.ImageAcquiredSemaphore = fsd.RenderCompleteSemaphore = .Null;
		}

		static void ImGui_ImplVulkanH_DestroyFrameRenderBuffers(VkDevice device, ImGui_ImplVulkanH_FrameRenderBuffers* buffers, VkAllocationCallbacks* allocator)
		{
		    if (buffers.VertexBuffer != .Null) { vkDestroyBuffer(device, buffers.VertexBuffer, allocator); buffers.VertexBuffer = .Null; }
		    if (buffers.VertexBufferMemory != .Null) { vkFreeMemory(device, buffers.VertexBufferMemory, allocator); buffers.VertexBufferMemory = .Null; }
		    if (buffers.IndexBuffer != .Null) { vkDestroyBuffer(device, buffers.IndexBuffer, allocator); buffers.IndexBuffer = .Null; }
		    if (buffers.IndexBufferMemory != .Null) { vkFreeMemory(device, buffers.IndexBufferMemory, allocator); buffers.IndexBufferMemory = .Null; }
		    buffers.VertexBufferSize = 0;
		    buffers.IndexBufferSize = 0;
		}

		static void ImGui_ImplVulkanH_DestroyWindowRenderBuffers(VkDevice device, ImGui_ImplVulkanH_WindowRenderBuffers* buffers, VkAllocationCallbacks* allocator)
		{
		    for (uint32 n = 0; n < buffers.Count; n++)
		        ImGui_ImplVulkanH_DestroyFrameRenderBuffers(device, &buffers.FrameRenderBuffers[n], allocator);
		    delete buffers.FrameRenderBuffers;
		    buffers.FrameRenderBuffers = null;
		    buffers.Index = 0;
		    buffers.Count = 0;
		}
	}
}