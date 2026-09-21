//! Namespace for numeric types and operations.

// Utilities
pub const Coerce = @import("numeric/ops.zig").Coerce;
pub const cast = @import("numeric/ops.zig").cast;
pub const set = @import("numeric/ops.zig").set;
pub const bitSize = @import("numeric/ops.zig").bitSize;
pub const isZero = @import("numeric/ops.zig").isZero;
pub const isInf = @import("numeric/ops.zig").isInf;
pub const isNan = @import("numeric/ops.zig").isNan;
// isPositive

// Constants
pub const highest = @import("numeric/constants.zig").highest;
pub const lowest = @import("numeric/constants.zig").lowest;
pub const smallest = @import("numeric/constants.zig").smallest;
pub const eps = @import("numeric/constants.zig").eps;
pub const inf = @import("numeric/constants.zig").inf;
pub const nan = @import("numeric/constants.zig").nan;
pub const pi = @import("numeric/constants.zig").pi;
pub const tau = @import("numeric/constants.zig").tau;
pub const e = @import("numeric/constants.zig").e;
pub const phi = @import("numeric/constants.zig").phi;
pub const egamma = @import("numeric/constants.zig").egamma;
pub const catalan = @import("numeric/constants.zig").catalan;
pub const apery = @import("numeric/constants.zig").apery;

// Basic operations
pub const Abs = @import("numeric/ops.zig").Abs;
pub const abs = @import("numeric/ops.zig").abs;
pub const absInto = @import("numeric/ops.zig").absInto;
pub const Abs1 = @import("numeric/ops.zig").Abs1;
pub const abs1 = @import("numeric/ops.zig").abs1;
pub const abs1Into = @import("numeric/ops.zig").abs1Into;
pub const Abs2 = @import("numeric/ops.zig").Abs2;
pub const abs2 = @import("numeric/ops.zig").abs2;
pub const abs2Into = @import("numeric/ops.zig").abs2Into;
pub const Neg = @import("numeric/ops.zig").Neg;
pub const neg = @import("numeric/ops.zig").neg;
pub const negInto = @import("numeric/ops.zig").negInto;
pub const Re = @import("numeric/ops.zig").Re;
pub const re = @import("numeric/ops.zig").re;
pub const Im = @import("numeric/ops.zig").Im;
pub const im = @import("numeric/ops.zig").im;
pub const Conj = @import("numeric/ops.zig").Conj;
pub const conj = @import("numeric/ops.zig").conj;
pub const conjInto = @import("numeric/ops.zig").conjInto;
pub const Sign = @import("numeric/ops.zig").Sign;
pub const sign = @import("numeric/ops.zig").sign;
// pub const copysign = num@import("numeric/ops.zig").copysign;

// Rounding functions
pub const Floor = @import("numeric/ops.zig").Floor;
pub const floor = @import("numeric/ops.zig").floor;
pub const floorInto = @import("numeric/ops.zig").floorInto;
pub const Ceil = @import("numeric/ops.zig").Ceil;
pub const ceil = @import("numeric/ops.zig").ceil;
pub const ceilInto = @import("numeric/ops.zig").ceilInto;
pub const Trunc = @import("numeric/ops.zig").Trunc;
pub const trunc = @import("numeric/ops.zig").trunc;
pub const truncInto = @import("numeric/ops.zig").truncInto;
pub const Round = @import("numeric/ops.zig").Round;
pub const round = @import("numeric/ops.zig").round;
pub const roundInto = @import("numeric/ops.zig").roundInto;

// Arithmetic operations
pub const Add = @import("numeric/ops.zig").Add;
pub const add = @import("numeric/ops.zig").add;
pub const addInto = @import("numeric/ops.zig").addInto;
pub const Sub = @import("numeric/ops.zig").Sub;
pub const sub = @import("numeric/ops.zig").sub;
pub const subInto = @import("numeric/ops.zig").subInto;
pub const Mul = @import("numeric/ops.zig").Mul;
pub const mul = @import("numeric/ops.zig").mul;
pub const mulInto = @import("numeric/ops.zig").mulInto;
pub const Fma = @import("numeric/ops.zig").Fma;
pub const fma = @import("numeric/ops.zig").fma;
pub const fmaInto = @import("numeric/ops.zig").fmaInto;
pub const Div = @import("numeric/ops.zig").Div;
pub const div = @import("numeric/ops.zig").div;
pub const divInto = @import("numeric/ops.zig").divInto;

// Comparison operations
pub const order = @import("numeric/ops.zig").order;
pub const eq = @import("numeric/ops.zig").eq;
pub const ne = @import("numeric/ops.zig").ne;
pub const lt = @import("numeric/ops.zig").lt;
pub const le = @import("numeric/ops.zig").le;
pub const gt = @import("numeric/ops.zig").gt;
pub const ge = @import("numeric/ops.zig").ge;
pub const Max = @import("numeric/ops.zig").Max;
pub const max = @import("numeric/ops.zig").max;
pub const maxInto = @import("numeric/ops.zig").maxInto;
pub const Min = @import("numeric/ops.zig").Min;
pub const min = @import("numeric/ops.zig").min;
pub const minInto = @import("numeric/ops.zig").minInto;

