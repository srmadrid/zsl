const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

pub fn isZero(x: anytype) bool {
    const X: type = @TypeOf(x);

    switch (comptime meta.numericType(X)) {
        .bool => return !x,
        .int => return x == 0,
        .float => return x == 0.0,
        .dyadic => return x.exponent == numeric.lowest(X.Exponent) and x.mantissa == 0,
        .complex => return numeric.isZero(numeric.re(x)) or numeric.isZero(numeric.im(x)),
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{X},
                "isZero",
                fn (X) bool,
                &.{X},
            ) orelse
                @compileError("zsl.numeric.isZero: " ++ @typeName(X) ++ " must implement `fn isZero(" ++ @typeName(X) ++ ") " ++ "bool`");

            return Impl.isZero(x);
        },
    }
}
