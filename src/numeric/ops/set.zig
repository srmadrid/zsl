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

/// Sets the value of `o` to `x`.
///
/// ## Signature
/// ```zig
/// numeric.set(o: *O, x: X, ctx: anytype) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The input operand.
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
/// `O` or `X` must implement the required `zmlSet` method. The expected
/// signature and behavior of `zmlSet` are as follows:
/// * `fn zmlSet(*O, X, anytype) !void`: Sets the value of `o` to `x`,
///   potentially using the provided context for necessary resources. This
///   function is responsible for validating the context.
pub inline fn set(o: anytype, x: anytype, ctx: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or
        !types.isNumeric(types.Child(O)) or
        !types.isNumeric(X))
        @compileError("zml.numeric.set: o must be a mutable one-itme pointer to a numeric, and x must be a numeric, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O)) {
        if (comptime types.isCustomType(X)) { // O and X both custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ O, X },
                "zmlSet",
                fn (*O, X, anytype) anyerror!void,
                &.{ *O, X, @TypeOf(ctx) },
            ) orelse
                @compileError("zml.numeric.set: " ++ @typeName(O) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSet(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", anytype) !void`");

            return Impl.set(o, x, ctx);
        } else { // only O custom
            comptime if (!types.hasMethod(O, "zmlSet", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) }))
                @compileError("zml.numeric.set: " ++ @typeName(O) ++ " must implement `fn zmlSet(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", anytype) !void`");

            return O.zmlSet(o, x, ctx);
        }
    } else if (comptime types.isCustomType(X)) { // only X custom
        comptime if (!types.hasMethod(X, "zmlSet", fn (*O, X, anytype) anyerror!void, &.{ *O, X, @TypeOf(ctx) }))
            @compileError("zml.numeric.set: " ++ @typeName(X) ++ " must implement `fn zmlSet(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", anytype) !void`");

        return X.zmlSet(o, x, ctx);
    }

    switch (comptime types.numericType(O)) {
        .bool => switch (comptime types.numericType(X)) {
            .bool => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = x;
            },
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(bool, x);
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(bool, x);
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(bool, x);
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(bool, x);
            },
            .integer => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(bool, x);
            },
            .rational => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(bool, x);
            },
            .real => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(bool, x);
            },
            .complex => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(bool, x);
            },
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(X)) {
            .bool => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .integer => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .rational => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .real => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .complex => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(X)) {
            .bool => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .integer => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .rational => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .real => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .complex => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(X)) {
            .bool => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .integer => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .rational => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .real => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .complex => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .custom => unreachable,
        },
        .cfloat => switch (comptime types.numericType(X)) {
            .bool => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .int => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .float => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .dyadic => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .cfloat => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .integer => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .rational => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .real => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .complex => {
                comptime types.validateContext(@TypeOf(ctx), .{});

                o.* = types.scast(O, x);
            },
            .custom => unreachable,
        },
        .integer => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = true,
                        .description = "The allocator to use for the integer's memory deallocation. Must be the same allocator used to initialize it.",
                    },
                },
            );

            try integer.Integer.set(o, ctx.allocator, x);
        },
        .rational => {
            comptime types.validateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{
                        .type = std.mem.Allocator,
                        .required = true,
                        .description = "The allocator to use for the rational's memory deallocation. Must be the same allocator used to initialize it.",
                    },
                },
            );

            try rational.Rational.set(o, ctx.allocator, x, 1);
        },
        .real => @compileError("zml.numeric.set: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .complex => @compileError("zml.numeric.set: not implemented for " ++ @typeName(O) ++ " and " ++ @typeName(X) ++ " yet."),
        .custom => unreachable,
    }
}
