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

pub fn Atan(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.atan: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Atan(X),
        .int => return float.Atan(X),
        .float => return float.Atan(X),
        .dyadic => @compileError("zml.numeric.atan: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.atan: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.atan: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.atan: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.atan: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAtan", fn (type) type, &.{X}))
                @compileError("zml.numeric.atan: " ++ @typeName(X) ++ " must implement `fn ZmlAtan(type) type`");

            return X.ZmlAtan(X);
        },
    }
}

/// Returns the arctangent `tan⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.atan(x: X, ctx: anytype) !numeric.Atan(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the arctangent of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Atan(@TypeOf(x))`: The arctangent of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAtan` method. The expected signature and
/// behavior of `ZmlAtan` are as follows:
/// * `fn ZmlAtan(type) type`: Returns the type of the arctangent of `x`.
///
/// `numeric.Atan(X)` or `X` must implement the required `zmlAtan` method. The
/// expected signature and behavior of `zmlAtan` are as follows:
/// * `fn zmlAtan(X, anytype) !numeric.Atan(X)`: Returns the arctangent of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn atan(x: anytype, ctx: anytype) !numeric.Atan(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Atan(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.atan(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.atan(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.atan(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.atan(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAtan",
                fn (X, anytype) anyerror!numeric.Atan(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.atan: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAtan(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAtan(x, ctx);
        },
    }
}
