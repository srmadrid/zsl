const std = @import("std");

const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const autodiff = @import("../autodiff.zig");
const stats = @import("../stats.zig");

const dual = @This();

pub fn isDual(T: type) bool {
    return switch (comptime @typeInfo(T)) {
        .@"struct" => blk: {
            comptime if (@hasField(T, "val") and @hasField(T, "eps")) {
                const Val = @TypeOf(@field(@as(T, undefined), "val"));
                const Eps = @TypeOf(@field(@as(T, undefined), "eps"));

                if (Val == Eps and meta.isNumeric(Val))
                    break :blk true;
            };
        },
        else => false,
    };
}

/// Represents a dual number `x + yε`, where `ε² = 0`.
pub fn Dual(comptime N: type) type {
    if (comptime !meta.isNumeric(N))
        @compileError("zsl.autodiff.Dual: N must be a numeric type, got \n\tN: " ++ @typeName(N) ++ "\n");

    return struct {
        val: N,
        eps: N,

        // Type signature
        pub const is_numeric = true;
        pub const is_integral = meta.isIntegral(N);
        pub const is_complex = meta.isComplex(N);
        pub const is_unsigned = meta.isUnsigned(N);

        pub const Accumulator = Dual(meta.Accumulator(N));
        pub const Real = Dual(meta.Real(N));
        pub const Scalar = N;

        pub const empty: autodiff.Dual(N) = .{
            .val = undefined,
            .eps = undefined,
        };

        // Basic operations
        pub const Abs = dual.Abs;
        pub const abs = dual.abs;
        pub const Abs1 = dual.Abs1;
        pub const abs1 = dual.abs1;
        pub const Abs2 = dual.Abs2;
        pub const abs2 = dual.abs2;
        pub const Neg = dual.Neg;
        pub const neg = dual.neg;
        pub const Re = dual.Re;
        pub const re = dual.re;
        pub const Im = dual.Im;
        pub const im = dual.im;
        pub const Conj = dual.Conj;
        pub const conj = dual.conj;
        pub const Sign = dual.Sign;
        pub const sign = dual.sign;

        // Arithmetic operations
        pub const Add = dual.Add;
        pub const add = dual.add;
        pub const Sub = dual.Sub;
        pub const sub = dual.sub;
        pub const Mul = dual.Mul;
        pub const mul = dual.mul;
        pub const Fma = dual.Fma;
        pub const fma = dual.fma;
        pub const Div = dual.Div;
        pub const div = dual.div;

        // Comparison operations
        // pub const cmp = ops.cmp;
        pub const eq = dual.eq;
        pub const ne = dual.ne;
        pub const lt = dual.lt;
        pub const le = dual.le;
        pub const gt = dual.gt;
        pub const ge = dual.ge;
        pub const Max = dual.Max;
        pub const max = dual.max;
        pub const Min = dual.Min;
        pub const min = dual.min;

        // Exponential functions
        pub const Exp = dual.Exp;
        pub const exp = dual.exp;
        pub const Ln = dual.Ln;
        pub const ln = dual.ln;

        // Power functions
        pub const Pow = dual.Pow;
        pub const pow = dual.pow;
        pub const Sqrt = dual.Sqrt;
        pub const sqrt = dual.sqrt;
        pub const Cbrt = dual.Cbrt;
        pub const cbrt = dual.cbrt;
        pub const Hypot = dual.Hypot;
        pub const hypot = dual.hypot;

        // Trigonometric functions
        pub const Sin = dual.Sin;
        pub const sin = dual.sin;
        pub const Cos = dual.Cos;
        pub const cos = dual.cos;
        pub const Tan = dual.Tan;
        pub const tan = dual.tan;
        pub const Asin = dual.Asin;
        pub const asin = dual.asin;
        pub const Acos = dual.Acos;
        pub const acos = dual.acos;
        pub const Atan = dual.Atan;
        pub const atan = dual.atan;
        pub const Atan2 = dual.Atan2;
        pub const atan2 = dual.atan2;

        // Hyperbolic functions
        pub const Sinh = dual.Sinh;
        pub const sinh = dual.sinh;
        pub const Cosh = dual.Cosh;
        pub const cosh = dual.cosh;
        pub const Tanh = dual.Tanh;
        pub const tanh = dual.tanh;
        pub const Asinh = dual.Asinh;
        pub const asinh = dual.asinh;
        pub const Acosh = dual.Acosh;
        pub const acosh = dual.acosh;
        pub const Atanh = dual.Atanh;
        pub const atanh = dual.atanh;

        pub fn standardUniform(prng: std.Random) autodiff.Dual(N) {
            return .{
                .val = stats.Uniform(N).sample(.{ .min = numeric.cast(N, 0), .max = numeric.cast(N, 1) }, prng),
                .eps = numeric.cast(N, 0),
            };
        }

        pub fn fromFloat(x: anytype) autodiff.Dual(N) {
            return .{
                .val = numeric.cast(N, x),
                .eps = numeric.cast(N, 0),
            };
        }

        pub fn toFloat(self: autodiff.Dual(N), comptime Float: type) Float {
            return numeric.cast(Float, self.val);
        }

        pub fn toComplex(self: autodiff.Dual(N), comptime Complex: type) Complex {
            return numeric.cast(Complex, self.val);
        }
    };
}

