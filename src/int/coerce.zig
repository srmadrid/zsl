const std = @import("std");

const meta = @import("../meta.zig");

/// Coerces two int or bool types, where at least one of them must be an int
/// type, to the smallest type that can represent all values representable by
/// either type.
///
/// For two ints, if they have different signedness, the result is a signed int.
/// The bit-width of the result is either the larger of the two bit-widths (if
/// the signed type is larger) or the larger of the two bit-widths plus one (if
/// the unsigned type is larger). If both ints are "standard" (see
/// `types.standard_integer_types`), the result is the next larger standard type
/// that can hold both values.
///
/// ## Arguments
/// * `X` (`comptime type`): The first type to coerce.
/// * `Y` (`comptime type`): The second type to coerce.
///
/// ## Returns
/// `type`: The coerced type that can represent all values of both `X` and `Y`.
pub fn Coerce(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.int) or !meta.numericType(Y).le(.int) or
        (meta.numericType(X) != .int and meta.numericType(Y) != .int))
        @compileError("zsl.int.Coerce: at least one of X or Y must be an int type, the other must be a bool or an int type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    if (comptime X == Y)
        return X;

    switch (comptime meta.numericType(X)) {
        .bool => switch (comptime meta.numericType(Y)) {
            .bool => return bool,
            .int => return Y,
            else => unreachable,
        },
        .int => switch (comptime meta.numericType(Y)) {
            .bool => return X,
            .int => {
                if (X == comptime_int)
                    return Y;

                if (Y == comptime_int)
                    return X;

                const xinfo = @typeInfo(X);
                const yinfo = @typeInfo(Y);

                if (xinfo.int.signedness == .unsigned) {
                    if (yinfo.int.signedness == .unsigned) { // both unsigned
                        if (xinfo.int.bits > yinfo.int.bits)
                            return X
                        else
                            return Y;
                    } else { // X unsigned, Y signed
                        if (xinfo.int.bits >= yinfo.int.bits) {
                            // Unsigned is larger or equal to signed
                            if (std.mem.indexOfScalar(type, &meta.standard_integer_types, X) != null and
                                std.mem.indexOfScalar(type, &meta.standard_integer_types, Y) != null)
                            {
                                // Both are standard integers, need to double
                                // bits, unless already at max, then only add 1
                                if (xinfo.int.bits == 128) {
                                    return @Int(yinfo.int.signedness, xinfo.int.bits + 1);
                                } else {
                                    return @Int(yinfo.int.signedness, xinfo.int.bits * 2);
                                }
                            } else {
                                // One of the types is not a standard integer,
                                // only need to increase max bits by 1
                                return @Int(yinfo.int.signedness, xinfo.int.bits + 1);
                            }
                        } else {
                            // Signed is larger than unsigned
                            return Y;
                        }
                    }
                } else {
                    if (yinfo.int.signedness == .unsigned) { // X signed, Y unsigned
                        if (yinfo.int.bits >= xinfo.int.bits) {
                            // Unsigned is larger than signed
                            if (std.mem.indexOfScalar(type, &meta.standard_integer_types, X) != null and
                                std.mem.indexOfScalar(type, &meta.standard_integer_types, Y) != null)
                            {
                                // Both are standard integers, need to double
                                // bits, unless already at max, then only add 1
                                if (yinfo.int.bits == 128) {
                                    return @Int(xinfo.int.signedness, yinfo.int.bits + 1);
                                } else {
                                    return @Int(xinfo.int.signedness, yinfo.int.bits * 2);
                                }
                            } else {
                                // One of the types is not a standard integer,
                                // only need to increase max bits by 1
                                return @Int(xinfo.int.signedness, yinfo.int.bits + 1);
                            }
                        } else {
                            // Signed is larger than unsigned
                            return X;
                        }
                    } else { // both signed
                        if (xinfo.int.bits > yinfo.int.bits)
                            return X
                        else
                            return Y;
                    }
                }
            },
            else => unreachable,
        },
        else => unreachable,
    }
}
