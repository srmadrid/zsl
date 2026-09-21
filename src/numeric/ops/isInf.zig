const std = @import("std");

const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

pub fn isInf(x: anytype) bool {
    const X: type = @TypeOf(x);

    switch (comptime meta.numericType(X)) {
        .bool => return false,
        .int => return false,
        .float => return std.math.isPositiveInf(x),
        .dyadic => return x.exponent == numeric.highest(X.Exponent) and x.mantissa == 0,
        .complex => return numeric.isInf(numeric.re(x)) or numeric.isInf(numeric.im(x)),
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{X},
                "isInf",
                fn (X) bool,
                &.{X},
            ) orelse
                @compileError("zsl.numeric.isInf: " ++ @typeName(X) ++ " must implement `fn isInf(" ++ @typeName(X) ++ ") " ++ "bool`");

            return Impl.isInf(x);
        },
    }
}
