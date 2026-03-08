const types = @import("../types.zig");
const constants = @import("../constants.zig");
const numeric = @import("../numeric.zig");

const rational = @import("../rational.zig");
const dyadic = @import("../dyadic.zig");
const complex = @import("../complex.zig");

/// Casts a value of any numeric type to any numeric type. Some casts may lead
/// to runtime panics if the value cannot be represented in the target type.
///
/// If the input and output types are equal, this is a no-op, returning the input
/// value directly.
///
/// ## Signature
/// ```zig
/// cast(comptime N: type, value: V) N
/// ```
///
/// ## Arguments
/// * `N` (`comptime type`): The type to cast to. Must be a numeric type.
/// * `value` (`anytype`): The value to cast. Must be a numeric.
///
/// ## Returns
/// `N`: The value casted to the type `N`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// If `N` is a custom numeric type, it must implement the required `from*`
/// method, depending on the input type `V`. The expected signature and behavior
/// of `from*` are as follows:
/// * `fn fromBool(V) N`: Creates a value of type `N` from a boolean value.
/// * `fn fromInt(V) N`: Creates a value of type `N` from a value of int type
///   `V`.
/// * `fn fromRational(V) N`: Creates a value of type `N` from a value of
///   rational type `V`.
/// * `fn fromFloat(V) N`: Creates a value of type `N` from a value of float type
///   `V`.
/// * `fn fromDyadic(V) N`: Creates a value of type `N` from a value of dyadic
///   type `V`.
/// * `fn fromComplex(V) N`: Creates a value of type `N` from a value of complex
///   type `V`.
/// * `fn fromCustom(V) N`: Creates a value of type `N` from a value of custom
///   type `V`.
///
/// If `V` is a custom numeric type, it must implement the required `to*` method,
/// depending on the output type `N`. The expected signature and behavior of
/// `to*` are as follows:
/// * `fn toBool(V) bool`: Converts a value of type `V` to a boolean value.
/// * `fn toInt(V, N: type) N`: Converts a value of type `V` to a value of int
///   type `N`.
/// * `fn toRational(V, N: type) N`: Converts a value of type `V` to a value of
///   rational type `N`.
/// * `fn toFloat(V, N: type) N`: Converts a value of type `V` to a value of
///   float type `N`.
/// * `fn toDyadic(V, N: type) N`: Converts a value of type `V` to a value of
///   dyadic type `N`.
/// * `fn toComplex(V, N: type) N`: Converts a value of type `V` to a value of
///   complex type `N`.
/// * `fn toCustom(V, N: type) N`: Converts a value of type `V` to a value of
///   custom type `N`.
///
/// If both `N` and `V` are custom numeric types, the function will search first
/// for a `from*` method in `N`, then for a `to*` method in `V` if it is not
/// found.
///
/// Boolean arguments have weaker constraints. If `N` is custom, `V` is `bool`
/// and `fromBool` is not found, the function will execute:
/// ```zig
/// return if (value) constants.one(N) else constants.zero(N);
/// ```
/// On the other hand, if `N` is bool, `V` is custom and `toBool` is not found,
/// the function will execute:
/// ```zig
/// return numeric.ne(value, constants.zero(V));
/// ```
/// In either case, `N` or `V` must adhere to the requirements of these
/// functions.
pub inline fn cast(comptime N: type, value: anytype) N {
    const V: type = @TypeOf(value);

    comptime if (!types.isNumeric(N) or !types.isNumeric(V))
        @compileError("zml.cast: N must be a numeric type and value must be a numeric, got\n\tN = " ++ @typeName(N) ++ "\n\tvalue: " ++ @typeName(V) ++ "\n");

    if (comptime N == V)
        return value;

    switch (comptime types.numericType(V)) {
        .bool => switch (comptime types.numericType(N)) {
            .bool => unreachable,
            .int, .rational, .float, .dyadic, .complex => return if (value) constants.one(N) else constants.zero(N),
            .custom => {
                comptime if (!types.hasMethod(N, "fromBool", fn (V) N, &.{V}))
                    return if (value) constants.one(N) else constants.zero(N);

                return N.fromBool(value);
            },
        },
        .int => switch (comptime types.numericType(N)) {
            .bool => return numeric.ne(value, constants.zero(V)),
            .int => return @intCast(value),
            .rational => return .init(value),
            .float => return @floatFromInt(value),
            .dyadic => return .init(value),
            .complex => return .init(value),
            .custom => {
                comptime if (!types.hasMethod(N, "fromInt", fn (V) N, &.{V}))
                    @compileError("zml.cast: " ++ @typeName(N) ++ " must implement `fn fromInt(" ++ @typeName(V) ++ ") " ++ @typeName(N) ++ "`");

                return N.fromInt(value);
            },
        },
        .rational => switch (comptime types.numericType(N)) {
            .bool => return numeric.ne(value, constants.zero(V)),
            .int => return value.toInt(V),
            .rational => return .init(value),
            .float => return value.toFloat(V),
            .dyadic => return .init(value),
            .complex => return .init(value),
            .custom => {
                comptime if (!types.hasMethod(N, "fromRational", fn (V) N, &.{V}))
                    @compileError("zml.cast: " ++ @typeName(N) ++ " must implement `fn fromRational(" ++ @typeName(V) ++ ") " ++ @typeName(N) ++ "`");

                return N.fromRational(value);
            },
        },
        .float => switch (comptime types.numericType(N)) {
            .bool => return numeric.ne(value, constants.zero(V)),
            .int => return @intFromFloat(value),
            .rational => return .init(value),
            .float => return @floatCast(value),
            .dyadic => return .init(value),
            .complex => return .init(value),
            .custom => {
                comptime if (!types.hasMethod(N, "fromFloat", fn (V) N, &.{V}))
                    @compileError("zml.cast: " ++ @typeName(N) ++ " must implement `fn fromFloat(" ++ @typeName(V) ++ ") " ++ @typeName(N) ++ "`");

                return N.fromFloat(value);
            },
        },
        .dyadic => switch (comptime types.numericType(N)) {
            .bool => return numeric.ne(value, constants.zero(V)),
            .int => return value.toInt(V),
            .rational => return .init(value),
            .float => return value.toFloat(V),
            .dyadic => return .init(value),
            .complex => return .init(value),
            .custom => {
                comptime if (!types.hasMethod(N, "fromDyadic", fn (V) N, &.{V}))
                    @compileError("zml.cast: " ++ @typeName(N) ++ " must implement `fn fromDyadic(" ++ @typeName(V) ++ ") " ++ @typeName(N) ++ "`");

                return N.fromDyadic(value);
            },
        },
        .complex => switch (comptime types.numericType(N)) {
            .bool => return numeric.ne(value, constants.zero(V)),
            .int => return .initSet(value, constants.zero),
            .rational => return .initSet(value),
            .float => return .initSet(value),
            .dyadic => return .initSet(value),
            .complex => return .{
                .re = cast(types.Scalar(N), value),
                .im = constants.zero(types.Scalar(N)),
            },
            .custom => {
                comptime if (!types.hasMethod(N, "zmlFromDyadic", fn (V) N, &.{V}))
                    @compileError("zml.cast: " ++ @typeName(N) ++ " must implement `fn zmlFromDyadic(" ++ @typeName(V) ++ ") " ++ @typeName(N) ++ "`");

                return N.zmlFromDyadic(value);
            },
        },
    }
}
