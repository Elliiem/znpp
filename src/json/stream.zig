// Serializing and Deserializing for Stream messages

const std = @import("std");

const LabeledError = @import("embedded.zig").LabeledError;

const Pair = @import("common.zig").Pair;
const ByteArray = @import("common.zig").ByteArray;

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
