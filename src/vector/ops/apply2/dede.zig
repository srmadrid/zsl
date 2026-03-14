const std = @import("std");

const types = @import("../types.zig");

const vector = @import("../vector.zig");

pub fn apply2(
    allocator: std.mem.Allocator,
    x: anytype,
    y: anytype,
    comptime op: anytype,
) !Dense(ReturnType2(op, Numeric(@TypeOf(x)), Numeric(@TypeOf(y)))) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    const R: type = ReturnType2(op, Numeric(X), Numeric(Y));

    if (comptime !types.isDenseVector(@TypeOf(x))) {
        var result: Dense(R) = try .init(allocator, y.len);
        errdefer result.deinit(allocator);

        var i: u32 = 0;

        errdefer result._cleanup(
            i,
            types.renameStructFields(
                types.keepStructFields(
                    ctx,
                    &.{"allocator"},
                ),
                .{ .allocator = "element_allocator" },
            ),
        );

        const opinfo = @typeInfo(@TypeOf(op));
        if (y.inc == 1) {
            while (i < result.len) : (i += 1) {
                if (comptime opinfo.@"fn".params.len == 2) {
                    result.data[i] = op(x, y.data[i]);
                } else if (comptime opinfo.@"fn".params.len == 3) {
                    result.data[i] = try op(x, y.data[i], ctx);
                }
            }
        } else {
            var iy: i32 = if (y.inc < 0) (-types.scast(i32, y.len) + 1) * y.inc else 0;
            while (i < result.len) : (i += 1) {
                if (comptime opinfo.@"fn".params.len == 2) {
                    result.data[i] = op(x, y.data[types.scast(u32, iy)]);
                } else if (comptime opinfo.@"fn".params.len == 3) {
                    result.data[i] = try op(x, y.data[types.scast(u32, iy)], ctx);
                }

                iy += y.inc;
            }
        }

        return result;
    } else if (comptime !types.isDenseVector(@TypeOf(y))) {
        var result: Dense(R) = try .init(allocator, x.len);
        errdefer result.deinit(allocator);

        var i: u32 = 0;

        errdefer result._cleanup(
            i,
            types.renameStructFields(
                types.keepStructFields(
                    ctx,
                    &.{"allocator"},
                ),
                .{ .allocator = "element_allocator" },
            ),
        );

        const opinfo = @typeInfo(@TypeOf(op));
        if (x.inc == 1) {
            while (i < result.len) : (i += 1) {
                if (comptime opinfo.@"fn".params.len == 2) {
                    result.data[i] = op(x.data[i], y);
                } else if (comptime opinfo.@"fn".params.len == 3) {
                    result.data[i] = try op(x.data[i], y, ctx);
                }
            }
        } else {
            var ix: i32 = if (x.inc < 0) (-types.scast(i32, x.len) + 1) * x.inc else 0;
            while (i < result.len) : (i += 1) {
                if (comptime opinfo.@"fn".params.len == 2) {
                    result.data[i] = op(x.data[types.scast(u32, ix)], y);
                } else if (comptime opinfo.@"fn".params.len == 3) {
                    result.data[i] = try op(x.data[types.scast(u32, ix)], y, ctx);
                }

                ix += x.inc;
            }
        }

        return result;
    }

    if (x.len != y.len)
        return vector.Error.DimensionMismatch;

    var result: Dense(R) = try .init(allocator, x.len);
    errdefer result.deinit(allocator);

    var i: u32 = 0;

    errdefer result._cleanup(
        i,
        types.renameStructFields(
            types.keepStructFields(
                ctx,
                &.{"allocator"},
            ),
            .{ .allocator = "element_allocator" },
        ),
    );

    const opinfo = @typeInfo(@TypeOf(op));
    if (x.inc == 1 and y.inc == 1) {
        while (i < result.len) : (i += 1) {
            if (comptime opinfo.@"fn".params.len == 2) {
                result.data[i] = op(x.data[i], y.data[i]);
            } else if (comptime opinfo.@"fn".params.len == 3) {
                result.data[i] = try op(x.data[i], y.data[i], ctx);
            }
        }
    } else {
        var ix: i32 = if (x.inc < 0) (-types.scast(i32, x.len) + 1) * x.inc else 0;
        var iy: i32 = if (y.inc < 0) (-types.scast(i32, y.len) + 1) * y.inc else 0;
        while (i < result.len) : (i += 1) {
            if (comptime opinfo.@"fn".params.len == 2) {
                result.data[i] = op(x.data[types.scast(u32, ix)], y.data[types.scast(u32, iy)]);
            } else if (comptime opinfo.@"fn".params.len == 3) {
                result.data[i] = try op(x.data[types.scast(u32, ix)], y.data[types.scast(u32, iy)], ctx);
            }

            ix += x.inc;
            iy += y.inc;
        }
    }

    return result;
}
