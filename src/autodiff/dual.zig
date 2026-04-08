const std = @import("std");

const types = @import("../types.zig");
const numeric = @import("../numeric.zig");

const autodiff = @import("../autodiff.zig");

pub fn isDual(comptime T: type) bool {
    return @hasDecl(T, "is_dual") and T.is_dual;
}

/// Represents a dual number `x + yϵ`
pub fn Dual(comptime N: type) type {
    if (comptime !types.isNumeric(N))
        @compileError("zsl.autodiff.Dual: T must be a numeric type, got \n\tT: " ++ @typeName(N) ++ "\n");

    return struct {
        val: N,
        eps: N,

        // Type signature
        pub const is_custom = true;
        pub const is_numeric = true;
        pub const is_dual = true;
        pub const is_complex = types.isComplex(N);

        // Scalar type
        pub const Scalar = N;

        pub const empty: autodiff.Dual(N) = .{
            .val = undefined,
            .eps = undefined,
        };

        // Constants
        pub const zero: autodiff.Dual(N) = .{
            .val = numeric.zero(N),
            .eps = numeric.zero(N),
        };

        // Basic operations
        pub const Abs = autodiff.dual.Abs;
        pub const abs = autodiff.dual.abs;
        pub const Abs1 = autodiff.dual.Abs1;
        pub const abs1 = autodiff.dual.abs1;
        pub const Abs2 = autodiff.dual.Abs2;
        pub const abs2 = autodiff.dual.abs2;
        pub const Neg = autodiff.dual.Neg;
        pub const neg = autodiff.dual.neg;
        pub const Re = autodiff.dual.Re;
        pub const re = autodiff.dual.re;
        pub const Im = autodiff.dual.Im;
        pub const im = autodiff.dual.im;
        pub const Conj = autodiff.dual.Conj;
        pub const conj = autodiff.dual.conj;
        pub const Sign = autodiff.dual.Sign;
        pub const sign = autodiff.dual.sign;

        // Arithmetic operations
        pub const Add = autodiff.dual.Add;
        pub const add = autodiff.dual.add;

        // Comparison operations

        // Exponential functions
        pub const Exp = autodiff.dual.Exp;
        pub const exp = autodiff.dual.exp;
        pub const Ln = autodiff.dual.Ln;
        pub const ln = autodiff.dual.ln;

        // Power functions
        // pub const Pow = ops.Pow;
        // pub const pow = ops.pow;
        pub const Sqrt = autodiff.dual.Sqrt;
        pub const sqrt = autodiff.dual.sqrt;
        pub const Cbrt = autodiff.dual.Cbrt;
        pub const cbrt = autodiff.dual.cbrt;
        // pub const Hypot = ops.Hypot;
        // pub const hypot = ops.hypot;

        pub fn fromFloat(x: anytype) autodiff.Dual(N) {
            return .{
                .val = numeric.cast(N, x),
                .eps = numeric.zero(N),
            };
        }

        pub fn toCfloat(self: Dual(N), comptime Cfloat: type) Cfloat {
            return types.scast(Cfloat, self.val);
        }
    };
}

pub fn Abs(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.abs: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Abs(types.Scalar(X)));
}

pub fn abs(x: anytype) autodiff.dual.Abs(@TypeOf(x)) {
    const absx = numeric.abs(x.val);

    return if (comptime !types.isComplex(types.Scalar(@TypeOf(x))))
        .{
            // |x|
            .val = absx,

            // sign(x) * y
            .eps = numeric.mul(numeric.sign(x.val), x.eps),
        }
    else
        .{
            // |x| = √(re(x)² + im(x)²)
            .val = absx,

            // if (x == 0)  0  else  (re(x) * re(y) + im(x) * im(y)) / |x|
            .eps = if (numeric.eq(x.val, numeric.zero(@TypeOf(x.val))))
                numeric.zero(@TypeOf(x.val))
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

pub fn Abs1(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.abs1: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Abs(types.Scalar(X)));
}

pub fn abs1(x: anytype) autodiff.dual.Abs1(@TypeOf(x)) {
    return if (comptime !types.isComplex(types.Scalar(@TypeOf(x))))
        .{
            // |x|
            .val = numeric.abs1(x.val),

            // sign(x) * y
            .eps = numeric.mul(numeric.sign(x.val), x.eps),
        }
    else
        .{
            // |re(x)| + |im(x)|
            .val = numeric.abs1(x.val),

            // sign(re(x)) * re(y) + sign(im(x)) * im(y)
            .eps = numeric.add(
                numeric.mul(numeric.sign(numeric.re(x.val)), numeric.re(x.eps)),
                numeric.mul(numeric.sign(numeric.im(x.val)), numeric.im(x.eps)),
            ),
        };
}

pub fn Abs2(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.abs2: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Abs(types.Scalar(X)));
}

