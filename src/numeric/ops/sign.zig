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

pub fn Sign(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.sign: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .float => return X,
        .dyadic => return X,
        .cfloat => return X,
        .integer => return X,
        .rational => return X,
        .real => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlSign", fn (type) type, &.{X}))
                @compileError("zml.numeric.sign: " ++ @typeName(X) ++ " must implement `fn ZmlSign(type) type`");

            return X.ZmlSign(X);
        },
    }
}

/// Returns the sign of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.sign(x: X, ctx: anytype) !numeric.Sign(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the sign of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Sign(@TypeOf(x))`: The sign of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlSign` method. The expected signature and
/// behavior of `ZmlSign` are as follows:
/// * `fn ZmlSign(type) type`: Returns the type of the sign of `x`.
///
/// `numeric.Sign(X)` or `X` must implement the required `zmlSign` method. The
/// expected signature and behavior of `zmlSign` are as follows:
/// * `fn zmlSign(X, anytype) !numeric.Sign(X)`: Returns the sign of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
///
/// Custom allocated types can optionally declare `zml_has_simple_sign` as
/// `true` to indicate that their `zmlASign` implementation can be called
/// without an allocator in the context, instead returning a view and never
/// erroring.
pub inline fn sign(x: anytype, ctx: anytype) !numeric.Sign(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sign(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x;
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return int.sign(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sign(x);
        },
        .dyadic => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return dyadic.sign(x);
        },
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.sign(x);
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
                integer.sign(ctx.allocator, x)
            else
                integer.sign(null, x) catch unreachable;
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
                rational.sign(ctx.allocator, x)
            else
                rational.sign(null, x) catch unreachable;
        },
        .real => @compileError("zml.numeric.sign: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.sign: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlSign",
                fn (X, anytype) anyerror!numeric.Sign(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.sign: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSign(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlSign(x, ctx);
        },
    }
}
