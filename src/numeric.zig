//! Namespace for numeric types and operations.

// Utilities
pub const Coerce = @import("numeric/coerce.zig").Coerce;
pub const cast = @import("numeric/cast.zig").cast;
pub const set = @import("numeric/set.zig").set;
pub const isNan = @import("numeric/isNan.zig").isNan;

// Constants
pub const highest = @import("numeric/highest.zig").highest;
pub const lowest = @import("numeric/lowest.zig").lowest;
pub const smallest = @import("numeric/smallest.zig").smallest;
pub const eps = @import("numeric/eps.zig").eps;
pub const inf = @import("numeric/inf.zig").inf;
pub const nan = @import("numeric/nan.zig").nan;
pub const pi = @import("numeric/pi.zig").pi;
pub const tau = @import("numeric/tau.zig").tau;
pub const e = @import("numeric/e.zig").e;
pub const phi = @import("numeric/phi.zig").phi;
pub const egamma = @import("numeric/egamma.zig").egamma;
pub const catalan = @import("numeric/catalan.zig").catalan;
pub const apery = @import("numeric/apery.zig").apery;

// Basic operations
pub const Abs = @import("numeric/abs.zig").Abs;
pub const abs = @import("numeric/abs.zig").abs;
pub const absInto = @import("numeric/abs.zig").absInto;
pub const Abs1 = @import("numeric/abs1.zig").Abs1;
pub const abs1 = @import("numeric/abs1.zig").abs1;
pub const abs1Into = @import("numeric/abs1.zig").abs1Into;
pub const Abs2 = @import("numeric/abs2.zig").Abs2;
pub const abs2 = @import("numeric/abs2.zig").abs2;
pub const abs2Into = @import("numeric/abs2.zig").abs2Into;
pub const Neg = @import("numeric/neg.zig").Neg;
pub const neg = @import("numeric/neg.zig").neg;
pub const negInto = @import("numeric/neg.zig").negInto;
pub const Re = @import("numeric/re.zig").Re;
pub const re = @import("numeric/re.zig").re;
pub const Im = @import("numeric/im.zig").Im;
pub const im = @import("numeric/im.zig").im;
pub const Conj = @import("numeric/conj.zig").Conj;
pub const conj = @import("numeric/conj.zig").conj;
pub const conjInto = @import("numeric/conj.zig").conjInto;
pub const Sign = @import("numeric/sign.zig").Sign;
pub const sign = @import("numeric/sign.zig").sign;
// pub const copysign = num@import("numeric/ops.zig").copysign;

// Arithmetic operations
pub const Add = @import("numeric/add.zig").Add;
pub const add = @import("numeric/add.zig").add;
pub const addInto = @import("numeric/add.zig").addInto;
pub const Sub = @import("numeric/sub.zig").Sub;
pub const sub = @import("numeric/sub.zig").sub;
pub const subInto = @import("numeric/sub.zig").subInto;
pub const Mul = @import("numeric/mul.zig").Mul;
pub const mul = @import("numeric/mul.zig").mul;
pub const mulInto = @import("numeric/mul.zig").mulInto;
pub const Fma = @import("numeric/fma.zig").Fma;
pub const fma = @import("numeric/fma.zig").fma;
pub const fmaInto = @import("numeric/fma.zig").fmaInto;
pub const Div = @import("numeric/div.zig").Div;
pub const div = @import("numeric/div.zig").div;
pub const divInto = @import("numeric/div.zig").divInto;

// Comparison operations
// pub const order = @import("numeric/ops.zig").order;
pub const eq = @import("numeric/eq.zig").eq;
pub const ne = @import("numeric/ne.zig").ne;
pub const lt = @import("numeric/lt.zig").lt;
pub const le = @import("numeric/le.zig").le;
pub const gt = @import("numeric/gt.zig").gt;
pub const ge = @import("numeric/ge.zig").ge;
pub const Max = @import("numeric/max.zig").Max;
pub const max = @import("numeric/max.zig").max;
pub const maxInto = @import("numeric/max.zig").maxInto;
pub const Min = @import("numeric/min.zig").Min;
pub const min = @import("numeric/min.zig").min;
pub const minInto = @import("numeric/min.zig").minInto;

// Exponential functions
pub const Exp = @import("numeric/exp.zig").Exp;
pub const exp = @import("numeric/exp.zig").exp;
pub const expInto = @import("numeric/exp.zig").expInto;
pub const Ln = @import("numeric/ln.zig").Ln;
pub const ln = @import("numeric/ln.zig").ln;
pub const lnInto = @import("numeric/ln.zig").lnInto;
// pub const Log = num@import("numeric/ops.zig").Log;
// pub const log = num@import("numeric/ops.zig").log;
// pub const logInto = num@import("numeric/ops.zig").logInto;

