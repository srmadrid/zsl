const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Mul(X: type, Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zml.numeric.mul: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "ZmlMul",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.mul: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn ZmlMul(type, type) type`");

            return Impl.ZmlMul(X, Y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "ZmlMul", fn (type, type) type, &.{ X, Y }))
                @compileError("zml.numeric.mul: " ++ @typeName(X) ++ " must implement `fn ZmlMul(type, type) type`");

            return X.ZmlMul(X, Y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "ZmlMul", fn (type, type) type, &.{ X, Y }))
            @compileError("zml.numeric.mul: " ++ @typeName(Y) ++ " must implement `fn ZmlMul(type, type) type`");

        return Y.ZmlMul(X, Y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => @compileError("zml.numeric.mul: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .int => return int.Mul(X, Y),
            .rational => return rational.Mul(X, Y),
            .float => return float.Mul(X, Y),
            .dyadic => return dyadic.Mul(X, Y),
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.Mul(X, Y),
            .rational => return rational.Mul(X, Y),
            .float => return float.Mul(X, Y),
            .dyadic => return dyadic.Mul(X, Y),
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.Mul(X, Y),
            .float => return float.Mul(X, Y),
            .dyadic => return dyadic.Mul(X, Y),
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.Mul(X, Y),
            .dyadic => return dyadic.Mul(X, Y),
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.Mul(X, Y),
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs multiplication between any two numeric operands.
///
/// ## Signature
/// ```zig
/// numeric.mul(x: X, y: Y) numeric.Mul(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `numeric.Mul(@TypeOf(x), @TypeOf(y))`: The result of the multiplication.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `ZmlMul` method. The expected
/// signature and behavior of `ZmlMul` are as follows:
/// * `fn ZmlMul(type, type) type`: Returns the type of `x * y`.
///
/// `numeric.Mul(X, Y)`, `X` or `Y` must implement the required `zmlMul` method.
/// The expected signatures and behavior of `zmlMul` are as follows:
/// * `fn zmlMul(X, Y) numeric.Mul(X, Y)`: Returns the multiplication of `x` and
///   `y`.
pub inline fn mul(x: anytype, y: anytype) numeric.Mul(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = numeric.Mul(X, Y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "zmlMul",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.mul: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlMul(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlMul(x, y);
        } else { // only X custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlMul",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.mul: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlMul(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlMul(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "zmlMul",
            fn (X, Y) R,
            &.{ X, Y },
        ) orelse
            @compileError("zml.numeric.mul: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlMul(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

        return Impl.zmlMul(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => unreachable,
            .int => return int.mul(x, y),
            .rational => return rational.mul(x, y),
            .float => return float.mul(x, y),
            .dyadic => return dyadic.mul(x, y),
            .complex => return complex.mul(x, y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.mul(x, y),
            .rational => return rational.mul(x, y),
            .float => return float.mul(x, y),
            .dyadic => return dyadic.mul(x, y),
            .complex => return complex.mul(x, y),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.mul(x, y),
            .float => return float.mul(x, y),
            .dyadic => return dyadic.mul(x, y),
            .complex => return complex.mul(x, y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.mul(x, y),
            .dyadic => return dyadic.mul(x, y),
            .complex => return complex.mul(x, y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.mul(x, y),
            .complex => return complex.mul(x, y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.mul(x, y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
