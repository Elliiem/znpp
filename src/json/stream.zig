// Serializing and Deserializing for Stream messages

const std = @import("std");

const Span = @import("embedded.zig").Span;
const LabeledError = @import("embedded.zig").LabeledError;

const Pair = @import("common.zig").Pair;
const ByteArray = @import("common.zig").ByteArray;
const RustEnum = @import("common.zig").RustEnum;

const Value = @import("value.zig").Value;

pub const Stream = union(enum) {
    Data: Pair(i64, Data),
    End: i64,
    Ack: i64,
    Drop: i64,
};

pub const Data = union(enum) {
    Raw: Raw,
    List: Value,

    const Raw = union(enum) {
        Ok: ByteArray,
        Err: RawError,
    };

    const RawError = union(enum) {
        IOError: LabeledError,
    };
};

pub const PipelineDataHeader = RustEnum(union(enum) {
    Empty,
    Value: Value,
    ListStream: ListStream,
    ByteStream: ByteStream,
});

pub const ListStream = struct {
    id: i64,
    span: Span,
};

pub const ByteStream = struct {
    id: i64,
    span: Span,
    type: []const u8,
};
