const std = @import("std");

const RustEnum = @import("common.zig").RustEnum;
const Pair = @import("common.zig").Pair;

const Value = @import("value.zig").Value;

test {
    std.testing.refAllDecls(@import("tests/embedded.zig"));
}

pub const Span = struct {
    start: i64,
    end: i64,
};

pub const EvaluatedCall = struct {
    head: Span,
    positional: []const Value,
    named: []const Pair([]const u8, ?Value),
};

pub const LabeledError = struct {
    msg: []const u8,
    labels: ?[]const ErrorLabel,
    code: ?[]const u8,
    url: ?[]const u8,
    help: ?[]const u8,
    inner: ?[]const LabeledError,

    pub const ErrorLabel = struct {
        text: []const u8,
    };
};

pub const Ordering = enum {
    Less,
    Equal,
    Greater,
};

pub const Operator = union(enum) {
    Comparison: Comparison,
    Math: Math,
    Bits: Bits,
    Assignment: Assignment,

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
};

//  TODO: Implement
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

//  TODO: Implement
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
