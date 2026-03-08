//! Namespace for complex operations.

const std = @import("std");

const types = @import("types.zig");
const numeric = @import("numeric.zig");
const constants = @import("constants.zig");

/// 32-bit complex type.
pub const cf16 = Complex(f16);
/// 64-bit complex type.
pub const cf32 = Complex(f32);
/// 128-bit complex type.
pub const cf64 = Complex(f64);
/// 160-bit complex type.
pub const cf80 = Complex(f80);
/// 256-bit complex type.
pub const cf128 = Complex(f128);
/// Compile-time complex type.
pub const comptime_complex = Complex(comptime_float);

pub fn Complex(comptime N: type) type {
    if (!types.isNumeric(N) or types.isIntegral(N))
        @compileError("zml.Complex: N must be a non-integral numeric type, got \n\tN: " ++ @typeName(N) ++ "\n");

    return struct {
        re: N,
        im: N,

        /// Type signature
        pub const zml_is_numeric = true;
        pub const zml_is_complex = true;
        pub const zml_is_signed = true;
        pub const zml_is_custom = types.isCustomType(N);

        /// Scalar type
        pub const ZmlScalar = N;

        pub fn init(re: N, im: N) Complex(N) {
            return .{
                .re = re,
                .im = im,
            };
        }

        pub fn initReal(re: N) Complex(N) {
            return .{
                .re = re,
                .im = constants.zero(N, .{}) catch unreachable,
            };
        }

        pub fn initImag(im: N) Complex(N) {
            return .{
                .re = constants.zero(N, .{}) catch unreachable,
                .im = im,
            };
        }

        pub fn initPolar(r: N, theta: N) Complex(N) {
            return .{
                .re = numeric.mul(r, numeric.cos(theta)),
                .im = numeric.mul(r, numeric.sin(theta)),
            };
        }

        pub fn add(x: Complex(N), y: Complex(N)) Complex(N) {
            return .{
                .re = ops.add(
                    x.re,
                    y.re,
                    .{},
                ) catch unreachable,
                .im = ops.add(
                    x.im,
                    y.im,
                    .{},
                ) catch unreachable,
            };
        }

        pub fn addReal(x: Complex(N), y: N) Complex(N) {
            return .{
                .re = ops.add(
                    x.re,
                    y,
                    .{},
                ) catch unreachable,
                .im = x.im,
            };
        }

        pub fn addImag(x: Cfloat(N), y: N) Cfloat(N) {
            return .{
                .re = x.re,
                .im = ops.add(
                    x.im,
                    y,
                    .{},
                ) catch unreachable,
            };
        }

        pub fn sub(x: Cfloat(N), y: Cfloat(N)) Cfloat(N) {
            return .{
                .re = ops.sub(
                    x.re,
                    y.re,
                    .{},
                ) catch unreachable,
                .im = ops.sub(
                    x.im,
                    y.im,
                    .{},
                ) catch unreachable,
            };
        }

        pub fn subReal(x: Cfloat(N), y: N) Cfloat(N) {
            return .{
                .re = ops.sub(
                    x.re,
                    y,
                    .{},
                ) catch unreachable,
                .im = x.im,
            };
        }

        pub fn subImag(x: Cfloat(N), y: N) Cfloat(N) {
            return .{
                .re = x.re,
                .im = ops.sub(
                    x.im,
                    y,
                    .{},
                ) catch unreachable,
            };
        }

        pub fn mul(x: Cfloat(N), y: Cfloat(N)) Cfloat(N) {
            return .{
                .re = ops.fma(
                    N,
                    x.re,
                    y.re,
                    ops.mul(
                        ops.neg(x.im, .{}) catch unreachable,
                        y.im,
                        .{},
                    ) catch unreachable,
                    .{},
                ) catch unreachable,
                .im = ops.fma(
                    N,
                    x.re,
                    y.im,
                    ops.mul(
                        x.im,
                        y.re,
                        .{},
                    ) catch unreachable,
                    .{},
                ) catch unreachable,
            };
        }

        pub fn mulReal(x: Cfloat(N), y: N) Cfloat(N) {
            return .{
                .re = ops.mul(
                    x.re,
                    y,
                    .{},
                ) catch unreachable,
                .im = ops.mul(
                    x.im,
                    y,
                    .{},
                ) catch unreachable,
            };
        }

        pub fn mulImag(x: Cfloat(N), y: N) Cfloat(N) {
            return .{
                .re = ops.mul(
                    ops.neg(x.im, .{}) catch unreachable,
                    y,
                    .{},
                ) catch unreachable,
                .im = ops.mul(
                    x.re,
                    y,
                    .{},
                ) catch unreachable,
            };
        }

        pub fn div(x: Cfloat(N), y: Cfloat(N)) Cfloat(N) {
            if (ops.lt(
                ops.abs(y.im, .{}) catch unreachable,
                ops.abs(y.re, .{}) catch unreachable,
                .{},
            ) catch unreachable) {
                const tmp1 = ops.div(
                    y.im,
                    y.re,
                    .{},
                ) catch unreachable;
                const tmp2 = ops.div(
                    1,
                    ops.fma(
                        tmp1,
                        y.im,
                        y.re,
                        .{},
                    ) catch unreachable,
                    .{},
                ) catch unreachable;

                return .{
                    .re = ops.mul(
                        ops.fma(
                            x.im,
                            tmp1,
                            x.re,
                            .{},
                        ) catch unreachable,
                        tmp2,
                        .{},
                    ) catch unreachable,
                    .im = ops.mul(
                        ops.fma(
                            ops.neg(x.re, .{}) catch unreachable,
                            tmp1,
                            x.im,
                            .{},
                        ) catch unreachable,
                        tmp2,
                        .{},
                    ) catch unreachable,
                };
            } else {
                const tmp1 = ops.div(
                    y.re,
                    y.im,
                    .{},
                ) catch unreachable;
                const tmp2 = ops.div(
                    1,
                    ops.fma(
                        tmp1,
                        y.re,
                        y.im,
                        .{},
                    ) catch unreachable,
                    .{},
                ) catch unreachable;

                return .{
                    .re = ops.mul(
                        ops.fma(
                            x.re,
                            tmp1,
                            x.im,
                            .{},
                        ) catch unreachable,
                        tmp2,
                        .{},
                    ) catch unreachable,
                    .im = ops.mul(
                        ops.fma(
                            x.im,
                            tmp1,
                            ops.neg(x.re, .{}) catch unreachable,
                            .{},
                        ) catch unreachable,
                        tmp2,
                        .{},
                    ) catch unreachable,
                };
            }
        }

        pub fn divReal(x: Cfloat(N), y: N) Cfloat(N) {
            return .{
                .re = ops.div(
                    x.re,
                    y,
                    .{},
                ) catch unreachable,
                .im = ops.div(
                    x.im,
                    y,
                    .{},
                ) catch unreachable,
            };
        }

        pub fn divImag(x: Cfloat(N), y: N) Cfloat(N) {
            return .{
                .re = ops.div(
                    x.im,
                    y,
                    .{},
                ) catch unreachable,
                .im = ops.div(
                    ops.neg(x.re, .{}) catch unreachable,
                    y,
                    .{},
                ) catch unreachable,
            };
        }

        pub fn conj(self: Cfloat(N)) Cfloat(N) {
            return .{
                .re = self.re,
                .im = ops.neg(self.im, .{}) catch unreachable,
            };
        }

        pub fn neg(self: Cfloat(N)) Cfloat(N) {
            return .{
                .re = ops.neg(self.re, .{}) catch unreachable,
                .im = ops.neg(self.im, .{}) catch unreachable,
            };
        }

        pub fn inverse(self: Cfloat(N)) Cfloat(N) {
            const s = ops.div(
                1,
                ops.hypot(self.re, self.im, .{}) catch unreachable,
                .{},
            ) catch unreachable;
            const s2 = ops.mul(
                s,
                s,
                .{},
            ) catch unreachable;

            return .{
                .re = ops.mul(
                    self.re,
                    s2,
                    .{},
                ) catch unreachable,
                .im = ops.mul(
                    ops.neg(self.im, .{}) catch unreachable,
                    s2,
                    .{},
                ) catch unreachable,
            };
        }
    };
}

