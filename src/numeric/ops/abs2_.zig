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

/// Performs in-place computation of the squared absolute value of a numeric `x`
/// into a numeric `o`.
///
/// ## Signature
/// ```zig
/// numeric.abs2_(o: *O, x: X, ctx: anytype) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The numeric value to get the squared absolute value of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `O` or `X` should implement the required `zmlAbs2_` method. The expected
/// signature and behavior of `zmlAbs2_` are as follows:
/// * `fn zmlAbs2_(*O, X, anytype) !void`: Computes the squared absolute value
///   of `x` and stores it in `o`, potentially using the provided context for
///   necessary resources. This function is responsible for validating the
///   context.
///
/// If neither `O` nor `X` implement the required `zmlAbs2_` method, the
/// function will fall back to using `numeric.set` with the result of
/// `numeric.abs2`, resulting in a less efficient implementation as it may
/// involve unnecessary allocations and copying. In this case, `O`, `X` and
/// `ctx`  must adhere to the requirements of these functions.
pub inline fn abs2_(o: anytype, x: anytype, ctx: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X))
        @compileError("zml.numeric.abs2_: o must be a mutable one-item pointer to a numeric, and x must be a numeric, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) { // O and X both custom
            const Impl: ?type = comptime types.anyHasMethod(
                &.{ O, X },
                "zmlAbs2_",
                fn (*O, X, anytype) anyerror!void,
                &.{ *O, X, @TypeOf(ctx) },
            );

            if (comptime Impl != null) {
                return Impl.?.zmlAbs2_(o, x, ctx);
            } else {
                var abs2 = try numeric.abs2(x, ctx);
                defer numeric.deinit(&abs2, ctx);

                return numeric.set(
                    o,
                    abs2,
                    ctx,
                );
            }
        } else { // only O custom
            if (comptime types.hasMethod(O, "zmlAbs2_", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) })) {
                return O.zmlAbs2_(o, x, ctx);
            } else {
                var abs2 = try numeric.abs2(x, ctx);
                defer numeric.deinit(&abs2, ctx);

                return numeric.set(
                    o,
                    abs2,
                    ctx,
                );
            }
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        if (comptime types.hasMethod(X, "zmlAbs2_", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) })) {
            return X.zmlAbs2_(o, x, ctx);
        } else {
            var abs2 = try numeric.abs2(x, ctx);
            defer numeric.deinit(&abs2, ctx);

            return numeric.set(
                o,
                abs2,
                ctx,
            );
        }
    }

    switch (comptime types.numericType(O)) {
        .bool, .int, .float, .dyadic, .cfloat => switch (comptime types.numericType(X)) {
            .bool => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    x,
                    ctx,
                ) catch unreachable;
            },
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    int.mul(x, x),
                    ctx,
                ) catch unreachable;
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    float.mul(x, x),
                    ctx,
                ) catch unreachable;
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    dyadic.mul(x, x),
                    ctx,
                ) catch unreachable;
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    cfloat.abs2(x),
                    ctx,
                ) catch unreachable;
            },
            .integer => {
                comptime types.validateContext(@TypeOf(ctx), .{
                    .buffer_allocator = .{
                        .type = std.mem.Allocator,
                        .required = true,
                        .description = "The allocator to use for the operation's temporary integer buffer allocation.",
                    },
                    .buffer = .{
                        .type = *integer.Integer,
                        .required = false,
                        .description = "A pointer to a persistent integer buffer that can be used for the operation's temporary allocations. If not provided, the operation will initialize a new buffer and deinitialize it before returning. Providing a buffer can be more efficient if the caller is performing multiple operations in a row and can reuse the same buffer for all of them.",
                    },
                });

                if (comptime types.ctxHasField(@TypeOf(ctx), "buffer", *integer.Integer)) {
                    try integer.mul_(ctx.buffer_allocator, ctx.buffer, x, x);

                    return numeric.set(
                        o,
                        ctx.buffer.*,
                        ctx,
                    ) catch unreachable;
                } else {
                    var abs2 = try integer.mul(ctx.buffer_allocator, x, x);
                    defer abs2.deinit(ctx.buffer_allocator);

                    return numeric.set(
                        o,
                        abs2,
                        ctx,
                    ) catch unreachable;
                }
            },
            .rational => {
                comptime types.validateContext(@TypeOf(ctx), .{
                    .buffer_allocator = .{
                        .type = std.mem.Allocator,
                        .required = true,
                        .description = "The allocator to use for the operation's temporary rational buffer allocation.",
                    },
                    .buffer = .{
                        .type = *rational.Rational,
                        .required = false,
                        .description = "A pointer to a persistent rational buffer that can be used for the operation's temporary allocations. If not provided, the operation will initialize a new buffer and deinitialize it before returning. Providing a buffer can be more efficient if the caller is performing multiple operations in a row and can reuse the same buffer for all of them.",
                    },
                });

                if (comptime types.ctxHasField(@TypeOf(ctx), "buffer", *rational.Rational)) {
                    try rational.mul_(ctx.buffer_allocator, ctx.buffer, x, x);

                    return numeric.set(
                        o,
                        ctx.buffer.*,
                        ctx,
                    ) catch unreachable;
                } else {
                    var abs2 = try rational.mul(ctx.buffer_allocator, x, x);
                    defer abs2.deinit(ctx.buffer_allocator);

                    return numeric.set(
                        o,
                        abs2,
                        ctx,
                    ) catch unreachable;
                }
            },
            .real => @compileError("zml.numeric.abs2_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.abs2_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .custom => unreachable,
        },
        .integer => switch (comptime types.numericType(X)) {
            .bool => {
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

                return numeric.set(
                    o,
                    x,
                    ctx,
                );
            },
            .int => {
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

                return numeric.set(
                    o,
                    int.mul(x, x),
                    ctx,
                );
            },
            .float => {
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

                return numeric.set(
                    o,
                    float.mul(x, x),
                    ctx,
                );
            },
            .dyadic => {
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

                return numeric.set(
                    o,
                    dyadic.mul(x, x),
                    ctx,
                );
            },
            .cfloat => {
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

                return numeric.set(
                    o,
                    cfloat.abs2(x),
                    ctx,
                );
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

                return integer.mul_(ctx.allocator, o, x, x);
            },
            .rational => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the integer's memory allocation.",
                        },
                        .buffer_allocator = .{
                            .type = std.mem.Allocator,
                            .required = false,
                            .description = "The allocator to use for the operation's temporary rational buffer allocation. If not provided, the operation will use the integer allocator for the rational's temporary buffer allocation as well.",
                        },
                        .buffer = .{
                            .type = *rational.Rational,
                            .required = false,
                            .description = "A pointer to a persistent rational buffer that can be used for the operation's temporary allocations. If not provided, the operation will initialize a new buffer and deinitialize it before returning. Providing a buffer can be more efficient if the caller is performing multiple operations in a row and can reuse the same buffer for all of them.",
                        },
                    },
                );

                if (comptime types.ctxHasField(@TypeOf(ctx), "buffer", *rational.Rational)) {
                    try rational.mul_(
                        if (comptime types.ctxHasField(@TypeOf(ctx), "buffer_allocator", std.mem.Allocator))
                            ctx.buffer_allocator
                        else
                            ctx.allocator,
                        ctx.buffer,
                        x,
                        x,
                    );

                    return numeric.set(
                        o,
                        ctx.buffer.*,
                        ctx,
                    );
                } else {
                    var abs2 = try rational.mul(
                        if (comptime types.ctxHasField(@TypeOf(ctx), "buffer_allocator", std.mem.Allocator))
                            ctx.buffer_allocator
                        else
                            ctx.allocator,
                        x,
                        x,
                    );
                    defer abs2.deinit(
                        if (comptime types.ctxHasField(@TypeOf(ctx), "buffer_allocator", std.mem.Allocator))
                            ctx.buffer_allocator
                        else
                            ctx.allocator,
                    );

                    return numeric.set(
                        o,
                        abs2,
                        ctx,
                    );
                }
            },
            .real => @compileError("zml.numeric.abs2_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.abs2_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(X)) {
            .bool => {
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

                return numeric.set(
                    o,
                    x,
                    ctx,
                );
            },
            .int => {
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

                return numeric.set(
                    o,
                    int.mul(x, x),
                    ctx,
                );
            },
            .float => {
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

                return numeric.set(
                    o,
                    float.mul(x, x),
                    ctx,
                );
            },
            .dyadic => {
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

                return numeric.set(
                    o,
                    dyadic.mul(x, x),
                    ctx,
                );
            },
            .cfloat => {
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

                return numeric.set(
                    o,
                    cfloat.abs2(x),
                    ctx,
                );
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
                        .buffer_allocator = .{
                            .type = std.mem.Allocator,
                            .required = false,
                            .description = "The allocator to use for the operation's temporary integer buffer allocation. If not provided, the operation will use the rational allocator for the integer's temporary buffer allocation as well.",
                        },
                        .buffer = .{
                            .type = *integer.Integer,
                            .required = false,
                            .description = "A pointer to a persistent integer buffer that can be used for the operation's temporary allocations. If not provided, the operation will initialize a new buffer and deinitialize it before returning. Providing a buffer can be more efficient if the caller is performing multiple operations in a row and can reuse the same buffer for all of them.",
                        },
                    },
                );

                if (comptime types.ctxHasField(@TypeOf(ctx), "buffer", *integer.Integer)) {
                    try integer.mul_(
                        if (comptime types.ctxHasField(@TypeOf(ctx), "buffer_allocator", std.mem.Allocator))
                            ctx.buffer_allocator
                        else
                            ctx.allocator,
                        ctx.buffer,
                        x,
                        x,
                    );

                    return numeric.set(
                        o,
                        ctx.buffer.*,
                        ctx,
                    );
                } else {
                    var abs2 = try integer.mul(
                        if (comptime types.ctxHasField(@TypeOf(ctx), "buffer_allocator", std.mem.Allocator))
                            ctx.buffer_allocator
                        else
                            ctx.allocator,
                        x,
                        x,
                    );
                    defer abs2.deinit(
                        if (comptime types.ctxHasField(@TypeOf(ctx), "buffer_allocator", std.mem.Allocator))
                            ctx.buffer_allocator
                        else
                            ctx.allocator,
                    );

                    return numeric.set(
                        o,
                        abs2,
                        ctx,
                    );
                }
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

                return rational.mul_(ctx.allocator, o, x, x);
            },
            .real => @compileError("zml.numeric.abs2_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.abs2_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .custom => unreachable,
        },
        .real => @compileError("zml.numeric.abs2_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.abs2_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .custom => unreachable,
    }
}
