const std = @import("std");

pub fn freeAllocated(alloc: std.mem.Allocator, token: std.json.Token) void {
    switch (token) {
        .allocated_string, .allocated_number => |value| {
            alloc.free(value);
        },
        else => {},
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

            var parsed: @This() = undefined;

            switch (try source.peekNextTokenType()) {
                .array_end => {
                    if (@typeInfo(A) != .Optional or @typeInfo(B) != .Optional) {
                        return error.UnexpectedToken;
                    }

                    _ = try source.next();
                    return .{ .a = null, .b = null };
                },
                else => {
                    parsed.a = try std.json.innerParse(A, alloc, source, options);
                },
            }

            switch (try source.peekNextTokenType()) {
                .array_end => {
                    if (@typeInfo(B) != .Optional) {
                        return error.UnexpectedToken;
                    }

                    _ = try source.next();
                    parsed.b = null;
                    return parsed;
                },
                else => {
                    parsed.b = try std.json.innerParse(B, alloc, source, options);
                },
            }

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

pub const EmptyList = struct {
    pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        _ = alloc;
        _ = options;

        const begin = try source.next();
        switch (begin) {
            .array_begin => {},
            else => {
                return error.UnexpectedToken;
            },
        }
        const end = try source.next();
        switch (end) {
            .array_end => {},
            else => {
                return error.UnexpectedToken;
            },
        }

        return .{};
    }

    pub fn jsonStringify(self: @This(), writer: anytype) !void {
        _ = self;

        try writer.beginArray();
        try writer.endArray();
    }
};

/// This is kinda a hack, user discression is adviced
/// This only works with externally tagged serde.rs enums, but this is true for most of nu_protocols enums
pub fn RustEnum(comptime Union: type) type {
    const info = switch (@typeInfo(Union)) {
        .Union => |info| info,
        else => unreachable,
    };

    comptime var void_fields_buffer: [info.fields.len]std.builtin.Type.UnionField = undefined;
    comptime var void_field_count = 0;

    for (info.fields) |field| {
        if (std.meta.eql(field.type, void)) {
            void_fields_buffer[void_field_count] = field;
            void_field_count += 1;
        }
    }

    const void_fields: []const std.builtin.Type.UnionField = void_fields_buffer[0..void_field_count];

    comptime var void_enum_fields: [void_fields.len]std.builtin.Type.EnumField = undefined;

    for (void_fields, 0..) |field, i| {
        void_enum_fields[i] = .{ .name = field.name, .value = i };
    }

    const void_fields_enum: type = @Type(.{
        .Enum = .{
            .tag_type = u64,
            .fields = &void_enum_fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_exhaustive = true,
        },
    });

    return struct {
        const union_type = Union;
        const void_enum = void_fields_enum;

        val: Union,

        pub fn jsonParse(alloc: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
            switch (try source.peekNextTokenType()) {
                .string => {
                    return .{ .val = convertRustEnumEnumField(Union, try std.json.innerParse(void_fields_enum, alloc, source, options)) catch return error.UnexpectedToken };
                },
                .object_begin => {
                    return .{ .val = try std.json.innerParse(Union, alloc, source, options) };
                },
                else => {
                    return error.UnexpectedToken;
                },
            }
        }

        pub fn jsonStringify(self: @This(), writer: anytype) !void {
            switch (self.val) {
                inline else => |unwrapped| {
                    if (std.meta.eql(@TypeOf(unwrapped), void)) {
                        try writer.write(@tagName(self.val));
                    } else {
                        try writer.write(self.val);
                    }
                },
            }
        }
    };
}

fn convertRustEnumEnumField(comptime target: type, value: anytype) !target {
    switch (@typeInfo(target)) {
        .Union => {},
        else => {
            @compileError("Target must be a union");
        },
    }

    switch (@typeInfo(@TypeOf(value))) {
        .Enum => |info| {
            if (info.fields.len == 0) {
                return error.EmptyEnum;
            }

            switch (value) {
                inline else => |unwrapped| {
                    const tag = @tagName(unwrapped);

                    if (!@hasField(target, tag)) {
                        @compileError("Target type doesnt contain this enums tag");
                    }

                    return @unionInit(target, tag, undefined);
                },
            }
        },
        else => {
            @compileError("Unsupported conversion value must be Enum");
        },
    }
}
