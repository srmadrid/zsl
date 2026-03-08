const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

/// Compares any two numerics `x` and `y` for less-than ordering.
///
/// ## Signature
/// ```zig
/// numeric.lt(x: X, y: Y) bool
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `bool`: `true` if `x` is less than `y`, `false` otherwise.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `zmlLt` method. The expected
/// signature and behavior of `zmlLt` are as follows:
/// * `fn zmlLt(X, Y) bool`: Compares `x` and `y` for less-than ordering.
pub inline fn lt(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "zmlLt",
                fn (X, Y) bool,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.lt: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlLt(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return Impl.zmlLt(x, y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "zmlLt", fn (X, Y) bool, &.{ X, Y }))
                @compileError("zml.numeric.lt: " ++ @typeName(X) ++ " must implement `fn zmlLt(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return X.zmlLt(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "zmlLt", fn (X, Y) bool, &.{ X, Y }))
            @compileError("zml.numeric.lt: " ++ @typeName(Y) ++ " must implement `fn zmlLt(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

        return Y.zmlLt(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return !x and y,
            .int => return int.lt(x, y),
            .rational => return rational.lt(x, y),
            .float => return float.lt(x, y),
            .dyadic => return dyadic.lt(x, y),
            .complex => @compileError("zml.numeric.lt: not defiltd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.lt(x, y),
            .rational => return rational.lt(x, y),
            .float => return float.lt(x, y),
            .dyadic => return dyadic.lt(x, y),
            .complex => @compileError("zml.numeric.lt: not defiltd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.lt(x, y),
            .float => return float.lt(x, y),
            .dyadic => return dyadic.lt(x, y),
            .complex => @compileError("zml.numeric.lt: not defiltd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.lt(x, y),
            .dyadic => return dyadic.lt(x, y),
            .complex => @compileError("zml.numeric.lt: not defiltd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.lt(x, y),
            .complex => @compileError("zml.numeric.lt: not defiltd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .complex => @compileError("zml.numeric.lt: not defiltd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
        .custom => unreachable,
    }
}
