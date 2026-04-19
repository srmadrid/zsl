const cblas = @This();

const types = @import("../types.zig");

pub const Layout = enum(c_int) {
    row_major = 101,
    col_major = 102,

    fn toZsl(self: cblas.Layout) types.Layout {
        return switch (self) {
            .row_major => .row_major,
            .col_major => .col_major,
        };
    }
};

pub const Transpose = enum(c_int) {
    no_trans = 111,
    trans = 112,
    conj_trans = 113,
    conj_no_trans = 114,
};

pub const Uplo = enum(c_int) {
    upper = 121,
    lower = 122,

    fn toZsl(self: Uplo) types.Uplo {
        return switch (self) {
            .upper => .upper,
            .lower => .lower,
        };
    }
};

pub const Diag = enum(c_int) {
    non_unit = 131,
    unit = 132,

    fn toZsl(self: Diag) types.Diag {
        return switch (self) {
            .non_unit => .non_unit,
            .unit => .unit,
        };
    }
};

pub const Side = enum(c_int) {
    left = 141,
    right = 142,
};

// Level 1
extern fn cblas_sasum(n: i64, x: [*c]const f32, incx: i64) f32;
extern fn cblas_dasum(n: i64, x: [*c]const f64, incx: i64) f64;
extern fn cblas_scasum(n: i64, x: *const anyopaque, incx: i64) f32;
extern fn cblas_dzasum(n: i64, x: *const anyopaque, incx: i64) f64;
pub const sasum = cblas_sasum;
pub const dasum = cblas_dasum;
pub const scasum = cblas_scasum;
pub const dzasum = cblas_dzasum;

extern fn cblas_saxpy(n: i64, alpha: f32, x: [*c]const f32, incx: i64, y: [*c]f32, incy: i64) void;
extern fn cblas_daxpy(n: i64, alpha: f64, x: [*c]const f64, incx: i64, y: [*c]f64, incy: i64) void;
extern fn cblas_caxpy(n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *anyopaque, incy: i64) void;
extern fn cblas_zaxpy(n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *anyopaque, incy: i64) void;
pub const saxpy = cblas_saxpy;
pub const daxpy = cblas_daxpy;
pub const caxpy = cblas_caxpy;
pub const zaxpy = cblas_zaxpy;

extern fn cblas_scopy(n: i64, x: [*c]const f32, incx: i64, y: [*c]f32, incy: i64) void;
extern fn cblas_dcopy(n: i64, x: [*c]const f64, incx: i64, y: [*c]f64, incy: i64) void;
extern fn cblas_ccopy(n: i64, x: *const anyopaque, incx: i64, y: *anyopaque, incy: i64) void;
extern fn cblas_zcopy(n: i64, x: *const anyopaque, incx: i64, y: *anyopaque, incy: i64) void;
pub const scopy = cblas_scopy;
pub const dcopy = cblas_dcopy;
pub const ccopy = cblas_ccopy;
pub const zcopy = cblas_zcopy;

extern fn cblas_sdot(n: i64, x: [*c]const f32, incx: i64, y: [*c]const f32, incy: i64) f32;
extern fn cblas_ddot(n: i64, x: [*c]const f64, incx: i64, y: [*c]const f64, incy: i64) f64;
pub const sdot = cblas_sdot;
pub const ddot = cblas_ddot;

extern fn cblas_cdotc_sub(n: i64, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, dotc: *anyopaque) void;
extern fn cblas_zdotc_sub(n: i64, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, dotc: *anyopaque) void;
extern fn cblas_cdotu_sub(n: i64, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, dotu: *anyopaque) void;
extern fn cblas_zdotu_sub(n: i64, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, dotu: *anyopaque) void;
pub const cdotc_sub = cblas_cdotc_sub;
pub const zdotc_sub = cblas_zdotc_sub;
pub const cdotu_sub = cblas_cdotu_sub;
pub const zdotu_sub = cblas_zdotu_sub;

