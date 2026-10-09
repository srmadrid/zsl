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
    if (!meta.isNumeric(N) or (meta.numericType(N) != .float and meta.numericType(N) != .dyadic))
        @compileError("zsl.Complex: N must be a float or dyadic type, got \n\tN = " ++ @typeName(N) ++ "\n");

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
