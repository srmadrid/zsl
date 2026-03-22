//! Namespace for SIMD utilities.

// Bbase length means length of data inputted, for instance 4 complexes, and
// vector length is the length of the simd vector, equal to the base length for
// real types, twice the base length for complex types.

const std = @import("std");
const options = @import("options");

const types = @import("types.zig");
const numeric = @import("numeric.zig");

const int = @import("int.zig");
const float = @import("float.zig");
const complex = @import("complex.zig");

pub fn suggestBaseLength(comptime N: type) ?comptime_int {
    comptime if (!types.isNumeric(N))
        @compileError("zsl.simd.suggestBaseLength: N must be a numeric type, got\n\tN = " ++ @typeName(N) ++ "\n");

    switch (comptime types.numericType(N)) {
        .bool, .int, .float => return std.simd.suggestVectorLength(N),
        .dyadic => return null,
        .complex => {
            return if (comptime types.numericType(types.Scalar(N)) == .float)
                return std.simd.suggestVectorLength(types.Scalar(N)).? / 2
            else
                null;
        },
        .custom => return null,
    }
}

fn baseToVectorLen(comptime N: type, comptime base_len: comptime_int) comptime_int {
    return base_len * if (comptime types.isComplex(N)) 2 else 1;
}

fn vectorToBaseLen(comptime N: type, comptime base_len: comptime_int) comptime_int {
    return base_len / if (comptime types.isComplex(N)) 2 else 1;
}

/// Makes the mask `.{ 0, -1, 1, -2, ..., base_len - 1, -base_len }`.
inline fn maskZip(comptime base_len: comptime_int) [base_len * 2]i32 {
    comptime var mask: @Vector(base_len * 2, i32) = undefined;
    inline for (0..base_len) |i| {
        mask[i * 2] = @intCast(i);
        mask[i * 2 + 1] = -@as(i32, @intCast(i)) - 1;
    }
    return mask;
}

/// Makes the mask `.{ 0, 2, 4, ..., (base_len - 1) * 2 }` to extract the real
/// parts of a complex vector using `@shuffle` with `undefined` as the second
/// vector.
inline fn maskReals(comptime base_len: comptime_int) @Vector(base_len, i32) {
    comptime var mask: @Vector(base_len, i32) = undefined;
    inline for (0..base_len) |i| {
        mask[i] = @intCast(i * 2);
    }
    return mask;
}

/// Makes the mask `.{ 1, 3, 5, ...,  (base_len - 1) * 2 + 1}` to extract the
/// imaginary parts of a complex vector using `@shuffle` with `undefined` as the
/// second vector.
inline fn maskIms(comptime base_len: comptime_int) @Vector(base_len, i32) {
    comptime var mask: @Vector(base_len, i32) = undefined;
    inline for (0..base_len) |i| {
        mask[i] = @intCast(i * 2 + 1);
    }
    return mask;
}

/// Makes the mask `.{ 0, -1, 1, -1, ..., base_len - 1, -1 }` to convert a real
/// vector to a complex one using `@shuffle` and `.{0}`, or equivalent, as the
/// second vector.
inline fn maskScalarToComplex(comptime base_len: comptime_int) @Vector(base_len * 2, i32) {
    comptime var mask: @Vector(base_len * 2, i32) = undefined;
    inline for (0..base_len) |i| {
        mask[i * 2] = @intCast(i);
        mask[i * 2 + 1] = -1;
    }
    return mask;
}

/// Makes the mask `.{ 0, 0, 1, 1, ... }`.
inline fn maskDupScalar(comptime base_len: comptime_int) @Vector(base_len * 2, i32) {
    comptime var mask: @Vector(base_len * 2, i32) = undefined;
    inline for (0..base_len) |i| {
        mask[i * 2] = @intCast(i);
        mask[i * 2 + 1] = @intCast(i);
    }
    return mask;
}

/// Makes the mask `.{ 0, 0, 2, 2, 4, 4, ..., (base_len - 1) * 2, (base_len - 1) * 2 }`
/// to duplicate the real parts of a complex vector using `@shuffle` with
/// `undefined` as the second vector, i.e., to obtain
/// `.{ x[0].re, x[0].re, x[1].re, x[1].re, ... }`.
inline fn maskDupReals(comptime base_len: comptime_int) @Vector(base_len * 2, i32) {
    comptime var mask: @Vector(base_len * 2, i32) = undefined;
    inline for (0..base_len) |i| {
        mask[i * 2] = @intCast(i * 2);
        mask[i * 2 + 1] = @intCast(i * 2);
    }
    return mask;
}

/// Makes the mask `.{ 1, 1, 3, 3, 5, 5, ..., (base_len - 1) * 2 + 1, (base_len - 1) * 2 + 1 }`
/// to duplicate the imaginary parts of a complex vector using `@shuffle` with
/// `undefined` as the second vector, i.e., to obtain
/// `.{ x[0].im, x[0].im, x[1].im, x[1].im, ... }`.
inline fn maskDupIms(comptime base_len: comptime_int) @Vector(base_len * 2, i32) {
    comptime var mask: @Vector(base_len * 2, i32) = undefined;
    inline for (0..base_len) |i| {
        mask[i * 2] = @intCast(i * 2 + 1);
        mask[i * 2 + 1] = @intCast(i * 2 + 1);
    }
    return mask;
}

/// Makes the mask `.{ 1, 0, 3, 2, 5, 4, ..., (base_len - 1) * 2 + 1, (base_len - 1) * 2 }`
/// to swap the real and imaginary parts of a complex vector using `@shuffle`
/// with `undefined` as the second vector, i.e., to obtain
/// `.{ x[0].im, x[0].re, x[1].im, x[1].re, ... }`.
inline fn maskSwapComplex(comptime base_len: comptime_int) @Vector(base_len * 2, i32) {
    comptime var mask: @Vector(base_len * 2, i32) = undefined;
    inline for (0..base_len) |i| {
        mask[i * 2] = @intCast(i * 2 + 1);
        mask[i * 2 + 1] = @intCast(i * 2);
    }
    return mask;
}

