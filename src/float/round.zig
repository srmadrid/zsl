const meta = @import("../meta.zig");

pub fn round(x: anytype) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!meta.isNumeric(X) or meta.numericType(X) != .float)
        @compileError("zsl.float.round: x must be a float, got \n\tx: " ++ @typeName(@TypeOf(x)) ++ "\n");

    return @round(x);
}
