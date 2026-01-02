#ifndef _ERR_H
#define _ERR_H

#include <features.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

#if __GNUC__ >= 3
#define __fp(x, y) __attribute__ ((__format__ (__printf__, x, y)))
#else
#define __fp(x, y)
#endif

void warn(const char *, ...) __fp(1, 2);
void vwarn(const char *, va_list) __fp(1, 0);
void warnx(const char *, ...) __fp(1, 2);
void vwarnx(const char *, va_list) __fp(1, 0);

_Noreturn void err(int, const char *, ...) __fp(2, 3);
_Noreturn void verr(int, const char *, va_list) __fp(2, 0);
_Noreturn void errx(int, const char *, ...) __fp(2, 3);
_Noreturn void verrx(int, const char *, va_list) __fp(2, 0);

#undef __fp

#ifdef __cplusplus
}
#endif

#endif
