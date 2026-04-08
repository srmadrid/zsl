pub const Shape = packed struct {
    mantissa: u112,
    exponent: u15,
    sign: u1,

    pub fn fromFloat(x: f128) Shape {
        return @bitCast(x);
    }

    pub fn toFloat(self: Shape) f128 {
        return @bitCast(self);
    }
};

pub fn getMantissa(x: f128) u112 {
    const tmp: Shape = @bitCast(x);
    return tmp.mantissa;
}

pub fn getExponent(x: f128) u15 {
    const tmp: Shape = @bitCast(x);
    return tmp.exponent;
}

pub fn getSign(x: f128) u1 {
    const tmp: Shape = @bitCast(x);
    return tmp.sign;
}

pub fn setMantissa(x: *f128, v: u112) void {
    var tmp: Shape = @bitCast(x.*);
    tmp.mantissa = v;
    x.* = @bitCast(tmp);
}

pub fn setExponent(x: *f128, v: u15) void {
    var tmp: Shape = @bitCast(x.*);
    tmp.exponent = v;
    x.* = @bitCast(tmp);
}

pub fn setSign(x: *f128, v: u1) void {
    var tmp: Shape = @bitCast(x.*);
    tmp.sign = v;
    x.* = @bitCast(tmp);
}

pub const ShapeSplit = packed struct {
    mantissa_low: u64,
    mantissa_high: u48,
    exponent: u15,
    sign: u1,

    pub fn fromFloat(x: f128) ShapeSplit {
        return @bitCast(x);
    }

    pub fn toFloat(self: ShapeSplit) f128 {
        return @bitCast(self);
    }
};

pub fn getMantissaHigh(x: f128) u64 {
    const tmp: ShapeSplit = @bitCast(x);
    return tmp.mantissa_high;
}

pub fn getMantissaLow(x: f128) u48 {
    const tmp: ShapeSplit = @bitCast(x);
    return tmp.mantissa_low;
}

pub const Parts32 = packed struct {
    lswlo: u32,
    lswhi: u32,
    mswlo: u32,
    mswhi: u32,

    pub fn fromFloat(x: f128) Parts32 {
        return @bitCast(x);
    }

    pub fn toFloat(self: Parts32) f128 {
        return @bitCast(self);
    }
};

pub fn getHighHighPart(x: f128) u32 {
    const tmp: Parts32 = @bitCast(x);
    return tmp.mswhi;
}

pub fn getHighLowPart(x: f128) u32 {
    const tmp: Parts32 = @bitCast(x);
    return tmp.mswlo;
}

pub fn getLowHighPart(x: f128) u32 {
    const tmp: Parts32 = @bitCast(x);
    return tmp.lswhi;
}

pub fn getLowLowPart(x: f128) u32 {
    const tmp: Parts32 = @bitCast(x);
    return tmp.lswlo;
}

pub fn setHighHighPart(x: *f128, v: u32) void {
    var tmp: Parts32 = @bitCast(x.*);
    tmp.mswhi = v;
    x.* = @bitCast(tmp);
}

pub fn setHighLowPart(x: *f128, v: u32) void {
    var tmp: Parts32 = @bitCast(x.*);
    tmp.mswlo = v;
    x.* = @bitCast(tmp);
}

pub fn setLowHighPart(x: *f128, v: u32) void {
    var tmp: Parts32 = @bitCast(x.*);
    tmp.lswhi = v;
    x.* = @bitCast(tmp);
}

pub fn setLowLowPart(x: *f128, v: u32) void {
    var tmp: Parts32 = @bitCast(x.*);
    tmp.lswlo = v;
    x.* = @bitCast(tmp);
}

pub const Parts64 = packed struct {
    lsw: u64,
    msw: u64,

    pub fn fromFloat(x: f128) Parts64 {
        return @bitCast(x);
    }

    pub fn toFloat(self: Parts64) f128 {
        return @bitCast(self);
    }
};

pub fn getHighPart(x: f128) u64 {
    const tmp: Parts64 = @bitCast(x);
    return tmp.msw;
}

pub fn getLowPart(x: f128) u64 {
    const tmp: Parts64 = @bitCast(x);
    return tmp.lsw;
}

pub fn setHighPart(x: *f128, v: u64) void {
    var tmp: Parts64 = @bitCast(x.*);
    tmp.msw = v;
    x.* = @bitCast(tmp);
}

pub fn setLowPart(x: *f128, v: u64) void {
    var tmp: Parts64 = @bitCast(x.*);
    tmp.lsw = v;
    x.* = @bitCast(tmp);
}
