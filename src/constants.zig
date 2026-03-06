const std = @import("std");
const types = @import("types.zig");

const int = @import("int.zig");
const float = @import("float.zig");
const dyadic = @import("dyadic.zig");
const cfloat = @import("cfloat.zig");
const integer = @import("integer.zig");
const rational = @import("rational.zig");
const real = @import("real.zig");
const complex = @import("complex.zig");

const _zero: u32 = 0;
const _one: u32 = 1;
const _two: u32 = 2;

/// Returns the additive identity (zero) for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the zero value for.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `N`: The zero value.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must implement the required `zmlZero` method. The expected signature and
/// behavior of `zmlZero` are as follows:
/// * `fn zmlZero(anytype) !N`: Returns the zero, potentially using the provided
///   context for necessary resources. This function is responsible for
///   validating the context.
///
/// Custom types can optionally declare `zml_has_simple_zero` as `true` to
/// indicate that their `zmlZero` implementation can be called with an empty
/// context, returning a view and never erroring.
pub inline fn zero(
    comptime N: type,
    ctx: anytype,
) !N {
    if (!comptime types.isNumeric(N))
        @compileError("zml.zero: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime types.numericType(N)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return false;
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return 0;
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return 0.0;
        },
        .dyadic => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return .{
                .mantissa = 0,
                .exponent = int.minVal(N.Exponent),
                .positive = true,
            };
        },
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return .{
                .re = zero(types.Scalar(N), .{}) catch unreachable,
                .im = zero(types.Scalar(N), .{}) catch unreachable,
            };
        },
        .integer => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the integer's memory allocation. If not provided, a read-only view backed by static storage will be returned.",
                    },
                },
            );

            if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator))
                return .init(ctx.allocator, 2)
            else
                return .{
                    .limbs = @ptrCast(@constCast(&_zero)),
                    .size = 0,
                    ._llen = 0,
                    .positive = true,
                    .flags = .{ .owns_data = false, .writable = false },
                };
        },
        .rational => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the rational's memory allocation. If not provided, a read-only view backed by static storage will be returned.",
                    },
                },
            );

            if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator)) {
                var num: integer.Integer = try zero(integer.Integer, .{ .allocator = ctx.allocator });
                errdefer num.deinit(ctx.allocator);

                return .{
                    .num = num,
                    .den = try one(integer.Integer, .{ .allocator = ctx.allocator }),
                    .flags = .{ .owns_data = true, .writable = true },
                };
            } else {
                return .{
                    .num = zero(integer.Integer, .{}) catch unreachable,
                    .den = one(integer.Integer, .{}) catch unreachable,
                    .flags = .{ .owns_data = false, .writable = false },
                };
            }
        },
        .real => @compileError("zml.zero: not implemented for " ++ @typeName(N) ++ " yet"),
        .complex => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the complex's memory allocation. If not provided, a read-only view backed by static storage will be returned.",
                    },
                },
            );

            if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator)) {
                var re: types.Scalar(N) = try zero(types.Scalar(N), .{ .allocator = ctx.allocator });
                errdefer re.deinit(ctx.allocator);

                return .{
                    .re = re,
                    .im = try zero(types.Scalar(N), .{ .allocator = ctx.allocator }),
                    .flags = .{ .owns_data = true, .writable = true },
                };
            } else {
                return .{
                    .re = zero(types.Scalar(N), .{}) catch unreachable,
                    .im = zero(types.Scalar(N), .{}) catch unreachable,
                    .flags = .{ .owns_data = false, .writable = false },
                };
            }
        },
        .custom => {
            comptime if (!types.hasMethod(N, "zmlZero", fn (anytype) anyerror!N, &.{@TypeOf(ctx)}))
                @compileError("zml.zero: " ++ @typeName(N) ++ " must implement `fn zmlZero(anytype) !" ++ @typeName(N) ++ "`");

            return N.zmlZero(ctx);
        },
    }
}

