const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Sub(X: type, Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zsl.numeric.sub: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "Sub",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.sub: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn Sub(type, type) type`");

            return Impl.Sub(X, Y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "Sub", fn (type, type) type, &.{ X, Y }))
                @compileError("zsl.numeric.sub: " ++ @typeName(X) ++ " must implement `fn Sub(type, type) type`");

            return X.Sub(X, Y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "Sub", fn (type, type) type, &.{ X, Y }))
            @compileError("zsl.numeric.sub: " ++ @typeName(Y) ++ " must implement `fn Sub(type, type) type`");

        return Y.Sub(X, Y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => @compileError("zsl.numeric.sub: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .int => return int.Sub(X, Y),
            .float => return float.Sub(X, Y),
            .dyadic => return dyadic.Sub(X, Y),
            .complex => return complex.Sub(X, Y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.Sub(X, Y),
            .float => return float.Sub(X, Y),
            .dyadic => return dyadic.Sub(X, Y),
            .complex => return complex.Sub(X, Y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => return float.Sub(X, Y),
            .dyadic => return dyadic.Sub(X, Y),
            .complex => return complex.Sub(X, Y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => return dyadic.Sub(X, Y),
            .complex => return complex.Sub(X, Y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic, .complex => return complex.Sub(X, Y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs subtraction between any two numeric operands.
///
/// ## Signature
/// ```zig
/// numeric.sub(x: X, y: Y) numeric.Sub(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `numeric.Sub(@TypeOf(x), @TypeOf(y))`: The result of the subtraction.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `Sub` method. The expected
/// signature and behavior of `Sub` are as follows:
/// * `fn Sub(type, type) type`: Returns the type of `x - y`.
///
/// `numeric.Sub(X, Y)`, `X` or `Y` must implement the required `sub` method.
/// The expected signatures and behavior of `sub` are as follows:
/// * `fn sub(X, Y) numeric.Sub(X, Y)`: Returns the subtraction of `x` and
///   `y`.
pub inline fn sub(x: anytype, y: anytype) numeric.Sub(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = numeric.Sub(X, Y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "sub",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.sub: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn sub(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.sub(x, y);
        } else { // only X custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "sub",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.sub: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn sub(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.sub(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "sub",
            fn (X, Y) R,
            &.{ X, Y },
        ) orelse
            @compileError("zsl.numeric.sub: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn sub(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

        return Impl.sub(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => unreachable,
            .int => return int.sub(x, y),
            .float => return float.sub(x, y),
            .dyadic => return dyadic.sub(x, y),
            .complex => return complex.sub(x, y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.sub(x, y),
            .float => return float.sub(x, y),
            .dyadic => return dyadic.sub(x, y),
            .complex => return complex.sub(x, y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => return float.sub(x, y),
            .dyadic => return dyadic.sub(x, y),
            .complex => return complex.sub(x, y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => return dyadic.sub(x, y),
            .complex => return complex.sub(x, y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic, .complex => return complex.sub(x, y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