pub fn abs2(x: anytype) autodiff.dual.Abs2(@TypeOf(x)) {
    return if (comptime !types.isComplex(types.Scalar(@TypeOf(x))))
        .{
            // |x|²
            .val = numeric.abs2(x.val),

            // 2 * x * y
            .eps = numeric.mul(numeric.two(types.Scalar(@TypeOf(x))), numeric.mul(x.val, x.eps)),
        }
    else
        .{
            // |x|² = re(x)² + im(x)²
            .val = numeric.abs2(x.val),

            // 2 * (re(x) * re(y) + im(x) * im(y))
            .eps = numeric.mul(
                numeric.two(types.Scalar(@TypeOf(x))),
                numeric.add(
                    numeric.mul(numeric.re(x.val), numeric.re(x.eps)),
                    numeric.mul(numeric.im(x.val), numeric.im(x.eps)),
                ),
            ),
        };
}

pub fn Neg(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.neg: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Neg(types.Scalar(X)));
}

pub fn neg(x: anytype) autodiff.dual.Neg(@TypeOf(x)) {
    return .{
        // -x
        .val = numeric.neg(x.val),

        // -y
        .eps = numeric.neg(x.eps),
    };
}

pub fn Re(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.re: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Re(types.Scalar(X)));
}

pub fn re(x: anytype) autodiff.dual.Re(@TypeOf(x)) {
    return .{
        // re(x)
        .val = numeric.re(x.val),

        // re(y)
        .eps = numeric.re(x.eps),
    };
}

pub fn Im(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.im: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Im(types.Scalar(X)));
}

pub fn im(x: anytype) autodiff.dual.Im(@TypeOf(x)) {
    return .{
        // im(x)
        .val = numeric.im(x.val),

        // im(y)
        .eps = numeric.im(x.eps),
    };
}

pub fn Conj(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.conj: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Conj(types.Scalar(X)));
}

pub fn conj(x: anytype) autodiff.dual.Conj(@TypeOf(x)) {
    return .{
        // conj(x)
        .val = numeric.conj(x.val),

        // conj(y)
        .eps = numeric.conj(x.eps),
    };
}

pub fn Sign(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.sign: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Abs(types.Scalar(X)));
}

pub fn sign(x: anytype) autodiff.dual.Sign(@TypeOf(x)) {
    if (comptime !types.isComplex(types.Scalar(@TypeOf(x)))) {
        return .{
            // sign(x)
            .val = numeric.sign(x.val),

            // 0
            .eps = numeric.zero(types.Scalar(@TypeOf(x))),
        };
    } else {
        if (numeric.eq(x.val, numeric.zero(@TypeOf(x.val)))) {
            return .{
                // 0
                .val = numeric.zero(@TypeOf(x.val)),

                // 0
                .eps = numeric.zero(@TypeOf(x.eps)),
            };
        }

        const absx = numeric.abs(x.val);
        const signx = numeric.div(x.val, absx);

        return .{
            // sign(x) = x / |x|
            .val = signx,

            // (y - sign(x) * (re(x) * re(y) + im(x) * im(y)) / |x|) / |x|
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

pub fn Exp(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.exp: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Exp(types.Scalar(X)));
}

pub fn exp(x: anytype) autodiff.dual.Exp(@TypeOf(x)) {
    const expx = numeric.exp(x.val);

    return .{
        // eˣ
        .val = expx,

        // y * eˣ
        .eps = numeric.mul(x.eps, expx),
    };
}

pub fn Ln(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.ln: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Ln(types.Scalar(X)));
}

pub fn ln(x: anytype) autodiff.dual.Ln(@TypeOf(x)) {
    return .{
        // ln(x)
        .val = numeric.ln(x.val),

        // y / x
        .eps = numeric.div(x.eps, x.val),
    };
}

pub fn Sqrt(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.sqrt: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Sqrt(types.Scalar(X)));
}

