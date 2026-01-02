/*
 * Copyright (c) 2013, 2017 Qualcomm Innovation Center, Inc.
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Innovation Center, Inc.
 */
/*-
 * Copyright (c) 2002-2004 Sam Leffler, Errno Consulting, Atheros
 * Communications, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the following conditions are met:
 * 1. The materials contained herein are unmodified and are used
 *    unmodified.
 * 2. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following NO
 *    ''WARRANTY'' disclaimer below (''Disclaimer''), without
 *    modification.
 * 3. Redistributions in binary form must reproduce at minimum a
 *    disclaimer similar to the Disclaimer below and any redistribution
 *    must be conditioned upon including a substantially similar
 *    Disclaimer requirement for further binary redistribution.
 * 4. Neither the names of the above-listed copyright holders nor the
 *    names of any contributors may be used to endorse or promote
 *    product derived from this software without specific prior written
 *    permission.
 *
 * NO WARRANTY
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF NONINFRINGEMENT,
 * MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
 * FOR SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGES.
 *
 */
/*
 * 2013 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#ifndef _ATH_AH_OSDEP_H_
#define _ATH_AH_OSDEP_H_
/*
 * Atheros Hardware Access Layer (HAL) OS Dependent Definitions.
 */

#ifndef QCA_PARTNER_PLATFORM
#ifdef __i386__
#include <linux/version.h>

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,18)
    #if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 33)
        #include <linux/autoconf.h>
    #else
        #include <generated/autoconf.h>
    #endif
#else   // LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,18)
    #include <linux/config.h>
#endif

#endif // __i386__
#endif //QCA_PARTNER_PLATFORM

#include <qdf_types.h>

/*
 * Starting with 2.6.4 the kernel supports a configuration option
 * to pass parameters in registers.  If this is enabled we must
 * mark all function interfaces in+out of the HAL to pass parameters
 * on the stack as this is the convention used internally (for
 * maximum portability).
 *
 * XXX A lot of functions have __ahdecl in their definition but not declaration
 * So compile breaks.
 * Since This is only an issue for i386 which has regparam enabled, instead of
 * changing the vanilla FC3 kernel, for now, remove the regparm
 * disabling.
 */
#ifndef __ahdecl
#ifdef __i386__
#define __ahdecl    __attribute__((regparm(0)))
#else
#define __ahdecl
#endif
#endif
#ifndef __packed
#define __packed    __attribute__((__packed__))
#endif

/*
 * When building the HAL proper we use no GPL-contaminated include
 * files and must define these types ourself.  Beware of these being
 * mismatched against the contents of <linux/types.h>
 */
#include <linux/types.h>
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,20) || !defined(__KERNEL__)
/*
 * temporary hack - coexist with other OS shim header files
 * (qdf_types_pvt.h) that also try to define bool.
 * Eventually this file should be deprecated in favor of the
 * qdf header files.
 */
#if !defined(__bool_already_defined__)
#define __bool_already_defined__
/*
 * Provide replacements for kernel defs in recent kernel version's
 * linux/types.h
 */
typedef enum {
    false = 0,
    true  = 1
} bool;
#endif /* __bool_already_defined__ */
#endif /* __KERNEL__ */

#if !defined (__LINUX_ARM_ARCH__)
#ifndef __i386__
#ifndef _STDARG_H
typedef void *va_list;
#endif
#endif
#endif


#if (!defined(_STDINT_H)) || (!defined(_LINUX_TYPES_H))
/* Must explictly set a 64-bit target for uinptr_t to be 64-bit correct */
    #if defined (__LINUX_MIPS64_ARCH__)
#if defined(uintptr_t)
#undef uintprt_t        
        typedef unsigned long long  uintptr_t;
#endif
    #else
        #include <linux/version.h>
        #if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,24)) || (!defined (_LINUX_TYPES_H))
	     typedef unsigned int        uintptr_t;
	#endif
    #endif
#endif


/*
 * Linux/BSD gcc compatibility shims.
 */
#define __printflike(_a,_b) \
    __attribute__ ((__format__ (__printf__, _a, _b)))
#define __va_list   va_list
#define OS_INLINE   __inline

/* no-ops */
#define HAL_USE_INTERSPERSED_READS
#define HAL_NO_INTERSPERSED_READS

