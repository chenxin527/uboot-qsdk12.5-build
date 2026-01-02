/*
 * Copyright (c) 2016 The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 */

#include <common.h>
#include <command.h>
#include <asm/mipsregs.h>

#if defined(CONFIG_AR7100)
#include <asm/addrspace.h>
#include <ar7100_soc.h>
#endif

#if defined(CONFIG_AR7240)
#include <asm/addrspace.h>
#include <ar7240_soc.h>
#endif

#if defined(CONFIG_ATHEROS)
#include <asm/addrspace.h>
#include <atheros.h>
#endif

static inline void mips_compare_set(u32 v)
{
        asm volatile ("mtc0 %0, $11" : : "r" (v));
}

static inline void mips_count_set(u32 v)
{
        asm volatile ("mtc0 %0, $9" : : "r" (v));
}


static inline u32 mips_count_get(void)
{
        u32 count;

        asm volatile ("mfc0 %0, $9" : "=r" (count) :);
        return count;
}

/*
 * timer without interrupts
 */

int timer_init(void)
{
        mips_compare_set(0);
        mips_count_set(0);
        return 0;
}

void  _machine_restart(void)
{
#if defined(CONFIG_ATHEROS)
        while (1) {
                ath_reg_wr(RST_RESET_ADDRESS, RST_RESET_FULL_CHIP_RESET_SET(1));
        }
#elif defined(CONFIG_INCA_IP)
        *INCA_IP_WDT_RST_REQ = 0x3f;
#elif defined(CONFIG_PURPLE) || defined(CONFIG_TB0229)
        void (*f)(void) = (void *) 0xbfc00000;

        f();
#elif defined(CONFIG_AR7100)
#ifndef COMPRESSED_UBOOT
        fprintf(stdout, "\nResetting...\n");
#endif  /* #ifndef COMPRESSED_UBOOT */
        for (;;) {
                ar7100_reg_wr(AR7100_RESET,
                        (AR7100_RESET_FULL_CHIP | AR7100_RESET_DDR));
        }
#elif defined(CONFIG_AR7240)
#ifndef COMPRESSED_UBOOT
        fprintf(stdout, "\nResetting...\n");
#endif  /* #ifndef COMPRESSED_UBOOT */
        for (;;) {
#ifdef CONFIG_WASP
                if (ar7240_reg_rd(AR7240_REV_ID) & 0xf) {
                        ar7240_reg_wr(AR7240_RESET,
                                (AR7240_RESET_FULL_CHIP | AR7240_RESET_DDR));
                } else {
                        /*
                         * WAR for full chip reset spi vs. boot-rom selection
                         * bug in wasp 1.0
                         */
                        ar7240_reg_wr (AR7240_GPIO_OE,
                                ar7240_reg_rd(AR7240_GPIO_OE) & (~(1 << 17)));
                }
#else
                ar7240_reg_wr(AR7240_RESET,
                        (AR7240_RESET_FULL_CHIP | AR7240_RESET_DDR));
#endif
        }
#endif
#ifndef COMPRESSED_UBOOT
        fprintf(stderr, "*** reset failed ***\n");
#endif  /* #ifndef COMPRESSED_UBOOT */
        return 0;
}


