const std = @import("std");

const numeric = @import("../../../numeric.zig");

// Implement so isize n works
pub fn scale2(x: anytype, n: isize) @TypeOf(x) {
    return std.math.scalbn(x, numeric.cast(i32, n));
}
