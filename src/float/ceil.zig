const meta = @import("../meta.zig");

pub fn ceil(x: anytype) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!meta.isNumeric(X) or meta.numericType(X) != .float)
        @compileError("zsl.float.ceil: x must be a float, got \n\tx: " ++ @typeName(@TypeOf(x)) ++ "\n");

    return @ceil(x);
}
