const numeric = @import("../../../numeric.zig");

pub fn acosh(x: anytype) @TypeOf(x) {
    return numeric.mul(
        numeric.ln(
            numeric.add(
                numeric.sqrt(numeric.div(numeric.add(x, 1), 2)),
                numeric.sqrt(numeric.div(numeric.sub(x, 1), 2)),
            ),
        ),
        2,
    );
}
