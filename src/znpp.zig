const std = @import("std");

pub const value = @import("json/value.zig");
pub const embedded = @import("json/embedded.zig");
pub const input = @import("json/input.zig");
pub const common = @import("json/common.zig");

test {
    std.testing.refAllDecls(@import("json/tests/input.zig"));
}

test {
    std.testing.refAllDecls(@import("json/tests/common.zig"));
}

test "main" {}
