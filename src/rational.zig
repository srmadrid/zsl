//! Namespace for rational operations.

const rational = @This();

const std = @import("std");

const types = @import("types.zig");
const Cmp = types.Cmp;
const int = @import("int.zig");

/// Arbitrary-precision rational type.
pub fn Rational(bits: u16) type {
    if (bits == 0 or bits >= int.maxVal(u16) / 2)
        @compileError(std.fmt.comptimePrint(
            "zsl.Dyadic: bits must be non-zero and less than {}, got\n\tbits: {}\n",
            .{ int.maxVal(u16) / 2, bits },
        ));

    return packed struct {
        numerator: Numerator,
        denominator: Denominator,

        /// Type flags
        pub const is_numeric = true;
        pub const is_rational = true;
        pub const is_real = true;
        pub const is_signed = true;

        pub const Numerator = std.meta.Int(.signed, bits);
        pub const Denominator = std.meta.Int(.unsigned, bits);

        // fn init(anytype): init from any numeric type
        // fn parse([]const u8): init from string
    };
}
