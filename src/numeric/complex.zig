//! Namespace for complex operations.

const complex = @This();

const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

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
    if (!meta.isNumeric(N) or meta.isIntegral(N))
        @compileError("zsl.Complex: N must be a non-integral numeric type, got \n\tN = " ++ @typeName(N) ++ "\n");

    return struct {
        re: N,
        im: N,

        // Type signature
        pub const is_numeric = true;
        pub const is_complex = true;

        pub const Accumulator = Complex(meta.Accumulator(N));
        pub const Real = N;
        pub const Scalar = N;

        /// Initializes a complex from any numeric value.
        ///
        /// ## Arguments
        /// * `value` (`anytype`): The value to set the complex to. Must be a
        ///   numeric.
        ///
        /// ## Returns
        /// `Complex(N)`: The new complex.
        pub fn initValue(value: anytype) Complex(N) {
            const V: type = @TypeOf(value);

            comptime if (!meta.isNumeric(V))
                @compileError("zsl.Complex(N).initValue: value must be a numeric, got \n\tvalue: " ++ @typeName(V) ++ "\n");

            switch (comptime meta.numericType(V)) {
                .bool, .int, .float, .dyadic => return .{
                    .re = numeric.cast(N, value),
                    .im = numeric.cast(N, 0),
                },
                .complex => return .{
                    .re = numeric.cast(N, value.re),
                    .im = numeric.cast(N, value.im),
                },
                .custom => return numeric.cast(Complex(N), value),
            }
        }

        pub fn toInt(self: Complex(N), comptime Int: type) Int {
            return numeric.cast(Int, self.re);
        }

        pub fn toFloat(self: Complex(N), comptime Float: type) Float {
            return numeric.cast(Float, self.re);
        }

        // fn parse

    };
}

/// Compares two operands of complex, dyadic, float, int or bool types, where at
/// least one operand must be of complex type, for equality. The operation is
/// performed by casting both operands to the coerced type, then comparing them.
///
/// ## Signature
/// ```zig
/// complex.eq(x: X, y: Y) bool
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `bool`: `true` if the operands are equal, `false` otherwise.
pub fn eq(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.complex) or !meta.numericType(Y).le(.complex) or
        (meta.numericType(X) != .complex and meta.numericType(Y) != .complex))
        @compileError("zsl.complex.eq: at least one of x or y to be a complex, the other must be a bool, an int, a float or a complex, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    switch (comptime meta.numericType(X)) {
        .bool, .int, .float, .dyadic => switch (comptime meta.numericType(Y)) {
            .complex => return numeric.eq(x, y.re) and numeric.eq(y.im, 0),
            else => unreachable,
        },
        .complex => switch (comptime meta.numericType(Y)) {
            .bool, .int, .float, .dyadic => return numeric.eq(x.re, y) and numeric.eq(x.im, 0),
            .complex => return numeric.eq(x.re, y.re) and numeric.eq(x.im, y.im),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Compares two operands of complex, dyadic, float, int or bool types, where at
/// least one operand must be of complex type, for inequality. The operation is
/// performed by casting both operands to the coerced type, then comparing them.
///
/// ## Signature
/// ```zig
/// complex.ne(x: X, y: Y) bool
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `bool`: `true` if the operands are not equal, `false` otherwise.
pub fn ne(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.complex) or !meta.numericType(Y).le(.complex) or
        (meta.numericType(X) != .complex and meta.numericType(Y) != .complex))
        @compileError("zsl.complex.ne: at least one of x or y to be a complex, the other must be a bool, an int, a float or a complex, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    switch (comptime meta.numericType(X)) {
        .bool, .int, .float, .dyadic => switch (comptime meta.numericType(Y)) {
            .complex => return numeric.ne(x, y.re) or numeric.ne(y.im, 0),
            else => unreachable,
        },
        .complex => switch (comptime meta.numericType(Y)) {
            .bool, .int, .float, .dyadic => return numeric.ne(x.re, y) or numeric.ne(x.im, 0),
            .complex => return numeric.ne(x.re, y.re) or numeric.ne(x.im, y.im),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

pub const Arg = @import("complex/arg.zig").Arg;
pub const arg = @import("complex/arg.zig").arg;
pub const exp = @import("complex/exp.zig").exp;
pub const ln = @import("complex/ln.zig").ln;
pub const Pow = @import("complex/pow.zig").Pow;
pub const pow = @import("complex/pow.zig").pow;
pub const sqrt = @import("complex/sqrt.zig").sqrt;
pub const sin = @import("complex/sin.zig").sin;
pub const cos = @import("complex/cos.zig").cos;
pub const tan = @import("complex/tan.zig").tan;
pub const asin = @import("complex/asin.zig").asin;
pub const acos = @import("complex/acos.zig").acos;
pub const atan = @import("complex/atan.zig").atan;
pub const sinh = @import("complex/sinh.zig").sinh;
pub const cosh = @import("complex/cosh.zig").cosh;
pub const tanh = @import("complex/tanh.zig").tanh;
pub const asinh = @import("complex/asinh.zig").asinh;
pub const acosh = @import("complex/acosh.zig").acosh;
pub const atanh = @import("complex/atanh.zig").atanh;