fn Abs(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Abs: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Abs(meta.Scalar(X)));
}

fn abs(x: anytype) autodiff.dual.Abs(@TypeOf(x)) {
    const absx = numeric.abs(x.val);

    return if (comptime meta.isReal(@TypeOf(x)))
        .{
            // `|x|`.
            .val = absx,

            // `sign(x) * y`.
            .eps = numeric.mul(numeric.sign(x.val), x.eps),
        }
    else
        .{
            // `|x| = √(Re{x}² + Im{x}²)`.
            .val = absx,

            // `if (x == 0)  0  else  (Re{x} * Re{y} + Im{x} * Im{y}) / |x|`.
            .eps = if (numeric.eq(x.val, 0))
                numeric.cast(meta.Scalar(@TypeOf(x)), 0)
            else
                numeric.div(
                    numeric.add(
                        numeric.mul(numeric.re(x.val), numeric.re(x.eps)),
                        numeric.mul(numeric.im(x.val), numeric.im(x.eps)),
                    ),
                    absx,
                ),
        };
}

fn Abs1(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Abs1: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Abs1(meta.Scalar(X)));
}

fn abs1(x: anytype) autodiff.dual.Abs1(@TypeOf(x)) {
    return if (comptime meta.isReal(@TypeOf(x)))
        .{
            // `|x|`.
            .val = numeric.abs1(x.val),

            // `sign(x) * y`.
            .eps = numeric.mul(numeric.sign(x.val), x.eps),
        }
    else
        .{
            // `|Re{x}| + |Im{x}|`.
            .val = numeric.abs1(x.val),

            // `sign(Re{x}) * Re{y} + sign(Im{x}) * Im{y}`.
            .eps = numeric.add(
                numeric.mul(numeric.sign(numeric.re(x.val)), numeric.re(x.eps)),
                numeric.mul(numeric.sign(numeric.im(x.val)), numeric.im(x.eps)),
            ),
        };
}

fn Abs2(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Abs2: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Abs2(meta.Scalar(X)));
}

