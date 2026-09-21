const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

pub fn bitSize(x: anytype) bool {
    const X: type = @TypeOf(x);

    switch (comptime meta.numericType(X)) {
        .bool => return 1,
        .int => return switch (comptime X) {
            else => @typeInfo(X).int.bits,
            comptime_int => blk: {
                comptime if (x == 0)
                    break :blk 1;

                comptime var temp = if (x < 0) -x else x;
                comptime var bits: comptime_int = 0;
                inline while (temp > 0) : (temp >>= 1) {
                    bits += 1;
                }

                break :blk bits + if (x < 0) 1 else 0;
            },
        },
        .float => return @typeInfo(X).float.bits,
        .dyadic => return @typeInfo(X.Mantissa).int.bits + @typeInfo(X.Exponent).int.bits + 1,
        .complex => return numeric.bitSize(numeric.re(x)) + numeric.bitSize(numeric.im(x)),
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{X},
                "bitSize",
                fn (X) u16,
                &.{X},
            ) orelse
                @compileError("zsl.numeric.bitSize: " ++ @typeName(X) ++ " must implement `fn bitSize(" ++ @typeName(X) ++ ") " ++ "u16`");

            return Impl.bitSize(x);
        },
    }
}
