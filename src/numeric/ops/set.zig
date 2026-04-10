const types = @import("../../types.zig");
const numeric = @import("../../numeric.zig");

/// Sets the value of `o` to `x`.
///
/// ## Signature
/// ```zig
/// numeric.set(o: *O, x: X) void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The input operand.
///
/// ## Returns
/// `void`
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `O` or `X` should implement the required `set` method. The expected
/// signature and behavior of `set` are as follows:
/// * `fn set(*O, X) void`: Sets the value of `o` to `x`.
///
/// If neither `O` nor `X` implement the required `set` method, the function
/// will fall back to assigning the result of `numeric.cast` directly to `o`. In
/// this case, `O` and `X` must adhere to the requirements of this function.
pub fn set(o: anytype, x: anytype) void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X))
        @compileError("zsl.numeric.set: o must be a mutable one-itme pointer to a numeric, and x must be a numeric, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) { // O and X both custom
            if (comptime types.anyHasMethod(
                &.{ O, X },
                "set",
                fn (*O, X) void,
                &.{ *O, X },
            )) |Impl|
                return Impl.set(o, x);
        } else { // only O custom
            comptime if (types.hasMethod(O, "set", fn (*O, X) void, &.{ *O, X }))
                return O.set(o, x);

            return O.set(o, x);
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        comptime if (types.hasMethod(X, "set", fn (*O, X) void, &.{ *O, X }))
            return X.set(o, x);
    }

    o.* = numeric.cast(O, x);
}