fn abs2(x: anytype) autodiff.dual.Abs2(@TypeOf(x)) {
    return if (comptime meta.isReal(@TypeOf(x)))
        .{
            // `|x|²`.
            .val = numeric.abs2(x.val),

            // `2 * x * y`.
            .eps = numeric.mul(numeric.cast(meta.Scalar(@TypeOf(x)), 2), numeric.mul(x.val, x.eps)),
        }
    else
        .{
            // `|x|² = Re{x}² + Im{x}²`.
            .val = numeric.abs2(x.val),

            // `2 * (Re{x} * Re{y} + Im{x} * Im{y})`.
            .eps = numeric.mul(
                2,
                numeric.add(
                    numeric.mul(numeric.re(x.val), numeric.re(x.eps)),
                    numeric.mul(numeric.im(x.val), numeric.im(x.eps)),
                ),
            ),
        };
}

fn Neg(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Neg: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Neg(meta.Scalar(X)));
}

fn neg(x: anytype) autodiff.dual.Neg(@TypeOf(x)) {
    return .{
        // `-x`.
        .val = numeric.neg(x.val),

        // `-y`.
        .eps = numeric.neg(x.eps),
    };
}

fn Re(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Re: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Re(meta.Scalar(X)));
}

fn re(x: anytype) autodiff.dual.Re(@TypeOf(x)) {
    return .{
        // `Re{x}`.
        .val = numeric.re(x.val),

        // `Re{y}`.
        .eps = numeric.re(x.eps),
    };
}

fn Im(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Im: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Im(meta.Scalar(X)));
}

fn im(x: anytype) autodiff.dual.Im(@TypeOf(x)) {
    return .{
        // `Im{x}`.
        .val = numeric.im(x.val),

        // `Im{y}`.
        .eps = numeric.im(x.eps),
    };
}

fn Conj(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Conj: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Conj(meta.Scalar(X)));
}

fn conj(x: anytype) autodiff.dual.Conj(@TypeOf(x)) {
    return .{
        // `x̅`.
        .val = numeric.conj(x.val),

        // `y̅`.
        .eps = numeric.conj(x.eps),
    };
}

fn Sign(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Sign: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Abs(meta.Scalar(X)));
}

fn sign(x: anytype) autodiff.dual.Sign(@TypeOf(x)) {
    if (comptime meta.isReal(@TypeOf(x))) {
        return .{
            // `sign(x)`.
            .val = numeric.sign(x.val),

            // `0`.
            .eps = numeric.cast(meta.Scalar(@TypeOf(x)), 0),
        };
    } else {
        if (numeric.eq(x.val, numeric.cast(meta.Scalar(@TypeOf(x)), 0))) {
            return .{
                // `0`.
                .val = numeric.cast(meta.Scalar(@TypeOf(x)), 0),

                // `0`.
                .eps = numeric.cast(meta.Scalar(@TypeOf(x)), 0),
            };
        }

        const absx = numeric.abs(x.val);
        const signx = numeric.div(x.val, absx);

        return .{
            // `sign(x) = x / |x|`.
            .val = signx,

            // `(y - sign(x) * (Re{x} * Re{y} + Im{x} * Im{y}) / |x|) / |x|`.
            .eps = numeric.div(
                numeric.sub(
                    x.eps,
                    numeric.mul(
                        signx,
                        numeric.div(
                            numeric.add(
                                numeric.mul(numeric.re(x.val), numeric.re(x.eps)),
                                numeric.mul(numeric.im(x.val), numeric.im(x.eps)),
                            ),
                            absx,
                        ),
                    ),
                ),
                absx,
            ),
        };
    }
}

fn Add(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.Add: at least one of X or Y must be a dual type, the other must be a numeric or a dual type, got\n\tX = " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    const SX: type = if (isDual(X)) meta.Scalar(X) else X;
    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;

    return Dual(numeric.Add(SX, SY));
}

fn add(x: anytype, y: anytype) autodiff.dual.Add(@TypeOf(x), @TypeOf(y)) {
    if (comptime isDual(@TypeOf(x))) {
        if (comptime isDual(@TypeOf(y))) {
            return .{
                .val = numeric.add(x.val, y.val),
                .eps = numeric.add(x.eps, y.eps),
            };
        } else {
            return .{
                .val = numeric.add(x.val, y),
                .eps = x.eps,
            };
        }
    } else {
        return .{
            .val = numeric.add(x, y.val),
            .eps = y.eps,
        };
    }
}

