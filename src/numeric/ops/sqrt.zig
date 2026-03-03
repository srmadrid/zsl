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

pub fn Sqrt(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.sqrt: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Sqrt(X),
        .int => return float.Sqrt(X),
        .float => return float.Sqrt(X),
        .dyadic => @compileError("zml.numeric.sqrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return cfloat.Sqrt(X),
        .integer => @compileError("zml.numeric.sqrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.sqrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.sqrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.sqrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlSqrt", fn (type) type, &.{X}))
                @compileError("zml.numeric.sqrt: " ++ @typeName(X) ++ " must implement `fn ZmlSqrt(type) type`");

            return X.ZmlSqrt(X);
        },
    }
}

/// Returns the square root `√x` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.sqrt(x: X, ctx: anytype) !numeric.Sqrt(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the square root of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Sqrt(@TypeOf(x))`: The square root of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlSqrt` method. The expected signature and
/// behavior of `ZmlSqrt` are as follows:
/// * `fn ZmlSqrt(type) type`: Returns the type of the square root of `x`.
///
/// `numeric.Sqrt(X)` or `X` must implement the required `zmlSqrt` method. The
/// expected signature and behavior of `zmlSqrt` are as follows:
/// * `fn zmlSqrt(X, anytype) !numeric.Sqrt(X)`: Returns the square root of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn sqrt(x: anytype, ctx: anytype) !numeric.Sqrt(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sqrt(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sqrt(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sqrt(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sqrt(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.sqrt(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlSqrt",
                fn (X, anytype) anyerror!numeric.Sqrt(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.sqrt: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSqrt(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlSqrt(x, ctx);
        },
    }
}
