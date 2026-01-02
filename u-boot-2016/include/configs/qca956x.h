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

#define CONFIG_MIPS32       1   /* MIPS32 CPU core  */
#define CONFIG_BOOTDELAY    2   /* autoboot after 4 seconds */
#define CONFIG_TIMESTAMP        /* Print image info with timestamp */

#define CONFIG_MII	1
#define CFG_CMD_MII	1
#define CONFIG_COMMANDS 1

#if pll
#define CFG_PLL_FREQ (pll)
#else
#define CFG_PLL_FREQ CFG_PLL_750_400_250
#endif

#if ddr_cas
#define CFG_DDR2_DRAGONFLY_CAS_LATENCY ddr_cas
#else
#define CFG_DDR2_DRAGONFLY_CAS_LATENCY 5
#endif

#if ATH_SGMII_FORCED
#define ATH_SGMII_FORCED_MODE    1
#endif

#if CONFIG_AP152
#define CFG_ATH_GMAC_NMACS      1
#define CFG_ATH_GE1_IS_CONNECTED 1
#define CONFIG_ATHRS_GMAC_SGMII  1
#define ATH_S17_MAC0_SGMII      1
#define CONFIG_ATHRS_GMAC_SGMII 1
#define CONFIG_ATHRS17_PHY      1
#define UART_RX18_TX22  1
#define __CONFIG_BOARD_NAME ap152
#define CONFIG_BOARD_NAME "ap152"
#endif

#if CONFIG_AP151
#define CFG_ATH_GMAC_NMACS	2
#define CFG_ATH_GE1_IS_CONNECTED 1
#define CFG_ATHRS27_PHY	1
#define UART_RX18_TX20	1
#define __CONFIG_BOARD_NAME ap151
#define CONFIG_BOARD_NAME "ap151"
#endif

#define CONFIG_DISPLAY_BOARDINFO 1
#define CONFIG_CUSTOM_BOARDINFO 1

#define BOARDCAL 0x9fff0000
#define CONFIG_SYS_RX_ETH_BUFFER 8
#define CONFIG_TFTP_BLOCKSIZE 512

#define CONFIG_SYS_CACHELINE_SIZE 32
#define CONFIG_SYS_ICACHE_SIZE 65536
#define CONFIG_SYS_DCACHE_SIZE 32768

#define CONFIG_SYS_LOAD_ADDR 0x81000000

#define CONFIG_LZMA 1
#define CONFIG_ATHEROS	1
#define CONFIG_IMAGE_FORMAT_LEGACY
#define CONFIG_SYS_SDRAM_BASE	0x80000000
#define CONFIG_SYS_INIT_SP_OFFSET 0xbd001800 // Redundant ?
#define CFG_INIT_SRAM_SP_OFFSET 0xbd001800

#define CONFIG_SYS_MAXARGS 16
#define CONFIG_SYS_FLASH_BASE 0x9f000000
#define CONFIG_SYS_MAX_FLASH_BANKS      1
#define CONFIG_SYS_MAX_FLASH_SECT       256

#define CONFIG_BAUDRATE 115200
#define CONFIG_SYS_BAUDRATE_TABLE  {115200}
#define CONFIG_LAST_STAGE_INIT
#define CONFIG_SYS_TEXT_BASE 0x9f000000

/* Console I/O Buffer Size */
#define CONFIG_SYS_CBSIZE               512
/* Print Buffer Size */
#define CONFIG_SYS_PBSIZE (CONFIG_SYS_CBSIZE+sizeof(CONFIG_SYS_PROMPT)+16)

#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_SYS_PROMPT_HUSH_PS2	"hush>"

/* Timer Specific */
#define CONFIG_SYS_MHZ	775
/* Since the count is incremented every other tick, divide by 2 -- CFG_HZ*/
#define CONFIG_SYS_MIPS_TIMER_FREQ      ((CONFIG_SYS_MHZ * 1000000)/2)

/*
 * The following #defines are needed to get flash environment right
 */
#define CONFIG_SYS_MONITOR_BASE 0x9f000000
#define CONFIG_SYS_MONITOR_LEN  (192 << 10)
#define CONFIG_SYS_MALLOC_LEN (128*1024)
#define CONFIG_SYS_BOOTPARAMS_LEN (64*1024)

#ifndef FLASH_SIZE
#define FLASH_SIZE 16
#endif


/*-----------------------------------------------------------------------
 * FLASH and environment organization
 */
