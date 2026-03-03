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

pub fn Log10(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.log10: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Log10(X),
        .int => return float.Log10(X),
        .float => return float.Log10(X),
        .dyadic => @compileError("zml.numeric.log10: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => @compileError("zml.numeric.log10: not implemented for " ++ @typeName(X) ++ " yet."),
        .integer => @compileError("zml.numeric.log10: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.log10: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.log10: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.log10: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlLog10", fn (type) type, &.{X}))
                @compileError("zml.numeric.log10: " ++ @typeName(X) ++ " must implement `fn ZmlLog10(type) type`");

            return X.ZmlLog10(X);
        },
    }
}

/// Returns the base-10 logarithm `log₁₀(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.log10(x: X, ctx: anytype) !numeric.Log10(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the base-10 logarithm of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Log10(@TypeOf(x))`: The base-10 logarithm of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlLog10` method. The expected signature
/// and behavior of `ZmlLog10` are as follows:
/// * `fn ZmlLog10(type) type`: Returns the type of the base-10 logarithm of
///   `x`.
///
/// `numeric.Log10(X)` or `X` must implement the required `zmlLog10` method. The
/// expected signature and behavior of `zmlLog10` are as follows:
/// * `fn zmlLog10(X, anytype) !numeric.Log10(X)`: Returns the base-10 logarithm
///   of `x`, potentially using the provided context for necessary resources.
///   This function is responsible for validating the context.
pub inline fn log10(x: anytype, ctx: anytype) !numeric.Log10(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Log10(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.log10(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.log10(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.log10(x);
        },
        .dyadic => unreachable,
        .cfloat => unreachable,
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlLog10",
                fn (X, anytype) anyerror!numeric.Log10(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.log10: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlLog10(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlLog10(x, ctx);
        },
    }
}
