const types = @import("../../types.zig");
const numeric = @import("../../numeric.zig");

/// Performs in-place computation of the subtraction of two numerics `x` and `y`
/// into a numeric `o`.
///
/// ## Signature
/// ```zig
/// numeric.sub_(o: *O, x: X, y: Y) void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `void`
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `O`, `X` or `Y` should implement the required `sub_` method. The expected
/// signature and behavior of `sub_` are as follows:
/// * `fn sub_(*O, X, Y) void`: Computes the subtraction of `x` and `y` and
///   stores it in `o`.
///
/// If none of `O`, `X` and `Y` implement the required `sub_` method, the
/// function will fall back to using `numeric.set` with the result of
/// `numeric.sub`, potentially resulting in a less efficient implementation. In
/// this case, `O`, `X` and `Y` must adhere to the requirements of these functions.
pub fn sub_(o: anytype, x: anytype, y: anytype) void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X) or
        !types.isNumeric(Y))
        @compileError("zsl.numeric.sub_: o must be a mutable one-item pointer to a numeric, and x and y must be numerics, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) {
            if (comptime types.isCustomType(Y)) { // O, X and Y all custom
                if (comptime types.anyHasMethod(&.{ O, X, Y }, "sub_", fn (*O, X, Y) void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            } else { // only O and X custom
                if (comptime types.anyHasMethod(&.{ O, X }, "sub_", fn (*O, X, Y) void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            }
        } else {
            if (comptime types.isCustomType(Y)) { // only O and Y custom
                if (comptime types.anyHasMethod(&.{ O, Y }, "sub_", fn (*O, X, Y) void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            } else { // only O custom
                if (comptime types.hasMethod(O, "sub_", fn (*O, X, Y) void, &.{ *O, X, Y }))
                    return O.sub_(o, x, y);
            }
        }
    } else {
        if (comptime types.isCustomType(X)) {
            if (comptime types.isCustomType(Y)) { // only X and Y custom
                if (comptime types.anyHasMethod(&.{ X, Y }, "sub_", fn (*O, X, Y) void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            } else { // only X custom
                if (comptime types.hasMethod(X, "sub_", fn (*O, X, Y) void, &.{ *O, X, Y }))
                    return X.sub_(o, x, y);
            }
        } else if (comptime types.isCustomType(Y)) { // only Y custom
            if (comptime types.hasMethod(Y, "sub_", fn (*O, X, Y) void, &.{ *O, X, Y }))
                return Y.sub_(o, x, y);
        }
    }

    return numeric.set(o, numeric.sub(x, y));
}