fn Sub(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.Sub: at least one of X or Y must be a dual type, the other must be a numeric or a dual type, got\n\tX = " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    const SX: type = if (isDual(X)) meta.Scalar(X) else X;
    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;

    return Dual(numeric.Sub(SX, SY));
}

fn sub(x: anytype, y: anytype) autodiff.dual.Sub(@TypeOf(x), @TypeOf(y)) {
    if (comptime isDual(@TypeOf(x))) {
        if (comptime isDual(@TypeOf(y))) {
            return .{
                .val = numeric.sub(x.val, y.val),
                .eps = numeric.sub(x.eps, y.eps),
            };
        } else {
            return .{
                .val = numeric.sub(x.val, y),
                .eps = x.eps,
            };
        }
    } else {
        return .{
            .val = numeric.sub(x, y.val),
            .eps = numeric.neg(y.eps),
        };
    }
}

fn Mul(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.Mul: at least one of X or Y must be a dual type, the other must be a numeric or a dual type, got\n\tX = " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    const SX: type = if (isDual(X)) meta.Scalar(X) else X;
    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;

    return Dual(numeric.Mul(SX, SY));
}

fn mul(x: anytype, y: anytype) autodiff.dual.Mul(@TypeOf(x), @TypeOf(y)) {
    if (comptime isDual(@TypeOf(x))) {
        if (comptime isDual(@TypeOf(y))) {
            return .{
                .val = numeric.mul(x.val, y.val),
                .eps = numeric.fma(x.val, y.eps, numeric.mul(x.eps, y.val)),
            };
        } else {
            return .{
                .val = numeric.mul(x.val, y),
                .eps = numeric.mul(x.eps, y),
            };
        }
    } else {
        return .{
            .val = numeric.mul(x, y.val),
            .eps = numeric.mul(x, y.eps),
        };
    }
}

fn Fma(comptime X: type, comptime Y: type, comptime Z: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or !meta.isNumeric(Z) or (!isDual(X) and !isDual(Y) and !isDual(Z)))
        @compileError("zsl.autodiff.dual.Fma: at least one of X, Y or Z must be a dual type, the others must be numeric or dual types, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n\tZ = " ++ @typeName(Z) ++ "\n");

    const SX: type = if (isDual(X)) meta.Scalar(X) else X;
    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;
    const SZ: type = if (isDual(Z)) meta.Scalar(Z) else Z;

    return Dual(numeric.Fma(SX, SY, SZ));
}

fn fma(x: anytype, y: anytype, z: anytype) autodiff.dual.Fma(@TypeOf(x), @TypeOf(y), @TypeOf(z)) {
    if (comptime isDual(@TypeOf(x))) {
        if (comptime isDual(@TypeOf(y))) {
            if (comptime isDual(@TypeOf(z))) {
                return .{
                    .val = numeric.fma(x.val, y.val, z.val),
                    .eps = numeric.fma(x.eps, y.val, numeric.fma(x.val, y.eps, z.eps)),
                };
            } else {
                return .{
                    .val = numeric.fma(x.val, y.val, z),
                    .eps = numeric.fma(x.eps, y.val, numeric.mul(x.val, y.eps)),
                };
            }
        } else {
            if (comptime isDual(@TypeOf(z))) {
                return .{
                    .val = numeric.fma(x.val, y, z.val),
                    .eps = numeric.fma(x.eps, y, z.eps),
                };
            } else {
                return .{
                    .val = numeric.fma(x.val, y, z),
                    .eps = numeric.mul(x.eps, y),
                };
            }
        }
    } else {
        if (comptime isDual(@TypeOf(y))) {
            if (comptime isDual(@TypeOf(z))) {
                return .{
                    .val = numeric.fma(x, y.val, z.val),
                    .eps = numeric.fma(x, y.eps, z.eps),
                };
            } else {
                return .{
                    .val = numeric.fma(x, y.val, z),
                    .eps = numeric.mul(x, y.eps),
                };
            }
        } else {
            if (comptime isDual(@TypeOf(z))) {
                return .{
                    .val = numeric.fma(x, y, z.val),
                    .eps = numeric.cast(meta.Scalar(autodiff.dual.Fma(@TypeOf(x), @TypeOf(y), @TypeOf(z))), z.eps),
                };
            }
        }
    }
}

