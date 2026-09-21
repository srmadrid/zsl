const meta = @import("../../meta.zig");
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
pub fn gt(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const C: type = numeric.Coerce(X, Y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y))
        @compileError("zsl.numeric.gt: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime meta.isCustomNumeric(X)) {
        if (comptime meta.isCustomNumeric(Y)) { // X and Y both custom
            const Impl: type = comptime meta.anyHasMethod(
                &.{ X, Y },
                "gt",
                fn (X, Y) bool,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.gt: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn gt(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return Impl.gt(x, y);
        } else { // only X custom
            comptime if (!meta.hasMethod(X, "gt", fn (X, Y) bool, &.{ X, Y }))
                @compileError("zsl.numeric.gt: " ++ @typeName(X) ++ " must implement `fn gt(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return X.gt(x, y);
        }
    } else if (comptime meta.isCustomNumeric(Y)) { // only Y custom
        comptime if (!meta.hasMethod(Y, "gt", fn (X, Y) bool, &.{ X, Y }))
            @compileError("zsl.numeric.gt: " ++ @typeName(Y) ++ " must implement `fn gt(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

        return Y.gt(x, y);
    }

    switch (comptime meta.numericType(X)) {
        .bool, .int, .float => switch (comptime meta.numericType(Y)) {
            .bool, .int, .float => return numeric.cast(C, x) > numeric.cast(C, y),
            .dyadic => return numeric.order(x, y) == .gt,
            .complex => @compileError("zsl.numeric.gt: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .dyadic => switch (comptime meta.numericType(Y)) {
            .bool, .int, .float, .dyadic => return numeric.order(x, y) == .gt,
            .complex => @compileError("zsl.numeric.gt: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .complex => @compileError("zsl.numeric.gt: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
        .custom => unreachable,
    }
}
