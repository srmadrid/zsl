const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

/// Compares any two numerics `x` and `y` for greater-than or equal ordering.
///
/// ## Signature
/// ```zig
/// numeric.ge(x: X, y: Y) bool
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `bool`: `true` if `x` is greater than or equal to `y`, `false` otherwise.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `zmlGe` method. The expected
/// signature and behavior of `zmlGe` are as follows:
/// * `fn zmlGe(X, Y) bool`: Compares `x` and `y` for greater-than or equal
///   ordering.
pub inline fn ge(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "zmlGe",
                fn (X, Y) bool,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.ge: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlGe(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return Impl.zmlGe(x, y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "zmlGe", fn (X, Y) bool, &.{ X, Y }))
                @compileError("zml.numeric.ge: " ++ @typeName(X) ++ " must implement `fn zmlGe(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return X.zmlGe(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "zmlGe", fn (X, Y) bool, &.{ X, Y }))
            @compileError("zml.numeric.ge: " ++ @typeName(Y) ++ " must implement `fn zmlGe(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

        return Y.zmlGe(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return x or !y,
            .int => return int.ge(x, y),
            .rational => return rational.ge(x, y),
            .float => return float.ge(x, y),
            .dyadic => return dyadic.ge(x, y),
            .complex => @compileError("zml.numeric.ge: not defiged for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.ge(x, y),
            .rational => return rational.ge(x, y),
            .float => return float.ge(x, y),
            .dyadic => return dyadic.ge(x, y),
            .complex => @compileError("zml.numeric.ge: not defiged for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.ge(x, y),
            .float => return float.ge(x, y),
            .dyadic => return dyadic.ge(x, y),
            .complex => @compileError("zml.numeric.ge: not defiged for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.ge(x, y),
            .dyadic => return dyadic.ge(x, y),
            .complex => @compileError("zml.numeric.ge: not defiged for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.ge(x, y),
            .complex => @compileError("zml.numeric.ge: not defiged for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .complex => @compileError("zml.numeric.ge: not defiged for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
        .custom => unreachable,
    }
}
