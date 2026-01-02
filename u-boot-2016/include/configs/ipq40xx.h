/*
 * Copyright (c) 2015-2017, The Linux Foundation. All rights reserved.
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

#ifndef _IPQ40XX_H
#define _IPQ40XX_H

/*
 * Beat the system! tools/scripts/make-asm-offsets uses
 * the following hard-coded define for both u-boot's
 * ASM offsets and platform specific ASM offsets :(
 */

#ifndef DO_DEPS_ONLY
#include <generated/asm-offsets.h>
#endif

#define CONFIG_IPQ40XX
#define CONFIG_IPQ_NO_RELOC
#define CONFIG_BOARD_EARLY_INIT_F
#define CONFIG_SYS_NO_FLASH
#define CONFIG_SYS_CACHELINE_SIZE	64
#define CONFIG_SKIP_LOWLEVEL_INIT
#define CONFIG_SYS_HZ			1000
#define CONFIG_SYS_VSNPRINTF
#define CONFIG_IPQ40XX_UART
#define CONFIG_CONS_INDEX		1
#define CONFIG_FIT_DISABLE_SHA256

#define CONFIG_BAUDRATE			115200
#define CONFIG_SYS_BAUDRATE_TABLE	{4800, 9600, 19200, 38400, 57600,\
								115200}
#define V_PROMPT			"(IPQ40xx) # "
#define CONFIG_SYS_CBSIZE		(256 * 2) /* Console I/O Buffer Size */
#define CONFIG_SYS_MAXARGS		16
#define CONFIG_SYS_PBSIZE		(CONFIG_SYS_CBSIZE + \
						sizeof(CONFIG_SYS_PROMPT) + 16)

#define TLMM_BASE			0x01000000
#define GPIO_CONFIG_ADDR(x)		(TLMM_BASE + (x)*0x1000)
#define GPIO_IN_OUT_ADDR(x)		(TLMM_BASE + 0x4 + (x)*0x1000)

#define HAVE_BLOCK_DEVICE
#define CONFIG_SYS_SDRAM_BASE		0x80000000
#define CONFIG_SYS_TEXT_BASE		0x87300000
#define CONFIG_SYS_SDRAM_SIZE		0x10000000
#define CONFIG_SYS_INIT_SP_ADDR 	(CONFIG_SYS_TEXT_BASE -\
						CONFIG_SYS_MALLOC_LEN -\
						CONFIG_ENV_SIZE -\
						GENERATED_BD_INFO_SIZE)
#define CONFIG_MAX_RAM_BANK_SIZE	CONFIG_SYS_SDRAM_SIZE
#define CONFIG_SYS_LOAD_ADDR		(CONFIG_SYS_SDRAM_BASE + (64 << 20))
#define CONFIG_DTB_LOAD_ADDR		(CONFIG_SYS_SDRAM_BASE + (96 << 20))
#define CONFIG_ROOTFS_LOAD_ADDR 	(CONFIG_SYS_SDRAM_BASE + (32 << 20))
#define CONFIG_NR_DRAM_BANKS		1
#define CONFIG_OF_LIBFDT		1

#ifdef CONFIG_IPQ40XX_I2C
#define CONFIG_SYS_I2C_QUP
#define CONFIG_CMD_I2C
#define CONFIG_DM_I2C
#endif

#define CONFIG_IPQ_APPSBL_IMG_TYPE	0x5

#define CONFIG_SYS_DEVICE_NULLDEV

/*
 * IPQ_TFTP_MIN_ADDR: Starting address of Linux HLOS region.
 * CONFIG_TZ_END_ADDR: Ending address of Trust Zone and starting
 * address of WLAN Area.
 * TFTP file can only be written in Linux HLOS region and WLAN AREA.
 */
#define IPQ_TFTP_MIN_ADDR		CONFIG_SYS_SDRAM_BASE
#define CONFIG_TZ_END_ADDR		0x88000000
#define CONFIG_SYS_SDRAM_END		(CONFIG_SYS_SDRAM_BASE + gd->ram_size)

#define CONFIG_QCA_UBOOT_OFFSET		0x7000000
#define CONFIG_UBOOT_END_ADDR		0x87400000

#define CONFIG_IPQ40XX_ENV
#define CONFIG_ENV_IS_IN_NAND

#define CONFIG_OF_COMBINE 1

#ifndef __ASSEMBLY__
#include <compiler.h>

extern loff_t board_env_offset;
extern loff_t board_env_range;
extern loff_t board_env_size;

#if !defined(__ASSEMBLY__)
#define INIT_STACK_SIZE		1024
typedef struct {
	uint8_t uboot[1024 * 1024 - INIT_STACK_SIZE];	/* ~1MB */
	uint8_t init_stack[INIT_STACK_SIZE];
	uint8_t sbl[1024 * 1024];				/* 1 MB */
	uint8_t cnss_debug[6 * 1024 * 1024];			/* 6 MB */
	uint8_t tz_apps[3 * 1024 * 1024];			/* 3 MB */
	uint8_t smem[512 * 1024];				/* 512 KB */
	uint8_t tz[1536 * 1024];				/* 1.5 MB */
} __attribute__ ((__packed__)) qca_mem_reserve_t;

