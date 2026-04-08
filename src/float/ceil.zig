const types = @import("../types.zig");

pub fn ceil(x: anytype) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!types.isNumeric(X) or types.numericType(X) != .float)
        @compileError("zsl.float.ceil: x must be a float, got \n\tx: " ++ @typeName(@TypeOf(x)) ++ "\n");

    return @ceil(x);
}
