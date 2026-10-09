const numeric = @import("../../../numeric.zig");

pub fn tan(x: anytype) @TypeOf(x) {
    const two_re = numeric.add(numeric.re(x), numeric.re(x));
    const two_im = numeric.add(numeric.im(x), numeric.im(x));

    const E = numeric.exp(numeric.neg(numeric.abs(two_im)));
    const E_sq = numeric.mul(E, E);
    const two_E = numeric.add(E, E);

    const sin_two_re = numeric.sin(two_re);
    const cos_two_re = numeric.cos(two_re);

    const den = numeric.add(1, numeric.fma(two_E, cos_two_re, E_sq));
    const num_re = numeric.mul(two_E, sin_two_re);
    const num_im = numeric.mul(numeric.sign(numeric.im(x)), numeric.sub(1, E_sq));

    return .{
        .re = numeric.div(num_re, den),
        .im = numeric.div(num_im, den),
    };
}