extern fn cblas_snrm2(n: i64, x: [*c]const f32, incx: i64) f32;
extern fn cblas_dnrm2(n: i64, x: [*c]const f64, incx: i64) f64;
extern fn cblas_scnrm2(n: i64, x: *const anyopaque, incx: i64) f32;
extern fn cblas_dznrm2(n: i64, x: *const anyopaque, incx: i64) f64;
pub const snrm2 = cblas_snrm2;
pub const dnrm2 = cblas_dnrm2;
pub const scnrm2 = cblas_scnrm2;
pub const dznrm2 = cblas_dznrm2;

extern fn cblas_srot(n: i64, x: [*c]f32, incx: i64, y: [*c]f32, incy: i64, c: f32, s: f32) void;
extern fn cblas_drot(n: i64, x: [*c]f64, incx: i64, y: [*c]f64, incy: i64, c: f64, s: f64) void;
extern fn cblas_csrot(n: i64, x: *anyopaque, incx: i64, y: *anyopaque, incy: i64, c: f32, s: f32) void;
extern fn cblas_zdrot(n: i64, x: *anyopaque, incx: i64, y: *anyopaque, incy: i64, c: f64, s: f64) void;
pub const srot = cblas_srot;
pub const drot = cblas_drot;
pub const csrot = cblas_csrot;
pub const zdrot = cblas_zdrot;

extern fn cblas_srotg(a: *f32, b: *f32, c: *f32, s: *f32) void;
extern fn cblas_drotg(a: *f64, b: *f64, c: *f64, s: *f64) void;
extern fn cblas_crotg(a: *anyopaque, b: *anyopaque, c: *f32, s: *anyopaque) void;
extern fn cblas_zrotg(a: *anyopaque, b: *anyopaque, c: *f64, s: *anyopaque) void;
pub const srotg = cblas_srotg;
pub const drotg = cblas_drotg;
pub const crotg = cblas_crotg;
pub const zrotg = cblas_zrotg;

extern fn cblas_srotm(n: i64, x: [*c]f32, incx: i64, y: [*c]f32, incy: i64, param: [*c]const f32) void;
extern fn cblas_drotm(n: i64, x: [*c]f64, incx: i64, y: [*c]f64, incy: i64, param: [*c]const f64) void;
pub const srotm = cblas_srotm;
pub const drotm = cblas_drotm;

extern fn cblas_srotmg(d1: *f32, d2: *f32, x1: *f32, y1: f32, param: [*c]f32) void;
extern fn cblas_drotmg(d1: *f64, d2: *f64, x1: *f64, y1: f64, param: [*c]f64) void;
pub const srotmg = cblas_srotmg;
pub const drotmg = cblas_drotmg;

extern fn cblas_sscal(n: i64, alpha: f32, x: [*c]f32, incx: i64) void;
extern fn cblas_dscal(n: i64, alpha: f64, x: [*c]f64, incx: i64) void;
extern fn cblas_cscal(n: i64, alpha: *const anyopaque, x: *anyopaque, incx: i64) void;
extern fn cblas_zscal(n: i64, alpha: *const anyopaque, x: *anyopaque, incx: i64) void;
extern fn cblas_csscal(n: i64, alpha: f32, x: *anyopaque, incx: i64) void;
extern fn cblas_zdscal(n: i64, alpha: f64, x: *anyopaque, incx: i64) void;
pub const sscal = cblas_sscal;
pub const dscal = cblas_dscal;
pub const cscal = cblas_cscal;
pub const zscal = cblas_zscal;
pub const csscal = cblas_csscal;
pub const zdscal = cblas_zdscal;

extern fn cblas_sswap(n: i64, x: [*c]f32, incx: i64, y: [*c]f32, incy: i64) void;
extern fn cblas_dswap(n: i64, x: [*c]f64, incx: i64, y: [*c]f64, incy: i64) void;
extern fn cblas_cswap(n: i64, x: *anyopaque, incx: i64, y: *anyopaque, incy: i64) void;
extern fn cblas_zswap(n: i64, x: *anyopaque, incx: i64, y: *anyopaque, incy: i64) void;
pub const sswap = cblas_sswap;
pub const dswap = cblas_dswap;
pub const cswap = cblas_cswap;
pub const zswap = cblas_zswap;

