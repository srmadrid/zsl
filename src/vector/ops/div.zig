const std = @import("std");

const types = @import("../../types.zig");

const numeric = @import("../../numeric.zig");
const vector = @import("../../vector.zig");

pub fn Div(comptime X: type, comptime Y: type) type {
    comptime if (!types.isVector(X) or !types.isNumeric(Y))
        @compileError("zsl.vector.div: x must be a vector and y must be a numeric, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X) and types.isVector(X)) {
        if (comptime types.isCustomType(Y) and types.isVector(Y)) { // X and Y both custom vectors
            if (comptime types.anyHasMethod(&.{ X, Y }, "Div", fn (type, type) type, &.{ X, Y })) |Impl|
                return Impl.Div(X, Y);
        } else { // only X custom vector
            if (comptime types.hasMethod(X, "Div", fn (type, type) type, &.{ X, Y }))
                return X.Div(X, Y);
        }
    } else if (comptime types.isCustomType(Y) and types.isVector(Y)) { // only Y custom vector
        if (comptime types.hasMethod(Y, "Div", fn (type, type) type, &.{ X, Y }))
            return Y.Div(X, Y);
    }

    return vector.Apply2(X, Y, numeric.div);
}

/// Performs division of vector by a numeric.
///
/// ## Signature
/// ```zig
/// vector.div(allocator: std.mem.Allocator, x: X, y: Y) !vector.Div(X, Y)
/// ```
///
/// ## Arguments
/// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
///   allocations.
/// * `x` (`anytype`): The left vector operand.
/// * `y` (`anytype`): The right numeric operand.
///
/// ## Returns
/// `vector.Div(@TypeOf(x), @TypeOf(y))`: The result of the division.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom vector types via specific method
/// implementations.
///
/// `X` or `Y` should implement the required `Div` method. The expected
/// signature and behavior of `Div` are as follows:
/// * `fn Div(type, type) type`: Returns the type of `x/y`.
///
/// If neither `X` nor `Y` implement the required `Div` method, the return
/// type will be obtained by using `vector.Apply2` with `numeric.div` as `op`.
///
/// `vector.Div(X, Y)`, `X` or `Y` must implement the required `div` method. The
/// expected signatures and behavior of `div` are as follows:
/// * `fn div(std.mem.Allocator, X, Y) vector.Div(X, Y)`: Returns the
///   divition of `x` and `y`.
pub inline fn div(allocator: std.mem.Allocator, x: anytype, y: anytype) !vector.Div(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = vector.Div(@TypeOf(x), @TypeOf(y));

    if (comptime types.isCustomType(X) and types.isVector(X)) { // only X custom vector
        if (comptime types.hasMethod(X, "div", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y }))
            return X.div(allocator, x, y);
    }

    return vector.apply2(allocator, x, y, numeric.div);
}
