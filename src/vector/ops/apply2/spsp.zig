pub fn apply2(
    allocator: std.mem.Allocator,
    x: anytype,
    y: anytype,
    comptime op: anytype,
    ctx: anytype,
) !Sparse(ReturnType2(op, Numeric(@TypeOf(x)), Numeric(@TypeOf(y)))) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = ReturnType2(op, Numeric(X), Numeric(Y));

    if (comptime !types.isSparseVector(@TypeOf(x))) {
        var result: Sparse(R) = try .init(allocator, y.len, y.nnz);
        errdefer result.deinit(allocator);

        var i: u32 = 0;

        errdefer result.cleanup(
            types.renameStructFields(
                types.keepStructFields(
                    ctx,
                    &.{"allocator"},
                ),
                .{ .allocator = "element_allocator" },
            ),
        );

        const opinfo = @typeInfo(@TypeOf(op));
        while (i < y.nnz) : (i += 1) {
            if (comptime opinfo.@"fn".params.len == 2) {
                result.data[i] = op(x, y.data[i]);
            } else if (comptime opinfo.@"fn".params.len == 3) {
                result.data[i] = try op(x, y.data[i], ctx);
            }

            result.idx[i] = y.idx[i];
            result.nnz += 1;
        }

        return result;
    } else if (comptime !types.isSparseVector(@TypeOf(y))) {
        var result: Sparse(R) = try .init(allocator, x.len, x.nnz);
        errdefer result.deinit(allocator);

        var i: u32 = 0;

        errdefer result.cleanup(
            types.renameStructFields(
                types.keepStructFields(
                    ctx,
                    &.{"allocator"},
                ),
                .{ .allocator = "element_allocator" },
            ),
        );

        const opinfo = @typeInfo(@TypeOf(op));
        while (i < x.nnz) : (i += 1) {
            if (comptime opinfo.@"fn".params.len == 2) {
                result.data[i] = op(x.data[i], y);
            } else if (comptime opinfo.@"fn".params.len == 3) {
                result.data[i] = try op(x.data[i], y, ctx);
            }

            result.idx[i] = x.idx[i];
            result.nnz += 1;
        }

        return result;
    }

    if (x.len != y.len)
        return vector.Error.DimensionMismatch;

    var result: Sparse(R) = try .init(allocator, x.len, int.min(x.nnz + y.nnz, x.len));
    errdefer result.deinit(allocator);

    var i: u32 = 0;
    var j: u32 = 0;

    errdefer result.cleanup(
        types.renameStructFields(
            types.keepStructFields(
                ctx,
                &.{"allocator"},
            ),
            .{ .allocator = "element_allocator" },
        ),
    );

    const opinfo = @typeInfo(@TypeOf(op));
    while (i < x.nnz and j < y.nnz) {
        if (x.idx[i] == y.idx[j]) {
            if (comptime opinfo.@"fn".params.len == 2) {
                result.data[result.nnz] = op(x.data[i], y.data[j]);
            } else if (comptime opinfo.@"fn".params.len == 3) {
                result.data[result.nnz] = try op(x.data[i], y.data[j], ctx);
            }

            result.idx[result.nnz] = x.idx[i];
            result.nnz += 1;
            i += 1;
            j += 1;
        } else if (x.idx[i] < y.idx[j]) {
            if (comptime opinfo.@"fn".params.len == 2) {
                result.data[result.nnz] = op(x.data[i], numeric.zero(Numeric(Y), .{}) catch unreachable);
            } else if (comptime opinfo.@"fn".params.len == 3) {
                result.data[result.nnz] = try op(x.data[i], numeric.zero(Numeric(Y), .{}) catch unreachable, ctx);
            }

            result.idx[result.nnz] = x.idx[i];
            result.nnz += 1;
            i += 1;
        } else {
            if (comptime opinfo.@"fn".params.len == 2) {
                result.data[result.nnz] = op(numeric.zero(Numeric(X), .{}) catch unreachable, y.data[j]);
            } else if (comptime opinfo.@"fn".params.len == 3) {
                result.data[result.nnz] = try op(numeric.zero(Numeric(X), .{}) catch unreachable, y.data[j], ctx);
            }

            result.idx[result.nnz] = y.idx[j];
            result.nnz += 1;
            j += 1;
        }
    }

    while (i < x.nnz) : (i += 1) {
        if (comptime opinfo.@"fn".params.len == 2) {
            result.data[result.nnz] = op(x.data[i], numeric.zero(Numeric(Y), .{}) catch unreachable);
        } else if (comptime opinfo.@"fn".params.len == 3) {
            result.data[result.nnz] = try op(x.data[i], numeric.zero(Numeric(Y), .{}) catch unreachable, ctx);
        }

        result.idx[result.nnz] = x.idx[i];
        result.nnz += 1;
    }

    while (j < y.nnz) : (j += 1) {
        if (comptime opinfo.@"fn".params.len == 2) {
            result.data[result.nnz] = op(numeric.zero(Numeric(X), .{}) catch unreachable, y.data[j]);
        } else if (comptime opinfo.@"fn".params.len == 3) {
            result.data[result.nnz] = try op(numeric.zero(Numeric(X), .{}) catch unreachable, y.data[j], ctx);
        }

        result.idx[result.nnz] = y.idx[j];
        result.nnz += 1;
    }

    return result;
}
