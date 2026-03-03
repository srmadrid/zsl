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

pub fn Gamma(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.gamma: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Gamma(X),
        .int => return float.Gamma(X),
        .float => return float.Gamma(X),
        .dyadic => @compileError("zml.numeric.gamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => @compileError("zml.numeric.gamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .integer => @compileError("zml.numeric.gamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.gamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.gamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.gamma: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlGamma", fn (type) type, &.{X}))
                @compileError("zml.numeric.gamma: " ++ @typeName(X) ++ " must implement `fn ZmlGamma(type) type`");

            return X.ZmlGamma(X);
        },
    }
}

/// Returns the gamma function of a numeric `x`.
///
/// The gamma function is defined as:
/// $$
/// \Gamma(x) = \int_0^\infty t^{x - 1} e^{-t} \mathrm{d}t.
/// $$
///
/// ## Signature
/// ```zig
/// numeric.gamma(x: X, ctx: anytype) !numeric.Gamma(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the gamma function of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Gamma(@TypeOf(x))`: The gamma function  of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlGamma` method. The expected signature
/// and behavior of `ZmlGamma` are as follows:
/// * `fn ZmlGamma(type) type`: Returns the type of the gamma function of `x`.
///
/// `numeric.Gamma(X)` or `X` must implement the required `zmlGamma` method. The
/// expected signature and behavior of `zmlGamma` are as follows:
/// * `fn zmlGamma(X, anytype) !numeric.Gamma(X)`: Returns the gamma function of
///   `x`, potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn gamma(x: anytype, ctx: anytype) !numeric.Gamma(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Gamma(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.gamma(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.gamma(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.gamma(x);
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
                "zmlGamma",
                fn (X, anytype) anyerror!numeric.Gamma(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.gamma: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlGamma(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlGamma(x, ctx);
        },
    }
}
