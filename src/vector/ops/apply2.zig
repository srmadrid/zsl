const std = @import("std");

const types = @import("../../types.zig");

const dense = @import("../dense.zig");
const sparse = @import("../sparse.zig");

pub fn Apply2(comptime X: type, comptime Y: type, comptime op: anytype) type {
    const Op = @TypeOf(op);
    const opinfo = @typeInfo(Op);

    comptime if ((!types.isVector(X) and !types.isNumeric(X)) or (!types.isVector(Y) and !types.isNumeric(Y)) or
        (!types.isVector(X) and !types.isVector(Y)) or
        opinfo != .@"fn" or opinfo.@"fn".params.len != 2)
        @compileError("zsl.vector.apply2: at least one of x or y must be a vector, the other must be a vector or a numeric, and op must be a function of two arguments, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top: " ++ @typeName(Op) ++ "\n");

    comptime var R = types.ReturnTypeFromInputs(op, &.{ types.Numeric(X), types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    comptime if (!types.isNumeric(R))
        @compileError("zsl.vector.apply2: calling op with arguments of types X and Y must return a numeric, got\n\tR = " ++ @typeName(R) ++ "\n");

    const xv_type = types.vectorType(X);
    const yv_type = types.vectorType(Y);
    switch (comptime xv_type) {
        .dense => switch (comptime yv_type) {
            .dense => return EnsureVector(.dense, R),
            .sparse => return EnsureVector(.dense, R),
            .custom => return EnsureVector(.custom, R), // Obviously wont work
            .numeric => return EnsureVector(.dense, R),
        },
        .sparse => switch (comptime yv_type) {
            .dense => return EnsureVector(.dense, R),
            .sparse => return EnsureVector(.sparse, R),
            .custom => return EnsureVector(.custom, R), // Wont work
            .numeric => return EnsureVector(.sparse, R),
        },
        .custom => return EnsureVector(.custom, R), // Wont work
        .numeric => switch (comptime yv_type) {
            .dense => return EnsureVector(.dense, R),
            .sparse => return EnsureVector(.sparse, R),
            .custom => return EnsureVector(.custom, R), // Wont work
            .numeric => unreachable,
        },
    }
}

/// Applies a binary operation element-wise between two vectors, or between a
/// vector and a scalar, handling all combinations of dense and sparse vectors.
///
/// Signature
/// ---------
/// ```zig
/// fn apply2(x: X, y: Y, ctx: anytype) !EnsureVector(Coerce(X, Y), ReturnType2(op, Numeric(X), Numeric(Y)))
/// ```
///
/// Parameters
/// ----------
/// `x` (`anytype`):
/// The left operand.
///
/// `y` (`anytype`):
/// The right operand.
///
/// `op` (`anytype`):
/// A function that takes two arguments (the elements from `x` and `y`), or
/// three arguments if a context is needed (the context is passed as the third
/// argument).
///
/// `ctx` (`anytype`):
/// A context struct providing necessary resources and configuration for the
/// operation. This function only performs partial validation of the context;
/// the specific requirements depend on the operation being performed. If the
/// context is missing required fields, the compiler will emit a detailed error
/// message describing the expected structure.
///
/// Returns
/// -------
/// `EnsureVector(Coerce(@TypeOf(x), @TypeOf(y)), ReturnType2(op, Numeric(@TypeOf(x)), Numeric(@TypeOf(y))))`:
/// The result of the operation. If both operands are sparse, or one operand is
/// sparse and the other is a scalar, the result is sparse. Otherwise, the
/// result is dense.
///
/// Errors
/// ------
/// `std.mem.Allocator.Error.OutOfMemory`:
/// If memory allocation fails.
///
/// `vector.Error.DimensionMismatch`:
/// If the two vectors do not have the same length. Can only happen if both
/// operands are vectors.
///
/// Notes
/// -----
/// If both operands are sparse vectors, or one operand is a sparse vector and
/// the other is a scalar, the operation is only applied to the indices where at
/// least one of the vectors, has a non-zero element, i.e., it is assumed that
/// `op(0, 0) == 0`, `op(scalar, 0) == 0`, and `op(0, scalar) == 0`.
pub fn apply2(
    allocator: std.mem.Allocator,
    x: anytype,
    y: anytype,
    comptime op: anytype,
    ctx: anytype,
) !EnsureVector(Coerce(@TypeOf(x), @TypeOf(y)), ReturnType2(op, Numeric(@TypeOf(x)), Numeric(@TypeOf(y)))) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = ReturnType2(op, types.Numeric(X), types.Numeric(Y));

    comptime if (!types.isVector(X) and !types.isVector(Y))
        @compileError("vector.apply2: at least one of x or y must be a vector, got " ++
            @typeName(X) ++ " and " ++ @typeName(Y));

    comptime if (@typeInfo(@TypeOf(op)) != .@"fn" or (@typeInfo(@TypeOf(op)).@"fn".params.len != 2 and @typeInfo(@TypeOf(op)).@"fn".params.len != 3))
        @compileError("vector.apply2: op must be a function of two arguments, or a function of three arguments with the third argument being a context, got " ++ @typeName(@TypeOf(op)));

    comptime switch (types.numericType(types.Numeric(R))) {
        .bool => @compileError("vector.add not defined for " ++ @typeName(X) ++ " and " ++ @typeName(Y)),
        .int, .float, .cfloat => {
            types.partialValidateContext(@TypeOf(ctx), .{});
        },
        .integer, .rational, .real, .complex => {
            types.partialValidateContext(
                @TypeOf(ctx),
                .{
                    .allocator = .{ .type = std.mem.Allocator, .required = true },
                },
            );
        },
    };

    if (comptime !types.isVector(X)) {
        switch (comptime types.vectorType(Y)) {
            .dense => return dense.apply2(allocator, x, y, op, ctx),
            .sparse => return sparse.apply2(allocator, x, y, op, ctx),
            .numeric => unreachable,
        }
    } else if (comptime !types.isVector(Y)) {
        switch (comptime types.vectorType(X)) {
            .dense => return dense.apply2(allocator, x, y, op, ctx),
            .sparse => return sparse.apply2(allocator, x, y, op, ctx),
            .numeric => unreachable,
        }
    } else {
        switch (comptime types.vectorType(X)) {
            .dense => switch (comptime types.vectorType(Y)) {
                .dense => return dense.apply2(allocator, x, y, op, ctx),
                .sparse => return @import("apply2/desp.zig").apply2(allocator, x, y, op, ctx),
                .numeric => unreachable,
            },
            .sparse => switch (comptime types.vectorType(Y)) {
                .dense => return @import("apply2/spde.zig").apply2(allocator, x, y, op, ctx),
                .sparse => return sparse.apply2(allocator, x, y, op, ctx),
                .numeric => unreachable,
            },
            .numeric => unreachable,
        }
    }
}
