/* -*- Mode: C -*- */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>

#define TPA_MAGIC "TPA"


/*

TODO:

- add support for more types

*/

struct tpa_vtbl {
    char magic[4];
    U32 element_size;
    void (*set)(pTHX_ void *, SV *);
    SV *(*get)(pTHX_ void *);
    char * packer;
};

void tpa_set_char(pTHX_ char *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

SV *tpa_get_char(pTHX_ char *ptr) {
    return newSViv(*ptr);
}


static struct tpa_vtbl vtbl_char = { TPA_MAGIC,
                                     sizeof(char),
                                     (void (*)(pTHX_ void*, SV*)) &tpa_set_char,
                                     (SV * (*)(pTHX_ void*)) &tpa_get_char,
                                     "c" };

void tpa_set_uchar(pTHX_ unsigned char *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

SV *tpa_get_uchar(pTHX_ unsigned char *ptr) {
    return newSVuv(*ptr);
}

static struct tpa_vtbl vtbl_uchar = { TPA_MAGIC,
                                      sizeof(unsigned char),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_uchar,
                                      (SV * (*)(pTHX_ void*)) &tpa_get_uchar,
                                      "C"};

void tpa_set_IV(pTHX_ IV *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

SV *tpa_get_IV(pTHX_ IV *ptr) {
    return newSViv(*ptr);
}

static struct tpa_vtbl vtbl_IV = { TPA_MAGIC,
                                   sizeof(IV),
                                   (void (*)(pTHX_ void*, SV*)) &tpa_set_IV,
                                   (SV * (*)(pTHX_ void*)) &tpa_get_IV,
                                   "i" };

void tpa_set_UV(pTHX_ UV *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

SV *tpa_get_UV(pTHX_ UV *ptr) {
    return newSVuv(*ptr);
}

static struct tpa_vtbl vtbl_UV = { TPA_MAGIC,
                                   sizeof(UV),
                                   (void (*)(pTHX_ void*, SV*)) &tpa_set_UV,
                                   (SV * (*)(pTHX_ void*)) &tpa_get_UV,
                                   "I" };

void tpa_set_NV(pTHX_ NV *ptr, SV *sv) {
    *ptr = SvNV(sv);
}

SV *tpa_get_NV(pTHX_ NV *ptr) {
    return newSVnv(*ptr);
}

static struct tpa_vtbl vtbl_NV = { TPA_MAGIC,
                                   sizeof(NV),
                                   (void (*)(pTHX_ void*, SV*)) &tpa_set_NV,
                                   (SV * (*)(pTHX_ void*)) &tpa_get_NV,
                                   "F" };

void tpa_set_double(pTHX_ double *ptr, SV *sv) {
    *ptr = SvNV(sv);
}

SV *tpa_get_double(pTHX_ double *ptr) {
    return newSVnv(*ptr);
}

static struct tpa_vtbl vtbl_double = { TPA_MAGIC,
                                       sizeof(double),
                                       (void (*)(pTHX_ void*, SV*)) &tpa_set_double,
                                       (SV * (*)(pTHX_ void*)) &tpa_get_double,
                                       "d" };

void tpa_set_float(pTHX_ float *ptr, SV *sv) {
    *ptr = SvNV(sv);
}

SV *tpa_get_float(pTHX_ float *ptr) {
    return newSVnv(*ptr);
}

static struct tpa_vtbl vtbl_float = { TPA_MAGIC,
                                      sizeof(float),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_float,
                                      (SV * (*)(pTHX_ void*)) &tpa_get_float,
                                      "f" };

void tpa_set_int_native(pTHX_ int *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

SV *tpa_get_int_native(pTHX_ int *ptr) {
    return newSViv(*ptr);
}

static struct tpa_vtbl vtbl_int_native = { TPA_MAGIC,
                                              sizeof(int),
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_int_native,
                                              (SV * (*)(pTHX_ void*)) &tpa_get_int_native,
                                              "i!" };

void tpa_set_short_native(pTHX_ short *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

SV *tpa_get_short_native(pTHX_ short *ptr) {
    return newSViv(*ptr);
}

static struct tpa_vtbl vtbl_short_native = { TPA_MAGIC,
                                              sizeof(short),
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_short_native,
                                              (SV * (*)(pTHX_ void*)) &tpa_get_short_native,
                                              "s!" };

void tpa_set_long_native(pTHX_ long *ptr, SV *sv) {
#if (IVSIZE >= LONGSIZE)
    *ptr = SvIV(sv);
#else
    if (SvIOK(sv))
        *ptr = SvIV(sv);
    else
        *ptr = SvNV(sv);
#endif
}

SV *tpa_get_long_native(pTHX_ long *ptr) {
#if (IVSIZE >= LONGSIZE)
    return newSViv(*ptr);
#else
    return newSVnv(*ptr);
#endif
}

static struct tpa_vtbl vtbl_long_native = { TPA_MAGIC,
                                            sizeof(long),
                                            (void (*)(pTHX_ void*, SV*)) &tpa_set_long_native,
                                            (SV * (*)(pTHX_ void*)) &tpa_get_long_native,
                                            "l!" };

void tpa_set_uint_native(pTHX_ unsigned int *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

SV *tpa_get_uint_native(pTHX_ unsigned int *ptr) {
    return newSVuv(*ptr);
}

static struct tpa_vtbl vtbl_uint_native = { TPA_MAGIC,
                                              sizeof(unsigned int),
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_uint_native,
                                              (SV * (*)(pTHX_ void*)) &tpa_get_uint_native,
                                              "S!" };

void tpa_set_ushort_native(pTHX_ unsigned short *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

SV *tpa_get_ushort_native(pTHX_ unsigned short *ptr) {
    return newSVuv(*ptr);
}

static struct tpa_vtbl vtbl_ushort_native = { TPA_MAGIC,
                                              sizeof(unsigned short),
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_ushort_native,
                                              (SV * (*)(pTHX_ void*)) &tpa_get_ushort_native,
                                              "S!" };

void tpa_set_ulong_native(pTHX_ unsigned long *ptr, SV *sv) {
#if (IVSIZE >= LONGSIZE)
    *ptr = SvUV(sv);
#else
    if (SvUOK(sv))
        *ptr = SvUV(sv);
    else
        *ptr = SvNV(sv);
#endif
}

SV *tpa_get_ulong_native(pTHX_ unsigned long *ptr) {
#if (IVSIZE >= LONGSIZE)
    return newSVuv(*ptr);
#else
    return newSVnv(*ptr);
#endif
}

static struct tpa_vtbl vtbl_ulong_native = { TPA_MAGIC,
                                             sizeof(unsigned long),
                                             (void (*)(pTHX_ void*, SV*)) &tpa_set_ulong_native,
                                             (SV * (*)(pTHX_ void*)) &tpa_get_ulong_native,
                                             "L!" };

#if defined(HAS_LONG_LONG) && LONGLONGSIZE == 8

void tpa_set_longlong_native(pTHX_ long long *ptr, SV *sv) {
#if IVSIZE >= LONGLONGSIZE
    *ptr = SvIV(sv);
#else
    if (SvIOK(sv))
        *ptr = SvIV(sv);
    else
        *ptr = SvNV(sv);
#endif
}

SV *tpa_get_longlong_native(pTHX_ long long *ptr) {
#if IVSIZE >= LONGLONGSIZE
    return newSViv(*ptr);
#else
    return newSVnv(*ptr);
#endif
}

static struct tpa_vtbl vtbl_longlong_native = { TPA_MAGIC,
                                                sizeof(long long),
                                                (void (*)(pTHX_ void*, SV*)) &tpa_set_longlong_native,
                                                (SV * (*)(pTHX_ void*)) &tpa_get_longlong_native,
                                                "q" };

void tpa_set_ulonglong_native(pTHX_ unsigned long long *ptr, SV *sv) {
#if IVSIZE >= LONGLONGSIZE
    *ptr = SvUV(sv);
#else
    if (SvUOK(sv))
        *ptr = SvUV(sv);
    else
        *ptr = SvNV(sv);
#endif
}

SV *tpa_get_ulonglong_native(pTHX_ unsigned long long *ptr) {
#if IVSIZE >= LONGLONGSIZE
    return newSVuv(*ptr);
#else
    return newSVnv(*ptr);
#endif
}

static struct tpa_vtbl vtbl_ulonglong_native = { TPA_MAGIC,
                                                 sizeof(unsigned long long),
                                                 (void (*)(pTHX_ void*, SV*)) &tpa_set_ulonglong_native,
                                                 (SV * (*)(pTHX_ void*)) &tpa_get_ulonglong_native,
                                                 "Q" };

#endif

#if ((BYTEORDER == 0x1234) && (SHORTSIZE == 2))

typedef unsigned short ushort_le;
#define tpa_set_ushort_le tpa_set_ushort_native
#define tpa_get_ushort_le tpa_get_ushort_native

#else

typedef unsigned char ushort_le[2];

void tpa_set_ushort_le(pTHX_ ushort_le *ptr, SV *sv) {
    UV v = SvUV(sv);
    ptr[0] = v;
    ptr[1] = v >> 8;
}

SV *tpa_get_ushort_le(pTHX_ ushort_le *ptr) {
    return newSVuv(ptr[1] << 8 + ptr[0] );
}

#endif

static struct tpa_vtbl vtbl_ushort_le = { TPA_MAGIC,
                                          sizeof(ushort_le),
                                          (void (*)(pTHX_ void*, SV*)) &tpa_set_ushort_le,
                                          (SV * (*)(pTHX_ void*)) &tpa_get_ushort_le,
                                          "v" };
#if ((BYTEORDER == 0x4321) && (SHORTSIZE == 2))

typedef unsigned short ushort_be;
#define tpa_set_ushort_be tpa_set_ushort_native
#define tpa_get_ushort_be tpa_get_ushort_native

#else

typedef unsigned char ushort_be[2];

void tpa_set_ushort_be(pTHX_ ushort_be *ptr, SV *sv) {
    UV v = SvUV(sv);
    (*ptr)[0] = v >> 8;
    (*ptr)[1] = v;
}

SV *tpa_get_ushort_be(pTHX_ ushort_be *ptr) {
    return newSVuv((*ptr)[0] << 8 + (*ptr)[1] );
}

#endif

static struct tpa_vtbl vtbl_ushort_be = { TPA_MAGIC,
                                          sizeof(ushort_be),
                                          (void (*)(pTHX_ void*, SV*)) &tpa_set_ushort_be,
                                          (SV * (*)(pTHX_ void*)) &tpa_get_ushort_be,
                                          "n" };

#if ((BYTEORDER == 0x1234) && (INTSIZE == 4))

typedef unsigned int ulong_le;
#define tpa_set_ulong_le tpa_set_uint_native
#define tpa_get_ulong_le tpa_get_uint_native

#elif ((BYTEORDER == 0x1234) && (LONGSIZE == 4))

typedef unsigned int ulong_le;
#define tpa_set_ulong_le tpa_set_ulong_native
#define tpa_get_ulong_le tpa_get_ulong_native

#else

typedef unsigned char ulong_le[4];

void tpa_set_ulong_le(pTHX_ ulong_le *ptr, SV *sv) {
    UV v = SvUV(sv);
    (*ptr)[0] = v;
    (*ptr)[1] = (v >>= 8);
    (*ptr)[2] = (v >>= 8);
    (*ptr)[3] = (v >>= 8);
}

SV *tpa_get_ulong_le(pTHX_ ulong_le *ptr) {
    return newSVuv((((*ptr)[3] << 8 + (*ptr)[2] ) << 8 + (*ptr)[1] ) << 8 + (*ptr)[0] );
}

#endif

static struct tpa_vtbl vtbl_ulong_le = { TPA_MAGIC,
                                      sizeof(ulong_le),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_ulong_le,
                                      (SV * (*)(pTHX_ void*)) &tpa_get_ulong_le,
                                      "V" };

#if ((BYTEORDER == 0x4321) && (INTSIZE == 4))

typedef unsigned int ulong_be;
#define tpa_set_ulong_be tpa_set_uint_native
#define tpa_get_ulong_be tpa_get_uint_native


#elif ((BYTEORDER == 0x4321) && (LONGSIZE == 4))

typedef unsigned long ulong_be;
#define tpa_set_ulong_be tpa_set_ulong_native
#define tpa_get_ulong_be tpa_get_ulong_native

#else

typedef unsigned char ulong_be[4];

void tpa_set_ulong_be(pTHX_ ulong_be *ptr, SV *sv) {
    UV v = SvUV(sv);
    (*ptr)[3] = v;
    (*ptr)[2] = (v >>= 8);
    (*ptr)[1] = (v >>= 8);
    (*ptr)[0] = (v >>= 8);
}

SV *tpa_get_ulong_be(pTHX_ ulong_be *ptr) {
    return newSVuv((((*ptr)[0] << 8 + (*ptr)[1] ) << 8 + (*ptr)[2] ) << 8 + (*ptr)[3] );
}

#endif

static struct tpa_vtbl vtbl_ulong_be = { TPA_MAGIC,
                                      sizeof(ulong_be),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_ulong_be,
                                      (SV * (*)(pTHX_ void*)) &tpa_get_ulong_be,
                                      "N" };



static struct tpa_vtbl *
data_vtbl(pTHX_ SV *sv) {
    if (sv) {
        MAGIC *mg = mg_find(sv, '~');
        if (mg && mg->mg_ptr && !strcmp(mg->mg_ptr, TPA_MAGIC))
            return (struct tpa_vtbl *)(mg->mg_ptr);
    }
    Perl_croak(aTHX_ "internal error");
}

static void
check_index(pTHX_ U32 ix, U32 esize) {
    U32 max = (~((U32)0))/esize;
    if ( max < ix )
        Perl_croak(aTHX_ "index %d is out of range", ix);
}

static char *
my_sv_unchop(pTHX_ SV *sv, STRLEN size) {
    STRLEN len;
    char *pv = SvPV(sv, len);
    IV off = SvOOK(sv) ? SvIVX(sv) : 0;
    if (!size)
        return pv;

    if (off >= size) {
        SvLEN_set(sv, SvLEN(sv) + size);
        SvCUR_set(sv, len + size);
        SvPV_set(sv, pv - size);
        if (off == size)
            SvFLAGS(sv) &= ~SVf_OOK;
        else
            SvIV_set(sv, off - size);
    }
    else if (len + size <= off + SvLEN(sv)) {
        if (off) {
            SvLEN_set(sv, SvLEN(sv) + off);
            SvFLAGS(sv) &= ~SVf_OOK;
        }
        SvCUR_set(sv, len + size);
        SvPV_set(sv, pv - off);
        Move(pv, pv + size - off, len, char);
    }
    else {
        SV *tmp = sv_2mortal(newSV(len + size));
        STRLEN tmp_len;
        char *tmp_pv;
        SvPOK_on(tmp);
        tmp_pv = SvPV(tmp, tmp_len);
        Move(pv, tmp_pv + size, len, char);
        SvCUR_set(tmp, size + len);
        sv_setsv(sv, tmp);
    }
    return SvPVX(sv);
}


MODULE = Tie::Array::Packed		PACKAGE = Tie::Array::Packed

SV *
TIEARRAY(klass, type, init)
    SV *klass;
    char *type;
    SV *init;
  CODE:
    {
        struct tpa_vtbl *vtbl = 0;
        if ( type[0] &&
             ( !type[1] ||
               ( type[1] == '!' && !type[2] ) ) )
        {
            switch(type[0]) {
            case 'c':
                vtbl = &vtbl_char;
                break;
            case 'C':
                vtbl = &vtbl_uchar;
                break;
            case 'i':
                if (type[1])
                    vtbl = &vtbl_int_native;
                else
                    vtbl = &vtbl_IV;
                break;
            case 'I':
                if (type[1])
                    vtbl = &vtbl_uint_native;
                else
                    vtbl = &vtbl_UV;
                break;
            case 'f':
                vtbl = &vtbl_float;
                break;
            case 'd':
                vtbl = &vtbl_double;
                break;
            case 'F':
                vtbl = &vtbl_NV;
                break;
            case 'n':
                vtbl = &vtbl_ushort_be;
                break;
            case 'N':
                vtbl = &vtbl_ulong_be;
                break;
            case 'v':
                vtbl = &vtbl_ushort_le;
                break;
            case 'V':
                vtbl = &vtbl_ulong_le;
                break;
            case 's':
                if (type[1])
                    vtbl = &vtbl_short_native;
                break;
            case 'S':
                if (type[1])
                    vtbl = &vtbl_ushort_native;
                break;
            case 'l':
                if (type[1])
                    vtbl = &vtbl_long_native;
                break;
            case 'L':
                if (type[1])
                    vtbl = &vtbl_ulong_native;
                break;
#if defined(HAS_LONG_LONG) && LONGLONGSIZE == 8
            case 'q':
                vtbl = &vtbl_longlong_native;
                break;
            case 'Q':
                vtbl = &vtbl_ulonglong_native;
                break;
#else
            case 'q':
            case 'Q':
                Perl_croak(aTHX_ "64bit %s packing not supported on this computer", type);
                break;
#endif
            }
        }
        if (!vtbl)
            Perl_croak(aTHX_ "invalid/unsupported packing type %s", type);
        else {
            STRLEN len;
            char *pv = SvPV(init, len);
            SV *data = newSVpvn(pv, len);
            RETVAL = newRV_noinc(data);
            if (SvOK(klass))
                sv_bless(RETVAL, gv_stashsv(klass, 1));
            sv_magic(data, 0, '~', (char *)vtbl, 0);
        }
    }
  OUTPUT:
    RETVAL

void
STORE(self, key, value)
    SV *self;
    U32 key;
    SV *value;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        STRLEN req = (key + 1) * esize;
        STRLEN len;
        char *pv = SvPV(data, len);

        check_index(aTHX_ key, esize);

        if (len < req) {
            pv = SvGROW(data, req);
            memset(pv + len, 0, req - len - esize);
            SvCUR_set(data, req);
        }
        (*(vtbl->set))(aTHX_ pv + req - esize, value);
    }

SV *
FETCH(self, key)
    SV *self;
    U32 key;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        STRLEN req = (key + 1) * esize;
        STRLEN len;
        char *pv = SvPV(data, len);
        if (len < req)
            RETVAL = &PL_sv_undef;
        else
            RETVAL = (*(vtbl->get))(aTHX_ pv + req - esize);
    }
  OUTPUT:
    RETVAL

U32
FETCHSIZE(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        RETVAL = SvCUR(data) / esize;
    }
  OUTPUT:
    RETVAL

void
STORESIZE(self, size)
    SV *self;
    U32 size;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        STRLEN req = size * esize;
        STRLEN len;
        char *pv = SvPV(data, len);

        check_index(aTHX_ size, esize);

        if (len < req) {
            pv = SvGROW(data, req);
            memset(pv + len, 0, req - len);
        }
        SvCUR_set(data, req);
    }

void
EXTEND(self, size)
    SV *self;
    U32 size;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        STRLEN req = size * esize;
        
        check_index(aTHX_ size, esize);
        
        SvGROW(data, req);
    }

SV *
EXISTS(self, key)
    SV *self;
    U32 key;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        RETVAL = ((SvCUR(data) / esize) > key) ? &PL_sv_yes : &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
DELETE(self, key)
    SV *self;
    U32 key;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        STRLEN req = (key + 1) * esize;
        STRLEN len;
        char *pv = SvPV(data, len);

        check_index(aTHX_ key, esize);

        if (len >= req) {
            RETVAL = (*(vtbl->get))(aTHX_ pv + req - esize);
            memset(pv + req - esize, 0, esize);
        }
        else
            RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

void
CLEAR(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        SvCUR_set(data, 0);
    }

void
PUSH(self, ...)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        U32 key = len / esize;
        STRLEN req = (key + items - 1) * esize;
        U32 i;

        check_index(aTHX_ key + items - 1, esize);

        pv = SvGROW(data, req);
        SvCUR_set(data, req);

        for (i = 1; i < items; i++)
            (*(vtbl->set))(aTHX_ pv + (key + i - 1) * esize, ST(i));
    }

SV *
POP(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        U32 size = len / esize;
        if (size) {
            STRLEN new_len = (size - 1) * esize;
            RETVAL = (*(vtbl->get))(aTHX_ pv + new_len);
            SvCUR_set(data, new_len);
        }
        else
            RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
SHIFT(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        U32 size = len / esize;
        if (size) {
            RETVAL = (*(vtbl->get))(aTHX_ pv);
            sv_chop(data, pv + esize);
        }
        else
            RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

void
UNSHIFT(self, ...)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        if (items > 1) {
            U32 esize = vtbl->element_size;
            char *pv;
            U32 i;

            check_index(aTHX_ SvCUR(data) / esize + items - 1, esize);

            pv = my_sv_unchop(aTHX_ data, esize * (items - 1));
            for (i = 1; i < items; i++, pv += esize) {
                (*(vtbl->set))(aTHX_ pv, ST(i));
            }
        }
    }

void
SPLICE(self, offset, length, ...)
    SV *self;
    U32 offset;
    U32 length;
  PPCODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        U32 esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        U32 size = len / esize;
        U32 i;
        U32 rep = items - 3;

        if (offset > size)
            offset = size;

        if (offset + length > size)
            length = size - offset;

        check_index(aTHX_ offset + items - 3 - length, esize);
        
        switch (GIMME_V) {
        case G_ARRAY:
            EXTEND(SP, items + length);
            for (i = 0; i < length; i++)
                ST(items + i) = sv_2mortal((*(vtbl->get))(aTHX_ pv + (offset + i) * esize));
            break;
        case G_SCALAR:
            if  (length)
                ST(0) = sv_2mortal((*(vtbl->get))(aTHX_ pv + (offset + length - 1) * esize));
            else
                ST(0) = &PL_sv_undef;
        }
        
        if (rep != length) {
            if (offset == 0) {
                if (length)
                    sv_chop(data, pv + length * esize);
                if (rep) {
                    pv = my_sv_unchop(aTHX_ data, rep * esize);
                }
            }
            else {
                pv = SvGROW(data, (size + rep - length) * esize);
                SvCUR_set(data, (size - length + rep) * esize);
                if (offset + length < size)
                    Move(pv + (offset + length) * esize,
                         pv + (offset + rep) * esize,
                         (size - offset - length) * esize, char);
            }
        }
        for (i = 0; i < rep; i++)
            (*(vtbl->set))(aTHX_ pv + (offset + i) * esize, ST(i + 3));

        switch(GIMME_V) {
        case G_ARRAY:
            for (i = 0; i< length; i++)
                ST(i) = ST(items + i);
            XSRETURN(length);
        case G_SCALAR:
            XSRETURN(1);
        default:
            XSRETURN_EMPTY;
        }
    }

char *
packer(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        RETVAL = vtbl->packer;
    }
  OUTPUT:
    RETVAL
