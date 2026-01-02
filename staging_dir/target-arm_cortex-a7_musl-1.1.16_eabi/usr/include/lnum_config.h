/*
** $Id: lnum_config.h,v ... $
** Internal Number model
** See Copyright Notice in lua.h
*/

#ifndef lnum_config_h
#define lnum_config_h

/*
** Default number modes
*/
#if (!defined LNUM_DOUBLE) && (!defined LNUM_FLOAT) && (!defined LNUM_LDOUBLE)
# define LNUM_DOUBLE
#endif
#if (!defined LNUM_INT16) && (!defined LNUM_INT32) && (!defined LNUM_INT64)
# define LNUM_INT32
#endif

/*
** Require C99 mode for COMPLEX, FLOAT and LDOUBLE (only DOUBLE is ANSI C).
*/
#if defined(LNUM_COMPLEX) && (__STDC_VERSION__ < 199901L)
# error "Need C99 for complex (use '--std=c99' or similar)"
#elif defined(LNUM_LDOUBLE) && (__STDC_VERSION__ < 199901L) && !defined(_MSC_VER)
# error "Need C99 for 'long double' (use '--std=c99' or similar)"
#elif defined(LNUM_FLOAT) && (__STDC_VERSION__ < 199901L)
/* LNUM_FLOAT not supported on Windows */
# error "Need C99 for 'float' (use '--std=c99' or similar)"
#endif
 
/*
** Number mode identifier to accompany the version string.
*/
#ifdef LNUM_COMPLEX
# define _LNUM1 "complex "
#else
# define _LNUM1 ""
#endif
#ifdef LNUM_DOUBLE
# define _LNUM2 "double"
#elif defined(LNUM_FLOAT)
# define _LNUM2 "float"
#elif defined(LNUM_LDOUBLE)
# define _LNUM2 "ldouble"
#endif
#ifdef LNUM_INT32
# define _LNUM3 "int32"
#elif defined(LNUM_INT64)
# define _LNUM3 "int64"
#elif defined(LNUM_INT16)
# define _LNUM3 "int16"
#endif
#define LUA_LNUM _LNUM1 _LNUM2 " " _LNUM3

/*
** LUA_NUMBER is the type of floating point number in Lua
** LUA_NUMBER_SCAN is the format for reading numbers.
** LUA_NUMBER_FMT is the format for writing numbers.
*/
#ifdef LNUM_FLOAT
# define LUA_NUMBER         float
# define LUA_NUMBER_SCAN    "%f"
# define LUA_NUMBER_FMT     "%g"  
#elif (defined LNUM_DOUBLE)
# define LUA_NUMBER	        double
# define LUA_NUMBER_SCAN    "%lf"
# define LUA_NUMBER_FMT     "%.14g"
#elif (defined LNUM_LDOUBLE)
# define LUA_NUMBER         long double
# define LUA_NUMBER_SCAN    "%Lg"
# define LUA_NUMBER_FMT     "%.20Lg"
#endif


/* 
** LUAI_MAXNUMBER2STR: size of a buffer fitting any number->string result.
**
**  double:  24 (sign, x.xxxxxxxxxxxxxxe+nnnn, and \0)
**  int64:   21 (19 digits, sign, and \0)
**  long double: 43 for 128-bit (sign, x.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxe+nnnn, and \0)
**           30 for 80-bit (sign, x.xxxxxxxxxxxxxxxxxxxxe+nnnn, and \0)
*/
#ifdef LNUM_LDOUBLE
# define _LUAI_MN2S 44
#else
# define _LUAI_MN2S 24
#endif

#ifdef LNUM_COMPLEX
# define LUAI_MAXNUMBER2STR (2*_LUAI_MN2S)
#else
# define LUAI_MAXNUMBER2STR _LUAI_MN2S
#endif

/*
** LUA_INTEGER is the integer type used by lua_pushinteger/lua_tointeger/lua_isinteger.
** LUA_INTEGER_SCAN is the format for reading integers
** LUA_INTEGER_FMT is the format for writing integers
**
** Note: Visual C++ 2005 does not have 'strtoull()', use '_strtoui64()' instead.
*/
#ifdef LNUM_INT32
# if LUAI_BITSINT > 16
#  define LUA_INTEGER   int
#  define LUA_INTEGER_SCAN "%d"
#  define LUA_INTEGER_FMT "%d"
# else
/* Note: 'LUA_INTEGER' being 'ptrdiff_t' (as in Lua 5.1) causes problems with
 *       'printf()' operations. Also 'unsigned ptrdiff_t' is invalid.
 */
