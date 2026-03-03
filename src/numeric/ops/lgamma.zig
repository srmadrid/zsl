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

pub fn Lgamma(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.lgamma: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Lgamma(X),
        .int => return float.Lgamma(X),
        .float => return float.Lgamma(X),
        .dyadic => @compileError("zml.numeric.lgamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => @compileError("zml.numeric.lgamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .integer => @compileError("zml.numeric.lgamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.lgamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.lgamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.lgamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlLgamma", fn (type) type, &.{X}))
                @compileError("zml.numeric.lgamma: " ++ @typeName(X) ++ " must implement `fn ZmlLgamma(type) type`");

            return X.ZmlLgamma(X);
        },
    }
}

/// Returns the log-gamma function of a numeric `x`.
///
/// The log-gamma function is defined as:
/// $$
/// \log(\Gamma(x)) = \left(\int_0^\infty t^{x - 1} e^{-t} \mathrm{d}t\right).
/// $$
///
/// ## Signature
/// ```zig
/// numeric.lgamma(x: X, ctx: anytype) !numeric.Lgamma(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the log-gamma function of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Lgamma(@TypeOf(x))`: The log-gamma function  of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlLgamma` method. The expected signature
/// and behavior of `ZmlLgamma` are as follows:
/// * `fn ZmlLgamma(type) type`: Returns the type of the log-gamma function of
///   `x`.
///
/// `numeric.Lgamma(X)` or `X` must implement the required `zmlLgamma` method.
/// The expected signature and behavior of `zmlLgamma` are as follows:
/// * `fn zmlLgamma(X, anytype) !numeric.Lgamma(X)`: Returns the log-gamma
///   function of `x`, potentially using the provided context for necessary
///   resources. This function is responsible for validating the context.
pub inline fn lgamma(x: anytype, ctx: anytype) !numeric.Lgamma(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Lgamma(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.lgamma(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.lgamma(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.lgamma(x);
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
                "zmlLgamma",
                fn (X, anytype) anyerror!numeric.Lgamma(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.lgamma: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlLgamma(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlLgamma(x, ctx);
        },
    }
}
