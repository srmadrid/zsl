const types = @import("../../types.zig");

const numeric = @import("../../numeric.zig");

const vecops = @import("../ops.zig");

/// Performs in-place computation of the addition of two vectors `x` and `y`
/// into a vector `o`.
///
/// Exact aliasing (in-place modification) between the output and an input is
/// permitted and often more efficient. Any other form of memory overlap might
/// yield incorrect results.
///
/// ## Signature
/// ```zig
/// vector.add_(o: *O, x: X, y: Y) !void
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
/// `O`, `X` or `Y` must implement the required `add_` method. The expected
/// signatures and behavior of `add_` are as follows:
/// * `fn add_(*O, X, Y) !void`: Computes the addition of `x` and `y` into `o`.
///
/// If none of `O`, `X` and `Y` implement the required `add_` method, the
/// function will fall back to using `vector.apply2_` with `numeric.add_`,
/// potentially resulting in a less efficient implementation. In this case, `O`,
/// `X` and `Y` must adhere to the requirements of these functions.
pub fn add_(o: anytype, x: anytype, y: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or !types.isVector(types.Child(O)) or
        !types.isVector(X) or !types.isVector(Y))
        @compileError("zsl.vector.add_: o must be a mutable one-itme pointer to a vector, and x and y must be vectors, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) {
            if (comptime types.isCustomType(Y)) { // O, X and Y all custom vectors
                if (comptime types.anyHasMethod(&.{ O, X, Y }, "add_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.add_(o, x, y);
            } else { // only O and X custom vectors
                if (comptime types.anyHasMethod(&.{ O, X }, "add_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.add_(o, x, y);
            }
        } else if (comptime types.isCustomType(Y)) {
            if (comptime types.isCustomType(Y)) { // only O and Y custom vectors
                if (comptime types.anyHasMethod(&.{ O, Y }, "add_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                    return Impl.add_(o, x, y);
            } else { // only O vector
                if (comptime types.hasMethod(O, "add_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                    return O.add_(o, x, y);
            }
        }
    } else if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // only X and Y custom vectors
            if (comptime types.anyHasMethod(&.{ X, Y }, "add_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y })) |Impl|
                return Impl.add_(o, x, y);
        } else { // only X custom vector
            if (comptime types.hasMethod(X, "add_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
                return X.add_(o, x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom vector
        if (comptime types.hasMethod(Y, "add_", fn (*O, X, Y) anyerror!void, &.{ *O, X, Y }))
            return Y.add_(o, x, y);
    }

    return vecops.apply2_(o, x, y, numeric.add_);
}
