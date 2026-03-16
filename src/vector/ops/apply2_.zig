const std = @import("std");

const types = @import("../../types.zig");

const vector = @import("../../vector.zig");

/// CHANGE DOCSApplies a binary operation elementwise between two vectors, or between a
/// vector and a numeric.
///
/// For two sparse vectors, or a sparse vector and a numeric, the operation is
/// only applied to the indices where at least one of the vectors has a non-zero
/// element.
///
/// ## Signature
/// ```zig
/// vector.apply2_(*O, x: X, y: Y, op: Op) !vector.Apply2(X, Y, op)
/// ```
///
/// ## Arguments
/// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
///   allocations.
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
/// * `op` (`comptime anytype`): A binary numeric function to apply elementwise
///   to `x` and `y`.
///
/// ## Returns
/// `vector.Apply2(@TypeOf(x), @TypeOf(y), op)`: The result of the operation.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
/// * `vector.Error.DimensionMismatch`: If the two vectors do not have the same
///   length. Can only happen if both operands are vectors.
///
/// ## Custom type support
/// This function supports custom vector types via specific method
/// implementations.
///
/// `X` or `Y` should implement the required `Apply2` method. The expected
/// signature and behavior of `Apply2` are as follows:
/// * `fn Apply2(type, type, anytype) type`: Returns the type of `x .op y`.
///
/// If neither `X` nor `Y` implement the required `Apply2` method, the return
/// type will be obtained by using `op`'s return type and attempting to call
/// `vector.EnsureVector` on `X` or `Y`.
///
/// `vector.Apply2(X, Y, op)`, `X` or `Y` must implement the required `apply2`
/// method. The expected signatures and behavior of `apply2` are as follows:
/// * `fn apply2_(std.mem.Allocator, X, Y, anytype) vector.Apply2(X, Y, op)`:
///   Returns the elementwise application of `op` on `x` and `y`.
pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const Op: type = @TypeOf(op_);
    const opinfo = @typeInfo(O);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or !types.isVector(types.Child(O)) or
        (!types.isVector(X) and !types.isNumeric(X)) or (!types.isVector(Y) and !types.isNumeric(Y)) or
        (!types.isVector(X) and !types.isVector(Y)) or
        opinfo != .@"fn" or opinfo.@"fn".params.len != 3)
        @compileError("zsl.vector.apply2_: o must be a mutable one-itme pointer to a vector, at least one of x or y must be a vector, the other must be a vector or a numeric, and op_ must be a function of three arguments, got\n\to: " ++
            @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

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
                .dense => return dedede.apply2_(allocator, x, y, op),
                .sparse => return dedesp.apply2_(allocator, x, y, op),
                .custom => unreachable,
                .numeric => return dedede.apply2_(allocator, x, y, op),
            },
            .sparse => switch (comptime types.vectorType(Y)) {
                .dense => return despde.apply2_(allocator, x, y, op),
                .sparse => return despsp.apply2_(allocator, x, y, op),
                .custom => unreachable,
                .numeric => return despsp.apply2_(allocator, x, y, op),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.vectorType(Y)) {
                .dense => return dedede.apply2_(allocator, x, y, op),
                .sparse => return despsp.apply2_(allocator, x, y, op),
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
                .sparse => return spspsp.apply2_(allocator, x, y, op),
                .custom => unreachable,
                .numeric => return spspsp.apply2_(allocator, x, y, op),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.vectorType(Y)) {
                .dense => @compileError("zsl.vector.apply2_: o cannot point to a sparse vector if the result is dense, got\n\to: *" ++
                    @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
                .sparse => return spspsp.apply2_(allocator, x, y, op),
                .custom => unreachable,
                .numeric => unreachable,
            },
        },
        .custom => unreachable,
        .numeric => unreachable,
    }
}