// Power functions
pub const Pow = @import("numeric/pow.zig").Pow;
pub const pow = @import("numeric/pow.zig").pow;
pub const powInto = @import("numeric/pow.zig").powInto;
pub const Sqrt = @import("numeric/sqrt.zig").Sqrt;
pub const sqrt = @import("numeric/sqrt.zig").sqrt;
pub const sqrtInto = @import("numeric/sqrt.zig").sqrtInto;
pub const Cbrt = @import("numeric/cbrt.zig").Cbrt;
pub const cbrt = @import("numeric/cbrt.zig").cbrt;
pub const cbrtInto = @import("numeric/cbrt.zig").cbrtInto;
pub const Hypot = @import("numeric/hypot.zig").Hypot;
pub const hypot = @import("numeric/hypot.zig").hypot;
pub const hypotInto = @import("numeric/hypot.zig").hypotInto;

// Trigonometric functions
pub const Sin = @import("numeric/sin.zig").Sin;
pub const sin = @import("numeric/sin.zig").sin;
pub const sinInto = @import("numeric/sin.zig").sinInto;
pub const Cos = @import("numeric/cos.zig").Cos;
pub const cos = @import("numeric/cos.zig").cos;
pub const cosInto = @import("numeric/cos.zig").cosInto;
pub const Tan = @import("numeric/tan.zig").Tan;
pub const tan = @import("numeric/tan.zig").tan;
pub const tanInto = @import("numeric/tan.zig").tanInto;
pub const Asin = @import("numeric/asin.zig").Asin;
pub const asin = @import("numeric/asin.zig").asin;
pub const asinInto = @import("numeric/asin.zig").asinInto;
pub const Acos = @import("numeric/acos.zig").Acos;
pub const acos = @import("numeric/acos.zig").acos;
pub const acosInto = @import("numeric/acos.zig").acosInto;
pub const Atan = @import("numeric/atan.zig").Atan;
pub const atan = @import("numeric/atan.zig").atan;
pub const atanInto = @import("numeric/atan.zig").atanInto;
pub const Atan2 = @import("numeric/atan2.zig").Atan2;
pub const atan2 = @import("numeric/atan2.zig").atan2;
pub const atan2Into = @import("numeric/atan2.zig").atan2Into;

// Hyperbolic functions
pub const Sinh = @import("numeric/sinh.zig").Sinh;
pub const sinh = @import("numeric/sinh.zig").sinh;
pub const sinhInto = @import("numeric/sinh.zig").sinhInto;
pub const Cosh = @import("numeric/cosh.zig").Cosh;
pub const cosh = @import("numeric/cosh.zig").cosh;
pub const coshInto = @import("numeric/cosh.zig").coshInto;
pub const Tanh = @import("numeric/tanh.zig").Tanh;
pub const tanh = @import("numeric/tanh.zig").tanh;
pub const tanhInto = @import("numeric/tanh.zig").tanhInto;
pub const Asinh = @import("numeric/asinh.zig").Asinh;
pub const asinh = @import("numeric/asinh.zig").asinh;
pub const asinhInto = @import("numeric/asinh.zig").asinhInto;
pub const Acosh = @import("numeric/acosh.zig").Acosh;
pub const acosh = @import("numeric/acosh.zig").acosh;
pub const acoshInto = @import("numeric/acosh.zig").acoshInto;
pub const Atanh = @import("numeric/atanh.zig").Atanh;
pub const atanh = @import("numeric/atanh.zig").atanh;
pub const atanhInto = @import("numeric/atanh.zig").atanhInto;

// Special functions
pub const Erf = @import("numeric/erf.zig").Erf;
pub const erf = @import("numeric/erf.zig").erf;
pub const erfInto = @import("numeric/erf.zig").erfInto;
pub const Erfc = @import("numeric/erfc.zig").Erfc;
pub const erfc = @import("numeric/erfc.zig").erfc;
pub const erfcInto = @import("numeric/erfc.zig").erfcInto;
pub const Gamma = @import("numeric/gamma.zig").Gamma;
pub const gamma = @import("numeric/gamma.zig").gamma;
pub const gammaInto = @import("numeric/gamma.zig").gammaInto;
pub const Lgamma = @import("numeric/lgamma.zig").Lgamma;
pub const lgamma = @import("numeric/lgamma.zig").lgamma;
pub const lgammaInto = @import("numeric/lgamma.zig").lgammaInto;
