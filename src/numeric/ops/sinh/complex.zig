const numeric = @import("../../../numeric.zig");

pub fn sinh(x: anytype) @TypeOf(x) {
    return .{
        .re = numeric.mul(numeric.sinh(numeric.re(x)), numeric.cos(numeric.im(x))),
        .im = numeric.mul(numeric.cosh(numeric.re(x)), numeric.sin(numeric.im(x))),
    };
}
