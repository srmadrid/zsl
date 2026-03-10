const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

/// Compares any two numerics `x` and `y` for equality.
///
/// ## Signature
/// ```zig
/// numeric.eq(x: X, y: Y) bool
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `bool`: `true` if the operands are equal, `false` otherwise.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `eq` method. The expected
/// signature and behavior of `eq` are as follows:
/// * `fn eq(X, Y) bool`: Compares `x` and `y` for equality.
pub inline fn eq(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zsl.numeric.eq: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "eq",
                fn (X, Y) bool,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.eq: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn eq(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return Impl.eq(x, y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "eq", fn (X, Y) bool, &.{ X, Y }))
                @compileError("zsl.numeric.eq: " ++ @typeName(X) ++ " must implement `fn eq(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return X.eq(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "eq", fn (X, Y) bool, &.{ X, Y }))
            @compileError("zsl.numeric.eq: " ++ @typeName(Y) ++ " must implement `fn eq(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

        return Y.eq(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return x == y,
            .int => return int.eq(x, y),
            .rational => return rational.eq(x, y),
            .float => return float.eq(x, y),
            .dyadic => return dyadic.eq(x, y),
            .complex => return complex.eq(x, y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.eq(x, y),
            .rational => return rational.eq(x, y),
            .float => return float.eq(x, y),
            .dyadic => return dyadic.eq(x, y),
            .complex => return complex.eq(x, y),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.eq(x, y),
            .float => return float.eq(x, y),
            .dyadic => return dyadic.eq(x, y),
            .complex => return complex.eq(x, y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.eq(x, y),
            .dyadic => return dyadic.eq(x, y),
            .complex => return complex.eq(x, y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.eq(x, y),
            .complex => return complex.eq(x, y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.eq(x, y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
