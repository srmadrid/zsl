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

pub fn Atan2(X: type, Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zml.numeric.atan2: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "ZmlAtan2",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.atan2: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn ZmlAtan2(type, type) type`");

            return Impl.ZmlAtan2(X, Y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "ZmlAtan2", fn (type, type) type, &.{ X, Y }))
                @compileError("zml.numeric.atan2: " ++ @typeName(X) ++ " must implement `fn ZmlAtan2(type, type) type`");

            return X.ZmlAtan2(X, Y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "ZmlAtan2", fn (type, type) type, &.{ X, Y }))
            @compileError("zml.numeric.atan2: " ++ @typeName(Y) ++ " must implement `fn ZmlAtan2(type, type) type`");

        return Y.ZmlAtan2(X, Y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => @compileError("zml.numeric.atan2: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .int, .float => return float.Atan2(X, Y),
            .dyadic => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .cfloat => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .integer => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .rational => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .real => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .complex => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => return float.Atan2(X, Y),
            .dyadic => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .cfloat => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .integer => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .rational => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .real => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .complex => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => return float.Atan2(X, Y),
            .dyadic => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .cfloat => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .integer, .rational => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .real => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .complex => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
            .custom => unreachable,
        },
        .dyadic => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .cfloat => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .integer => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .rational => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .real => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .complex => @compileError("zml.numeric.atan2: not implemented for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ " yet."),
        .custom => unreachable,
    }
}

/// Computes the arctangent `tan⁻¹(y/x)` of any two numeric operands, using the
/// signs of both arguments to determine the correct quadrant of the result.
///
/// ## Signature
/// ```zig
/// numeric.atan2(x: X, y: Y, ctx: anytype) !numeric.Atan2(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Atan2(@TypeOf(x), @TypeOf(y))`: The arctangent of `y/x`.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `ZmlAtan2` method. The expected
/// signature and behavior of `ZmlAtan2` are as follows:
/// * `fn ZmlAtan2(type, type) type`: Returns the type of `tan⁻¹(y/x)`.
///
/// `numeric.Atan2(X, Y)`, `X` or `Y` must implement the required `zmlAtan2`
/// method. The expected signatures and behavior of `zmlAtan2` are as follows:
/// * `fn zmlAtan2(X, Y, anytype) !numeric.Atan2(X, Y)`: Returns the arctangent
///   of `y/x`, potentially using the provided context for necessary resources.
///   This function is responsible for validating the context.
pub inline fn atan2(x: anytype, y: anytype, ctx: anytype) !numeric.Atan2(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = numeric.Atan2(X, Y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "zmlAtan2",
                fn (X, Y, anytype) anyerror!R,
                &.{ X, Y, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.atan2: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlAtan2(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAtan2(x, y, ctx);
        } else { // only X custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAtan2",
                fn (X, Y, anytype) anyerror!R,
                &.{ X, Y, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.atan2: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAtan2(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlAtan2(x, y, ctx);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "zmlAtan2",
            fn (X, Y, anytype) anyerror!R,
            &.{ X, Y, @TypeOf(ctx) },
        ) orelse
            @compileError("zml.numeric.atan2: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlAtan2(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

        return Impl.zmlAtan2(x, y, ctx);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => unreachable,
            .int, .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return float.atan2(x, y);
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

                return float.atan2(x, y);
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

                return float.atan2(x, y);
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