#  define LUA_INTEGER   long
#  define LUA_INTEGER_SCAN "%ld"
#  define LUA_INTEGER_FMT "%ld"
# endif
# define LUA_INTEGER_MAX 0x7FFFFFFF             /* 2^31-1 */
/* */
#elif defined(LNUM_INT64)
# define LUA_INTEGER	long long
# ifdef _MSC_VER
#  define lua_str2ul    _strtoui64
# else
#  define lua_str2ul    strtoull
# endif
# define LUA_INTEGER_SCAN "%lld"
# define LUA_INTEGER_FMT "%lld"
# define LUA_INTEGER_MAX 0x7fffffffffffffffLL       /* 2^63-1 */ 
# define LUA_INTEGER_MIN (-LUA_INTEGER_MAX - 1LL)   /* -2^63 */
/* */
#elif defined(LNUM_INT16)
# if LUAI_BITSINT > 16
#  define LUA_INTEGER    short
#  define LUA_INTEGER_SCAN "%hd"
#  define LUA_INTEGER_FMT "%hd"
# else
#  define LUA_INTEGER    int
#  define LUA_INTEGER_SCAN "%d"
#  define LUA_INTEGER_FMT "%d"
# endif
# define LUA_INTEGER_MAX 0x7FFF             /* 2^16-1 */
#endif

#ifndef lua_str2ul
# define lua_str2ul (unsigned LUA_INTEGER)strtoul
#endif
#ifndef LUA_INTEGER_MIN
# define LUA_INTEGER_MIN (-LUA_INTEGER_MAX -1)  /* -2^16|32 */
#endif

/*
@@ lua_number2int is a macro to convert lua_Number to int.
@@ lua_number2integer is a macro to convert lua_Number to lua_Integer.
** CHANGE them if you know a faster way to convert a lua_Number to
** int (with any rounding method and without throwing errors) in your
** system. In Pentium machines, a naive typecast from double to int
** in C is extremely slow, so any alternative is worth trying.
*/

/* On a Pentium, resort to a trick */
#if defined(LNUM_DOUBLE) && !defined(LUA_ANSI) && !defined(__SSE2__) && \
    (defined(__i386) || defined (_M_IX86) || defined(__i386__))

/* On a Microsoft compiler, use assembler */
# if defined(_MSC_VER)
#  define lua_number2int(i,d)   __asm fld d   __asm fistp i
# else

/* the next trick should work on any Pentium, but sometimes clashes
   with a DirectX idiosyncrasy */
union luai_Cast { double l_d; long l_l; };
#  define lua_number2int(i,d) \
  { volatile union luai_Cast u; u.l_d = (d) + 6755399441055744.0; (i) = u.l_l; }
# endif

# ifndef LNUM_INT64
#  define lua_number2integer    lua_number2int
# endif

/* this option always works, but may be slow */
#else
# define lua_number2int(i,d)        ((i)=(int)(d))
#endif

/* Note: Some compilers (OS X gcc 4.0?) may choke on double->long long conversion 
 *       since it can lose precision. Others do require 'long long' there.  
 */
#ifndef lua_number2integer
# define lua_number2integer(i,d)    ((i)=(lua_Integer)(d))
#endif

/*
** 'luai_abs()' to give absolute value of 'lua_Integer'
*/
#ifdef LNUM_INT32
# define luai_abs abs
#elif defined(LNUM_INT64) && (__STDC_VERSION__ >= 199901L)
# define luai_abs llabs
#else
# define luai_abs(v) ((v) >= 0 ? (v) : -(v))
#endif

/*
** LUAI_UACNUMBER is the result of an 'usual argument conversion' over a number.
** LUAI_UACINTEGER the same, over an integer.
*/
#define LUAI_UACNUMBER	double
#define LUAI_UACINTEGER long

/* ANSI C only has math funcs for 'double. C99 required for float and long double
 * variants.
 */
#ifdef LNUM_DOUBLE
# define _LF(name) name
#elif defined(LNUM_FLOAT)
# define _LF(name) name ## f
#elif defined(LNUM_LDOUBLE)
# define _LF(name) name ## l
#endif

#endif