pub fn sqrt(x: anytype) autodiff.dual.Sqrt(@TypeOf(x)) {
    const sqrtx = numeric.sqrt(x.value);

    return .{
        // √x
        .val = sqrtx,

        // y / (2 * √x)
        .eps = numeric.div(x.eps, numeric.mul(numeric.two(@TypeOf(x.val)), x.val)),
    };
}

pub fn Cbrt(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.cbrt: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Cbrt(types.Scalar(X)));
}

pub fn cbrt(x: anytype) autodiff.dual.Cbrt(@TypeOf(x)) {
    const cbrtx = numeric.cbrt(x.value);

    return .{
        // ∛x
        .val = cbrtx,

        // y / (3 * ∛x²)
        .eps = numeric.div(x.eps, numeric.mul(numeric.add(numeric.two(@TypeOf(x.val)), numeric.one(@TypeOf(x.val))), x.val)),
    };
}

pub fn Sin(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.sin: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Sin(types.Scalar(X)));
}

pub fn sin(x: anytype) autodiff.dual.Sin(@TypeOf(x)) {
    return .{
        // sin(x)
        .val = numeric.sin(x.val),

        // y * cos(x)
        .eps = numeric.mul(x.eps, numeric.cos(x.val)),
    };
}

pub fn Cos(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.cos: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Cos(types.Scalar(X)));
}

pub fn cos(x: anytype) autodiff.dual.Cos(@TypeOf(x)) {
    return .{
        // cos(x)
        .val = numeric.cos(x.val),

        // -y * sin(x)
        .eps = numeric.neg(numeric.mul(x.eps, numeric.sin(x.val))),
    };
}

pub fn Tan(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.tan: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Tan(types.Scalar(X)));
}

pub fn tan(x: anytype) autodiff.dual.Tan(@TypeOf(x)) {
    const tanx = numeric.tan(x.val);

    return .{
        // tan(x)
        .val = tanx,

        // y * (1 + tan(x)²)
        .eps = numeric.mul(x.eps, numeric.add(numeric.one(@TypeOf(x.val)), numeric.mul(tanx, tanx))),
    };
}

pub fn Asin(comptime X: type) type {
    comptime if (!types.isNumeric(X) or !isDual(X))
        @compileError("zsl.autodiff.dual.asin: X must be a dual type, got\n\tX: " ++ @typeName(X) ++ "\n");

    return Dual(numeric.Asin(types.Scalar(X)));
}

pub fn asin(x: anytype) autodiff.dual.Asin(@TypeOf(x)) {
    return .{
        // asin(x)
        .val = numeric.asin(x.val),

        // y / √(1 - x²)
        .eps = numeric.div(x.eps, numeric.sqrt(numeric.sub(numeric.one(@TypeOf(x.val)), numeric.mul(x.val, x.val)))),
    };
}

fn _Add(comptime X: type, comptime Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or (!isDual(X) and !isDual(Y)))
        @compileError("zsl.Dual(T).add: at least one of x or y must be a dual, the other must be a numeric, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    const SX: type = if (isDual(X)) types.Scalar(X) else X;
    const SY: type = if (isDual(Y)) types.Scalar(Y) else Y;

    return Dual(numeric.Add(SX, SY));
}

fn _add(x: anytype, y: anytype) _Add(@TypeOf(x), @TypeOf(y)) {
    // if (comptime isDual(@TypeOf(x))) {
    //     if (comptime isDual(@TypeOf(y))) {
    //         return .{
    //             .val = ops.add(x.val, y.val, .{}) catch unreachable,
    //             .eps = ops.add(x.eps, y.eps, .{}) catch unreachable,
    //         };
    //     } else {
    //         return .{
    //             .val = ops.add(x.val, y, .{}) catch unreachable,
    //             .eps = x.eps,
    //         };
    //     }
    // } else {
    //     return .{
    //         .val = ops.add(x, y.val, .{}) catch unreachable,
    //         .eps = y.eps,
    //     };
    // }
    return .empty;
}
