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

pub fn Sin(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.sin: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Sin(X),
        .int => return float.Sin(X),
        .float => return float.Sin(X),
        .dyadic => @compileError("zml.numeric.sin: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.sin: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.sin: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.sin: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.sin: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlSin", fn (type) type, &.{X}))
                @compileError("zml.numeric.sin: " ++ @typeName(X) ++ " must implement `fn ZmlSin(type) type`");

            return X.ZmlSin(X);
        },
    }
}

/// Returns the sine `sin(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.sin(x: X, ctx: anytype) !numeric.Sin(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the sine of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Sin(@TypeOf(x))`: The sine of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlSin` method. The expected signature and
/// behavior of `ZmlSin` are as follows:
/// * `fn ZmlSin(type) type`: Returns the type of the sine of `x`.
///
/// `numeric.Sin(X)` or `X` must implement the required `zmlSin` method. The
/// expected signature and behavior of `zmlSin` are as follows:
/// * `fn zmlSin(X, anytype) !numeric.Sin(X)`: Returns the sine of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn sin(x: anytype, ctx: anytype) !numeric.Sin(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sin(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sin(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sin(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sin(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.sin(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlSin",
                fn (X, anytype) anyerror!numeric.Sin(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.sin: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSin(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlSin(x, ctx);
        },
    }
}
