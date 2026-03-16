const std = @import("std");

const types = @import("../../types.zig");

const numeric = @import("../../numeric.zig");
const vector = @import("../../vector.zig");

pub fn Mul(comptime X: type, comptime Y: type) type {
    comptime if ((!types.isVector(X) and !types.isNumeric(X)) or (!types.isVector(Y) and !types.isNumeric(Y)) or
        (!types.isVector(X) and !types.isVector(Y)) or (types.isVector(X) and types.isVector(Y)))
        @compileError("zsl.vector.mul: at least one of x or y must be a vector, the other must be a numeric, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X) and types.isVector(X)) {
        if (comptime types.isCustomType(Y) and types.isVector(Y)) { // X and Y both custom vectors
            if (comptime types.anyHasMethod(&.{ X, Y }, "Mul", fn (type, type) type, &.{ X, Y })) |Impl|
                return Impl.Mul(X, Y);
        } else { // only X custom vector
            if (comptime types.hasMethod(X, "Mul", fn (type, type) type, &.{ X, Y }))
                return X.Mul(X, Y);
        }
    } else if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only Y custom vector
        if (comptime types.hasMethod(Y, "Mul", fn (type, type) type, &.{ X, Y }))
            return Y.Mul(X, Y);
    }

    return vector.Apply2(X, Y, numeric.mul);
}

/// Performs multiplication between a vector and a numeric.
///
/// ## Signature
/// ```zig
/// vector.mul(allocator: std.mem.Allocator, x: X, y: Y) !vector.Mul(X, Y)
/// ```
///
/// ## Arguments
/// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
///   allocations.
/// * `x` (`anytype`): The left vector or numeric operand.
/// * `y` (`anytype`): The right numeric or vector operand.
///
/// ## Returns
/// `vector.Mul(@TypeOf(x), @TypeOf(y))`: The result of the multiplication.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom vector types via specific method
/// implementations.
///
/// `X` or `Y` should implement the required `Mul` method. The expected
/// signature and behavior of `Mul` are as follows:
/// * `fn Mul(type, type) type`: Returns the type of `x * y`.
///
/// If neither `X` nor `Y` implement the required `Mul` method, the return
/// type will be obtained by using `vector.Apply2` with `numeric.mul` as `op`.
///
/// `vector.Mul(X, Y)`, `X` or `Y` must implement the required `mul` method. The
/// expected signatures and behavior of `mul` are as follows:
/// * `fn mul(std.mem.Allocator, X, Y) vector.Mul(X, Y)`: Returns the
///   multiplication of `x` and `y`.
pub inline fn mul(allocator: std.mem.Allocator, x: anytype, y: anytype) !vector.Mul(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = vector.Mul(@TypeOf(x), @TypeOf(y));

    if (comptime types.isCustomType(X) and types.isVector(X)) { // only X custom vector
        if (comptime types.hasMethod(X, "mul", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y }))
            return X.mul(allocator, x, y);
    } else if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only Y custom vector
        if (comptime types.hasMethod(Y, "mul", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y }))
            return Y.mul(allocator, x, y);
    }

    return vector.apply2(allocator, x, y, numeric.mul);
}
