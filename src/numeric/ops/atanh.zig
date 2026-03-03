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

pub fn Atanh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.atanh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Atanh(X),
        .int => return float.Atanh(X),
        .float => return float.Atanh(X),
        .dyadic => @compileError("zml.numeric.atanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.atanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.atanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.atanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.atanh: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAtanh", fn (type) type, &.{X}))
                @compileError("zml.numeric.atanh: " ++ @typeName(X) ++ " must implement `fn ZmlAtanh(type) type`");

            return X.ZmlAtanh(X);
        },
    }
}

/// Returns the hyperbolic arctangent `tanh⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.atanh(x: X, ctx: anytype) !numeric.Atanh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic arctangent of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Atanh(@TypeOf(x))`: The hyperbolic arctangent of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAtanh` method. The expected signature
/// and behavior of `ZmlAtanh` are as follows:
/// * `fn ZmlAtanh(type) type`: Returns the type of the hyperbolic arctangent of
///   `x`.
///
/// `numeric.Atanh(X)` or `X` must implement the required `zmlAtanh` method. The
/// expected signature and behavior of `zmlAtanh` are as follows:
/// * `fn zmlAtanh(X, anytype) !numeric.Atanh(X)`: Returns the hyperbolic
///   arctangent of `x`, potentially using the provided context for necessary
///   resources. This function is responsible for validating the context.
pub inline fn atanh(x: anytype, ctx: anytype) !numeric.Atanh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Atanh(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.atanh(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.atanh(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.atanh(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.atanh(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAtanh",
                fn (X, anytype) anyerror!numeric.Atanh(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.atanh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAtanh(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAtanh(x, ctx);
        },
    }
}
