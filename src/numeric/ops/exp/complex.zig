const numeric = @import("../../../numeric.zig");

pub fn exp(x: anytype) @TypeOf(x) {
    const r = numeric.exp(numeric.re(x));

    return .{
        .re = numeric.mul(r, numeric.cos(numeric.im(x))),
        .im = numeric.mul(r, numeric.sin(numeric.im(x))),
    };
}
