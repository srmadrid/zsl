const types = @import("../types.zig");
const numeric = @import("../numeric.zig");

const float = @import("../float.zig");

const dbl64 = @import("dbl64.zig");
const ldbl128 = @import("ldbl128.zig");

/// Returns the hyperbolic arctangent $\tanh^{-1}(x)$ of a float.
///
/// ## Signature
/// ```zig
/// float.atanh(x: X) X
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The value to get the hyperbolic arctangent of.
///
/// ## Returns
/// `@TypeOf(x)`: The hyperbolic arctangent of `x`.
pub inline fn atanh(x: anytype) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!types.isNumeric(X) or types.numericType(X) != .float)
        @compileError("zsl.float.atanh: x must be a float, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (X) {
        f16 => return numeric.cast(f16, atanh32(numeric.cast(f32, x))),
        f32 => {
            // https://github.com/JuliaMath/openlibm/blob/master/src/e_atanhf.c
            return atanh32(numeric.cast(f32, x));
        },
        f64 => {
            // https://github.com/JuliaMath/openlibm/blob/master/src/e_atanh.c
            return atanh64(numeric.cast(f64, x));
        },
        f80 => {
            //
            // return atanh80(numeric.cast(f80, x));
            return numeric.cast(f80, atanh128(numeric.cast(f128, x)));
        },
        f128 => {
            // https://github.com/JuliaMath/openlibm/blob/master/ld128/e_atanhl.c
            return atanh128(numeric.cast(f128, x));
        },
        else => unreachable,
    }
}

// Translation of:
// https://github.com/JuliaMath/openlibm/blob/master/src/e_atanhf.c
//
// Original copyright notice:
// s_atanhf.c -- float version of s_atanh.c.
// Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
//
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunPro, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
fn atanh32(x: f32) f32 {
    const hx: i32 = @bitCast(x);
    const ix: i32 = hx & 0x7fffffff;

    if (ix > 0x3f800000) // |x| > 1
        return (x - x) / (x - x);

    if (ix == 0x3f800000)
        return x / 0.0;

    if (ix < 0x31800000)
        return x; // x < 2**-28

    const xx: f32 = @bitCast(ix);
    var t: f32 = undefined;
    if (ix < 0x3f000000) { // x < 0.5
        t = xx + xx;
        t = 0.5 * float.log1p(t + t * xx / (1.0 - xx));
    } else {
        t = 0.5 * float.log1p((xx + xx) / (1.0 - xx));
    }

    return if (hx < 0) -t else t;
}

// Translation of:
// https://github.com/JuliaMath/openlibm/blob/master/src/e_atanh.c
//
// Original copyright notice:
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunPro, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
fn atanh64(x: f64) f64 {
    const hx: i32 = @bitCast(dbl64.getHighPart(x));
    const lx: u32 = dbl64.getLowPart(x);
    const ix: i32 = hx & 0x7fffffff;

    if ((ix | @as(i32, @bitCast((lx | (0 -% lx)) >> 31))) > 0x3ff00000) // |x| > 1
        return (x - x) / (x - x);

    if (ix == 0x3ff00000)
        return x / 0.0;

    if (ix < 0x3e300000)
        return x; // x < 2**-28

    var xx: f64 = x;
    dbl64.setHighPart(&xx, @bitCast(ix));
    var t: f64 = undefined;
    if (ix < 0x3fe00000) { // x < 0.5
        t = xx + xx;
        t = 0.5 * float.log1p(t + t * xx / (1.0 - xx));
    } else t = 0.5 * float.log1p((xx + xx) / (1.0 - xx));

    return if (hx < 0) -t else t;
}

// Translation of:
// https://github.com/JuliaMath/openlibm/blob/master/ld128/e_atanhl.c
//
// Original copyright notice:
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunPro, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
fn atanh128(x: f128) f128 {
    var u: ldbl128.Parts32 = .fromFloat(x);
    const jx: u32 = u.mswhi;
    const ix: u32 = jx & 0x7fffffff;
    u.mswhi = ix;

    if (ix >= 0x3fff0000) { // |x| >= 1.0 or inf or NaN
        if (u.toFloat() == 1.0)
            return x / 0.0
        else
            return (x - x) / (x - x);
    }

    if (ix < 0x3fc60000) // x < 2**-57
        return x;

    var t: f128 = undefined;
    if (ix < 0x3ffe0000) { // x < 0.5
        t = u.toFloat() + u.toFloat();
        t = 0.5 * float.log1p(t + t * u.toFloat() / (1.0 - u.toFloat()));
    } else t = 0.5 * float.log1p((u.toFloat() + u.toFloat()) / (1.0 - u.toFloat()));

    return if (jx & 0x80000000 != 0) -t else t;
}
