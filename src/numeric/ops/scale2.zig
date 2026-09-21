const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

pub fn Scale2(X: type) type {
    comptime if (!meta.isNumeric(X))
        @compileError("zsl.numeric.Scale2: X must be a numeric type, got \n\tX = " ++ @typeName(X) ++ "\n");

    switch (comptime meta.numericType(X)) {
        .bool => @compileError("zsl.numeric.Scale2: not defined for " ++ @typeName(X) ++ "."),
        .int => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !meta.hasMethod(X, "Scale2", fn (type) type, &.{X}))
                @compileError("zsl.numeric.Scale2: " ++ @typeName(X) ++ " must implement `fn Scale2(type) type`");

            return X.Scale2(X);
        },
    }
}

/// Returns the result of multiplying a numeric `x` by 2 raised to the power of
/// `n` (`x * 2ⁿ`).
///
/// ## Signature
/// ```zig
/// numeric.scale2(x: X, n: isize) numeric.Scale2(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to be scaled.
/// * `n` (`isize`): The integer exponent to raise 2 by.
///
/// ## Returns
/// `numeric.Scale2(@TypeOf(x), isize)`: The scaled value of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Scale2` method. The expected signature and
/// behavior of `Scale2` are as follows:
/// * `fn Scale2(type) type`: Returns the type of the scaled value.
///
/// `numeric.Scale2(X)` or `X` must implement the required `scale2` method. The
/// expected signature and behavior of `scale2` are as follows:
/// * `fn scale2(X, isize) numeric.Scale2(X)`: Returns the scaled value of `x`.
pub fn scale2(x: anytype, n: isize) numeric.Scale2(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Scale2(X);

    switch (comptime meta.numericType(X)) {
        .bool => unreachable,
        .int => return if (n >= 0) x << @intCast(n) else x >> @intCast(-n),
        .float => return @import("scale2/float.zig").scale2(x, n),
        .dyadic => @compileError("zsl.numeric.scale2: not implemented for " ++ @typeName(X) ++ " yet."),
        .complex => return .{
            .re = numeric.scale2(numeric.re(x), n),
            .im = numeric.scale2(numeric.im(x), n),
        },
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{ R, X },
                "scale2",
                fn (X, isize) numeric.Scale2(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.scale2: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn scale2(" ++ @typeName(X) ++ ", isize) " ++ @typeName(R) ++ "`");

            return Impl.scale2(x, n);
        },
    }
}

pub fn scale2Into(o: anytype, x: anytype, n: isize) void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);

    comptime if (!meta.isPointer(O) or meta.isConstPointer(O) or
        !meta.isNumeric(meta.Child(O)) or
        !meta.isNumeric(X))
        @compileError("zsl.numeric.scale2Into: o must be a mutable one-item pointer to a numeric, and x must be a numeric, got \n\to: " ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n");

    O = meta.Child(O);

    if (comptime meta.isCustomNumeric(O)) {
        if (comptime meta.isCustomNumeric(X)) { // O and X both custom
            if (comptime meta.anyHasMethod(&.{ O, X }, "scale2Into", fn (*O, X, isize) void, &.{ *O, X, isize })) |Impl|
                return Impl.scale2Into(o, x, n);
        } else { // only O custom
            if (comptime meta.hasMethod(O, "scale2Into", fn (*O, X, isize) void, &.{ *O, X, isize }))
                return O.scale2Into(o, x, n);
        }
    } else if (comptime meta.isCustomNumeric(X)) { // only X custom
        if (comptime meta.hasMethod(X, "scale2Into", fn (*O, X, isize) void, &.{ *O, X, isize }))
            return X.scale2Into(o, x, n);
    }

    return numeric.set(o, numeric.scale2(x, n));
}
