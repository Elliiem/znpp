const std = @import("std");

const LabeledError = @import("embedded.zig").LabeledError;
const Signature = @import("embedded.zig").Signature;
const Ordering = @import("embedded.zig").Ordering;

const Pair = @import("common.zig").Pair;

const Value = @import("value.zig").Value;

pub const Output = union(enum) {};

pub const CallResponse = Pair(i64, CallResponseParameter);

pub const CallResponseParameter = union(enum) {
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
