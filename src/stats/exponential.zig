const std = @import("std");

const meta = @import("../meta.zig");

const numeric = @import("../numeric.zig");

const stats = @import("../stats.zig");

const utils = @import("utils.zig");

/// An exponential distribution that yields continuous waiting times of type
/// `Real`. The distribution is parameterized by a positive rate `lambda`, it
/// models the interval between independent events occurring continuously at a
/// constant average rate.
pub fn Exponential(comptime Real: type) type {
    comptime if (!meta.isNumeric(Real) or meta.isIntegral(Real) or !meta.isReal(Real))
        @compileError("zsl.stats.Exponential: Real must be a real non-integral numeric type, got \n\tReal = " ++ @typeName(Real) ++ "\n");

    return struct {
        lambda: Real,

        // Type signatures
        pub const is_distribution = true;

        /// Initializes a new exponential distribution.
        ///
        /// ## Arguments
        /// * `lambda` (`Real`): The rate parameter (must be positive non-zero).
        pub fn init(lambda: Real) stats.Exponential(Real) {
            return .{
                .lambda = lambda,
            };
        }

        /// Samples a random value from the exponential distribution using
        /// Inverse Transform Sampling.
        ///
        /// ## Arguments
        /// * `self` (`stats.Exponential(Real)`): The exponential distribution.
        /// * `prng` (`std.Random`): The standard random number generator.
        ///
        /// ## Returns
        /// `Real`: A random non-negative waiting time.
        pub fn sample(self: stats.Exponential(Real), prng: std.Random) Real {
            return numeric.div(
                numeric.neg(numeric.ln(numeric.sub(1, utils.standardUniform(Real, prng)))),
                self.lambda,
            );
        }

        /// Computes the Probability Density Function (PDF) evaluated at `x`.
        /// For complex types, evaluates the joint probability density of the
        /// independent real and imaginary components.
        ///
        /// ## Arguments
        /// * `self` (`stats.Exponential(Real)`): The exponential distribution.
        /// * `x` (`Real`): The value at which to evaluate the density.
        ///
        /// ## Returns
        /// `Real`: The probability density at `x`.
        pub fn pdf(self: stats.Exponential(Real), x: Real) Real {
            if (numeric.lt(x, 0))
                return numeric.cast(Real, 0);

            return numeric.mul(
                self.lambda,
                numeric.exp(numeric.neg(numeric.mul(self.lambda, x))),
            );
        }

        /// Computes the natural logarithm of the Probability Density Function
        /// (Log-PDF) evaluated at `x`. Recommended over `ln(pdf(x))` to prevent
        /// underflow for large waiting times.
        ///
        /// ## Arguments
        /// * `self` (`stats.Exponential(Real)`): The exponential distribution.
        /// * `x` (`Real`): The value at which to evaluate the log-density.
        ///
        /// ## Returns
        /// `Real`: The log-probability density at `x`.
        pub fn lpdf(self: stats.Exponential(Real), x: Real) Real {
            if (numeric.lt(x, 0))
                return numeric.neg(numeric.inf(Real));

            // lpdf(x) = ln(lambda) - lambda * x
            return numeric.sub(
                numeric.ln(self.lambda),
                numeric.mul(self.lambda, x),
            );
        }

        /// Computes the Cumulative Distribution Function (CDF) evaluated at
        /// `x`. Represents the probability that an event occurs within waiting
        /// time `x`.
        ///
        /// ## Arguments
        /// * `self` (`stats.Exponential(Real)`): The exponential distribution.
        /// * `x` (`Real`): The upper bound of the waiting time.
        ///
        /// ## Returns
        /// `Real`: The cumulative probability in the range [0, 1].
        pub fn cdf(self: stats.Exponential(Real), x: Real) Real {
            if (numeric.le(x, 0))
                return numeric.cast(Real, 0);

            // cdf(x) = 1 - e^(-lambda * x)
            return numeric.sub(1, numeric.exp(numeric.neg(numeric.mul(self.lambda, x))));
        }

        /// Computes the Inverse Cumulative Distribution Function (iCDF), or
        /// quantile function. Maps a probability threshold `p` to the
        /// corresponding waiting time `x`.
        ///
        /// ## Arguments
        /// * `self` (`stats.Exponential(Real)`): The exponential distribution.
        /// * `p` (`Real`): The probability threshold. Must be in [0, 1) for real
        ///   types, or have components in [0, 1) for complex types.
        ///
        /// ## Returns
        /// `Real`: The waiting time `x` such that `cdf(x) == p`.
        pub fn icdf(self: stats.Exponential(Real), p: Real) Real {
            if (numeric.le(p, 0))
                return numeric.cast(Real, 0);

            if (numeric.ge(p, 1))
                return numeric.inf(Real);

            // icdf(p) = -ln(1 - p) / lambda
            return numeric.div(numeric.neg(numeric.ln(numeric.sub(1, p))), self.lambda);
        }
    };
}
