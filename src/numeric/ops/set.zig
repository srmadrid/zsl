const types = @import("../../types.zig");

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
/// `O` or `X` must implement the required `zmlSet` method. The expected
/// signature and behavior of `zmlSet` are as follows:
/// * `fn zmlSet(*O, X) void`: Sets the value of `o` to `x`.
pub inline fn set(o: anytype, x: anytype) void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X))
        @compileError("zml.numeric.set: o must be a mutable one-itme pointer to a numeric, and x must be a numeric, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) { // O and X both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ O, X },
                "zmlSet",
                fn (*O, X) void,
                &.{ *O, X },
            ) orelse
                @compileError("zml.numeric.set: " ++ @typeName(O) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSet(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ") void`");

            return Impl.set(o, x);
        } else { // only O custom
            comptime if (!types.hasMethod(O, "zmlSet", fn (*O, X) void, &.{ *O, X }))
                @compileError("zml.numeric.set: " ++ @typeName(O) ++ " must implement `fn zmlSet(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ") void`");

            return O.zmlSet(o, x);
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        comptime if (!types.hasMethod(X, "zmlSet", fn (*O, X) void, &.{ *O, X }))
            @compileError("zml.numeric.set: " ++ @typeName(X) ++ " must implement `fn zmlSet(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ") void`");

        return X.zmlSet(o, x);
    }

    o.* = types.scast(O, x);
}
