const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

/// Compares any two numerics `x` and `y` for less-than or equal ordering.
///
/// ## Signature
/// ```zig
/// numeric.le(x: X, y: Y) bool
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `bool`: `true` if `x` is less than or equal to `y`, `false` otherwise.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `zmlLe` method. The expected
/// signature and behavior of `zmlLe` are as follows:
/// * `fn zmlLe(X, Y) bool`: Compares `x` and `y` for less-than or equal
///   ordering.
pub inline fn le(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "zmlLe",
                fn (X, Y) bool,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.le: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlLe(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return Impl.zmlLe(x, y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "zmlLe", fn (X, Y) bool, &.{ X, Y }))
                @compileError("zml.numeric.le: " ++ @typeName(X) ++ " must implement `fn zmlLe(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return X.zmlLe(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "zmlLe", fn (X, Y) bool, &.{ X, Y }))
            @compileError("zml.numeric.le: " ++ @typeName(Y) ++ " must implement `fn zmlLe(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

        return Y.zmlLe(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return !x or y,
            .int => return int.le(x, y),
            .rational => return rational.le(x, y),
            .float => return float.le(x, y),
            .dyadic => return dyadic.le(x, y),
            .complex => @compileError("zml.numeric.le: not defiled for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.le(x, y),
            .rational => return rational.le(x, y),
            .float => return float.le(x, y),
            .dyadic => return dyadic.le(x, y),
            .complex => @compileError("zml.numeric.le: not defiled for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.le(x, y),
            .float => return float.le(x, y),
            .dyadic => return dyadic.le(x, y),
            .complex => @compileError("zml.numeric.le: not defiled for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.le(x, y),
            .dyadic => return dyadic.le(x, y),
            .complex => @compileError("zml.numeric.le: not defiled for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.le(x, y),
            .complex => @compileError("zml.numeric.le: not defiled for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .complex => @compileError("zml.numeric.le: not defiled for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
        .custom => unreachable,
    }
}
