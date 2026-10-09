const numeric = @import("../../../numeric.zig");

pub fn pow(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    if (y < 0)
        return 0;

    var result: @TypeOf(x) = 1;
    var base: @TypeOf(x) = x;
    var exponent: @TypeOf(x) = y;

    while (exponent != 0) : (exponent >>= 1) {
        if ((exponent & 1) != 0)
            result = numeric.mul(result, base);

        base = numeric.mul(base, base);
    }

    return result;
}
