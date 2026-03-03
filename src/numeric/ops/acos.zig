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

pub fn Acos(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.acos: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Acos(X),
        .int => return float.Acos(X),
        .float => return float.Acos(X),
        .dyadic => @compileError("zml.numeric.acos: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => return X,
        .integer => @compileError("zml.numeric.acos: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.acos: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.acos: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.acos: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAcos", fn (type) type, &.{X}))
                @compileError("zml.numeric.acos: " ++ @typeName(X) ++ " must implement `fn ZmlAcos(type) type`");

            return X.ZmlAcos(X);
        },
    }
}

/// Returns the arccosine `cos⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.acos(x: X, ctx: anytype) !numeric.Acos(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the arccosine of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Acos(@TypeOf(x))`: The arccosine of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAcos` method. The expected signature and
/// behavior of `ZmlAcos` are as follows:
/// * `fn ZmlAcos(type) type`: Returns the type of the arccosine of `x`.
///
/// `numeric.Acos(X)` or `X` must implement the required `zmlAcos` method. The
/// expected signature and behavior of `zmlAcos` are as follows:
/// * `fn zmlAcos(X, anytype) !numeric.Acos(X)`: Returns the arccosine of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn acos(x: anytype, ctx: anytype) !numeric.Acos(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Acos(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.acos(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.acos(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.acos(x);
        },
        .dyadic => unreachable,
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return cfloat.acos(x);
        },
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAcos",
                fn (X, anytype) anyerror!numeric.Acos(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.acos: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAcos(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAcos(x, ctx);
        },
    }
}
