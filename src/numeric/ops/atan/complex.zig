const numeric = @import("../../../numeric.zig");

pub fn atan(x: anytype) @TypeOf(x) {
    const re_two = numeric.mul(numeric.re(x), numeric.re(x));
    const im_two = numeric.mul(numeric.im(x), numeric.im(x));

    const two_re = numeric.mul(2, numeric.re(x));
    const one_minus_r2 = numeric.sub(1, numeric.add(re_two, im_two));

    const num = numeric.fma(numeric.add(numeric.im(x), 1), numeric.add(numeric.im(x), 1), re_two);
    const den = numeric.fma(numeric.sub(numeric.im(x), 1), numeric.sub(numeric.im(x), 1), re_two);

    return .{
        .re = numeric.div(numeric.atan2(two_re, one_minus_r2), 2),
        .im = numeric.div(numeric.ln(numeric.div(num, den)), 4),
    };
}
