const numeric = @import("../../../numeric.zig");

pub fn sqrt(x: anytype) @TypeOf(x) {
    const X = @TypeOf(x);

    // NaN check
    if (numeric.isNan(x))
        return numeric.nan(X);

    // Negative check
    if (!x.positive) {
        if (numeric.isZero(x))
            return x;

        return numeric.nan(X);
    }

    // Inf check
    if (numeric.isInf(x))
        return numeric.inf(X);

    // Zero check
    if (numeric.isZero(x))
        return x;

    const mantissa_bits = @typeInfo(X.Mantissa).int.bits;

    // For finite positive x = m * 2^e:
    //   sqrt(x) = sqrt(m << a) * 2^((e - a) / 2)
    // where a ∈ {N, N - 1} is chosen so (e - a) is even. Either choice puts
    // m = m << a in a range where isqrt(m) lands in [2^(N-1), 2^N), exactly
    // the N-bit normalized range, so no post-sqrt renormalization is needed.
    const e_is_odd = @mod(x.exponent, 2) != 0;
    const shift_amount = if (e_is_odd != (comptime (mantissa_bits & 1) != 0)) mantissa_bits - 1 else mantissa_bits;

    const n = numeric.cast(X.WideMantissa, x.mantissa) << @intCast(shift_amount);

    // Integer square root via Newton's method. Starting from an overestimation,
    // the iteration converges monotonically downward to floor(sqrt(n)) in
    // O(log(N)) steps.
    const q: X.WideMantissa = blk: {
        const msb_pos: u16 = 2 * mantissa_bits - 1 - @clz(n);
        var k: X.WideMantissa = @as(X.WideMantissa, 1) << @intCast(msb_pos / 2 + 1);
        while (true) {
            const next_k: X.WideMantissa = (k + n / k) / 2;

            if (next_k >= k)
                break :blk k;

            k = next_k;
        }
    };

    // For integer n, sqrt(n) is never exactly q + 0.5 (that would require
    // n = q^2 + q + 1/4, impossible for integer n), so there are no ties. The
    // decision reduces to:
    //   rem > q  iff  n ≥ q^2 + q + 1  iff  sqrt(n) > q + 0.5  iff  round up
    const rem: X.WideMantissa = n - q * q;

    var mantissa: X.Mantissa = @truncate(q);
    var result_exp: X.WideExponent = @divExact(
        numeric.cast(X.WideExponent, x.exponent) - numeric.cast(X.WideExponent, shift_amount),
        2,
    );

    if (rem > q) {
        const inc = @addWithOverflow(mantissa, 1);
        mantissa = inc[0];
        if (inc[1] != 0) {
            // q was 2^N - 1; rounding overflowed to 2^N. Renormalize.
            mantissa = @as(X.Mantissa, 1) << (mantissa_bits - 1);
            result_exp +|= 1;
        }
    }

    // Check for overflow
    if (result_exp >= numeric.highest(X.Exponent))
        return .{
            .mantissa = 0,
            .exponent = numeric.highest(X.Exponent),
            .positive = true,
        };

    // Check for underflow
    if (result_exp <= numeric.lowest(X.Exponent))
        return .{
            .mantissa = 0,
            .exponent = numeric.lowest(X.Exponent),
            .positive = true,
        };

    return .{
        .mantissa = mantissa,
        .exponent = numeric.cast(X.Exponent, result_exp),
        .positive = true,
    };
}
