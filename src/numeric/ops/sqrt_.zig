const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

/// Performs in-place computation of the square root `√x` of a numeric `x` into
/// a numeric `o`.
///
/// ## Signature
/// ```zig
/// numeric.sqrt_(o: *O, x: X) void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The numeric value to get the square root of.
///
/// ## Returns
/// `void`
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `O` or `X` should implement the required `zmlSqrt_` method. The expected
/// signature and behavior of `zmlSqrt_` are as follows:
/// * `fn zmlSqrt_(*O, X) void`: Computes the square root of `x` and stores it
///   in `o`.
///
/// If neither `O` nor `X` implement the required `zmlSqrt_` method, the function
/// will fall back to using `numeric.set` with the result of `numeric.sqrt`,
/// potentially resulting in a less efficient implementation. In this case, `O`
/// and `X` must adhere to the requirements of these functions.
pub inline fn sqrt_(o: anytype, x: anytype) void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X))
        @compileError("zml.numeric.sqrt_: o must be a mutable one-item pointer to a numeric, and x must be a numeric, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) { // O and X both custom
            if (comptime types.anyHasMethod(&.{ O, X }, "zmlSqrt_", fn (*O, X) void, &.{ *O, X })) |Impl|
                return Impl.zmlSqrt_(o, x);
        } else { // only O custom
            if (comptime types.hasMethod(O, "zmlSqrt_", fn (*O, X) void, &.{ *O, X }))
                return O.zmlSqrt_(o, x);
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        if (comptime types.hasMethod(X, "zmlSqrt_", fn (*O, X) void, &.{ *O, X }))
            return X.zmlSqrt_(o, x);
    }

    return numeric.set(o, numeric.sqrt(x));
}
