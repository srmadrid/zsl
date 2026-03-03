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

pub fn Cos(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.cos: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Cos(X),
        .int => return float.Cos(X),
        .float => return float.Cos(X),
        .dyadic => @compileError("zml.numeric.cos: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.cos: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.cos: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.cos: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.cos: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlCos", fn (type) type, &.{X}))
                @compileError("zml.numeric.cos: " ++ @typeName(X) ++ " must implement `fn ZmlCos(type) type`");

            return X.ZmlCos(X);
        },
    }
}

/// Returns the cosine `cos(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.cos(x: X, ctx: anytype) !numeric.Cos(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the cosine of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Cos(@TypeOf(x))`: The cosine of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlCos` method. The expected signature and
/// behavior of `ZmlCos` are as follows:
/// * `fn ZmlCos(type) type`: Returns the type of the cosine of `x`.
///
/// `numeric.Cos(X)` or `X` must implement the required `zmlCos` method. The
/// expected signature and behavior of `zmlCos` are as follows:
/// * `fn Cos(X, anytype) !numeric.Cos(X)`: Returns the cosine of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn cos(x: anytype, ctx: anytype) !numeric.Cos(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Cos(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.cos(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.cos(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.cos(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.cos(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlCos",
                fn (X, anytype) anyerror!numeric.Cos(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.cos: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlCos(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlCos(x, ctx);
        },
    }
}
