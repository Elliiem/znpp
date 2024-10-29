// Serializing and Deserializing for input messages

const std = @import("std");

const Span = @import("embedded.zig").Span;
const EvaluatedCall = @import("embedded.zig").EvaluatedCall;

const Operator = @import("embedded.zig").Operator;
const LabeledError = @import("embedded.zig").LabeledError;
//  NOTE: Config is not yet implemented EngineCallResponse.Config wont work
const Config = @import("embedded.zig").Config;

const Pair = @import("common.zig").Pair;
const ByteArray = @import("common.zig").ByteArray;
const RustEnum = @import("common.zig").RustEnum;

const Value = @import("value.zig").Value;
const Record = @import("value.zig").Record;

const PipelineDataHeader = @import("stream.zig").PipelineDataHeader;
const ListStream = @import("stream.zig").ListStream;
const ByteStream = @import("stream.zig").ByteStream;

pub const Input = RustEnum(union(enum) {
    Call: PluginCall,
    EngineCallResponse: EngineCallResponse,
    Goodbye,
});

pub const PluginCall = Pair(i64, PluginCallParam);

pub const PluginCallParam = RustEnum(union(enum) {
    Metadata,
    Signature,
    Run: Run,
    CustomValueOp: CustomValueOp,
});

pub const Run = struct {
    name: []const u8,
    call: EvaluatedCall,
    input: PipelineDataHeader,
};

pub const CustomValueOp = union(enum) {
    ToBaseValue: InputCustom,
    FollowPathInt: FollowPathInt,
    FollowPathString: FollowPathString,
    PartialCmp: PartialCmp,
    Operation: Operation,
    Dropped: InputCustom,

    const InputCustomInner = struct {
        name: []const u8,
        data: ByteArray,
    };

    pub const InputCustom = struct {
        item: InputCustomInner,
        span: Span,
    };

    pub const FollowPathInt = struct {
        val: InputCustom,
        item: i64,
        span: Span,
    };

    pub const FollowPathString = struct {
        val: InputCustom,
        item: []const u8,
        span: Span,
    };

    pub const PartialCmp = struct {
        a: InputCustom,
        b: Value,
    };

    pub const Operation = struct {
        a: InputCustom,
        b: Value,
        operator: Operator,
    };

    const B = RustEnum(union(enum) {
        ToBaseValue,
        FollowPathInt: RawFollowPathInt,
        FollowPathString: RawFollowPathString,
        PartialCmp: Value,
        Operation: Pair(Operator, Value),
        Dropped,

        pub const RawFollowPathInt = struct {
            item: i64,
            span: Span,
        };

        pub const RawFollowPathString = struct {
            item: []const u8,
            span: Span,
        };
    });

    pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        const raw = try std.json.innerParse(Pair(InputCustom, B), alloc, source, options);

        switch (raw.b.val) {
            .ToBaseValue => {
                return .{
                    .ToBaseValue = raw.a,
                };
            },
            .FollowPathInt => |b| {
                return .{
                    .FollowPathInt = .{
                        .val = raw.a,
                        .item = b.item,
                        .span = b.span,
                    },
                };
            },
            .FollowPathString => |b| {
                return .{
                    .FollowPathString = .{
                        .val = raw.a,
                        .item = b.item,
                        .span = b.span,
                    },
                };
            },
            .PartialCmp => |b| {
                return .{
                    .PartialCmp = .{
                        .a = raw.a,
                        .b = b,
                    },
                };
            },
            .Operation => |b| {
                return .{
                    .Operation = .{
                        .a = raw.a,
                        .b = b.b,
                        .operator = b.a,
                    },
                };
            },
            .Dropped => {
                return .{
                    .Dropped = raw.a,
                };
            },
        }

        unreachable;
    }

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        switch (self) {
            .ToBaseValue => |value| {
                try writer.write(Pair(InputCustom, []const u8){
                    .a = value,
                    .b = "ToBaseValue",
                });
            },
            .FollowPathInt => |value| {
                try writer.write(Pair(InputCustom, B){
                    .a = value.val,
                    .b = .{
                        .val = .{
                            .FollowPathInt = .{
                                .item = value.item,
                                .span = value.span,
                            },
                        },
                    },
                });
            },
            .FollowPathString => |value| {
                try writer.write(Pair(InputCustom, B){
                    .a = value.val,
                    .b = .{
                        .val = .{
                            .FollowPathString = .{
                                .item = value.item,
                                .span = value.span,
                            },
                        },
                    },
                });
            },
            .PartialCmp => |value| {
                try writer.write(Pair(InputCustom, B){
                    .a = value.a,
                    .b = .{
                        .val = .{
                            .PartialCmp = value.b,
                        },
                    },
                });
            },
            .Operation => |value| {
                try writer.write(Pair(InputCustom, B){
                    .a = value.a,
                    .b = .{
                        .val = .{
                            .Operation = .{
                                .a = value.operator,
                                .b = value.b,
                            },
                        },
                    },
                });
            },
            .Dropped => |value| {
                try writer.write(Pair(InputCustom, []const u8){
                    .a = value,
                    .b = "Dropped",
                });
            },
        }
    }
};

pub const EngineCallResponse = Pair(i64, EngineCallResponseParam);

const EngineCallResponseParam = RustEnum(union(enum) {
    Error: union(enum) { LabeledError: LabeledError },
    Value: Value,
    ListStream: ListStream,
    ByteStream: ByteStream,
    Config: Config,
    ValueMap: Record,
    Identifier: i64,
});