#define CFG_MAX_FLASH_BANKS     1       /* max number of memory banks */
#if (FLASH_SIZE == 16)
#define CFG_MAX_FLASH_SECT      256     /* max number of sectors on one chip */
#define ATH_MTDPARTS_MIB0       "64k(mib0)"
#elif (FLASH_SIZE == 8)
#define CFG_MAX_FLASH_SECT      128     /* max number of sectors on one chip */
#define ATH_MTDPARTS_MIB0       "64k(mib0)"
#elif (FLASH_SIZE == 4)
#define CFG_MAX_FLASH_SECT      64      /* max number of sectors on one chip */
#define ATH_MTDPARTS_MIB0       "64k(mib0)"
#elif (FLASH_SIZE == 2)
#define CFG_MAX_FLASH_SECT      32      /* max number of sectors on one chip */
#define ATH_MTDPARTS_MIB0       "64k(mib0)"
#else
#       error "Invalid flash Size/sector "
#endif

#define CFG_FLASH_SECTOR_SIZE   (64*1024)
#if (FLASH_SIZE == 16)
#define CFG_FLASH_SIZE          0x01000000      /* Total flash size */
#elif (FLASH_SIZE == 8)
#define CFG_FLASH_SIZE          0x00800000      /* max number of sectors on one chip */
#elif (FLASH_SIZE == 4)
#define CFG_FLASH_SIZE          0x00400000      /* Total flash size */
#elif (FLASH_SIZE == 2)
#define CFG_FLASH_SIZE          0x00200000      /* Total flash size */
#else
#       error "Invalid flash Size "
#endif

#if defined(CONFIG_ATH_NAND_BR) && defined(COMPRESSED_UBOOT)
#define CFG_FLASH_BASE                  0xa0100000
#else
/* NOR Flash start address */
#define CFG_FLASH_BASE                  0x9f000000
#endif

#ifdef COMPRESSED_UBOOT
#define BOOTSTRAP_TEXT_BASE             CFG_FLASH_BASE
#define BOOTSTRAP_CFG_MONITOR_BASE      BOOTSTRAP_TEXT_BASE
#endif

/*
 * Defines to change flash size on reboot
 */
#ifdef ENABLE_DYNAMIC_CONF
#define UBOOT_FLASH_SIZE                (256 * 1024)
#define UBOOT_ENV_SEC_START             (CFG_FLASH_BASE + UBOOT_FLASH_SIZE)

#define CFG_FLASH_MAGIC                 0xaabacada
#define CFG_FLASH_MAGIC_F               (UBOOT_ENV_SEC_START + CFG_FLASH_SECTOR_SIZE - 0x20)
#define CFG_FLASH_SECTOR_SIZE_F         *(volatile int *)(CFG_FLASH_MAGIC_F + 0x4)
#define CFG_FLASH_SIZE_F                *(volatile int *)(CFG_FLASH_MAGIC_F + 0x8) /* Total flash size */
#define CFG_MAX_FLASH_SECT_F            (CFG_FLASH_SIZE / CFG_FLASH_SECTOR_SIZE) /* max number of sectors on one chip */
#else
#define CFG_FLASH_SIZE_F                CFG_FLASH_SIZE
#define CFG_FLASH_SECTOR_SIZE_F         CFG_FLASH_SECTOR_SIZE
#endif

#define	CONFIG_ENV_IS_IN_FLASH	1
#define CONFIG_ENV_SIZE	CFG_FLASH_SECTOR_SIZE //CFG_ENV_SIZE
#define	CONFIG_ENV_ADDR	0x9f040000

#define CONFIG_SYS_TEXT_BASE 0x9f000000
#define CONFIG_ATH_SOC 1
#define CONFIG_MACH_QCA956x 1

// DDR2
// 0x40c3   25MHz
// 0x4138   40MHz
// DDR1
// 0x4186   25Mhz
// 0x4270   40Mhz

#define CFG_DDR_REFRESH_VAL	0x4186
#define CFG_DDR2_REFRESH_VAL	0x40c3

#define CONFIG_PCI_CONFIG_DATA_IN_OTP

#if defined(CONFIG_CUS249) || defined(CONFIG_TB753)
#else
#define CONFIG_PCI 1
#define CONFIG_CMD_PCI
#define CONFIG_PCI_SCAN_SHOW
#define CONFIG_USB 1
#endif

/*
** Parameters defining the location of the calibration/initialization
** information for the two Merlin devices.
** NOTE: **This will change with different flash configurations**
*/

#define WLANCAL                         0x9fff1000

/* For Merlin, both PCI, PCI-E interfaces are valid */
#define ATH_ART_PCICFG_OFFSET           12


