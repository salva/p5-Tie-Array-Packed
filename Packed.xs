/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>
#include <limits.h>

#define TPA_MAGIC "TPA"

#define RESERVE_BEFORE ((((size) >> 3) + 8) * (esize))
#define RESERVE_AFTER ((((size) >> 2) + 8) * (esize))

#define MySvGROW(sv, req) (SvLEN(sv) < (req) ? sv_grow((sv), (req) + RESERVE_AFTER ) : SvPVX(sv))

/*

TODO:

- add support for more types

*/

struct tpa_vtbl {
    char magic[4];
    UV element_size;
    void (*set)(pTHX_ void *, SV *);
    void (*get)(pTHX_ void *, SV *);
    char * packer;
};

void tpa_set_char(pTHX_ char *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

void tpa_get_char(pTHX_ char *ptr, SV *sv) {
    sv_setiv(sv, *ptr);
}

static struct tpa_vtbl vtbl_char = { TPA_MAGIC,
                                     sizeof(char),
                                     (void (*)(pTHX_ void*, SV*)) &tpa_set_char,
                                     (void (*)(pTHX_ void*, SV*)) &tpa_get_char,
                                     "c" };

void tpa_set_uchar(pTHX_ unsigned char *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

void tpa_get_uchar(pTHX_ unsigned char *ptr, SV *sv) {
    sv_setuv(sv, *ptr);
}

static struct tpa_vtbl vtbl_uchar = { TPA_MAGIC,
                                      sizeof(unsigned char),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_uchar,
                                      (void (*)(pTHX_ void*, SV*)) &tpa_get_uchar,
                                      "C"};

void tpa_set_IV(pTHX_ IV *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

void tpa_get_IV(pTHX_ IV *ptr, SV *sv) {
    sv_setiv(sv, *ptr);
}

static struct tpa_vtbl vtbl_IV = { TPA_MAGIC,
                                   sizeof(IV),
                                   (void (*)(pTHX_ void*, SV*)) &tpa_set_IV,
                                   (void (*)(pTHX_ void*, SV*)) &tpa_get_IV,
                                   "i" };

void tpa_set_UV(pTHX_ UV *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

void tpa_get_UV(pTHX_ UV *ptr, SV *sv) {
    sv_setuv(sv, *ptr);
}

static struct tpa_vtbl vtbl_UV = { TPA_MAGIC,
                                   sizeof(UV),
                                   (void (*)(pTHX_ void*, SV*)) &tpa_set_UV,
                                   (void (*)(pTHX_ void*, SV*)) &tpa_get_UV,
                                   "I" };

void tpa_set_NV(pTHX_ NV *ptr, SV *sv) {
    *ptr = SvNV(sv);
}

void tpa_get_NV(pTHX_ NV *ptr, SV *sv) {
    sv_setnv(sv, *ptr);
}

static struct tpa_vtbl vtbl_NV = { TPA_MAGIC,
                                   sizeof(NV),
                                   (void (*)(pTHX_ void*, SV*)) &tpa_set_NV,
                                   (void (*)(pTHX_ void*, SV*)) &tpa_get_NV,
                                   "F" };

void tpa_set_double(pTHX_ double *ptr, SV *sv) {
    *ptr = SvNV(sv);
}

tpa_get_double(pTHX_ double *ptr, SV *sv) {
    sv_setnv(sv, *ptr);
}

static struct tpa_vtbl vtbl_double = { TPA_MAGIC,
                                       sizeof(double),
                                       (void (*)(pTHX_ void*, SV*)) &tpa_set_double,
                                       (void (*)(pTHX_ void*, SV*)) &tpa_get_double,
                                       "d" };

void tpa_set_float(pTHX_ float *ptr, SV *sv) {
    *ptr = SvNV(sv);
}

void tpa_get_float(pTHX_ float *ptr, SV *sv) {
    sv_setnv(sv, *ptr);
}

static struct tpa_vtbl vtbl_float = { TPA_MAGIC,
                                      sizeof(float),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_float,
                                      (void (*)(pTHX_ void*, SV*)) &tpa_get_float,
                                      "f" };

void tpa_set_int_native(pTHX_ int *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

void tpa_get_int_native(pTHX_ int *ptr, SV *sv) {
    sv_setiv(sv, *ptr);
}

static struct tpa_vtbl vtbl_int_native = { TPA_MAGIC,
                                              sizeof(int),
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_int_native,
                                              (void (*)(pTHX_ void*, SV*)) &tpa_get_int_native,
                                              "i!" };

void tpa_set_short_native(pTHX_ short *ptr, SV *sv) {
    *ptr = SvIV(sv);
}

void tpa_get_short_native(pTHX_ short *ptr, SV *sv) {
    sv_setiv(sv, *ptr);
}

static struct tpa_vtbl vtbl_short_native = { TPA_MAGIC,
                                              sizeof(short),
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_short_native,
                                              (void (*)(pTHX_ void*, SV*)) &tpa_get_short_native,
                                              "s!" };

void tpa_set_long_native(pTHX_ long *ptr, SV *sv) {
#if (IVSIZE >= LONGSIZE)
    *ptr = SvIV(sv);
#else
    if (SvIOK(sv)) {
        if (SvIOK_UV(sv))
            *ptr = SvUV(sv);
        else
            *ptr = SvIV(sv);
    }
    else
        *ptr = SvNV(sv);
#endif
}

void tpa_get_long_native(pTHX_ long *ptr, SV *sv) {
#if (IVSIZE >= LONGSIZE)
    sv_setiv(sv, *ptr);
#else
    sv_setnv(sv, *ptr);
#endif
}

static struct tpa_vtbl vtbl_long_native = { TPA_MAGIC,
                                            sizeof(long),
                                            (void (*)(pTHX_ void*, SV*)) &tpa_set_long_native,
                                            (void (*)(pTHX_ void*, SV*)) &tpa_get_long_native,
                                            "l!" };

void tpa_set_uint_native(pTHX_ unsigned int *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

void tpa_get_uint_native(pTHX_ unsigned int *ptr, SV *sv) {
    sv_setuv(sv, *ptr);
}

static struct tpa_vtbl vtbl_uint_native = { TPA_MAGIC,
                                              sizeof(unsigned int),
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_uint_native,
                                              (void (*)(pTHX_ void*, SV*)) &tpa_get_uint_native,
                                              "S!" };

void tpa_set_ushort_native(pTHX_ unsigned short *ptr, SV *sv) {
    *ptr = SvUV(sv);
}

void tpa_get_ushort_native(pTHX_ unsigned short *ptr, SV *sv) {
    sv_setuv(sv, *ptr);
}

static struct tpa_vtbl vtbl_ushort_native = { TPA_MAGIC,
                                              sizeof(unsigned short),
                                              (void (*)(pTHX_ void*, SV*)) &tpa_set_ushort_native,
                                              (void (*)(pTHX_ void*, SV*)) &tpa_get_ushort_native,
                                              "S!" };

void tpa_set_ulong_native(pTHX_ unsigned long *ptr, SV *sv) {
#if (IVSIZE >= LONGSIZE)
    *ptr = SvUV(sv);
#else
    if (SvIOK(sv) && !SvIOK_notUV(sv))
        *ptr = SvNV(sv);
    else
        *ptr = SvUV(sv);
#endif
}

void tpa_get_ulong_native(pTHX_ unsigned long *ptr, SV *sv) {
#if (IVSIZE >= LONGSIZE)
    sv_setuv(sv, *ptr);
#else
    sv_setnv(sv, *ptr);
#endif
}

static struct tpa_vtbl vtbl_ulong_native = { TPA_MAGIC,
                                             sizeof(unsigned long),
                                             (void (*)(pTHX_ void*, SV*)) &tpa_set_ulong_native,
                                             (void (*)(pTHX_ void*, SV*)) &tpa_get_ulong_native,
                                             "L!" };

#if defined(HAS_LONG_LONG) && LONGLONGSIZE == 8

void tpa_set_longlong_native(pTHX_ long long *ptr, SV *sv) {
#if IVSIZE >= LONGLONGSIZE
    *ptr = SvIV(sv);
#else
    if (SvIOK(sv)) {
        if (SvIOK_UV(sv))
            *ptr = SvUV(sv);
        else
            *ptr = SvIV(sv);
    }
    else
        *ptr = SvNV(sv);
#endif
}

void tpa_get_longlong_native(pTHX_ long long *ptr, SV *sv) {
#if IVSIZE >= LONGLONGSIZE
    sv_setiv(sv, *ptr);
#else
    sv_setnv(sv, *ptr);
#endif
}

static struct tpa_vtbl vtbl_longlong_native = { TPA_MAGIC,
                                                sizeof(long long),
                                                (void (*)(pTHX_ void*, SV*)) &tpa_set_longlong_native,
                                                (void (*)(pTHX_ void*, SV*)) &tpa_get_longlong_native,
                                                "q" };

void tpa_set_ulonglong_native(pTHX_ unsigned long long *ptr, SV *sv) {
#if IVSIZE >= LONGLONGSIZE
    *ptr = SvUV(sv);
#else
    if (SvIOK(sv) && !SvIOK_notUV(sv))
        *ptr = SvNV(sv);
    else
        *ptr = SvUV(sv);
#endif
}

void tpa_get_ulonglong_native(pTHX_ unsigned long long *ptr, SV *sv) {
#if IVSIZE >= LONGLONGSIZE
    sv_setuv(sv, *ptr);
#else
    sv_setnv(sv, *ptr);
#endif
}

static struct tpa_vtbl vtbl_ulonglong_native = { TPA_MAGIC,
                                                 sizeof(unsigned long long),
                                                 (void (*)(pTHX_ void*, SV*)) &tpa_set_ulonglong_native,
                                                 (void (*)(pTHX_ void*, SV*)) &tpa_get_ulonglong_native,
                                                 "Q" };

#endif

#if (((BYTEORDER == 0x1234) || (BYTEORDER == 0x12345678)) && (SHORTSIZE == 2))

typedef unsigned short ushort_le;
#define tpa_set_ushort_le tpa_set_ushort_native
#define tpa_get_ushort_le tpa_get_ushort_native

#else

typedef struct _ushort_le { unsigned char c[2]; } ushort_le;

void tpa_set_ushort_le(pTHX_ ushort_le *ptr, SV *sv) {
    UV v = SvUV(sv);
    ptr->c[0] = v;
    ptr->c[1] = v >> 8;
}

void tpa_get_ushort_le(pTHX_ ushort_le *ptr, SV *sv) {
    sv_setuv(sv, (ptr->c[1] << 8) + ptr->c[0]);
}

#endif

static struct tpa_vtbl vtbl_ushort_le = { TPA_MAGIC,
                                          sizeof(ushort_le),
                                          (void (*)(pTHX_ void*, SV*)) &tpa_set_ushort_le,
                                          (void (*)(pTHX_ void*, SV*)) &tpa_get_ushort_le,
                                          "v" };
#if (((BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)) && (SHORTSIZE == 2))

typedef unsigned short ushort_be;
#define tpa_set_ushort_be tpa_set_ushort_native
#define tpa_get_ushort_be tpa_get_ushort_native

#else

typedef struct _ushort_be { unsigned char c[2]; } ushort_be;

void tpa_set_ushort_be(pTHX_ ushort_be *ptr, SV *sv) {
    UV v = SvUV(sv);
    ptr->c[0] = v >> 8;
    ptr->c[1] = v;
}

void tpa_get_ushort_be(pTHX_ ushort_be *ptr, SV *sv) {
    sv_setuv(sv, (ptr->c[0] << 8) + ptr->c[1] );
}

#endif

static struct tpa_vtbl vtbl_ushort_be = { TPA_MAGIC,
                                          sizeof(ushort_be),
                                          (void (*)(pTHX_ void*, SV*)) &tpa_set_ushort_be,
                                          (void (*)(pTHX_ void*, SV*)) &tpa_get_ushort_be,
                                          "n" };

#if (((BYTEORDER == 0x1234) || (BYTEORDER == 0x12345678)) && (SHORTSIZE == 4))

typedef unsigned short ulong_le;
#define tpa_set_ulong_le tpa_set_ushort_native
#define tpa_get_ulong_le tpa_get_ushort_native

#elif (((BYTEORDER == 0x1234) || (BYTEORDER == 0x12345678)) && (INTSIZE == 4))

typedef unsigned int ulong_le;
#define tpa_set_ulong_le tpa_set_uint_native
#define tpa_get_ulong_le tpa_get_uint_native

#elif (((BYTEORDER == 0x1234) || (BYTEORDER == 0x12345678)) && (LONGSIZE == 4))

typedef unsigned int ulong_le;
#define tpa_set_ulong_le tpa_set_ulong_native
#define tpa_get_ulong_le tpa_get_ulong_native

#else

typedef struct _ulong_le { unsigned char c[4]; } ulong_le;

void tpa_set_ulong_le(pTHX_ ulong_le *ptr, SV *sv) {
    UV v = SvUV(sv);
    ptr->c[0] = v;
    ptr->c[1] = (v >>= 8);
    ptr->c[2] = (v >>= 8);
    ptr->c[3] = (v >>= 8);
}

void tpa_get_ulong_le(pTHX_ ulong_le *ptr, SV* sv) {
    sv_setuv(sv, (((((ptr->c[3] << 8) + ptr->c[2] ) << 8) + ptr->c[1] ) << 8) + ptr->c[0] );
}

#endif

static struct tpa_vtbl vtbl_ulong_le = { TPA_MAGIC,
                                      sizeof(ulong_le),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_ulong_le,
                                      (void (*)(pTHX_ void*, SV*)) &tpa_get_ulong_le,
                                      "V" };

#if  (((BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)) && (SHORTSIZE == 4))

typedef unsigned short ulong_be;
#define tpa_set_ulong_be tpa_set_ushort_native
#define tpa_get_ulong_be tpa_get_ushort_native

#elif (((BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)) && (INTSIZE == 4))

typedef unsigned int ulong_be;
#define tpa_set_ulong_be tpa_set_uint_native
#define tpa_get_ulong_be tpa_get_uint_native


#elif (((BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)) && (LONGSIZE == 4))

typedef unsigned long ulong_be;
#define tpa_set_ulong_be tpa_set_ulong_native
#define tpa_get_ulong_be tpa_get_ulong_native

#else

typedef struct _ulong_be { unsigned char c[4]; } ulong_be;

void tpa_set_ulong_be(pTHX_ ulong_be *ptr, SV *sv) {
    UV v = SvUV(sv);
    ptr->c[3] = v;
    ptr->c[2] = (v >>= 8);
    ptr->c[1] = (v >>= 8);
    ptr->c[0] = (v >>= 8);
}

void tpa_get_ulong_be(pTHX_ ulong_be *ptr, SV *sv) {
    sv_setuv(sv, (((((ptr->c[0] << 8) + ptr->c[1] ) << 8) + ptr->c[2] ) << 8) + ptr->c[3] );
}

#endif

static struct tpa_vtbl vtbl_ulong_be = { TPA_MAGIC,
                                      sizeof(ulong_be),
                                      (void (*)(pTHX_ void*, SV*)) &tpa_set_ulong_be,
                                      (void (*)(pTHX_ void*, SV*)) &tpa_get_ulong_be,
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
check_index(pTHX_ UV ix, UV esize) {
    UV max = ((UV)(-1))/esize;
    if ( max < ix )
        Perl_croak(aTHX_ "index %d is out of range", ix);
}

static char *
my_sv_unchop(pTHX_ SV *sv, STRLEN size, STRLEN reserve) {
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
    else {
        size += reserve;
        if ((size < reserve) || (len + size < size))
            Perl_croak(aTHX_ "panic: memory wrap");
        
        if (len + size <= off + SvLEN(sv)) {
            SvCUR_set(sv, len + size);
            SvPV_set(sv, pv - off);
            Move(pv, pv + size - off, len, char);
            if (off) {
                SvLEN_set(sv, SvLEN(sv) + off );
                SvFLAGS(sv) &= ~SVf_OOK;
            }
        }
        else {
            SV *tmp = sv_2mortal(newSV(len + size));
            char *tmp_pv;
            SvPOK_on(tmp);
            tmp_pv = SvPV_nolen(tmp);
            Move(pv, tmp_pv + size, len, char);
            SvCUR_set(tmp, len + size);
            sv_setsv(sv, tmp);
        }
 
        if (reserve)
            sv_chop(sv, SvPVX(sv) + reserve);
    }
    return SvPVX(sv);
}

static void
reverse_elements(void *ptr, IV len, IV esize) {
    if ((esize % sizeof(unsigned int) == 0) && (PTR2IV(ptr) % sizeof(unsigned int) == 0)) {
        int *start, *end;
        esize /= sizeof(int);
        start = (int *)ptr;
        end = start + (len - 1) * esize;
        if (esize == 1) {
            while (start < end) {
                int tmp = *start;
                *(start++) = *end;
                *(end--) = tmp;
            }
        }
        else {
            while (start < end) {
                int i;
                for (i = 0; i < esize; i++) {
                    int tmp = *start;
                    *(start++) = *end;
                    *(end++) = tmp;
                }
                end -= esize * 2;
            }
        }
    }
    else {
        char *start = (char *)ptr;
        char *end = start + (len - 1) * esize;
        while (start < end) {
            int i;
            for (i = 0; i < esize; i++) {
                char tmp = *start;
                *(start++) = *end;
                *(end++) = tmp;
            }
            end -= esize * 2;
        }
    }
}




MODULE = Tie::Array::Packed		PACKAGE = Tie::Array::Packed
PROTOTYPES: DISABLE

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
                vtbl = &vtbl_int_native;
                break;
            case 'I':
                vtbl = &vtbl_uint_native;
                break;
            case 'j':
                vtbl = &vtbl_IV;
                break;
            case 'J':
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
#if (PERL_VERSION < 7)
            sv_magic(data, 0, '~', (char *)vtbl, sizeof(*vtbl));
#else
            sv_magic(data, 0, '~', (char *)vtbl, 0);
#endif
        }
    }
  OUTPUT:
    RETVAL

void
STORE(self, key, value)
    SV *self;
    UV key;
    SV *value;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN req = (key + 1) * esize;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;

        check_index(aTHX_ key, esize);

        if (len < req) {
            pv = MySvGROW(data, req);
            memset(pv + len, 0, req - len - esize);
            SvCUR_set(data, req);
        }
        (*(vtbl->set))(aTHX_ pv + req - esize, value);
    }

SV *
FETCH(self, key)
    SV *self;
    UV key;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN req = (key + 1) * esize;
        STRLEN len;
        char *pv = SvPV(data, len);
        if (len < req)
            RETVAL = &PL_sv_undef;
        else {
            RETVAL = newSV(0);
            (*(vtbl->get))(aTHX_ pv + req - esize, RETVAL);
        }
    }
  OUTPUT:
    RETVAL

UV
FETCHSIZE(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        RETVAL = SvCUR(data) / esize;
    }
  OUTPUT:
    RETVAL

void
STORESIZE(self, size)
    SV *self;
    UV size;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
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
    UV size;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN req = size * esize;
        
        check_index(aTHX_ size, esize);
        
        SvGROW(data, req);
    }

SV *
EXISTS(self, key)
    SV *self;
    UV key;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        RETVAL = ((SvCUR(data) / esize) > key) ? &PL_sv_yes : &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
DELETE(self, key)
    SV *self;
    UV key;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN req = (key + 1) * esize;
        STRLEN len;
        char *pv = SvPV(data, len);

        check_index(aTHX_ key, esize);

        if (len >= req) {
            RETVAL = newSV(0);
            (*(vtbl->get))(aTHX_ pv + req - esize, RETVAL);
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
        UV esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;
        STRLEN req = (size + items - 1) * esize;
        UV i;

        check_index(aTHX_ size + items - 1, esize);

        pv = MySvGROW(data, req);
        SvCUR_set(data, req);

        for (i = 1; i < items; i++)
            (*(vtbl->set))(aTHX_ pv + (size + i - 1) * esize, ST(i));
    }

SV *
POP(self)
    SV *self;
  CODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;
        if (size) {
            STRLEN new_len = (size - 1) * esize;
            RETVAL = newSV(0);
            (*(vtbl->get))(aTHX_ pv + new_len, RETVAL);
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
        UV esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;
        if (size) {
            RETVAL = newSV(0);
            (*(vtbl->get))(aTHX_ pv, RETVAL);
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
            UV esize = vtbl->element_size;
	    UV size = SvCUR(data) / esize;
            char *pv;
            UV i;

            check_index(aTHX_ size + items - 1, esize);
            pv = my_sv_unchop(aTHX_ data, esize * (items - 1), RESERVE_BEFORE);
            for (i = 1; i < items; i++, pv += esize) {
                (*(vtbl->set))(aTHX_ pv, ST(i));
            }
        }
    }

void
SPLICE(self, offset, length, ...)
    SV *self;
    UV offset;
    UV length;
  PPCODE:
    {
        SV *data = SvRV(self);
        struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
        UV esize = vtbl->element_size;
        STRLEN len;
        char *pv = SvPV(data, len);
        UV size = len / esize;
        UV rep = items - 3;
        UV i;

        if (offset > size)
            offset = size;

        if (offset + length > size)
            length = size - offset;

        check_index(aTHX_ offset + items - 3 - length, esize);
        
        switch (GIMME_V) {
        case G_ARRAY:
            EXTEND(SP, items + length);
            for (i = 0; i < length; i++) {
                SV *sv = sv_newmortal();
                (*(vtbl->get))(aTHX_ pv + (offset + i) * esize, sv);
                ST(items + i) = sv;
            }
            break;
        case G_SCALAR:
            if  (length) {
                SV *sv = sv_newmortal();
                (*(vtbl->get))(aTHX_ pv + (offset + length - 1) * esize, sv);
                ST(0) = sv;
            }
            else
                ST(0) = &PL_sv_undef;
        }
        
        if (rep != length) {
            if (offset == 0) {
                if (length)
                    sv_chop(data, pv + length * esize);
                if (rep) {
                    pv = my_sv_unchop(aTHX_ data, rep * esize, RESERVE_BEFORE);
                }
            }
            else {
                pv = MySvGROW(data, (size + rep - length) * esize);
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
    SV *data = SvRV(self);
    struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
    RETVAL = vtbl->packer;
OUTPUT:
    RETVAL

UV
element_size(self)
    SV *self;
CODE:
    SV *data = SvRV(self);
    struct tpa_vtbl *vtbl = data_vtbl(aTHX_ data);
    RETVAL = vtbl->element_size;
OUTPUT:
    RETVAL    

void
reverse(self)
    SV *self;
CODE:
    SV *data = SvRV(self);
    STRLEN len;
    char *pv = SvPV(data, len);
    IV esize = data_vtbl(aTHX_ data)->element_size;
    reverse_elements(pv, len / esize, esize);

void
rotate(self, how_much = 1)
    SV *self
    IV how_much
CODE:
    if (how_much) {
        SV *data = SvRV(self);
        STRLEN len;
        char *pv = SvPV(data, len);
        IV esize = data_vtbl(aTHX_ data)->element_size;
        IV size;
        if (esize % sizeof(int) == 0) {
            how_much *= esize / sizeof(int);
            esize = sizeof(int);
        }
        size = len / esize;
        if (how_much < 0)
            how_much += size;
        how_much %= size;
        /* printf("how_much: %d\n", how_much); */
        reverse_elements(pv, how_much, esize);
        reverse_elements(pv + how_much * esize, size - how_much, esize);
        reverse_elements(pv, size, esize);
    }


