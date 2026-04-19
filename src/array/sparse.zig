const std = @import("std");

const meta = @import("../meta.zig");
const Scalar = meta.Scalar;
const ReturnType1 = meta.ReturnType1;
const ReturnType2 = meta.ReturnType2;
const scast = meta.scast;
const cast = meta.cast;
const validateContext = meta.validateContext;

const numeric = @import("../numeric.zig");
const int = @import("../int.zig");

const array = @import("../array.zig");
const max_dimensions = array.max_dimensions;
const Order = meta.Layout;
const Flags = array.Flags;
const Range = array.Range;

const dense = @import("dense.zig");
const Dense = dense.Dense;

pub fn Sparse(T: type, order: Order) type {
    if (!meta.isNumeric(T))
        @compileError("Strided requires a numeric type, got " ++ @typeName(T));

    return struct {
        nnz: usize,

        /// Type signatures
        pub const is_array = {};
        pub const is_sparse = {};

        /// Numeric type
        pub const Numeric = T;

        pub const empty: Dense(T, order) = .{
            .nnz = 0,
        };
    };
}
