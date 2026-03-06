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

pub fn Abs1(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.abs1: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .float => return X,
        .dyadic => return X,
        .cfloat => return cfloat.Abs1(X),
        .integer => return X,
        .rational => return X,
        .real => return X,
        .complex => return complex.Abs1(X),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAbs1", fn (type) type, &.{X}))
                @compileError("zml.numeric.abs1: " ++ @typeName(X) ++ " must implement `fn ZmlAbs1(type) type`");

            return X.ZmlAbs1(X);
        },
    }
}

/// Returns the 1-norm of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.abs1(x: X, ctx: anytype) !numeric.Abs1(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the 1-norm of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Abs1(@TypeOf(x))`: The 1-norm of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAbs1` method. The expected signature and
/// behavior of `ZmlAbs1` are as follows:
/// * `fn ZmlAbs1(type) type`: Returns the type of the 1-norm of `x`.
///
/// `numeric.Abs1(X)` or `X` must implement the required `zmlAbs1` method. The
/// expected signature and behavior of `zmlAbs1` are as follows:
/// * `fn zmlAbs1(X, anytype) !numeric.Abs1(X)`: Returns the 1-norm of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
///
/// Custom types can optionally declare `zml_has_simple_abs1` as `true` to
/// indicate that their `zmlAbs1` implementation can be called with an empty
/// context, returning a view and never erroring.
pub inline fn abs1(x: anytype, ctx: anytype) !numeric.Abs1(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Abs1(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x;
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return int.abs(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.abs(x);
        },
        .dyadic => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return dyadic.abs(x);
        },
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.abs1(x);
        },
        .integer => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the integer's memory allocation. If not provided, a view will be returned.",
                    },
                },
            );

            return if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator))
                integer.abs(ctx.allocator, x)
            else
                integer.abs(null, x) catch unreachable;
        },
        .rational => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the rational's memory allocation. If not provided, a view will be returned.",
                    },
                },
            );

            return if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator))
                rational.abs(ctx.allocator, x)
            else
                rational.abs(null, x) catch unreachable;
        },
        .real => @compileError("zml.numeric.abs1: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.abs1: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAbs1",
                fn (X, anytype) anyerror!numeric.Abs1(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.abs1: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAbs1(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAbs1(x, ctx);
        },
    }
}
