const std = @import("std");

pub fn freeAllocated(alloc: std.mem.Allocator, token: std.json.Token) void {
    switch (token) {
        .allocated_string, .allocated_number => |value| {
            alloc.free(value);
        },
        else => {},
    }
}

pub fn expectToken(token: std.json.Token, comptime expected: @typeInfo(std.json.Token).Union.tag_type.?) !void {
    switch (token) {
        inline expected => {},
        else => {
            return error.UnexpectedToken;
        },
    }
}

pub fn Pair(comptime A: type, comptime B: type) type {
    return struct {
        a: A,
        b: B,

        pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
            switch (try source.next()) {
                .array_begin => {},
                else => |token| {
                    freeAllocated(alloc, token);
                    return error.UnexpectedToken;
                },
            }

            const parsed = .{
                .a = try std.json.innerParse(A, alloc, source, options),
                .b = try std.json.innerParse(B, alloc, source, options),
            };

            switch (try source.next()) {
                .array_end => {},
                else => |token| {
                    freeAllocated(alloc, token);
                    return error.UnexpectedToken;
                },
            }
            return parsed;
        }

        pub fn jsonStringify(self: @This(), writer: anytype) !void {
            try writer.beginArray();

            try writer.write(self.a);
            try writer.write(self.b);

            try writer.endArray();
        }
    };
}

pub fn StringUnion(comptime T: type) type {
    const info = switch (@typeInfo(T)) {
        .Union => |info| info,
        else => unreachable,
    };

    const string_field = for (info.fields) |field| {
        if (std.meta.eql(field.type, []const u8)) {
            break field;
        }
    } else unreachable;

    return struct {
        val: T,

        pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
            switch (try source.peekNextTokenType()) {
                .string => {
                    switch (try source.nextAllocMax(alloc, .alloc_if_needed, options.max_value_len.?)) {
                        inline .string, .allocated_string => |str| {
                            return .{ .val = @unionInit(T, string_field.name, str) };
                        },
                        else => unreachable,
                    }
                },
                .object_begin => {
                    return .{ .val = try std.json.innerParse(T, alloc, source, options) };
                },
                else => return error.UnexpectedToken,
            }
        }

        pub fn jsonStringify(self: @This(), writer: anytype) !void {
            //  TODO: see if we can implement this
            try writer.write(self.val);
        }
    };
}

pub const ByteArray = struct {
    value: []const u8,

    pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        return .{ .value = try std.json.innerParse([]const u8, alloc, source, options) };
    }

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        try writer.beginArray();

        for (self.value) |byte| {
            try writer.write(byte);
        }

        try writer.endArray();
    }
};
