//! Namespace for int operations.

// Utilities
pub const Coerce = @import("int/coerce.zig").Coerce;
pub const bitSize = @import("int/bitSize.zig").bitSize;

// Constants
pub const highest = @import("int/highest.zig").highest;
pub const lowest = @import("int/lowest.zig").lowest;
pub const smallest = @import("int/smallest.zig").smallest;
pub const eps = @import("int/eps.zig").eps;

// Basic operations
pub const abs = @import("int/abs.zig").abs;
pub const sign = @import("int/sign.zig").sign;

// Arithmetic operations
pub const Add = @import("int/add.zig").Add;
pub const add = @import("int/add.zig").add;
pub const Sub = @import("int/sub.zig").Sub;
pub const sub = @import("int/sub.zig").sub;
pub const Mul = @import("int/mul.zig").Mul;
pub const mul = @import("int/mul.zig").mul;
pub const Div = @import("int/div.zig").Div;
pub const div = @import("int/div.zig").div;

// Comparison operations
pub const order = @import("int/order.zig").order;
pub const eq = @import("int/eq.zig").eq;
pub const ne = @import("int/ne.zig").ne;
pub const lt = @import("int/lt.zig").lt;
pub const le = @import("int/le.zig").le;
pub const gt = @import("int/gt.zig").gt;
pub const ge = @import("int/ge.zig").ge;
pub const Max = @import("int/max.zig").Max;
pub const max = @import("int/max.zig").max;
pub const Min = @import("int/min.zig").Min;
pub const min = @import("int/min.zig").min;

// Power functions
pub const Pow = @import("int/pow.zig").Pow;
pub const pow = @import("int/pow.zig").pow;
