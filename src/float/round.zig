const types = @import("../types.zig");

pub fn round(x: anytype) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!types.isNumeric(X) or types.numericType(X) != .float)
        @compileError("zsl.float.round: x must be a float, got \n\tx: " ++ @typeName(@TypeOf(x)) ++ "\n");

    return @round(x);
}
