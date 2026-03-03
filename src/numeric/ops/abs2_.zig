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
///   configuration for the operation. The required fields depend on `X` and
///   `Y`. If the context is missing required fields or contains unnecessary or
///   wrongly typed fields, the compiler will emit a detailed error message
///   describing the expected structure.
///
/// ### Context structure
/// The fields of `ctx` depend on `O` and `X`.
///
/// #### `O` is not allocated and `X` is not allocated
/// The context must be empty.
/// 
/// #### `O` is not allocated and `X` is allocated
/// * `buffer_allocator: std.mem.Allocator`: The allocator to use for the 
///   operation's temporary buffer allocation.
/// * `buffer: numeric.Abs2(X)` (optional): A persistent buffer that can be used 
///   for the operation's temporary storage. If not provided, the operation will 
///   initialize a new buffer and deinitialize it before returning. Providing a 
///   buffer can be more efficient if the caller is performing multiple 
///   operations in a row and can reuse the same buffer for all of them.
///
/// #### `O` is allocated and `X` is not allocated
/// * `allocator: std.mem.Allocator`: The allocator to use for the output value.
/// 
/// #### `O` is allocated, `X` is allocated and `O == X`
/// * `allocator: std.mem.Allocator`: The allocator to use for the output value.
///   The operation will perform the computation in-place, so no additional 
///   buffer is needed.
/// 
/// #### `O` is allocated, `X` is allocated and `O != X`
/// * `allocator: std.mem.Allocator`: The allocator to use for the output value.
/// * `buffer_allocator: std.mem.Allocator` (optional): The allocator to use for 
///   the operation's temporary buffer allocation. If not provided, the 
///   operation will use the output allocator for the temporary buffer 
///   allocation as well.
/// * `buffer: numeric.Abs2(X)` (optional): A persistent buffer that can be used
///   for the operation's temporary storage. If not provided, the operation will
///   initialize a new buffer and deinitialize it before returning. Providing a
///   buffer can be more efficient if the caller is performing multiple 
///   operations in a row and can reuse the same buffer for all of them.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails. Can
///   only happen if `O` is allocated and an allocator is provided.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `O` or `X` should implement the required `abs2_` method. The expected
/// signature and behavior of `abs2_` are as follows:
/// * `O` is not allocated: `fn abs2_(*O, X) void`: Computes the squared
///   absolute value of `x` and stores it in `o`.
/// * `O` is allocated: `fn abs2_(std.mem.Allocator, *O, X) !void`: Computes the
///   squared absolute value of `x` and stores it in `o`.
///
/// If neither `O` nor `X` implement the required `abs2_` method, the function
/// will fall back to using `numeric.set` with the result of `numeric.abs2`. In
/// this case, `O`, `X` and `ctx`  must adhere to the requirements of these
/// functions.
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
            if (comptime types.isAllocated(O)) {
                const Impl: ?type = comptime types.anyHasMethod(
                    &.{ O, X },
                    "abs2_",
                    fn (std.mem.Allocator, *O, X) anyerror!void,
                    &.{ std.mem.Allocator, *O, X },
                );

                if (comptime Impl != null) {
                    comptime types.validateContext(
                        @TypeOf(ctx),
                        .{
                            .allocator = .{
                                .type = std.mem.Allocator,
                                .required = true,
                                .description = "The allocator to use for the custom numeric's memory allocation.",
                            },
                        },
                    );

                    try Impl.?.abs2_(ctx.allocator, o, x);
                } else {
                    comptime if (types.isAllocated(numeric.Abs2(X)))
                        types.validateContext(
                            @TypeOf(ctx),
                            .{
                                .allocator = .{
                                    .type = std.mem.Allocator,
                                    .required = true,
                                    .description = "The allocator to use for the custom numeric's memory allocation.",
                                },
                                .buffer_allocator = .{
                                    .type = std.mem.Allocator,
                                    .required = false,
                                    .description = "The allocator to use for the operation's temporary buffer allocation. If not provided, the operation will use the custom numeric allocator for the temporary buffer allocation as well.",
                                },
                            },
                        )
                    else
                        types.validateContext(@TypeOf(ctx), .{
                            .allocator = .{
                                .type = std.mem.Allocator,
                                .required = true,
                                .description = "The allocator to use for the custom numeric's memory allocation.",
                            },
                        });

                    const abs2_ctx = if (comptime types.isAllocated(numeric.Abs2(X)))
                        if (comptime types.ctxHasField(@TypeOf(ctx), "buffer_allocator", std.mem.Allocator))
                            types.keepRenameStructFields(ctx, .{ .buffer_allocator = "allocator" })
                        else
                            ctx
                    else
                        .{};

                    var abs2 = try numeric.abs2(x, abs2_ctx);
                    defer numeric.deinit(&abs2, abs2_ctx);

                    try numeric.set(
                        o,
                        abs2,
                        types.keepStructFields(ctx, .{"allocator"}),
                    );
                }

                return;

                FROM HERE, ALSO EDIT ABS_ AND THE REST OF THE OPERATIONS THAT LOOK FOR A SIMPLE VERSION
            } else {
                const Impl: type = comptime types.anyHasMethod(
                    &.{ O, X },
                    "abs2_",
                    fn (*O, X) void,
                    &.{ *O, X },
                ) orelse {
                    var abs2 = try numeric.abs2(x, ctx);
                    defer numeric.deinit(&abs2, ctx);

                    numeric.set(
                        o,
                        abs2,
                        .{},
                    ) catch unreachable;

                    return;
                };

                comptime types.validateContext(@TypeOf(ctx), .{});

                Impl.abs2_(o, x);

                return;
            }
        } else { // only O custom
            if (comptime types.isAllocated(O)) {
                if (comptime !types.hasMethod(O, "abs2_", fn (std.mem.Allocator, *O, X) anyerror!void, &.{ std.mem.Allocator, *O, X })) {
                    var abs2 = try numeric.abs2(x, if (types.isAllocated(numeric.Abs2(X))) ctx else .{});
                    defer numeric.deinit(&abs2, if (types.isAllocated(numeric.Abs2(X))) ctx else .{});

                    try numeric.set(
                        o,
                        abs2,
                        ctx,
                    );

                    return;
                }

                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = true,
                            .description = "The allocator to use for the custom numeric's memory allocation.",
                        },
                    },
                );

                try O.abs2_(ctx.allocator, o, x);

                return;
            } else {
                if (comptime !types.hasMethod(O, "abs2_", fn (*O, X) void, &.{ *O, X })) {
                    var abs2 = try numeric.abs2(x, ctx);
                    defer numeric.deinit(&abs2, ctx);

                    numeric.set(
                        o,
                        abs2,
                        .{},
                    ) catch unreachable;

                    return;
                }

                comptime types.validateContext(@TypeOf(ctx), .{});

                O.abs2_(o, x);

                return;
            }
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        if (comptime types.isAllocated(O)) {
            if (comptime !types.hasMethod(X, "abs2_", fn (std.mem.Allocator, *O, X) anyerror!void, &.{ std.mem.Allocator, *O, X })) {
                var abs2 = try numeric.abs2(x, if (types.isAllocated(numeric.Abs2(X))) ctx else .{});
                defer numeric.deinit(&abs2, if (types.isAllocated(numeric.Abs2(X))) ctx else .{});

                try numeric.set(
                    o,
                    abs2,
                    ctx,
                );

                return;
            }

            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = true,
                        .description = "The allocator to use for the custom numeric's memory allocation.",
                    },
                },
            );

            try X.abs2_(ctx.allocator, o, x);

            return;
        } else {
            if (comptime !types.hasMethod(X, "abs2_", fn (*O, X) void, &.{ *O, X })) {
                var abs2 = try numeric.abs2(x, ctx);
                defer numeric.deinit(&abs2, ctx);

                numeric.set(
                    o,
                    abs2,
                    .{},
                ) catch unreachable;

                return;
            }

            comptime types.validateContext(@TypeOf(ctx), .{});

            X.abs2_(o, x);

            return;
        }
    }

    switch (comptime types.numericType(O)) {
        .bool, .int, .float, .dyadic, .cfloat => switch (comptime types.numericType(X)) {
            .bool => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                numeric.set(
                    o,
                    x,
                    ctx,
                ) catch unreachable;
            },
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                numeric.set(
                    o,
                    int.mul(x, x),
                    ctx,
                ) catch unreachable;
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                numeric.set(
                    o,
                    float.mul(x, x),
                    ctx,
                ) catch unreachable;
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                numeric.set(
                    o,
                    dyadic.mul(x, x),
                    ctx,
                ) catch unreachable;
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                numeric.set(
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
                        .type = ?*integer.Integer,
                        .required = false,
                        .description = "A pointer to a persistent integer buffer that can be used for the operation's temporary allocations. If not provided, the operation will initialize a new buffer and deinitialize it before returning. Providing a buffer can be more efficient if the caller is performing multiple operations in a row and can reuse the same buffer for all of them.",
                    },
                });

                if (comptime types.ctxHasField(@TypeOf(ctx), "buffer", ?*integer.Integer)) {
                    try integer.mul_(ctx.buffer_allocator, ctx.buffer, x, x);

                    numeric.set(
                        o,
                        ctx.buffer.*,
                        ctx,
                    ) catch unreachable;
                } else {
                    var abs2 = try integer.mul(ctx.buffer_allocator, x, x);
                    defer abs2.deinit(ctx.buffer_allocator);

                    numeric.set(
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
                        .type = ?*rational.Rational,
                        .required = false,
                        .description = "A pointer to a persistent rational buffer that can be used for the operation's temporary allocations. If not provided, the operation will initialize a new buffer and deinitialize it before returning. Providing a buffer can be more efficient if the caller is performing multiple operations in a row and can reuse the same buffer for all of them.",
                    },
                });

                if (comptime types.ctxHasField(@TypeOf(ctx), "buffer", ?*rational.Rational)) {
                    try rational.mul_(ctx.buffer_allocator, ctx.buffer, x, x);

                    numeric.set(
                        o,
                        ctx.buffer.*,
                        ctx,
                    ) catch unreachable;
                } else {
                    var abs2 = try rational.mul(ctx.buffer_allocator, x, x);
                    defer abs2.deinit(ctx.buffer_allocator);

                    numeric.set(
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

                try numeric.set(
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

                try numeric.set(
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

                try numeric.set(
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

                try numeric.set(
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

                try numeric.set(
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

                try integer.mul_(ctx.allocator, o, x, x);
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
                            .type = ?*rational.Rational,
                            .required = false,
                            .description = "A pointer to a persistent rational buffer that can be used for the operation's temporary allocations. If not provided, the operation will initialize a new buffer and deinitialize it before returning. Providing a buffer can be more efficient if the caller is performing multiple operations in a row and can reuse the same buffer for all of them.",
                        },
                    },
                );

                if (comptime types.ctxHasField(@TypeOf(ctx), "buffer", ?*rational.Rational)) {
                    try rational.mul_(ctx.buffer_allocator orelse ctx.allocator, ctx.buffer, x, x);

                    numeric.set(
                        o,
                        ctx.buffer.*,
                        ctx,
                    ) catch unreachable;
                } else {
                    var abs2 = try rational.mul(ctx.buffer_allocator orelse ctx.allocator, x, x);
                    defer abs2.deinit(ctx.buffer_allocator orelse ctx.allocator);

                    numeric.set(
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

                try numeric.set(
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

                try numeric.set(
                    o,
                    int.abs(x),
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

                try numeric.set(
                    o,
                    float.abs(x),
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

                try numeric.set(
                    o,
                    dyadic.abs(x),
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

                try numeric.set(
                    o,
                    cfloat.abs(x),
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
                    },
                );

                try numeric.set(
                    o,
                    integer.abs(null, x) catch unreachable,
                    ctx,
                );
            },
            .rational => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = false,
                            .description = "The allocator for the rational's memory allocation. If not provided, the operation will return an error unless o and x refer to the same rational.",
                        },
                    },
                );

                if (comptime types.ctxHasField(@TypeOf(ctx), "allocator", std.mem.Allocator))
                    try rational.abs_(ctx.allocator, o, x)
                else
                    try rational.abs_(null, o, x);
            },
            .real => @compileError("zml.numeric.abs_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.abs_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .custom => unreachable,
        },
        .real => @compileError("zml.numeric.abs_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.abs_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .custom => unreachable,
    }
}
