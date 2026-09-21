const numeric = @import("../../../numeric.zig");

pub fn div_rc(x: anytype, y: anytype) @TypeOf(y) {
    if (numeric.lt(numeric.abs(numeric.im(y)), numeric.abs(numeric.re(y)))) {
        const tmp1 = numeric.div(numeric.im(y), numeric.re(y));
        const tmp2 = numeric.div(x, numeric.fma(tmp1, numeric.im(y), numeric.re(y)));

        return .{
            .re = tmp2,
            .im = numeric.mul(numeric.neg(tmp1), tmp2),
        };
    } else {
        const tmp1 = numeric.div(numeric.re(y), numeric.im(y));
        const tmp2 = numeric.div(x, numeric.fma(tmp1, numeric.re(y), numeric.im(y)));

        return .{
            .re = numeric.mul(tmp1, tmp2),
            .im = numeric.neg(tmp2),
        };
    }
}

pub fn div_cc(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    if (numeric.lt(numeric.abs(numeric.im(y)), numeric.abs(numeric.re(y)))) {
        const tmp1 = numeric.div(numeric.im(y), numeric.re(y));
        const tmp2 = numeric.div(1, numeric.fma(tmp1, numeric.im(y), numeric.re(y)));

        return .{
            .re = numeric.mul(numeric.fma(numeric.im(x), tmp1, numeric.re(x)), tmp2),
            .im = numeric.mul(numeric.fma(numeric.neg(numeric.re(x)), tmp1, numeric.im(x)), tmp2),
        };
    } else {
        const tmp1 = numeric.div(numeric.re(y), numeric.im(y));
        const tmp2 = numeric.div(1, numeric.fma(tmp1, numeric.re(y), numeric.im(y)));

        return .{
            .re = numeric.mul(numeric.fma(numeric.re(x), tmp1, numeric.im(x)), tmp2),
            .im = numeric.mul(numeric.fma(numeric.im(x), tmp1, numeric.neg(numeric.re(x))), tmp2),
        };
    }
}
