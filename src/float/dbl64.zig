pub const Shape = packed struct {
    mantissa: u52,
    exponent: u11,
    sign: u1,

    pub fn fromFloat(x: f64) Shape {
        return @bitCast(x);
    }

    pub fn toFloat(self: Shape) f64 {
        return @bitCast(self);
    }
};

pub fn getMantissa(x: f64) u52 {
    const tmp: Shape = @bitCast(x);
    return tmp.mantissa;
}

pub fn getExponent(x: f64) u11 {
    const tmp: Shape = @bitCast(x);
    return tmp.exponent;
}

pub fn getSign(x: f64) u1 {
    const tmp: Shape = @bitCast(x);
    return tmp.sign;
}

pub fn setMantissa(x: *f64, v: u52) void {
    var tmp: Shape = @bitCast(x.*);
    tmp.mantissa = v;
    x.* = @bitCast(tmp);
}

pub fn setExponent(x: *f64, v: u11) void {
    var tmp: Shape = @bitCast(x.*);
    tmp.exponent = v;
    x.* = @bitCast(tmp);
}

pub fn setSign(x: *f64, v: u1) void {
    var tmp: Shape = @bitCast(x.*);
    tmp.sign = v;
    x.* = @bitCast(tmp);
}

pub const Parts = packed struct {
    lsw: u32,
    msw: u32,

    pub fn fromFloat(x: f64) Parts {
        return @bitCast(x);
    }

    pub fn toFloat(self: Parts) f64 {
        return @bitCast(self);
    }
};

pub fn getHighPart(x: f64) u32 {
    const tmp: Parts = @bitCast(x);
    return tmp.msw;
}

pub fn getLowPart(x: f64) u32 {
    const tmp: Parts = @bitCast(x);
    return tmp.lsw;
}

pub fn setHighPart(x: *f64, v: u32) void {
    var tmp: Parts = @bitCast(x.*);
    tmp.msw = v;
    x.* = @bitCast(tmp);
}

pub fn setLowPart(x: *f64, v: u32) void {
    var tmp: Parts = @bitCast(x.*);
    tmp.lsw = v;
    x.* = @bitCast(tmp);
}

pub fn setFromParts(x: *f64, msw: u32, lsw: u32) void {
    const tmp: Parts = .{ .msw = msw, .lsw = lsw };
    x.* = @bitCast(tmp);
}