/// Returns the multiplicative identity (one) for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the one value for.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `N`: The one value.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must implement the required `zmlOne` method. The expected signature and
/// behavior of `zmlOne` are as follows:
/// * `fn zmlOne(anytype) !N`: Returns the one, potentially using the provided
///   context for necessary resources. This function is responsible for
///   validating the context.
///
/// Custom types can optionally declare `zml_has_simple_one` as `true` to
/// indicate that their `zmlOne` implementation can be called with an empty
/// context, returning a view and never erroring.
pub inline fn one(
    comptime N: type,
    ctx: anytype,
) !N {
    if (!comptime types.isNumeric(N))
        @compileError("zml.one: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime types.numericType(N)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return true;
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return 1;
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return 1.0;
        },
        .dyadic => @compileError("zml.one: not implemented for dyadic types yet"),
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return .{
                .re = one(types.Scalar(N), .{}) catch unreachable,
                .im = zero(types.Scalar(N), .{}) catch unreachable,
            };
        },
        .integer => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the integer's memory allocation. If not provided, a read-only view backed by static storage will be returned.",
                    },
                },
            );

            if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator)) {
                var result: integer.Integer = try .init(ctx.allocator, 2);
                result.limbs[0] = 1;
                result.size = 1;
                return result;
            } else {
                return .{
                    .limbs = @ptrCast(@constCast(&_one)),
                    .size = 0,
                    ._llen = 0,
                    .positive = true,
                    .flags = .{ .owns_data = false, .writable = false },
                };
            }
        },
        .rational => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the rational's memory allocation. If not provided, a read-only view backed by static storage will be returned.",
                    },
                },
            );

            if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator)) {
                var num: integer.Integer = try one(integer.Integer, .{ .allocator = ctx.allocator });
                errdefer num.deinit(ctx.allocator);

                return .{
                    .num = num,
                    .den = try one(integer.Integer, .{ .allocator = ctx.allocator }),
                    .flags = .{ .owns_data = true, .writable = true },
                };
            } else {
                return .{
                    .num = one(integer.Integer, .{}) catch unreachable,
                    .den = one(integer.Integer, .{}) catch unreachable,
                    .flags = .{ .owns_data = false, .writable = false },
                };
            }
        },
        .real => @compileError("zml.one: not implemented for " ++ @typeName(N) ++ " yet"),
        .complex => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the complex's memory allocation. If not provided, a read-only view backed by static storage will be returned.",
                    },
                },
            );

            if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator)) {
                var re: types.Scalar(N) = try one(types.Scalar(N), .{ .allocator = ctx.allocator });
                errdefer re.deinit(ctx.allocator);

                return .{
                    .re = re,
                    .im = try zero(types.Scalar(N), .{ .allocator = ctx.allocator }),
                    .flags = .{ .owns_data = true, .writable = true },
                };
            } else {
                return .{
                    .re = one(types.Scalar(N), .{}) catch unreachable,
                    .im = zero(types.Scalar(N), .{}) catch unreachable,
                    .flags = .{ .owns_data = false, .writable = false },
                };
            }
        },
        .custom => {
            comptime if (!types.hasMethod(N, "zmlOne", fn (anytype) anyerror!N, &.{@TypeOf(ctx)}))
                @compileError("zml.one: " ++ @typeName(N) ++ " must implement `fn zmlOne(anytype) !" ++ @typeName(N) ++ "`");

            return N.zmlOne(ctx);
        },
    }
}

/// Returns the numeric constant two for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the two value for.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `N`: The two value.
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must implement the required `zmlTwo` method. The expected signature and
/// behavior of `zmlTwo` are as follows:
/// * `fn zmlTwo(anytype) !N`: Returns the two, potentially using the provided
///   context for necessary resources. This function is responsible for
///   validating the context.
///
/// Custom types can optionally declare `zml_has_simple_two` as `true` to
/// indicate that their `zmlTwo` implementation can be called with an empty
/// context, returning a view and never erroring.
pub inline fn two(
    comptime N: type,
    ctx: anytype,
) !N {
    if (!comptime types.isNumeric(N))
        @compileError("zml.two: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime types.numericType(N)) {
        .bool => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return true;
        },
        .int => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return 2;
        },
        .float => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return 2.0;
        },
        .dyadic => @compileError("zml.two: not implemented for dyadic types yet"),
        .cfloat => {
            comptime types.validateContext(@TypeOf(ctx), .{});

            return .{
                .re = two(types.Scalar(N), .{}) catch unreachable,
                .im = zero(types.Scalar(N), .{}) catch unreachable,
            };
        },
        .integer => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the integer's memory allocation. If not provided, a read-only view backed by static storage will be returned.",
                    },
                },
            );

            if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator)) {
                var result: integer.Integer = try .init(ctx.allocator, 2);
                result.limbs[0] = 2;
                result.size = 1;
                return result;
            } else {
                return .{
                    .limbs = @ptrCast(@constCast(&_two)),
                    .size = 0,
                    ._llen = 0,
                    .positive = true,
                    .flags = .{ .owns_data = false, .writable = false },
                };
            }
        },
        .rational => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the rational's memory allocation. If not provided, a read-only view backed by static storage will be returned.",
                    },
                },
            );

            if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator)) {
                var num: integer.Integer = try two(integer.Integer, .{ .allocator = ctx.allocator });
                errdefer num.deinit(ctx.allocator);

                return .{
                    .num = num,
                    .den = try two(integer.Integer, .{ .allocator = ctx.allocator }),
                    .flags = .{ .owns_data = true, .writable = true },
                };
            } else {
                return .{
                    .num = two(integer.Integer, .{}) catch unreachable,
                    .den = one(integer.Integer, .{}) catch unreachable,
                    .flags = .{ .owns_data = false, .writable = false },
                };
            }
        },
        .real => @compileError("zml.two: not implemented for " ++ @typeName(N) ++ " yet"),
        .complex => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = false,
                        .description = "The allocator to use for the complex's memory allocation. If not provided, a read-only view backed by static storage will be returned.",
                    },
                },
            );

            if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator)) {
                var re: types.Scalar(N) = try two(types.Scalar(N), .{ .allocator = ctx.allocator });
                errdefer re.deinit(ctx.allocator);

                return .{
                    .re = re,
                    .im = try zero(types.Scalar(N), .{ .allocator = ctx.allocator }),
                    .flags = .{ .owns_data = true, .writable = true },
                };
            } else {
                return .{
                    .re = two(types.Scalar(N), .{}) catch unreachable,
                    .im = zero(types.Scalar(N), .{}) catch unreachable,
                    .flags = .{ .owns_data = false, .writable = false },
                };
            }
        },
        .custom => {
            comptime if (!types.hasMethod(N, "zmlTwo", fn (anytype) anyerror!N, &.{@TypeOf(ctx)}))
                @compileError("zml.two: " ++ @typeName(N) ++ " must implement `fn zmlTwo(anytype) !" ++ @typeName(N) ++ "`");

            return N.zmlTwo(ctx);
        },
    }
}
