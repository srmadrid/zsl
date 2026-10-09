const numeric = @import("../../../numeric.zig");

pub fn pow_rc(x: anytype, y: anytype) @TypeOf(y) {
    const r = numeric.pow(x, numeric.re(y));
    const theta = numeric.mul(numeric.im(y), numeric.ln(x));

    return .{
        .re = numeric.mul(r, numeric.cos(theta)),
        .im = numeric.mul(r, numeric.sin(theta)),
    };
}

pub fn pow_cr(x: anytype, y: numeric.Re(@TypeOf(x))) @TypeOf(x) {
    const r = numeric.pow(numeric.abs(x), y);
    const theta = numeric.mul(numeric.arg(x), y);

    return .{
        .re = numeric.mul(r, numeric.cos(theta)),
        .im = numeric.mul(r, numeric.sin(theta)),
    };
}

pub fn pow_cc(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    const r = numeric.abs(x);
    const theta = numeric.arg(x);
    const ln_r = numeric.ln(r);

    const a = numeric.exp(numeric.fma(numeric.re(y), ln_r, numeric.neg(numeric.mul(numeric.im(y), theta))));
    const b = numeric.fma(numeric.re(y), theta, numeric.mul(numeric.im(y), ln_r));

    return .{
        .re = numeric.mul(a, numeric.cos(b)),
        .im = numeric.mul(a, numeric.sin(b)),
    };
}
