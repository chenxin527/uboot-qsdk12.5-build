#ifndef _MONETARY_H
#define _MONETARY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <features.h>

#define __NEED_ssize_t
#define __NEED_size_t
#define __NEED_locale_t

#include <bits/alltypes.h>

#if __GNUC__ >= 3
#define __fsfm(x, y) __attribute__ ((__format__ (__strfmon__, x, y)))
#else
#define __fsfm(x, y)
#endif

ssize_t strfmon(char *__restrict, size_t, const char *__restrict, ...) __fsfm(3, 4);
ssize_t strfmon_l(char *__restrict, size_t, locale_t, const char *__restrict, ...) __fsfm(4, 5);

#undef __fsfm

#ifdef __cplusplus
}
#endif

#endif
