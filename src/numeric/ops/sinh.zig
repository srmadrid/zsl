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

pub fn Sinh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.sinh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Sinh(X),
        .int => return float.Sinh(X),
        .float => return float.Sinh(X),
        .dyadic => @compileError("zml.numeric.sinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.sinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.sinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.sinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.sinh: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlSinh", fn (type) type, &.{X}))
                @compileError("zml.numeric.sinh: " ++ @typeName(X) ++ " must implement `fn ZmlSinh(type) type`");

            return X.ZmlSinh(X);
        },
    }
}

/// Returns the hyperbolic sine `sinh(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.sinh(x: X, ctx: anytype) !numeric.Sinh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic sine of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Sinh(@TypeOf(x))`: The hyperbolic sine of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlSinh` method. The expected signature and
/// behavior of `ZmlSinh` are as follows:
/// * `fn ZmlSinh(type) type`: Returns the type of the hyperbolic sine of `x`.
///
/// `numeric.Sinh(X)` or `X` must implement the required `zmlSinh` method. The
/// expected signature and behavior of `zmlSinh` are as follows:
/// * `fn zmlSinh(X, anytype) !numeric.Sinh(X)`: Returns the hyperbolic sine of
///   `x`, potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn sinh(x: anytype, ctx: anytype) !numeric.Sinh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sinh(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sinh(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sinh(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.sinh(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.sinh(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlSinh",
                fn (X, anytype) anyerror!numeric.Sinh(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.sinh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSinh(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlSinh(x, ctx);
        },
    }
}
