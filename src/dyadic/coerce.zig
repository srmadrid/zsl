const std = @import("std");

const meta = @import("../meta.zig");

const int = @import("../int.zig");
const dyadic = @import("../dyadic.zig");

/// Coerces two dyadic, float, int or bool types, where at least one of them
/// must be a dyadic type, to the smallest type that can represent all values
/// representable by either type.
///
/// ## Arguments
/// * `X` (`comptime type`): The first type to coerce.
/// * `Y` (`comptime type`): The second type to coerce.
///
/// ## Returns
/// `type`: The coerced type that can represent all values of both `X` and `Y`.
pub fn Coerce(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.dyadic) or !meta.numericType(Y).le(.dyadic) or
        (meta.numericType(X) != .dyadic and meta.numericType(Y) != .dyadic))
        @compileError("zsl.dyadic.Coerce: at least one of X or Y must be a dyadic type, the other must be a bool, an int, a float or a dyadic type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    if (comptime X == Y)
        return X;

    switch (comptime meta.numericType(X)) {
        .bool => switch (comptime meta.numericType(Y)) {
            .dyadic => return Y,
            else => unreachable,
        },
        .int => switch (comptime meta.numericType(Y)) {
            .dyadic => {
                if (X == comptime_int)
                    return Y;

                const xinfo = @typeInfo(X);

                return dyadic.Dyadic(
                    int.max(xinfo.int.bits, @typeInfo(Y.Mantissa).int.bits),
                    @typeInfo(Y.Exponent).int.bits,
                );
            },
            else => unreachable,
        },
        .float => switch (comptime meta.numericType(Y)) {
            .dyadic => {
                if (X == comptime_float)
                    return Y;

                const x_mantissa_bits = std.math.floatMantissaBits(X) + 1;
                const x_exponent_bits = std.math.floatExponentBits(X);

                return dyadic.Dyadic(
                    int.max(x_mantissa_bits, @typeInfo(Y.Mantissa).int.bits),
                    int.max(x_exponent_bits, @typeInfo(Y.Exponent).int.bits),
                );
            },
            else => unreachable,
        },
        .dyadic => switch (comptime meta.numericType(Y)) {
            .bool => return X,
            .int => return Coerce(Y, X),
            .float => return Coerce(Y, X),
            .dyadic => {
                return dyadic.Dyadic(
                    int.max(@typeInfo(X.Mantissa).int.bits, @typeInfo(Y.Mantissa).int.bits),
                    int.max(@typeInfo(X.Exponent).int.bits, @typeInfo(Y.Exponent).int.bits),
                );
            },
            else => unreachable,
        },
        else => unreachable,
    }
}
