/*
 * Copyright (c) 2014, The Linux Foundation. All rights reserved.
 * Permission to use, copy, modify, and/or distribute this software for
 * any purpose with or without fee is hereby granted, provided that the
 * above copyright notice and this permission notice appear in all copies.
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
 * OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifndef __NSS_MACSEC_TYPES_H__
#define __NSS_MACSEC_TYPES_H__

#ifdef __KERNEL__
#include <linux/module.h>
#include <linux/types.h>
#include <linux/ctype.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/string.h>
#include <linux/fs.h>
#include <linux/wait.h>
#include <linux/mutex.h>
#include <asm/uaccess.h>
#include <net/sock.h>
#include <net/netlink.h>

#define osal_print printk

#else
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <pthread.h>
#include <semaphore.h>
#include <signal.h>
#include <errno.h>

#define osal_print printf

typedef char bool;

#endif

#define __LITTLE_ENDIAN__

/*
 * Basic data types
 */
#if 0
typedef unsigned long long sa_u64_t;
typedef long long sa_i64_t;
typedef unsigned int sa_u32_t;
typedef int sa_i32_t;
typedef unsigned short sa_u16_t;
typedef short sa_i16_t;
typedef unsigned char sa_u8_t;
typedef signed char sa_i8_t;

typedef char sa_ch_t;
typedef long sa_il_t;
typedef unsigned long sa_ul_t;

typedef char sa_bool_t;
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

/*
 * Basic data types
 */
#define u64 u64_t
#define i64 i64_t
#define u32 u32_t
#define i32 i32_t
#define u16 u16_t
#define i16 i16_t
#define u8 u8_t
#define i8 i8_t
typedef unsigned long long u64;
typedef long long i64;
typedef unsigned int u32;
typedef int i32;
typedef unsigned short u16;
typedef short i16;
typedef unsigned char u8;
typedef signed char i8;

typedef int BOOL;
//typedef  char sa_bool_t;
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

typedef enum {
	ERROR_OK = 0,
	ERROR_RESOURCE = 1,
	ERROR_PARAM = 2,
	ERROR_NOT_FOUND = 3,
	ERROR_CONFLICT = 4,
	ERROR_TIMEOUT = 5,
	ERROR_NOT_SUPPORT = 6,
	ERROR_ERROR = 0xffffffff
} g_error_t;

#ifndef OK
#define OK                   ERROR_OK
#endif

#ifndef ERROR
#define ERROR                ERROR_ERROR
#endif

#define SHR_RET_ON_ERR(f) \
    do{ g_error_t shr_rv = (f); \
        if ( shr_rv != OK) { \
            return shr_rv; \
        } \
    }while(0)

#define SHR_PARAM_CHECK(f) \
	do{ \
		if (!(f)) { \
			osal_print("%s[%d]: error parameter!\r\n", __FUNCTION__, __LINE__); \
			return ERROR_PARAM; \
		} \
	}while(0)

#endif /* __TYPES_H__ */