extern fn cblas_isamax(n: i64, x: [*c]const f32, incx: i64) i64;
extern fn cblas_idamax(n: i64, x: [*c]const f64, incx: i64) i64;
extern fn cblas_icamax(n: i64, x: *const anyopaque, incx: i64) i64;
extern fn cblas_izamax(n: i64, x: *const anyopaque, incx: i64) i64;
pub const isamax = cblas_isamax;
pub const idamax = cblas_idamax;
pub const icamax = cblas_icamax;
pub const izamax = cblas_izamax;

extern fn cblas_isamin(n: i64, x: [*c]const f32, incx: i64) i64;
extern fn cblas_idamin(n: i64, x: [*c]const f64, incx: i64) i64;
extern fn cblas_icamin(n: i64, x: *const anyopaque, incx: i64) i64;
extern fn cblas_izamin(n: i64, x: *const anyopaque, incx: i64) i64;
pub const isamin = cblas_isamin;
pub const idamin = cblas_idamin;
pub const icamin = cblas_icamin;
pub const izamin = cblas_izamin;

// Level 2
extern fn cblas_sgbmv(layout: Layout, transa: Transpose, m: i64, n: i64, kl: i64, ku: i64, alpha: f32, a: [*c]const f32, lda: i64, x: [*c]const f32, incx: i64, beta: f32, y: [*c]f32, incy: i64) void;
extern fn cblas_dgbmv(layout: Layout, transa: Transpose, m: i64, n: i64, kl: i64, ku: i64, alpha: f64, a: [*c]const f64, lda: i64, x: [*c]const f64, incx: i64, beta: f64, y: [*c]f64, incy: i64) void;
extern fn cblas_cgbmv(layout: Layout, transa: Transpose, m: i64, n: i64, kl: i64, ku: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
extern fn cblas_zgbmv(layout: Layout, transa: Transpose, m: i64, n: i64, kl: i64, ku: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
pub const sgbmv = cblas_sgbmv;
pub const dgbmv = cblas_dgbmv;
pub const cgbmv = cblas_cgbmv;
pub const zgbmv = cblas_zgbmv;

extern fn cblas_sgemv(layout: Layout, transa: Transpose, m: i64, n: i64, alpha: f32, a: [*c]const f32, lda: i64, x: [*c]const f32, incx: i64, beta: f32, y: [*c]f32, incy: i64) void;
extern fn cblas_dgemv(layout: Layout, transa: Transpose, m: i64, n: i64, alpha: f64, a: [*c]const f64, lda: i64, x: [*c]const f64, incx: i64, beta: f64, y: [*c]f64, incy: i64) void;
extern fn cblas_cgemv(layout: Layout, transa: Transpose, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
extern fn cblas_zgemv(layout: Layout, transa: Transpose, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
pub const sgemv = cblas_sgemv;
pub const dgemv = cblas_dgemv;
pub const cgemv = cblas_cgemv;
pub const zgemv = cblas_zgemv;

extern fn cblas_sger(layout: Layout, m: i64, n: i64, alpha: f32, x: [*c]const f32, incx: i64, y: [*c]const f32, incy: i64, a: [*c]f32, lda: i64) void;
extern fn cblas_dger(layout: Layout, m: i64, n: i64, alpha: f64, x: [*c]const f64, incx: i64, y: [*c]const f64, incy: i64, a: [*c]f64, lda: i64) void;
extern fn cblas_cgeru(layout: Layout, m: i64, n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, a: *anyopaque, lda: i64) void;
extern fn cblas_zgeru(layout: Layout, m: i64, n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, a: *anyopaque, lda: i64) void;
extern fn cblas_cgerc(layout: Layout, m: i64, n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, a: *anyopaque, lda: i64) void;
extern fn cblas_zgerc(layout: Layout, m: i64, n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, a: *anyopaque, lda: i64) void;
pub const sger = cblas_sger;
pub const dger = cblas_dger;
pub const cgeru = cblas_cgeru;
pub const zgeru = cblas_zgeru;
pub const cgerc = cblas_cgerc;
pub const zgerc = cblas_zgerc;

extern fn cblas_chbmv(layout: Layout, uplo: Uplo, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
extern fn cblas_zhbmv(layout: Layout, uplo: Uplo, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
pub const chbmv = cblas_chbmv;
pub const zhbmv = cblas_zhbmv;

extern fn cblas_chemv(layout: Layout, uplo: Uplo, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
extern fn cblas_zhemv(layout: Layout, uplo: Uplo, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
pub const chemv = cblas_chemv;
pub const zhemv = cblas_zhemv;

extern fn cblas_cher(layout: Layout, uplo: Uplo, n: i64, alpha: f32, x: *const anyopaque, incx: i64, a: *anyopaque, lda: i64) void;
extern fn cblas_zher(layout: Layout, uplo: Uplo, n: i64, alpha: f64, x: *const anyopaque, incx: i64, a: *anyopaque, lda: i64) void;
pub const cher = cblas_cher;
pub const zher = cblas_zher;

extern fn cblas_cher2(layout: Layout, uplo: Uplo, n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, a: *anyopaque, lda: i64) void;
extern fn cblas_zher2(layout: Layout, uplo: Uplo, n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, a: *anyopaque, lda: i64) void;
pub const cher2 = cblas_cher2;
pub const zher2 = cblas_zher2;

extern fn cblas_chpmv(layout: Layout, uplo: Uplo, n: i64, alpha: *const anyopaque, ap: *const anyopaque, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
extern fn cblas_zhpmv(layout: Layout, uplo: Uplo, n: i64, alpha: *const anyopaque, ap: *const anyopaque, x: *const anyopaque, incx: i64, beta: *const anyopaque, y: *anyopaque, incy: i64) void;
pub const chpmv = cblas_chpmv;
pub const zhpmv = cblas_zhpmv;

extern fn cblas_chpr(layout: Layout, uplo: Uplo, n: i64, alpha: f32, x: *const anyopaque, incx: i64, ap: *anyopaque) void;
extern fn cblas_zhpr(layout: Layout, uplo: Uplo, n: i64, alpha: f64, x: *const anyopaque, incx: i64, ap: *anyopaque) void;
pub const chpr = cblas_chpr;
pub const zhpr = cblas_zhpr;

extern fn cblas_chpr2(layout: Layout, uplo: Uplo, n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, ap: *anyopaque) void;
extern fn cblas_zhpr2(layout: Layout, uplo: Uplo, n: i64, alpha: *const anyopaque, x: *const anyopaque, incx: i64, y: *const anyopaque, incy: i64, ap: *anyopaque) void;
pub const chpr2 = cblas_chpr2;
pub const zhpr2 = cblas_zhpr2;

extern fn cblas_ssbmv(layout: Layout, uplo: Uplo, n: i64, k: i64, alpha: f32, a: [*c]const f32, lda: i64, x: [*c]const f32, incx: i64, beta: f32, y: [*c]f32, incy: i64) void;
extern fn cblas_dsbmv(layout: Layout, uplo: Uplo, n: i64, k: i64, alpha: f64, a: [*c]const f64, lda: i64, x: [*c]const f64, incx: i64, beta: f64, y: [*c]f64, incy: i64) void;
pub const ssbmv = cblas_ssbmv;
pub const dsbmv = cblas_dsbmv;

extern fn cblas_sspmv(layout: Layout, uplo: Uplo, n: i64, alpha: f32, ap: [*c]const f32, x: [*c]const f32, incx: i64, beta: f32, y: [*c]f32, incy: i64) void;
extern fn cblas_dspmv(layout: Layout, uplo: Uplo, n: i64, alpha: f64, ap: [*c]const f64, x: [*c]const f64, incx: i64, beta: f64, y: [*c]f64, incy: i64) void;
pub const sspmv = cblas_sspmv;
pub const dspmv = cblas_dspmv;

extern fn cblas_sspr(layout: Layout, uplo: Uplo, n: i64, alpha: f32, x: [*c]const f32, incx: i64, ap: [*c]f32) void;
extern fn cblas_dspr(layout: Layout, uplo: Uplo, n: i64, alpha: f64, x: [*c]const f64, incx: i64, ap: [*c]f64) void;
pub const sspr = cblas_sspr;
pub const dspr = cblas_dspr;

extern fn cblas_sspr2(layout: Layout, uplo: Uplo, n: i64, alpha: f32, x: [*c]const f32, incx: i64, y: [*c]const f32, incy: i64, ap: [*c]f32) void;
extern fn cblas_dspr2(layout: Layout, uplo: Uplo, n: i64, alpha: f64, x: [*c]const f64, incx: i64, y: [*c]const f64, incy: i64, ap: [*c]f64) void;
pub const sspr2 = cblas_sspr2;
pub const dspr2 = cblas_dspr2;

extern fn cblas_ssymv(layout: Layout, uplo: Uplo, n: i64, alpha: f32, a: [*c]const f32, lda: i64, x: [*c]const f32, incx: i64, beta: f32, y: [*c]f32, incy: i64) void;
extern fn cblas_dsymv(layout: Layout, uplo: Uplo, n: i64, alpha: f64, a: [*c]const f64, lda: i64, x: [*c]const f64, incx: i64, beta: f64, y: [*c]f64, incy: i64) void;
pub const ssymv = cblas_ssymv;
pub const dsymv = cblas_dsymv;

extern fn cblas_ssyr(layout: Layout, uplo: Uplo, n: i64, alpha: f32, x: [*c]const f32, incx: i64, a: [*c]f32, lda: i64) void;
extern fn cblas_dsyr(layout: Layout, uplo: Uplo, n: i64, alpha: f64, x: [*c]const f64, incx: i64, a: [*c]f64, lda: i64) void;
pub const ssyr = cblas_ssyr;
pub const dsyr = cblas_dsyr;

extern fn cblas_ssyr2(layout: Layout, uplo: Uplo, n: i64, alpha: f32, x: [*c]const f32, incx: i64, y: [*c]const f32, incy: i64, a: [*c]f32, lda: i64) void;
extern fn cblas_dsyr2(layout: Layout, uplo: Uplo, n: i64, alpha: f64, x: [*c]const f64, incx: i64, y: [*c]const f64, incy: i64, a: [*c]f64, lda: i64) void;
pub const ssyr2 = cblas_ssyr2;
pub const dsyr2 = cblas_dsyr2;

extern fn cblas_stbmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, k: i64, a: [*c]const f32, lda: i64, x: [*c]f32, incx: i64) void;
extern fn cblas_dtbmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, k: i64, a: [*c]const f64, lda: i64, x: [*c]f64, incx: i64) void;
extern fn cblas_ctbmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, k: i64, a: *const anyopaque, lda: i64, x: *anyopaque, incx: i64) void;
extern fn cblas_ztbmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, k: i64, a: *const anyopaque, lda: i64, x: *anyopaque, incx: i64) void;
pub const stbmv = cblas_stbmv;
pub const dtbmv = cblas_dtbmv;
pub const ctbmv = cblas_ctbmv;
pub const ztbmv = cblas_ztbmv;

extern fn cblas_stbsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, k: i64, a: [*c]const f32, lda: i64, x: [*c]f32, incx: i64) void;
extern fn cblas_dtbsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, k: i64, a: [*c]const f64, lda: i64, x: [*c]f64, incx: i64) void;
extern fn cblas_ctbsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, k: i64, a: *const anyopaque, lda: i64, x: *anyopaque, incx: i64) void;
extern fn cblas_ztbsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, k: i64, a: *const anyopaque, lda: i64, x: *anyopaque, incx: i64) void;
pub const stbsv = cblas_stbsv;
pub const dtbsv = cblas_dtbsv;
pub const ctbsv = cblas_ctbsv;
pub const ztbsv = cblas_ztbsv;

extern fn cblas_stpmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, ap: [*c]const f32, x: [*c]f32, incx: i64) void;
extern fn cblas_dtpmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, ap: [*c]const f64, x: [*c]f64, incx: i64) void;
extern fn cblas_ctpmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, ap: *const anyopaque, x: *anyopaque, incx: i64) void;
extern fn cblas_ztpmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, ap: *const anyopaque, x: *anyopaque, incx: i64) void;
pub const stpmv = cblas_stpmv;
pub const dtpmv = cblas_dtpmv;
pub const ctpmv = cblas_ctpmv;
pub const ztpmv = cblas_ztpmv;

