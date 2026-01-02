/*
 * Copyright (c) 2001-2002 Silicon Graphics, Inc.
 * All Rights Reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program.  If not, see
 * <http://www.gnu.org/licenses/>.
 *
 */
#ifndef __XATTR_H__
#define __XATTR_H__

#if defined(linux)
#include <features.h>
#endif

/* Portability non glibc c++ build systems */
#ifndef __THROW
# if defined __cplusplus
#  define __THROW       throw ()
# else
#  define __THROW
# endif
#endif

#include <errno.h>
#ifndef ENOATTR
# define ENOATTR ENODATA        /* No such attribute */
#endif

#define XATTR_CREATE  0x1       /* set value, fail if attr already exists */
#define XATTR_REPLACE 0x2       /* set value, fail if attr does not exist */

#ifdef __cplusplus
extern "C" {
#endif

extern int setxattr (const char *__path, const char *__name,
		      const void *__value, size_t __size, int __flags) __THROW;
extern int lsetxattr (const char *__path, const char *__name,
		      const void *__value, size_t __size, int __flags) __THROW;
extern int fsetxattr (int __filedes, const char *__name,
		      const void *__value, size_t __size, int __flags) __THROW;

extern ssize_t getxattr (const char *__path, const char *__name,
				void *__value, size_t __size) __THROW;
extern ssize_t lgetxattr (const char *__path, const char *__name,
				void *__value, size_t __size) __THROW;
extern ssize_t fgetxattr (int __filedes, const char *__name,
				void *__value, size_t __size) __THROW;

extern ssize_t listxattr (const char *__path, char *__list,
				size_t __size) __THROW;
extern ssize_t llistxattr (const char *__path, char *__list,
				size_t __size) __THROW;
extern ssize_t flistxattr (int __filedes, char *__list,
				size_t __size) __THROW;

extern int removexattr (const char *__path, const char *__name) __THROW;
extern int lremovexattr (const char *__path, const char *__name) __THROW;
extern int fremovexattr (int __filedes,   const char *__name) __THROW;

#ifdef __cplusplus
}
#endif

#endif	/* __XATTR_H__ */
