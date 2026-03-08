const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Pow(X: type, Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zml.numeric.pow: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "ZmlPow",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.pow: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn ZmlPow(type, type) type`");

            return Impl.ZmlPow(X, Y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "ZmlPow", fn (type, type) type, &.{ X, Y }))
                @compileError("zml.numeric.pow: " ++ @typeName(X) ++ " must implement `fn ZmlPow(type, type) type`");

            return X.ZmlPow(X, Y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "ZmlPow", fn (type, type) type, &.{ X, Y }))
            @compileError("zml.numeric.pow: " ++ @typeName(Y) ++ " must implement `fn ZmlPow(type, type) type`");

        return Y.ZmlPow(X, Y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => @compileError("zml.numeric.pow: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .int => return int.Pow(X, Y),
            .rational => return rational.Pow(X, Y),
            .float => return float.Pow(X, Y),
            .dyadic => return dyadic.Pow(X, Y),
            .complex => return complex.Pow(X, Y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.Pow(X, Y),
            .rational => return rational.Pow(X, Y),
            .float => return float.Pow(X, Y),
            .dyadic => return dyadic.Pow(X, Y),
            .complex => return complex.Pow(X, Y),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.Pow(X, Y),
            .float => return float.Pow(X, Y),
            .dyadic => return dyadic.Pow(X, Y),
            .complex => return complex.Pow(X, Y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.Pow(X, Y),
            .dyadic => return dyadic.Pow(X, Y),
            .complex => return complex.Pow(X, Y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.Pow(X, Y),
            .complex => return complex.Pow(X, Y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.Pow(X, Y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs exponentiation `xʸ` between any two numeric operands.
///
/// ## Signature
/// ```zig
/// numeric.pow(x: X, y: Y) numeric.Pow(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `numeric.Pow(@TypeOf(x), @TypeOf(y))`: The result of the exponentiation.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `ZmlPow` method. The expected
/// signature and behavior of `ZmlPow` are as follows:
/// * `fn ZmlPow(type, type) type`: Returns the type of `x + y`.
///
/// `numeric.Pow(X, Y)`, `X` or `Y` must implement the required `zmlPow` method.
/// The expected signatures and behavior of `zmlPow` are as follows:
/// * `fn zmlPow(X, Y) numeric.Pow(X, Y)`: Returns the exponentiation of `x` to
///   the power `y`.
pub inline fn pow(x: anytype, y: anytype) numeric.Pow(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = numeric.Pow(X, Y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "zmlPow",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.pow: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlPow(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlPow(x, y);
        } else { // only X custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlPow",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.pow: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlPow(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlPow(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "zmlPow",
            fn (X, Y) R,
            &.{ X, Y },
        ) orelse
            @compileError("zml.numeric.pow: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlPow(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

        return Impl.zmlPow(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => unreachable,
            .int => return int.pow(x, y),
            .rational => return rational.pow(x, y),
            .float => return float.pow(x, y),
            .dyadic => return dyadic.pow(x, y),
            .complex => return complex.pow(x, y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.pow(x, y),
            .rational => return rational.pow(x, y),
            .float => return float.pow(x, y),
            .dyadic => return dyadic.pow(x, y),
            .complex => return complex.pow(x, y),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.pow(x, y),
            .float => return float.pow(x, y),
            .dyadic => return dyadic.pow(x, y),
            .complex => return complex.pow(x, y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.pow(x, y),
            .dyadic => return dyadic.pow(x, y),
            .complex => return complex.pow(x, y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.pow(x, y),
            .complex => return complex.pow(x, y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.pow(x, y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