#define QCA_MEM_RESERVE_SIZE(x)		sizeof(((qca_mem_reserve_t *)0)->x)
#define QCA_MEM_RESERVE_BASE(x)		\
	(CONFIG_SYS_TEXT_BASE + \
	 ((uint32_t)&(((qca_mem_reserve_t *)0)->x)))
#endif/*__ASSEMBLY__*/

#define CONFIG_QCA_SMEM_BASE		0x87e00000
#define QCA_KERNEL_START_ADDR	\
	(CONFIG_SYS_SDRAM_BASE + sizeof(qca_mem_reserve_t))

#define QCA_DRAM_KERNEL_SIZE	\
	(CONFIG_SYS_SDRAM_SIZE - sizeof(qca_mem_reserve_t))

#define QCA_BOOT_PARAMS_ADDR	(QCA_KERNEL_START_ADDR + 0x100)
#endif
#define CONFIG_FLASH_PROTECT
#define CONFIG_CMD_FLASHWRITE

/* Environment */
#define CONFIG_ARCH_CPU_INIT
#define CONFIG_BOARD_LATE_INIT
#define CONFIG_ENV_OFFSET		board_env_offset
#define CONFIG_ENV_SIZE		CONFIG_ENV_SIZE_MAX
#define CONFIG_ENV_RANGE		board_env_range
#define CONFIG_ENV_SIZE_MAX		(256 << 10) /* 256 KB */
#define CONFIG_SYS_MALLOC_LEN		(CONFIG_ENV_SIZE_MAX + (2048 << 10))

#define CONFIG_CMD_MEMTEST
#define CONFIG_SYS_MEMTEST_START	CONFIG_SYS_SDRAM_BASE + 0x1300000
#define CONFIG_SYS_MEMTEST_END		CONFIG_SYS_MEMTEST_START + 0x100
#define CONFIG_CMD_SOURCE		1
#define CONFIG_INITRD_TAG		1
#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_SYS_NULLDEV
#define CONFIG_CMD_XIMG
#define CONFIG_IPQ_ETH_INIT_DEFER

/*
 * USB Support
 */

#ifdef CONFIG_USB_XHCI_IPQ
#define CONFIG_USB_XHCI
#define CONFIG_USB_XHCI_DWC3
#define CONFIG_CMD_USB
#define CONFIG_DOS_PARTITION
#define CONFIG_USB_STORAGE
#define CONFIG_SYS_USB_XHCI_MAX_ROOT_PORTS      2
#define CONFIG_USB_MAX_CONTROLLER_COUNT         2
#endif

/*
*Run command support
*/
#define	 CONFIG_CMD_RUN

/*
 * SPI NAND SUPPORT
 */
#define CONFIG_IPQ40XX_SPI_NAND
#ifdef CONFIG_IPQ40XX_SPI_NAND
#define CONFIG_SPI_NAND
#define CONFIG_SF_SPI_NAND_CS 1
#define CONFIG_IPQ_SPI_NAND_INFO_IDX  1
#endif
#define CONFIG_QUP_SPI_USE_DMA 1

/* L1 cache line size is 64 bytes, L2 cache line size is 128 bytes
 * Cache flush and invalidation based on L1 cache, so the cache line
 * size is configured to 64 */
#define CONFIG_SYS_CACHELINE_SIZE	64

#define CONFIG_QCA_BAM                 1
/*
 * NAND Flash Configs104
 */

/* CONFIG_QPIC_NAND: QPIC NAND in BAM mode107
 * CONFIG_IPQ_NAND: QPIC NAND in FIFO/block mode.108
 * BAM is enabled by default.109
 */
#define CONFIG_QPIC_NAND
#define CONFIG_CMD_NAND
#define CONFIG_SYS_NAND_ONFI_DETECTION

#define CONFIG_SYS_MAX_NAND_DEVICE      (CONFIG_IPQ_MAX_NAND_DEVICE + \
					CONFIG_IPQ_MAX_SPI_DEVICE)

#define CONFIG_IPQ_MAX_BLSP_QUPS	2
#define CONFIG_IPQ_MAX_SPI_DEVICE       2
#define CONFIG_IPQ_MAX_NAND_DEVICE      1

#define CONFIG_SYS_NAND_SELF_INIT
#define CONFIG_QPIC_NAND_NAND_INFO_IDX	0
#define CONFIG_IPQ_SPI_NOR_INFO_IDX	2

#define CONFIG_NAND_FLASH_INFO_IDX	CONFIG_QPIC_NAND_NAND_INFO_IDX
#define CONFIG_SPI_FLASH_INFO_IDX	CONFIG_IPQ_SPI_NOR_INFO_IDX

#define QCA_SPI_NOR_DEVICE		"spi0.0"

#define QCA_ROOT_FS_PART_NAME "rootfs"

/*
 * SPI Flash Configs
 */

