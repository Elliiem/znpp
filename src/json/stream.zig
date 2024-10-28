// Serializing and Deserializing for Stream messages

const std = @import("std");

const LabeledError = @import("embedded.zig").LabeledError;

const Pair = @import("common.zig").Pair;
const ByteArray = @import("common.zig").ByteArray;

pub const Stream = union(enum) { Data: Pair(i64, Data) };

pub const Data = union(enum) {
    Raw: Raw,
    List: List,

    const Raw = union(enum) {
        Ok: ByteArray,
        Err: RawError,
    };

    const RawError = union(enum) {
        IOError: LabeledError,
    };

    const List = struct {};
};