pub fn Add(comptime X: type, comptime Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or
        !types.numericType(X).le(.complex) or !types.numericType(Y).le(.complex) or
        (types.numericType(X) != .complex and types.numericType(Y) != .complex))
        @compileError("zml.complex.add: at least one of x or y must be a complex, the other must be a bool, an int, a float, a dyadic or a complex, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return types.Coerce(X, Y);
}

pub inline fn add(
    x: anytype,
    y: anytype,
) Add(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = Add(X, Y);

    switch (types.numericType(X)) {
        .bool, .int, .float, .dyadic => {
            switch (types.numericType(Y)) {
                .complex => return types.scast(R, y).addReal(types.scast(types.Scalar(R), x)),
                else => unreachable,
            }
        },
        .complex => {
            switch (types.numericType(Y)) {
                .bool, .int, .float, .dyadic => return types.scast(R, x).addReal(types.scast(types.Scalar(R), y)),
                .complex => return types.scast(R, x).add(types.scast(R, y)),
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

pub fn Sub(comptime X: type, comptime Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or
        !types.numericType(X).le(.complex) or !types.numericType(Y).le(.complex) or
        (types.numericType(X) != .complex and types.numericType(Y) != .complex))
        @compileError("zml.complex.sub: at least one of x or y to be a complex, the other must be a bool, an int, a float or a complex, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return types.Coerce(X, Y);
}

pub inline fn sub(
    x: anytype,
    y: anytype,
) Sub(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = Sub(X, Y);

    switch (types.numericType(X)) {
        .bool, .int, .float, .dyadic => {
            switch (types.numericType(Y)) {
                .complex => return types.scast(R, y).neg().addReal(types.scast(types.Scalar(R), x)),
                else => unreachable,
            }
        },
        .complex => {
            switch (types.numericType(Y)) {
                .bool, .int, .float, .dyadic => return types.scast(R, x).subReal(types.scast(types.Scalar(R), y)),
                .complex => return types.scast(R, x).sub(types.scast(R, y)),
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

pub fn Mul(comptime X: type, comptime Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or
        !types.numericType(X).le(.complex) or !types.numericType(Y).le(.complex) or
        (types.numericType(X) != .complex and types.numericType(Y) != .complex))
        @compileError("zml.complex.mul: at least one of x or y to be a complex, the other must be a bool, an int, a float or a complex, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return types.Coerce(X, Y);
}

pub inline fn mul(
    x: anytype,
    y: anytype,
) Mul(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = Mul(X, Y);

    switch (types.numericType(X)) {
        .bool, .int, .float, .dyadic => {
            switch (types.numericType(Y)) {
                .complex => return types.scast(R, y).mulReal(types.scast(types.Scalar(R), x)),
                else => unreachable,
            }
        },
        .complex => {
            switch (types.numericType(Y)) {
                .bool, .int, .float, .dyadic => return types.scast(R, x).mulReal(types.scast(types.Scalar(R), y)),
                .complex => return types.scast(R, x).mul(types.scast(R, y)),
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

pub fn Div(comptime X: type, comptime Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or
        !types.numericType(X).le(.complex) or !types.numericType(Y).le(.complex) or
        (types.numericType(X) != .complex and types.numericType(Y) != .complex))
        @compileError("zml.complex.div: at least one of x or y to be a complex, the other must be a bool, an int, a float or a complex, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return types.Coerce(X, Y);
}

pub inline fn div(
    x: anytype,
    y: anytype,
) Div(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = Div(X, Y);

    switch (types.numericType(X)) {
        .bool, .int, .float, .dyadic => {
            switch (types.numericType(Y)) {
                .complex => return types.scast(R, y).divReal(types.scast(types.Scalar(R), x)),
                else => unreachable,
            }
        },
        .complex => {
            switch (types.numericType(Y)) {
                .bool, .int, .float, .dyadic => return types.scast(R, x).divReal(types.scast(types.Scalar(R), y)),
                .complex => return types.scast(R, x).div(types.scast(R, y)),
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

pub inline fn eq(
    x: anytype,
    y: anytype,
) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or
        !types.numericType(X).le(.complex) or !types.numericType(Y).le(.complex) or
        (types.numericType(X) != .complex and types.numericType(Y) != .complex))
        @compileError("zml.complex.eq: at least one of x or y to be a complex, the other must be a bool, an int, a float or a complex, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    switch (types.numericType(X)) {
        .bool, .int, .float, .dyadic => {
            switch (types.numericType(Y)) {
                .complex => {
                    return ops.eq(x, y.re, .{}) catch unreachable and
                        ops.eq(0, y.im, .{}) catch unreachable;
                },
                else => unreachable,
            }
        },
        .complex => {
            switch (types.numericType(Y)) {
                .bool, .int, .float, .dyadic => {
                    return ops.eq(x.re, y, .{}) catch unreachable and
                        ops.eq(x.im, 0, .{}) catch unreachable;
                },
                .complex => {
                    return ops.eq(x.re, y.re, .{}) catch unreachable and
                        ops.eq(x.im, y.im, .{}) catch unreachable;
                },
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

pub inline fn ne(
    x: anytype,
    y: anytype,
) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or
        !types.numericType(X).le(.complex) or !types.numericType(Y).le(.complex) or
        (types.numericType(X) != .complex and types.numericType(Y) != .complex))
        @compileError("zml.complex.ne: at least one of x or y to be a complex, the other must be a bool, an int, a float or a complex, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    switch (types.numericType(X)) {
        .bool, .int, .float, .dyadic => {
            switch (types.numericType(Y)) {
                .complex => {
                    return ops.ne(x, y.re, .{}) catch unreachable or
                        ops.ne(0, y.im, .{}) catch unreachable;
                },
                else => unreachable,
            }
        },
        .complex => {
            switch (types.numericType(Y)) {
                .bool, .int, .float, .dyadic => {
                    return ops.ne(x.re, y, .{}) catch unreachable or
                        ops.ne(x.im, 0, .{}) catch unreachable;
                },
                .complex => {
                    return ops.ne(x.re, y.re, .{}) catch unreachable or
                        ops.ne(x.im, y.im, .{}) catch unreachable;
                },
                else => unreachable,
            }
        },
        else => unreachable,
    }
}

pub const Fma = @import("complex/fma.zig").Fma;
pub const fma = @import("complex/fma.zig").fma;
pub const Arg = @import("complex/arg.zig").Arg;
pub const arg = @import("complex/arg.zig").arg;
pub const Abs = @import("complex/abs.zig").Abs;
pub const abs = @import("complex/abs.zig").abs;
pub const Abs1 = @import("complex/abs1.zig").Abs1;
pub const abs1 = @import("complex/abs1.zig").abs1;
pub const Abs2 = @import("complex/abs2.zig").Abs2;
pub const abs2 = @import("complex/abs2.zig").abs2;
pub const exp = @import("complex/exp.zig").exp;
pub const Log = @import("complex/log.zig").Log;
pub const log = @import("complex/log.zig").log;
pub const Pow = @import("complex/pow.zig").Pow;
pub const pow = @import("complex/pow.zig").pow;
pub const Sqrt = @import("complex/sqrt.zig").Sqrt;
pub const sqrt = @import("complex/sqrt.zig").sqrt; // Adapt to dyadics
pub const sin = @import("complex/sin.zig").sin;
pub const cos = @import("complex/cos.zig").cos;
pub const tan = @import("complex/tan.zig").tan; // Adapt to dyadics
pub const asin = @import("complex/asin.zig").asin; // Adapt to dyadics
pub const acos = @import("complex/acos.zig").acos; // Adapt to dyadics
pub const atan = @import("complex/atan.zig").atan; // Adapt to dyadics
pub const sinh = @import("complex/sinh.zig").sinh;
pub const cosh = @import("complex/cosh.zig").cosh;
pub const tanh = @import("complex/tanh.zig").tanh;
pub const asinh = @import("complex/asinh.zig").asinh;
pub const acosh = @import("complex/acosh.zig").acosh;
pub const atanh = @import("complex/atanh.zig").atanh;
