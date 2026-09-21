const std = @import("std");

const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

pub fn order(x: anytype, y: anytype) std.math.Order {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const C: type = numeric.Coerce(X, Y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y))
        @compileError("zsl.numeric.order: x and y must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    if (comptime meta.isCustomNumeric(X)) {
        if (comptime meta.isCustomNumeric(Y)) { // X and Y both custom
            const Impl: type = comptime meta.anyHasMethod(
                &.{ X, Y },
                "order",
                fn (X, Y) std.math.Order,
                &.{ X, Y },
            ) orelse
                @compileError("zsl.numeric.order: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn order(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") std.math.Order`");

            return Impl.order(x, y);
        } else { // only X custom
            comptime if (!meta.hasMethod(X, "order", fn (X, Y) std.math.Order, &.{ X, Y }))
                @compileError("zsl.numeric.order: " ++ @typeName(X) ++ " must implement `fn order(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") std.math.Order`");

            return X.order(x, y);
        }
    } else if (comptime meta.isCustomNumeric(Y)) { // only Y custom
        comptime if (!meta.hasMethod(Y, "order", fn (X, Y) std.math.Order, &.{ X, Y }))
            @compileError("zsl.numeric.order: " ++ @typeName(Y) ++ " must implement `fn order(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ") std.math.Order`");

        return Y.order(x, y);
    }

    switch (comptime meta.numericType(X)) {
        .bool => switch (comptime meta.numericType(Y)) {
            .bool => return if (x and !y) .lt else if (y and !x) .gt else .eq,
            .int, .float => return if (numeric.cast(C, x) < numeric.cast(C, y)) .lt else if (numeric.cast(C, x) > numeric.cast(C, y)) .gt else .eq,
            .dyadic => return @import("order/dyadic.zig").order(numeric.cast(C, x), numeric.cast(C, y)),
            .complex => @compileError("zsl.numeric.lt: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .int, .float => switch (comptime meta.numericType(Y)) {
            .bool, .int, .float => return if (numeric.cast(C, x) < numeric.cast(C, y)) .lt else if (numeric.cast(C, x) > numeric.cast(C, y)) .gt else .eq,
            .dyadic => return @import("order/dyadic.zig").order(numeric.cast(C, x), numeric.cast(C, y)),
            .complex => @compileError("zsl.numeric.lt: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .dyadic => switch (comptime meta.numericType(Y)) {
            .bool, .int, .float, .dyadic => return @import("order/dyadic.zig").order(numeric.cast(C, x), numeric.cast(C, y)),
            .complex => @compileError("zsl.numeric.lt: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
            .custom => unreachable,
        },
        .complex => @compileError("zsl.numeric.lt: not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "."),
        .custom => unreachable,
    }
}
