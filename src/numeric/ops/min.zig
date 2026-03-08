const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Min(X: type, Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zml.numeric.min: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "ZmlMin",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.min: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn ZmlMin(type, type) type`");

            return Impl.ZmlMin(X, Y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "ZmlMin", fn (type, type) type, &.{ X, Y }))
                @compileError("zml.numeric.min: " ++ @typeName(X) ++ " must implement `fn ZmlMin(type, type) type`");

            return X.ZmlMin(X, Y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "ZmlMin", fn (type, type) type, &.{ X, Y }))
            @compileError("zml.numeric.min: " ++ @typeName(Y) ++ " must implement `fn ZmlMin(type, type) type`");

        return Y.ZmlMin(X, Y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return bool,
            .int => return int.Min(X, Y),
            .rational => return rational.Min(X, Y),
            .float => return float.Min(X, Y),
            .dyadic => return dyadic.Min(X, Y),
            .complex => @compileError("zml.numeric.min: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.Min(X, Y),
            .rational => return rational.Min(X, Y),
            .float => return float.Min(X, Y),
            .dyadic => return dyadic.Min(X, Y),
            .complex => @compileError("zml.numeric.min: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.Min(X, Y),
            .float => return float.Min(X, Y),
            .dyadic => return dyadic.Min(X, Y),
            .complex => @compileError("zml.numeric.min: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.Min(X, Y),
            .dyadic => return dyadic.Min(X, Y),
            .complex => @compileError("zml.numeric.min: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.Min(X, Y),
            .complex => @compileError("zml.numeric.min: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .complex => @compileError("zml.numeric.min: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
        .custom => unreachable,
    }
}

/// Returns the minimum between any two numeric operands.
///
/// ## Signature
/// ```zig
/// numeric.min(x: X, y: Y) numeric.Min(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `numeric.Min(@TypeOf(x), @TypeOf(y))`: The minimum between `x` and `y`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `ZmlMin` method. The expected
/// signature and behavior of `ZmlMin` are as follows:
/// * `fn ZmlMin(type, type) type`: Returns the type of `x + y`.
///
/// `numeric.Min(X, Y)`, `X` or `Y` must implement the required `zmlMin` method.
/// The expected signatures and behavior of `zmlMin` are as follows:
/// * `fn zmlMin(X, Y) numeric.Min(X, Y)`: Returns the minimum between `x` and
///   `y`.
pub inline fn min(x: anytype, y: anytype) numeric.Min(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = numeric.Min(X, Y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "zmlMin",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.min: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlMin(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlMin(x, y);
        } else { // only X custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlMin",
                fn (X, Y) R,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.min: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlMin(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlMin(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "zmlMin",
            fn (X, Y) R,
            &.{ X, Y },
        ) orelse
            @compileError("zml.numeric.min: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlMin(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") " ++ @typeName(R) ++ "`");

        return Impl.zmlMin(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return x and y,
            .int => return int.min(x, y),
            .rational => return rational.min(x, y),
            .float => return float.min(x, y),
            .dyadic => return dyadic.min(x, y),
            .complex => unreachable,
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.min(x, y),
            .rational => return rational.min(x, y),
            .float => return float.min(x, y),
            .dyadic => return dyadic.min(x, y),
            .complex => unreachable,
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.min(x, y),
            .float => return float.min(x, y),
            .dyadic => return dyadic.min(x, y),
            .complex => unreachable,
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.min(x, y),
            .dyadic => return dyadic.min(x, y),
            .complex => unreachable,
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.min(x, y),
            .complex => unreachable,
            .custom => unreachable,
        },
        .complex => unreachable,
        .custom => unreachable,
    }
}
