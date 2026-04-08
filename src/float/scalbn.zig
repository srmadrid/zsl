const std = @import("std");

const types = @import("../types.zig");
const numeric = @import("../numeric.zig");

const float = @import("../float.zig");

const dbl64 = @import("dbl64.zig");
const ldbl128 = @import("ldbl128.zig");

pub fn Scalbn(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !types.numericType(X).le(.float))
        @compileError("zsl.float.scalbn: x must be a bool, an int or a float, got \n\tx: " ++ @typeName(X) ++ "\n");

    return types.EnsureFloat(X);
}

pub fn scalbn(x: anytype, n: i32) Scalbn(@TypeOf(x)) {
    return std.math.scalbn(numeric.cast(Scalbn(@TypeOf(x)), x), n);
}
