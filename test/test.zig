const vk = @import("vk");
const vma = @import("vma");
const std = @import("std");

test "vma" {
    const instance = try vk.CreateInstance(.{}, null);
    defer vk.DestroyInstance(instance, null);

    var physDevice: vk.PhysicalDevice = .Null;
    _ = try vk.EnumeratePhysicalDevices(instance, @as(*[1]vk.PhysicalDevice, &physDevice));
    if (physDevice == .Null) return error.NoDevicesAvailable;

    const device = try vk.CreateDevice(physDevice, .{
        .queueCreateInfoCount = 1,
        .pQueueCreateInfos = &[_]vk.DeviceQueueCreateInfo{ .{
            .queueFamilyIndex = 0,
            .queueCount = 1,
            .pQueuePriorities = &[_]f32{ 1.0 },
        } },
    }, null);
    defer vk.DestroyDevice(device, null);

    const functions = vma.VulkanFunctions.init(instance, device, vk.vkGetInstanceProcAddr);

    const allocator = try vma.Allocator.create(.{
        .instance = instance,
        .physicalDevice = physDevice,
        .device = device,
        .frameInUseCount = 3,
        .pVulkanFunctions = &functions,
    });
    defer allocator.destroy();
}

test "Reference everything" {
    @setEvalBranchQuota(10000);
    std.testing.refAllDeclsRecursive(vma);
}
