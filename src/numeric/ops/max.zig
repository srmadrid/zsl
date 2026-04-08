const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Max(X: type, Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zsl.numeric.max: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "Max",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.max: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn Max(type, type) type`");

            return Impl.Max(X, Y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "Max", fn (type, type) type, &.{ X, Y }))
                @compileError("zsl.numeric.max: " ++ @typeName(X) ++ " must implement `fn Max(type, type) type`");

            return X.Max(X, Y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "Max", fn (type, type) type, &.{ X, Y }))
            @compileError("zsl.numeric.max: " ++ @typeName(Y) ++ " must implement `fn Max(type, type) type`");

        return Y.Max(X, Y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return bool,
            .int => return int.Max(X, Y),
            .float => return float.Max(X, Y),
            .dyadic => return dyadic.Max(X, Y),
            .complex => @compileError("zsl.numeric.max: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.Max(X, Y),
            .float => return float.Max(X, Y),
            .dyadic => return dyadic.Max(X, Y),
            .complex => @compileError("zsl.numeric.max: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => return float.Max(X, Y),
            .dyadic => return dyadic.Max(X, Y),
            .complex => @compileError("zsl.numeric.max: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => return dyadic.Max(X, Y),
            .complex => @compileError("zsl.numeric.max: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .complex => @compileError("zsl.numeric.max: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
        .custom => unreachable,
    }
}

/// Returns the maximum between any two numeric operands.
///
/// ## Signature
/// ```zig
/// numeric.max(x: X, y: Y) numeric.Max(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `numeric.Max(@TypeOf(x), @TypeOf(y))`: The maximum between `x` and `y`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `Max` method. The expected
/// signature and behavior of `Max` are as follows:
/// * `fn Max(type, type) type`: Returns the type of `x + y`.
///
/// `numeric.Max(X, Y)`, `X` or `Y` must implement the required `max` method.
/// The expected signatures and behavior of `max` are as follows:
/// * `fn max(X, Y) numeric.Max(X, Y)`: Returns the maximum between `x` and
///   `y`.
pub fn max(x: anytype, y: anytype) numeric.Max(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = numeric.Max(X, Y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "max",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.max: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn max(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.max(x, y);
        } else { // only X custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "max",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.max: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn max(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.max(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "max",
            fn (X, Y) R,
            &.{ X, Y },
        ) orelse
            @compileError("zsl.numeric.max: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn max(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

        return Impl.max(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return x or y,
            .int => return int.max(x, y),
            .float => return float.max(x, y),
            .dyadic => return dyadic.max(x, y),
            .complex => unreachable,
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.max(x, y),
            .float => return float.max(x, y),
            .dyadic => return dyadic.max(x, y),
            .complex => unreachable,
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => return float.max(x, y),
            .dyadic => return dyadic.max(x, y),
            .complex => unreachable,
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => return dyadic.max(x, y),
            .complex => unreachable,
            .custom => unreachable,
        },
        .complex => unreachable,
        .custom => unreachable,
    }
}