fn Div(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.Div: at least one of X or Y must be a dual type, the other must be a numeric or a dual type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    const SX: type = if (isDual(X)) meta.Scalar(X) else X;
    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;

    return Dual(numeric.Div(SX, SY));
}

fn div(x: anytype, y: anytype) autodiff.dual.Div(@TypeOf(x), @TypeOf(y)) {
    if (comptime isDual(@TypeOf(x))) {
        if (comptime isDual(@TypeOf(y))) {
            const invy = numeric.div(1, y.val);

            return .{
                .val = numeric.mul(x.val, invy),
                .eps = numeric.mul(numeric.fma(x.eps, y.val, numeric.neg(numeric.mul(x.val, y.eps))), numeric.mul(invy, invy)),
            };
        } else {
            const invy = numeric.div(1, y.val);

            return .{
                .val = numeric.mul(x.val, invy),
                .eps = numeric.mul(x.eps, invy),
            };
        }
    } else {
        const invy = numeric.div(1, y.val);

        return .{
            .val = numeric.mul(x, invy),
            .eps = numeric.neg(numeric.mul(numeric.mul(x, y.eps), numeric.mul(invy, invy))),
        };
    }
}

fn eq(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.eq: at least one of x or y must be a dual, the other must be a numeric or a dual, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return numeric.eq(
        if (comptime isDual(X)) x.val else x,
        if (comptime isDual(Y)) y.val else y,
    );
}

fn ne(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.ne: at least one of x or y must be a dual, the other must be a numeric or a dual, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return numeric.ne(
        if (comptime isDual(X)) x.val else x,
        if (comptime isDual(Y)) y.val else y,
    );
}

fn lt(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.lt: at least one of x or y must be a dual, the other must be a numeric or a dual, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return numeric.lt(
        if (comptime isDual(X)) x.val else x,
        if (comptime isDual(Y)) y.val else y,
    );
}

fn le(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.le: at least one of x or y must be a dual, the other must be a numeric or a dual, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return numeric.le(
        if (comptime isDual(X)) x.val else x,
        if (comptime isDual(Y)) y.val else y,
    );
}

fn gt(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.gt: at least one of x or y must be a dual, the other must be a numeric or a dual, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return numeric.gt(
        if (comptime isDual(X)) x.val else x,
        if (comptime isDual(Y)) y.val else y,
    );
}

fn ge(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.ge: at least one of x or y must be a dual, the other must be a numeric or a dual, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return numeric.ge(
        if (comptime isDual(X)) x.val else x,
        if (comptime isDual(Y)) y.val else y,
    );
}

fn Max(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.Max: at least one of X or Y must be a dual type, the other must be a numeric or a dual type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    const SX: type = if (isDual(X)) meta.Scalar(X) else X;
    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;

    return Dual(numeric.Max(SX, SY));
}

fn max(x: anytype, y: anytype) autodiff.dual.Max(@TypeOf(x), @TypeOf(y)) {
    const R: type = autodiff.dual.Max(@TypeOf(x), @TypeOf(y));

    return if (numeric.gt(x, y)) numeric.cast(R, x) else numeric.cast(R, y);
}

fn Min(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.Min: at least one of X or Y must be a dual type, the other must be a numeric or a dual type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    const SX: type = if (isDual(X)) meta.Scalar(X) else X;
    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;

    return Dual(numeric.Min(SX, SY));
}

