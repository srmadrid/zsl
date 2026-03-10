const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

/// Performs in-place computation of the fused multiplication and addition of
/// three numerics `x`, `y` and `z` into a numeric `o`.
///
/// ## Signature
/// ```zig
/// numeric.fma_(o: *O, x: X, y: Y, z: Z) void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The left multiplication operand.
/// * `y` (`anytype`): The right multiplication operand.
/// * `z` (`anytype`): The addition operand.
///
/// ## Returns
/// `void`
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `O`, `X`, `Y` or `Z` should implement the required `fma_` method. The
/// expected signature and behavior of `fma_` are as follows:
/// * `fn fma_(*O, X, Y, Z) void`: Computes the fused multiplication and
///   addition of `x`, `y` and `z` and stores it in `o`.
///
/// If none of `O`, `X`, `Y` and `Z` implement the required `fma_` method, the
/// function will fall back to using `numeric.set` with the result of
/// `numeric.fma`, potentially resulting in a less efficient implementation. In
/// this case, `O`, `X`, `Y` and `Z` must adhere to the requirements of these
/// functions.
pub inline fn fma_(o: anytype, x: anytype, y: anytype, z: anytype) void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const Z: type = @TypeOf(z);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X) or
        !types.isNumeric(Y) or
        !types.isNumeric(Z))
        @compileError("zsl.numeric.fma_: o must be a mutable one-item pointer to a numeric, and x, y and < must be numerics, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\tz: " ++ @typeName(Z) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) {
            if (comptime types.isCustomType(Y)) {
                if (comptime types.isCustomType(Z)) { // O, X, Y and Z all custom
                    if (comptime types.anyHasMethod(&.{ O, X, Y, Z }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                        return Impl.fma_(o, x, y, z);
                } else { // only O, X and Y custom
                    if (comptime types.anyHasMethod(&.{ O, X, Y }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                        return Impl.fma_(o, x, y, z);
                }
            } else {
                if (comptime types.isCustomType(Z)) { // only O, X and Z custom
                    if (comptime types.anyHasMethod(&.{ O, X, Z }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                        return Impl.fma_(o, x, y, z);
                } else { // only O and X custom
                    if (comptime types.anyHasMethod(&.{ O, X }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                        return Impl.fma_(o, x, y, z);
                }
            }
        } else {
            if (comptime types.isCustomType(Y)) {
                if (comptime types.isCustomType(Z)) { // only O, Y and Z custom
                    if (comptime types.anyHasMethod(&.{ O, Y, Z }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                        return Impl.fma_(o, x, y, z);
                } else { // only O and Y custom
                    if (comptime types.anyHasMethod(&.{ O, Y }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                        return Impl.fma_(o, x, y, z);
                }
            } else {
                if (comptime types.isCustomType(Z)) { // only O and Z custom
                    if (comptime types.anyHasMethod(&.{ O, Z }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                        return Impl.fma_(o, x, y, z);
                } else { // only O custom
                    if (comptime types.hasMethod(O, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z }))
                        return O.fma_(o, x, y, z);
                }
            }
        }
    } else if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) {
            if (comptime types.isCustomType(Z)) { // only X, Y and Z custom
                if (comptime types.anyHasMethod(&.{ X, Y, Z }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                    return Impl.fma_(o, x, y, z);
            } else { // only X and Y custom
                if (comptime types.anyHasMethod(&.{ X, Y }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                    return Impl.fma_(o, x, y, z);
            }
        } else {
            if (comptime types.isCustomType(Z)) { // only X and Z custom
                if (comptime types.anyHasMethod(&.{ X, Z }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                    return Impl.fma_(o, x, y, z);
            } else { // only X custom
                if (comptime types.hasMethod(X, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z }))
                    return X.fma_(o, x, y, z);
            }
        }
    } else if (comptime types.isCustomType(Y)) {
        if (comptime types.isCustomType(Z)) { // only Y and Z custom
            if (comptime types.anyHasMethod(&.{ Y, Z }, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z })) |Impl|
                return Impl.fma_(o, x, y, z);
        } else { // only Y custom
            if (comptime types.hasMethod(Y, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z }))
                return Y.fma_(o, x, y, z);
        }
    } else if (comptime types.isCustomType(Z)) { // only Z custom
        if (comptime types.hasMethod(Z, "fma_", fn (*O, X, Y, Z) void, &.{ *O, X, Y, Z }))
            return Z.fma_(o, x, y, z);
    }

    return numeric.set(o, numeric.fma(x, y, z));
}
