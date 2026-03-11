const types = @import("../../types.zig");
const numeric = @import("../../numeric.zig");

/// Performs in-place computation of the arctangent `tan⁻¹(y/x)` of two numerics
/// `y` and `x` into a numeric `o`, using the signs of both arguments to
/// determine the correct quadrant of the result.
///
/// ## Signature
/// ```zig
/// numeric.atan2_(o: *O, y: Y, x: X) void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `y` (`anytype`): The `y` coordinate.
/// * `x` (`anytype`): The `x` coordinate.
///
/// ## Returns
/// `void`
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `O`, `Y` or `X` should implement the required `atan2_` method. The expected
/// signature and behavior of `atan2_` are as follows:
/// * `fn atan2_(*O, Y, X) void`: Computes the arctangent of `y/x` and stores it in
///   `o`.
///
/// If none of `O`, `Y` and `X` implement the required `atan2_` method, the
/// function will fall back to using `numeric.set` with the result of
/// `numeric.atan2`, potentially resulting in a less efficient implementation. In
/// this case, `O`, `Y` and `X` must adhere to the requirements of these
/// functions.
pub inline fn atan2_(o: anytype, y: anytype, x: anytype) void {
    comptime var O: type = @TypeOf(o);
    const Y: type = @TypeOf(y);
    const X: type = @TypeOf(x);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(Y) or
        !types.isNumeric(X))
        @compileError("zsl.numeric.atan2_: o must be a mutable one-item pointer to a numeric, and y and x must be numerics, got \n\to: " ++ @typeName(O) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(Y)) {
            if (comptime types.isCustomType(X)) { // O, Y and X all custom
                if (comptime types.anyHasMethod(&.{ O, Y, X }, "atan2_", fn (*O, Y, X) void, &.{ *O, Y, X })) |Impl|
                    return Impl.atan2_(o, y, x);
            } else { // only O and Y custom
                if (comptime types.anyHasMethod(&.{ O, Y }, "atan2_", fn (*O, Y, X) void, &.{ *O, Y, X })) |Impl|
                    return Impl.atan2_(o, y, x);
            }
        } else {
            if (comptime types.isCustomType(X)) { // only O and X custom
                if (comptime types.anyHasMethod(&.{ O, X }, "atan2_", fn (*O, Y, X) void, &.{ *O, Y, X })) |Impl|
                    return Impl.atan2_(o, y, x);
            } else { // only O custom
                if (comptime types.hasMethod(O, "atan2_", fn (*O, Y, X) void, &.{ *O, Y, X }))
                    return O.atan2_(o, y, x);
            }
        }
    } else {
        if (comptime types.isCustomType(Y)) {
            if (comptime types.isCustomType(X)) { // only Y and X custom
                if (comptime types.anyHasMethod(&.{ Y, X }, "atan2_", fn (*O, Y, X) void, &.{ *O, Y, X })) |Impl|
                    return Impl.atan2_(o, y, x);
            } else { // only Y custom
                if (comptime types.hasMethod(Y, "atan2_", fn (*O, Y, X) void, &.{ *O, Y, X }))
                    return Y.atan2_(o, y, x);
            }
        } else if (comptime types.isCustomType(X)) { // only X custom
            if (comptime types.hasMethod(Y, "atan2_", fn (*O, Y, X) void, &.{ *O, Y, X }))
                return Y.atan2_(o, y, x);
        }
    }

    return numeric.set(o, numeric.atan2(y, x));
}