fn min(x: anytype, y: anytype) autodiff.dual.Min(@TypeOf(x), @TypeOf(y)) {
    const R: type = autodiff.dual.Min(@TypeOf(x), @TypeOf(y));

    return if (numeric.lt(x, y)) numeric.cast(R, x) else numeric.cast(R, y);
}

fn Exp(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Exp: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Exp(meta.Scalar(X)));
}

fn exp(x: anytype) autodiff.dual.Exp(@TypeOf(x)) {
    const expx = numeric.exp(x.val);

    return .{
        // `eˣ`.
        .val = expx,

        // `y * eˣ`.
        .eps = numeric.mul(x.eps, expx),
    };
}

fn Ln(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Ln: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Ln(meta.Scalar(X)));
}

fn ln(x: anytype) autodiff.dual.Ln(@TypeOf(x)) {
    return .{
        // `ln(x)`.
        .val = numeric.ln(x.val),

        // `y / x`.
        .eps = numeric.div(x.eps, x.val),
    };
}

fn Pow(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.Pow: at least one of X or Y must be a dual type, the other must be a numeric or a dual type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    const SX: type = if (isDual(X)) meta.Scalar(X) else X;
    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;

    return Dual(numeric.Pow(SX, SY));
}

fn pow(x: anytype, y: anytype) autodiff.dual.Pow(@TypeOf(x), @TypeOf(y)) {
    if (comptime isDual(@TypeOf(x))) {
        if (comptime isDual(@TypeOf(y))) {
            const xpowy = numeric.pow(x.val, y.val);

            return .{
                .val = xpowy,
                .eps = numeric.fma(
                    numeric.mul(
                        y.val,
                        numeric.pow(
                            x.val,
                            numeric.sub(
                                y.val,
                                1,
                            ),
                        ),
                    ),
                    x.eps,
                    numeric.mul(
                        xpowy,
                        numeric.mul(
                            numeric.ln(x.val),
                            y.eps,
                        ),
                    ),
                ),
            };
        } else {
            const xpowy = numeric.pow(x.val, y);

            return .{
                .val = xpowy,
                .eps = numeric.mul(
                    numeric.mul(
                        y,
                        numeric.pow(
                            x.val,
                            numeric.sub(
                                y,
                                1,
                            ),
                        ),
                    ),
                    x.eps,
                ),
            };
        }
    } else {
        const xpowy = numeric.pow(x, y.val);

        return .{
            .val = xpowy,
            .eps = numeric.mul(
                xpowy,
                numeric.mul(
                    numeric.ln(x.val),
                    y.eps,
                ),
            ),
        };
    }
}

fn Sqrt(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Sqrt: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Sqrt(meta.Scalar(X)));
}

fn sqrt(x: anytype) autodiff.dual.Sqrt(@TypeOf(x)) {
    const sqrtx = numeric.sqrt(x.val);

    return .{
        // `√x`.
        .val = sqrtx,

        // `y / (2 * √x)`.
        .eps = numeric.div(x.eps, numeric.mul(2, sqrtx)),
    };
}

fn Cbrt(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Cbrt: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Cbrt(meta.Scalar(X)));
}

fn cbrt(x: anytype) autodiff.dual.Cbrt(@TypeOf(x)) {
    const cbrtx = numeric.cbrt(x.val);

    return .{
        // `∛x`.
        .val = cbrtx,

        // `y / (3 * ∛x²)`.
        .eps = numeric.div(
            x.eps,
            numeric.mul(
                3,
                numeric.mul(cbrtx, cbrtx),
            ),
        ),
    };
}

fn Hypot(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.autodiff.dual.Hypot: at least one of X or Y must be a dual type, the other must be a numeric or a dual type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    const SX: type = if (isDual(X)) meta.Scalar(X) else X;
    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;

    return Dual(numeric.Hypot(SX, SY));
}

