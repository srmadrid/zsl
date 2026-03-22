const std = @import("std");

const types = @import("../../types.zig");

const numeric = @import("../../numeric.zig");
const vector = @import("../../vector.zig");

const vecops = @import("../ops.zig");

pub fn Sub(comptime X: type, comptime Y: type) type {
    comptime if (!types.isVector(X) or !types.isVector(Y))
        @compileError("zsl.vector.sub: x and y must be vectors, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X) and types.isVector(X)) {
        if (comptime types.isCustomType(Y) and types.isVector(Y)) { // X and Y both custom vectors
            if (comptime types.anyHasMethod(&.{ X, Y }, "Sub", fn (type, type) type, &.{ X, Y })) |Impl|
                return Impl.Sub(X, Y);
        } else { // only X custom vector
            if (comptime types.hasMethod(X, "Sub", fn (type, type) type, &.{ X, Y }))
                return X.Sub(X, Y);
        }
    } else if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only Y custom vector
        if (comptime types.hasMethod(Y, "Sub", fn (type, type) type, &.{ X, Y }))
            return Y.Sub(X, Y);
    }

    return vecops.Apply2(X, Y, numeric.sub);
}

/// Performs subtraction between two vectors.
///
/// ## Signature
/// ```zig
/// vector.sub(allocator: std.mem.Allocator, x: X, y: Y) !vector.Sub(X, Y)
/// ```
///
/// ## Arguments
/// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
///   allocations.
/// * `x` (`anytype`): The left vector operand.
/// * `y` (`anytype`): The right vector operand.
///
/// ## Returns
/// `vector.Sub(@TypeOf(x), @TypeOf(y))`: The result of the subtraction.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
/// * `vector.Error.DimensionMismatch`: If the two vectors do not have the same
///   length.
///
/// ## Custom type support
/// This function supports custom vector types via specific method
/// implementations.
///
/// `X` or `Y` should implement the required `Sub` method. The expected
/// signature and behavior of `Sub` are as follows:
/// * `fn Sub(type, type) type`: Returns the type of `x - y`.
///
/// If neither `X` nor `Y` implement the required `Sub` method, the return
/// type will be obtained by using `vector.Apply2` with `numeric.sub` as `op`.
///
/// `vector.Sub(X, Y)`, `X` or `Y` must implement the required `sub` method. The
/// expected signatures and behavior of `sub` are as follows:
/// * `fn sub(std.mem.Allocator, X, Y) !vector.Sub(X, Y)`: Returns the
///   subtraction of `x` and `y`.
///
/// If none of `vector.Sub(X, Y)`, `X` and `Y` implement the required `sub`
/// method, the function will fall back to using `vector.apply2` with
/// `numeric.sub`, potentially resulting in a less efficient implementation. In
/// this case, `vector.Sub(X, Y)`, `X` and `Y` must adhere to the requirements
/// of these functions.
pub inline fn sub(allocator: std.mem.Allocator, x: anytype, y: anytype) !vector.Sub(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = vector.Sub(@TypeOf(x), @TypeOf(y));

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom vectors
            if (comptime types.anyHasMethod(&.{ X, Y }, "sub", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y })) |Impl|
                return Impl.sub(allocator, x, y);
        } else { // only X custom vector
            if (comptime types.hasMethod(X, "sub", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y }))
                return X.sub(allocator, x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom vector
        if (comptime types.hasMethod(Y, "sub", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y }))
            return Y.sub(allocator, x, y);
    }

    return vecops.apply2(allocator, x, y, numeric.sub);
}
