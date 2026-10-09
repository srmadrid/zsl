const numeric = @import("../../../numeric.zig");

pub fn ln(x: anytype) @TypeOf(x) {
    return .{
        .re = numeric.ln(numeric.abs(x)),
        .im = numeric.arg(x),
    };
}
