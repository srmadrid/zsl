const meta = @import("../../meta.zig");

const numeric = @import("../../numeric.zig");

const matops = @import("../ops.zig");

/// Performs in-place computation of the subtraction of two matrices `x` and `y`
/// into a matrix `o`.
///
/// ## Signature
/// ```zig
/// matrix.sub_(o: *O, x: X, y: Y) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output matrix operand.
/// * `x` (`anytype`): The left matrix operand.
/// * `y` (`anytype`): The right matrix operand.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `matrix.Error.DimensionMismatch`: If the three matrices do not have the
///   same dimensions.
///
/// ## Custom type support
/// This function supports custom matrix types via specific method
/// implementations.
///
/// `O`, `X` or `Y` must implement the required `sub_` method. The expected
/// signatures and behavior of `sub_` are as follows:
/// * `fn sub_(*O, X, Y) !void`: Computes the subtraction of `x` and `y` into
///   `o`.
///
/// If none of `O`, `X` and `Y` implement the required `sub_` method, the
/// function will fall back to using `matrix.apply2_` with `numeric.sub_`,
/// potentially resulting in a less efficient implementation. In this case, `O`,
/// `X` and `Y` must adhere to the requirements of these functions.
pub fn sub_(o: anytype, x: anytype, y: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isPointer(O) or meta.isConstPointer(O) or !meta.isMatrix(meta.Child(O)) or
        !meta.isMatrix(X) or !meta.isMatrix(Y))
        @compileError("zsl.matrix.sub_: o must be a mutable one-itme pointer to a matrix, and x and y must be matrices, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    O = meta.Child(O);

    if (comptime meta.isCustomType(O)) {
        if (comptime meta.isCustomType(X)) {
            if (comptime meta.isCustomType(Y)) { // O, X and Y all custom matrices
                if (comptime meta.anyHasMethod(&.{ O, X, Y }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            } else { // only O and X custom matrices
                if (comptime meta.anyHasMethod(&.{ O, X }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            }
        } else if (comptime meta.isCustomType(Y)) {
            if (comptime meta.isCustomType(Y)) { // only O and Y custom matrices
                if (comptime meta.anyHasMethod(&.{ O, Y }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            } else { // only O matrix
                if (comptime meta.hasMethod(O, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                    return O.sub_(o, x, y);
            }
        }
    } else if (comptime meta.isCustomType(X)) {
        if (comptime meta.isCustomType(Y)) { // only X and Y custom matrices
            if (comptime meta.anyHasMethod(&.{ X, Y }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                return Impl.sub_(o, x, y);
        } else { // only X custom matrix
            if (comptime meta.hasMethod(X, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                return X.sub_(o, x, y);
        }
    } else if (comptime meta.isCustomType(Y)) { // only Y custom matrix
        if (comptime meta.hasMethod(Y, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
            return Y.sub_(o, x, y);
    }

    return matops.apply2_(o, x, y, numeric.sub_);
}
