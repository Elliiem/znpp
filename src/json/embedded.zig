const std = @import("std");

const EmptyList = @import("common.zig").EmptyList;
const RustEnum = @import("common.zig").RustEnum;
const Pair = @import("common.zig").Pair;
const freeAllocated = @import("common.zig").freeAllocated;
const expectToken = @import("common.zig").expectToken;

const Value = @import("value.zig").Value;

test {
    std.testing.refAllDecls(@import("tests/embedded.zig"));
}

pub const Span = struct {
    start: i64,
    end: i64,
};

pub const PipelineDataHeader = union(enum) {
    Empty,
    Value: Value,
    ListStream: ListStream,
    ByteStream: ByteStream,

    pub const ListStream = struct {
        id: i64,
        span: Span,
    };

    pub const ByteStream = struct {
        id: i64,
        span: Span,
        type: []const u8,
    };

    const PipelineDataHeaderObjectFields = enum {
        Value,
        ListStream,
        ByteStream,
    };

    pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        switch (try source.peekNextTokenType()) {
            .string => {
                const value_token = try source.nextAllocMax(alloc, .alloc_if_needed, options.max_value_len.?);
                defer freeAllocated(alloc, value_token);

                switch (value_token) {
                    inline .string, .allocated_string => |str| {
                        if (!std.mem.eql(u8, str, "Empty")) {
                            return error.UnexpectedToken;
                        }

                        return .Empty;
                    },
                    else => unreachable,
                }
            },
            .object_begin => {
                _ = try source.next();

                const union_field_token = try source.nextAllocMax(alloc, .alloc_if_needed, options.max_value_len.?);
                defer freeAllocated(alloc, union_field_token);

                const field = switch (union_field_token) {
                    inline .string, .allocated_string => |str| std.meta.stringToEnum(PipelineDataHeaderObjectFields, str) orelse return error.InvalidEnumTag,
                    else => {
                        return error.UnexpectedToken;
                    },
                };

                const parsed = switch (field) {
                    .Value => return .{ .Value = try std.json.innerParse(Value, alloc, source, options) },
                    .ListStream => return .{ .ListStream = try std.json.innerParse(ListStream, alloc, source, options) },
                    .ByteStream => return .{ .ByteStream = try std.json.innerParse(ByteStream, alloc, source, options) },
                };

                try expectToken(try source.next(), .object_end);

                return parsed;
            },
            else => {
                return error.UnexpectedToken;
            },
        }

        unreachable;
    }

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        switch (self) {
            .Empty => {
                try writer.write("Empty");
            },
            else => {
                try writer.beginObject();

                switch (self) {
                    .Value => {
                        try writer.objectField("Value");
                        try writer.write(self.Value);
                    },
                    .ListStream => {
                        try writer.objectField("ListStream");
                        try writer.write(self.ListStream);
                    },
                    .ByteStream => {
                        try writer.objectField("ByteStream");
                        try writer.write(self.ByteStream);
                    },
                    else => unreachable,
                }

                try writer.endObject();
            },
        }
    }
};

pub const ErrorLabel = struct {
    text: []const u8,
};

pub const LabeledError = struct {
    msg: []const u8,
    labels: ?[]const ErrorLabel,
    code: ?[]const u8,
    url: ?[]const u8,
    help: ?[]const u8,
    inner: ?[]const LabeledError,
};

pub const Ordering = enum {
    Less,
    Equal,
    Greater,
};

pub const Operator = union(enum) {
    pub const Comparison = enum {
        Equal,
        NotEqual,
        LessThan,
        GreaterThan,
        LessThanOrEqual,
        GraterThanOrEqual,
        RegexMatch,
        NotRegexMatch,
        In,
        NotIn,
        StartsWith,
        EndsWith,
    };

    pub const Math = enum {
        Plus,
        Append,
        Minus,
        Multiply,
        Divide,
        Modulo,
        FloorDivision,
        Pow,
    };

    pub const Boolean = enum {
        And,
        Or,
        Xor,
    };

    pub const Bits = enum {
        BitOr,
        BitXor,
        BitAnd,
        ShiftLeft,
        ShiftRight,
    };

    pub const Assignment = enum {
        Assign,
        PlusAssign,
        AppendAssign,
        MinusAssign,
        MultiplyAssign,
        DivideAssign,
    };

    Comparison: Comparison,
    Math: Math,
    Bits: Bits,
    Assignment: Assignment,
};

pub const Config = struct {};

pub const Signature = struct {
    name: []const u8,
    description: []const u8,
    extra_description: []const u8,
    search_terms: [][]const u8,
    required_positional: [][]const u8,
    optional_positional: [][]const u8,
    rest_positional: [][]const u8,
    vectorizes_over_list: bool,
    named: []Flag,
    input_output_types: []Pair(Type, Type),
    allow_variants_without_examples: bool,
    is_filter: bool,
    creates_scope: bool,
    allows_unknown_args: bool,
    category: Category,
};

pub const Flag = struct {
    long: []const u8,
    short: ?u8,
    arg: ?SyntaxShape,
    required: bool,
    desc: []const u8,
    var_id: ?Id,
    default_value: ?Value,
};

pub const Id = struct {};

pub const SyntaxShape = RustEnum(union(enum) {
    Any,
    Binary,
    Block,
    Boolean,
    CellPath,
    Closure: ?[]SyntaxShape,
    // CompleterWrapper
    DateTime,
    Directory,
    Duration,
    Error,
    Expression,
    ExternalArgument,
    FilePath,
    Filesize,
    Float,
    FullCellPath,
    GlobPattern,
    Int,
    ImportPattern,
    // Keyword
    // List
    MathExpression,
    MatchBlock,
    Nothing,
    Number,
    OneOf: []SyntaxShape,
    Operator,
    Range,
    // Record
    RowCondition,
    Signature,
    String,
    // Table
    VarWithOptType,
});

pub const Type = RustEnum(union(enum) {
    Any,
    Binary,
    Block,
    Bool,
    CellPath,
    Closure,
    // Custom
    Date,
    Duration,
    Error,
    Filesize,
    Float,
    Int,
    // List
    ListStream,
    Nothing,
    Number,
    Range,
    // Record
    Signature,
    String,
    Glob,
    // Table
});

pub const Category = RustEnum(union(enum) {
    Bits,
    Bytes,
    Chart,
    Conversions,
    Core,
    Custom: []const u8,
    Database,
    Date,
    Debug,
    Default,
    Removed,
    Env,
    Experimental,
    FileSystem,
    Filters,
    Formats,
    Generators,
    Hash,
    History,
    Math,
    Misc,
    Network,
    Path,
    Platform,
    Plugin,
    Random,
    Shells,
    Strings,
    Systems,
    Viewers,
});
