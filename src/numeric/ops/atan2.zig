const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Atan2(Y: type, X: type) type {
    comptime if (!types.isNumeric(Y) or !types.isNumeric(X))
        @compileError("zml.numeric.atan2: x and y must be numerics, got \n\ty: " ++ @typeName(Y) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    if (comptime types.isCustomType(Y)) {
        if (comptime types.isCustomType(X)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ Y, X },
                "ZmlAtan2",
                fn (type, type) type,
                &.{ Y, X },
            ) orelse
                @compileError("zml.numeric.atan2: " ++ @typeName(Y) ++ " or " ++ @typeName(X) ++ " must implement `fn ZmlAtan2(type, type) type`");

            return Impl.ZmlAtan2(Y, X);
        } else { // only Y custom
            comptime if (!types.hasMethod(Y, "ZmlAtan2", fn (type, type) type, &.{ Y, X }))
                @compileError("zml.numeric.atan2: " ++ @typeName(Y) ++ " must implement `fn ZmlAtan2(type, type) type`");

            return Y.ZmlAtan2(Y, X);
        }
    } else if (comptime types.isCustomType(X)) { // only Y custom
        comptime if (!types.hasMethod(Y, "ZmlAtan2", fn (type, type) type, &.{ Y, X }))
            @compileError("zml.numeric.atan2: " ++ @typeName(X) ++ " must implement `fn ZmlAtan2(type, type) type`");

        return X.ZmlAtan2(Y, X);
    }

    switch (comptime types.numericType(Y)) {
        .bool => switch (comptime types.numericType(X)) {
            .bool => @compileError("zml.numeric.atan2: not defined for " ++ @typeName(Y) ++ " and " ++ @typeName(X) ++ "."),
            .int => @compileError("zml.numeric.atan2: not defined for " ++ @typeName(Y) ++ " and " ++ @typeName(X) ++ "."),
            .rational => return rational.Atan2(Y, X),
            .float => return float.Atan2(Y, X),
            .dyadic => return dyadic.Atan2(Y, X),
            .complex => return complex.Atan2(Y, X),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(X)) {
            .bool, .int => @compileError("zml.numeric.atan2: not defined for " ++ @typeName(Y) ++ " and " ++ @typeName(X) ++ "."),
            .rational => return rational.Atan2(Y, X),
            .float => return float.Atan2(Y, X),
            .dyadic => return dyadic.Atan2(Y, X),
            .complex => return complex.Atan2(Y, X),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(X)) {
            .bool, .int, .rational => return rational.Atan2(Y, X),
            .float => return float.Atan2(Y, X),
            .dyadic => return dyadic.Atan2(Y, X),
            .complex => return complex.Atan2(Y, X),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(X)) {
            .bool, .int, .rational, .float => return float.Atan2(Y, X),
            .dyadic => return dyadic.Atan2(Y, X),
            .complex => return complex.Atan2(Y, X),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(X)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.Atan2(Y, X),
            .complex => return complex.Atan2(Y, X),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(X)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.Atan2(Y, X),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Computes the arctangent `tan⁻¹(y/x)` of any two numeric operands, using the
/// signs of both arguments to determine the correct quadrant of the result.
///
/// ## Signature
/// ```zig
/// numeric.atan2(y: Y, x: X) numeric.Atan2(Y, X)
/// ```
///
/// ## Arguments
/// * `y` (`anytype`): The `y` coordinate.
/// * `x` (`anytype`): The `x` coordinate.
///
/// ## Returns
/// `numeric.Atan2(@TypeOf(y), @TypeOf(x))`: The arctangent of `y/x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `Y` or `X` must implement the required `ZmlAtan2` method. The expected
/// signature and behavior of `ZmlAtan2` are as follows:
/// * `fn ZmlAtan2(type, type) type`: Returns the type of the arctangent of `y/x`.
///
/// `numeric.Atan2(Y, X)`, `Y` or `X` must implement the required `zmlAtan2` method.
/// The expected signatures and behavior of `zmlAtan2` are as follows:
/// * `fn zmlAtan2(Y, X) numeric.Atan2(Y, X)`: Returns the arctangent of `y/x`.
pub inline fn atan2(y: anytype, x: anytype) numeric.Atan2(@TypeOf(y), @TypeOf(x)) {
    const Y: type = @TypeOf(y);
    const X: type = @TypeOf(x);
    const R: type = numeric.Atan2(Y, X);

    if (comptime types.isCustomType(Y)) {
        if (comptime types.isCustomType(X)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, Y, X },
                "zmlAtan2",
                fn (Y, X) R,
                &.{ Y, X },
            ) orelse
                @compileError("zml.numeric.atan2: " ++ @typeName(R) ++ ", " ++ @typeName(Y) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAtan2(" ++ @typeName(Y) ++ ", " ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAtan2(y, x);
        } else { // only Y custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, Y },
                "zmlAtan2",
                fn (Y, X) R,
                &.{ Y, X },
            ) orelse
                @compileError("zml.numeric.atan2: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlAtan2(" ++ @typeName(Y) ++ ", " ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAtan2(y, x);
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, X },
            "zmlAtan2",
            fn (Y, X) R,
            &.{ Y, X },
        ) orelse
            @compileError("zml.numeric.atan2: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAtan2(" ++ @typeName(Y) ++ ", " ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

        return Impl.zmlAtan2(y, x);
    }

    switch (comptime types.numericType(Y)) {
        .bool => switch (comptime types.numericType(X)) {
            .bool => unreachable,
            .int => unreachable,
            .rational => return rational.atan2(y, x),
            .float => return float.atan2(y, x),
            .dyadic => return dyadic.atan2(y, x),
            .complex => return complex.atan2(y, x),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(X)) {
            .bool, .int => unreachable,
            .rational => return rational.atan2(y, x),
            .float => return float.atan2(y, x),
            .dyadic => return dyadic.atan2(y, x),
            .complex => return complex.atan2(y, x),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(X)) {
            .bool, .int, .rational => return rational.atan2(y, x),
            .float => return float.atan2(y, x),
            .dyadic => return dyadic.atan2(y, x),
            .complex => return complex.atan2(y, x),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(X)) {
            .bool, .int, .rational, .float => return float.atan2(y, x),
            .dyadic => return dyadic.atan2(y, x),
            .complex => return complex.atan2(y, x),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(X)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.atan2(y, x),
            .complex => return complex.atan2(y, x),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(X)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.atan2(y, x),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
