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

/// Performs in-place computation of the complex conjugate of a numeric `x` into
/// a numeric `o`.
///
/// ## Signature
/// ```zig
/// numeric.conj_(o: *O, x: X, ctx: anytype) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The numeric value to get the complex conjugate of.
/// * `ctx` (`anytype`): A context struct providing necessary resources and
///   configuration for the operation.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
/// * `integer.Error.AllocatorRequired`: If `O == X == Integer`, `o` and `x`
///   are different instances, and no allocator is provided in the context.
/// * `rational.Error.AllocatorRequired`: If `O == X == Rational`, `o` and `x`
///   are different instances, and no allocator is provided in the context.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `O` or `X` should implement the required `zmlConj_` method. The expected
/// signature and behavior of `zmlConj_` are as follows:
/// * `fn zmlConj_(*O, X, anytype) !void`: Computes the complex conjugate of `x`
///   and stores it in `o`, potentially using the provided context for necessary
///   resources. This function is responsible for validating the context.
///
/// Custom types can optionally declare `zml_has_simple_conj` as `true` to
/// indicate that their `zmlConj_` implementation can be called with an empty
/// context (particularly when `O == X` and `o` and `x` are the same instance),
/// instead performing the operation in-place and never erroring.
///
/// If neither `O` nor `X` implement the required `zmlConj_` method, the
/// function will fall back to using `numeric.set` with the result of
/// `numeric.conj`, resulting in a less efficient implementation as it may
/// involve unnecessary allocations and copying. In this case, `O`, `X` and
/// `ctx`  must adhere to the requirements of these functions.
pub inline fn conj_(o: anytype, x: anytype, ctx: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X))
        @compileError("zml.numeric.conj_: o must be a mutable one-item pointer to a numeric, and x must be a numeric, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) { // O and X both custom
            const Impl: ?type = comptime types.anyHasMethod(
                &.{ O, X },
                "zmlConj_",
                fn (*O, X, anytype) anyerror!void,
                &.{ *O, X, @TypeOf(ctx) },
            );

            if (comptime Impl != null) {
                return Impl.?.zmlConj_(o, x, ctx);
            } else {
                var conj = try numeric.conj(x, ctx);
                defer numeric.deinit(&conj, ctx);

                return numeric.set(
                    o,
                    conj,
                    ctx,
                );
            }
        } else { // only O custom
            if (comptime types.hasMethod(O, "zmlConj_", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) })) {
                return O.zmlConj_(o, x, ctx);
            } else {
                var conj = try numeric.conj(x, ctx);
                defer numeric.deinit(&conj, ctx);

                return numeric.set(
                    o,
                    conj,
                    ctx,
                );
            }
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        if (comptime types.hasMethod(X, "zmlConj_", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) })) {
            return X.zmlConj_(o, x, ctx);
        } else {
            var conj = try numeric.conj(x, ctx);
            defer numeric.deinit(&conj, ctx);

            return numeric.set(
                o,
                conj,
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
                    x,
                    ctx,
                ) catch unreachable;
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    x,
                    ctx,
                ) catch unreachable;
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    x,
                    ctx,
                ) catch unreachable;
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    x.conj(),
                    ctx,
                ) catch unreachable;
            },
            .integer => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    x,
                    ctx,
                ) catch unreachable;
            },
            .rational => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    x,
                    ctx,
                ) catch unreachable;
            },
            .real => @compileError("zml.numeric.conj_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.conj_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    x,
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
                    x,
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
                    x,
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
                    x.conj(),
                    ctx,
                );
            },
            .integer => {
                comptime types.validateContext(
                    @TypeOf(ctx),
                    .{
                        .allocator = .{
                            .type = std.mem.Allocator,
                            .required = false,
                            .description = "The allocator for the integer's memory allocation. If not provided, the operation will return an error unless o and x refer to the same integer.",
                        },
                    },
                );

                return numeric.set(
                    o,
                    x,
                    ctx,
                );
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
                    },
                );

                return numeric.set(
                    o,
                    x,
                    ctx,
                );
            },
            .real => @compileError("zml.numeric.conj_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.conj_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    x,
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
                    x,
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
                    x,
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
                    x,
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

                return numeric.set(
                    o,
                    x,
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

                return numeric.set(
                    o,
                    x,
                    ctx,
                );
            },
            .real => @compileError("zml.numeric.conj_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.conj_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .custom => unreachable,
        },
        .real => @compileError("zml.numeric.conj_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.conj_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .custom => unreachable,
    }
}