extern fn cblas_stpsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, ap: [*c]const f32, x: [*c]f32, incx: i64) void;
extern fn cblas_dtpsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, ap: [*c]const f64, x: [*c]f64, incx: i64) void;
extern fn cblas_ctpsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, ap: *const anyopaque, x: *anyopaque, incx: i64) void;
extern fn cblas_ztpsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, ap: *const anyopaque, x: *anyopaque, incx: i64) void;
pub const stpsv = cblas_stpsv;
pub const dtpsv = cblas_dtpsv;
pub const ctpsv = cblas_ctpsv;
pub const ztpsv = cblas_ztpsv;

extern fn cblas_strmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, a: [*c]const f32, lda: i64, x: [*c]f32, incx: i64) void;
extern fn cblas_dtrmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, a: [*c]const f64, lda: i64, x: [*c]f64, incx: i64) void;
extern fn cblas_ctrmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, a: *const anyopaque, lda: i64, x: *anyopaque, incx: i64) void;
extern fn cblas_ztrmv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, a: *const anyopaque, lda: i64, x: *anyopaque, incx: i64) void;
pub const strmv = cblas_strmv;
pub const dtrmv = cblas_dtrmv;
pub const ctrmv = cblas_ctrmv;
pub const ztrmv = cblas_ztrmv;

