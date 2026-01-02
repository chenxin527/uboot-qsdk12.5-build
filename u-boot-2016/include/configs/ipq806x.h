/*
 * Copyright (c) 2012-2015 The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef _IPQ806x_CDP_H
#define _IPQ806x_CDP_H

/*
 * Disabled for actual chip.
 * #define CONFIG_RUMI
 */
#if !defined(DO_DEPS_ONLY) || defined(DO_SOC_DEPS_ONLY)
/*
 * Beat the system! tools/scripts/make-asm-offsets uses
 * the following hard-coded define for both u-boot's
 * ASM offsets and platform specific ASM offsets :(
 */
#include <generated/generic-asm-offsets.h>
#ifdef __ASM_OFFSETS_H__
#undef __ASM_OFFSETS_H__
#endif
#if !defined(DO_SOC_DEPS_ONLY)
#include <generated/asm-offsets.h>
#endif
#endif /* !DO_DEPS_ONLY */

#define CONFIG_IPQ806X
#define CONFIG_IPQ_NO_RELOC
#define CONFIG_SMP_CMD_SUPPORT
#ifdef CONFIG_SMP_CMD_SUPPORT
#define NR_CPUS				2
#endif

#define CONFIG_SYS_NO_FLASH
#define CONFIG_SYS_CACHELINE_SIZE   64
#define CONFIG_IPQ806X_ENV
#define CONFIG_SYS_BOOTM_LEN		(64 << 20)
#define CONFIG_IPQ_FDT_HIGH		0xffffffff
#define CONFIG_BOOTARGS			"console=ttyMSM0,115200n8"
#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_SYS_VSNPRINTF
#define CONFIG_FIT_DISABLE_SHA256

#define CONFIG_MBN_HEADER
#define CONFIG_IPQ_APPSBL_IMG_TYPE	0x5

#ifdef CONFIG_USB_XHCI_IPQ
#define CONFIG_USB_XHCI
#define CONFIG_USB_XHCI_DWC3
#define CONFIG_CMD_USB
#define CONFIG_DOS_PARTITION
#define CONFIG_USB_STORAGE
#define CONFIG_SYS_USB_XHCI_MAX_ROOT_PORTS 2
#define CONFIG_USB_MAX_CONTROLLER_COUNT 2
#endif

#define CONFIG_IPQ806X_UART
#undef CONFIG_CMD_FLASH
#undef CONFIG_CMD_FPGA		        /* FPGA configuration support */
#undef CONFIG_CMD_IMI
#undef CONFIG_CMD_IMLS
#undef CONFIG_CMD_NFS		        /* NFS support */
#define CONFIG_CMD_NET		        /* network support */
#define CONFIG_CMD_DHCP
#undef CONFIG_SYS_MAX_FLASH_SECT
#define CONFIG_NR_DRAM_BANKS            1
#define CONFIG_SKIP_LOWLEVEL_INIT
#define CONFIG_CMD_PING

#define CONFIG_IPQ_SNPS_GMAC
#define CONFIG_MII
#define CONFIG_CMD_MII
#define CONFIG_BITBANGMII
#define CONFIG_BITBANGMII_MULTI

#define CONFIG_IPQ_SWITCH_ATHRS17
#define CONFIG_IPQ_SWITCH_QCA8511

#define CONFIG_SYS_RX_ETH_BUFFER        8
#define CONFIG_IPQ_NO_MACS		4

#undef CONFIG_BOARD_EARLY_INIT_F

#undef CONFIG_HW_WATCHDOG

#define CONFIG_SYS_DEVICE_NULLDEV
#define CONFIG_FLASH_PROTECT
#define CONFIG_CMD_FLASHWRITE

/* Environment */
#define CONFIG_MSM_PCOMM
#define CONFIG_ARCH_CPU_INIT

#define CONFIG_ENV_SIZE			CONFIG_ENV_SIZE_MAX
#define CONFIG_ENV_RANGE		board_env_range
#define CONFIG_ENV_SIZE_MAX             (256 << 10) /* 256 KB */
#define CONFIG_SYS_MALLOC_LEN           (CONFIG_ENV_SIZE_MAX + (512 << 10))

