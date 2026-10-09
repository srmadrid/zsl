const numeric = @import("../../../numeric.zig");

pub fn asin(x: anytype) @TypeOf(x) {
    const r1 = numeric.abs(numeric.add(x, 1));
    const r2 = numeric.abs(numeric.sub(x, 1));

    const sum = numeric.add(r1, r2);
    const diff = numeric.sub(r1, r2);

    const u = numeric.div(diff, 2);
    const v = numeric.div(sum, 2);

    const re = numeric.asin(u);
    const im = numeric.acosh(v);

    return .{
        .re = re,
        .im = if (numeric.lt(numeric.im(x), 1)) numeric.neg(im) else im,
    };
}
