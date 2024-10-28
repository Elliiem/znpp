const std = @import("std");

const StringUnion = @import("../common.zig").StringUnion;

const StringUnionBase = union(enum) {
    String: []const u8,
};

const test_string_union_json =
    \\"Foo"
;

test "Parse StringUnion" {
    const parsed = try std.json.parseFromSlice(StringUnion(StringUnionBase), std.testing.allocator, test_string_union_json, .{});
    defer parsed.deinit();
}
