const numeric = @import("../../../numeric.zig");

pub fn acos(x: anytype) @TypeOf(x) {
    const prod = numeric.mul(
        numeric.sqrt(numeric.sub(1, x)),
        numeric.sqrt(numeric.add(1, x)),
    );

    const i_prod = @TypeOf(prod){
        .re = numeric.neg(numeric.im(prod)),
        .im = numeric.re(prod),
    };

    const inner = numeric.ln(numeric.add(x, i_prod));

    return .{
        .re = numeric.im(inner),
        .im = numeric.neg(numeric.re(inner)),
    };
}
