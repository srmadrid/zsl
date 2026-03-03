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

pub fn Exp(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.exp: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Exp(X),
        .int => return float.Exp(X),
        .float => return float.Exp(X),
        .dyadic => @compileError("zml.numeric.exp: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.exp: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.exp: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.exp: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.exp: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlExp", fn (type) type, &.{X}))
                @compileError("zml.numeric.exp: " ++ @typeName(X) ++ " must implement `fn ZmlExp(type) type`");

            return X.ZmlExp(X);
        },
    }
}

/// Returns the exponential `eˣ` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.exp(x: X, ctx: anytype) !numeric.Exp(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the exponential of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Exp(@TypeOf(x))`: The exponential of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlExp` method. The expected signature and
/// behavior of `ZmlExp` are as follows:
/// * `fn ZmlExp(type) type`: Returns the type of the exponential of `x`.
///
/// `numeric.Exp(X)` or `X` must implement the required `zmlExp` method. The
/// expected signature and behavior of `zmlExp` are as follows:
/// * `fn zmlExp(X, anytype) !numeric.Exp(X)`: Returns the exponential of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn exp(x: anytype, ctx: anytype) !numeric.Exp(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Exp(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.exp(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.exp(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.exp(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.exp(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlExp",
                fn (X, anytype) anyerror!numeric.Exp(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.exp: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlExp(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlExp(x, ctx);
        },
    }
}
