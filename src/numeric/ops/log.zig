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

pub fn Log(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.log: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Log(X),
        .int => return float.Log(X),
        .float => return float.Log(X),
        .dyadic => @compileError("zml.numeric.log: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.log: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.log: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.log: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.log: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlLog", fn (type) type, &.{X}))
                @compileError("zml.numeric.log: " ++ @typeName(X) ++ " must implement `fn ZmlLog(type) type`");

            return X.ZmlLog(X);
        },
    }
}

/// Returns the natural logarithm `log(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.log(x: X, ctx: anytype) !numeric.Log(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the natural logarithm of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Log(@TypeOf(x))`: The natural logarithm of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlLog` method. The expected signature and
/// behavior of `ZmlLog` are as follows:
/// * `fn ZmlLog(type) type`: Returns the type of the natural logarithm of `x`.
///
/// `numeric.Log(X)` or `X` must implement the required `zmlLog` method. The
/// expected signature and behavior of `zmlLog` are as follows:
/// * `fn zmlLog(X, anytype) !numeric.Log(X)`: Returns the natural logarithm of
///   `x`, potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn log(x: anytype, ctx: anytype) !numeric.Log(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Log(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.log(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.log(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.log(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.log(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlLog",
                fn (X, anytype) anyerror!numeric.Log(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.log: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlLog(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlLog(x, ctx);
        },
    }
}
