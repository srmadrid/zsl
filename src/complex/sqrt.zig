const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the square root `√z` of a complex.
///
/// ## Signature
/// ```zig
/// complex.sqrt(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the square root of.
///
/// ## Returns
/// `@TypeOf(z)`: The square root of `z`.
pub fn sqrt(z: anytype) @TypeOf(z) {
    if (numeric.eq(z.re, numeric.zero(@TypeOf(z.re))) and
        numeric.eq(z.im, numeric.zero(@TypeOf(z.im))))
        return z;

    const a = numeric.abs(z.re);
    const b = numeric.abs(z.im);
    const r = numeric.abs(z);

    const w = numeric.sqrt(numeric.div(numeric.add(r, a), numeric.two(@TypeOf(z.re))));

    if (numeric.ge(z.re, numeric.zero(@TypeOf(z.re)))) {
        return .{
            .re = w,
            .im = numeric.div(z.im, numeric.mul(numeric.two(@TypeOf(z.re)), w)),
        };
    } else {
        return .{
            .re = numeric.div(b, numeric.mul(numeric.two(@TypeOf(z.re)), w)),
            .im = if (numeric.ge(z.im, numeric.zero(@TypeOf(z.im)))) w else numeric.neg(w),
        };
    }
}
