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

/// Performs in-place computation of the sine `sin(x)` of a numeric `x` into a
/// numeric `o`.
///
/// ## Signature
/// ```zig
/// numeric.sin_(o: *O, x: X, ctx: anytype) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The numeric value to get the sine of.
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
/// `O` or `X` should implement the required `zmlSin_` method. The expected
/// signature and behavior of `zmlSin_` are as follows:
/// * `fn zmlSin_(*O, X, anytype) !void`: Computes the sine of `x` and stores it
///   in `o`, potentially using the provided context for necessary resources.
///   This function is responsible for validating the context.
///
/// If neither `O` nor `X` implement the required `zmlSin_` method, the function
/// will fall back to using `numeric.set` with the result of `numeric.sin`,
/// resulting in a less efficient implementation as it may involve unnecessary
/// allocations and copying. In this case, `O`, `X` and `ctx`  must adhere to
/// the requirements of these functions.
pub inline fn sin_(o: anytype, x: anytype, ctx: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X))
        @compileError("zml.numeric.sin_: o must be a mutable one-item pointer to a numeric, and x must be a numeric, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) { // O and X both custom
            const Impl: ?type = comptime types.anyHasMethod(
                &.{ O, X },
                "zmlSin_",
                fn (*O, X, anytype) anyerror!void,
                &.{ *O, X, @TypeOf(ctx) },
            );

            if (comptime Impl != null) {
                return Impl.?.zmlSin_(o, x, ctx);
            } else {
                var sin = try numeric.sin(x, ctx);
                defer numeric.deinit(&sin, ctx);

                return numeric.set(
                    o,
                    sin,
                    ctx,
                );
            }
        } else { // only O custom
            if (comptime types.hasMethod(O, "zmlSin_", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) })) {
                return O.zmlSin_(o, x, ctx);
            } else {
                var sin = try numeric.sin(x, ctx);
                defer numeric.deinit(&sin, ctx);

                return numeric.set(
                    o,
                    sin,
                    ctx,
                );
            }
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        if (comptime types.hasMethod(X, "zmlSin_", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) })) {
            return X.zmlSin_(o, x, ctx);
        } else {
            var sin = try numeric.sin(x, ctx);
            defer numeric.deinit(&sin, ctx);

            return numeric.set(
                o,
                sin,
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
                    float.sin(x),
                    ctx,
                ) catch unreachable;
            },
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    float.sin(x),
                    ctx,
                ) catch unreachable;
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    float.sin(x),
                    ctx,
                ) catch unreachable;
            },
            .dyadic => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    cfloat.sin(x),
                    ctx,
                ) catch unreachable;
            },
            .integer => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .rational => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .real => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    float.sin(x),
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
                    float.sin(x),
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
                    float.sin(x),
                    ctx,
                );
            },
            .dyadic => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    cfloat.sin(x),
                    ctx,
                );
            },
            .integer => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .rational => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .real => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    float.sin(x),
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
                    float.sin(x),
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
                    float.sin(x),
                    ctx,
                );
            },
            .dyadic => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    cfloat.sin(x),
                    ctx,
                );
            },
            .integer => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .rational => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .real => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .custom => unreachable,
        },
        .real => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.sin_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .custom => unreachable,
    }
}
