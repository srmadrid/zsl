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

pub fn Erf(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.erf: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Erf(X),
        .int => return float.Erf(X),
        .float => return float.Erf(X),
        .dyadic => @compileError("zml.numeric.erf: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => @compileError("zml.numeric.erf: not implemented for " ++ @typeName(X) ++ " yet."),
        .integer => @compileError("zml.numeric.erf: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.erf: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.erf: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.erf: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlErf", fn (type) type, &.{X}))
                @compileError("zml.numeric.erf: " ++ @typeName(X) ++ " must implement `fn ZmlErf(type) type`");

            return X.ZmlErf(X);
        },
    }
}

/// Returns the error function of a numeric `x`.
///
/// The error function is defined as:
/// $$
/// \mathrm{erf}(x) = \frac{2}{\sqrt{\pi}} \int_0^x e^{-t^2} \mathrm{d}t.
/// $$
///
/// ## Signature
/// ```zig
/// numeric.erf(x: X, ctx: anytype) !numeric.Erf(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the error function of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Erf(@TypeOf(x))`: The error function of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlErf` method. The expected signature and
/// behavior of `ZmlErf` are as follows:
/// * `fn ZmlErf(type) type`: Returns the type of the error function of `x`.
///
/// `numeric.Erf(X)` or `X` must implement the required `zmlErf` method. The
/// expected signature and behavior of `zmlErf` are as follows:
/// * `fn zmlErf(X, anytype) !numeric.Erf(X)`: Returns the error function of
///   `x`, potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn erf(x: anytype, ctx: anytype) !numeric.Erf(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Erf(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.erf(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.erf(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.erf(x);
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
                "zmlErf",
                fn (X, anytype) anyerror!numeric.Erf(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.erf: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlErf(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlErf(x, ctx);
        },
    }
}