/// Makes the mask `.{ -1.0, 1.0, -1.0, 1.0, ... }` to negate the real parts of
/// a complex vector before addition, effectively emulating an ADDSUB
/// instruction for complex multiplication.
inline fn maskAddSub(comptime N: type, comptime base_len: comptime_int) @Vector(base_len * 2, types.Scalar(N)) {
    comptime var mask: @Vector(base_len * 2, types.Scalar(N)) = undefined;
    inline for (0..base_len) |i| {
        mask[i * 2] = -1.0;
        mask[i * 2 + 1] = 1.0;
    }
    return mask;
}

/// Makes the mask `.{ 1.0, -1.0, 1.0, -1.0, ... }` to conjugate the elements of
/// a complex vector for division.
inline fn maskConjugate(comptime N: type, comptime base_len: comptime_int) @Vector(base_len * 2, types.Scalar(N)) {
    comptime var mask: @Vector(base_len * 2, types.Scalar(N)) = undefined;
    inline for (0..base_len) |i| {
        mask[i * 2] = 1.0;
        mask[i * 2 + 1] = -1.0;
    }
    return mask;
}

inline fn broadcast(comptime base_len: comptime_int, value: anytype) @Vector(baseToVectorLen(@TypeOf(value), base_len), types.Scalar(@TypeOf(value))) {
    if (comptime types.isComplex(@TypeOf(value))) {
        var r: @Vector(2 * base_len, types.Scalar(@TypeOf(value))) = undefined;

        comptime var i = 0;
        inline while (i < base_len * 2) : (i += 2) {
            r[i] = value.re;
            r[i + 1] = value.im;
        }
        return r;
    } else {
        return @splat(value);
    }
}

inline fn castVector(comptime N: type, comptime V: type, comptime base_len: comptime_int, vector: @Vector(baseToVectorLen(V, base_len), types.Scalar(V))) @Vector(baseToVectorLen(N, base_len), types.Scalar(N)) {
    switch (comptime types.numericType(V)) {
        .bool => switch (comptime types.numericType(N)) {
            .bool => return vector,
            .int => return @intFromBool(vector),
            .float => return @floatFromInt(@intFromBool(vector)),
            .dyadic => unreachable,
            .complex => return @shuffle(types.Scalar(N), @as(@Vector(base_len, types.Scalar(N)), @floatFromInt(@intFromBool(vector))), @Vector(1, types.Scalar(N)){0.0}, maskScalarToComplex(base_len)),
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(N)) {
            .bool => return vector != @as(@TypeOf(vector), @splat(0)),
            .int => return @intCast(vector),
            .float => return @floatFromInt(vector),
            .dyadic => unreachable,
            .complex => return @shuffle(types.Scalar(N), @as(@Vector(base_len, types.Scalar(N)), @floatFromInt(vector)), @Vector(1, types.Scalar(N)){0.0}, maskScalarToComplex(base_len)),
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(N)) {
            .bool => return vector != @as(@TypeOf(vector), @splat(0.0)),
            .int => return @intFromFloat(vector),
            .float => return @floatCast(vector),
            .dyadic => unreachable,
            .complex => return @shuffle(types.Scalar(N), @as(@Vector(base_len, types.Scalar(N)), @floatCast(vector)), @Vector(1, types.Scalar(N)){0.0}, maskScalarToComplex(base_len)),
            .custom => unreachable,
        },
        .dyadic => unreachable,
        .complex => switch (comptime types.numericType(N)) {
            .bool => return @shuffle(N, vector != @as(@TypeOf(vector), @splat(0.0)), undefined, maskReals(base_len)) |
                @shuffle(N, vector != @as(@TypeOf(vector), @splat(0.0)), undefined, maskIms(base_len)),
            .int => return @intFromFloat(@shuffle(types.Scalar(V), vector, undefined, maskReals(base_len))),
            .float => return @floatCast(@shuffle(types.Scalar(V), vector, undefined, maskReals(base_len))),
            .dyadic => unreachable,
            .complex => return @floatCast(vector),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

pub inline fn set(o: anytype, x: anytype, comptime base_len: comptime_int) void {
    const O: type = @TypeOf(o[0]);
    const X: type = if (comptime types.isManyItemPointer(@TypeOf(x))) @TypeOf(x[0]) else @TypeOf(x);

    const vo: [*]types.Scalar(O) = @ptrCast(o);
    const vx: @Vector(baseToVectorLen(X, base_len), types.Scalar(X)) = if (comptime types.isManyItemPointer(@TypeOf(x)))
        @as([*]const types.Scalar(X), @ptrCast(x))[0..baseToVectorLen(X, base_len)].*
    else
        broadcast(base_len, x);

    vo[0..baseToVectorLen(O, base_len)].* = castVector(O, X, base_len, vx);
}

/// Performs an inline SIMD addition of two contiguous arrays of numeric types
/// `x` and `y`, storing the result in `o`.
///
/// This is a low-level kernel. It operates directly on many-item pointers and
/// performs no bounds checking. The caller is responsible for ensuring that
/// the memory is accessible for the given vector length.
///
/// ## Signature
/// ```zig
/// simd.add_(o: [*]O, x: [*]X, y: [*]Y, comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.add_(o: [*]O, x: X, y: [*]Y, comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.add_(o: [*]O, x: [*]X, y: Y, comptime base_len: comptime_int) void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): Pointer to the output operand data.
/// * `x` (`anytype`): Pointer to the left operand data.
/// * `y` (`anytype`): Pointer to the right operand data.
/// * `base_len` (`comptime comptime_int`): The base length of the input data.
///
/// ## Returns
/// `void`
pub inline fn add_(o: anytype, x: anytype, y: anytype, comptime base_len: comptime_int) void {
    const O: type = @TypeOf(o[0]);
    const X: type = if (comptime types.isManyItemPointer(@TypeOf(x))) @TypeOf(x[0]) else @TypeOf(x);
    const Y: type = if (comptime types.isManyItemPointer(@TypeOf(y))) @TypeOf(y[0]) else @TypeOf(y);
    const R: type = numeric.Add(X, Y);

    const vo: [*]types.Scalar(O) = @ptrCast(o);
    const vx: @Vector(baseToVectorLen(X, base_len), types.Scalar(X)) = if (comptime types.isManyItemPointer(@TypeOf(x)))
        @as([*]const types.Scalar(X), @ptrCast(x))[0..baseToVectorLen(X, base_len)].*
    else
        broadcast(base_len, x);
    const vy: @Vector(baseToVectorLen(Y, base_len), types.Scalar(Y)) = if (comptime types.isManyItemPointer(@TypeOf(y)))
        @as([*]const types.Scalar(Y), @ptrCast(y))[0..baseToVectorLen(Y, base_len)].*
    else
        broadcast(base_len, y);

    switch (comptime types.numericType(O)) {
        .bool, .int, .float => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => @compileError("zsl.simd.add_: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "\n"),
                .int => switch (comptime options.int_mode) {
                    .default => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                    .wrap => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) +% castVector(R, Y, base_len, vy)),
                    .saturate => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) +| castVector(R, Y, base_len, vy)),
                },
                .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) + castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Y)) {
                .bool, .int => switch (comptime options.int_mode) {
                    .default => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                    .wrap => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) +% castVector(R, Y, base_len, vy)),
                    .saturate => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) +| castVector(R, Y, base_len, vy)),
                },
                .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) + castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) + castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) + castVector(types.Scalar(R), Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) + castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .dyadic => unreachable,
        .complex => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => @compileError("zsl.simd.add: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "\n"),
                .int => switch (comptime options.int_mode) {
                    .default => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                    .wrap => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) +% castVector(R, Y, base_len, vy)),
                    .saturate => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) +| castVector(R, Y, base_len, vy)),
                },
                .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Y)) {
                .bool, .int => switch (comptime options.int_mode) {
                    .default => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                    .wrap => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) +% castVector(R, Y, base_len, vy)),
                    .saturate => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) +| castVector(R, Y, base_len, vy)),
                },
                .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) + castVector(R, Y, base_len, vy)),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs an inline SIMD subtraction of two contiguous arrays of numeric
