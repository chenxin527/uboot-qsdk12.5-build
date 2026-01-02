/*
* Copyright (c) 2011, 2018 Qualcomm Innovation Center, Inc.
* All Rights Reserved.
* Confidential and Proprietary - Qualcomm Innovation Center, Inc.
*
*/

/*
 * Copyright (c) 2010, Atheros Communications Inc. 
 * All Rights Reserved.
 * 
 * 2011 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 * 
 */
#ifndef _ATH_COMPAT_H_
#define _ATH_COMPAT_H_

#ifdef ANDROID
#if !defined(__linux__)
#define __linux__
#endif
#endif

/*
 * BSD/Linux compatibility shims.  These are used mainly to
 * minimize differences when importing necesary BSD code.
 */

#include "wlan_opts.h"

#define NBBY    8           /* number of bits/byte */

#ifdef __linux__
#include <linux/version.h>
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,18)
#define roundup(x, y)   ((((x)+((y)-1))/(y))*(y))  /* to any y */
#endif
#elif WIN32
#define roundup(x, y)   ((((x)+((y)-1))/(y))*(y))  /* to any y */
#endif

#define howmany(x, y)   (((x)+((y)-1))/(y))

/* Bit map related macros. */
#define setbit(a,i) ((a)[(i)/NBBY] |= 1<<((i)%NBBY))
#define clrbit(a,i) ((a)[(i)/NBBY] &= ~(1<<((i)%NBBY)))
#define isset(a,i)  ((a)[(i)/NBBY] & (1<<((i)%NBBY)))
#define isclr(a,i)  (((a)[(i)/NBBY] & (1<<((i)%NBBY))) == 0)

#ifdef __linux__
#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,6,28)
#define ath_netdev_priv(d)  ((d)->priv)
#else
#define ath_netdev_priv(d)  netdev_priv(d) 
#endif 

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,22)
#ifndef __packed
#define __packed __attribute__((__packed__))
#endif
#endif


#define __printflike(_a,_b) \
    __attribute__ ((__format__ (__printf__, _a, _b)))
#endif /* __linux__ */

#define __offsetof(t,m) offsetof(t,m)

#ifndef ALIGNED_POINTER
/*
 * ALIGNED_POINTER is a boolean macro that checks whether an address
 * is valid to fetch data elements of type t from on this architecture.
 * This does not reflect the optimal alignment, just the possibility
 * (within reasonable limits). 
 *
 */
#define ALIGNED_POINTER(p,t)    1
#endif

/*
**  For non Linux (gcc compiled) drivers, define the likely() and 
**  unlikely() macros to be simply the argument.  This sould fix build
**  issues for NetBSD and Vista
*/

#ifndef __linux__

#define unlikely(_a)    _a
#define likely(_b)      _b

#endif

/*
** Assert for Linux kernel mode.  This assumes unlikely is defined,
** so it assumes a Linux OS
*/

#ifdef __KERNEL__
#include <asm/page.h>

#if ATH_DEBUG
#define KASSERT(exp, msg) do {          \
    if (unlikely(!(exp))) {         \
        printk msg;         \
        BUG();              \
    }                   \
} while (0)
#else
#define KASSERT(exp, msg)
#endif /* ATH_DEBUG */

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,24)
#define CTL_AUTO -2
#define DEV_ATH 9
#else
#define CTL_AUTO CTL_UNNUMBERED
#define DEV_ATH CTL_UNNUMBERED
#endif  /* sysctl */

#endif /* __KERNEL__ */

/*
 * NetBSD/FreeBSD defines for file version.
 */
#define __FBSDID(_s)
#define __KERNEL_RCSID(_n,_s)
#endif /* _ATH_COMPAT_H_ */
