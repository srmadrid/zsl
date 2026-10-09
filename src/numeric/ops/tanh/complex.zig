const numeric = @import("../../../numeric.zig");

pub fn tanh(x: anytype) @TypeOf(x) {
    if (numeric.ge(numeric.re(x), 0)) {
        const w = numeric.exp(numeric.mul(x, -2));

        return numeric.div(
            numeric.sub(1, w),
            numeric.add(1, w),
        );
    } else {
        const w = numeric.exp(numeric.mul(x, 2));

        return numeric.div(
            numeric.sub(w, 1),
            numeric.add(w, 1),
        );
    }
}
