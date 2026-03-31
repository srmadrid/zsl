const types = @import("../../types.zig");

const vector = @import("../../vector.zig");

/// Applies a binary in-place operation elementwise between an output and two
/// input vectors, or between an output vector, an input vector and an input
/// numeric.
///
/// For two input sparse vectors, or an input sparse vector and an input
/// numeric, if the output is also a sparse vector, the operation is only
/// applied to the indices where at least one of the vectors has a non-zero
/// element.
///
/// ## Signature
/// ```zig
/// vector.apply2_(*O, x: X, y: Y, op_: Op) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The left input operand.
/// * `y` (`anytype`): The right input operand.
/// * `op_` (`comptime anytype`): An in-place binary numeric function to apply
///   elementwise to `o`, `x` and `y`.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `vector.Error.DimensionMismatch`: If the vectors do not have the same
///   length.
///
/// ## Custom type support
/// This function supports custom vector types via specific method
/// implementations.
///
/// `O`, `X` or `Y` must implement the required `apply2_` method. The expected
/// signatures and behavior of `apply2_` are as follows:
/// * `fn apply2_(*O, X, Y, anytype) !void`: Returns the elementwise application
///   of `op_` on `o`, `x` and `y`.
pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const Op: type = @TypeOf(op_);
    const opinfo = @typeInfo(Op);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or !types.isVector(types.Child(O)) or
        (!types.isVector(X) and !types.isNumeric(X)) or (!types.isVector(Y) and !types.isNumeric(Y)) or
        (!types.isVector(X) and !types.isVector(Y)) or
        opinfo != .@"fn" or opinfo.@"fn".params.len != 3)
        @compileError("zsl.vector.apply2_: o must be a mutable one-itme pointer to a vector, at least one of x or y must be a vector, the other must be a vector or a numeric, and op_ must be a function of three arguments, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O) and types.isVector(O)) {
        if (comptime types.isCustomType(X) and types.isVector(X)) {
            if (comptime types.isCustomType(Y) and types.isVector(Y)) { // O, X and Y all custom vectors
                const Impl: type = comptime types.anyHasMethod(
                    &.{ O, X, Y },
                    "apply2_",
                    fn (*O, X, Y, anytype) anyerror!void,
                    &.{ *O, X, Y, Op },
                ) orelse
                    @compileError("zsl.vector.apply2_: " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

                return Impl.apply2_(o, x, y, op_);
            } else { // only O and X custom vectors
                const Impl: type = comptime types.anyHasMethod(
                    &.{ O, X },
                    "apply2_",
                    fn (*O, X, Y, anytype) anyerror!void,
                    &.{ *O, X, Y, Op },
                ) orelse
                    @compileError("zsl.vector.apply2_: " ++ @typeName(O) ++ " or " ++ @typeName(X) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

                return Impl.apply2_(o, x, y, op_);
            }
        } else {
            if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only O and Y custom vectors
                const Impl: type = comptime types.anyHasMethod(
                    &.{ O, Y },
                    "apply2_",
                    fn (*O, X, Y, anytype) anyerror!void,
                    &.{ *O, X, Y, Op },
                ) orelse
                    @compileError("zsl.vector.apply2_: " ++ @typeName(O) ++ " or " ++ @typeName(Y) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

                return Impl.apply2_(o, x, y, op_);
            } else { // only O custom vector
                comptime if (!types.hasMethod(O, "apply2_", fn (*O, X, Y, anytype) anyerror!void, &.{ *O, X, Y, Op }))
                    @compileError("zsl.vector.apply2_: " ++ @typeName(O) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

                return O.apply2_(o, x, y, op_);
            }
        }
    } else if (comptime types.isCustomType(X) and types.isVector(X)) {
        if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only X and Y custom vectors
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "apply2_",
                fn (*O, X, Y, anytype) anyerror!void,
                &.{ *O, X, Y, Op },
            ) orelse
                @compileError("zsl.vector.apply2_: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

            return Impl.apply2_(o, x, y, op_);
        } else { // only X custom vector
            comptime if (!types.hasMethod(X, "apply2_", fn (*O, X, Y, anytype) anyerror!void, &.{ *O, X, Y, Op }))
                @compileError("zsl.vector.apply2_: " ++ @typeName(X) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

            return X.apply2_(o, x, y, op_);
        }
    } else if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only Y custom vector
        comptime if (!types.hasMethod(Y, "apply2_", fn (*O, X, Y, anytype) anyerror!void, &.{ *O, X, Y, Op }))
            @compileError("zsl.vector.apply2_: " ++ @typeName(Y) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

        return Y.apply2_(o, x, y, op_);
    }

    switch (comptime types.vectorType(O)) {
        .dense => switch (comptime types.vectorType(X)) {
            .dense => switch (comptime types.vectorType(Y)) {
                .dense => return @import("apply2_/dedede.zig").apply2_(o, x, y, op_),
                .sparse => return @import("apply2_/dedesp,zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/dedenu.zig").apply2_(o, x, y, op_),
            },
            .sparse => switch (comptime types.vectorType(Y)) {
                .dense => return @import("apply2_/despde.zig").apply2_(o, x, y, op_),
                .sparse => return @import("apply2_/despsp.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/despnu.zig").apply2_(o, x, y, op_),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.vectorType(Y)) {
                .dense => return @import("apply2_/denude.zig").apply2_(o, x, y, op_),
                .sparse => return @import("apply2_/denusp.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => unreachable,
            },
        },
        .sparse => switch (comptime types.vectorType(X)) {
            .dense => @compileError("zsl.vector.apply2_: o cannot point to a sparse vector if the result is dense, got\n\to: *" ++
                @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            .sparse => switch (comptime types.vectorType(Y)) {
                .dense => @compileError("zsl.vector.apply2_: o cannot point to a sparse vector if the result is dense, got\n\to: *" ++
                    @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
                .sparse => return @import("apply2_/spspsp.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/spspnu.zig").apply2_(o, x, y, op_),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.vectorType(Y)) {
                .dense => @compileError("zsl.vector.apply2_: o cannot point to a sparse vector if the result is dense, got\n\to: *" ++
                    @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
                .sparse => return @import("apply2_/spnusp.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => unreachable,
            },
        },
        .custom => unreachable,
        .numeric => unreachable,
    }
}