#define CONFIG_QCA_SPI
#define CONFIG_SPI_FLASH
#define CONFIG_CMD_SF
#define CONFIG_SPI_FLASH_STMICRO
#define CONFIG_SPI_FLASH_SPANSION
#define CONFIG_SPI_FLASH_WINBOND
#define CONFIG_SPI_FLASH_MACRONIX
#define CONFIG_SPI_FLASH_GIGADEVICE
#define CONFIG_ENV_IS_IN_SPI_FLASH	1
#define CONFIG_ENV_SECT_SIZE        	(64 * 1024)

#define CONFIG_SPI_FLASH_USE_4K_SECTORS
#define CONFIG_SPI_NOR_GENERIC
#define CONFIG_SF_DEFAULT_BUS 0
#define CONFIG_SF_DEFAULT_CS 0
#define CONFIG_SF_DEFAULT_MODE SPI_MODE_0
#define CONFIG_SF_DEFAULT_SPEED	(48 * 1000 * 1000)
#define CONFIG_SPI_FLASH_BAR    1

#define CONFIG_ENV_OVERWRITE
#define CONFIG_CMD_PING
#define CONFIG_CMD_DHCP
#define CONFIG_IPQ40XX_ESS	1
#define CONFIG_IPQ40XX_EDMA     1
#define CONFIG_NET_RETRY_COUNT          5
#define CONFIG_SYS_RX_ETH_BUFFER        16
#define CONFIG_IPQ_MDIO     	1
#define CONFIG_QCA8075_PHY      1
#define CONFIG_QCA8033_PHY      1
#define CONFIG_MII
#define CONFIG_CMD_MII
#define CONFIG_IPADDR   192.168.1.11
#define CONFIG_IPQ_NO_MACS      2

#define CONFIG_MTD_DEVICE
#define CONFIG_MTD_PARTITIONS
#define CONFIG_CMD_MTDPARTS
#define NUM_ALT_PARTITION	8

#define CONFIG_CMD_UBI
#define CONFIG_RBTREE
#define CONFIG_CMD_BOOTZ
#define CONFIG_SYS_BOOTM_LEN   (64 << 20)
#define CONFIG_IPQ_FDT_HIGH     0x87000000
#define CONFIG_OF_BOARD_SETUP 1

#define TCSR_BOOT_MISC_REG	((u32 *)0x193D100)

#ifdef CONFIG_OF_BOARD_SETUP
#define DLOAD_DISABLE		(~BIT(4))
#define DLOAD_ENABLE		BIT(4)
#define RESERVE_ADDRESS_START	0x87B00000 /*TZAPPS, SMEM and TZ Regions */
#define RESERVE_ADDRESS_SIZE	0x500000

#define SET_MAGIC				0x1
#define CLEAR_MAGIC				0x0
#define SCM_CMD_TZ_CONFIG_HW_FOR_RAM_DUMP_ID	0x9
#define SCM_CMD_TZ_FORCE_DLOAD_ID		0x10
#define BOOT_VERSION				0
#define TZ_VERSION				1
#endif

#define CONFIG_FDT_FIXUP_PARTITIONS
#define CONFIG_BOOTCOMMAND "bootipq"

#define CONFIG_BOOTDELAY	2

#define CONFIG_LIB_UUID

#define CONFIG_SMP_CMD_SUPPORT

#ifdef CONFIG_SMP_CMD_SUPPORT
#define NR_CPUS				4
#endif

/*
 * CRASH DUMP ENABLE
 */

#define CONFIG_QCA_APPSBL_DLOAD	1

#ifdef CONFIG_QCA_APPSBL_DLOAD
#define CONFIG_CMD_TFTPPUT
/* We will be uploading very big files */
#undef CONFIG_NET_RETRY_COUNT
#define CONFIG_NET_RETRY_COUNT	500

#define IPQ_TEMP_DUMP_ADDR 0
#endif

#define CONFIG_QCA_KERNEL_CRASHDUMP_ADDRESS	0x87B00000
#define CONFIG_CPU_CONTEXT_DUMP_SIZE		0x70000
#define TLV_BUF_OFFSET				0x70000
#define CONFIG_TLV_DUMP_SIZE			0x10000
#define CONFIG_QCA_MMC				1

#ifdef CONFIG_QCA_MMC
#define CONFIG_MMC
#define CONFIG_ENV_IS_IN_MMC
#define CONFIG_CMD_MMC
#define CONFIG_SDHCI
#define CONFIG_SDHCI_QCA
#define CONFIG_GENERIC_MMC
#define CONFIG_EFI_PARTITION
#define CONFIG_SYS_MMC_ENV_DEV  0
#define CONFIG_SDHCI_SUPPORT
#define CONFIG_MMC_ADMA
#endif

#define PCI_MAX_DEVICES	1
#ifdef CONFIG_PCI_IPQ
#define CONFIG_PCI
#define CONFIG_CMD_PCI
#define CONFIG_PCI_SCAN_SHOW
#endif

#undef CONFIG_IPQ_ROOTFS_AUTH

#define CONFIG_IPQ_4B_ADDR_SWITCH_REQD
#endif /* _IPQ40XX_H */
