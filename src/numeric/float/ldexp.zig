const std = @import("std");
const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");
const float = @import("../float.zig");

pub fn ldexp(x: anytype, n: i32) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!meta.isNumeric(X) or meta.numericType(X) != .float)
        @compileError("zsl.float.ldexp: x must be a float, got \n\tx: " ++ @typeName(X) ++ "\n");

    if (!std.math.isFinite(x) or x == 0)
        return x + x;

    return float.scalbn(x, n);
}
