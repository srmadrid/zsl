const std = @import("std");

const meta = @import("../meta.zig");

const numeric = @import("../numeric.zig");

const stats = @import("../stats.zig");

const utils = @import("utils.zig");

/// A normal (Gaussian) distribution that yields values of type `N`.
/// For complex types, the distribution generates independent normal variables
/// for the real and imaginary parts, scaled by `sigma.re` and `sigma.im`
/// respectively. If `sigma.re == sigma.im`, this results in a circularly
/// symmetric complex normal distribution.
pub fn Normal(comptime N: type) type {
    comptime if (!meta.isNumeric(N) or !meta.isNonIntegral(N))
        @compileError("zsl.stats.Normal: N must be a non-integral numeric type, got \n\tN = " ++ @typeName(N) ++ "\n");

    return struct {
        mu: N,
        sigma: N,

        // Type signatures
        pub const is_distribution = true;

        // Numeric type
        pub const Numeric = N;

        const Self = @This();

        /// Initializes a new normal distribution.
        ///
        /// ## Arguments
        /// * `mu` (`N`): The mean (expected value) of the distribution.
        /// * `sigma` (`N`): The standard deviation of the distribution.
        pub fn init(mu: N, sigma: N) Self {
            return .{
                .mu = mu,
                .sigma = sigma,
            };
        }

        /// Samples a random value from the normal distribution using the
        /// Marsaglia polar method.
        ///
        /// ## Arguments
        /// * `self` (`stats.Normal(N)`): The normal distribution to sample
        ///   from.
        /// * `prng` (`std.Random`): The standard random number generator used
        ///   to produce the random bits.
        ///
        /// ## Returns
        /// `N`: A random value normally distributed with mean `mu` and standard
        /// deviation `sigma`.
        pub fn sample(self: Self, prng: std.Random) N {
            var u: meta.Real(N) = undefined;
            var v: meta.Real(N) = undefined;
            var s: meta.Real(N) = undefined;

            while (true) {
                u = numeric.sub(numeric.mul(numeric.two(meta.Real(N)), utils.standardUniform(meta.Real(N), prng)), numeric.one(meta.Real(N)));
                v = numeric.sub(numeric.mul(numeric.two(meta.Real(N)), utils.standardUniform(meta.Real(N), prng)), numeric.one(meta.Real(N)));
                s = numeric.add(numeric.mul(u, u), numeric.mul(v, v));

                if (numeric.gt(s, numeric.zero(meta.Real(N))) and numeric.lt(s, numeric.one(meta.Real(N))))
                    break;
            }

            const temp = numeric.sqrt(numeric.mul(numeric.neg(numeric.two(meta.Real(N))), numeric.div(numeric.ln(s), s)));

            if (comptime !meta.isComplex(N))
                return numeric.add(self.mu, numeric.mul(self.sigma, numeric.mul(u, temp)))
            else
                return .{
                    .re = numeric.add(self.mu.re, numeric.mul(self.sigma.re, numeric.mul(u, temp))),
                    .im = numeric.add(self.mu.im, numeric.mul(self.sigma.im, numeric.mul(v, temp))),
                };
        }
    };
}
