const std = @import("std");

const types = @import("../../types.zig");
const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const cfloat = @import("../../cfloat.zig");
const integer = @import("../../integer.zig");
const rational = @import("../../rational.zig");
const real = @import("../../real.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Tanh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.tanh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Tanh(X),
        .int => return float.Tanh(X),
        .float => return float.Tanh(X),
        .dyadic => @compileError("zml.numeric.tanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.tanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.tanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.tanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.tanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlTanh", fn (type) type, &.{X}))
                @compileError("zml.numeric.tanh: " ++ @typeName(X) ++ " must implement `fn ZmlTanh(type) type`");

            return X.ZmlTanh(X);
        },
    }
}

/// Returns the hyperbolic tangent `tanh(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.tanh(x: X, ctx: anytype) !numeric.Tanh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic tangent of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Tanh(@TypeOf(x))`: The hyperbolic tangent of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlTanh` method. The expected signature and
/// behavior of `ZmlTanh` are as follows:
/// * `fn ZmlTanh(type) type`: Returns the type of the hyperbolic tangent of `x`.
///
/// `numeric.Tanh(X)` or `X` must implement the required `zmlTanh` method. The
/// expected signature and behavior of `zmlTanh` are as follows:
/// * `fn zmlTanh(X, anytype) !numeric.Tanh(X)`: Returns the hyperbolic tangent
///   of `x`, potentially using the provided context for necessary resources.
///   This function is responsible for validating the context.
pub inline fn tanh(x: anytype, ctx: anytype) !numeric.Tanh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Tanh(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.tanh(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.tanh(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.tanh(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.tanh(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlTanh",
                fn (X, anytype) anyerror!numeric.Tanh(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.tanh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlTanh(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlTanh(x, ctx);
        },
    }
}
