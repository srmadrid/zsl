const types = @import("../../types.zig");

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
pub inline fn sub_(o: anytype, x: anytype, y: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or !types.isMatrix(types.Child(O)) or
        !types.isMatrix(X) or !types.isMatrix(Y))
        @compileError("zsl.matrix.sub_: o must be a mutable one-itme pointer to a matrix, and x and y must be matrices, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) {
            if (comptime types.isCustomType(Y)) { // O, X and Y all custom matrices
                if (comptime types.anyHasMethod(&.{ O, X, Y }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            } else { // only O and X custom matrices
                if (comptime types.anyHasMethod(&.{ O, X }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            }
        } else if (comptime types.isCustomType(Y)) {
            if (comptime types.isCustomType(Y)) { // only O and Y custom matrices
                if (comptime types.anyHasMethod(&.{ O, Y }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            } else { // only O matrix
                if (comptime types.hasMethod(O, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                    return O.sub_(o, x, y);
            }
        }
    } else if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // only X and Y custom matrices
            if (comptime types.anyHasMethod(&.{ X, Y }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                return Impl.sub_(o, x, y);
        } else { // only X custom matrix
            if (comptime types.hasMethod(X, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                return X.sub_(o, x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom matrix
        if (comptime types.hasMethod(Y, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
            return Y.sub_(o, x, y);
    }

    return matops.apply2_(o, x, y, numeric.sub_);
}
