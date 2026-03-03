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

pub fn Asin(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.asin: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Asin(X),
        .int => return float.Asin(X),
        .float => return float.Asin(X),
        .dyadic => @compileError("zml.numeric.asin: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.asin: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.asin: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.asin: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.asin: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAsin", fn (type) type, &.{X}))
                @compileError("zml.numeric.asin: " ++ @typeName(X) ++ " must implement `fn ZmlAsin(type) type`");

            return X.ZmlAsin(X);
        },
    }
}

/// Returns the arcsine `sin⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.asin(x: X, ctx: anytype) !numeric.Asin(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the arcsine of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Asin(@TypeOf(x))`: The arcsine of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAsin` method. The expected signature and
/// behavior of `ZmlAsin` are as follows:
/// * `fn ZmlAsin(type) type`: Returns the type of the arcsine of `x`.
///
/// `numeric.Asin(X)` or `X` must implement the required `zmlAsin` method. The
/// expected signature and behavior of `zmlAsin` are as follows:
/// * `fn zmlAsin(X, anytype) !numeric.Asin(X)`: Returns the arcsine of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn asin(x: anytype, ctx: anytype) !numeric.Asin(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Asin(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.asin(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.asin(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.asin(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.asin(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAsin",
                fn (X, anytype) anyerror!numeric.Asin(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.asin: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAsin(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAsin(x, ctx);
        },
    }
}
