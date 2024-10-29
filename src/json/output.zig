const std = @import("std");

const Span = @import("embedded.zig").Span;
const EvaluatedCall = @import("input.zig").EvaluatedCall;
const LabeledError = @import("embedded.zig").LabeledError;
const Ordering = @import("embedded.zig").Ordering;
const Signature = @import("embedded.zig").Signature;

const Pair = @import("common.zig").Pair;
const RustEnum = @import("common.zig").RustEnum;

const Value = @import("value.zig").Value;
const Closure = @import("value.zig").Closure;

const PipelineDataHeader = @import("stream.zig").PipelineDataHeader;

pub const Output = union(enum) {
    CallResponse: CallResponse,
    EngineCall: EngineCall,
};

pub const CallResponse = Pair(i64, CallResponseParam);

pub const CallResponseParam = union(enum) {
    Error: LabeledError,
    Metadata: Metadata,
    Signature: PluginSignature,
    Ordering: ?Ordering,
    Value: Value,

    pub const Metadata = struct {
        version: ?[]const u8,
    };

    pub const PluginSignature = struct {
        sig: PluginSignature,
        examples: []Example,

        pub const Example = struct {
            example: []const u8,
            description: []const u8,
            result: ?Value,
        };
    };
};

pub const EngineCall = struct {
    context: i64,
    id: i64,
    call: Call,

    pub const Call = RustEnum(union(enum) {
        GetConfig,
        GetPluginConfig,
        GetEnvVar: []const u8,
        GetEnvVars,
        GetCurrentDir,
        AddEnvVar: Pair([]const u8, Value),
        GetHelp,
        EnterForeground,
        LeaveForeground,
        GetSpanContents: Span,
        EvalClosure: EvalClosure,
        FindDecl: []const u8,
        CallDecl: CallDecl,
        Option: Option,
    });

    pub const EvalClosure = struct {
        closure: Closure,
        input: PipelineDataHeader,
        redirect_stdout: bool,
        redirect_stderr: bool,
    };

    pub const CallDecl = struct {
        decl_id: i64,
        call: EvaluatedCall,
        input: PipelineDataHeader,
        redirect_stdout: bool,
        redirect_stderr: bool,
    };

    pub const Option = union(enum) {
        GoDisabled: bool,
    };
};
