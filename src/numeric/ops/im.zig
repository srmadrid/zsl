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

const constants = @import("../../constants.zig");

pub fn Im(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.im: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

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
            if (comptime !types.hasMethod(X, "ZmlIm", fn (type) type, &.{X}))
                @compileError("zml.numeric.im: " ++ @typeName(X) ++ " must implement `fn ZmlIm(type) type`");

            return X.ZmlIm(X);
        },
    }
}

/// Returns the imaginary part of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.im(x: X, ctx: anytype) !numeric.Im(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the imaginary part of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Im(@TypeOf(x))`: The imaginary of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlIm` method. The expected signature and
/// behavior of `ZmlIm` are as follows:
/// * `fn ZmlIm(type) type`: Returns the type of the imaginary part of `x`.
///
/// `numeric.Im(X)` or `X` must implement the required `zmlIm` method. The
/// expected signature and behavior of `zmlIm` are as follows:
/// * `fn zmlIm(X, anytype) !numeric.Im(X)`: Returns the imaginary part of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
///
/// Custom types can optionally declare `zml_has_simple_im` as `true` to
/// indicate that their `zmlIm` implementation can be called with an empty
/// context, returning a view and never erroring.
pub inline fn im(x: anytype, ctx: anytype) !numeric.Im(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Im(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x;
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return 0;
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return 0.0;
        },
        .dyadic => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return .zero;
        },
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return x.im;
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

            return constants.zero(integer.Integer, ctx);
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

            return constants.zero(rational.Rational, ctx);
        },
        .real => @compileError("zml.numeric.im: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.im: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlIm",
                fn (X, anytype) anyerror!numeric.Im(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.im: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlIm(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlIm(x, ctx);
        },
    }
}
