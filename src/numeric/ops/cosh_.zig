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

/// Performs in-place computation of the hyperbolic cosine `cosh(x)` of a
/// numeric `x` into a numeric `o`.
///
/// ## Signature
/// ```zig
/// numeric.cosh_(o: *O, x: X, ctx: anytype) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The numeric value to get the hyperbolic cosine of.
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
/// `O` or `X` should implement the required `zmlCosh_` method. The expected
/// signature and behavior of `zmlCosh_` are as follows:
/// * `fn zmlCosh_(*O, X, anytype) !void`: Computes the hyperbolic cosine of `x`
///   and stores it in `o`, potentially using the provided context for necessary
///   resources. This function is responsible for validating the context.
///
/// If neither `O` nor `X` implement the required `zmlCosh_` method, the function
/// will fall back to using `numeric.set` with the result of `numeric.cosh`,
/// resulting in a less efficient implementation as it may involve unnecessary
/// allocations and copying. In this case, `O`, `X` and `ctx`  must adhere to
/// the requirements of these functions.
pub inline fn cosh_(o: anytype, x: anytype, ctx: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X))
        @compileError("zml.numeric.cosh_: o must be a mutable one-item pointer to a numeric, and x must be a numeric, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) { // O and X both custom
            const Impl: ?type = comptime types.anyHasMethod(
                &.{ O, X },
                "zmlCosh_",
                fn (*O, X, anytype) anyerror!void,
                &.{ *O, X, @TypeOf(ctx) },
            );

            if (comptime Impl != null) {
                return Impl.?.zmlCosh_(o, x, ctx);
            } else {
                var cosh = try numeric.cosh(x, ctx);
                defer numeric.deinit(&cosh, ctx);

                return numeric.set(
                    o,
                    cosh,
                    ctx,
                );
            }
        } else { // only O custom
            if (comptime types.hasMethod(O, "zmlCosh_", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) })) {
                return O.zmlCosh_(o, x, ctx);
            } else {
                var cosh = try numeric.cosh(x, ctx);
                defer numeric.deinit(&cosh, ctx);

                return numeric.set(
                    o,
                    cosh,
                    ctx,
                );
            }
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        if (comptime types.hasMethod(X, "zmlCosh_", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) })) {
            return X.zmlCosh_(o, x, ctx);
        } else {
            var cosh = try numeric.cosh(x, ctx);
            defer numeric.deinit(&cosh, ctx);

            return numeric.set(
                o,
                cosh,
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
                    float.cosh(x),
                    ctx,
                ) catch unreachable;
            },
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    float.cosh(x),
                    ctx,
                ) catch unreachable;
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    float.cosh(x),
                    ctx,
                ) catch unreachable;
            },
            .dyadic => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                return numeric.set(
                    o,
                    cfloat.cosh(x),
                    ctx,
                ) catch unreachable;
            },
            .integer => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .rational => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .real => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    float.cosh(x),
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
                    float.cosh(x),
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
                    float.cosh(x),
                    ctx,
                );
            },
            .dyadic => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    cfloat.cosh(x),
                    ctx,
                );
            },
            .integer => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .rational => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .real => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    float.cosh(x),
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
                    float.cosh(x),
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
                    float.cosh(x),
                    ctx,
                );
            },
            .dyadic => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
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
                    cfloat.cosh(x),
                    ctx,
                );
            },
            .integer => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .rational => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .real => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .complex => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
            .custom => unreachable,
        },
        .real => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.cosh_: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .custom => unreachable,
    }
}
