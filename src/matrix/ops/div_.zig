const meta = @import("../../meta.zig");

const numeric = @import("../../numeric.zig");

const matops = @import("../ops.zig");

/// Performs in-place computation of the division of a matrix `x` and a numeric
/// `y` into a matrix `o`.
///
/// ## Signature
/// ```zig
/// matrix.div_(o: *O, x: X, y: Y) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output matrix operand.
/// * `x` (`anytype`): The left matrix operand.
/// * `y` (`anytype`): The right numeric operand.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `matrix.Error.DimensionMismatch`: If the two matrices do not have the
///   same dimensions.
///
/// ## Custom type support
/// This function supports custom matrix types via specific method
/// implementations.
///
/// `O` or `X` must implement the required `div_` method. The expected
/// signatures and behavior of `div_` are as follows:
/// * `fn div_(*O, X, Y) !void`: Computes the division of `x` and `y` into `o`.
///
/// If none of `O`, `X` and `Y` implement the required `div_` method, the
/// function will fall back to using `matrix.apply2_` with `numeric.div_`,
/// potentially resulting in a less efficient implementation. In this case, `O`,
/// `X` and `Y` must adhere to the requirements of these functions.
pub fn div_(o: anytype, x: anytype, y: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isPointer(O) or meta.isConstPointer(O) or !meta.isMatrix(meta.Child(O)) or
        !meta.isMatrix(X) or !meta.isNumeric(Y))
        @compileError("zsl.matrix.div_: o must be a mutable one-itme pointer to a matrix, x must be a matrix, and y must be a numeric, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    O = meta.Child(O);

    if (comptime meta.isCustomType(O)) {
        if (comptime meta.isCustomType(X)) { // only O and X custom matrices
            if (comptime meta.anyHasMethod(&.{ O, X }, "div_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                return Impl.div_(o, x, y);
        } else { // only O matrix
            if (comptime meta.hasMethod(O, "div_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                return O.div_(o, x, y);
        }
    } else if (comptime meta.isCustomType(X)) { // only X custom matrix
        if (comptime meta.hasMethod(X, "div_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
            return X.div_(o, x, y);
    }

    return matops.apply2_(o, x, y, numeric.div_);
}
