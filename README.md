# Vulkan backend for Dear ImGui in Beef
Ported from the [official Vulkan backend](https://github.com/ocornut/imgui/blob/master/backends/imgui_impl_vulkan.h) based on commit [5854da10e664312e51acec618267d06b1294ac0b](https://github.com/ocornut/imgui/tree/5854da10e664312e51acec618267d06b1294ac0b).

## Usage
Clone the project into BeefLibs, then in the IDE, right click your workspace and go Add From Installed > ImGuiImplVulkan.  
Requires the [Bulkan](https://github.com/jayrulez/Bulkan) library.  
  
Example:
```beef
using ImGui;

namespace Foo {
    class Bar {
        public static void Main() {
            ImGuiImplVulkan.InitInfo info = .() {
                // Fill with Vulkan data
            };

            ImGuiImplVulkan.Init(&info, renderPass);

            // Upload fonts
            {
                // Begin command buffer
                ImGuiImplVulkan.CreateFontsTexture(commandBuffer);
                // End command buffer

                VkSubmitInfo submitInfo = .() {
                    commandBufferCount = 1,
                    pCommandBuffers = commandBuffer
                };
                vkQueueSubmit(queue, 1, &submitInfo, .Null);
                vkDeviceWaitIdle(device);

                ImGuiImplVulkan.DestroyFontUploadObjects();
            }

            ...

            while (true) {
                ...
                ImGuiImplVulkan.NewFrame();
                ...
                ImGui.Render();
                ImGuiImplVulkan.RenderDrawData(ImGui.GetDrawData(), commandBuffer);
                ...
            }

            ...

            ImGuiImplVulkan.Shutdown();
        }
    }
}
```