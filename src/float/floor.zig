const types = @import("../types.zig");

pub fn floor(x: anytype) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!types.isNumeric(X) or types.numericType(X) != .float)
        @compileError("zsl.float.floor: x must be a float, got \n\tx: " ++ @typeName(@TypeOf(x)) ++ "\n");

    return @floor(x);
}