typedef void* HAL_SOFTC;
typedef void* HAL_BUS_HANDLE;
typedef void* HAL_ADAPTER_HANDLE;
typedef u_int32_t HAL_BUS_ADDR;         /* XXX architecture dependent */
typedef void* HAL_BUS_TAG;

/* 
 * Supported Bus types
 */
typedef enum ath_hal_bus_type {
   HAL_BUS_TYPE_PCI,
   HAL_BUS_TYPE_AHB,
   HAL_BUS_TYPE_SIM, /* simulator */
   HAL_BUS_TYPE_SDIO, 
} HAL_BUS_TYPE;


typedef struct hal_bus_info {
    HAL_BUS_TAG  bc_tag;
    int          cal_in_flash;
}HAL_BUS_INFO;

/*
 * Bus to hal context handoff
 */
typedef struct hal_bus_context {
    HAL_BUS_INFO     bc_info;
    HAL_BUS_HANDLE  bc_handle;
    HAL_BUS_TYPE    bc_bustype;
} HAL_BUS_CONTEXT;

/*
** Forward reference, since ah_osdep.h is included before the definition of ath_hal
** in the ah.h file
*/

struct ath_hal;
struct hal_reg_parm {
    u_int8_t             halPciePowerSaveEnable;             // Program Serdes; Use ASPM
    u_int8_t             halPcieL1SKPEnable;                 // Enable L1 SKP workaround
    u_int8_t             halPcieClockReq;
    u_int32_t            halPciePowerReset;
    u_int32_t            halPcieWaen;
    u_int32_t            halPcieDetach;
    u_int8_t             halPcieRestore;
    u_int8_t             htEnable;               // Enable/disable 11n mode
    u_int32_t            ofdmTrigLow;
    u_int32_t            ofdmTrigHigh;
    u_int32_t            cckTrigHigh;
    u_int32_t            cckTrigLow;
    u_int32_t            enableANI;
    u_int8_t             noiseImmunityLvl;
    u_int32_t            ofdmWeakSigDet;
    u_int32_t            cckWeakSigThr;
    u_int8_t             spurImmunityLvl;
    u_int8_t             firStepLvl;
    int8_t               rssiThrHigh;
    int8_t               rssiThrLow;
    u_int16_t            diversityControl;                // Enable/disable antenna diversity
    u_int16_t            antennaSwitchSwap; 
    u_int32_t            forceBias;
    u_int32_t            forceBiasAuto;
    int                  calInFlash;
#ifdef ATH_SUPPORT_TxBF         
    u_int8_t             CVTimeOut;
    u_int16_t            TxBFCtl;
#define HAL_TXBF_IMBF                        0x01
#define HAL_TXBF_NON_EXBF                    0x02
#define HAL_TXBF_COMP_EXBF                   0x04
#define HAL_TXBF_IMBF_FB                     0x08
#define HAL_TXBF_NON_EXBF_IMMEDIATELY_RPT    0x10
#define HAL_TXBF_COMP_EXBF_IMMEDIATELY_RPT   0x20
#define HAL_TXBF_NON_EXBF_DELAY_RPT          0x40
#define HAL_TXBF_COMP_EXBF_DELAY_RPT         0x80
#define HAL_TXBF_DEFAULT_ON  \
            (HAL_TXBF_NON_EXBF | HAL_TXBF_COMP_EXBF | \
            HAL_TXBF_NON_EXBF_IMMEDIATELY_RPT | HAL_TXBF_COMP_EXBF_IMMEDIATELY_RPT |    \
            HAL_TXBF_NON_EXBF_DELAY_RPT | HAL_TXBF_COMP_EXBF_DELAY_RPT) 
#define HAL_TXBF_DEFAULT_OFF                 0
#define HAL_TXBF_DEFAULT                     HAL_TXBF_DEFAULT_ON
#endif

};


/*
 * XXX: to avoid redefinition of some of the macros
 * in global osdep.h
 */
#ifdef BUILD_HAL

/*
 * Delay n microseconds.
 */
#ifndef OS_DELAY
extern  void __ahdecl ath_hal_delay(int);
#define OS_DELAY(_n)    ath_hal_delay(_n)
#endif

extern  void* __ahdecl ath_hal_ioremap(uintptr_t addr, u_int32_t len);
#ifdef AR9100
#   define OS_REMAP(_ignore, _addr, _len)       ath_hal_ioremap(_addr, _len)
extern void ath_hal_ahb_mac_reset(void);
extern void ath_hal_get_chip_revisionid(u_int32_t *);
#else
#   define OS_REMAP(_addr, _len)       ath_hal_ioremap(_addr, _len)
#endif

