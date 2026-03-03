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

pub fn Acosh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.acosh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Acosh(X),
        .int => return float.Acosh(X),
        .float => return float.Acosh(X),
        .dyadic => @compileError("zml.numeric.acosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.acosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.acosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.acosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.acosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAcosh", fn (type) type, &.{X}))
                @compileError("zml.numeric.acosh: " ++ @typeName(X) ++ " must implement `fn ZmlAcosh(type) type`");

            return X.ZmlAcosh(X);
        },
    }
}

/// Returns the hyperbolic arccosine `cos⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.acosh(x: X, ctx: anytype) !numeric.Acosh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic arccosine of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Acosh(@TypeOf(x))`: The hyperbolic arccosine of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAcosh` method. The expected signature and
/// behavior of `ZmlAcosh` are as follows:
/// * `fn ZmlAcosh(type) type`: Returns the type of the hyperbolic arccosine of
///   `x`.
///
/// `numeric.Acosh(X)` or `X` must implement the required `zmlAcosh` method. The
/// expected signature and behavior of `zmlAcosh` are as follows:
/// * `fn zmlAcosh(X, anytype) !numeric.Acosh(X)`: Returns the hyperbolic
///   arccosine of `x`, potentially using the provided context for necessary
///   resources. This function is responsible for validating the context.
pub inline fn acosh(x: anytype, ctx: anytype) !numeric.Acosh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Acosh(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.acosh(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.acosh(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.acosh(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.acosh(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAcosh",
                fn (X, anytype) anyerror!numeric.Acosh(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.acosh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAcosh(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAcosh(x, ctx);
        },
    }
}
