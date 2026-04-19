const std = @import("std");

const meta = @import("../../meta.zig");

const numeric = @import("../../numeric.zig");
const vector = @import("../../vector.zig");

const vecops = @import("../ops.zig");

pub fn Mul(comptime X: type, comptime Y: type) type {
    comptime if ((!meta.isVector(X) and !meta.isNumeric(X)) or (!meta.isVector(Y) and !meta.isNumeric(Y)) or
        (!meta.isVector(X) and !meta.isVector(Y)) or (meta.isVector(X) and meta.isVector(Y)))
        @compileError("zsl.vector.mul: at least one of x or y must be a vector, the other must be a numeric, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime meta.isCustomType(X) and meta.isVector(X)) {
        if (comptime meta.isCustomType(Y) and meta.isVector(Y)) { // X and Y both custom vectors
            if (comptime meta.anyHasMethod(&.{ X, Y }, "Mul", fn (type, type) type, &.{ X, Y })) |Impl|
                return Impl.Mul(X, Y);
        } else { // only X custom vector
            if (comptime meta.hasMethod(X, "Mul", fn (type, type) type, &.{ X, Y }))
                return X.Mul(X, Y);
        }
    } else if (comptime meta.isCustomType(Y) and meta.isVector(Y)) { // only Y custom vector
        if (comptime meta.hasMethod(Y, "Mul", fn (type, type) type, &.{ X, Y }))
            return Y.Mul(X, Y);
    }

    return vecops.Apply2(X, Y, numeric.mul);
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
/// * `fn mul(std.mem.Allocator, X, Y) !vector.Mul(X, Y)`: Returns the
///   multiplication of `x` and `y`.
///
/// If none of `vector.Mul(X, Y)`, `X` and `Y` implement the required `mul`
/// method, the function will fall back to using `vector.apply2` with
/// `numeric.mul`, potentially resulting in a less efficient implementation. In
/// this case, `vector.Mul(X, Y)`, `X` and `Y` must adhere to the requirements
/// of these functions.
pub fn mul(allocator: std.mem.Allocator, x: anytype, y: anytype) !vector.Mul(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = vector.Mul(@TypeOf(x), @TypeOf(y));

    if (comptime meta.isCustomType(X) and meta.isVector(X)) { // only X custom vector
        if (comptime meta.hasMethod(X, "mul", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y }))
            return X.mul(allocator, x, y);
    } else if (comptime meta.isCustomType(Y) and meta.isVector(Y)) { // only Y custom vector
        if (comptime meta.hasMethod(Y, "mul", fn (std.mem.Allocator, X, Y) anyerror!R, &.{ std.mem.Allocator, X, Y }))
            return Y.mul(allocator, x, y);
    }

    return vecops.apply2(allocator, x, y, numeric.mul);
}
