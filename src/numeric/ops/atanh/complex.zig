const numeric = @import("../../../numeric.zig");

pub fn atanh(x: anytype) @TypeOf(x) {
    return numeric.div(
        numeric.sub(
            numeric.ln(numeric.add(1, x)),
            numeric.ln(numeric.sub(1, x)),
        ),
        2,
    );
}
