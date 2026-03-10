pub const types = @import("types.zig");
pub const cast = types.cast;
pub const Cmp = types.Cmp;
pub const Layout = types.Layout;
pub const Uplo = types.Uplo;
pub const Diag = types.Diag;
pub const IterationOrder = types.IterationOrder;

pub const int = @import("int.zig");
pub const rational = @import("rational.zig");
pub const Rational = rational.Rational;
pub const float = @import("float.zig");
pub const dyadic = @import("dyadic.zig");
pub const Dyadic = dyadic.Dyadic;
pub const complex = @import("complex.zig");
pub const Complex = complex.Complex;
pub const cf16 = complex.cf16;
pub const cf32 = complex.cf32;
pub const cf64 = complex.cf64;
pub const cf80 = complex.cf80;
pub const cf128 = complex.cf128;
pub const comptime_ccomplex = complex.comptime_complex;

// Domain namespaces
pub const numeric = @import("numeric.zig");
pub const vector = @import("vector.zig");
pub const matrix = @import("matrix.zig");
pub const array = @import("array.zig");

pub const linalg = @import("linalg.zig");
pub const autodiff = @import("autodiff.zig");

// Symbolic system.
//pub const Expression = @import("expression/expression.zig").Expression;
//pub const Symbol = @import("symbol.zig").Symbol;
//pub const Element = @import("element.zig").Element;
//pub const Variable = @import("variable.zig").Variable;
//pub const Set = @import("set.zig").Set;
