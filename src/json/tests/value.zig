const std = @import("std");

const Range = @import("../value.zig").Range;

const test_range_0 = Range{
    .val = .{
        .IntRange = .{
            .start = 0,
            .step = 1,
            .end = .{
                .Unbounded = undefined,
            },
        },
    },
    .span = .{
        .start = 1380,
        .end = 1383,
    },
};

const test_range_json_0 =
    \\{
    \\    "val": {
    \\        "IntRange": {
    \\            "start": 0,
    \\            "step": 1,
    \\            "end": "Unbounded"
    \\        }
    \\    },
    \\    "span": {
    \\        "start": 1380,
    \\        "end": 1383
    \\    }
    \\}
;

test "Parse Range 0" {
    const parsed = try std.json.parseFromSlice(Range, std.testing.allocator, test_range_json_0, .{});
    defer parsed.deinit();

    try std.testing.expectEqualDeep(test_range_0, parsed.value);
}

test "Stringify Range 0" {
    const json = try std.json.stringifyAlloc(std.testing.allocator, test_range_0, .{ .whitespace = .indent_4 });
    defer std.testing.allocator.free(json);

    try std.testing.expectEqualStrings(test_range_json_0, json);
}

const test_range_1 = Range{
    .val = .{
        .IntRange = .{
            .start = 7,
            .step = 1,
            .end = .{
                .Included = 10,
            },
        },
    },
    .span = .{
        .start = 1380,
        .end = 1385,
    },
};

const test_range_json_1 =
    \\{
    \\    "val": {
    \\        "IntRange": {
    \\            "start": 7,
    \\            "step": 1,
    \\            "end": {
    \\                "Included": 10
    \\            }
    \\        }
    \\    },
    \\    "span": {
    \\        "start": 1380,
    \\        "end": 1385
    \\    }
    \\}
;

test "Parse Range 1" {
    const parsed = try std.json.parseFromSlice(Range, std.testing.allocator, test_range_json_1, .{});
    defer parsed.deinit();

    try std.testing.expectEqualDeep(test_range_1, parsed.value);
}

test "Stringify Range 1" {
    const json = try std.json.stringifyAlloc(std.testing.allocator, test_range_1, .{ .whitespace = .indent_4 });
    defer std.testing.allocator.free(json);

    try std.testing.expectEqualStrings(test_range_json_1, json);
}

const test_range_2 = Range{
    .val = .{
        .IntRange = .{
            .start = 7,
            .step = 1,
            .end = .{
                .Excluded = 10,
            },
        },
    },
    .span = .{
        .start = 1380,
        .end = 1386,
    },
};

const test_range_json_2 =
    \\{
    \\    "val": {
    \\        "IntRange": {
    \\            "start": 7,
    \\            "step": 1,
    \\            "end": {
    \\                "Excluded": 10
    \\            }
    \\        }
    \\    },
    \\    "span": {
    \\        "start": 1380,
    \\        "end": 1386
    \\    }
    \\}
;

test "Parse Range 2" {
    const parsed = try std.json.parseFromSlice(Range, std.testing.allocator, test_range_json_2, .{});
    defer parsed.deinit();

    try std.testing.expectEqualDeep(test_range_2, parsed.value);
}

test "Stringify Range 2" {
    const json = try std.json.stringifyAlloc(std.testing.allocator, test_range_2, .{ .whitespace = .indent_4 });
    defer std.testing.allocator.free(json);

    try std.testing.expectEqualStrings(test_range_json_2, json);
}

const test_range_3 = Range{
    .val = .{
        .IntRange = .{
            .start = 0,
            .step = 64,
            .end = .{
                .Included = 128,
            },
        },
    },
    .span = .{
        .start = 1380,
        .end = 1390,
    },
};

const test_range_json_3 =
    \\{
    \\    "val": {
    \\        "IntRange": {
    \\            "start": 0,
    \\            "step": 64,
    \\            "end": {
    \\                "Included": 128
    \\            }
    \\        }
    \\    },
    \\    "span": {
    \\        "start": 1380,
    \\        "end": 1390
    \\    }
    \\}
;

test "Parse Range 3" {
    const parsed = try std.json.parseFromSlice(Range, std.testing.allocator, test_range_json_3, .{});
    defer parsed.deinit();

    try std.testing.expectEqualDeep(test_range_3, parsed.value);
}

test "Stringify Range 3" {
    const json = try std.json.stringifyAlloc(std.testing.allocator, test_range_3, .{ .whitespace = .indent_4 });
    defer std.testing.allocator.free(json);

    try std.testing.expectEqualStrings(test_range_json_3, json);
}

//  TODO: Record

//  TODO: CellPath
