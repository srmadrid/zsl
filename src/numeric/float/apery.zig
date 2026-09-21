const meta = @import("../meta.zig");

pub fn apery(comptime Float: type) Float {
    comptime if (!meta.isNumeric(Float) or meta.numericType(Float) != .float)
        @compileError("zsl.float.apery: Float must be a float type, got \n\tFloat = " ++ @typeName(Float) ++ "\n");

    return 1.20205690315959428539973816151144999076498629234049;
}
