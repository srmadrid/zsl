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

pub fn Log2(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.log2: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Log2(X),
        .int => return float.Log2(X),
        .float => return float.Log2(X),
        .dyadic => @compileError("zml.numeric.log2: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => @compileError("zml.numeric.log2: not implemented for " ++ @typeName(X) ++ " yet."),
        .integer => @compileError("zml.numeric.log2: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.log2: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.log2: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.log2: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlLog2", fn (type) type, &.{X}))
                @compileError("zml.numeric.log2: " ++ @typeName(X) ++ " must implement `fn ZmlLog2(type) type`");

            return X.ZmlLog2(X);
        },
    }
}

/// Returns the base-2 logarithm `log₁₀(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.log2(x: X, ctx: anytype) !numeric.Log2(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the base-2 logarithm of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Log2(@TypeOf(x))`: The base-2 logarithm of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlLog2` method. The expected signature
/// and behavior of `ZmlLog2` are as follows:
/// * `fn ZmlLog2(type) type`: Returns the type of the base-2 logarithm of `x`.
///
/// `numeric.Log2(X)` or `X` must implement the required `zmlLog2` method. The
/// expected signature and behavior of `zmlLog2` are as follows:
/// * `fn zmlLog2(X, anytype) !numeric.Log2(X)`: Returns the base-2 logarithm of
///   `x`, potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn log2(x: anytype, ctx: anytype) !numeric.Log2(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Log2(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.log2(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.log2(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.log2(x);
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
                "zmlLog2",
                fn (X, anytype) anyerror!numeric.Log2(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.log2: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlLog2(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlLog2(x, ctx);
        },
    }
}
