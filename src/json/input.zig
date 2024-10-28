// Serializing and Deserializing for input messages

const std = @import("std");

const Span = @import("embedded.zig").Span;
const PipelineDataHeader = @import("embedded.zig").PipelineDataHeader;

const Operator = @import("embedded.zig").Operator;
const LabeledError = @import("embedded.zig").LabeledError;
//  NOTE: Config is not yet implemented EngineCallResponse.Config wont work
const Config = @import("embedded.zig").Config;

const Pair = @import("common.zig").Pair;
const StringUnion = @import("common.zig").StringUnion;
const ByteArray = @import("common.zig").ByteArray;

const freeAllocated = @import("common.zig").freeAllocated;
const expectToken = @import("common.zig").expectToken;

const Value = @import("value.zig").Value;
const Record = @import("value.zig").Record;

pub const Input = union(enum) {
    Call: Call,
    EngineCallResponse: EngineCallResponse,
};

pub const Call = Pair(i64, CallParameter);

pub const CallParameter = union(enum) {
    Metadata,
    Signature,
    Run: Run,
    CustomValueOp: CustomValueOp,

    const StringFields = enum {
        Metadata,
        Signature,
    };

    const ObjectFields = enum {
        Run,
        CustomValueOp,
    };

    pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        switch (try source.peekNextTokenType()) {
            .string => {
                switch (try source.nextAllocMax(alloc, .alloc_if_needed, options.max_value_len.?)) {
                    inline .string, .allocated_string => |str| {
                        return switch (std.meta.stringToEnum(StringFields, str) orelse return error.InvalidEnumTag) {
                            .Metadata => .Metadata,
                            .Signature => .Signature,
                        };
                    },
                    else => unreachable,
                }
            },
            .object_begin => {
                _ = try source.next();

                const union_field_token = try source.nextAllocMax(alloc, .alloc_if_needed, options.max_value_len.?);
                defer freeAllocated(alloc, union_field_token);

                const union_field = switch (union_field_token) {
                    inline .string, .allocated_string => |str| std.meta.stringToEnum(ObjectFields, str) orelse return error.InvalidEnumTag,
                    else => {
                        return error.UnexpectedToken;
                    },
                };

                const parsed: @This() = switch (union_field) {
                    .Run => .{ .Run = try std.json.innerParse(Run, alloc, source, options) },
                    .CustomValueOp => .{ .CustomValueOp = try std.json.innerParse(CustomValueOp, alloc, source, options) },
                };

                try expectToken(try source.next(), .object_end);

                return parsed;
            },
            else => {
                return error.UnexpectedToken;
            },
        }
    }

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        switch (self) {
            .Metadata => {
                try writer.write("Metadata");
            },
            .Signature => {
                try writer.write("Signature");
            },
            else => {
                try writer.beginObject();

                switch (self) {
                    .Run => {
                        try writer.objectField("Run");
                        try writer.write(self.Run);
                    },
                    .CustomValueOp => {
                        try writer.objectField("CustomValueOp");
                        try writer.write(self.CustomValueOp);
                    },
                    else => unreachable,
                }

                try writer.endObject();
            },
        }
    }
};

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

    const BParam = StringUnion(union(enum) {
        String: []const u8,
        FollowPathInt: RawFollowPathInt,
        FollowPathString: RawFollowPathString,
        PartialCmp: Value,
        Operation: Pair(Operator, Value),

        pub const RawFollowPathInt = struct {
            item: i64,
            span: Span,
        };

        pub const RawFollowPathString = struct {
            item: []const u8,
            span: Span,
        };
    });

    const BStringParams = enum { ToBaseValue, Dropped };

    pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        const raw = try std.json.innerParse(Pair(InputCustom, BParam), alloc, source, options);

        switch (raw.b.val) {
            .String => |str| {
                const union_field = std.meta.stringToEnum(BStringParams, str) orelse return error.InvalidEnumTag;

                return switch (union_field) {
                    .ToBaseValue => .{
                        .ToBaseValue = raw.a,
                    },
                    .Dropped => .{
                        .Dropped = raw.a,
                    },
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
                try writer.write(Pair(InputCustom, BParam){
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
                try writer.write(Pair(InputCustom, BParam){
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
                try writer.write(Pair(InputCustom, BParam){
                    .a = value.a,
                    .b = .{
                        .val = .{
                            .PartialCmp = value.b,
                        },
                    },
                });
            },
            .Operation => |value| {
                try writer.write(Pair(InputCustom, BParam){
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

const InputCustomInner = struct {
    name: []const u8,
    data: ByteArray,
};

pub const InputCustom = struct {
    item: InputCustomInner,
    span: Span,
};

pub const EvaluatedCall = struct {
    head: Span,
    positional: []const Value,
    named: []const Pair([]const u8, ?Value),
};

pub const EngineCallResponse = Pair(i64, EngineCallResponseParameter);

const EngineCallResponseParameter = union(enum) {
    Error: LabeledError,
    PipelineHeader: PipelineDataHeader,
    Config: Config,
    ValueMap: Record,
    Identifier: i64,
    Goodbye,

    const StringFields = enum {
        Goodbye,
    };

    const ObjectFields = enum {
        Error,
        Empty,
        Value,
        ListStream,
        ByteStream,
        Config,
        ValueMap,
        Identifier,
    };

    pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        switch (try source.peekNextTokenType()) {
            .string => {
                const token = try source.nextAllocMax(alloc, .alloc_if_needed, options.max_value_len.?);
                defer freeAllocated(alloc, token);

                _ = switch (try source.nextAllocMax(alloc, .alloc_if_needed, options.max_value_len.?)) {
                    inline .string, .allocated_string => |str| std.meta.stringToEnum(StringFields, str) orelse return error.InvalidEnumTag,
                    else => unreachable,
                };

                return .Goodbye;
            },
            .object_begin => {
                _ = try source.next();

                const union_field_token = try source.nextAllocMax(alloc, .alloc_if_needed, options.max_value_len.?);
                defer freeAllocated(alloc, union_field_token);

                const field = switch (union_field_token) {
                    inline .string, .allocated_string => |str| std.meta.stringToEnum(ObjectFields, str) orelse return error.InvalidEnumTag,
                    else => {
                        return error.UnexpectedToken;
                    },
                };

                const parsed: @This() = switch (field) {
                    .Error => blk: {
                        // For errors we need to skip ahead to the actual value...
                        const begin_token = try source.next();
                        defer freeAllocated(alloc, begin_token);
                        try expectToken(begin_token, .object_begin);

                        const error_union_field_token = try source.next();
                        defer freeAllocated(alloc, error_union_field_token);
                        switch (error_union_field_token) {
                            .string, .allocated_string => {},
                            else => {
                                return error.UnexpectedToken;
                            },
                        }

                        const parsed_error = .{ .Error = try std.json.innerParse(LabeledError, alloc, source, options) };

                        // ...and skip the closing of the "Error" field
                        const end_token = try source.next();
                        defer freeAllocated(alloc, end_token);
                        try expectToken(end_token, .object_end);

                        break :blk parsed_error;
                    },
                    .Empty => .{ .PipelineHeader = .Empty },
                    .Value => .{ .PipelineHeader = .{ .Value = try std.json.innerParse(Value, alloc, source, options) } },
                    .ListStream => .{ .PipelineHeader = .{ .ListStream = try std.json.innerParse(PipelineDataHeader.ListStream, alloc, source, options) } },
                    .ByteStream => .{ .PipelineHeader = .{ .ByteStream = try std.json.innerParse(PipelineDataHeader.ByteStream, alloc, source, options) } },
                    .Config => .{ .Config = try std.json.innerParse(Config, alloc, source, options) },
                    .ValueMap => .{ .ValueMap = try std.json.innerParse(Record, alloc, source, options) },
                    .Identifier => .{ .Identifier = try std.json.innerParse(i64, alloc, source, options) },
                };

                const end_token = try source.next();
                defer freeAllocated(alloc, end_token);
                try expectToken(end_token, .object_end);

                return parsed;
            },
            else => {
                return error.UnexpectedToken;
            },
        }
    }

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        switch (self) {
            .Error => |err| {
                try writer.beginObject();
                try writer.objectField("Error");
                try writer.beginObject();
                try writer.objectField("LabeledError");
                try writer.write(err);
                try writer.endObject();
                try writer.endObject();
            },
            .PipelineHeader => {
                try writer.write(self.PipelineHeader);
            },
            .Config => {
                try writer.beginObject();
                try writer.objectField("Config");
                try writer.write(self.Config);
                try writer.endObject();
            },
            .ValueMap => {
                try writer.beginObject();
                try writer.objectField("ValueMap");
                try writer.write(self.ValueMap);
                try writer.endObject();
            },
            .Identifier => {
                try writer.beginObject();
                try writer.objectField("Identifier");
                try writer.write(self.Identifier);
                try writer.endObject();
            },
            .Goodbye => {
                try writer.write("Goodbye");
            },
        }
    }
};
