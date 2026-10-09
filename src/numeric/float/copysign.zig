const std = @import("std");

const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

/// Returns a value with the magnitude of `x` and the sign of `y`.
pub fn copysign(x: anytype, y: anytype) @TypeOf(x) {
    comptime if (!meta.isFixedPrecision(@TypeOf(x)) or meta.isComplex(@TypeOf(x)))
        @compileError("x must be an int or float");

    switch (meta.numericType(@TypeOf(x))) {
        .int => {
            switch (meta.numericType(@TypeOf(y))) {
                .int => {
                    comptime if (@typeInfo(@TypeOf(x)).int.signedness == .unsigned and @typeInfo(@TypeOf(y)).int.signedness == .signed)
                        @compileError("If x is an unsigned int, y must be also be an unsigned int");

                    switch (@typeInfo(@TypeOf(y)).int.signedness) {
                        .unsigned => return x,
                        .signed => {
                            if (y < 0) {
                                return -numeric.abs(x);
                            } else {
                                return numeric.abs(x);
                            }
                        },
                    }

                    // To make more efficient
                },
                .float => {
                    comptime if (@typeInfo(@TypeOf(x)).int.signedness == .unsigned)
                        @compileError("If x is an unsigned int, y must be also be an unsigned int");

                    // To implement for int and float
                },
                else => unreachable,
            }
        },
        .float => {
            switch (meta.numericType(@TypeOf(y))) {
                .int => {
                    comptime if (@typeInfo(@TypeOf(x)).float.signedness == .unsigned)
                        @compileError("Not implemented for float and int");

                    // To implement for float and int
                },
                .float => {
                    // To implement for different float meta
                    return std.math.copysign(x, y);
                },
                else => unreachable,
            }
        },
        else => unreachable,
    }
}
