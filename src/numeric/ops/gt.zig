const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

/// Compares any two numerics `x` and `y` for greater-than ordering.
///
/// ## Signature
/// ```zig
/// numeric.gt(x: X, y: Y) bool
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `bool`: `true` if `x` is greater than `y`, `false` otherwise.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `gt` method. The expected
/// signature and behavior of `gt` are as follows:
/// * `fn gt(X, Y) bool`: Compares `x` and `y` for greater-than ordering.
pub inline fn gt(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zsl.numeric.gt: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "gt",
                fn (X, Y) bool,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.gt: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn gt(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return Impl.gt(x, y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "gt", fn (X, Y) bool, &.{ X, Y }))
                @compileError("zsl.numeric.gt: " ++ @typeName(X) ++ " must implement `fn gt(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return X.gt(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "gt", fn (X, Y) bool, &.{ X, Y }))
            @compileError("zsl.numeric.gt: " ++ @typeName(Y) ++ " must implement `fn gt(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

        return Y.gt(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return x and !y,
            .int => return int.gt(x, y),
            .rational => return rational.gt(x, y),
            .float => return float.gt(x, y),
            .dyadic => return dyadic.gt(x, y),
            .complex => @compileError("zsl.numeric.gt: not defigtd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.gt(x, y),
            .rational => return rational.gt(x, y),
            .float => return float.gt(x, y),
            .dyadic => return dyadic.gt(x, y),
            .complex => @compileError("zsl.numeric.gt: not defigtd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.gt(x, y),
            .float => return float.gt(x, y),
            .dyadic => return dyadic.gt(x, y),
            .complex => @compileError("zsl.numeric.gt: not defigtd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.gt(x, y),
            .dyadic => return dyadic.gt(x, y),
            .complex => @compileError("zsl.numeric.gt: not defigtd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.gt(x, y),
            .complex => @compileError("zsl.numeric.gt: not defigtd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .complex => @compileError("zsl.numeric.gt: not defigtd for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
        .custom => unreachable,
    }
}
