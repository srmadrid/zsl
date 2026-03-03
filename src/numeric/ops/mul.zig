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

pub fn Mul(X: type, Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y))
        @compileError("zml.numeric.mul: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "ZmlMul",
                fn (type, type) type,
                &.{ X, Y },
            ) orelse
                @compileError("zml.numeric.mul: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn ZmlMul(type, type) type`");

            return Impl.ZmlMul(X, Y);
        } else { // only X custom
            comptime if (!types.hasMethod(X, "ZmlMul", fn (type, type) type, &.{ X, Y }))
                @compileError("zml.numeric.mul: " ++ @typeName(X) ++ " must implement `fn ZmlMul(type, type) type`");

            return X.ZmlMul(X, Y);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        comptime if (!types.hasMethod(Y, "ZmlMul", fn (type, type) type, &.{ X, Y }))
            @compileError("zml.numeric.mul: " ++ @typeName(Y) ++ " must implement `fn ZmlMul(type, type) type`");

        return Y.ZmlMul(X, Y);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => @compileError("zml.numeric.mul: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .int => return int.Mul(X, Y),
            .float => return float.Mul(X, Y),
            .dyadic => return dyadic.Mul(X, Y),
            .cfloat => return cfloat.Mul(X, Y),
            .integer => return integer.Integer,
            .rational => return rational.Rational,
            .real => return real.Real,
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => return int.Mul(X, Y),
            .float => return float.Mul(X, Y),
            .dyadic => return dyadic.Mul(X, Y),
            .cfloat => return cfloat.Mul(X, Y),
            .integer => return integer.Integer,
            .rational => return rational.Rational,
            .real => return real.Real,
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => return float.Mul(X, Y),
            .dyadic => return dyadic.Mul(X, Y),
            .cfloat => return cfloat.Mul(X, Y),
            .integer, .rational => return rational.Rational,
            .real => return real.Real,
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => return dyadic.Mul(X, Y),
            .cfloat => return cfloat.Mul(X, Y),
            .integer, .rational => return rational.Rational,
            .real => return real.Real,
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .cfloat => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic, .cfloat => return cfloat.Mul(X, Y),
            .integer, .rational, .real => return complex.Mul(complex.Complex(rational.Rational), Y),
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .integer => switch (comptime types.numericType(Y)) {
            .bool, .int => return integer.Integer,
            .float, .dyadic => return rational.Rational,
            .cfloat => return complex.Mul(complex.Complex(rational.Rational), Y),
            .integer => return integer.Integer,
            .rational => return rational.Rational,
            .real => return real.Real,
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => return rational.Rational,
            .cfloat => return complex.Mul(complex.Complex(rational.Rational), Y),
            .integer, .rational => return rational.Rational,
            .real => return real.Real,
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .real => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => return real.Real,
            .cfloat => return complex.Mul(complex.Complex(rational.Rational), Y),
            .integer, .rational, .real => return real.Real,
            .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic, .cfloat, .integer, .rational, .real, .complex => return complex.Mul(X, Y),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs multiplication between any two numeric operands.
///
/// ## Signature
/// ```zig
/// numeric.mul(x: X, y: Y, ctx: anytype) !numeric.Mul(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `numeric.Mul(@TypeOf(x), @TypeOf(y))`: The result of the multiplication.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails. Can
///   only happen if `numeric.Mul(X, Y)` is allocated.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` or `Y` must implement the required `ZmlMul` method. The expected signature
/// and behavior of `ZmlMul` are as follows:
/// * `fn ZmlMul(type, type) type`: Returns the type of `x + y`.
///
/// `numeric.Mul(X, Y)`, `X` or `Y` must implement the required `zmlMul` method.
/// The expected signatures and behavior of `zmlMul` are as follows:
/// * `fn zmlMul(X, Y, anytype) !numeric.Mul(X, Y)`: Returns the multiplication
///   of `x` and `y`, potentially using the provided context for necessary
///   resources. This function is responsible for validating the context.
pub inline fn mul(x: anytype, y: anytype, ctx: anytype) !numeric.Mul(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = numeric.Mul(X, Y);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) { // X and Y both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X, Y },
                "zmlMul",
                fn (X, Y, anytype) anyerror!R,
                &.{ X, Y, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.mul: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlMul(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlMul(x, y, ctx);
        } else { // only X custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlMul",
                fn (X, Y, anytype) anyerror!R,
                &.{ X, Y, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.mul: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlMul(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

            return Impl.zmlMul(x, y, ctx);
        }
    } else if (comptime types.isCustomType(Y)) { // only Y custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Y },
            "zmlMul",
            fn (X, Y, anytype) anyerror!R,
            &.{ X, Y, @TypeOf(ctx) },
        ) orelse
            @compileError("zml.numeric.mul: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn zmlMul(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !" ++ @typeName(R) ++ "`");

        return Impl.zmlMul(x, y, ctx);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => unreachable,
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return int.mul(x, y);
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return float.mul(x, y);
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return dyadic.mul(x, y);
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return cfloat.mul(x, y);
            },
            .integer => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the integer's memory allocation.",
                        },
                    },
                );

                return integer.mul(ctx.allocator, x, y);
            },
            .rational => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x, y);
            },
            .real => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the real's memory allocation.",
                        },
                    },
                );

                return real.mul(ctx.allocator, x, y);
            },
            .complex => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y);
            },
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return int.mul(x, y);
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return float.mul(x, y);
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return dyadic.mul(x, y);
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return cfloat.mul(x, y);
            },
            .integer => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the integer's memory allocation.",
                        },
                    },
                );

                return integer.mul(ctx.allocator, x, y);
            },
            .rational => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x, y);
            },
            .real => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the real's memory allocation.",
                        },
                    },
                );

                return real.mul(ctx.allocator, x, y);
            },
            .complex => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y);
            },
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return float.mul(x, y);
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return dyadic.mul(x, y);
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return cfloat.mul(x, y);
            },
            .integer => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x, y.asRational());
            },
            .rational => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x, y);
            },
            .real => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the real's memory allocation.",
                        },
                    },
                );

                return real.mul(ctx.allocator, x, y);
            },
            .complex => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y);
            },
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return dyadic.mul(x, y);
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return cfloat.mul(x, y);
            },
            .integer => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x, y.asRational());
            },
            .rational => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x, y);
            },
            .real => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the real's memory allocation.",
                        },
                    },
                );

                return real.mul(ctx.allocator, x, y);
            },
            .complex => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y);
            },
            .custom => unreachable,
        },
        .cfloat => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic, .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return cfloat.mul(x, y);
            },
            .integer, .rational, .real => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y.asComplex());
            },
            .complex => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y);
            },
            .custom => unreachable,
        },
        .integer => switch (comptime types.numericType(Y)) {
            .bool, .int => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the integer's memory allocation.",
                        },
                    },
                );

                return integer.mul(ctx.allocator, x, y);
            },
            .float, .dyadic => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x.asRational(), y);
            },
            .cfloat => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x.asComplex(), y);
            },
            .integer => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the integer's memory allocation.",
                        },
                    },
                );

                return integer.mul(ctx.allocator, x, y);
            },
            .rational => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x, y);
            },
            .real => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the real's memory allocation.",
                        },
                    },
                );

                return real.mul(ctx.allocator, x, y);
            },
            .complex => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y);
            },
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x, y);
            },
            .cfloat => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x.asComplex(), y);
            },
            .integer, .rational => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the rational's memory allocation.",
                        },
                    },
                );

                return rational.mul(ctx.allocator, x, y);
            },
            .real => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the real's memory allocation.",
                        },
                    },
                );

                return real.mul(ctx.allocator, x, y);
            },
            .complex => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y);
            },
            .custom => unreachable,
        },
        .real => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the real's memory allocation.",
                        },
                    },
                );

                return real.mul(ctx.allocator, x, y);
            },
            .cfloat => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x.asComplex(), y);
            },
            .integer, .rational, .real => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the real's memory allocation.",
                        },
                    },
                );

                return real.mul(ctx.allocator, x, y);
            },
            .complex => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y);
            },
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .float, .dyadic, .cfloat, .integer, .rational, .real, .complex => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the complex's memory allocation.",
                        },
                    },
                );

                return complex.mul(ctx.allocator, x, y);
            },
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
