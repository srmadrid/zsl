const types = @import("../types.zig");

const int = @import("../int.zig");
const rational = @import("../rational.zig");
const float = @import("../float.zig");
const dyadic = @import("../dyadic.zig");
const complex = @import("../complex.zig");

/// Returns the additive identity (zero) for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the zero value for.
///
/// ## Returns
/// `N`: The zero value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must implement the required `zero` method. The expected signature and
/// behavior of `zero` are as follows:
/// * `fn zero(anytype) N`: Returns the zero value.
pub inline fn zero(comptime N: type) N {
    comptime if (!types.isNumeric(N))
        @compileError("zsl.numeric.zero: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime types.numericType(N)) {
        .bool => return false,
        .int => return 0,
        .rational => return .zero,
        .float => return 0.0,
        .dyadic => return .zero,
        .complex => return .zero,
        .custom => {
            comptime if (!types.hasMethod(N, "zero", fn () N, &.{}))
                @compileError("zsl.numeric.zero: " ++ @typeName(N) ++ " must implement `fn zero() " ++ @typeName(N) ++ "`");

            return N.zero();
        },
    }
}

/// Returns the multiplicative identity (one) for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the one value for.
///
/// ## Returns
/// `N`: The one value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must implement the required `one` method. The expected signature and
/// behavior of `one` are as follows:
/// * `fn one() N`: Returns the one value.
pub inline fn one(comptime N: type) N {
    comptime if (!types.isNumeric(N))
        @compileError("zsl.numeric.one: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime types.numericType(N)) {
        .bool => return true,
        .int => return 1,
        .rational => return .one,
        .float => return 1.0,
        .dyadic => return .one,
        .complex => return .one,
        .custom => {
            comptime if (!types.hasMethod(N, "one", fn () N, &.{}))
                @compileError("zsl.numeric.one: " ++ @typeName(N) ++ " must implement `fn one() " ++ @typeName(N) ++ "`");

            return N.one();
        },
    }
}

/// Returns the numeric constant two for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the two value for.
///
/// ## Returns
/// `N`: The two value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must implement the required `two` method. The expected signature and
/// behavior of `two` are as follows:
/// * `fn two() N`: Returns the two value.
pub inline fn two(comptime N: type) N {
    comptime if (!types.isNumeric(N))
        @compileError("zsl.numeric.two: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime types.numericType(N)) {
        .bool => return true,
        .custom => {
            comptime if (!types.hasMethod(N, "two", fn () N, &.{}))
                @compileError("zsl.numeric.two: " ++ @typeName(N) ++ " must implement `fn two() " ++ @typeName(N) ++ "`");

            return N.two();
        },
    }
}
