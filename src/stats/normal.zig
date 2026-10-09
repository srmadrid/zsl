const std = @import("std");

const meta = @import("../meta.zig");

const numeric = @import("../numeric.zig");

const stats = @import("../stats.zig");

const utils = @import("utils.zig");

/// A normal (Gaussian) distribution that yields values of type `Real`.
pub fn Normal(comptime Real: type) type {
    comptime if (!meta.isNumeric(Real) or meta.isIntegral(Real) or !meta.isReal(Real))
        @compileError("zsl.stats.Normal: Real must be a real non-integral numeric type, got \n\tReal = " ++ @typeName(Real) ++ "\n");

    return struct {
        mu: Real,
        sigma: Real,

        // Type signatures
        pub const is_distribution = true;

        /// Initializes a new normal distribution.
        ///
        /// ## Arguments
        /// * `mu` (`Real`): The mean (expected value) of the distribution.
        /// * `sigma` (`Real`): The standard deviation of the distribution.
        pub fn init(mu: Real, sigma: Real) stats.Normal(Real) {
            return .{
                .mu = mu,
                .sigma = sigma,
            };
        }

        /// Samples a random value from the normal distribution using the
        /// Marsaglia polar method.
        ///
        /// ## Arguments
        /// * `self` (`stats.Normal(Real)`): The normal distribution to sample
        ///   from.
        /// * `prng` (`std.Random`): The standard random number generator used
        ///   to produce the random bits.
        ///
        /// ## Returns
        /// `Real`: A random value normally distributed with mean `mu` and
        /// standard deviation `sigma`.
        pub fn sample(self: stats.Normal(Real), prng: std.Random) Real {
            var u: Real = undefined;
            var v: Real = undefined;
            var s: Real = undefined;

            while (true) {
                u = numeric.sub(numeric.mul(2, utils.standardUniform(Real, prng)), 1);
                v = numeric.sub(numeric.mul(2, utils.standardUniform(Real, prng)), 1);
                s = numeric.add(numeric.mul(u, u), numeric.mul(v, v));

                if (numeric.gt(s, 0) and numeric.lt(s, 1))
                    break;
            }

            const temp = numeric.sqrt(numeric.mul(-2, numeric.div(numeric.ln(s), s)));

            return numeric.add(self.mu, numeric.mul(self.sigma, numeric.mul(u, temp)));
        }

        /// Computes the Probability Density Function (PDF) evaluated at `x`.
        /// For complex types, this evaluates the joint probability density of
        /// the independent real and imaginary components.
        ///
        /// ## Arguments
        /// * `self` (`stats.Normal(Real)`): The normal distribution.
        /// * `x` (`Real`): The value at which to evaluate the density.
        ///
        /// ## Returns
        /// `Real`: The probability density at `x`.
        pub fn pdf(self: stats.Normal(Real), x: Real) Real {
            const z = numeric.div(numeric.sub(x, self.mu), self.sigma);

            return numeric.div(
                numeric.exp(numeric.neg(numeric.div(numeric.mul(z, z), 2))),
                numeric.mul(self.sigma, numeric.sqrt(numeric.tau(Real))),
            );
        }

        /// Computes the natural logarithm of the Probability Density Function
        /// (Log-PDF) evaluated at `x`. This is numerically much more stable
        /// than taking the log of `pdf(x)` for extreme values.
        ///
        /// ## Arguments
        /// * `self` (`stats.Normal(Real)`): The normal distribution.
        /// * `x` (`Real`): The value at which to evaluate the log-density.
        ///
        /// ## Returns
        /// `Real`: The log-probability density at `x`.
        pub fn lpdf(self: stats.Normal(Real), x: Real) Real {
            const z = numeric.div(numeric.sub(x, self.mu), self.sigma);

            return numeric.neg(
                numeric.add(
                    numeric.add(
                        numeric.ln(self.sigma),
                        numeric.div(numeric.ln(numeric.tau(Real)), 2),
                    ),
                    numeric.div(numeric.mul(z, z), 2),
                ),
            );
        }

        /// Computes the Cumulative Distribution Function (CDF) evaluated at
        /// `x`. Represents the probability that a random variable from this
        /// distribution is less than or equal to `x`. For complex types, this
        /// returns the joint cumulative probability of both real and imaginary
        /// components.
        ///
        /// ## Arguments
        /// * `self` (`stats.Normal(Real)`): The normal distribution.
        /// * `x` (`Real`): The upper bound to evaluate the cumulative
        ///   probability.
        ///
        /// ## Returns
        /// `Real`: The cumulative probability in the range [0, 1].
        pub fn cdf(self: stats.Normal(Real), x: Real) Real {
            return numeric.div(
                numeric.add(
                    1,
                    numeric.erf(
                        numeric.div(
                            numeric.sub(x, self.mu),
                            numeric.mul(self.sigma, numeric.sqrt(numeric.cast(Real, 2))),
                        ),
                    ),
                ),
                2,
            );
        }

        /// Computes the Inverse Cumulative Distribution Function (iCDF), also
        /// known as the quantile function or percent point function. Maps a
        /// probability `p` back to the corresponding value in the distribution
        /// domain.
        ///
        /// ## Arguments
        /// * `self` (`stats.Normal(Real)`): The normal distribution.
        /// * `p` (`Real`): The probability threshold. For real types, p must be
        ///   in (0, 1). For complex types, both p.re and p.im must be in (0, 1).
        ///
        /// ## Returns
        /// `Real`: The value `x` such that `cdf(x) == p`.
        pub fn icdf(self: stats.Normal(Real), p: Real) Real {
            return numeric.add(
                self.mu,
                numeric.mul(
                    self.sigma,
                    numeric.mul(
                        numeric.sqrt(numeric.cast(Real, 2)),
                        numeric.erfinv(numeric.sub(numeric.mul(2, p), 1)),
                    ),
                ),
            );
        }
    };
}
