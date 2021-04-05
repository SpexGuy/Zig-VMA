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
    });
    defer allocator.destroy();
}

// compile everything

comptime {
    @setEvalBranchQuota(10000);
    refAllDeclsRecursive(vma);
}

fn refAllDeclsRecursive(comptime T: type) void {
    comptime {
        switch (@typeInfo(T)) {
            .Struct => |info| refDeclsList(T, info.decls),
            .Union => |info| refDeclsList(T, info.decls),
            .Enum => |info| refDeclsList(T, info.decls),
            .Opaque => |info| refDeclsList(T, info.decls),
            else => {},
        }
    }
}

fn refDeclsList(comptime T: type, comptime decls: []const std.builtin.TypeInfo.Declaration) void {
    for (decls) |decl| {
        if (decl.is_pub) {
            _ = @field(T, decl.name);
            switch (decl.data) {
                .Type => |SubType| refAllDeclsRecursive(SubType),
                .Var => |Type| {},
                .Fn => |fn_decl| {},
            }
        }
    }
}
