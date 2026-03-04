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

pub fn Hypot(X: type, Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zml.numeric.hypot: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "ZmlHypot",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.hypot: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn ZmlHypot(type, type) type`");

            return Impl.ZmlHypot(X, Y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "ZmlHypot", fn (type, type) type, &.{ X, Y }))
                @compileError("zml.numeric.hypot: " ++ @typeName(X) ++ " must implement `fn ZmlHypot(type, type) type`");

            return X.ZmlHypot(X, Y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "ZmlHypot", fn (type, type) type, &.{ X, Y }))
            @compileError("zml.numeric.hypot: " ++ @typeName(Y) ++ " must implement `fn ZmlHypot(type, type) type`");

        return Y.ZmlHypot(X, Y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => @compileError("zml.numeric.hypot: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .int, .float => return float.Hypot(X, Y),
            .dyadic => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .cfloat => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .integer => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .rational => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .real => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .complex => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => return float.Hypot(X, Y),
            .dyadic => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .cfloat => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .integer => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .rational => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .real => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .complex => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => return float.Hypot(X, Y),
            .dyadic => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .cfloat => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .integer, .rational => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .real => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .complex => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .custom => unreachable,
        },
        .dyadic => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .cfloat => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .integer => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .rational => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .real => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .complex => @compileError("zml.numeric.hypot: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .custom => unreachable,
    }
}

/// Computes the hypotenuse `√(x² + y²)` of any two numeric operands.
///
/// ## Signature
/// ```zig
/// numeric.hypot(x: X, y: Y, ctx: anytype) !numeric.Hypot(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Hypot(@TypeOf(x), @TypeOf(y))`: The hypotenuse of `x` and `y`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `ZmlHypot` method. The expected
/// signature and behavior of `ZmlHypot` are as follows:
/// * `fn ZmlHypot(type, type) type`: Returns the type of `√(x² + y²)`.
///
/// `numeric.Hypot(X, Y)`, `X` or `Y` must implement the required `zmlHypot`
/// method. The expected signatures and behavior of `zmlHypot` are as follows:
/// * `fn zmlHypot(X, Y, anytype) !numeric.Hypot(X, Y)`: Returns the hypotenuse
///   of `x` and `y`, potentially using the provided context for necessary
///   resources. This function is responsible for validating the context.
pub inline fn hypot(x: anytype, y: anytype, ctx: anytype) !numeric.Hypot(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = numeric.Hypot(X, Y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "zmlHypot",
                fn (X, Y, anytype) anyerror!R,
                &.{ X, Y, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.hypot: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlHypot(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlHypot(x, y, ctx);
        } else { // only X custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlHypot",
                fn (X, Y, anytype) anyerror!R,
                &.{ X, Y, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.hypot: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlHypot(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlHypot(x, y, ctx);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "zmlHypot",
            fn (X, Y, anytype) anyerror!R,
            &.{ X, Y, @TypeOf(ctx) },
        ) orelse
            @compileError("zml.numeric.hypot: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlHypot(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

        return Impl.zmlHypot(x, y, ctx);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => unreachable,
            .int, .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return float.hypot(x, y);
            },
            .dyadic => unreachable,
            .cfloat => unreachable,
            .integer => unreachable,
            .rational => unreachable,
            .real => unreachable,
            .complex => unreachable,
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return float.hypot(x, y);
            },
            .dyadic => unreachable,
            .cfloat => unreachable,
            .integer => unreachable,
            .rational => unreachable,
            .real => unreachable,
            .complex => unreachable,
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return float.hypot(x, y);
            },
            .dyadic => unreachable,
            .cfloat => unreachable,
            .integer => unreachable,
            .rational => unreachable,
            .real => unreachable,
            .complex => unreachable,
            .custom => unreachable,
        },
        .dyadic => unreachable,
        .cfloat => unreachable,
        .integer => unreachable,
        .rational => unreachable,
        .real => unreachable,
        .complex => unreachable,
        .custom => unreachable,
    }
}
