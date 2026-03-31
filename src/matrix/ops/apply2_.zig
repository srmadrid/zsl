const types = @import("../../types.zig");

const matrix = @import("../../matrix.zig");

/// Applies a binary in-place operation elementwise between an output and two
/// input matrices, or between an output matrix, an input matrix and an input
/// numeric.
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
                // .general_sparse => return gdgdgs.apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdgdsd.zig").apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdgdss.apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdgdhd.zig").apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdgdhs.apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdgdtd.zig").apply2_(o, x, y, op_),
                // .triangular_sparse => return gdgdts.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdgddi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdgdpe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdgdnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .general_sparse => switch (comptime types.matrixType(Y)) {
                // .general_dense => return gdgsgd.apply2_(o, x, y, op_),
                // .general_sparse => return gdgsgs.apply2_(o, x, y, op_),
                // .symmetric_dense => return gdgssd.apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdgsss.apply2_(o, x, y, op_),
                // .hermitian_dense => return gdgshd.apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdgshs.apply2_(o, x, y, op_),
                // .triangular_dense => return gdgstd.apply2_(o, x, y, op_),
                // .triangular_sparse => return gdgsts.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                // .diagonal => return gdgsdi.apply2_(o, x, y, op_),
                // .permutation => return gdgspe.apply2_(o, x, y, op_),
                .custom => unreachable,
                // .numeric => return gdgsnu.apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .symmetric_dense => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdsdgd.zig").apply2_(o, x, y, op_),
                // .general_sparse => return gdsdgs.apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdsdsd.zig").apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdsdss.apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdsdhd.zig").apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdsdhs.apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdsdtd.zig").apply2_(o, x, y, op_),
                // .triangular_sparse => return gdsdts.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdsddi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdsdpe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdsdnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .symmetric_sparse => switch (comptime types.matrixType(Y)) {
                // .general_dense => return gdspgd.apply2_(o, x, y, op_),
                // .general_sparse => return gdspgs.apply2_(o, x, y, op_),
                // .symmetric_dense => return gdspsd.apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdspss.apply2_(o, x, y, op_),
                // .hermitian_dense => return gdsphd.apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdsphs.apply2_(o, x, y, op_),
                // .triangular_dense => return gdsptd.apply2_(o, x, y, op_),
                // .triangular_sparse => return gdspts.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                // .diagonal => return gdspdi.apply2_(o, x, y, op_),
                // .permutation => return gdsppe.apply2_(o, x, y, op_),
                .custom => unreachable,
                // .numeric => return gdspnu.apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .hermitian_dense => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdhdgd.zig").apply2_(o, x, y, op_),
                // .general_sparse => return gdhdgs.apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdhdsd.zig").apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdhdss.apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdhdhd.zig").apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdhdhs.apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdhdtd.zig").apply2_(o, x, y, op_),
                // .triangular_sparse => return gdhdts.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdhddi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdhdpe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdhdnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .hermitian_sparse => switch (comptime types.matrixType(Y)) {
                // .general_dense => return gdhsgd.apply2_(o, x, y, op_),
                // .general_sparse => return gdshgs.apply2_(o, x, y, op_),
                // .symmetric_dense => return gdhssd.apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdhsss.apply2_(o, x, y, op_),
                // .hermitian_dense => return gdhshd.apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdhshs.apply2_(o, x, y, op_),
                // .triangular_dense => return gdhstd.apply2_(o, x, y, op_),
                // .triangular_sparse => return gdhsts.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                // .diagonal => return gdhsdi.apply2_(o, x, y, op_),
                // .permutation => return gdhspe.apply2_(o, x, y, op_),
                .custom => unreachable,
                // .numeric => return gdhsnu.apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .triangular_dense => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gdtdgd.zig").apply2_(o, x, y, op_),
                // .general_sparse => return gdtdgs.apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdtdsd.zig").apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdtdss.apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdtdhd.zig").apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdtdhs.apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdtdtd.zig").apply2_(o, x, y, op_),
                // .triangular_sparse => return gdtdts.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdtddi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdtdpe.apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/gdtdnu.zig").apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .triangular_sparse => switch (comptime types.matrixType(Y)) {
                // .general_dense => return gdtsgd.apply2_(o, x, y, op_),
                // .general_sparse => return gdtsgs.apply2_(o, x, y, op_),
                // .symmetric_dense => return gdtssd.apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdtsss.apply2_(o, x, y, op_),
                // .hermitian_dense => return gdtshd.apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdtshs.apply2_(o, x, y, op_),
                // .triangular_dense => return gdtstd.apply2_(o, x, y, op_),
                // .triangular_sparse => return gdtsts.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                // .diagonal => return gdtsdi.apply2_(o, x, y, op_),
                // .permutation => return gdtspe.apply2_(o, x, y, op_),
                .custom => unreachable,
                // .numeric => return gdtsnu.apply2_(o, x, y, op_),
                else => @compileError("Not implemented yet"),
            },
            .builder_sparse => unreachable,
            .diagonal => switch (comptime types.matrixType(Y)) {
                .general_dense => return @import("apply2_/gddigd.zig").apply2_(o, x, y, op_),
                // .general_sparse => return gddigs.apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gddisd.zig").apply2_(o, x, y, op_),
                // .symmetric_sparse => return gddiss.apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gddihd.zig").apply2_(o, x, y, op_),
                // .hermitian_sparse => return gddihs.apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdditd.zig").apply2_(o, x, y, op_),
                // .triangular_sparse => return gddits.apply2_(o, x, y, op_),
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
                // .general_sparse => return gdnugs.apply2_(o, x, y, op_),
                .symmetric_dense => return @import("apply2_/gdnusd.zig").apply2_(o, x, y, op_),
                // .symmetric_sparse => return gdnuss.apply2_(o, x, y, op_),
                .hermitian_dense => return @import("apply2_/gdnuhd.zig").apply2_(o, x, y, op_),
                // .hermitian_sparse => return gdnuhs.apply2_(o, x, y, op_),
                .triangular_dense => return @import("apply2_/gdnutd.zig").apply2_(o, x, y, op_),
                // .triangular_sparse => return gdnuts.apply2_(o, x, y, op_),
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/gdnudi.zig").apply2_(o, x, y, op_),
                // .permutation => return gdnupe.apply2_(o, x, y, op_),
                .custom => unreachable,
                // .numeric => unreachable,
                else => @compileError("Not implemented yet"),
            },
        },
        .general_sparse => unreachable,
        //     .symmetric_dense => switch (comptime types.matrixType(X)) {
        //         .symmetric_dense => switch (comptime types.matrixType(Y)) {
        //             .symmetric_dense => return sdsdsd.apply2_(o, x, y, op_),
        //             .symmetric_sparse => return sdsdss.apply2_(o, x, y, op_),
        //             .diagonal => return sdsddi.apply2_(o, x, y, op_),
        //             .custom => unreachable,
        //             .numeric => return sdsdnu.apply2_(o, x, y, op_),
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .symmetric_sparse => switch (comptime types.matrixType(Y)) {
        //             .symmetric_dense => return sdspsd.apply2_(o, x, y, op_),
        //             .symmetric_sparse => return sdspss.apply2_(o, x, y, op_),
        //             .diagonal => return sdspdi.apply2_(o, x, y, op_),
        //             .custom => unreachable,
        //             .numeric => return sdspnu.apply2_(o, x, y, op_),
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .diagonal => switch (comptime types.matrixType(Y)) {
        //             .symmetric_dense => return sddisd.apply2_(o, x, y, op_),
        //             .symmetric_sparse => return sddiss.apply2_(o, x, y, op_),
        //             .diagonal => return sddidi.apply2_(o, x, y, op_),
        //             .custom => unreachable,
        //             .numeric => return sddinu.apply2_(o, x, y, op_),
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .custom => unreachable,
        //         .numeric => switch (comptime types.matrixType(Y)) {
        //             .symmetric_dense => return sdnusd.apply2_(o, x, y, op_),
        //             .symmetric_sparse => return sdnuss.apply2_(o, x, y, op_),
        //             .diagonal => return gdnudi.apply2_(o, x, y, op_),
        //             .custom => unreachable,
        //             .numeric => unreachable,
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //     },
        .symmetric_sparse => unreachable,
        //     .hermitian_dense => switch (comptime types.matrixType(X)) {
        //         .symmetric_dense => switch (comptime types.matrixType(Y)) {
        //             .hermitian_dense => {
        //                 comptime if (types.isComplex(types.Numeric(X)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhddi.apply2_(o, x, y, op_);
        //             },
        //             .hermitian_sparse => {
        //                 comptime if (types.isComplex(types.Numeric(X)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhddi.apply2_(o, x, y, op_);
        //             },
        //             .custom => unreachable,
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .symmetric_sparse => switch (comptime types.matrixType(Y)) {
        //             .hermitian_dense => {
        //                 comptime if (types.isComplex(types.Numeric(X)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhddi.apply2_(o, x, y, op_);
        //             },
        //             .hermitian_sparse => {
        //                 comptime if (types.isComplex(types.Numeric(X)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhddi.apply2_(o, x, y, op_);
        //             },
        //             .custom => unreachable,
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .hermitian_dense => switch (comptime types.matrixType(Y)) {
        //             .symmetric_dense => {
        //                 comptime if (types.isComplex(types.Numeric(Y)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhdsd.apply2_(o, x, y, op_);
        //             },
        //             .symmetric_sparse => {
        //                 comptime if (types.isComplex(types.Numeric(Y)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhdsd.apply2_(o, x, y, op_);
        //             },
        //             .hermitian_dense => return hdhdhd.apply2_(o, x, y, op_),
        //             .hermitian_sparse => return hdhdhs.apply2_(o, x, y, op_),
        //             .diagonal => {
        //                 comptime if (types.isComplex(types.Numeric(Y)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhddi.apply2_(o, x, y, op_);
        //             },
        //             .custom => unreachable,
        //             .numeric => {
        //                 comptime if (types.isComplex(Y))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhdnu.apply2_(o, x, y, op_);
        //             },
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .hermitian_sparse => switch (comptime types.matrixType(Y)) {
        //             .symmetric_dense => {
        //                 comptime if (types.isComplex(types.Numeric(Y)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhdsd.apply2_(o, x, y, op_);
        //             },
        //             .symmetric_sparse => {
        //                 comptime if (types.isComplex(types.Numeric(Y)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhdsd.apply2_(o, x, y, op_);
        //             },
        //             .hermitian_dense => return hdhdhd.apply2_(o, x, y, op_),
        //             .hermitian_sparse => return hdhdhs.apply2_(o, x, y, op_),
        //             .diagonal => {
        //                 comptime if (types.isComplex(types.Numeric(Y)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhddi.apply2_(o, x, y, op_);
        //             },
        //             .custom => unreachable,
        //             .numeric => {
        //                 comptime if (types.isComplex(Y))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhdnu.apply2_(o, x, y, op_);
        //             },
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .diagonal => switch (comptime types.matrixType(Y)) {
        //             .hermitian_dense => {
        //                 comptime if (types.isComplex(types.Numeric(X)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhddi.apply2_(o, x, y, op_);
        //             },
        //             .hermitian_sparse => {
        //                 comptime if (types.isComplex(types.Numeric(X)))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhddi.apply2_(o, x, y, op_);
        //             },
        //             .diagonal => return sddidi.apply2_(o, x, y, op_),
        //             .custom => unreachable,
        //             .numeric => return sddinu.apply2_(o, x, y, op_),
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .custom => unreachable,
        //         .numeric => switch (comptime types.matrixType(Y)) {
        //             .hermitian_dense => {
        //                 comptime if (types.isComplex(X))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhdnu.apply2_(o, x, y, op_);
        //             },
        //             .hermitian_sparse => {
        //                 comptime if (types.isComplex(X))
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return hdhdnu.apply2_(o, x, y, op_);
        //             },
        //             .custom => unreachable,
        //             .numeric => unreachable,
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //     },
        .hermitian_sparse => unreachable,
        //     .triangular_dense => switch (comptime types.matrixType(X)) {
        //         .triangular_dense => switch (comptime types.matrixType(Y)) {
        //             .triangular_dense => {
        //                 comptime if (types.uploOf(X) != types.uploOf(Y) or types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdtdtd.apply2_(o, x, y, op_);
        //             },
        //             .triangular_sparse => {
        //                 comptime if (types.uploOf(X) != types.uploOf(Y) or types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdtdts.apply2_(o, x, y, op_);
        //             },
        //             .diagonal => {
        //                 comptime if (types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdtddi.apply2_(o, x, y, op_);
        //             },
        //             .custom => unreachable,
        //             .numeric => {
        //                 comptime if (types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdtdnu.apply2_(o, x, y, op_);
        //             },
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .triangular_sparse => switch (comptime types.matrixType(Y)) {
        //             .triangular_dense => {
        //                 comptime if (types.uploOf(X) != types.uploOf(Y) or types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdtstd.apply2_(o, x, y, op_);
        //             },
        //             .triangular_sparse => {
        //                 comptime if (types.uploOf(X) != types.uploOf(Y) or types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdtsts.apply2_(o, x, y, op_);
        //             },
        //             .diagonal => {
        //                 comptime if (types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdtsdi.apply2_(o, x, y, op_);
        //             },
        //             .custom => unreachable,
        //             .numeric => {
        //                 comptime if (types.uploOf(O) != types.uploOf(X) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdtsnu.apply2_(o, x, y, op_);
        //             },
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .diagonal => switch (comptime types.matrixType(Y)) {
        //             .triangular_dense => {
        //                 comptime if (types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdditd.apply2_(o, x, y, op_);
        //             },
        //             .triangular_sparse => {
        //                 comptime if (types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tddits.apply2_(o, x, y, op_);
        //             },
        //             .diagonal => {
        //                 comptime if (types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tddidi.apply2_(o, x, y, op_);
        //             },
        //             .custom => unreachable,
        //             .numeric => {
        //                 comptime if (types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tddinu.apply2_(o, x, y, op_);
        //             },
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         .custom => unreachable,
        //         .numeric => switch (comptime types.matrixType(Y)) {
        //             .triangular_dense => {
        //                 comptime if (types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdnutd.apply2_(o, x, y, op_);
        //             },
        //             .triangular_sparse => {
        //                 comptime if (types.uploOf(O) != types.uploOf(Y) or types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdnuts.apply2_(o, x, y, op_);
        //             },
        //             .diagonal => {
        //                 comptime if (types.diagOf(O) == .unit)
        //                     @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n");

        //                 return tdnudi.apply2_(o, x, y, op_);
        //             },
        //             .custom => unreachable,
        //             .numeric => unreachable,
        //             else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //         },
        //         else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        //     },
        .triangular_sparse => unreachable,
        //     .builder_sparse => {},
        .diagonal => switch (comptime types.matrixType(X)) {
            .builder_sparse => unreachable,
            .diagonal => switch (comptime types.matrixType(Y)) {
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/dididi.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => return @import("apply2_/didinu.zig").apply2_(o, x, y, op_),
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            .custom => unreachable,
            .numeric => switch (comptime types.matrixType(Y)) {
                .builder_sparse => unreachable,
                .diagonal => return @import("apply2_/dinudi.zig").apply2_(o, x, y, op_),
                .custom => unreachable,
                .numeric => unreachable,
                else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
            },
            else => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        },
        .permutation => @compileError("zsl.matrix.apply2_: the result of the operation is incompatible with o's type, got\n\to: *" ++ @typeName(O) ++ "x: " ++ @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\top_: " ++ @typeName(Op) ++ "\n"),
        .custom => unreachable,
        .numeric => unreachable,
        else => @compileError("Not implemented yet"),
    }
}
