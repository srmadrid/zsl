const std = @import("std");

const numeric = @import("../../numeric.zig");

pub fn modf(x: anytype) struct { integer: @TypeOf(x), fraction: @TypeOf(x) } {
    switch (@TypeOf(x)) {
        f16 => return numeric.cast(f16, std.math.modf(numeric.cast(f32, x))),
        f32 => return std.math.modf(x),
        f64 => return std.math.modf(x),
        f80 => return numeric.cast(f80, std.math.modf(numeric.cast(f64, x))),
        f128 => return numeric.cast(f128, std.math.modf(numeric.cast(f64, x))),
        else => @compileError("x must be a float"),
    }
}
