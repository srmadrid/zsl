const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Im(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.im: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return types.Scalar(X),
        .custom => {
            if (comptime !types.hasMethod(X, "Im", fn (type) type, &.{X}))
                @compileError("zsl.numeric.im: " ++ @typeName(X) ++ " must implement `fn Im(type) type`");

            return X.Im(X);
        },
    }
}

/// Returns the imaginary part of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.im(x: X) numeric.Im(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the imaginary part of.
///
/// ## Returns
/// `numeric.Im(@TypeOf(x))`: The imaginary part of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Im` method. The expected signature and
/// behavior of `Im` are as follows:
/// * `fn Im(type) type`: Returns the type of the imaginary part of `x`.
///
/// `numeric.Im(X)` or `X` must implement the required `im` method. The
/// expected signature and behavior of `im` are as follows:
/// * `fn im(X) numeric.Im(X)`: Returns the imaginary part of `x`.
pub fn im(x: anytype) numeric.Im(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Im(X);

    switch (comptime types.numericType(X)) {
        .bool => return false,
        .int => return 0,
        .float => return 0.0,
        .dyadic => return .zero,
        .complex => return x.im,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "im",
                fn (X) numeric.Im(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.im: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn im(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.im(x);
        },
    }
}