fn hypot(x: anytype, y: anytype) autodiff.dual.Hypot(@TypeOf(x), @TypeOf(y)) {
    if (comptime isDual(@TypeOf(x))) {
        if (comptime isDual(@TypeOf(y))) {
            const hypotxy = numeric.hypot(x.val, y.val);

            return .{
                .val = hypotxy,
                .eps = numeric.div(numeric.fma(x.val, x.eps, numeric.mul(y.val, y.eps)), hypotxy),
            };
        } else {
            const hypotxy = numeric.hypot(x.val, y);

            return .{
                .val = hypotxy,
                .eps = numeric.div(numeric.mul(x.val, x.eps), hypotxy),
            };
        }
    } else {
        const hypotxy = numeric.hypot(x, y.val);

        return .{
            .val = hypotxy,
            .eps = numeric.div(numeric.mul(y.val, y.eps), hypotxy),
        };
    }
}

fn Sin(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Sin: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Sin(meta.Scalar(X)));
}

fn sin(x: anytype) autodiff.dual.Sin(@TypeOf(x)) {
    return .{
        // `sin(x)`.
        .val = numeric.sin(x.val),

        // `y * cos(x)`.
        .eps = numeric.mul(x.eps, numeric.cos(x.val)),
    };
}

fn Cos(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Cos: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Cos(meta.Scalar(X)));
}

fn cos(x: anytype) autodiff.dual.Cos(@TypeOf(x)) {
    return .{
        // `cos(x)`.
        .val = numeric.cos(x.val),

        // `-y * sin(x)`.
        .eps = numeric.neg(numeric.mul(x.eps, numeric.sin(x.val))),
    };
}

fn Tan(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Tan: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Tan(meta.Scalar(X)));
}

fn tan(x: anytype) autodiff.dual.Tan(@TypeOf(x)) {
    const tanx = numeric.tan(x.val);

    return .{
        // `tan(x)`.
        .val = tanx,

        // `y * (1 + tan(x)²)`.
        .eps = numeric.mul(x.eps, numeric.add(1, numeric.mul(tanx, tanx))),
    };
}

fn Asin(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Asin: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Asin(meta.Scalar(X)));
}

fn asin(x: anytype) autodiff.dual.Asin(@TypeOf(x)) {
    return .{
        // `asin(x)`.
        .val = numeric.asin(x.val),

        // `y / √(1 - x²)`.
        .eps = numeric.div(x.eps, numeric.sqrt(numeric.sub(1, numeric.mul(x.val, x.val)))),
    };
}

fn Acos(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Acos: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Acos(meta.Scalar(X)));
}

fn acos(x: anytype) autodiff.dual.Acos(@TypeOf(x)) {
    return .{
        // `acos(x)`.
        .val = numeric.acos(x.val),

        // `-y / √(1 - x²)`.
        .eps = numeric.neg(numeric.div(x.eps, numeric.sqrt(numeric.sub(1, numeric.mul(x.val, x.val))))),
    };
}

fn Atan(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Atan: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Atan(meta.Scalar(X)));
}

fn atan(x: anytype) autodiff.dual.Atan(@TypeOf(x)) {
    return .{
        // `atan(x)`.
        .val = numeric.atan(x.val),

        // `y / (1 + x²)`.
        .eps = numeric.div(x.eps, numeric.add(1, numeric.mul(x.val, x.val))),
    };
}

fn Atan2(comptime Y: type, comptime X: type) type {
    comptime if (!meta.isNumeric(Y) or !meta.isNumeric(X) or (!isDual(Y) and !isDual(X)))
        @compileError("zsl.autodiff.dual.Atan2: at least one of Y or X must be a dual, the other must be a numeric or a dual type, got\n\tY = " ++
            @typeName(Y) ++ "\n\tX = " ++ @typeName(X) ++ "\n");

    const SY: type = if (isDual(Y)) meta.Scalar(Y) else Y;
    const SX: type = if (isDual(X)) meta.Scalar(X) else X;

    return Dual(numeric.Atan2(SY, SX));
}

