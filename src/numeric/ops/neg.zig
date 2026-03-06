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

pub fn Neg(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.neg: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

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
            if (comptime !types.hasMethod(X, "ZmlNeg", fn (type) type, &.{X}))
                @compileError("zml.numeric.neg: " ++ @typeName(X) ++ " must implement `fn ZmlNeg(type) type`");

            return X.ZmlNeg(X);
        },
    }
}

/// Returns the negation of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.neg(x: X, ctx: anytype) !numeric.Neg(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the negation of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Neg(@TypeOf(x))`: The negation of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlNeg` method. The expected signature and
/// behavior of `ZmlNeg` are as follows:
/// * `fn ZmlNeg(type) type`: Returns the type of the negation of `x`.
///
/// `numeric.Neg(X)` or `X` must implement the required `zmlNeg` method. The
/// expected signature and behavior of `zmlNeg` are as follows:
/// * `fn zmlNeg(X, anytype) !numeric.Neg(X)`: Returns the negation of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
///
/// Custom types can optionally declare `zml_has_simple_neg` as `true` to
/// indicate that their `zmlNeg` implementation can be called with an empty
/// context, returning a view and never erroring.
pub inline fn neg(x: anytype, ctx: anytype) !numeric.Neg(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Neg(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x;
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return -x;
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return -x;
        },
        .dyadic => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return dyadic.neg(x);
        },
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.neg(x);
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
                integer.neg(ctx.allocator, x)
            else
                integer.neg(null, x) catch unreachable;
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
                rational.neg(ctx.allocator, x)
            else
                rational.neg(null, x) catch unreachable;
        },
        .real => @compileError("zml.numeric.neg: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.neg: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlNeg",
                fn (X, anytype) anyerror!numeric.Neg(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.neg: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlNeg(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlNeg(x, ctx);
        },
    }
}