/// types `x` and `y`, storing the result in `o`.
///
/// This is a low-level kernel. It operates directly on many-item pointers and
/// performs no bounds checking. The caller is responsible for ensuring that
/// the memory is accessible for the given vector length.
///
/// ## Signature
/// ```zig
/// simd.sub_(o: [*]O, x: [*]X, y: [*]Y, comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.sub_(o: [*]O, x: X, y: [*]Y, comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.sub_(o: [*]O, x: [*]X, y: Y, comptime base_len: comptime_int) void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): Pointer to the output operand data.
/// * `x` (`anytype`): Pointer to the left operand data.
/// * `y` (`anytype`): Pointer to the right operand data.
/// * `base_len` (`comptime comptime_int`): The base length of the input data.
///
/// ## Returns
/// `void`
pub inline fn sub_(o: anytype, x: anytype, y: anytype, comptime base_len: comptime_int) void {
    const O: type = @TypeOf(o[0]);
    const X: type = if (comptime types.isManyItemPointer(@TypeOf(x))) @TypeOf(x[0]) else @TypeOf(x);
    const Y: type = if (comptime types.isManyItemPointer(@TypeOf(y))) @TypeOf(y[0]) else @TypeOf(y);
    const R: type = numeric.Sub(X, Y);

    const vo: [*]types.Scalar(O) = @ptrCast(o);
    const vx: @Vector(baseToVectorLen(X, base_len), types.Scalar(X)) = if (comptime types.isManyItemPointer(@TypeOf(x)))
        @as([*]const types.Scalar(X), @ptrCast(x))[0..baseToVectorLen(X, base_len)].*
    else
        broadcast(base_len, x);
    const vy: @Vector(baseToVectorLen(Y, base_len), types.Scalar(Y)) = if (comptime types.isManyItemPointer(@TypeOf(y)))
        @as([*]const types.Scalar(Y), @ptrCast(y))[0..baseToVectorLen(Y, base_len)].*
    else
        broadcast(base_len, y);

    switch (comptime types.numericType(O)) {
        .bool, .int, .float => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => @compileError("zsl.simd.sub_: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "\n"),
                .int => switch (comptime options.int_mode) {
                    .default => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                    .wrap => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) -% castVector(R, Y, base_len, vy)),
                    .saturate => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) -| castVector(R, Y, base_len, vy)),
                },
                .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) - castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Y)) {
                .bool, .int => switch (comptime options.int_mode) {
                    .default => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                    .wrap => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) -% castVector(R, Y, base_len, vy)),
                    .saturate => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) -| castVector(R, Y, base_len, vy)),
                },
                .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) - castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) - castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) - castVector(types.Scalar(R), Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) - castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .dyadic => unreachable,
        .complex => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => @compileError("zsl.simd.sub: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "\n"),
                .int => switch (comptime options.int_mode) {
                    .default => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                    .wrap => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) -% castVector(R, Y, base_len, vy)),
                    .saturate => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) -| castVector(R, Y, base_len, vy)),
                },
                .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Y)) {
                .bool, .int => switch (comptime options.int_mode) {
                    .default => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                    .wrap => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) -% castVector(R, Y, base_len, vy)),
                    .saturate => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) -| castVector(R, Y, base_len, vy)),
                },
                .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) - castVector(R, Y, base_len, vy)),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs an inline SIMD multiplication of two contiguous arrays of numeric
