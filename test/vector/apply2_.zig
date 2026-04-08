const std = @import("std");

const zsl = @import("zsl");

const tzsl = @import("../zsl.zig");

const combinations = [_][3]type{
    // dedede
    .{ zsl.vector.Dense(zsl.cf32), zsl.vector.Dense(zsl.cf64), zsl.vector.Dense(zsl.cf64) },

    // dedesp
    .{ zsl.vector.Dense(zsl.cf32), zsl.vector.Dense(zsl.cf64), zsl.vector.Sparse(zsl.cf64) },
    // dedesp: aliasing
    .{ zsl.vector.Dense(zsl.cf64), zsl.vector.Dense(zsl.cf64), zsl.vector.Sparse(zsl.cf64) },

    // dedenu
    .{ zsl.vector.Dense(zsl.cf32), zsl.vector.Dense(zsl.cf64), zsl.cf64 },

    // despde
    .{ zsl.vector.Dense(zsl.cf32), zsl.vector.Sparse(zsl.cf64), zsl.vector.Dense(zsl.cf64) },
    // despde: aliasing
    .{ zsl.vector.Dense(zsl.cf64), zsl.vector.Sparse(zsl.cf64), zsl.vector.Dense(zsl.cf64) },

    // despsp
    .{ zsl.vector.Dense(zsl.cf32), zsl.vector.Sparse(zsl.cf64), zsl.vector.Sparse(zsl.cf64) },

    // despnu
    .{ zsl.vector.Dense(zsl.cf32), zsl.vector.Sparse(zsl.cf64), zsl.cf64 },

    // denude
    .{ zsl.vector.Dense(zsl.cf32), zsl.cf64, zsl.vector.Dense(zsl.cf64) },

    // denusp
    .{ zsl.vector.Dense(zsl.cf32), zsl.cf64, zsl.vector.Sparse(zsl.cf64) },

    // spspsp
    .{ zsl.vector.Sparse(zsl.cf32), zsl.vector.Sparse(zsl.cf64), zsl.vector.Sparse(zsl.cf64) },

    // spspnu
    .{ zsl.vector.Sparse(zsl.cf32), zsl.vector.Sparse(zsl.cf64), zsl.cf64 },
    // spspnu: aliasing
    .{ zsl.vector.Sparse(zsl.cf64), zsl.vector.Sparse(zsl.cf64), zsl.cf64 },

    // spnusp
    .{ zsl.vector.Sparse(zsl.cf32), zsl.cf64, zsl.vector.Sparse(zsl.cf64) },
    // spnusp: aliasing
    .{ zsl.vector.Sparse(zsl.cf64), zsl.cf64, zsl.vector.Sparse(zsl.cf64) },
};

const len_limits: [3]usize = .{
    7,
    16,
    33,
};

test "zsl.vector.apply2_" {
    @setEvalBranchQuota(3000);

    const allocator = std.testing.allocator;

    var prng = std.Random.DefaultPrng.init(@bitCast(std.time.timestamp()));
    const rand = prng.random();

    inline for (combinations) |combination| {
        const can_alias_B = combination[0] == combination[1];
        const can_alias_C = combination[0] == combination[2];

        const ops_to_test =
            if (comptime zsl.types.isNumeric(combination[1]))
                .{"mul"}
            else if (comptime zsl.types.isNumeric(combination[2]))
                .{ "mul", "div" }
            else
                .{ "add", "sub" };

        for (len_limits) |len| {
            try executeTestBlock(allocator, rand, combination, ops_to_test, len, false, false);
            if (can_alias_B) try executeTestBlock(allocator, rand, combination, ops_to_test, len, true, false);
            if (can_alias_C) try executeTestBlock(allocator, rand, combination, ops_to_test, len, false, true);
        }
    }
}

fn executeTestBlock(
    allocator: std.mem.Allocator,
    rand: std.Random,
    comptime combination: [3]type,
    comptime ops: anytype,
    len: usize,
    comptime alias_B: bool,
    comptime alias_C: bool,
) !void {
    inline for (ops) |op| {
        var A = try tzsl.vector.randomVector(
            combination[0],
            allocator,
            rand,
            len,
            len,
        );
        defer A.deinit(allocator);

        var B = if (comptime alias_B) A else if (comptime zsl.types.isNumeric(combination[1])) tzsl.randomNumber(combination[1], rand) else try tzsl.vector.randomVector(
            combination[1],
            allocator,
            rand,
            len,
            len / 4,
        );
        defer if (comptime !alias_B) tzsl.deinit(allocator, &B);

        var C = if (comptime alias_C) A else if (comptime zsl.types.isNumeric(combination[2])) tzsl.randomNumber(combination[2], rand) else try tzsl.vector.randomVector(
            combination[2],
            allocator,
            rand,
            len,
            len / 4,
        );
        defer if (comptime !alias_C) tzsl.deinit(allocator, &C);

        var D = if (comptime std.mem.eql(u8, op, "add"))
            try tzsl.vector.correctApply2(zsl.types.Numeric(combination[0]), allocator, len, B, C, zsl.numeric.add_)
        else if (comptime std.mem.eql(u8, op, "sub"))
            try tzsl.vector.correctApply2(zsl.types.Numeric(combination[0]), allocator, len, B, C, zsl.numeric.sub_)
        else if (comptime std.mem.eql(u8, op, "mul"))
            try tzsl.vector.correctApply2(zsl.types.Numeric(combination[0]), allocator, len, B, C, zsl.numeric.mul_)
        else
            try tzsl.vector.correctApply2(zsl.types.Numeric(combination[0]), allocator, len, B, C, zsl.numeric.div_);
        defer D.deinit(allocator);

        if (comptime std.mem.eql(u8, op, "add"))
            zsl.vector.add_(&A, B, C) catch unreachable
        else if (comptime std.mem.eql(u8, op, "sub"))
            zsl.vector.sub_(&A, B, C) catch unreachable
        else if (comptime std.mem.eql(u8, op, "mul"))
            zsl.vector.mul_(&A, B, C) catch unreachable
        else
            zsl.vector.div_(&A, B, C) catch unreachable;

        tzsl.vector.areEql(A, D) catch |e| {
            const aliasing = if (comptime alias_B) "B" else if (comptime alias_C) "C" else "no";
            std.debug.print(
                "Failed on A: {s} = B: {s} {s} C: {s}, case len = {}, aliasing = {s}\n",
                .{ @typeName(combination[0]), @typeName(combination[1]), op, @typeName(combination[2]), len, aliasing },
            );

            tzsl.vector.printVector("A", A);
            if (comptime zsl.types.isVector(@TypeOf(B))) tzsl.vector.printVector("B", B) else std.debug.print("B: {}\n", .{B});
            if (comptime zsl.types.isVector(@TypeOf(C))) tzsl.vector.printVector("C", C) else std.debug.print("C: {}\n", .{C});
            tzsl.vector.printVector("D", D);

            return e;
        };
    }
}
