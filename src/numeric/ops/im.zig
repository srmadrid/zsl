const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Im(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.im: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return types.Scalar(X),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlIm", fn (type) type, &.{X}))
                @compileError("zml.numeric.im: " ++ @typeName(X) ++ " must implement `fn ZmlIm(type) type`");

            return X.ZmlIm(X);
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
/// `X` must implement the required `ZmlIm` method. The expected signature and
/// behavior of `ZmlIm` are as follows:
/// * `fn ZmlIm(type) type`: Returns the type of the imaginary part of `x`.
///
/// `numeric.Im(X)` or `X` must implement the required `zmlIm` method. The
/// expected signature and behavior of `zmlIm` are as follows:
/// * `fn zmlIm(X) numeric.Im(X)`: Returns the imaginary part of `x`.
pub inline fn im(x: anytype) numeric.Im(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Im(X);

    switch (comptime types.numericType(X)) {
        .bool => return false,
        .int => return 0,
        .rational => return .zero,
        .float => return 0.0,
        .dyadic => return .zero,
        .complex => return x.im,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlIm",
                fn (X) numeric.Im(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.im: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlIm(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlIm(x);
        },
    }
}
