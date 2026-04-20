const std = @import("std");
const options = @import("options");

const meta = @import("../../meta.zig");

const numeric = @import("../../numeric.zig");

const int = @import("../../int.zig");

const linalg = @import("../../linalg.zig");

/// Threshold for n to execute multithreded version (guess, calculate actual value)
const multithreading_threshold = 250_000;

/// Max threads to use (guess, calculate actual value)
const max_threads = 64;

pub fn Asum(X: type) type {
    return meta.Scalar(meta.Child(X));
}

/// Computes the sum of magnitudes of the elements of a real vector, or the sum
/// of magnitudes of the real and imaginary parts of elements of a complex
/// vector:
///
/// ```zig
/// abs(x[0].re) + abs(x[0].im) + abs(x[1].re) + abs(x[1].im) + ... + abs(x[n - 1].re) + abs(x[n - 1].im),
/// ```
///
/// where `x` is a vector with `n` elements.
///
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available.
///
/// ## Signature
/// ```zig
/// linalg.blas.asum(n: isize, x: [*]const X, incx: isize, ctx: anytype) !Asum(X)
/// ```
///
/// ## Arguments
/// * `n` (`isize`): Specifies the number of elements in vector `x`. Must be
///   greater than 0.
/// * `x` (`anytype`): Array, size at least `1 + (n - 1) * abs(incx)`.
/// * `incx` (`isize`): Specifies the increment for indexing vector `x`. Must be
///   different from 0.
///
/// ## Returns
/// `Asum(@TypeOf(x))`: The sum of magnitudes of real and imaginary parts of all
/// elements of the vector.
///
/// ## Errors
/// * `linalg.blas.Error.InvalidArgument`: If `n` is less than or equal to 0, or
///   `incx` is equal to 0.
pub fn asum(n: isize, x: anytype, incx: isize) !linalg.blas.Asum(@TypeOf(x)) {
    comptime var X: type = @TypeOf(x);

    comptime if (!meta.isManyItemPointer(X) or !meta.isNumeric(meta.Child(X)))
        @compileError("zsl.linalg.blas.asum: x must be a many-item pointer to numerics, got \n\tx: " ++ @typeName(X) ++ "\n");

    X = meta.Child(X);

    if (n <= 0 or incx == 0)
        return linalg.blas.Error.InvalidArgument;

    if ((comptime options.link_cblas != null) and incx > 0) {
        switch (comptime meta.numericType(X)) {
            .float => {
                if (comptime X == f32) return linalg.cblas.sasum(n, x, incx) else if (comptime X == f64) return linalg.cblas.dasum(n, x, incx);
            },
            .complex => {
                if (comptime meta.Scalar(X) == f32) return linalg.cblas.scasum(n, x, incx) else if (comptime meta.Scalar(X) == f64) return linalg.cblas.dzasum(n, x, incx);
            },
            else => {},
        }
    }

    if (n < multithreading_threshold)
        return k_asum(n, x, incx);

    const num_threads = int.min(std.Thread.getCpuCount() catch 1, max_threads);

    if (num_threads <= 1)
        return k_asum(n, x, incx);

    var threads: [max_threads]std.Thread = undefined;
    var sums: [max_threads]meta.Accumulator(linalg.blas.Asum(X)) = .{numeric.zero(meta.Accumulator(linalg.blas.Asum(X)))} ** max_threads;

    const Worker = struct {
        fn execute(out: *meta.Accumulator(linalg.blas.Asum(X)), worker_n: isize, worker_x: @TypeOf(x), worker_incx: isize) void {
            out.* = k_asum(worker_n, worker_x, worker_incx);
        }
    };

    const chunk_size = int.div(n, numeric.cast(isize, num_threads));
    var spawn_err: ?anyerror = null;
    var spawned_count: usize = 0;
    var i: usize = 0;
    while (i < num_threads) : (i += 1) {
        const chunk_start = numeric.cast(isize, i) * chunk_size;
        const chunk_end = if (i == num_threads - 1) n else chunk_start + chunk_size;

        if (std.Thread.spawn(.{}, Worker.execute, .{
            &sums[i],
            chunk_end - chunk_start,
            x + numeric.cast(usize, if (incx > 0)
                chunk_start * incx
            else
                (-n + chunk_end) * incx),
            incx,
        })) |th| {
            threads[i] = th;
            spawned_count += 1;
        } else |err| {
            spawn_err = err;
            break;
        }
    }

    var sum = numeric.zero(meta.Accumulator(linalg.blas.Asum(X)));
    var t: usize = 0;
    while (t < spawned_count) : (t += 1) {
        threads[t].join();
        numeric.add_(&sum, sum, sums[t]);
    }

    if (spawn_err) |err|
        return err;

    return numeric.cast(linalg.blas.Asum(X), sum);
}

pub fn k_asum(n: isize, x: anytype, incx: isize) linalg.blas.Asum(@TypeOf(x)) {
    const X: type = meta.Child(@TypeOf(x));

    const len = numeric.cast(usize, n);
    const unroll = 2 * (std.simd.suggestVectorLength(X) orelse 2);

    var sums: [unroll]meta.Accumulator(linalg.blas.Asum(X)) = .{numeric.zero(meta.Accumulator(linalg.blas.Asum(X)))} ** unroll;

    if (incx == 1) {
        var i: usize = 0;
        while (i < (len / unroll) * unroll) : (i += unroll) {
            inline for (0..unroll) |u| {
                // sums[u] += abs1(x[i + u])
                numeric.add_(
                    &sums[u],
                    sums[u],
                    numeric.abs1(x[i + u]),
                );
            }
        }

        while (i < len) : (i += 1) {
            // sums[0] += abs1(x[i])
            numeric.add_(
                &sums[0],
                sums[0],
                numeric.abs1(x[i]),
            );
        }
    } else {
        var ix: isize = if (incx < 0) (-n + 1) * incx else 0;
        var i: usize = 0;

        while (i < (len / unroll) * unroll) : (i += unroll) {
            inline for (0..unroll) |u| {
                // sums[u] += abs1(x[ix + u * incx])
                numeric.add_(
                    &sums[u],
                    sums[u],
                    numeric.abs1(x[numeric.cast(usize, ix + numeric.cast(isize, u) * incx)]),
                );
            }

            ix += numeric.cast(isize, unroll) * incx;
        }

        while (i < len) : (i += 1) {
            // sums[0] += abs1(x[ix])
            numeric.add_(
                &sums[0],
                sums[0],
                numeric.abs1(x[numeric.cast(usize, ix)]),
            );
            ix += incx;
        }
    }

    var sum = numeric.zero(meta.Accumulator(linalg.blas.Asum(X)));
    inline for (0..unroll) |u| {
        // sum += sums[u]
        numeric.add_(&sum, sum, sums[u]);
    }

    return numeric.cast(linalg.blas.Asum(X), sum);
}
