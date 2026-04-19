const meta = @import("../../meta.zig");

const numeric = @import("../../numeric.zig");

const vecops = @import("../ops.zig");

/// Performs in-place computation of the subtraction of two vectors `x` and `y`
/// into a vector `o`.
///
/// Exact aliasing (in-place modification) between the output and an input is
/// permitted and often more efficient. Any other form of memory overlap might
/// yield incorrect results.
///
/// ## Signature
/// ```zig
/// vector.sub_(o: *O, x: X, y: Y) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output vector operand.
/// * `x` (`anytype`): The left vector operand.
/// * `y` (`anytype`): The right vector operand.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `vector.Error.DimensionMismatch`: If the three vectors do not have the
///   same length.
///
/// ## Custom type support
/// This function supports custom vector types via specific method
/// implementations.
///
/// `O`, `X` or `Y` must implement the required `sub_` method. The expected
/// signatures and behavior of `sub_` are as follows:
/// * `fn sub_(*O, X, Y) !void`: Computes the subtraction of `x` and `y` into
///   `o`.
///
/// If none of `O`, `X` and `Y` implement the required `sub_` method, the
/// function will fall back to using `vector.apply2_` with `numeric.sub_`,
/// potentially resulting in a less efficient implementation. In this case, `O`,
/// `X` and `Y` must adhere to the requirements of these functions.
pub fn sub_(o: anytype, x: anytype, y: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isPointer(O) or meta.isConstPointer(O) or !meta.isVector(meta.Child(O)) or
        !meta.isVector(X) or !meta.isVector(Y))
        @compileError("zsl.vector.sub_: o must be a mutable one-itme pointer to a vector, and x and y must be vectors, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    O = meta.Child(O);

    if (comptime meta.isCustomType(O)) {
        if (comptime meta.isCustomType(X)) {
            if (comptime meta.isCustomType(Y)) { // O, X and Y all custom vectors
                if (comptime meta.anyHasMethod(&.{ O, X, Y }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            } else { // only O and X custom vectors
                if (comptime meta.anyHasMethod(&.{ O, X }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            }
        } else if (comptime meta.isCustomType(Y)) {
            if (comptime meta.isCustomType(Y)) { // only O and Y custom vectors
                if (comptime meta.anyHasMethod(&.{ O, Y }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.sub_(o, x, y);
            } else { // only O vector
                if (comptime meta.hasMethod(O, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                    return O.sub_(o, x, y);
            }
        }
    } else if (comptime meta.isCustomType(X)) {
        if (comptime meta.isCustomType(Y)) { // only X and Y custom vectors
            if (comptime meta.anyHasMethod(&.{ X, Y }, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                return Impl.sub_(o, x, y);
        } else { // only X custom vector
            if (comptime meta.hasMethod(X, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                return X.sub_(o, x, y);
        }
    } else if (comptime meta.isCustomType(Y)) { // only Y custom vector
        if (comptime meta.hasMethod(Y, "sub_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
            return Y.sub_(o, x, y);
    }

    return vecops.apply2_(o, x, y, numeric.sub_);
}
