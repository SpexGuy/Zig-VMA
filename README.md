# Zig-VMA

This project provides Zig bindings for the Vulkan Memory Allocator library.

## Using this project

To use this library, first copy `vma.zig`, `vma_config.zig`, and the `VulkanMemoryAllocator` folder into your project.  `vma_config.zig` contains build flags which will be used to configure the project.  It has separate configurations for debug and release builds.

Then copy the relevant parts from `build.zig` into your build file, and update them to the paths that you used for the previously copied files.

Check out [this repository](https://github.com/SpexGuy/sdltest) for an example of the library in use.
