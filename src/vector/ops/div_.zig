const types = @import("../../types.zig");

const numeric = @import("../../numeric.zig");

const vecops = @import("../ops.zig");

/// Performs in-place computation of the division of a vector `x` and a numeric
/// `y` into a vector `o`.
///
/// ## Signature
/// ```zig
/// vector.div_(o: *O, x: X, y: Y) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output vector operand.
/// * `x` (`anytype`): The left vector operand.
/// * `y` (`anytype`): The right numeric operand.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `vector.Error.DimensionMismatch`: If the two vectors do not have the
///   same length.
///
/// ## Custom type support
/// This function supports custom vector types via specific method
/// implementations.
///
/// `O` or `X` must implement the required `div_` method. The expected
/// signatures and behavior of `div_` are as follows:
/// * `fn div_(*O, X, Y) !void`: Computes the division of `x` and `y` into `o`.
///
/// If none of `O`, `X` and `Y` implement the required `div_` method, the
/// function will fall back to using `vector.apply2_` with `numeric.div_`,
/// potentially resulting in a less efficient implementation. In this case, `O`,
/// `X` and `Y` must adhere to the requirements of these functions.
pub fn div_(o: anytype, x: anytype, y: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or !types.isVector(types.Child(O)) or
        !types.isVector(X) or !types.isNumeric(Y))
        @compileError("zsl.vector.div_: o must be a mutable one-itme pointer to a vector, x must be a vector, and y must be a numeric, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) { // only O and X custom vectors
            if (comptime types.anyHasMethod(&.{ O, X }, "div_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                return Impl.div_(o, x, y);
        } else { // only O vector
            if (comptime types.hasMethod(O, "div_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                return O.div_(o, x, y);
        }
    } else if (comptime types.isCustomType(X)) { // only X custom vector
        if (comptime types.hasMethod(X, "div_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
            return X.div_(o, x, y);
    }

    return vecops.apply2_(o, x, y, numeric.div_);
}
