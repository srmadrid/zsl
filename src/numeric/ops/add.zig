const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Add(X: type, Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zml.numeric.add: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "ZmlAdd",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.add: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn ZmlAdd(type, type) type`");

            return Impl.ZmlAdd(X, Y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "ZmlAdd", fn (type, type) type, &.{ X, Y }))
                @compileError("zml.numeric.add: " ++ @typeName(X) ++ " must implement `fn ZmlAdd(type, type) type`");

            return X.ZmlAdd(X, Y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "ZmlAdd", fn (type, type) type, &.{ X, Y }))
            @compileError("zml.numeric.add: " ++ @typeName(Y) ++ " must implement `fn ZmlAdd(type, type) type`");

        return Y.ZmlAdd(X, Y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => @compileError("zml.numeric.add: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .int => return int.Add(X, Y),
            .rational => return rational.Add(X, Y),
            .float => return float.Add(X, Y),
            .dyadic => return dyadic.Add(X, Y),
            .complex => return complex.Add(X, Y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.Add(X, Y),
            .rational => return rational.Add(X, Y),
            .float => return float.Add(X, Y),
            .dyadic => return dyadic.Add(X, Y),
            .complex => return complex.Add(X, Y),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.Add(X, Y),
            .float => return float.Add(X, Y),
            .dyadic => return dyadic.Add(X, Y),
            .complex => return complex.Add(X, Y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.Add(X, Y),
            .dyadic => return dyadic.Add(X, Y),
            .complex => return complex.Add(X, Y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.Add(X, Y),
            .complex => return complex.Add(X, Y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.Add(X, Y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs addition between any two numeric operands.
///
/// ## Signature
/// ```zig
/// numeric.add(x: X, y: Y) numeric.Add(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `numeric.Add(@TypeOf(x), @TypeOf(y))`: The result of the addition.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `ZmlAdd` method. The expected
/// signature and behavior of `ZmlAdd` are as follows:
/// * `fn ZmlAdd(type, type) type`: Returns the type of `x + y`.
///
/// `numeric.Add(X, Y)`, `X` or `Y` must implement the required `zmlAdd` method.
/// The expected signatures and behavior of `zmlAdd` are as follows:
/// * `fn zmlAdd(X, Y) numeric.Add(X, Y)`: Returns the addition of `x` and `y`.
pub inline fn add(x: anytype, y: anytype) numeric.Add(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = numeric.Add(X, Y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "zmlAdd",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.add: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlAdd(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAdd(x, y);
        } else { // only X custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAdd",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.add: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAdd(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAdd(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "zmlAdd",
            fn (X, Y) R,
            &.{ X, Y },
        ) orelse
            @compileError("zml.numeric.add: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlAdd(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

        return Impl.zmlAdd(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => unreachable,
            .int => return int.add(x, y),
            .rational => return rational.add(x, y),
            .float => return float.add(x, y),
            .dyadic => return dyadic.add(x, y),
            .complex => return complex.add(x, y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.add(x, y),
            .rational => return rational.add(x, y),
            .float => return float.add(x, y),
            .dyadic => return dyadic.add(x, y),
            .complex => return complex.add(x, y),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.add(x, y),
            .float => return float.add(x, y),
            .dyadic => return dyadic.add(x, y),
            .complex => return complex.add(x, y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.add(x, y),
            .dyadic => return dyadic.add(x, y),
            .complex => return complex.add(x, y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.add(x, y),
            .complex => return complex.add(x, y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.add(x, y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
