const std = @import("std");

const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

pub fn isNan(x: anytype) bool {
    const X: type = @TypeOf(x);

    switch (comptime meta.numericType(X)) {
        .bool => return false,
        .int => return false,
        .float => return std.math.isNan(x),
        .dyadic => return x.exponent == numeric.highest(X.Exponent) and x.mantissa != 0,
        .complex => return (numeric.isNan(numeric.re(x)) or numeric.isNan(numeric.im(x))) and
            !numeric.isInf(numeric.re(x)) and !numeric.isInf(numeric.im(x)),
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{X},
                "isNan",
                fn (X) bool,
                &.{X},
            ) orelse
                @compileError("zsl.numeric.isNan: " ++ @typeName(X) ++ " must implement `fn isNan(" ++ @typeName(X) ++ ") " ++ "bool`");

            return Impl.isNan(x);
        },
    }
}
