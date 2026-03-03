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

pub fn Tan(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.tan: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Tan(X),
        .int => return float.Tan(X),
        .float => return float.Tan(X),
        .dyadic => @compileError("zml.numeric.tan: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.tan: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.tan: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.tan: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.tan: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlTan", fn (type) type, &.{X}))
                @compileError("zml.numeric.tan: " ++ @typeName(X) ++ " must implement `fn ZmlTan(type) type`");

            return X.ZmlTan(X);
        },
    }
}

/// Returns the tangent `tan(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.tan(x: X, ctx: anytype) !numeric.Tan(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the tangent of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Tan(@TypeOf(x))`: The tangent of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlTan` method. The expected signature and
/// behavior of `ZmlTan` are as follows:
/// * `fn ZmlTan(type) type`: Returns the type of the tangent of `x`.
///
/// `numeric.Tan(X)` or `X` must implement the required `zmlTan` method. The
/// expected signature and behavior of `zmlTan` are as follows:
/// * `fn zmlTan(X, anytype) !numeric.Tan(X)`: Returns the tangent of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn tan(x: anytype, ctx: anytype) !numeric.Tan(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Tan(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.tan(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.tan(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.tan(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.tan(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlTan",
                fn (X, anytype) anyerror!numeric.Tan(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.tan: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlTan(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlTan(x, ctx);
        },
    }
}
