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

pub fn Cbrt(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.cbrt: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Cbrt(X),
        .int => return float.Cbrt(X),
        .float => return float.Cbrt(X),
        .dyadic => @compileError("zml.numeric.cbrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => @compileError("zml.numeric.cbrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .integer => @compileError("zml.numeric.cbrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.cbrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.cbrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.cbrt: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlCbrt", fn (type) type, &.{X}))
                @compileError("zml.numeric.cbrt: " ++ @typeName(X) ++ " must implement `fn ZmlCbrt(type) type`");

            return X.ZmlCbrt(X);
        },
    }
}

/// Returns the cube root `∛x` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.cbrt(x: X, ctx: anytype) !numeric.Cbrt(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the cube root of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Cbrt(@TypeOf(x))`: The cube root of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlCbrt` method. The expected signature and
/// behavior of `ZmlCbrt` are as follows:
/// * `fn ZmlCbrt(type) type`: Returns the type of the cube root of `x`.
///
/// `numeric.Cbrt(X)` or `X` must implement the required `zmlCbrt` method. The
/// expected signature and behavior of `zmlCbrt` are as follows:
/// * `fn zmlCbrt(X, anytype) !numeric.Cbrt(X)`: Returns the cube root of `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn cbrt(x: anytype, ctx: anytype) !numeric.Cbrt(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Cbrt(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.cbrt(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.cbrt(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.cbrt(x);
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
                "zmlCbrt",
                fn (X, anytype) anyerror!numeric.Cbrt(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.cbrt: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlCbrt(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlCbrt(x, ctx);
        },
    }
}
