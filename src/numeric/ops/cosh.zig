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

pub fn Cosh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.cosh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Cosh(X),
        .int => return float.Cosh(X),
        .float => return float.Cosh(X),
        .dyadic => @compileError("zml.numeric.cosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.cosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.cosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.cosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.cosh: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlCosh", fn (type) type, &.{X}))
                @compileError("zml.numeric.cosh: " ++ @typeName(X) ++ " must implement `fn ZmlCosh(type) type`");

            return X.ZmlCosh(X);
        },
    }
}

/// Returns the hyperbolic cosine `cosh(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.cosh(x: X, ctx: anytype) !numeric.Cosh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic cosine of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Cosh(@TypeOf(x))`: The hyperbolic cosine of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlCosh` method. The expected signature and
/// behavior of `ZmlCosh` are as follows:
/// * `fn ZmlCosh(type) type`: Returns the type of the hyperbolic cosine of `x`.
///
/// `numeric.Cosh(X)` or `X` must implement the required `zmlCosh` method. The
/// expected signature and behavior of `zmlCosh` are as follows:
/// * `fn Cosh(X, anytype) !numeric.Cosh(X)`: Returns the hyperbolic cosine of
///   `x`, potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn cosh(x: anytype, ctx: anytype) !numeric.Cosh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Cosh(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.cosh(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.cosh(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.cosh(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.cosh(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlCosh",
                fn (X, anytype) anyerror!numeric.Cosh(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.cosh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlCosh(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlCosh(x, ctx);
        },
    }
}
