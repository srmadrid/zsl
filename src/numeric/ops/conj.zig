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

pub fn Conj(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.conj: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

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
            if (comptime !types.hasMethod(X, "ZmlConj", fn (type) type, &.{X}))
                @compileError("zml.numeric.conj: " ++ @typeName(X) ++ " must implement `fn ZmlConj(type) type`");

            return X.ZmlConj(X);
        },
    }
}

/// Returns the complex conjugate of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.conj(x: X, ctx: anytype) !numeric.Conj(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the complex conjugate of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Conj(@TypeOf(x))`: The complex conjugate of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlConj` method. The expected signature and
/// behavior of `ZmlConj` are as follows:
/// * `fn ZmlConj(type) type`: Returns the type of the complex conjugate of `x`.
///
/// `numeric.Conj(X)` or `X` must implement the required `zmlConj` method. The
/// expected signature and behavior of `zmlConj` are as follows:
/// * `fn zmlConj(X, anytype) !numeric.Conj(X)`: Returns the complex conjugate
///   of `x`, potentially using the provided context for necessary resources.
///   This function is responsible for validating the context.
///
/// Custom allocated types can optionally declare `zml_has_simple_conj` as `true`
/// to indicate that their `zmlConj` implementation can be called without an
/// allocator in the context, instead returning a view and never erroring.
pub inline fn conj(x: anytype, ctx: anytype) !numeric.Conj(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Conj(X);

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

            return x.conj();
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
        .real => @compileError("zml.numeric.conj: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.conj: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlConj",
                fn (X, anytype) anyerror!numeric.Conj(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.conj: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlConj(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlConj(x, ctx);
        },
    }
}
