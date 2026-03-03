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

pub fn Asinh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.asinh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Asinh(X),
        .int => return float.Asinh(X),
        .float => return float.Asinh(X),
        .dyadic => @compileError("zml.numeric.asinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.asinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.asinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.asinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.asinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAsinh", fn (type) type, &.{X}))
                @compileError("zml.numeric.asinh: " ++ @typeName(X) ++ " must implement `fn ZmlAsinh(type) type`");

            return X.ZmlAsinh(X);
        },
    }
}

/// Returns the hyperbolic arcsine `sinh⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.asinh(x: X, ctx: anytype) !numeric.Asinh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic arcsine of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Asinh(@TypeOf(x))`: The hyperbolic arcsine of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAsinh` method. The expected signature and
/// behavior of `ZmlAsinh` are as follows:
/// * `fn ZmlAsinh(type) type`: Returns the type of the hyperbolic arcsine of
///   `x`.
///
/// `numeric.Asinh(X)` or `X` must implement the required `zmlAsinh` method. The
/// expected signature and behavior of `zmlAsinh` are as follows:
/// * `fn zmlAsinh(X, anytype) !numeric.Asinh(X)`: Returns the hyperbolic
///   arcsine of `x`, potentially using the provided context for necessary
///   resources. This function is responsible for validating the context.
pub inline fn asinh(x: anytype, ctx: anytype) !numeric.Asinh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Asinh(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.asinh(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.asinh(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.asinh(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.asinh(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAsinh",
                fn (X, anytype) anyerror!numeric.Asinh(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.asinh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAsinh(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAsinh(x, ctx);
        },
    }
}