fn atan2(y: anytype, x: anytype) autodiff.dual.Atan2(@TypeOf(y), @TypeOf(x)) {
    if (comptime isDual(@TypeOf(y))) {
        if (comptime isDual(@TypeOf(x))) {
            return .{
                .val = numeric.atan2(y.val, x.val),
                .eps = numeric.div(numeric.fma(x.val, y.eps, numeric.neg(numeric.mul(y.val, x.eps))), numeric.add(numeric.mul(x.val, x.val), numeric.mul(y.val, y.val))),
            };
        } else {
            return .{
                .val = numeric.atan2(y.val, x),
                .eps = numeric.div(numeric.mul(x, y.eps), numeric.add(numeric.mul(x, x), numeric.mul(y.val, y.val))),
            };
        }
    } else {
        return .{
            .val = numeric.atan2(y, x.val),
            .eps = numeric.div(numeric.neg(numeric.mul(y, x.eps)), numeric.add(numeric.mul(x.val, x.val), numeric.mul(y, y))),
        };
    }
}

fn Sinh(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Sinh: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Sinh(meta.Scalar(X)));
}

fn sinh(x: anytype) autodiff.dual.Sinh(@TypeOf(x)) {
    return .{
        // `sinh(x)`.
        .val = numeric.sinh(x.val),

        // `y * cosh(x)`.
        .eps = numeric.mul(x.eps, numeric.cosh(x.val)),
    };
}

fn Cosh(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Cosh: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Cosh(meta.Scalar(X)));
}

fn cosh(x: anytype) autodiff.dual.Cosh(@TypeOf(x)) {
    return .{
        // `cosh(x)`.
        .val = numeric.cosh(x.val),

        // `y * sinh(x)`.
        .eps = numeric.mul(x.eps, numeric.sinh(x.val)),
    };
}

fn Tanh(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Tanh: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Tanh(meta.Scalar(X)));
}

fn tanh(x: anytype) autodiff.dual.Tanh(@TypeOf(x)) {
    const tanhx = numeric.tanh(x.val);

    return .{
        // `tanh(x)`.
        .val = tanhx,

        // `y * (1 - tanh(x)²)`.
        .eps = numeric.mul(x.eps, numeric.sub(1, numeric.mul(tanhx, tanhx))),
    };
}

fn Asinh(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Asinh: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Asinh(meta.Scalar(X)));
}

fn asinh(x: anytype) autodiff.dual.Asinh(@TypeOf(x)) {
    return .{
        // `asinh(x)`.
        .val = numeric.asinh(x.val),

        // `y / √(x² + 1)`.
        .eps = numeric.div(x.eps, numeric.sqrt(numeric.add(numeric.mul(x.val, x.val), 1))),
    };
}

fn Acosh(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Acosh: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Acosh(meta.Scalar(X)));
}

fn acosh(x: anytype) autodiff.dual.Acosh(@TypeOf(x)) {
    const acoshx = numeric.acosh(x.val);

    return .{
        // `acosh(x)`.
        .val = acoshx,

        // `y / sinh(acosh(x))`.
        .eps = numeric.div(x.eps, numeric.sinh(acoshx)),
    };
}

fn Atanh(comptime X: type) type {
    comptime if (!meta.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.Atanh: X must be a dual type, got\n\tX = " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Atanh(meta.Scalar(X)));
}

fn atanh(x: anytype) autodiff.dual.Atanh(@TypeOf(x)) {
    return .{
        // `atanh(x)`.
        .val = numeric.atanh(x.val),

        // `y / (1 - x²)`.
        .eps = numeric.div(x.eps, numeric.sub(1, numeric.mul(x.val, x.val))),
    };
}
