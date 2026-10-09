const numeric = @import("../../../numeric.zig");

pub fn sqrt(x: anytype) @TypeOf(x) {
    if (numeric.eq(x, 0))
        return x;

    const a = numeric.abs(numeric.re(x));
    const b = numeric.abs(numeric.im(x));
    const r = numeric.abs(x);

    const w = numeric.sqrt(numeric.div(numeric.add(r, a), 2));

    if (numeric.ge(numeric.re(x), 0)) {
        return .{
            .re = w,
            .im = numeric.div(numeric.im(x), numeric.mul(2, w)),
        };
    } else {
        return .{
            .re = numeric.div(b, numeric.mul(2, w)),
            .im = if (numeric.ge(numeric.im(x), 0)) w else numeric.neg(w),
        };
    }
}
