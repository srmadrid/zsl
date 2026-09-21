pub const meta = @import("meta.zig");

pub const Dyadic = @import("numeric/dyadic.zig").Dyadic;
pub const Complex = @import("numeric/complex.zig").Complex;
pub const cf16 = @import("numeric/complex.zig").cf16;
pub const cf32 = @import("numeric/complex.zig").cf32;
pub const cf64 = @import("numeric/complex.zig").cf64;
pub const cf80 = @import("numeric/complex.zig").cf80;
pub const cf128 = @import("numeric/complex.zig").cf128;
pub const comptime_complex = @import("numeric/complex.zig").comptime_complex;

// Domain namespaces
pub const numeric = @import("numeric.zig");
pub const vector = @import("vector.zig");
pub const matrix = @import("matrix.zig");
pub const array = @import("array.zig");
pub const poly = @import("poly.zig");

// Module namespaces
pub const stats = @import("stats.zig");
pub const linalg = @import("linalg.zig");
// numdiff
pub const autodiff = @import("autodiff.zig");
// numint
// signal
// optim
// root
// interp

// Miscellaneous
pub const thread = @import("thread.zig");
