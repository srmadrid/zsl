const numeric = @import("../../../numeric.zig");

pub fn asinh(x: anytype) @TypeOf(x) {
    const z_first_quad = @TypeOf(x){
        .re = numeric.abs(numeric.re(x)),
        .im = numeric.abs(numeric.im(x)),
    };

    const w = numeric.fma(z_first_quad, z_first_quad, 1);

    const root = numeric.sqrt(w);
    const sum = numeric.add(z_first_quad, root);
    const quad_result = numeric.ln(sum);

    return .{
        .re = if (numeric.lt(numeric.re(x), 0)) numeric.neg(quad_result.re) else quad_result.re,
        .im = if (numeric.lt(numeric.im(x), 0)) numeric.neg(quad_result.im) else quad_result.im,
    };
}
