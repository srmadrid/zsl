const types = @import("../types.zig");

const int = @import("../int.zig");

/// Coerces two float, int or bool types, where at least one of them must be a
/// float type, to the smallest type that can represent all values representable
/// by either type.
///
/// ## Arguments
/// * `X` (`comptime type`): The first type to coerce.
/// * `Y` (`comptime type`): The second type to coerce.
///
/// ## Returns
/// `type`: The coerced type that can represent all values of both `X` and `Y`.
pub fn Coerce(comptime X: type, comptime Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or
        !types.numericType(X).le(.float) or !types.numericType(Y).le(.float) or
        (types.numericType(X) != .float and types.numericType(Y) != .float))
        @compileError("zsl.float.Coerce: at least one of X or Y must be a float type, the other must be a bool, an int or a float type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    if (comptime X == Y)
        return X;

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .float => return Y,
            else => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .float => {
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
            else => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
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
            else => unreachable,
        },
        else => unreachable,
    }
}
