const meta = @import("../../meta.zig");

const numeric = @import("../../numeric.zig");

const vecops = @import("../ops.zig");

/// Performs in-place computation of the multiplication of a vectors and a
/// numeric, `x` and `y`, into a vector `o`.
///
/// Exact aliasing (in-place modification) between the output and an input is
/// permitted and often more efficient. Any other form of memory overlap might
/// yield incorrect results.
///
/// ## Signature
/// ```zig
/// vector.mul_(o: *O, x: X, y: Y) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output vector operand.
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `vector.Error.DimensionMismatch`: If the two vectors do not have the same
///   length.
///
/// ## Custom type support
/// This function supports custom vector types via specific method
/// implementations.
///
/// `O`, `X` or `Y` must implement the required `mul_` method. The expected
/// signatures and behavior of `mul_` are as follows:
/// * `fn mul_(*O, X, Y) !void`: Computes the multiplication of `x` and `y` into
///   `o`.
///
/// If none of `O`, `X` and `Y` implement the required `mul_` method, the
/// function will fall back to using `vector.apply2_` with `numeric.mul_`,
/// potentially resulting in a less efficient implementation. In this case, `O`,
/// `X` and `Y` must adhere to the requirements of these functions.
pub fn mul_(o: anytype, x: anytype, y: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isPointer(O) or meta.isConstPointer(O) or !meta.isVector(meta.Child(O)) or
        (!meta.isVector(X) and !meta.isNumeric(X)) or (!meta.isVector(Y) and !meta.isNumeric(Y)) or
        (!meta.isVector(X) and !meta.isVector(Y)))
        @compileError("zsl.vector.mul_: o must be a mutable one-itme pointer to a vector, and at least one of x or y must be a vector, the other must be a vector or a numeric, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    O = meta.Child(O);

    if (comptime meta.isCustomType(O)) {
        if (comptime meta.isCustomType(X) and meta.isVector(X)) { // only O and X custom vectors
            if (comptime meta.anyHasMethod(&.{ O, X }, "mul_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                return Impl.mul_(o, x, y);
        } else if (comptime meta.isCustomType(Y) and meta.isVector(Y)) { // only O and Y custom vectors
            if (comptime meta.anyHasMethod(&.{ O, Y }, "mul_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                return Impl.mul_(o, x, y);
        } else { // only O custom vector
            if (comptime meta.hasMethod(O, "mul_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                return O.mul_(o, x, y);
        }
    } else if (comptime meta.isCustomType(X)) { // only X custom vector
        if (comptime meta.hasMethod(X, "mul_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
            return X.mul_(o, x, y);
    } else if (comptime meta.isCustomType(Y)) { // only Y custom vector
        if (comptime meta.hasMethod(Y, "mul_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
            return Y.mul_(o, x, y);
    }

    return vecops.apply2_(o, x, y, numeric.mul_);
}
