//! Namespace for vector types and operations.

pub const Static = @import("vector/static.zig").Static;
pub const Dense = @import("vector/dense.zig").Dense;
pub const Sparse = @import("vector/sparse.zig").Sparse;

pub const Add = @import("vector/ops.zig").Add;
pub const add = @import("vector/ops.zig").add;
pub const addUnchecked = @import("vector/ops.zig").addUnchecked;
pub const addAlloc = @import("vector/ops.zig").addAlloc;
pub const addInto = @import("vector/ops.zig").addInto;
pub const addIntoUnchecked = @import("vector/ops.zig").addIntoUnchecked;
pub const Sub = @import("vector/ops.zig").Sub;
pub const sub = @import("vector/ops.zig").sub;
pub const subUnchecked = @import("vector/ops.zig").subUnchecked;
pub const subAlloc = @import("vector/ops.zig").subAlloc;
pub const subInto = @import("vector/ops.zig").subInto;
pub const subIntoUnchecked = @import("vector/ops.zig").subIntoUnchecked;
pub const Mul = @import("vector/ops.zig").Mul;
pub const mul = @import("vector/ops.zig").mul;
pub const mulAlloc = @import("vector/ops.zig").mulAlloc;
pub const mulInto = @import("vector/ops.zig").mulInto;
pub const mulIntoUnchecked = @import("vector/ops.zig").mulIntoUnchecked;
pub const Div = @import("vector/ops.zig").Div;
pub const div = @import("vector/ops.zig").div;
pub const divAlloc = @import("vector/ops.zig").divAlloc;
pub const divInto = @import("vector/ops.zig").divInto;
pub const divIntoUnchecked = @import("vector/ops.zig").divIntoUnchecked;

pub const Error = error{
    ZeroLength,
    PositionOutOfBounds,
    DimensionMismatch,
    NonContiguousData,
    ZeroDimension,
    DataNotOwned,
    InsufficientSpace,
};

pub const Flags = packed struct {
    owns_data: bool = true,
    noconj: bool = true,
};
