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
            switch (comptime meta.numericType(N)) {
                .bool, .int => unreachable,
                .float, .dyadic => {
                    var u: N = undefined;
                    var v: N = undefined;
                    var s: N = undefined;

                    while (true) {
                        u = numeric.sub(numeric.mul(numeric.two(N), utils.standardUniform(N, prng)), numeric.one(N));
                        v = numeric.sub(numeric.mul(numeric.two(N), utils.standardUniform(N, prng)), numeric.one(N));
                        s = numeric.add(numeric.mul(u, u), numeric.mul(v, v));

                        if (numeric.gt(s, numeric.zero(N)) and numeric.lt(s, numeric.one(N)))
                            break;
                    }

                    return numeric.add(
                        self.mu,
                        numeric.mul(
                            self.sigma,
                            numeric.mul(
                                u,
                                numeric.sqrt(numeric.mul(
                                    numeric.neg(numeric.two(N)),
                                    numeric.div(
                                        numeric.ln(s),
                                        s,
                                    ),
                                )),
                            ),
                        ),
                    );
                },
                .complex => {
                    var u: meta.Scalar(N) = undefined;
                    var v: meta.Scalar(N) = undefined;
                    var s: meta.Scalar(N) = undefined;

                    while (true) {
                        u = numeric.sub(numeric.mul(numeric.two(meta.Scalar(N)), utils.standardUniform(meta.Scalar(N), prng)), numeric.one(meta.Scalar(N)));
                        v = numeric.sub(numeric.mul(numeric.two(meta.Scalar(N)), utils.standardUniform(meta.Scalar(N), prng)), numeric.one(meta.Scalar(N)));
                        s = numeric.add(numeric.mul(u, u), numeric.mul(v, v));

                        if (numeric.gt(s, numeric.zero(meta.Scalar(N))) and numeric.lt(s, numeric.one(meta.Scalar(N))))
                            break;
                    }

                    const tmp = numeric.sqrt(numeric.mul(numeric.neg(numeric.two(meta.Scalar(N))), numeric.div(numeric.ln(s), s)));

                    return .{
                        .re = numeric.add(self.mu.re, numeric.mul(self.sigma.re, numeric.mul(u, tmp))),
                        .im = numeric.add(self.mu.im, numeric.mul(self.sigma.im, numeric.mul(v, tmp))),
                    };
                },
                .custom => @compileError("zsl.stats.Normal(N).sample: not implemented for custom types yet"),
            }
        }
    };
}
