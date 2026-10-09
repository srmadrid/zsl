const numeric = @import("../../../numeric.zig");

pub fn cos(x: anytype) @TypeOf(x) {
    return .{
        .re = numeric.mul(numeric.cos(numeric.re(x)), numeric.cosh(numeric.im(x))),
        .im = numeric.mul(numeric.sin(numeric.re(x)), numeric.sinh(numeric.im(x))),
    };
}
