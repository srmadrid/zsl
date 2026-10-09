//! Namespace for polynomial types and operations.

pub const Static = @import("poly/static.zig").Static;
pub const Dense = @import("poly/dense.zig").Dense;
pub const Sparse = @import("poly/sparse.zig").Sparse;

// pub const Add = @import("poly/ops.zig").Add;
// pub const add = @import("poly/ops.zig").add;
// pub const addUnchecked = @import("poly/ops.zig").addUnchecked;
// pub const addAlloc = @import("poly/ops.zig").addAlloc;
// pub const addInto = @import("poly/ops.zig").addInto;
// pub const addIntoUnchecked = @import("poly/ops.zig").addIntoUnchecked;
// pub const Sub = @import("poly/ops.zig").Sub;
// pub const sub = @import("poly/ops.zig").sub;
// pub const subUnchecked = @import("poly/ops.zig").subUnchecked;
// pub const subAlloc = @import("poly/ops.zig").subAlloc;
// pub const subInto = @import("poly/ops.zig").subInto;
// pub const subIntoUnchecked = @import("poly/ops.zig").subIntoUnchecked;
// pub const Mul = @import("poly/ops.zig").Mul;
// pub const mul = @import("poly/ops.zig").mul;
// pub const mulAlloc = @import("poly/ops.zig").mulAlloc;
// pub const mulInto = @import("poly/ops.zig").mulInto;
// pub const mulIntoUnchecked = @import("poly/ops.zig").mulIntoUnchecked;
// pub const Div = @import("poly/ops.zig").Div;
// pub const div = @import("poly/ops.zig").div;
// pub const divAlloc = @import("poly/ops.zig").divAlloc;
// pub const divInto = @import("poly/ops.zig").divInto;
// pub const divIntoUnchecked = @import("poly/ops.zig").divIntoUnchecked;

pub const Error = error{
    PositionOutOfBounds,
    DimensionMismatch,
    ZeroLength,
    DataNotOwned,
};

pub const Flags = packed struct {
    owns_data: bool = true,
};
