const meta = @import("../meta.zig");

pub fn floor(x: anytype) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!meta.isNumeric(X) or meta.numericType(X) != .float)
        @compileError("zsl.float.floor: x must be a float, got \n\tx: " ++ @typeName(@TypeOf(x)) ++ "\n");

    return @floor(x);
}
