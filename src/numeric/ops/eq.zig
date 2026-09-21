const meta = @import("../../meta.zig");
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
pub fn eq(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const C: type = numeric.Coerce(X, Y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y))
        @compileError("zsl.numeric.eq: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime meta.isCustomNumeric(X)) {
        if (comptime meta.isCustomNumeric(Y)) { // X and Y both custom
            const Impl: type = comptime meta.anyHasMethod(
                &.{ X, Y },
                "eq",
                fn (X, Y) bool,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.eq: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn eq(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return Impl.eq(x, y);
        } else { // only X custom
            comptime if (!meta.hasMethod(X, "eq", fn (X, Y) bool, &.{ X, Y }))
                @compileError("zsl.numeric.eq: " ++ @typeName(X) ++ " must implement `fn eq(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

            return X.eq(x, y);
        }
    } else if (comptime meta.isCustomNumeric(Y)) { // only Y custom
        comptime if (!meta.hasMethod(Y, "eq", fn (X, Y) bool, &.{ X, Y }))
            @compileError("zsl.numeric.eq: " ++ @typeName(Y) ++ " must implement `fn eq(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") bool`");

        return Y.eq(x, y);
    }

    switch (comptime meta.numericType(X)) {
        .bool, .int, .float => switch (comptime meta.numericType(Y)) {
            .bool, .int, .float => return numeric.cast(C, x) == numeric.cast(C, y),
            .dyadic => return numeric.order(x, y) == .eq,
            .complex => return numeric.eq(numeric.re(x), numeric.re(y)) and numeric.eq(numeric.im(x), numeric.im(y)),
            .custom => unreachable,
        },
        .dyadic => switch (comptime meta.numericType(Y)) {
            .bool, .int, .float, .dyadic => return numeric.order(x, y) == .eq,
            .complex => return numeric.eq(numeric.re(x), numeric.re(y)) and numeric.eq(numeric.im(x), numeric.im(y)),
            .custom => unreachable,
        },
        .complex => switch (comptime meta.numericType(meta.Scalar(X))) {
            .bool, .int, .float, .dyadic, .complex => return numeric.eq(numeric.re(x), numeric.re(y)) and numeric.eq(numeric.im(x), numeric.im(y)),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