/*
*Run command support
*/
#define	CONFIG_CMD_RUN

/*
 * select serial console configuration
 */
#define CONFIG_CONS_INDEX		1

/* allow to overwrite serial and ethaddr */
#define CONFIG_ENV_OVERWRITE
#define CONFIG_BAUDRATE			115200
#define CONFIG_SYS_BAUDRATE_TABLE	{4800, 9600, 19200, 38400, 57600,\
	115200}

#define V_PROMPT			"(IPQ) # "
#ifndef CONFIG_SYS_PROMPT
#define CONFIG_SYS_PROMPT		V_PROMPT
#endif
#define CONFIG_SYS_CBSIZE		(512 * 2) /* Console I/O Buffer Size */

#define CONFIG_SYS_INIT_SP_ADDR		(CONFIG_SYS_TEXT_BASE - CONFIG_SYS_MALLOC_LEN - CONFIG_ENV_SIZE - GENERATED_BD_INFO_SIZE)
#define CONFIG_SYS_MAXARGS		16
#define CONFIG_SYS_PBSIZE		(CONFIG_SYS_CBSIZE + \
		sizeof(CONFIG_SYS_PROMPT) + 16)

#define CONFIG_SYS_SDRAM_BASE		0x40000000
#define CONFIG_SYS_TEXT_BASE		0x42000000
#define CONFIG_SYS_SDRAM_SIZE		0x10000000
#define CONFIG_MAX_RAM_BANK_SIZE	CONFIG_SYS_SDRAM_SIZE
#define CONFIG_SYS_LOAD_ADDR		(CONFIG_SYS_SDRAM_BASE + (64 << 20))
#define CONFIG_ROOTFS_LOAD_ADDR 	(CONFIG_SYS_SDRAM_BASE + (96 << 20))

#define QCA_KERNEL_START_ADDR		CONFIG_SYS_SDRAM_BASE
#define QCA_BOOT_PARAMS_ADDR		(QCA_KERNEL_START_ADDR + 0x100)
#define CONFIG_QCA_SMEM_BASE		CONFIG_SYS_SDRAM_BASE + 0x1000000

#define CONFIG_QCA_UBOOT_OFFSET		0x1D00000
#define CONFIG_UBOOT_END_ADDR		0x42100000

#define CONFIG_OF_COMBINE		1

#define CONFIG_CMD_BOOTZ

/*
 * I2C Configs
 */
#ifdef CONFIG_IPQ806X_I2C
#define CONFIG_SYS_I2C_QUP
#define CONFIG_CMD_I2C
#define CONFIG_DM_I2C
#endif

/*
 * PCI Configs
 */
#define PCI_MAX_DEVICES	3
#ifdef CONFIG_PCI_IPQ
#define CONFIG_PCI
#define CONFIG_CMD_PCI
#define CONFIG_PCI_SCAN_SHOW
#endif


/*
 * MMC Configs
 */
#define CONFIG_QCA_MMC

#ifdef CONFIG_QCA_MMC
#define CONFIG_CMD_MMC
#define CONFIG_MMC
#define CONFIG_EFI_PARTITION
#define CONFIG_GENERIC_MMC
#define CONFIG_ENV_IS_IN_MMC
#define CONFIG_SYS_MMC_ENV_DEV		0
#endif

#define QCA_ROOT_FS_PART_NAME		"rootfs"
/*
 * CRASH DUMP ENABLE
 */

#define CONFIG_QCA_APPSBL_DLOAD 1
#ifdef CONFIG_QCA_APPSBL_DLOAD
#define CONFIG_CMD_TFTPPUT
/* We will be uploading very big files */
#undef CONFIG_NET_RETRY_COUNT
#define CONFIG_NET_RETRY_COUNT 500
#endif

#ifndef __ASSEMBLY__
#include <compiler.h>

