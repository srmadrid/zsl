const meta = @import("../meta.zig");

pub fn bitSize(x: anytype) u16 {
    const X: type = @TypeOf(x);

    comptime if (!meta.isNumeric(X) or meta.numericType(X) != .int)
        @compileError("zsl.int.bitSize: x must be an int, got \n\tx: " ++ @typeName(X) ++ "\n");

    return switch (comptime X) {
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
    };
}
