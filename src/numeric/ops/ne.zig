const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

/// Compares any two numerics `x` and `y` for inequality.
///
/// ## Signature
/// ```zig
/// numeric.ne(x: X, y: Y) bool
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `bool`: `true` if the operands are not equal, `false` otherwise.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `zmlNe` method. The expected
/// signature and behavior of `zmlNe` are as follows:
/// * `fn zmlNe(X, Y) bool`: Compares `x` and `y` for inequality.
pub inline fn ne(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "zmlNe",
                fn (X, Y) bool,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.ne: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlNe(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return Impl.zmlNe(x, y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "zmlNe", fn (X, Y) bool, &.{ X, Y }))
                @compileError("zml.numeric.ne: " ++ @typeName(X) ++ " must implement `fn zmlNe(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return X.zmlNe(x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "zmlNe", fn (X, Y) bool, &.{ X, Y }))
            @compileError("zml.numeric.ne: " ++ @typeName(Y) ++ " must implement `fn zmlNe(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

        return Y.zmlNe(x, y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => return x == y,
            .int => return int.ne(x, y),
            .rational => return rational.ne(x, y),
            .float => return float.ne(x, y),
            .dyadic => return dyadic.ne(x, y),
            .complex => return complex.ne(x, y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.ne(x, y),
            .rational => return rational.ne(x, y),
            .float => return float.ne(x, y),
            .dyadic => return dyadic.ne(x, y),
            .complex => return complex.ne(x, y),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => return rational.ne(x, y),
            .float => return float.ne(x, y),
            .dyadic => return dyadic.ne(x, y),
            .complex => return complex.ne(x, y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => return float.ne(x, y),
            .dyadic => return dyadic.ne(x, y),
            .complex => return complex.ne(x, y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => return dyadic.ne(x, y),
            .complex => return complex.ne(x, y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => return complex.ne(x, y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
