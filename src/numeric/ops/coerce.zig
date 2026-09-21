const std = @import("std");

const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

/// Coerces any two numeric types to the smallest type that can represent all
/// values representable by either type.
///
/// For two ints, if they have different signedness, the result is a signed int.
/// The bit-width of the result is either the larger of the two bit-widths (if
/// the signed type is larger) or the larger of the two bit-widths plus one (if
/// the unsigned type is larger). If both ints are "standard" (see
/// `meta.standard_integer_types`), the result is the next larger standard type
/// that can hold both values.
///
/// ## Arguments
/// * `X` (`comptime type`): The first type to coerce. Must be a numeric type.
/// * `Y` (`comptime type`): The second type to coerce. Must be a numeric type.
///
/// ## Returns
/// `type`: The coerced type that can represent all values of both `X` and `Y`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `Coerce` method. The expected
/// signature and behavior of `Coerce` are as follows:
/// * `fn Coerce(type, type) type`: Returns the smallest type that can represent
///   all values of types `X` and `Y`.
pub fn Coerce(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y))
        @compileError("zsl.numeric.Coerce: X and Y must be numeric types, got \n\tX = " ++ @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    if (comptime meta.isCustomNumeric(X)) {
        if (comptime meta.isCustomNumeric(Y)) { // X and Y both custom
            const Impl: type = comptime meta.anyHasMethod(
                &.{ X, Y },
                "Coerce",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.Coerce: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn Coerce(type, type) type`");

            return Impl.Coerce(X, Y);
        } else { // only X custom
            comptime if (!meta.hasMethod(X, "Coerce", fn (type, type) type, &.{ X, Y }))
                @compileError("zsl.numeric.Coerce: " ++ @typeName(X) ++ " must implement `fn Coerce(type, type) type`");

            return X.Coerce(X, Y);
        }
    } else if (comptime meta.isCustomNumeric(Y)) { // only Y custom
        comptime if (!meta.hasMethod(Y, "Coerce", fn (type, type) type, &.{ X, Y }))
            @compileError("zsl.numeric.Coerce: " ++ @typeName(Y) ++ " must implement `fn Coerce(type, type) type`");

        return Y.Coerce(X, Y);
    }

    switch (comptime meta.numericType(X)) {
        .bool => switch (comptime meta.numericType(Y)) {
            .bool => return bool,
            .int => return Y,
            .float => return Y,
            .dyadic => return Y,
            .complex => return Y,
            .custom => unreachable,
        },
        .int => switch (comptime meta.numericType(Y)) {
            .bool => return X,
            .int => {
                if (X == comptime_int)
                    return Y;

                if (Y == comptime_int)
                    return X;

                const xinfo = @typeInfo(X);
                const yinfo = @typeInfo(Y);

                if (xinfo.int.signedness == .unsigned) {
                    if (yinfo.int.signedness == .unsigned) { // both unsigned
                        return if (xinfo.int.bits > yinfo.int.bits)
                            X
                        else
                            Y;
                    } else { // X unsigned, Y signed
                        if (xinfo.int.bits >= yinfo.int.bits) {
                            // Unsigned is larger or equal to signed
                            if (std.mem.indexOfScalar(type, &meta.standard_integer_types, X) != null and
                                std.mem.indexOfScalar(type, &meta.standard_integer_types, Y) != null)
                            {
                                // Both are standard integers, need to double
                                // bits, unless already at max, then only add 1
                                return if (xinfo.int.bits == 128)
                                    @Int(yinfo.int.signedness, xinfo.int.bits + 1)
                                else
                                    @Int(yinfo.int.signedness, xinfo.int.bits * 2);
                            } else {
                                // One of the types is not a standard integer,
                                // only need to increase max bits by 1
                                return @Int(yinfo.int.signedness, xinfo.int.bits + 1);
                            }
                        } else {
                            // Signed is larger than unsigned
                            return Y;
                        }
                    }
                } else {
                    if (yinfo.int.signedness == .unsigned) { // X signed, Y unsigned
                        if (yinfo.int.bits >= xinfo.int.bits) {
                            // Unsigned is larger than signed
                            if (std.mem.indexOfScalar(type, &meta.standard_integer_types, X) != null and
                                std.mem.indexOfScalar(type, &meta.standard_integer_types, Y) != null)
                            {
                                // Both are standard integers, need to double
                                // bits, unless already at max, then only add 1
                                return if (yinfo.int.bits == 128)
                                    @Int(xinfo.int.signedness, yinfo.int.bits + 1)
                                else
                                    @Int(xinfo.int.signedness, yinfo.int.bits * 2);
                            } else {
                                // One of the types is not a standard integer,
                                // only need to increase max bits by 1
                                return @Int(xinfo.int.signedness, yinfo.int.bits + 1);
                            }
                        } else {
                            // Signed is larger than unsigned
                            return X;
                        }
                    } else { // both signed
                        return if (xinfo.int.bits > yinfo.int.bits)
                            X
                        else
                            Y;
                    }
                }
            },
            .float => {
                if (X == comptime_int)
                    return Y;

                const xinfo = @typeInfo(X);
                const FX = if (xinfo.int.bits <= 11)
                    f16
                else if (xinfo.int.bits <= 24)
                    f32
                else if (xinfo.int.bits <= 64) // Lossy past 53, but to not explode width
                    f64
                else
                    f128;

                if (Y == comptime_float)
                    return FX;

                return Coerce(FX, Y);
            },
            .dyadic => {
                if (X == comptime_int)
                    return Y;

                const xinfo = @typeInfo(X);

                return @import("../dyadic.zig").Dyadic(
                    numeric.max(xinfo.int.bits, @typeInfo(Y.Mantissa).int.bits),
                    @typeInfo(Y.Exponent).int.bits,
                );
            },
            .complex => return @import("../complex.zig").Complex(numeric.Coerce(X, meta.Scalar(Y))),
            .custom => unreachable,
        },
        .float => switch (comptime meta.numericType(Y)) {
            .bool => return X,
            .int => return Coerce(Y, X),
            .float => {
                if (X == comptime_float)
                    return Y;

                if (Y == comptime_float)
                    return X;

                const xinfo = @typeInfo(X);
                const yinfo = @typeInfo(Y);

                if (xinfo.float.bits > yinfo.float.bits)
                    return X
                else
                    return Y;
            },
            .dyadic => {
                if (X == comptime_float)
                    return Y;

                const x_mantissa_bits = std.math.floatMantissaBits(X) + 1;
                const x_exponent_bits = std.math.floatExponentBits(X);

                return @import("../dyadic.zig").Dyadic(
                    numeric.max(x_mantissa_bits, @typeInfo(Y.Mantissa).int.bits),
                    numeric.max(x_exponent_bits, @typeInfo(Y.Exponent).int.bits),
                );
            },
            .complex => return @import("../complex.zig").Complex(numeric.Coerce(X, meta.Scalar(Y))),
            .custom => unreachable,
        },
        .dyadic => switch (comptime meta.numericType(Y)) {
            .bool => return X,
            .int => return Coerce(Y, X),
            .float => return Coerce(Y, X),
            .dyadic => {
                return @import("../dyadic.zig").Dyadic(
                    numeric.max(@typeInfo(X.Mantissa).int.bits, @typeInfo(Y.Mantissa).int.bits),
                    numeric.max(@typeInfo(X.Exponent).int.bits, @typeInfo(Y.Exponent).int.bits),
                );
            },
            .complex => return @import("../complex.zig").Complex(numeric.Coerce(X, meta.Scalar(Y))),
            .custom => unreachable,
        },
        .complex => switch (comptime meta.numericType(Y)) {
            .bool => X,
            .int => return @import("../complex.zig").Complex(numeric.Coerce(meta.Scalar(X), Y)),
            .float => return @import("../complex.zig").Complex(numeric.Coerce(meta.Scalar(X), Y)),
            .dyadic => return @import("../complex.zig").Complex(numeric.Coerce(meta.Scalar(X), Y)),
            .complex => return @import("../complex.zig").Complex(numeric.Coerce(meta.Scalar(X), meta.Scalar(Y))),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
