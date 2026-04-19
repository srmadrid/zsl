const std = @import("std");

const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const float = @import("../float.zig");

const dbl64 = @import("dbl64.zig");
const ldbl128 = @import("ldbl128.zig");

pub fn scalbn(x: anytype, n: i32) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!meta.isNumeric(X) or meta.numericType(X) != .float)
        @compileError("zsl.float.scalbn: x must be a float, got \n\tx: " ++ @typeName(X) ++ "\n");

    return std.math.scalbn(x, n);
}