// Exponential functions
pub const Exp = @import("numeric/ops.zig").Exp; // From here
pub const exp = @import("numeric/ops.zig").exp;
pub const expInto = @import("numeric/ops.zig").expInto;
pub const Ln = @import("numeric/ops.zig").Ln;
pub const ln = @import("numeric/ops.zig").ln;
pub const lnInto = @import("numeric/ops.zig").lnInto;
// pub const Log = num@import("numeric/ops.zig").Log;
// pub const log = num@import("numeric/ops.zig").log;
// pub const logInto = num@import("numeric/ops.zig").logInto;

// Power functions
pub const Pow = @import("numeric/ops.zig").Pow;
pub const pow = @import("numeric/ops.zig").pow;
pub const powInto = @import("numeric/ops.zig").powInto;
pub const Scale2 = @import("numeric/ops.zig").Scale2;
pub const scale2 = @import("numeric/ops.zig").scale2;
pub const scale2Into = @import("numeric/ops.zig").scale2Into;
pub const Sqrt = @import("numeric/ops.zig").Sqrt;
pub const sqrt = @import("numeric/ops.zig").sqrt;
pub const sqrtInto = @import("numeric/ops.zig").sqrtInto;
pub const Cbrt = @import("numeric/ops.zig").Cbrt;
pub const cbrt = @import("numeric/ops.zig").cbrt;
pub const cbrtInto = @import("numeric/ops.zig").cbrtInto;
pub const Hypot = @import("numeric/ops.zig").Hypot;
pub const hypot = @import("numeric/ops.zig").hypot;
pub const hypotInto = @import("numeric/ops.zig").hypotInto;

// Trigonometric functions
pub const Sin = @import("numeric/ops.zig").Sin;
pub const sin = @import("numeric/ops.zig").sin;
pub const sinInto = @import("numeric/ops.zig").sinInto;
pub const Cos = @import("numeric/ops.zig").Cos;
pub const cos = @import("numeric/ops.zig").cos;
pub const cosInto = @import("numeric/ops.zig").cosInto;
pub const Tan = @import("numeric/ops.zig").Tan;
pub const tan = @import("numeric/ops.zig").tan;
pub const tanInto = @import("numeric/ops.zig").tanInto;
pub const Asin = @import("numeric/ops.zig").Asin;
pub const asin = @import("numeric/ops.zig").asin;
pub const asinInto = @import("numeric/ops.zig").asinInto;
pub const Acos = @import("numeric/ops.zig").Acos;
pub const acos = @import("numeric/ops.zig").acos;
pub const acosInto = @import("numeric/ops.zig").acosInto;
pub const Atan = @import("numeric/ops.zig").Atan;
pub const atan = @import("numeric/ops.zig").atan;
pub const atanInto = @import("numeric/ops.zig").atanInto;
pub const Atan2 = @import("numeric/ops.zig").Atan2;
pub const atan2 = @import("numeric/ops.zig").atan2;
pub const atan2Into = @import("numeric/ops.zig").atan2Into;

// Hyperbolic functions
pub const Sinh = @import("numeric/ops.zig").Sinh;
pub const sinh = @import("numeric/ops.zig").sinh;
pub const sinhInto = @import("numeric/ops.zig").sinhInto;
pub const Cosh = @import("numeric/ops.zig").Cosh;
pub const cosh = @import("numeric/ops.zig").cosh;
pub const coshInto = @import("numeric/ops.zig").coshInto;
pub const Tanh = @import("numeric/ops.zig").Tanh;
pub const tanh = @import("numeric/ops.zig").tanh;
pub const tanhInto = @import("numeric/ops.zig").tanhInto;
pub const Asinh = @import("numeric/ops.zig").Asinh;
pub const asinh = @import("numeric/ops.zig").asinh;
pub const asinhInto = @import("numeric/ops.zig").asinhInto;
pub const Acosh = @import("numeric/ops.zig").Acosh;
pub const acosh = @import("numeric/ops.zig").acosh;
pub const acoshInto = @import("numeric/ops.zig").acoshInto;
pub const Atanh = @import("numeric/ops.zig").Atanh;
pub const atanh = @import("numeric/ops.zig").atanh;
pub const atanhInto = @import("numeric/ops.zig").atanhInto;

// Special functions
pub const Erf = @import("numeric/ops.zig").Erf;
pub const erf = @import("numeric/ops.zig").erf;
pub const erfInto = @import("numeric/ops.zig").erfInto;
pub const Erfc = @import("numeric/ops.zig").Erfc;
pub const erfc = @import("numeric/ops.zig").erfc;
pub const erfcInto = @import("numeric/ops.zig").erfcInto;
pub const Gamma = @import("numeric/ops.zig").Gamma;
pub const gamma = @import("numeric/ops.zig").gamma;
pub const gammaInto = @import("numeric/ops.zig").gammaInto;
pub const Lgamma = @import("numeric/ops.zig").Lgamma;
pub const lgamma = @import("numeric/ops.zig").lgamma;
pub const lgammaInto = @import("numeric/ops.zig").lgammaInto;