/// types `x` and `y`, storing the result in `o`.
///
/// This is a low-level kernel. It operates directly on many-item pointers and
/// performs no bounds checking. The caller is responsible for ensuring that
/// the memory is accessible for the given vector length.
///
/// ## Signature
/// ```zig
/// simd.mul_(o: [*]O, x: [*]X, y: [*]Y, comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.mul_(o: [*]O, x: X, y: [*]Y, comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.mul_(o: [*]O, x: [*]X, y: Y, comptime base_len: comptime_int) void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): Pointer to the output operand data.
/// * `x` (`anytype`): Pointer to the left operand data.
/// * `y` (`anytype`): Pointer to the right operand data.
/// * `base_len` (`comptime comptime_int`): The base length of the input data.
///
/// ## Returns
/// `void`
pub inline fn mul_(o: anytype, x: anytype, y: anytype, comptime base_len: comptime_int) void {
    const O: type = @TypeOf(o[0]);
    const X: type = if (comptime types.isManyItemPointer(@TypeOf(x))) @TypeOf(x[0]) else @TypeOf(x);
    const Y: type = if (comptime types.isManyItemPointer(@TypeOf(y))) @TypeOf(y[0]) else @TypeOf(y);
    const R: type = numeric.Mul(X, Y);

    const vo: [*]types.Scalar(O) = @ptrCast(o);
    const vx: @Vector(baseToVectorLen(X, base_len), types.Scalar(X)) = if (comptime types.isManyItemPointer(@TypeOf(x)))
        @as([*]const types.Scalar(X), @ptrCast(x))[0..baseToVectorLen(X, base_len)].*
    else
        broadcast(base_len, x);
    const vy: @Vector(baseToVectorLen(Y, base_len), types.Scalar(Y)) = if (comptime types.isManyItemPointer(@TypeOf(y)))
        @as([*]const types.Scalar(Y), @ptrCast(y))[0..baseToVectorLen(Y, base_len)].*
    else
        broadcast(base_len, y);

    switch (comptime types.numericType(O)) {
        .bool, .int, .float => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => @compileError("zsl.simd.mul_: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "\n"),
                .int => switch (comptime options.int_mode) {
                    .default => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                    .wrap => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy)),
                    .saturate => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy)),
                },
                .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) * castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Y)) {
                .bool, .int => switch (comptime options.int_mode) {
                    .default => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                    .wrap => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy)),
                    .saturate => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy)),
                },
                .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) * castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) * castVector(types.Scalar(R), Y, base_len, vy)),
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) * castVector(types.Scalar(R), Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => {
                    const vx_casted = castVector(R, X, base_len, vx);
                    const vy_casted = castVector(R, Y, base_len, vy);

                    const a = @shuffle(types.Scalar(R), vx_casted, undefined, maskReals(base_len));
                    const b = @shuffle(types.Scalar(R), vx_casted, undefined, maskIms(base_len));
                    const c = @shuffle(types.Scalar(R), vy_casted, undefined, maskReals(base_len));
                    const d = @shuffle(types.Scalar(R), vy_casted, undefined, maskIms(base_len));

                    o[0..base_len].* = castVector(O, types.Scalar(R), base_len, (a * c) - (b * d));
                },
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .dyadic => unreachable,
        .complex => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => @compileError("zsl.simd.mul: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "\n"),
                .int => switch (comptime options.int_mode) {
                    .default => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                    .wrap => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy)),
                    .saturate => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy)),
                },
                .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => {
                    const vx_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), X, base_len, vx), undefined, maskDupScalar(base_len));
                    const vy_casted = castVector(R, Y, base_len, vy);

                    vo[0 .. base_len * 2].* = castVector(O, R, base_len, vx_dup * vy_casted);
                },
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Y)) {
                .bool, .int => switch (comptime options.int_mode) {
                    .default => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                    .wrap => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy)),
                    .saturate => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy)),
                },
                .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => {
                    const vx_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), X, base_len, vx), undefined, maskDupScalar(base_len));
                    const vy_casted = castVector(R, Y, base_len, vy);

                    vo[0 .. base_len * 2].* = castVector(O, R, base_len, vx_dup * vy_casted);
                },
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => {
                    const vx_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), X, base_len, vx), undefined, maskDupScalar(base_len));
                    const vy_casted = castVector(R, Y, base_len, vy);

                    vo[0 .. base_len * 2].* = castVector(O, R, base_len, vx_dup * vy_casted);
                },
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => {
                    const vx_c = castVector(R, X, base_len, vx);
                    const vy_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), Y, base_len, vy), undefined, maskDupScalar(base_len));

                    vo[0 .. base_len * 2].* = castVector(O, R, base_len, vx_c * vy_dup);
                },
                .dyadic => unreachable,
                .complex => {
                    const vx_casted = castVector(R, X, base_len, vx);
                    const vy_casted = castVector(R, Y, base_len, vy);

                    const vx_swap = @shuffle(types.Scalar(R), vx_casted, undefined, maskSwapComplex(base_len));
                    const vy_reals = @shuffle(types.Scalar(R), vy_casted, undefined, maskDupReals(base_len));
                    const vy_ims = @shuffle(types.Scalar(R), vy_casted, undefined, maskDupIms(base_len));

                    vo[0 .. base_len * 2].* = castVector(O, R, base_len, (vx_casted * vy_reals) + (vx_swap * (vy_ims * maskAddSub(R, base_len))));
                },
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs an inline SIMD fused multiplication and addition of three
/// contiguous arrays of numeric types `x`, `y` and `z`, `(x * y) + z`, storing
/// the result in `o`.
///
/// This is a low-level kernel. It operates directly on many-item pointers and
/// performs no bounds checking. The caller is responsible for ensuring that
/// the memory is accessible for the given vector length.
///
/// ## Signature
/// ```zig
/// simd.fma_(o: [*]O, x: [*]X, y: [*]Y, z: [*], comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.fma_(o: [*]O, x: X, y: [*]Y, z: [*], comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.fma_(o: [*]O, x: [*]X, y: Y, z: [*], comptime base_len: comptime_int) void
/// ```
/// or any combination where at least one of `x`, `y` and `z` is a many item
/// pointer.
///
/// ## Arguments
/// * `o` (`anytype`): Pointer to the output operand data.
/// * `x` (`anytype`): Pointer to the left multiplication operand data.
/// * `y` (`anytype`): Pointer to the right multiplication operand data.
/// * `z` (`anytype`): Pointer to the addition operand data.
/// * `base_len` (`comptime comptime_int`): The base length of the input data.
///
/// ## Returns
/// `void`
pub inline fn fma_(o: anytype, x: anytype, y: anytype, z: anytype, comptime base_len: comptime_int) void {
    const O: type = @TypeOf(o[0]);
    const X: type = if (comptime types.isManyItemPointer(@TypeOf(x))) @TypeOf(x[0]) else @TypeOf(x);
    const Y: type = if (comptime types.isManyItemPointer(@TypeOf(y))) @TypeOf(y[0]) else @TypeOf(y);
    const Z: type = if (comptime types.isManyItemPointer(@TypeOf(z))) @TypeOf(z[0]) else @TypeOf(z);
    const R: type = numeric.Fma(X, Y, Z);

    const vo: [*]types.Scalar(O) = @ptrCast(o);
    const vx: @Vector(baseToVectorLen(X, base_len), types.Scalar(X)) = if (comptime types.isManyItemPointer(@TypeOf(x)))
        @as([*]const types.Scalar(X), @ptrCast(x))[0..baseToVectorLen(X, base_len)].*
    else
        broadcast(base_len, x);
    const vy: @Vector(baseToVectorLen(Y, base_len), types.Scalar(Y)) = if (comptime types.isManyItemPointer(@TypeOf(y)))
        @as([*]const types.Scalar(Y), @ptrCast(y))[0..baseToVectorLen(Y, base_len)].*
    else
        broadcast(base_len, y);
    const vz: @Vector(baseToVectorLen(Z, base_len), types.Scalar(Z)) = if (comptime types.isManyItemPointer(@TypeOf(z)))
        @as([*]const types.Scalar(Z), @ptrCast(z))[0..baseToVectorLen(Z, base_len)].*
    else
        broadcast(base_len, z);

    switch (comptime types.numericType(O)) {
        .bool, .int, .float => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => switch (comptime types.numericType(Z)) {
                    .bool => @compileError("zsl.simd.fma_: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ " and " ++ @typeName(Z) ++ "\n"),
                    .int => switch (comptime options.int_mode) {
                        .default => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy) + castVector(R, Z, base_len, vz)),
                        .wrap => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy) +% castVector(R, Z, base_len, vz)),
                        .saturate => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy) +| castVector(R, Z, base_len, vz)),
                    },
                    .float => o[0..base_len].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .int => switch (comptime types.numericType(Z)) {
                    .bool, .int => switch (comptime options.int_mode) {
                        .default => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy) + castVector(R, Z, base_len, vz)),
                        .wrap => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy) +% castVector(R, Z, base_len, vz)),
                        .saturate => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy) +| castVector(R, Z, base_len, vz)),
                    },
                    .float => o[0..base_len].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .float => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => o[0..base_len].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .dyadic => unreachable,
                .complex => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Y)) {
                .bool, .int => switch (comptime types.numericType(Z)) {
                    .bool, .int => switch (comptime options.int_mode) {
                        .default => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy) + castVector(R, Z, base_len, vz)),
                        .wrap => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy) +% castVector(R, Z, base_len, vz)),
                        .saturate => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy) +| castVector(R, Z, base_len, vz)),
                    },
                    .float => o[0..base_len].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .float => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => o[0..base_len].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .dyadic => unreachable,
                .complex => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => o[0..base_len].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .dyadic => unreachable,
                .complex => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), castVector(types.Scalar(R), X, base_len, vx), castVector(types.Scalar(R), Y, base_len, vy), castVector(types.Scalar(R), Z, base_len, vz))),
                    .custom => unreachable,
                },
                .dyadic => unreachable,
                .complex => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => {
                        const vx_casted = castVector(R, X, base_len, vx);
                        const vy_casted = castVector(R, Y, base_len, vy);

                        const a = @shuffle(types.Scalar(R), vx_casted, undefined, maskReals(base_len));
                        const b = @shuffle(types.Scalar(R), vx_casted, undefined, maskIms(base_len));
                        const c = @shuffle(types.Scalar(R), vy_casted, undefined, maskReals(base_len));
                        const d = @shuffle(types.Scalar(R), vy_casted, undefined, maskIms(base_len));

                        const vz_casted = castVector(types.Scalar(R), Z, base_len, vz);

                        o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), -b, d, @mulAdd(@Vector(base_len, types.Scalar(R)), a, c, vz_casted)));
                    },
                    .dyadic => unreachable,
                    .complex => {
                        const vx_casted = castVector(R, X, base_len, vx);
                        const vy_casted = castVector(R, Y, base_len, vy);

                        const a = @shuffle(types.Scalar(R), vx_casted, undefined, maskReals(base_len));
                        const b = @shuffle(types.Scalar(R), vx_casted, undefined, maskIms(base_len));
                        const c = @shuffle(types.Scalar(R), vy_casted, undefined, maskReals(base_len));
                        const d = @shuffle(types.Scalar(R), vy_casted, undefined, maskIms(base_len));

                        const vz_re = @shuffle(types.Scalar(R), castVector(R, Z, base_len, vz), undefined, maskReals(base_len));

                        o[0..base_len].* = castVector(O, types.Scalar(R), base_len, @mulAdd(@Vector(base_len, types.Scalar(R)), -b, d, @mulAdd(@Vector(base_len, types.Scalar(R)), a, c, vz_re)));
                    },
                    .custom => unreachable,
                },
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .dyadic => unreachable,
        .complex => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => switch (comptime types.numericType(Z)) {
                    .bool => @compileError("zsl.simd.fma_: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ " and " ++ @typeName(Z) ++ "\n"),
                    .int => switch (comptime options.int_mode) {
                        .default => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy) + castVector(R, Z, base_len, vz)),
                        .wrap => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy) +% castVector(R, Z, base_len, vz)),
                        .saturate => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy) +| castVector(R, Z, base_len, vz)),
                    },
                    .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .custom => unreachable,
                },
                .int => switch (comptime types.numericType(Z)) {
                    .bool, .int => switch (comptime options.int_mode) {
                        .default => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy) + castVector(R, Z, base_len, vz)),
                        .wrap => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy) +% castVector(R, Z, base_len, vz)),
                        .saturate => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy) +| castVector(R, Z, base_len, vz)),
                    },
                    .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .custom => unreachable,
                },
                .float => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .custom => unreachable,
                },
                .dyadic => unreachable,
                .complex => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => {
                        const vx_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), X, base_len, vx), undefined, maskDupScalar(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_dup, castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz)));
                    },
                    .dyadic => unreachable,
                    .complex => {
                        const vx_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), X, base_len, vx), undefined, maskDupScalar(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_dup, castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz)));
                    },
                    .custom => unreachable,
                },
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Y)) {
                .bool, .int => switch (comptime types.numericType(Z)) {
                    .bool, .int => switch (comptime options.int_mode) {
                        .default => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) * castVector(R, Y, base_len, vy) + castVector(R, Z, base_len, vz)),
                        .wrap => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *% castVector(R, Y, base_len, vy) +% castVector(R, Z, base_len, vz)),
                        .saturate => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) *| castVector(R, Y, base_len, vy) +| castVector(R, Z, base_len, vz)),
                    },
                    .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .custom => unreachable,
                },
                .float => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .custom => unreachable,
                },
                .dyadic => unreachable,
                .complex => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => {
                        const vx_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), X, base_len, vx), undefined, maskDupScalar(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_dup, castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz)));
                    },
                    .dyadic => unreachable,
                    .complex => {
                        const vx_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), X, base_len, vx), undefined, maskDupScalar(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_dup, castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz)));
                    },
                    .custom => unreachable,
                },
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len, R), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .dyadic => unreachable,
                    .complex => vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), castVector(R, X, base_len, vx), castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz))),
                    .custom => unreachable,
                },
                .dyadic => unreachable,
                .complex => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => {
                        const vx_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), X, base_len, vx), undefined, maskDupScalar(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_dup, castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz)));
                    },
                    .dyadic => unreachable,
                    .complex => {
                        const vx_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), X, base_len, vx), undefined, maskDupScalar(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_dup, castVector(R, Y, base_len, vy), castVector(R, Z, base_len, vz)));
                    },
                    .custom => unreachable,
                },
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => {
                        const vy_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), Y, base_len, vy), undefined, maskDupScalar(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), castVector(R, X, base_len, vx), vy_dup, castVector(R, Z, base_len, vz)));
                    },
                    .dyadic => unreachable,
                    .complex => {
                        const vy_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), Y, base_len, vy), undefined, maskDupScalar(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), castVector(R, X, base_len, vx), vy_dup, castVector(R, Z, base_len, vz)));
                    },
                    .custom => unreachable,
                },
                .dyadic => unreachable,
                .complex => switch (comptime types.numericType(Z)) {
                    .bool, .int, .float => {
                        const vx_casted = castVector(R, X, base_len, vx);
                        const vy_casted = castVector(R, Y, base_len, vy);
                        const vz_casted = castVector(R, Z, base_len, vz);

                        const vx_swap = @shuffle(types.Scalar(R), vx_casted, undefined, maskSwapComplex(base_len));
                        const vy_reals = @shuffle(types.Scalar(R), vy_casted, undefined, maskDupReals(base_len));
                        const vy_ims = @shuffle(types.Scalar(R), vy_casted, undefined, maskDupIms(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_swap, vy_ims * maskAddSub(R, base_len), @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_casted, vy_reals, vz_casted)));
                    },
                    .dyadic => unreachable,
                    .complex => {
                        const vx_casted = castVector(R, X, base_len, vx);
                        const vy_casted = castVector(R, Y, base_len, vy);
                        const vz_casted = castVector(R, Z, base_len, vz);

                        const vx_swap = @shuffle(types.Scalar(R), vx_casted, undefined, maskSwapComplex(base_len));
                        const vy_reals = @shuffle(types.Scalar(R), vy_casted, undefined, maskDupReals(base_len));
                        const vy_ims = @shuffle(types.Scalar(R), vy_casted, undefined, maskDupIms(base_len));

                        vo[0 .. base_len * 2].* = castVector(O, R, base_len, @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_swap, vy_ims * maskAddSub(R, base_len), @mulAdd(@Vector(base_len * 2, types.Scalar(R)), vx_casted, vy_reals, vz_casted)));
                    },
                    .custom => unreachable,
                },
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs an inline SIMD division of two contiguous arrays of numeric types
/// `x` and `y`, storing the result in `o`.
///
/// This is a low-level kernel. It operates directly on many-item pointers and
/// performs no bounds checking. The caller is responsible for ensuring that
/// the memory is accessible for the given vector length.
///
/// ## Signature
/// ```zig
/// simd.div_(o: [*]O, x: [*]X, y: [*]Y, comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.div_(o: [*]O, x: X, y: [*]Y, comptime base_len: comptime_int) void
/// ```
/// or
/// ```zig
/// simd.div_(o: [*]O, x: [*]X, y: Y, comptime base_len: comptime_int) void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): Pointer to the output operand data.
/// * `x` (`anytype`): Pointer to the left operand data.
/// * `y` (`anytype`): Pointer to the right operand data.
/// * `base_len` (`comptime comptime_int`): The base length of the input data.
///
/// ## Returns
/// `void`
pub inline fn div_(o: anytype, x: anytype, y: anytype, comptime base_len: comptime_int) void {
    const O: type = @TypeOf(o[0]);
    const X: type = if (comptime types.isManyItemPointer(@TypeOf(x))) @TypeOf(x[0]) else @TypeOf(x);
    const Y: type = if (comptime types.isManyItemPointer(@TypeOf(y))) @TypeOf(y[0]) else @TypeOf(y);
    const R: type = numeric.Div(X, Y);

    const vo: [*]types.Scalar(O) = @ptrCast(o);
    const vx: @Vector(baseToVectorLen(X, base_len), types.Scalar(X)) = if (comptime types.isManyItemPointer(@TypeOf(x)))
        @as([*]const types.Scalar(X), @ptrCast(x))[0..baseToVectorLen(X, base_len)].*
    else
        broadcast(base_len, x);
    const vy: @Vector(baseToVectorLen(Y, base_len), types.Scalar(Y)) = if (comptime types.isManyItemPointer(@TypeOf(y)))
        @as([*]const types.Scalar(Y), @ptrCast(y))[0..baseToVectorLen(Y, base_len)].*
    else
        broadcast(base_len, y);

    switch (comptime types.numericType(O)) {
        .bool, .int, .float => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => @compileError("zsl.simd.div_: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "\n"),
                .int, .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) / castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => {
                    const vy_casted = castVector(R, Y, base_len, vy);

                    const c = @shuffle(types.Scalar(R), vy_casted, undefined, maskReals(base_len));
                    const d = @shuffle(types.Scalar(R), vy_casted, undefined, maskIms(base_len));
                    const a = castVector(types.Scalar(R), X, base_len, vx);
                    const b: @Vector(base_len, types.Scalar(R)) = @splat(0.0);

                    const is_d_less = @abs(d) < @abs(c);

                    const denom_major = @select(types.Scalar(R), is_d_less, c, d);
                    const denom_minor = @select(types.Scalar(R), is_d_less, d, c);

                    const num_re_major = @select(types.Scalar(R), is_d_less, a, b);
                    const num_re_minor = @select(types.Scalar(R), is_d_less, b, a);

                    const r = denom_minor / denom_major;
                    const den = @mulAdd(@Vector(base_len, types.Scalar(R)), r, denom_minor, denom_major);

                    const res_re_unscaled = @mulAdd(@Vector(base_len, types.Scalar(R)), r, num_re_minor, num_re_major);
                    const res_re = res_re_unscaled / den;

                    o[0..base_len].* = castVector(O, types.Scalar(R), base_len, res_re);
                },
                .custom => unreachable,
            },
            .int, .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => o[0..base_len].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) / castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => {
                    const vy_casted = castVector(R, Y, base_len, vy);

                    const c = @shuffle(types.Scalar(R), vy_casted, undefined, maskReals(base_len));
                    const d = @shuffle(types.Scalar(R), vy_casted, undefined, maskIms(base_len));
                    const a = castVector(types.Scalar(R), X, base_len, vx);
                    const b: @Vector(base_len, types.Scalar(R)) = @splat(0.0);

                    const is_d_less = @abs(d) < @abs(c);

                    const denom_major = @select(types.Scalar(R), is_d_less, c, d);
                    const denom_minor = @select(types.Scalar(R), is_d_less, d, c);

                    const num_re_major = @select(types.Scalar(R), is_d_less, a, b);
                    const num_re_minor = @select(types.Scalar(R), is_d_less, b, a);

                    const r = denom_minor / denom_major;
                    const den = @mulAdd(@Vector(base_len, types.Scalar(R)), r, denom_minor, denom_major);

                    const res_re_unscaled = @mulAdd(@Vector(base_len, types.Scalar(R)), r, num_re_minor, num_re_major);
                    const res_re = res_re_unscaled / den;

                    o[0..base_len].* = castVector(O, types.Scalar(R), base_len, res_re);
                },
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => o[0..base_len].* = castVector(O, types.Scalar(R), base_len, castVector(types.Scalar(R), X, base_len, vx) / castVector(types.Scalar(R), Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => {
                    const vx_casted = castVector(R, X, base_len, vx);
                    const vy_casted = castVector(R, Y, base_len, vy);

                    const c = @shuffle(types.Scalar(R), vy_casted, undefined, maskReals(base_len));
                    const d = @shuffle(types.Scalar(R), vy_casted, undefined, maskIms(base_len));
                    const a = @shuffle(types.Scalar(R), vx_casted, undefined, maskReals(base_len));
                    const b = @shuffle(types.Scalar(R), vx_casted, undefined, maskIms(base_len));

                    const is_d_less = @abs(d) < @abs(c);

                    const denom_major = @select(types.Scalar(R), is_d_less, c, d);
                    const denom_minor = @select(types.Scalar(R), is_d_less, d, c);

                    const num_re_major = @select(types.Scalar(R), is_d_less, a, b);
                    const num_re_minor = @select(types.Scalar(R), is_d_less, b, a);

                    const r = denom_minor / denom_major;
                    const den = @mulAdd(@Vector(base_len, types.Scalar(R)), r, denom_minor, denom_major);

                    const res_re_unscaled = @mulAdd(@Vector(base_len, types.Scalar(R)), r, num_re_minor, num_re_major);
                    const res_re = res_re_unscaled / den;

                    o[0..base_len].* = castVector(O, types.Scalar(R), base_len, res_re);
                },
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .dyadic => unreachable,
        .complex => switch (comptime types.numericType(X)) {
            .bool => switch (comptime types.numericType(Y)) {
                .bool => @compileError("zsl.simd.div: not defined for " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " and " ++ @typeName(Y) ++ "\n"),
                .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) / castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => {
                    const vy_casted = castVector(R, Y, base_len, vy);

                    const c = @shuffle(types.Scalar(R), vy_casted, undefined, maskReals(base_len));
                    const d = @shuffle(types.Scalar(R), vy_casted, undefined, maskIms(base_len));
                    const a = castVector(types.Scalar(R), X, base_len, vx);
                    const b: @Vector(base_len, types.Scalar(R)) = @splat(0.0);

                    const is_d_less = @abs(d) < @abs(c);

                    const denom_major = @select(types.Scalar(R), is_d_less, c, d);
                    const denom_minor = @select(types.Scalar(R), is_d_less, d, c);

                    const num_re_major = @select(types.Scalar(R), is_d_less, a, b);
                    const num_re_minor = @select(types.Scalar(R), is_d_less, b, a);

                    const num_im_major = @select(types.Scalar(R), is_d_less, b, -a);
                    const num_im_minor = @select(types.Scalar(R), is_d_less, -a, b);

                    const r = denom_minor / denom_major;
                    const den = @mulAdd(@Vector(base_len, types.Scalar(R)), r, denom_minor, denom_major);

                    const res_re_unscaled = @mulAdd(@Vector(base_len, types.Scalar(R)), r, num_re_minor, num_re_major);
                    const res_im_unscaled = @mulAdd(@Vector(base_len, types.Scalar(R)), r, num_im_minor, num_im_major);

                    const res_re = res_re_unscaled / den;
                    const res_im = res_im_unscaled / den;

                    const vres = @shuffle(types.Scalar(R), res_re, res_im, maskZip(base_len));
                    vo[0 .. base_len * 2].* = castVector(O, R, base_len, vres);
                },
                .custom => unreachable,
            },
            .int, .float => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => vo[0 .. base_len * 2].* = castVector(O, R, base_len, castVector(R, X, base_len, vx) / castVector(R, Y, base_len, vy)),
                .dyadic => unreachable,
                .complex => {
                    const vy_casted = castVector(R, Y, base_len, vy);

                    const c = @shuffle(types.Scalar(R), vy_casted, undefined, maskReals(base_len));
                    const d = @shuffle(types.Scalar(R), vy_casted, undefined, maskIms(base_len));
                    const a = castVector(types.Scalar(R), X, base_len, vx);
                    const b: @Vector(base_len, types.Scalar(R)) = @splat(0.0);

                    const is_d_less = @abs(d) < @abs(c);

                    const denom_major = @select(types.Scalar(R), is_d_less, c, d);
                    const denom_minor = @select(types.Scalar(R), is_d_less, d, c);

                    const num_re_major = @select(types.Scalar(R), is_d_less, a, b);
                    const num_re_minor = @select(types.Scalar(R), is_d_less, b, a);

                    const num_im_major = @select(types.Scalar(R), is_d_less, b, -a);
                    const num_im_minor = @select(types.Scalar(R), is_d_less, -a, b);

                    const r = denom_minor / denom_major;
                    const den = @mulAdd(@Vector(base_len, types.Scalar(R)), r, denom_minor, denom_major);

                    const res_re_unscaled = @mulAdd(@Vector(base_len, types.Scalar(R)), r, num_re_minor, num_re_major);
                    const res_im_unscaled = @mulAdd(@Vector(base_len, types.Scalar(R)), r, num_im_minor, num_im_major);

                    const res_re = res_re_unscaled / den;
                    const res_im = res_im_unscaled / den;

                    const vres = @shuffle(types.Scalar(R), res_re, res_im, maskZip(base_len));
                    vo[0 .. base_len * 2].* = castVector(O, R, base_len, vres);
                },
                .custom => unreachable,
            },
            .dyadic => unreachable,
            .complex => switch (comptime types.numericType(Y)) {
                .bool, .int, .float => {
                    const vx_casted = castVector(R, X, base_len, vx);
                    const vy_dup = @shuffle(types.Scalar(R), castVector(types.Scalar(R), Y, base_len, vy), undefined, maskDupScalar(base_len));

                    vo[0 .. base_len * 2].* = castVector(O, R, base_len, vx_casted / vy_dup);
                },
                .dyadic => unreachable,
                .complex => {
                    const vx_casted = castVector(R, X, base_len, vx);
                    const vy_casted = castVector(R, Y, base_len, vy);

                    const c = @shuffle(types.Scalar(R), vy_casted, undefined, maskReals(base_len));
                    const d = @shuffle(types.Scalar(R), vy_casted, undefined, maskIms(base_len));
                    const a = @shuffle(types.Scalar(R), vx_casted, undefined, maskReals(base_len));
                    const b = @shuffle(types.Scalar(R), vx_casted, undefined, maskIms(base_len));

                    const is_d_less = @abs(d) < @abs(c);

                    const denom_major = @select(types.Scalar(R), is_d_less, c, d);
                    const denom_minor = @select(types.Scalar(R), is_d_less, d, c);

                    const num_re_major = @select(types.Scalar(R), is_d_less, a, b);
                    const num_re_minor = @select(types.Scalar(R), is_d_less, b, a);

                    const num_im_major = @select(types.Scalar(R), is_d_less, b, -a);
                    const num_im_minor = @select(types.Scalar(R), is_d_less, -a, b);

                    const r = denom_minor / denom_major;
                    const den = @mulAdd(@Vector(base_len, types.Scalar(R)), r, denom_minor, denom_major);

                    const res_re_unscaled = @mulAdd(@Vector(base_len, types.Scalar(R)), r, num_re_minor, num_re_major);
                    const res_im_unscaled = @mulAdd(@Vector(base_len, types.Scalar(R)), r, num_im_minor, num_im_major);

                    const res_re = res_re_unscaled / den;
                    const res_im = res_im_unscaled / den;

                    vo[0 .. base_len * 2].* = castVector(O, R, base_len, @shuffle(types.Scalar(R), res_re, res_im, maskZip(base_len)));
                },
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