#ifndef OS_MEMZERO
#define OS_MEMZERO(_a, _n)  ath_hal_memzero((_a), (_n))
extern void __ahdecl ath_hal_memzero(void *, size_t);
#endif
#ifndef OS_MEMCPY
#define OS_MEMCPY(_d, _s, _n)   ath_hal_memcpy(_d,_s,_n)
extern void * __ahdecl ath_hal_memcpy(void *, const void *, size_t);
#endif
#ifndef OS_MEMSET
#define OS_MEMSET(_buf, _ch, _len)  memset(_buf, _ch, _len)
#endif

#ifndef __i386__
#ifndef abs
#define abs(_a)     __builtin_abs(_a)
#endif
#endif

extern  u_int32_t __ahdecl ath_hal_getuptime(struct ath_hal *);

#endif

/*
 * Byte order/swapping support.
 */
#define AH_LITTLE_ENDIAN    1234
#define AH_BIG_ENDIAN       4321

#if AH_BYTE_ORDER == AH_BIG_ENDIAN
/*
 * This could be optimized but since we only use it for
 * a few registers there's little reason to do so.
 */
static inline u_int32_t
__bswap32(u_int32_t _x)
{
    return ((u_int32_t)(
          (((const u_int8_t *)(&_x))[0]    ) |
          (((const u_int8_t *)(&_x))[1]<< 8) |
          (((const u_int8_t *)(&_x))[2]<<16) |
          (((const u_int8_t *)(&_x))[3]<<24))
    );
}
#define __bswap16(_x) ( (u_int16_t)( (((const u_int8_t *)(&_x))[0] ) |\
                         ( ( (const u_int8_t *)( &_x ) )[1]<< 8) ) )
#else
#define __bswap32(_x)   (_x)
#define __bswap16(_x)   (_x)
#endif

#if AH_UNALIGNED_SUPPORTED
static inline u_int32_t
__get_be32(u_int8_t *_x)
{
    return ((u_int32_t)(
          (((u_int32_t)_x[0])<<24) |
          (((u_int32_t)_x[1])<<16) |
          (((u_int32_t)_x[2])<< 8) |
          (((u_int32_t)_x[3])    ))
    );
}

static inline void
__put_be32(u_int8_t *_x, u_int32_t _val)
{
    _x[0] = (u_int8_t)(_val>>24);
    _x[1] = (u_int8_t)(_val>>16);
    _x[2] = (u_int8_t)(_val>> 8);
    _x[3] = (u_int8_t)(_val&0xff);
}

static inline u_int16_t
__get_be16(u_int8_t *_x)
{
    return ((u_int16_t)(
          (((u_int16_t)_x[0])<< 8) |
          (((u_int16_t)_x[1])    ))
    );
}

static inline void
__put_be16(u_int8_t *_x, u_int16_t _val)
{
    _x[0] = (u_int8_t)(_val>> 8);
    _x[1] = (u_int8_t)(_val&0xff);
}

static inline u_int32_t
__get_le32(u_int8_t *_x)
{
    return ((u_int32_t)(
          (((u_int32_t)_x[0])    ) |
          (((u_int32_t)_x[1])<< 8) |
          (((u_int32_t)_x[2])<<16) |
          (((u_int32_t)_x[3])<<24))
    );
}

static inline void
__put_le32(u_int8_t *_x, u_int32_t _val)
{
    _x[0] = (u_int8_t)(_val&0xff);
    _x[1] = (u_int8_t)(_val>> 8);
    _x[2] = (u_int8_t)(_val>>16);
    _x[3] = (u_int8_t)(_val>>24);
}

static inline u_int16_t
__get_le16(u_int8_t *_x)
{
    return ((u_int16_t)(
          (((u_int16_t)_x[0])    ) |
          (((u_int16_t)_x[1])<< 8))
    );
}

static inline void
__put_le16(u_int8_t *_x, u_int16_t _val)
{
    _x[0] = (u_int8_t)(_val&0xff);
    _x[1] = (u_int8_t)(_val>> 8);
}

