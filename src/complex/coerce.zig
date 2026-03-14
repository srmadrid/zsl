const types = @import("../types.zig");
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
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or
        !types.numericType(X).le(.complex) or !types.numericType(Y).le(.complex) or
        (types.numericType(X) != .complex and types.numericType(Y) != .complex))
        @compileError("zsl.complex.Coerce: at least one of X or Y must be a complex type, the other must be a bool, an int, a float, a dyadic or a complex type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    if (comptime X == Y)
        return X;

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .complex => return Y,
            else => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .complex => return complex.Complex(numeric.Coerce(X, types.Scalar(Y))),
            else => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .complex => return complex.Complex(numeric.Coerce(X, types.Scalar(Y))),
            else => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .complex => return complex.Complex(numeric.Coerce(X, types.Scalar(Y))),
            else => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool => X,
            .int => return complex.Complex(numeric.Coerce(types.Scalar(X), Y)),
            .float => return complex.Complex(numeric.Coerce(types.Scalar(X), Y)),
            .dyadic => return complex.Complex(numeric.Coerce(types.Scalar(X), Y)),
            .complex => return complex.Complex(numeric.Coerce(types.Scalar(X), types.Scalar(Y))),
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
