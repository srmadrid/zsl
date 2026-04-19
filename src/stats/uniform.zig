const std = @import("std");

const meta = @import("../meta.zig");

const numeric = @import("../numeric.zig");

const stats = @import("../stats.zig");

const utils = @import("utils.zig");

/// A uniform distribution that yields values of type `N`. For integral types,
/// the range is inclusive, `[min, max]`, for non-integral types, the range is
/// half-open, `[min, max)`, and for complex types the range is applied to the
/// real and imaginary parts independently, `[min.re, max.re)` and
/// `[min.im, max.im)`.
pub fn Uniform(N: type) type {
    comptime if (!meta.isNumeric(N) or meta.numericType(N) == .bool)
        @compileError("zsl.stats.Uniform: N must be a non-bool numeric type, got \n\tN = " ++ @typeName(N) ++ "\n");

    return struct {
        min: N,
        max: N,

        // Type signatures
        pub const is_distribution = true;

        // Numeric type
        pub const Numeric = N;

        /// Initializes a new uniform distribution.
        ///
        /// ## Arguments
        /// * `min` (`N`): The lower bound of the uniform distribution
        ///   (inclusive).
        /// * `max` (`N`): The upper bound of the uniform distribution
        ///   (inclusive for integral types, exclusive for non-integral types).
        pub fn init(min: N, max: N) stats.Uniform(N) {
            return .{
                .min = min,
                .max = max,
            };
        }

        /// Samples a random value from the uniform distribution.
        ///
        /// ## Arguments
        /// * `self` (`stats.Uniform(N)`): The uniform distribution to sample
        ///   from.
        /// * `prng` (`std.Random`): The standard random number generator used
        ///   to produce the random bits.
        ///
        /// ## Returns
        /// `N`: A random value uniformly distributed between `min` and `max`.
        pub fn sample(self: stats.Uniform(N), prng: std.Random) N {
            switch (comptime meta.numericType(N)) {
                .bool => unreachable,
                .int => return utils.discreteUniform(N, self.min, self.max, prng),
                .float, .dyadic => {
                    const u = utils.standardUniform(N, prng);
                    return numeric.add(self.min, numeric.mul(u, numeric.sub(self.max, self.min)));
                },
                .complex => {
                    const u_re = utils.standardUniform(meta.Scalar(N), prng);
                    const u_im = utils.standardUniform(meta.Scalar(N), prng);
                    return .{
                        .re = numeric.add(self.min.re, numeric.mul(u_re, numeric.sub(self.max.re, self.min.re))),
                        .im = numeric.add(self.min.im, numeric.mul(u_im, numeric.sub(self.max.im, self.min.im))),
                    };
                },
                .custom => @compileError("zsl.stats.Uniform(N).sample: not implemented for custom types yet"),
            }
        }
    };
}
