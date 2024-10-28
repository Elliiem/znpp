const std = @import("std");

pub const value = @import("json/value.zig");
pub const embedded = @import("json/embedded.zig");
pub const input = @import("json/input.zig");

test {
    std.testing.refAllDecls(@import("json/tests/input.zig"));
}

test {
    std.testing.refAllDecls(@import("json/tests/common.zig"));
}

test "main" {
    const ordering = embedded.Ordering.Less;

    const json = try std.json.stringifyAlloc(std.testing.allocator, ordering, .{ .whitespace = .indent_4 });
    defer std.testing.allocator.free(json);
}