#if AH_BYTE_ORDER == AH_BIG_ENDIAN
#define __get32 __get_be32
#define __put32 __put_be32
#define __get16 __get_be16
#define __put16 __put_be16
#else
#define __get32 __get_le32
#define __put32 __put_le32
#define __get16 __get_le16
#define __put16 __put_le16
#endif
#endif /* AH_UNALIGNED_SUPPORTED */

#ifdef QCA_PARTNER_PLATFORM

#include "ath_carr_pltfrm.h"

#else /* QCA_PARTNER_PLATFORM */

/*
 * Register read/write; we assume the registers will always
 * be memory-mapped.  Note that register accesses are done
 * using target-specific functions when debugging is enabled
 * (AH_DEBUG) or we are explicitly configured this way.  The
 * latter is used on some platforms where the full i/o space
 * cannot be directly mapped.
 *
 * The hardware registers are native little-endian byte order.
 * Big-endian hosts are handled by enabling hardware byte-swap
 * of register reads and writes at reset.  But the PCI clock
 * domain registers are not byte swapped!  Thus, on big-endian
 * platforms we have to byte-swap thoese registers specifically.
 * Most of this code is collapsed at compile time because the
 * register values are constants.
 */
#if AH_BYTE_ORDER == AH_BIG_ENDIAN

#ifdef __LINUX_ARM_ARCH__
/*
 * IXP platform needs a uin32
 */
#define _OS_REG_WRITE(_ah, _reg, _val) do {             \
    writel((_val),                                      \
            ((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg)))); \
} while(0)
#define _OS_REG_READ(_ah, _reg) \
        readl((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg)))

#elif defined (__LINUX_MIPS32_ARCH__) || defined (__LINUX_MIPS64_ARCH__)
#define _OS_REG_WRITE(_ah, _reg, _val) \
    *((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg))) = (_val)
#define _OS_REG_READ(_ah, _reg) \
    *((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg)))

#elif defined (__LINUX_UBICOM32_ARCH__)
#define _OS_REG_WRITE(_ah, _reg, _val) do {		\
	writel((_val),			\
		((void *)(AH_PRIVATE(_ah)->ah_sh + (_reg))));	\
} while(0)
#define _OS_REG_READ(_ah, _reg)				\
	readl((void *)(AH_PRIVATE(_ah)->ah_sh + (_reg)))

#elif defined (__LINUX_POWERPC_ARCH__)
#define _OS_REG_WRITE(_ah, _reg, _val) do {             \
    writel((_val),                                      \
            ((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg)))); \
} while(0)
#define _OS_REG_READ(_ah, _reg) \
    readl((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg)))
#else
#define _OS_REG_WRITE(_ah, _reg, _val) do {                 \
    if ( (_reg) >= 0x4000 && (_reg) < 0x5000)               \
        *((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg))) =      \
            __bswap32((_val));                  \
    else                                    \
        *((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg))) = (_val);  \
} while (0)
#define _OS_REG_READ(_ah, _reg) \
    (((_reg) >= 0x4000 && (_reg) < 0x5000) ? \
        __bswap32(*((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg)))) : \
        *((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg))))
#endif /*__LINUX_ARM_ARCH__*/

#else /* AH_LITTLE_ENDIAN */
#define _OS_REG_WRITE(_ah, _reg, _val) do { \
    *((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg))) = (_val); \
} while (0)
#define _OS_REG_READ(_ah, _reg) \
    *((volatile u_int32_t *)(AH_PRIVATE(_ah)->ah_sh + (_reg)))
#endif /* AH_BYTE_ORDER */

#endif /* QCA_PARTNER_PLATFORM */
/* no-op for non-USB solutions */
#define ENABLE_REG_WRITE_BUFFER
#define DISABLE_REG_WRITE_BUFFER
#define OS_REG_WRITE_FLUSH(_ah)
#define HTC_SET_PS_STATE(_ah, _mode)
#define WMI_SEND_TXPOWER_TARGET(_ah, _mode)

#if defined(AH_DEBUG) || defined(AH_REGOPS_FUNC) || defined(AH_DEBUG_ALQ)
/* use functions to do register operations */
#define OS_REG_WRITE(_ah, _reg, _val)   ath_hal_reg_write(_ah, _reg, _val)
#define OS_REG_READ(_ah, _reg)      ath_hal_reg_read(_ah, _reg)

extern  void __ahdecl ath_hal_reg_write(struct ath_hal *ah,
        u_int reg, u_int32_t val);
