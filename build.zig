const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const vma_config = @import("vma_config.zig");

fn getConfigArgs(comptime config: vma_config.Config) []const []const u8 {
    comptime {
        @setEvalBranchQuota(100000);
        var args: []const []const u8 = &[_][]const u8 {
            std.fmt.comptimePrint("-DVMA_VULKAN_VERSION={}", .{ config.vulkanVersion }),
            std.fmt.comptimePrint("-DVMA_DEDICATED_ALLOCATION={}", .{ @boolToInt(config.dedicatedAllocation)}),
            std.fmt.comptimePrint("-DVMA_BIND_MEMORY2={}", .{ @boolToInt(config.bindMemory2)}),
            std.fmt.comptimePrint("-DVMA_MEMORY_BUDGET={}", .{ @boolToInt(config.memoryBudget)}),
            std.fmt.comptimePrint("-DVMA_STATIC_VULKAN_FUNCTIONS={}", .{ @boolToInt(config.staticVulkanFunctions)}),
            std.fmt.comptimePrint("-DVMA_STATS_STRING_ENABLED={}", .{ @boolToInt(config.statsStringEnabled)}),
        };
        if (config.debugInitializeAllocations) |value| {
            args = args ++ &[_][]const u8 { std.fmt.comptimePrint(
                "-DVMA_DEBUG_INITIALIZE_ALLOCATIONS={}",
                .{ @boolToInt(value) },
            ) };
        }
        if (config.debugMargin) |value| {
            args = args ++ &[_][]const u8 { std.fmt.comptimePrint(
                "-DVMA_DEBUG_MARGIN={}",
                .{ value },
            ) };
        }
        if (config.debugDetectCorruption) |value| {
            args = args ++ &[_][]const u8 { std.fmt.comptimePrint(
                "-DVMA_DEBUG_DETECT_CORRUPTION={}",
                .{ @boolToInt(value) },
            ) };
        }
        if (config.recordingEnabled) |value| {
            args = args ++ &[_][]const u8 { std.fmt.comptimePrint(
                "-DVMA_RECORDING_ENABLED={}",
                .{ @boolToInt(value) },
            ) };
        }
        if (config.debugMinBufferImageGranularity) |value| {
            args = args ++ &[_][]const u8 { std.fmt.comptimePrint(
                "-DVMA_DEBUG_MIN_BUFFER_IMAGE_GRANULARITY={}",
                .{ value },
            ) };
        }
        if (config.debugGlobalMutex) |value| {
            args = args ++ &[_][]const u8 { std.fmt.comptimePrint(
                "-DVMA_DEBUG_GLOBAL_MUTEX={}",
                .{ @boolToInt(value) },
            ) };
        }
        if (config.useStlContainers) |value| {
            args = args ++ &[_][]const u8 { std.fmt.comptimePrint(
                "-DVMA_USE_STL_CONTAINERS={}",
                .{ @boolToInt(value) },
            ) };
        }
        if (config.useStlSharedMutex) |value| {
            args = args ++ &[_][]const u8 { std.fmt.comptimePrint(
                "-DVMA_USE_STL_SHARED_MUTEX={}",
                .{ @boolToInt(value) },
            ) };
        }

        return args;
    }
}

fn joinFromThisDir(allocator: std.mem.Allocator, rel_path: []const u8) []const u8 {
    const dirname = std.fs.path.dirname(@src().file) orelse ".";
    return std.fs.path.join(allocator, &.{ dirname, rel_path }) catch unreachable;
}

pub fn linkVma(object: *LibExeObjStep, vk_root_file: []const u8, mode: std.builtin.Mode, target: std.zig.CrossTarget) void {
    const commonArgs = &[_][]const u8 { "-std=c++14" };
    const releaseArgs = &[_][]const u8 { } ++ commonArgs ++ comptime getConfigArgs(vma_config.releaseConfig);
    const debugArgs = &[_][]const u8 { } ++ commonArgs ++ comptime getConfigArgs(vma_config.debugConfig);
    const allocator = object.builder.allocator;
    const args = if (mode == .Debug) debugArgs else releaseArgs;

    object.addCSourceFile(joinFromThisDir(allocator, "VulkanMemoryAllocator/src/VmaUsage.cpp"), args);
    object.addIncludeDir(joinFromThisDir(allocator, "VulkanMemoryAllocator/src/"));
    object.addPackage(std.build.Pkg{
        .name = "vma",
        .source = .{
            .path = joinFromThisDir(allocator, "vma.zig"),
        },
        .dependencies = &[_]std.build.Pkg{.{
            .name = "vk",
            .source = .{
                .path = vk_root_file,
            },
        }},
    });
    object.linkLibC();
    if (target.getAbi() != .msvc) {
        // MSVC can't link libc++, it causes duplicate symbol errors.
        // But it's needed for other targets.
        object.linkSystemLibrary("c++");
    }
}

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addTest("test/test.zig");
    lib.addPackagePath("vk", "test/vulkan_core.zig");
    linkVma(lib, "test/vulkan_core.zig", mode, target);
    lib.linkSystemLibrary("test/vulkan-1");
    lib.setTarget(target);
    
    const test_step = b.step("test", "run tests");
    test_step.dependOn(&lib.step);
}
