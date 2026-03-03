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

pub fn Erfc(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.erfc: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return float.Erfc(X),
        .int => return float.Erfc(X),
        .float => return float.Erfc(X),
        .dyadic => @compileError("zml.numeric.erfc: not implemented for " ++ @typeName(X) ++ " yet."),
        .cfloat => @compileError("zml.numeric.erfc: not implemented for " ++ @typeName(X) ++ " yet."),
        .integer => @compileError("zml.numeric.erfc: not implemented for " ++ @typeName(X) ++ " yet."),
        .rational => @compileError("zml.numeric.erfc: not implemented for " ++ @typeName(X) ++ " yet."),
        .real => @compileError("zml.numeric.erfc: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.erfc: not implemented for " ++ @typeName(X) ++ " yet."),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlErfc", fn (type) type, &.{X}))
                @compileError("zml.numeric.erfc: " ++ @typeName(X) ++ " must implement `fn ZmlErfc(type) type`");

            return X.ZmlErfc(X);
        },
    }
}

/// Returns the complementary error function of a numeric `x`.
///
/// The error function is defined as:
/// $$
/// \mathrm{erfc}(x) = 1 - \frac{2}{\sqrt{\pi}} \int_0^x e^{-t^2} \mathrm{d}t.
/// $$
///
/// ## Signature
/// ```zig
/// numeric.erfc(x: X, ctx: anytype) !numeric.Erfc(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the complementary error function
///   of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Erfc(@TypeOf(x))`: The error function of `x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlErfc` method. The expected signature and
/// behavior of `ZmlErfc` are as follows:
/// * `fn ZmlErfc(type) type`: Returns the type of the error function of `x`.
///
/// `numeric.Erfc(X)` or `X` must implement the required `zmlErfc` method. The
/// expected signature and behavior of `zmlErfc` are as follows:
/// * `fn zmlErfc(X, anytype) !numeric.Erfc(X)`: Returns the error function of
///   `x`, potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn erfc(x: anytype, ctx: anytype) !numeric.Erfc(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Erfc(X);

    switch (comptime types.numericType(X)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.erfc(x);
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.erfc(x);
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return float.erfc(x);
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
                "zmlErfc",
                fn (X, anytype) anyerror!numeric.Erfc(X),
                &.{ X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.erfc: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlErfc(" ++ @typeName(X) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlErfc(x, ctx);
        },
    }
}