extern  u_int32_t __ahdecl ath_hal_reg_read(struct ath_hal *ah, u_int reg);
#else
/* inline register operations */
#define OS_REG_WRITE(_ah, _reg, _val)   _OS_REG_WRITE(_ah, _reg, _val)

#define OS_REG_READ(_ah, _reg)      _OS_REG_READ(_ah, _reg)
#endif /* AH_DEBUG || AH_REGFUNC || AH_DEBUG_ALQ */

#ifdef AH_DEBUG_ALQ
extern  void __ahdecl OS_MARK(struct ath_hal *, u_int id, u_int32_t value);
#else
#define OS_MARK(_ah, _id, _v)
#endif

#ifdef __KERNEL__
#ifdef ATH_CAL_NAND_FLASH

#ifndef ATH_CAL_NAND_PARTITION
#define ATH_CAL_NAND_PARTITION "ART"
#endif

#ifdef __LINUX_ARM_ARCH__
#if LINUX_VERSION_CODE <= KERNEL_VERSION(3,4,103)
#include "mach/board.h"
#endif

#define OS_NAND_FLASH_READ(_calpart, _addr, _len, _retlen, _buf)     \
           wifi_board_data_read(_addr,(size_t)_len,(size_t *)_retlen, _buf)
#else
/* NAND FLASH Read method */
extern int ath_nand_local_read(u_char *cal_part,loff_t from, size_t len,
		size_t *retlen, u_char *buf);

#define OS_NAND_FLASH_READ(_calpart, _addr, _len, _retlen, _buf)     \
           ath_nand_local_read((u_char *)_calpart, _addr,(size_t)_len,(size_t *)_retlen, _buf)
#endif
#endif
#endif

/*
 * Linux-specific attach/detach methods needed for module reference counting.
 *
 * XXX We can't use HAL_STATUS because the type isn't defined at this
 *     point (circular dependency); we wack the type and patch things
 *     up in the function.
 *
 * NB: These are intentionally not marked __ahdecl since they are
 *     compiled with the default calling convetion and are not called
 *     from within the HAL.
 */
typedef u_int32_t (*HAL_BUS_CONFIG_READER)(HAL_SOFTC sc, u_int32_t offset, void *pBuffer, u_int32_t length);

struct ath_hal_callback {
    /* Callback Functions */
    HAL_BUS_CONFIG_READER read_pci_config_space;
};

#if NO_HAL
static inline struct ath_hal *_ath_hal_attach(u_int16_t devid, 
                                        HAL_ADAPTER_HANDLE osdev,
                                        HAL_SOFTC softc,
                                        HAL_BUS_CONTEXT *bus_context,
                                        struct hal_reg_parm *hal_conf_parm,
                                        const struct ath_hal_callback *cb,
                                        void* status)
{
	return NULL;
}
static inline void ath_hal_detach(struct ath_hal *a)
{
}
#else
extern  struct ath_hal *_ath_hal_attach(u_int16_t devid, 
                                        HAL_ADAPTER_HANDLE osdev,
                                        HAL_SOFTC,
                                        HAL_BUS_CONTEXT *bus_context,
                                        struct hal_reg_parm *hal_conf_parm,
                                        const struct ath_hal_callback *,
                                        void* status);
extern  void ath_hal_detach(struct ath_hal *);
#endif

#ifdef __KERNEL__
/*
 * Atomic interface
 */
typedef atomic_t os_atomic_t;

#define OS_ATOMIC_READ(_patomic_arg)           atomic_read((_patomic_arg))
#define OS_ATOMIC_SET(_patomic_arg, v)         atomic_set((_patomic_arg), (v))
//#define OS_ATOMIC_ADD(v, _patomic_arg)         atomic_add((v), (_patomic_arg))
#define OS_ATOMIC_INC(_patomic_arg)            atomic_inc((_patomic_arg))
#define OS_ATOMIC_DEC(_patomic_arg)            atomic_dec((_patomic_arg))
//#define OS_ATOMIC_DEC_AND_TEST(_patomic_arg)   (NdisInterlockedDecrement(_patomic_arg) == 0)

//#define OS_CMPXCHG(_m, _old, _new)             InterlockedCompareExchange(_m, _new, _old)
#endif


/*
 * Calculation of array length
 */
#ifndef ARRAY_LENGTH
#define ARRAY_LENGTH(a)         (sizeof(a) / sizeof((a)[0]))
#endif

#endif /* _ATH_AH_OSDEP_H_ */