/*
 * XXX XXX Please do not instantiate this structure. XXX XXX
 * This is just a convenience to avoid
 *      - adding #defines for every new reservation
 *      - updating the multiple associated defines like smem base,
 *        kernel start etc...
 *      - re-calculation of the defines if the order changes or
 *        some reservations are deleted
 * For new reservations just adding a member to the structure should
 * suffice.
 * Ensure that the size of this structure matches with the definition
 * of the following IPQ806x compile time definitions
 *      PHYS_OFFSET     (linux-sources/arch/arm/mach-msm/Kconfig)
 *      zreladdr        (linux-sources/arch/arm/mach-msm/Makefile.boot)
 *      CONFIG_SYS_INIT_SP_ADDR defined above should point to the bottom.
 *      MSM_SHARED_RAM_PHYS (linux-sources/arch/arm/mach-msm/board-ipq806x.c)
 *
 */

extern loff_t board_env_offset;
extern loff_t board_env_range;
extern loff_t board_env_size;

#if !defined(DO_DEPS_ONLY) || defined(DO_SOC_DEPS_ONLY)
typedef struct {
	uint8_t nss[16 * 1024 * 1024];
	uint8_t smem[2 * 1024 * 1024];
#ifdef CONFIG_QCA_APPSBL_DLOAD
	uint8_t uboot[1 * 1024 * 1024];
	uint8_t nsstcmdump[128 * 1024];
	uint8_t sbl3[384 * 1024];
	uint8_t plcfwdump[512*1024];
	uint8_t wlanfwdump[(1 * 1024 * 1024) - GENERATED_GBL_DATA_SIZE];
	uint8_t init_stack[GENERATED_GBL_DATA_SIZE];
#endif
} __attribute__ ((__packed__)) ipq_mem_reserve_t;

/* Convenience macros for the above convenience structure :-) */
#define IPQ_MEM_RESERVE_SIZE(x)         sizeof(((ipq_mem_reserve_t *)0)->x)
#define IPQ_MEM_RESERVE_BASE(x)         \
	(CONFIG_SYS_SDRAM_BASE + \
	((uint32_t)&(((ipq_mem_reserve_t *)0)->x)))
#endif

#define IPQ_NSSTCM_DUMP_ADDR            (IPQ_MEM_RESERVE_BASE(nsstcmdump))
#define IPQ_TEMP_DUMP_ADDR              (IPQ_MEM_RESERVE_BASE(nsstcmdump))

#define IPQ_TFTP_MIN_ADDR		(CONFIG_SYS_SDRAM_BASE + (64 << 20))
#define IPQ_TFTP_MAX_ADDR		(gd->bd->bi_dram[0].start +	\
					 gd->bd->bi_dram[0].size)


#define CONFIG_QCA_SMEM_BASE	CONFIG_SYS_SDRAM_BASE + 0x1000000
#endif /* __ASSEMBLY__ */

#ifndef CONFIG_FIT
#define CONFIG_FIT
#endif
#define CONFIG_SYS_NULLDEV
#define CONFIG_CMD_XIMG

/*Support for Compressed DTB image*/
#ifdef CONFIG_FIT
#define CONFIG_DTB_COMPRESSION
#define CONFIG_DTB_LOAD_MAXLEN		0x100000
#endif

/*
 * SPI Flash Configs
 */
#define CONFIG_QCA_SPI
#define CONFIG_SPI_FLASH
#define CONFIG_CMD_SF
#define CONFIG_SPI_FLASH_STMICRO
#define CONFIG_SPI_FLASH_SPANSION
#define CONFIG_SPI_FLASH_MACRONIX
#define CONFIG_SPI_FLASH_WINBOND
#define CONFIG_ENV_IS_IN_SPI_FLASH	1
#define CONFIG_ENV_SECT_SIZE        	(64 * 1024)

#define CONFIG_SPI_FLASH_USE_4K_SECTORS
#define CONFIG_SF_DEFAULT_BUS 0
#define CONFIG_SF_DEFAULT_CS 0
#define CONFIG_SF_DEFAULT_SPEED         (48 * 1000 * 1000)
#define CONFIG_SF_DEFAULT_MODE SPI_MODE_0

#define CONFIG_SPI_FLASH_BAR

