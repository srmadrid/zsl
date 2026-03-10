const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Fma(X: type, Y: type, Z: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or !types.isNumeric(Z))
        @compileError("zsl.numeric.fma: x, y and z must be numerics, got \n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\tz: " ++ @typeName(Z) ++ "\n");

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) {
            if (comptime types.isCustomType(Z)) { // X, Y and Z all custom
                const Impl: type = comptime types.anyHasMethod(
                    &.{ X, Y, Z },
                    "Fma",
                    fn (type, type, type) type,
                    &.{ X, Y, Z },
                ) orelse
                    @compileError("zsl.numeric.fma: " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ " or " ++ @typeName(Z) ++ " must implement `fn Fma(type, type, type) type`");

                return Impl.Fma(X, Y, Z);
            } else { // only X and Y custom
                const Impl: type = comptime types.anyHasMethod(
                    &.{ X, Y },
                    "Fma",
                    fn (type, type, type) type,
                    &.{ X, Y, Z },
                ) orelse
                    @compileError("zsl.numeric.fma: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn Fma(type, type, type) type`");

                return Impl.Fma(X, Y, Z);
            }
        } else {
            if (comptime types.isCustomType(Z)) { // only X and Z custom
                const Impl: type = comptime types.anyHasMethod(
                    &.{ X, Z },
                    "Fma",
                    fn (type, type, type) type,
                    &.{ X, Y, Z },
                ) orelse
                    @compileError("zsl.numeric.fma: " ++ @typeName(X) ++ " or " ++ @typeName(Z) ++ " must implement `fn Fma(type, type, type) type`");

                return Impl.Fma(X, Y, Z);
            } else { // only X custom
                comptime if (!types.hasMethod(X, "Fma", fn (type, type, type) type, &.{ X, Y, Z }))
                    @compileError("zsl.numeric.fma: " ++ @typeName(X) ++ " must implement `fn Fma(type, type, type) type`");

                return X.Fma(X, Y, Z);
            }
        }
    } else if (comptime types.isCustomType(Y)) {
        if (comptime types.isCustomType(Z)) { // only Y and Z custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ Y, Z },
                "Fma",
                fn (type, type, type) type,
                &.{ X, Y, Z },
            ) orelse
                @compileError("zsl.numeric.fma: " ++ @typeName(Y) ++ " or " ++ @typeName(Z) ++ " must implement `fn Fma(type, type, type) type`");

            return Impl.Fma(X, Y, Z);
        } else { // only Y custom
            comptime if (!types.hasMethod(Y, "Fma", fn (type, type, type) type, &.{ X, Y, Z }))
                @compileError("zsl.numeric.fma: " ++ @typeName(Y) ++ " must implement `fn Fma(type, type, type) type`");

            return Y.Fma(X, Y, Z);
        }
    } else if (comptime types.isCustomType(Z)) { // only Z custom
        comptime if (!types.hasMethod(Z, "Fma", fn (type, type, type) type, &.{ X, Y, Z }))
            @compileError("zsl.numeric.fma: " ++ @typeName(Z) ++ " must implement `fn Fma(type, type, type) type`");

        return Z.Fma(X, Y, Z);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => switch (comptime types.numericType(Z)) {
                .bool => @compileError("zsl.numeric.fma: not defined for " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ " and " ++ @typeName(Z) ++ "."),
                .int => return int.Fma(X, Y, Z),
                .rational => return rational.Fma(X, Y, Z),
                .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Z)) {
                .bool, .int => return int.Fma(X, Y, Z),
                .rational => return rational.Fma(X, Y, Z),
                .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .rational => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational => return rational.Fma(X, Y, Z),
                .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => switch (comptime types.numericType(Z)) {
                .bool, .int => return int.Fma(X, Y, Z),
                .rational => return rational.Fma(X, Y, Z),
                .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .rational => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational => return rational.Fma(X, Y, Z),
                .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational => return rational.Fma(X, Y, Z),
                .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float => return float.Fma(X, Y, Z),
                .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.Fma(X, Y, Z),
                .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.Fma(X, Y, Z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}

/// Performs fused multiplication and addition (x * y + z) between any three
/// numeric operands.
///
/// ## Signature
/// ```zig
/// numeric.fma(x: X, y: Y, z: Z) numeric.Fma(X, Y, Z)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left multiplication operand.
/// * `y` (`anytype`): The right multiplication operand.
/// * `z` (`anytype`): The addition operand.
///
/// ## Returns
/// `numeric.Fma(@TypeOf(x), @TypeOf(y), @TypeOf(z))`: The result of the fused
/// multiplication and addition.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X`, `Y` or `Z` must implement the required `Fma` method. The expected
/// signature and behavior of `Fma` are as follows:
/// * `fn Fma(type, type, type) type`: Returns the type of `x * y + z`.
///
/// `numeric.Fma(X, Y, Z)`, `X`, `Y` or `Z` must implement the required `fma`
/// method. The expected signatures and behavior of `fma` are as follows:
/// * `fn fma(X, Y, Z) numeric.Fma(X, Y, Z)`: Returns the fused multiplication
/// and addition of `x`, `y` and `z`.
pub inline fn fma(x: anytype, y: anytype, z: anytype) numeric.Fma(@TypeOf(x), @TypeOf(y), @TypeOf(z)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const Z: type = @TypeOf(z);
    const R: type = numeric.Fma(X, Y, Z);

    if (comptime types.isCustomType(X)) {
        if (comptime types.isCustomType(Y)) {
            if (comptime types.isCustomType(Z)) { // X, Y and Z all custom
                const Impl: type = comptime types.anyHasMethod(
                    &.{ R, X, Y, Z },
                    "fma",
                    fn (X, Y, Z) R,
                    &.{ X, Y, Z },
                ) orelse
                    @compileError("zsl.numeric.fma: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ " or " ++ @typeName(Z) ++ " must implement `fn fma(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", " ++ @typeName(Z) ++ ") " ++ @typeName(R) ++ "`");

                return Impl.fma(x, y, z);
            } else { // only X and Y custom
                const Impl: type = comptime types.anyHasMethod(
                    &.{ R, X, Y },
                    "fma",
                    fn (X, Y, Z) R,
                    &.{ X, Y, Z },
                ) orelse
                    @compileError("zsl.numeric.fma: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn fma(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", " ++ @typeName(Z) ++ ") " ++ @typeName(R) ++ "`");

                return Impl.fma(x, y, z);
            }
        } else {
            if (comptime types.isCustomType(Z)) { // only X and Z custom
                const Impl: type = comptime types.anyHasMethod(
                    &.{ R, X, Z },
                    "fma",
                    fn (X, Y, Z) R,
                    &.{ X, Y, Z },
                ) orelse
                    @compileError("zsl.numeric.fma: " ++ @typeName(R) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Z) ++ " must implement `fn fma(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", " ++ @typeName(Z) ++ ") " ++ @typeName(R) ++ "`");

                return Impl.fma(x, y, z);
            } else { // only X custom
                const Impl: type = comptime types.anyHasMethod(
                    &.{ R, X },
                    "fma",
                    fn (X, Y, Z) R,
                    &.{ X, Y, Z },
                ) orelse
                    @compileError("zsl.numeric.fma: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn fma(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", " ++ @typeName(Z) ++ ") " ++ @typeName(R) ++ "`");

                return Impl.fma(x, y, z);
            }
        }
    } else if (comptime types.isCustomType(Y)) {
        if (comptime types.isCustomType(Z)) { // only Y and Z custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, Y, Z },
                "fma",
                fn (X, Y, Z) R,
                &.{ X, Y, Z },
            ) orelse
                @compileError("zsl.numeric.fma: " ++ @typeName(R) ++ ", " ++ @typeName(Y) ++ " or " ++ @typeName(Z) ++ " must implement `fn fma(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", " ++ @typeName(Z) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.fma(x, y, z);
        } else { // only Y custom
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, Y },
                "fma",
                fn (X, Y, Z) R,
                &.{ X, Y, Z },
            ) orelse
                @compileError("zsl.numeric.fma: " ++ @typeName(R) ++ " or " ++ @typeName(Y) ++ " must implement `fn fma(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", " ++ @typeName(Z) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.fma(x, y, z);
        }
    } else if (comptime types.isCustomType(Z)) { // only Z custom
        const Impl: type = comptime types.anyHasMethod(
            &.{ R, Z },
            "fma",
            fn (X, Y, Z) R,
            &.{ X, Y, Z },
        ) orelse
            @compileError("zsl.numeric.fma: " ++ @typeName(R) ++ " or " ++ @typeName(Z) ++ " must implement `fn fma(" ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", " ++ @typeName(Z) ++ ") " ++ @typeName(R) ++ "`");

        return Impl.fma(x, y, z);
    }

    switch (comptime types.numericType(X)) {
        .bool => switch (comptime types.numericType(Y)) {
            .bool => switch (comptime types.numericType(Z)) {
                .bool => unreachable,
                .int => return int.fma(x, y, z),
                .rational => return rational.fma(x, y, z),
                .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .int => switch (comptime types.numericType(Z)) {
                .bool, .int => return int.fma(x, y, z),
                .rational => return rational.fma(x, y, z),
                .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .rational => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational => return rational.fma(x, y, z),
                .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .int => switch (comptime types.numericType(Y)) {
            .bool, .int => switch (comptime types.numericType(Z)) {
                .bool, .int => return int.fma(x, y, z),
                .rational => return rational.fma(x, y, z),
                .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .rational => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational => return rational.fma(x, y, z),
                .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .rational => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational => return rational.fma(x, y, z),
                .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .float => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .float => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float => return float.fma(x, y, z),
                .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .dyadic => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic => return dyadic.fma(x, y, z),
                .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .complex => switch (comptime types.numericType(Y)) {
            .bool, .int, .rational, .float, .dyadic, .complex => switch (comptime types.numericType(Z)) {
                .bool, .int, .rational, .float, .dyadic, .complex => return complex.fma(x, y, z),
                .custom => unreachable,
            },
            .custom => unreachable,
        },
        .custom => unreachable,
    }
}