extern fn cblas_strsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, a: [*c]const f32, lda: i64, x: [*c]f32, incx: i64) void;
extern fn cblas_dtrsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, a: [*c]const f64, lda: i64, x: [*c]f64, incx: i64) void;
extern fn cblas_ctrsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, a: *const anyopaque, lda: i64, x: *anyopaque, incx: i64) void;
extern fn cblas_ztrsv(layout: Layout, uplo: Uplo, transa: Transpose, diag: Diag, n: i64, a: *const anyopaque, lda: i64, x: *anyopaque, incx: i64) void;
pub const strsv = cblas_strsv;
pub const dtrsv = cblas_dtrsv;
pub const ctrsv = cblas_ctrsv;
pub const ztrsv = cblas_ztrsv;

// Level 3
extern fn cblas_sgemm(layout: Layout, transa: Transpose, transb: Transpose, m: i64, n: i64, k: i64, alpha: f32, a: [*c]const f32, lda: i64, b: [*c]const f32, ldb: i64, beta: f32, c: [*c]f32, ldc: i64) void;
extern fn cblas_dgemm(layout: Layout, transa: Transpose, transb: Transpose, m: i64, n: i64, k: i64, alpha: f64, a: [*c]const f64, lda: i64, b: [*c]const f64, ldb: i64, beta: f64, c: [*c]f64, ldc: i64) void;
extern fn cblas_cgemm(layout: Layout, transa: Transpose, transb: Transpose, m: i64, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
extern fn cblas_zgemm(layout: Layout, transa: Transpose, transb: Transpose, m: i64, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
pub const sgemm = cblas_sgemm;
pub const dgemm = cblas_dgemm;
pub const cgemm = cblas_cgemm;
pub const zgemm = cblas_zgemm;

extern fn cblas_chemm(layout: Layout, side: Side, uplo: Uplo, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
extern fn cblas_zhemm(layout: Layout, side: Side, uplo: Uplo, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
pub const chemm = cblas_chemm;
pub const zhemm = cblas_zhemm;

extern fn cblas_cherk(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: f32, a: *const anyopaque, lda: i64, beta: f32, c: *anyopaque, ldc: i64) void;
extern fn cblas_zherk(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: f64, a: *const anyopaque, lda: i64, beta: f64, c: *anyopaque, ldc: i64) void;
pub const cherk = cblas_cherk;
pub const zherk = cblas_zherk;

extern fn cblas_cher2k(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: f32, c: *anyopaque, ldc: i64) void;
extern fn cblas_zher2k(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: f64, c: *anyopaque, ldc: i64) void;
pub const cher2k = cblas_cher2k;
pub const zher2k = cblas_zher2k;

extern fn cblas_ssymm(layout: Layout, side: Side, uplo: Uplo, m: i64, n: i64, alpha: f32, a: [*c]const f32, lda: i64, b: [*c]const f32, ldb: i64, beta: f32, c: [*c]f32, ldc: i64) void;
extern fn cblas_dsymm(layout: Layout, side: Side, uplo: Uplo, m: i64, n: i64, alpha: f64, a: [*c]const f64, lda: i64, b: [*c]const f64, ldb: i64, beta: f64, c: [*c]f64, ldc: i64) void;
extern fn cblas_csymm(layout: Layout, side: Side, uplo: Uplo, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
extern fn cblas_zsymm(layout: Layout, side: Side, uplo: Uplo, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
pub const ssymm = cblas_ssymm;
pub const dsymm = cblas_dsymm;
pub const csymm = cblas_csymm;
pub const zsymm = cblas_zsymm;

extern fn cblas_ssyrk(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: f32, a: [*c]const f32, lda: i64, beta: f32, c: [*c]f32, ldc: i64) void;
extern fn cblas_dsyrk(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: f64, a: [*c]const f64, lda: i64, beta: f64, c: [*c]f64, ldc: i64) void;
extern fn cblas_csyrk(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
extern fn cblas_zsyrk(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
pub const ssyrk = cblas_ssyrk;
pub const dsyrk = cblas_dsyrk;
pub const csyrk = cblas_csyrk;
pub const zsyrk = cblas_zsyrk;

extern fn cblas_ssyr2k(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: f32, a: [*c]const f32, lda: i64, b: [*c]const f32, ldb: i64, beta: f32, c: [*c]f32, ldc: i64) void;
extern fn cblas_dsyr2k(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: f64, a: [*c]const f64, lda: i64, b: [*c]const f64, ldb: i64, beta: f64, c: [*c]f64, ldc: i64) void;
extern fn cblas_csyr2k(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
extern fn cblas_zsyr2k(layout: Layout, uplo: Uplo, trans: Transpose, n: i64, k: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *const anyopaque, ldb: i64, beta: *const anyopaque, c: *anyopaque, ldc: i64) void;
pub const ssyr2k = cblas_ssyr2k;
pub const dsyr2k = cblas_dsyr2k;
pub const csyr2k = cblas_csyr2k;
pub const zsyr2k = cblas_zsyr2k;

extern fn cblas_strmm(layout: Layout, side: Side, uplo: Uplo, transa: Transpose, diag: Diag, m: i64, n: i64, alpha: f32, a: [*c]const f32, lda: i64, b: [*c]f32, ldb: i64) void;
extern fn cblas_dtrmm(layout: Layout, side: Side, uplo: Uplo, transa: Transpose, diag: Diag, m: i64, n: i64, alpha: f64, a: [*c]const f64, lda: i64, b: [*c]f64, ldb: i64) void;
extern fn cblas_ctrmm(layout: Layout, side: Side, uplo: Uplo, transa: Transpose, diag: Diag, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *anyopaque, ldb: i64) void;
extern fn cblas_ztrmm(layout: Layout, side: Side, uplo: Uplo, transa: Transpose, diag: Diag, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *anyopaque, ldb: i64) void;
pub const strmm = cblas_strmm;
pub const dtrmm = cblas_dtrmm;
pub const ctrmm = cblas_ctrmm;
pub const ztrmm = cblas_ztrmm;

extern fn cblas_strsm(layout: Layout, side: Side, uplo: Uplo, transa: Transpose, diag: Diag, m: i64, n: i64, alpha: f32, a: [*c]const f32, lda: i64, b: [*c]f32, ldb: i64) void;
extern fn cblas_dtrsm(layout: Layout, side: Side, uplo: Uplo, transa: Transpose, diag: Diag, m: i64, n: i64, alpha: f64, a: [*c]const f64, lda: i64, b: [*c]f64, ldb: i64) void;
extern fn cblas_ctrsm(layout: Layout, side: Side, uplo: Uplo, transa: Transpose, diag: Diag, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *anyopaque, ldb: i64) void;
extern fn cblas_ztrsm(layout: Layout, side: Side, uplo: Uplo, transa: Transpose, diag: Diag, m: i64, n: i64, alpha: *const anyopaque, a: *const anyopaque, lda: i64, b: *anyopaque, ldb: i64) void;
pub const strsm = cblas_strsm;
pub const dtrsm = cblas_dtrsm;
pub const ctrsm = cblas_ctrsm;
pub const ztrsm = cblas_ztrsm;