/*
 *MTEST Configs
 */
#define CONFIG_SYS_MEMTEST_START	CONFIG_SYS_SDRAM_BASE + 0x1300000
#define CONFIG_SYS_MEMTEST_END		CONFIG_SYS_MEMTEST_START + 0x100


/*NAND Flash Configs*/
#define CONFIG_CMD_NAND
#define CONFIG_IPQ_NAND
#define CONFIG_SYS_NAND_ONFI_DETECTION
#define CONFIG_SYS_NAND_SELF_INIT

#define CONFIG_IPQ_MAX_SPI_DEVICE	1
#define CONFIG_IPQ_MAX_NAND_DEVICE	1

#define CONFIG_SYS_MAX_NAND_DEVICE	(CONFIG_IPQ_MAX_NAND_DEVICE + \
		CONFIG_IPQ_MAX_SPI_DEVICE)

#define CONFIG_IPQ_NAND_NAND_INFO_IDX	0
#define CONFIG_IPQ_SPI_NOR_INFO_IDX	1

#define CONFIG_NAND_FLASH_INFO_IDX	CONFIG_IPQ_NAND_NAND_INFO_IDX
#define CONFIG_SPI_FLASH_INFO_IDX	CONFIG_IPQ_SPI_NOR_INFO_IDX

#define QCA_SPI_NOR_DEVICE		"nand1"

#define CONFIG_FDT_FIXUP_PARTITIONS
#define NUM_ALT_PARTITION		8

#define CONFIG_MTD_DEVICE
#define CONFIG_MTD_PARTITIONS
#define CONFIG_CMD_MTDPARTS

#define CONFIG_BOOTDELAY 2
#define CONFIG_BOOTCOMMAND  "bootipq"

#define CONFIG_BOARD_LATE_INIT

#define CONFIG_ENV_IS_IN_NAND
#define CONFIG_ENV_OFFSET board_env_offset

/*for ubi*/
#define CONFIG_CMD_UBI
#define CONFIG_RBTREE

#define CONFIG_OF_LIBFDT		1
#define CONFIG_OF_BOARD_SETUP		1

#ifdef CONFIG_OF_BOARD_SETUP
#define DLOAD_DISABLE		(~BIT(4))
#define DLOAD_ENABLE		BIT(4)
#define BOOT_VERSION			0
#define TZ_VERSION			1
#endif

/* L1 cache line size is 64 bytes, L2 cache line size is 128 bytes
 * Cache flush and invalidation based on L1 cache, so the cache line
 * size is configured to 64 */
#define CONFIG_SYS_CACHELINE_SIZE  64
/*#define CONFIG_SYS_DCACHE_OFF*/

/* Enabling this flag will report any L2 errors.
 * By default we are disabling it */
#define CONFIG_IPQ_REPORT_L2ERR

/*
 * Location in IMEM which contains the physical address of
 * 4K page allocated from kernel for storing the crashdump data
 */
#define CONFIG_QCA_KERNEL_CRASHDUMP_ADDRESS	*((unsigned int *)0x2A03F658)
#define CONFIG_CPU_CONTEXT_DUMP_SIZE		2048
#define TLV_BUF_OFFSET				2048
#define CONFIG_TLV_DUMP_SIZE			2048
#define SCM_CMD_TZ_CONFIG_HW_FOR_RAM_DUMP_ID	0xFFFFFFFF /* Invalid CMD ID */
#define SCM_CMD_TZ_FORCE_DLOAD_ID		0xFFFFFFFF /* Invalid CMD ID */

/*
 * CRASH DUMP ENABLE
 */

#define CONFIG_QCA_APPSBL_DLOAD 1

#define TLMM_BASE_ADDR      0x00800000
#define GPIO_CONFIG_ADDR(x) (TLMM_BASE_ADDR + 0x1000 + (x)*0x10)
#define GPIO_IN_OUT_ADDR(x) (TLMM_BASE_ADDR + 0x1004 + (x)*0x10)

#undef CONFIG_IPQ_ROOTFS_AUTH

#endif /* _IPQ806x_CDP_H */

