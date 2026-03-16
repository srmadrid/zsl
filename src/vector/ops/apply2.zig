const std = @import("std");

const types = @import("../../types.zig");

const vector = @import("../../vector.zig");

const dede = @import("apply2/dede.zig");
const desp = @import("apply2/desp.zig");
const spde = @import("apply2/spde.zig");
const spsp = @import("apply2/spsp.zig");

pub fn Apply2(comptime X: type, comptime Y: type, comptime op: anytype) type {
    const Op = @TypeOf(op);
    const opinfo = @typeInfo(Op);

    comptime if ((!types.isVector(X) and !types.isNumeric(X)) or (!types.isVector(Y) and !types.isNumeric(Y)) or
        (!types.isVector(X) and !types.isVector(Y)) or
        opinfo != .@"fn" or opinfo.@"fn".params.len != 2)
        @compileError("zsl.vector.apply2: at least one of x or y must be a vector, the other must be a vector or a numeric, and op must be a function of two arguments, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top: " ++ @typeName(Op) ++ "\n");

    comptime var R = types.ReturnTypeFromInputs(op, &.{ types.Numeric(X), types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    comptime if (!types.isNumeric(R))
        @compileError("zsl.vector.apply2: calling op with arguments of types X and Y must return a numeric, got\n\tR = " ++ @typeName(R) ++ "\n");

    if (comptime types.isCustomType(X) and types.isVector(X)) {
        if (comptime types.isCustomType(Y) and types.isVector(Y)) { // X and Y both custom vectors
            if (comptime types.anyHasMethod(&.{ X, Y }, "Apply2", fn (type, type, anytype) type, &.{ X, Y, Op })) |Impl|
                return Impl.Apply2(X, Y, op);
        } else { // only X custom vector
            if (comptime types.hasMethod(X, "Apply2", fn (type, type, anytype) type, &.{ X, Y, Op }))
                return X.Apply2(X, Y, op);
        }
    } else if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only Y custom vector
        if (comptime types.hasMethod(Y, "Apply2", fn (type, type, anytype) type, &.{ X, Y, Op }))
            return Y.Apply2(X, Y, op);
    }

    switch (comptime types.vectorType(X)) {
        .dense => switch (comptime types.vectorType(Y)) {
            .dense => return vector.Dense(R),
            .sparse => return vector.Dense(R),
            .custom => return vector.EnsureVector(Y, R),
            .numeric => return vector.Dense(R),
        },
        .sparse => switch (comptime types.vectorType(Y)) {
            .dense => return vector.Dense(R),
            .sparse => return vector.Sparse(R),
            .custom => return vector.EnsureVector(Y, R),
            .numeric => return vector.Sparse(R),
        },
        .custom => switch (comptime types.vectorType(Y)) {
            .dense => return vector.EnsureVector(X, R),
            .sparse => return vector.EnsureVector(X, R),
            .custom => {
                if (comptime types.hasMethod(X, "EnsureVector", fn (type, type) type, &.{ X, R }))
                    return X.EnsureVector(X, R);

                return vector.EnsureVector(Y, R);
            },
            .numeric => return vector.EnsureVector(X, R),
        },
        .numeric => switch (comptime types.vectorType(Y)) {
            .dense => return vector.Dense(R),
            .sparse => return vector.Sparse(R),
            .custom => return vector.EnsureVector(Y, R),
            .numeric => unreachable,
        },
    }
}

/// Applies a binary operation elementwise between two vectors, or between a
/// vector and a numeric.
///
/// For two sparse vectors, or a sparse vector and a numeric, the operation is
/// only applied to the indices where at least one of the vectors has a non-zero
/// element.
///
/// ## Signature
/// ```zig
/// vector.apply2(allocator: std.mem.Allocator, x: X, y: Y, op: Op) !vector.Apply2(X, Y, op)
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
/// * `fn apply2(std.mem.Allocator, X, Y, anytype) vector.Apply2(X, Y, op)`:
///   Returns the elementwise application of `op` on `x` and `y`.
pub fn apply2(allocator: std.mem.Allocator, x: anytype, y: anytype, comptime op: anytype) !vector.Apply2(@TypeOf(x), @TypeOf(y), op) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const Op: type = @TypeOf(op);
    const R: type = vector.Apply2(X, Y, op);

    if (comptime types.isCustomType(X) and types.isVector(X)) {
        if (comptime types.isCustomType(Y) and types.isVector(Y)) { // X and Y both custom vectors
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "apply2",
                fn (std.mem.Allocator, X, Y, anytype) anyerror!R,
                &.{ std.mem.Allocator, X, Y, Op },
            ) orelse
                @compileError("zsl.vector.apply2: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn apply2(std.mem.Allocator, " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.apply2(allocator, x, y, op);
        } else { // only X custom vector
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "apply2",
                fn (std.mem.Allocator, X, Y, anytype) anyerror!R,
                &.{ std.mem.Allocator, X, Y, Op },
            ) orelse
                @compileError("zsl.vector.apply2: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn apply2(std.mem.Allocator, " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.apply2(allocator, x, y, op);
        }
    } else if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "apply2",
            fn (std.mem.Allocator, X, Y, anytype) anyerror!R,
            &.{ std.mem.Allocator, X, Y, Op },
        ) orelse
            @compileError("zsl.vector.apply2: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn apply2(std.mem.Allocator, " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

        return Impl.apply2(allocator, x, y, op);
    }

    switch (comptime types.vectorType(X)) {
        .dense => switch (comptime types.vectorType(Y)) {
            .dense => return dede.apply2(allocator, x, y, op),
            .sparse => return desp.apply2(allocator, x, y, op),
            .custom => unreachable,
            .numeric => return dede.apply2(allocator, x, y, op),
        },
        .sparse => switch (comptime types.vectorType(Y)) {
            .dense => return spde.apply2(allocator, x, y, op),
            .sparse => return spsp.apply2(allocator, x, y, op),
            .custom => unreachable,
            .numeric => return spsp.apply2(allocator, x, y, op),
        },
        .custom => unreachable,
        .numeric => switch (comptime types.vectorType(Y)) {
            .dense => return dede.apply2(allocator, x, y, op),
            .sparse => return spsp.apply2(allocator, x, y, op),
            .custom => unreachable,
            .numeric => unreachable,
        },
    }
}
