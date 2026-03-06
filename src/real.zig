//! Namespace for real operations.

const std = @import("std");
const Rational = @import("rational.zig").Rational;

pub const Real = struct {
    rational: Rational,
    //irrationals: []Irrational, Maybe istead hold something like struct { irrational: Irrational, multiplicity: i32 }, with for instance, .{pi, -2} means \pi^{-2}

    /// Type flags
    pub const zml_is_numeric = true;
    pub const zml_is_real = true;
    pub const zml_is_real_type = true;
    pub const zml_is_signed = true;
    pub const zml_is_allocated = true;

    /// Operation flags
    pub const zml_has_simple_abs = true;
    pub const zml_has_simple_abs1 = true;
    pub const zml_has_simple_neg = true;
    pub const zml_has_simple_re = true;
    pub const zml_has_simple_im = true;
    pub const zml_has_simple_conj = true;
    pub const zml_has_simple_sign = true;

    pub const empty: Real = .{
        .rational = .empty,
    };
};
