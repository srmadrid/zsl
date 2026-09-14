const meta = @import("../meta.zig");

pub fn eps(comptime Int: type) Int {
    comptime if (!meta.isNumeric(Int) or meta.numericType(Int) != .int)
        @compileError("zsl.int.eps: Int must be an int type, got \n\tInt = " ++ @typeName(Int) ++ "\n");

    return 0;
}
