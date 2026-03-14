//! Namespace for vector types and operations.

const dense = @import("vector/dense.zig");
pub const Dense = dense.Dense;
const sparse = @import("vector/sparse.zig");
pub const Sparse = sparse.Sparse;

const vecops = @import("vector/ops.zig");
pub const Apply2 = vecops.Apply2;
pub const apply2 = vecops.apply2;

pub const add = vecops.add;
pub const sub = vecops.sub;
pub const mul = vecops.mul;
pub const div = vecops.div;

pub const Error = error{
    ZeroLength,
    PositionOutOfBounds,
    DimensionMismatch,
    NonContiguousData,
    ZeroDimension,
    DataNotOwned,
};

pub const Flags = packed struct {
    owns_data: bool = true,
};
