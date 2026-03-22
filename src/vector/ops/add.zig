const std = @import("std");

const types = @import("../../types.zig");

const numeric = @import("../../numeric.zig");
const vector = @import("../../vector.zig");

const vecops = @import("../ops.zig");

pub fn Add(comptime X: type, comptime Y: type) type {
    comptime if (!types.isVector(X) or !types.isVector(Y))
        @compileError("zsl.vector.add: x and y must be vectors, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X) and types.isVector(X)) {
        if (comptime types.isCustomType(Y) and types.isVector(Y)) { // X and Y both custom vectors
            if (comptime types.anyHasMethod(&.{ X, Y }, "Add", fn (type, type) type, &.{ X, Y })) |Impl|
                return Impl.Add(X, Y);
        } else { // only X custom vector
            if (comptime types.hasMethod(X, "Add", fn (type, type) type, &.{ X, Y }))
                return X.Add(X, Y);
        }
    } else if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only Y custom vector
        if (comptime types.hasMethod(Y, "Add", fn (type, type) type, &.{ X, Y }))
            return Y.Add(X, Y);
    }

    return vecops.Apply2(X, Y, numeric.add);
}

/// Performs addition between two vectors.
///
/// ## Signature
/// ```zig
/// vector.add(allocator: std.mem.Allocator, x: X, y: Y) !vector.Add(X, Y)
/// ```
///
/// ## Arguments
/// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
///   allocations.
/// * `x` (`anytype`): The left vector operand.
/// * `y` (`anytype`): The right vector operand.
///
/// ## Returns
/// `vector.Add(@TypeOf(x), @TypeOf(y))`: The result of the addition.
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
/// `X` or `Y` should implement the required `Add` method. The expected
/// signature and behavior of `Add` are as follows:
/// * `fn Add(type, type) type`: Returns the type of `x + y`.
///
/// If neither `X` nor `Y` implement the required `Add` method, the return
/// type will be obtained by using `vector.Apply2` with `numeric.add` as `op`.
///
/// `vector.Add(X, Y)`, `X` or `Y` should implement the required `add` method.
/// The expected signatures and behavior of `add` are as follows:
/// * `fn add(std.mem.Allocator, X, Y) !vector.Add(X, Y)`: Returns the addition
///   of `x` and `y`.
///
/// If none of `vector.Add(X, Y)`, `X` and `Y` implement the required `add`
/// method, the function will fall back to using `vector.apply2` with
/// `numeric.add`, potentially resulting in a less efficient implementation. In
/// this case, `vector.Add(X, Y)`, `X` and `Y` must adhere to the requirements
/// of these functions.
pub inline fn add(allocator: std.mem.Allocator, x: anytype, y: anytype) !vector.Add(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = vector.Add(@TypeOf(x), @TypeOf(y));

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom vectors
            if (comptime types.anyHasMethod(&.{ X, Y }, "add", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y })) |Impl|
                return Impl.add(allocator, x, y);
        } else { // only X custom vector
            if (comptime types.hasMethod(X, "add", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y }))
                return X.add(allocator, x, y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom vector
        if (comptime types.hasMethod(Y, "add", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y }))
            return Y.add(allocator, x, y);
    }

    return vecops.apply2(allocator, x, y, numeric.add);
}
