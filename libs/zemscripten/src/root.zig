const std = @import("std");

extern "C" fn emmalloc_memalign(alignment: usize, size: usize) ?*anyopaque;
extern "C" fn emmalloc_realloc_try(ptr: ?*anyopaque, size: usize) ?*anyopaque;
extern "C" fn emmalloc_free(ptr: ?*anyopaque) void;

/// Zig Allocator that wraps emmalloc
/// use with linker flag -sMALLOC=emmalloc
pub const EmmallocAllocator = struct {
    const Self = @This();
    dummy: u32 = undefined,

    pub fn allocator(self: *Self) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = &alloc,
                .resize = &resize,
                .free = &free,
            },
        };
    }

    fn alloc(
        ctx: *anyopaque,
        len: usize,
        ptr_align_log2: u8,
        return_address: usize,
    ) ?[*]u8 {
        _ = ctx;
        _ = return_address;
        const ptr_align = @as(usize, 1) << @as(u5, @intCast(ptr_align_log2));
        if (!std.math.isPowerOfTwo(ptr_align)) unreachable;
        const ptr = emmalloc_memalign(ptr_align, len) orelse return null;
        return @ptrCast(ptr);
    }

    fn resize(
        ctx: *anyopaque,
        buf: []u8,
        buf_align_log2: u8,
        new_len: usize,
        return_address: usize,
    ) bool {
        _ = ctx;
        _ = return_address;
        _ = buf_align_log2;
        return emmalloc_realloc_try(buf.ptr, new_len) != null;
    }

    fn free(
        ctx: *anyopaque,
        buf: []u8,
        buf_align_log2: u8,
        return_address: usize,
    ) void {
        _ = ctx;
        _ = buf_align_log2;
        _ = return_address;
        return emmalloc_free(buf.ptr);
    }
};
