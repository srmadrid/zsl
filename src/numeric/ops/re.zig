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

pub fn Re(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.re: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .float => return X,
        .dyadic => return X,
        .cfloat => return types.Scalar(X),
        .integer => return X,
        .rational => return X,
        .real => return X,
        .complex => return types.Scalar(X),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlRe", fn (type) type, &.{X}))
                @compileError("zml.numeric.re: " ++ @typeName(X) ++ " must implement `fn ZmlRe(type) type`");

            return X.ZmlRe(X);
        },
    }
}

/// Returns the real part of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.re(x: X, ctx: anytype) !numeric.Re(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the real part of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Re(@TypeOf(x))`: The real part of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlRe` method. The expected signature and
/// behavior of `ZmlRe` are as follows:
/// * `fn ZmlRe(type) type`: Returns the type of the real part of `x`.
///
/// `numeric.Re(X)` or `X` must implement the required `zmlRe` method. The
/// expected signature and behavior of `zmlRe` are as follows:
/// * `fn zmlRe(X, anytype) !numeric.Re(X)`: Returns the real part of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
///
/// Custom types can optionally declare `zml_has_simple_re` as `true` to
/// indicate that their `zmlRe` implementation can be called with an empty
/// context, returning a view and never erroring.
pub inline fn re(x: anytype, ctx: anytype) !numeric.Re(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Re(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x;
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x;
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x;
        },
        .dyadic => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x;
        },
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x.re;
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
                x.copy(ctx.allocator)
            else
                x.view();
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
                x.copy(ctx.allocator)
            else
                x.view();
        },
        .real => @compileError("zml.numeric.re: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.re: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlRe",
                fn (X, anytype) anyerror!numeric.Re(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.re: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlRe(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlRe(x, ctx);
        },
    }
}
