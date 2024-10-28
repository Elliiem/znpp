const std = @import("std");

const Pair = @import("../common.zig").Pair;

const ErrorLabel = @import("../embedded.zig").ErrorLabel;
const LabeledError = @import("../embedded.zig").LabeledError;

const Value = @import("../value.zig").Value;

const Call = @import("../input.zig").Call;
const EngineCallResponse = @import("../input.zig").EngineCallResponse;

const test_call_0 = Call{
    .a = 0,
    .b = .{
        .Run = .{
            .name = "inc",
            .call = .{
                .head = .{ .start = 40400, .end = 40403 },
                .positional = &[_]Value{
                    Value{
                        .String = .{
                            .val = "0.1.2",
                            .span = .{
                                .start = 40407,
                                .end = 40415,
                            },
                        },
                    },
                },
                .named = &[_]Pair([]const u8, ?Value){
                    Pair([]const u8, ?Value){
                        .a = "major",
                        .b = Value{
                            .Bool = .{
                                .val = true,
                                .span = .{
                                    .start = 40404,
                                    .end = 40406,
                                },
                            },
                        },
                    },
                },
            },
            .input = .Empty,
        },
    },
};

const test_call_json_0 =
    \\[
    \\    0,
    \\    {
    \\        "Run": {
    \\            "name": "inc",
    \\            "call": {
    \\                "head": {
    \\                    "start": 40400,
    \\                    "end": 40403
    \\                },
    \\                "positional": [
    \\                    {
    \\                        "String": {
    \\                            "val": "0.1.2",
    \\                            "span": {
    \\                                "start": 40407,
    \\                                "end": 40415
    \\                            }
    \\                        }
    \\                    }
    \\                ],
    \\                "named": [
    \\                    [
    \\                        "major",
    \\                        {
    \\                            "Bool": {
    \\                                "val": true,
    \\                                "span": {
    \\                                    "start": 40404,
    \\                                    "end": 40406
    \\                                }
    \\                            }
    \\                        }
    \\                    ]
    \\                ]
    \\            },
    \\            "input": "Empty"
    \\        }
    \\    }
    \\]
;

test "Parse Call 0" {
    const parsed = try std.json.parseFromSlice(Call, std.testing.allocator, test_call_json_0, .{});
    defer parsed.deinit();

    try std.testing.expectEqualDeep(test_call_0, parsed.value);
}

test "Stringify Call 0" {
    const json = try std.json.stringifyAlloc(std.testing.allocator, test_call_0, .{ .whitespace = .indent_4 });
    defer std.testing.allocator.free(json);

    try std.testing.expectEqualStrings(test_call_json_0, json);
}

const test_call_1 = Call{
    .a = 0,
    .b = .{
        .CustomValueOp = .{
            .FollowPathInt = .{
                .val = .{
                    .item = .{
                        .name = "version",
                        .data = .{
                            .value = &[_]u8{ 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0 },
                        },
                    },
                    .span = .{
                        .start = 90,
                        .end = 96,
                    },
                },
                .item = 0,
                .span = .{
                    .start = 320,
                    .end = 321,
                },
            },
        },
    },
};

const test_call_json_1 =
    \\[
    \\    0,
    \\    {
    \\        "CustomValueOp": [
    \\            {
    \\                "item": {
    \\                    "name": "version",
    \\                    "data": [
    \\                        0,
    \\                        0,
    \\                        0,
    \\                        0,
    \\                        1,
    \\                        0,
    \\                        0,
    \\                        0,
    \\                        2,
    \\                        0,
    \\                        0,
    \\                        0
    \\                    ]
    \\                },
    \\                "span": {
    \\                    "start": 90,
    \\                    "end": 96
    \\                }
    \\            },
    \\            {
    \\                "FollowPathInt": {
    \\                    "item": 0,
    \\                    "span": {
    \\                        "start": 320,
    \\                        "end": 321
    \\                    }
    \\                }
    \\            }
    \\        ]
    \\    }
    \\]
;

test "Parse Call 1" {
    const parsed = try std.json.parseFromSlice(Call, std.testing.allocator, test_call_json_1, .{});
    defer parsed.deinit();

    try std.testing.expectEqualDeep(test_call_1, parsed.value);
}

test "Stringify Call 1" {
    const json = try std.json.stringifyAlloc(std.testing.allocator, test_call_1, .{ .whitespace = .indent_4 });
    defer std.testing.allocator.free(json);

    try std.testing.expectEqualStrings(test_call_json_1, json);
}

const test_response_0 = EngineCallResponse{ .a = 0, .b = .{
    .Error = .{
        .msg = "The connection closed.",
        .labels = &[_]ErrorLabel{},
        .code = null,
        .url = null,
        .help = null,
        .inner = &[_]LabeledError{},
    },
} };

const test_response_json_0 =
    \\[
    \\    0,
    \\    {
    \\        "Error": {
    \\            "LabeledError": {
    \\                "msg": "The connection closed.",
    \\                "labels": [],
    \\                "code": null,
    \\                "url": null,
    \\                "help": null,
    \\                "inner": []
    \\            }
    \\        }
    \\    }
    \\]
;

test "Parse EngineCallResponse 0" {
    const parsed = try std.json.parseFromSlice(EngineCallResponse, std.testing.allocator, test_response_json_0, .{});
    defer parsed.deinit();

    try std.testing.expectEqualDeep(test_response_0, parsed.value);
}

test "Stringify CallParameter 0" {
    const json = try std.json.stringifyAlloc(std.testing.allocator, test_response_0, .{ .whitespace = .indent_4 });
    defer std.testing.allocator.free(json);

    try std.testing.expectEqualStrings(test_response_json_0, json);
}

const test_response_1 = EngineCallResponse{
    .a = 0,
    .b = .{
        .PipelineHeader = .{
            .ListStream = .{
                .id = 23,
                .span = .{
                    .start = 8081,
                    .end = 8087,
                },
            },
        },
    },
};

const test_response_json_1 =
    \\[
    \\    0,
    \\    {
    \\        "ListStream": {
    \\            "id": 23,
    \\            "span": {
    \\                "start": 8081,
    \\                "end": 8087
    \\            }
    \\        }
    \\    }
    \\]
;

test "Parse EngineCallResponse 1" {
    const parsed = try std.json.parseFromSlice(EngineCallResponse, std.testing.allocator, test_response_json_1, .{});
    defer parsed.deinit();

    try std.testing.expectEqualDeep(test_response_1, parsed.value);
}

test "Stringify CallParameter 1" {
    const json = try std.json.stringifyAlloc(std.testing.allocator, test_response_1, .{ .whitespace = .indent_4 });
    defer std.testing.allocator.free(json);

    try std.testing.expectEqualStrings(test_response_json_1, json);
}
