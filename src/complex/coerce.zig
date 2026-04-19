const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Coerces two complex, dyadic, float, int or bool types, where at least one of
/// them must be a complex type, to the smallest type that can represent all
/// values representable by either type.
///
/// ## Arguments
/// * `X` (`comptime type`): The first type to coerce.
/// * `Y` (`comptime type`): The second type to coerce.
///
/// ## Returns
/// `type`: The coerced type that can represent all values of both `X` and `Y`.
pub fn Coerce(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.complex) or !meta.numericType(Y).le(.complex) or
        (meta.numericType(X) != .complex and meta.numericType(Y) != .complex))
        @compileError("zsl.complex.Coerce: at least one of X or Y must be a complex type, the other must be a bool, an int, a float, a dyadic or a complex type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    if (comptime X == Y)
        return X;

    switch (comptime meta.numericType(X)) {
        .bool => switch (comptime meta.numericType(Y)) {
            .complex => return Y,
            else => unreachable,
        },
        .int => switch (comptime meta.numericType(Y)) {
            .complex => return complex.Complex(numeric.Coerce(X, meta.Scalar(Y))),
            else => unreachable,
        },
        .float => switch (comptime meta.numericType(Y)) {
            .complex => return complex.Complex(numeric.Coerce(X, meta.Scalar(Y))),
            else => unreachable,
        },
        .dyadic => switch (comptime meta.numericType(Y)) {
            .complex => return complex.Complex(numeric.Coerce(X, meta.Scalar(Y))),
            else => unreachable,
        },
        .complex => switch (comptime meta.numericType(Y)) {
            .bool => X,
            .int => return complex.Complex(numeric.Coerce(meta.Scalar(X), Y)),
            .float => return complex.Complex(numeric.Coerce(meta.Scalar(X), Y)),
            .dyadic => return complex.Complex(numeric.Coerce(meta.Scalar(X), Y)),
            .complex => return complex.Complex(numeric.Coerce(meta.Scalar(X), meta.Scalar(Y))),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
