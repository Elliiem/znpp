const std = @import("std");

const Span = @import("embedded.zig").Span;
const LabeledError = @import("embedded.zig").LabeledError;

const Pair = @import("common.zig").Pair;
const ByteArray = @import("common.zig").ByteArray;
const RustEnum = @import("common.zig").RustEnum;
const freeAllocated = @import("common.zig").freeAllocated;

test {
    std.testing.refAllDecls(@import("tests/value.zig"));
}

pub const Value = union(enum) {
    Bool: Bool,
    Int: Int,
    Float: Float,
    Filesize: Filesize,
    Date: Date,
    Range: Range,
    String: String,
    Glob: Glob,
    Record: Record,
    List: List,
    Block: Block,
    Closure: Closure,
    Nothing: Nothing,
    Error: Error,
    Binary: Binary,
    CellPath: CellPath,
    Custom: Custom,
};

pub const Bool = struct {
    val: bool,
    span: Span,
};

pub const Int = struct {
    val: i64,
    span: Span,
};

pub const Float = struct {
    val: f64,
    span: Span,
};

pub const Filesize = struct {
    val: i64,
    span: Span,
};

pub const Duration = struct {
    val: i64,
    span: Span,
};

pub const Date = struct {
    val: []const u8,
    span: Span,
};

pub const RangeType = enum {
    IntRange,
    FloatRange,
};

pub const Range = struct {
    val: RangeInnerUnion,
    span: Span,
};

pub const RangeInnerUnion = union(RangeType) {
    IntRange: RangeInner(.IntRange),
    FloatRange: RangeInner(.FloatRange),
};

fn RangeInner(comptime T: RangeType) type {
    return struct {
        start: rangeContainer(T),
        step: rangeContainer(T),
        end: Bound(T),
    };
}

fn rangeContainer(comptime T: RangeType) type {
    return switch (T) {
        .IntRange => i64,
        .FloatRange => f64,
    };
}

pub fn Bound(comptime T: RangeType) type {
    return RustEnum(union(enum) {
        Included: rangeContainer(T),
        Excluded: rangeContainer(T),
        Unbounded,
    });
}

pub const String = struct {
    val: []const u8,
    span: Span,
};

pub const Glob = struct {
    val: []const u8,
    no_expand: bool,
    span: Span,
};

pub const Record = struct {
    val: RecordInner,
    span: Span,
};

pub const RecordInner = struct {
    values: *std.StringHashMap(Value),

    pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        var parsed = @This(){ .values = try alloc.create(std.StringHashMap(Value)) };
        parsed.values.* = std.StringHashMap(Value).init(alloc);

        errdefer {
            parsed.values.deinit();
            alloc.destroy(parsed.values);
        }

        switch (try source.next()) {
            .object_begin => {},
            else => |token| {
                freeAllocated(alloc, token);
                return error.UnexpectedToken;
            },
        }

        while (true) {
            const field_name_token = try source.nextAllocMax(alloc, .alloc_if_needed, options.max_value_len.?);
            defer freeAllocated(alloc, field_name_token);

            switch (field_name_token) {
                inline .string, .allocated_string => |str| {
                    try parsed.values.put(str, try std.json.innerParse(Value, alloc, source, options));
                },
                .object_end => {
                    return parsed;
                },
                else => {
                    return error.UnexpectedToken;
                },
            }
        }

        unreachable;
    }

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try writer.beginObject();

        var iter = self.values.keyIterator();

        while (iter.next()) |key| {
            try writer.objectField(key.*);
            try writer.write(self.values.get(key.*).?);
        }

        try writer.endObject();
    }
};

pub const List = struct {
    vals: []Value,
    span: Span,
};

pub const Block = struct {
    val: u64,
    span: Span,
};

pub const Closure = struct {
    val: ClosureValue,
    span: Span,
};

const ClosureValue = struct {
    block_id: u64,
    captures: []Pair(u64, Value),
};

pub const Nothing = struct {
    span: Span,
};

pub const Error = struct {
    val: LabeledError,
    span: Span,
};

pub const Binary = struct {
    val: ByteArray,
    span: Span,
};

pub const CellPath = struct {
    val: CellPathInner,
    span: Span,
};

const CellPathInner = struct {
    members: []PathMember,
};

const PathMember = struct {
    val: PathMemberValUnion,
    span: Span,
    optional: bool,
};

const PathMemberValUnion = union(enum) {
    Int: i64,
    String: []const u8,

    pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        return switch (try source.peekNextTokenType()) {
            .number => PathMemberValUnion{ .Int = try std.json.innerParse(i64, alloc, source, options) },
            .string => PathMemberValUnion{ .String = try std.json.innerParse([]const u8, alloc, source, options) },
            else => return error.UnexpectedToken,
        };
    }

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        switch (self) {
            .Int => |val| try writer.write(val),
            .String => |val| try writer.write(val),
        }
    }
};

pub const Custom = struct {
    val: CustomInner,
    span: Span,
};

const CustomInner = struct {
    type: []const u8,
    name: []const u8,
    data: ByteArray,
    notify_on_drop: bool,
};
