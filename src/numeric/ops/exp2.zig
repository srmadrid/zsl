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

pub fn Exp2(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.exp2: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Exp2(X),
        .int => return float.Exp2(X),
        .float => return float.Exp2(X),
        .dyadic => @compileError("zml.numeric.exp2: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => @compileError("zml.numeric.exp2: not implemented for " ++ @typeName(X) ++ " yet."),
        .integer => @compileError("zml.numeric.exp2: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.exp2: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.exp2: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.exp2: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlExp2", fn (type) type, &.{X}))
                @compileError("zml.numeric.exp2: " ++ @typeName(X) ++ " must implement `fn ZmlExp2(type) type`");

            return X.ZmlExp2(X);
        },
    }
}

/// Returns the base-2 exponential `2ˣ` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.exp2(x: X, ctx: anytype) !numeric.Exp2(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the base-2 exponential of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Exp2(@TypeOf(x))`: The base-2 exponential of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlExp2` method. The expected signature and
/// behavior of `ZmlExp2` are as follows:
/// * `fn ZmlExp2(type) type`: Returns the type of the base-2 exponential of
///   `x`.
///
/// `numeric.Exp2(X)` or `X` must implement the required `zmlExp2` method. The
/// expected signature and behavior of `zmlExp2` are as follows:
/// * `fn zmlExp2(X, anytype) !numeric.Exp2(X)`: Returns the base-2 exponential
///   of `x`, potentially using the provided context for necessary resources.
///   This function is responsible for validating the context.
pub inline fn exp2(x: anytype, ctx: anytype) !numeric.Exp2(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Exp2(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.exp2(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.exp2(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.exp2(x);
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
                "zmlExp2",
                fn (X, anytype) anyerror!numeric.Exp2(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.exp2: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlExp2(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlExp2(x, ctx);
        },
    }
}
