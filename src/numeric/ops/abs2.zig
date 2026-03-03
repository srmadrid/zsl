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

pub fn Abs2(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.abs2: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .float => return X,
        .dyadic => return X,
        .cfloat => return cfloat.Abs2(X),
        .integer => return X,
        .rational => return X,
        .real => return X,
        .complex => return complex.Abs2(X),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAbs2", fn (type) type, &.{X}))
                @compileError("zml.numeric.abs2: " ++ @typeName(X) ++ " must implement `fn ZmlAbs2(type) type`");

            return X.ZmlAbs2(X);
        },
    }
}

/// Returns the squared absolute value of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.abs2(x: X, ctx: anytype) !numeric.Abs2(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the squared absolute value of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Abs2(@TypeOf(x))`: The squared absolute value of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAbs2` method. The expected signature and
/// behavior of `ZmlAbs2` are as follows:
/// * `fn ZmlAbs2(type) type`: Returns the type of the squared absolute value of
///   `x`.
///
/// `numeric.Abs2(X)` or `X` must implement the required `zmlAbs2` method. The
/// expected signature and behavior of `zmlAbs2` are as follows:
/// * `fn zmlAbs2(X, anytype) !numeric.Abs2(X)`: Returns the squared absolute
///   value of `x`, potentially using the provided context for necessary
///   resources. This function is responsible for validating the context.
pub inline fn abs2(x: anytype, ctx: anytype) !numeric.Abs2(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Abs2(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x;
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return int.mul(x, x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.mul(x, x);
        },
        .dyadic => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return dyadic.mul(x, x);
        },
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.mul(x, x);
        },
        .integer => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = true,
                        .description = "The allocator to use for the integer's memory allocation.",
                    },
                },
            );

            return integer.mul(ctx.allocator, x, x);
        },
        .rational => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = true,
                        .description = "The allocator to use for the rational's memory allocation.",
                    },
                },
            );

            return rational.mul(ctx.allocator, x, x);
        },
        .real => @compileError("zml.numeric.abs2: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.abs2: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAbs2",
                fn (X, anytype) anyerror!numeric.Abs2(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.abs2: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAbs2(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAbs2(x, ctx);
        },
    }
}
