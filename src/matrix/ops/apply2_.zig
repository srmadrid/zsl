const types = @import("../../types.zig");

const matrix = @import("../../matrix.zig");

/// Applies a binary in-place operation elementwise between an output and two
/// input matrices, or between an output matrix, an input matrix and an input
/// numeric.
///
/// Aliasing is permitted and may be more efficient in some cases.
///
/// For two input sparse matrices, or an input sparse matrix and an input
/// numeric, if the output is also a sparse matrix, the operation is only
/// applied to the indices where at least one of the matrices has a non-zero
/// element.
///
/// ## Signature
/// ```zig
/// matrix.apply2_(*O, x: X, y: Y, op_: Op) !void
/// ```
///
/// ## Arguments
/// * `o` (`anytype`): The output operand.
/// * `x` (`anytype`): The left input operand.
/// * `y` (`anytype`): The right input operand.
/// * `op_` (`comptime anytype`): An in-place binary numeric function to apply
///   elementwise to `o`, `x` and `y`.
///
/// ## Returns
/// `void`
///
/// ## Errors
/// * `matrix.Error.DimensionMismatch`: If the matrices do not have the same
///   dimensions.
///
/// ## Custom type support
/// This function supports custom matrix types via specific method
/// implementations.
///
/// `O`, `X` or `Y` must implement the required `apply2_` method. The expected
/// signatures and behavior of `apply2_` are as follows:
/// * `fn apply2_(*O, X, Y, anytype) !void`: Returns the elementwise application
///   of `op_` on `o`, `x` and `y`.
pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    comptime var O: type = @TypeOf(o);
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const Op: type = @TypeOf(op_);
    const opinfo = @typeInfo(Op);

    comptime if (!types.isPointer(O) or types.isConstPointer(O) or !types.isMatrix(types.Child(O)) or
        (!types.isMatrix(X) and !types.isNumeric(X)) or (!types.isMatrix(Y) and !types.isNumeric(Y)) or
        (!types.isMatrix(X) and !types.isMatrix(Y)) or
        opinfo != .@"fn" or opinfo.@"fn".params.len != 3)
        @compileError("zsl.matrix.apply2_: o must be a mutable one-itme pointer to a matrix, at least one of x or y must be a matrix, the other must be a matrix or a numeric, and op_ must be a function of three arguments, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

    comptime if ((types.isSparseMatrix(O) and types.matrixType(O) != .builder) or
        types.isBuilderMatrix(X) or types.isBuilderMatrix(Y))
        @compileError("zsl.matrix.apply2_: if o points to a sparse matrix it must be a builder matrix, and x and y must not be a builder matrices, got\n\to: " ++
            @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

    O = types.Child(O);

    if (comptime types.isCustomType(O) and types.isMatrix(O)) {
        if (comptime types.isCustomType(X) and types.isMatrix(X)) {
            if (comptime types.isCustomType(Y) and types.isMatrix(Y)) { // O, X and Y all custom matrices
                const Impl: type = comptime types.anyHasMethod(
                    &.{ O, X, Y },
                    "apply2_",
                    fn (*O, X, Y, anytype) anyerror!void,
                    &.{ *O, X, Y, Op },
                ) orelse
                    @compileError("zsl.matrix.apply2_: " ++ @typeName(O) ++ ", " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

                return Impl.apply2_(o, x, y, op_);
            } else { // only O and X custom matrices
                const Impl: type = comptime types.anyHasMethod(
                    &.{ O, X },
                    "apply2_",
                    fn (*O, X, Y, anytype) anyerror!void,
                    &.{ *O, X, Y, Op },
                ) orelse
                    @compileError("zsl.matrix.apply2_: " ++ @typeName(O) ++ " or " ++ @typeName(X) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

                return Impl.apply2_(o, x, y, op_);
            }
        } else {
            if (comptime types.isCustomType(Y) and types.isMatrix(Y)) { // only O and Y custom matrices
                const Impl: type = comptime types.anyHasMethod(
                    &.{ O, Y },
                    "apply2_",
                    fn (*O, X, Y, anytype) anyerror!void,
                    &.{ *O, X, Y, Op },
                ) orelse
                    @compileError("zsl.matrix.apply2_: " ++ @typeName(O) ++ " or " ++ @typeName(Y) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

                return Impl.apply2_(o, x, y, op_);
            } else { // only O custom matrix
                comptime if (!types.hasMethod(O, "apply2_", fn (*O, X, Y, anytype) anyerror!void, &.{ *O, X, Y, Op }))
                    @compileError("zsl.matrix.apply2_: " ++ @typeName(O) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

                return O.apply2_(o, x, y, op_);
            }
        }
    } else if (comptime types.isCustomType(X) and types.isMatrix(X)) {
        if (comptime types.isCustomType(Y) and types.isMatrix(Y)) { // only X and Y custom matrices
            const Impl: type = comptime types.anyHasMethod(
                &.{ X, Y },
                "apply2_",
                fn (*O, X, Y, anytype) anyerror!void,
                &.{ *O, X, Y, Op },
            ) orelse
                @compileError("zsl.matrix.apply2_: " ++ @typeName(X) ++ " or " ++ @typeName(Y) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

            return Impl.apply2_(o, x, y, op_);
        } else { // only X custom matrix
            comptime if (!types.hasMethod(X, "apply2_", fn (*O, X, Y, anytype) anyerror!void, &.{ *O, X, Y, Op }))
                @compileError("zsl.matrix.apply2_: " ++ @typeName(X) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

            return X.apply2_(o, x, y, op_);
        }
    } else if (comptime types.isCustomType(Y) and types.isMatrix(Y)) { // only Y custom matrix
        comptime if (!types.hasMethod(Y, "apply2_", fn (*O, X, Y, anytype) anyerror!void, &.{ *O, X, Y, Op }))
            @compileError("zsl.matrix.apply2_: " ++ @typeName(Y) ++ " must implement `fn apply2_(*" ++ @typeName(O) ++ ", " ++ @typeName(X) ++ ", " ++ @typeName(Y) ++ ", anytype) !void`");

        return Y.apply2_(o, x, y, op_);
    }

    switch (comptime types.matrixType(O)) {
        .general_dense => switch (comptime types.matrixType(X)) {
            .general_dense => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdgdgd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gdgdgs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdgdsd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gdgdss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdgdhd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gdgdhs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdgdtd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gdgdts.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdgddi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdgdpe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdgdnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .general_sparse => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdgsgd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gdgsgs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdgssd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gdgsss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdgshd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gdgshs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdgstd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gdgsts.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdgsdi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdgspe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdgsnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .symmetric_dense => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdsdgd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gdsdgs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdsdsd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gdsdss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdsdhd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gdsdhs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdsdtd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gdsdts.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdsddi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdsdpe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdsdnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .symmetric_sparse => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdssgd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gdssgs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdsssd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gdssss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdsshd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gdsshs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdsstd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gdssts.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdssdi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdsspe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdssnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .hermitian_dense => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdhdgd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gdhdgs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdhdsd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gdhdss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdhdhd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gdhdhs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdhdtd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gdhdts.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdhddi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdhdpe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdhdnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .hermitian_sparse => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdhsgd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gdhsgs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdhssd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gdhsss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdhshd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gdhshs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdhstd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gdhsts.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdhsdi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdhspe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdhsnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .triangular_dense => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdtdgd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gdtdgs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdtdsd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gdtdss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdtdhd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gdtdhs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdtdtd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gdtdts.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdtddi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdtdpe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdtdnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .triangular_sparse => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdtsgd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gdtsgs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdtssd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gdtsss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdtshd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gdtshs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdtstd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gdtsts.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdtsdi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdtspe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdtsnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .builder_sparse => unreachable,
            .diagonal => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gddigd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gddigs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gddisd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gddiss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gddihd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gddihs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdditd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gddits.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gddidi.zig").apply2_(o, x, y, op_),
                // .permutation => return gddipe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gddinu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .permutation => switch (comptime types.matrixType(Y)) {
                // .general_dense => return gdpegd.apply2_(o, x, y, op_),
                // .general_sparse => return gdpegs.apply2_(o, x, y, op_),
                // .symmetric_dense => return gdpesd.apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdpess.apply2_(o, x, y, op_),
                // .hermitian_dense => return gdpehd.apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdpehs.apply2_(o, x, y, op_),
                // .triangular_dense => return gdpetd.apply2_(o, x, y, op_),
                // .triangular_sparse => return gdpets.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                // .diagonal => return gdpedi.apply2_(o, x, y, op_),
                // .permutation => return gdpepe.apply2_(o, x, y, op_),
                .custom => unreachable,
                // .numeric => return gdpenu.apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdnugd.zig").apply2_(o, x, y, op_),
                .general_sparse => return @import("apply2_/gdnugs.zig").apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdnusd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/gdnuss.zig").apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdnuhd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/gdnuhs.zig").apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdnutd.zig").apply2_(o, x, y, op_),
                .triangular_sparse => return @import("apply2_/gdnuts.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdnudi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdnupe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => unreachable,
                else => @compileError("Not implemented yet"),
            },
        },
        .general_sparse => unreachable,
        .symmetric_dense => switch (comptime types.matrixType(X)) {
            .symmetric_dense => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => return @import("apply2_/sdsdsd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/sdsdss.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/sdsddi.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/sdsdnu.zig").apply2_(o, x, y, op_),
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .symmetric_sparse => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => return @import("apply2_/sdsssd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/sdssss.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/sdssdi.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/sdssnu.zig").apply2_(o, x, y, op_),
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .diagonal => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => return @import("apply2_/sddisd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/sddiss.zig").apply2_(o, x, y, op_),
                .diagonal => return @import("apply2_/sddidi.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .custom => unreachable,
                .numeric => return @import("apply2_/sddinu.zig").apply2_(o, x, y, op_),
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => return @import("apply2_/sdnusd.zig").apply2_(o, x, y, op_),
                .symmetric_sparse => return @import("apply2_/sdnuss.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/sdnudi.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => unreachable,
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        },
        .symmetric_sparse => unreachable,
        .hermitian_dense => switch (comptime types.matrixType(X)) {
            .symmetric_dense => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdsdsd.zig").apply2_(o, x, y, op_);
                },
                .symmetric_sparse => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdsdss.zig").apply2_(o, x, y, op_);
                },
                .hermitian_dense => {
                    comptime if (types.isComplex(types.Numeric(X)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdsdhd.zig").apply2_(o, x, y, op_);
                },
                .hermitian_sparse => {
                    comptime if (types.isComplex(types.Numeric(X)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdsdhs.zig").apply2_(o, x, y, op_);
                },
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdsddi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdsdnu.zig").apply2_(o, x, y, op_);
                },
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .symmetric_sparse => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdsssd.zig").apply2_(o, x, y, op_);
                },
                .symmetric_sparse => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdssss.zig").apply2_(o, x, y, op_);
                },
                .hermitian_dense => {
                    comptime if (types.isComplex(types.Numeric(X)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdsshd.zig").apply2_(o, x, y, op_);
                },
                .hermitian_sparse => {
                    comptime if (types.isComplex(types.Numeric(X)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdsshs.zig").apply2_(o, x, y, op_);
                },
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdssdi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdssnu.zig").apply2_(o, x, y, op_);
                },
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .hermitian_dense => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => {
                    comptime if (types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdhdsd.zig").apply2_(o, x, y, op_);
                },
                .symmetric_sparse => {
                    comptime if (types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdhdss.zig").apply2_(o, x, y, op_);
                },
                .hermitian_dense => return @import("apply2_/hdhdhd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/hdhdhs.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdhddi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => {
                    comptime if (types.isComplex(Y))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdhdnu.zig").apply2_(o, x, y, op_);
                },
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .hermitian_sparse => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => {
                    comptime if (types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdhssd.zig").apply2_(o, x, y, op_);
                },
                .symmetric_sparse => {
                    comptime if (types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdhsss.zig").apply2_(o, x, y, op_);
                },
                .hermitian_dense => return @import("apply2_/hdhshd.zig").apply2_(o, x, y, op_),
                .hermitian_sparse => return @import("apply2_/hdhshs.zig").apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdhsdi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => {
                    comptime if (types.isComplex(Y))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdhsnu.zig").apply2_(o, x, y, op_);
                },
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .builder_sparse => unreachable,
            .diagonal => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hddisd.zig").apply2_(o, x, y, op_);
                },
                .symmetric_sparse => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hddiss.zig").apply2_(o, x, y, op_);
                },
                .hermitian_dense => {
                    comptime if (types.isComplex(types.Numeric(X)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hddihd.zig").apply2_(o, x, y, op_);
                },
                .hermitian_sparse => {
                    comptime if (types.isComplex(types.Numeric(X)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hddihs.zig").apply2_(o, x, y, op_);
                },
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hddidi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hddinu.zig").apply2_(o, x, y, op_);
                },
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.matrixType(Y)) {
                .symmetric_dense => {
                    comptime if (types.isComplex(X) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdnusd.zig").apply2_(o, x, y, op_);
                },
                .symmetric_sparse => {
                    comptime if (types.isComplex(X) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdnuss.zig").apply2_(o, x, y, op_);
                },
                .hermitian_dense => {
                    comptime if (types.isComplex(X))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdnuhd.zig").apply2_(o, x, y, op_);
                },
                .hermitian_sparse => {
                    comptime if (types.isComplex(X))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdnuhs.zig").apply2_(o, x, y, op_);
                },
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.isComplex(types.Numeric(X)) or types.isComplex(types.Numeric(Y)))
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/hdnudi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => unreachable,
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        },
        .hermitian_sparse => unreachable,
        .triangular_dense => switch (comptime types.matrixType(X)) {
            .triangular_dense => switch (comptime types.matrixType(Y)) {
                .triangular_dense => {
                    comptime if (types.uploOf(O) != types.uploOf(X) or types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdtdtd.zig").apply2_(o, x, y, op_);
                },
                .triangular_sparse => {
                    comptime if (types.uploOf(O) != types.uploOf(X) or types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdtdts.zig").apply2_(o, x, y, op_);
                },
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdtddi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => {
                    comptime if (types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdtdnu.zig").apply2_(o, x, y, op_);
                },
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .triangular_sparse => switch (comptime types.matrixType(Y)) {
                .triangular_dense => {
                    comptime if (types.uploOf(X) != types.uploOf(Y) or types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdtstd.zig").apply2_(o, x, y, op_);
                },
                .triangular_sparse => {
                    comptime if (types.uploOf(X) != types.uploOf(Y) or types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdtsts.zig").apply2_(o, x, y, op_);
                },
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdtsdi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => {
                    comptime if (types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdtsnu.zig").apply2_(o, x, y, op_);
                },
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .builder_sparse => unreachable,
            .diagonal => switch (comptime types.matrixType(Y)) {
                .triangular_dense => {
                    comptime if (types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdditd.zig").apply2_(o, x, y, op_);
                },
                .triangular_sparse => {
                    comptime if (types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tddits.zig").apply2_(o, x, y, op_);
                },
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tddidi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => {
                    comptime if (types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tddinu.zig").apply2_(o, x, y, op_);
                },
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.matrixType(Y)) {
                .triangular_dense => {
                    comptime if (types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdnutd.zig").apply2_(o, x, y, op_);
                },
                .triangular_sparse => {
                    comptime if (types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdnuts.zig").apply2_(o, x, y, op_);
                },
                .builder_sparse => unreachable,
                .diagonal => {
                    comptime if (types.diagOf(O) == .unit)
                        @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

                    return @import("apply2_/tdnudi.zig").apply2_(o, x, y, op_);
                },
                .custom => unreachable,
                .numeric => unreachable,
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        },
        .triangular_sparse => unreachable,
        .builder_sparse => @compileError("Not implemented yet"),
        .diagonal => switch (comptime types.matrixType(X)) {
            .builder_sparse => unreachable,
            .diagonal => switch (comptime types.matrixType(Y)) {
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/dididi.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/didinu.zig").apply2_(o, x, y, op_),
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.matrixType(Y)) {
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/dinudi.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => unreachable,
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        },
        .permutation => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "\n\tx: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        .custom => unreachable,
        .numeric => unreachable,
    }
}
