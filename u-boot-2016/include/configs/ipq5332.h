/*
* Copyright (c) 2016-2019, The Linux Foundation. All rights reserved.
*
* Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
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

#ifndef _IPQ5332_H
#define _IPQ5332_H

#ifndef DO_DEPS_ONLY
#include <generated/asm-offsets.h>
#endif

#define CONFIG_IPQ5332
#undef	CONFIG_QCA_DISABLE_SCM
#define CONFIG_SPI_FLASH_CYPRESS
#define CONFIG_SYS_NO_FLASH
#define CONFIG_IPQ_NO_RELOC

#define CONFIG_CMD_AES
#define CONFIG_CMD_AES_256
#define CONFIG_IPQ_DERIVE_KEY

#ifndef CONFIG_IPQ_TINY
#define CONFIG_SYS_NONCACHED_MEMORY     	(1 << 20)
#endif /* CONFIG_IPQ_TINY */

#define CONFIG_SYS_VSNPRINTF

/*
 * Enable Early and Late init
 * This config needs for secondary boot and to set BADOFF5E
 * This config also need for spi-nor boot,
 * set size and offset of hlos and rootfs
*/
#define CONFIG_BOARD_EARLY_INIT_F
#define CONFIG_BOARD_LATE_INIT

#define CONFIG_IPQ5332_UART
#define CONFIG_NR_DRAM_BANKS			1
#define CONFIG_SKIP_LOWLEVEL_INIT

#define CONFIG_SYS_BOOTM_LEN			0x4000000

#define CONFIG_ENV_SIZE_MAX			(256 << 10) /* 256 KB */

/*
 * Enable MIBIB reload
 */
#define CONFIG_IPQ_MIBIB_RELOAD
#define CONFIG_IPQ_XTRACT_N_FLASH

/*
 * Enable Flashwrite command
 */
#define CONFIG_CMD_FLASHWRITE

/*
 * Enable Env overwrite support
 */
#define CONFIG_ENV_OVERWRITE

/*
 * select serial console configuration
*/
#define CONFIG_CONS_INDEX			1
#define CONFIG_SYS_DEVICE_NULLDEV

/* allow to overwrite serial and ethaddr */
#define CONFIG_BAUDRATE				115200
#define CONFIG_SYS_BAUDRATE_TABLE		{4800, 9600, 19200, 38400, 57600,\
						115200}

#define CONFIG_SYS_CBSIZE			(512 * 2) /* Console I/O Buffer Size */
/*

		svc_sp     --> --------------
		irq_sp     --> |            |
		fiq_sp     --> |            |
		bd         --> |            |
		gd         --> |            |
		pgt        --> |            |
		malloc     --> |            |
		text_base  --> |------------|
*/

#define CONFIG_SYS_INIT_SP_ADDR         	(CONFIG_SYS_TEXT_BASE -\
						CONFIG_SYS_MALLOC_LEN - CONFIG_ENV_SIZE -\
						GENERATED_BD_INFO_SIZE)

#define CONFIG_SYS_MAXARGS			16
#define CONFIG_SYS_PBSIZE			(CONFIG_SYS_CBSIZE + \
							sizeof(CONFIG_SYS_PROMPT) + 16)

#define TLMM_BASE				0x01000000
#define GPIO_CONFIG_ADDR(x)			(TLMM_BASE + (x)*0x1000)
#define GPIO_IN_OUT_ADDR(x)			(TLMM_BASE + 0x4 + (x)*0x1000)

#define CONFIG_SYS_SDRAM_BASE			0x40000000
#ifdef CONFIG_IPQ_TINY
#ifdef CONFIG_IPQ_TINY2
#define CONFIG_SYS_TEXT_BASE			0x4B050000
#define CONFIG_QCA_SMEM_SIZE			0x30000
#else
#define CONFIG_SYS_TEXT_BASE			0x4A450000
#endif
#define CONFIG_SYS_LOAD_ADDR                    (CONFIG_SYS_SDRAM_BASE + (64 << 20))
#define	CONFIG_IPQ_JFFS2_CLEANMARKER
#else
#define CONFIG_SYS_TEXT_BASE			0x4A400000
#define CONFIG_SYS_LOAD_ADDR                    (CONFIG_SYS_SDRAM_BASE + (256 << 20))
#endif
#define CONFIG_SYS_SDRAM_SIZE			0x10000000
#define CONFIG_MAX_RAM_BANK_SIZE		CONFIG_SYS_SDRAM_SIZE

#define QCA_KERNEL_START_ADDR			CONFIG_SYS_SDRAM_BASE
#define QCA_DRAM_KERNEL_SIZE			CONFIG_SYS_SDRAM_SIZE
#define QCA_BOOT_PARAMS_ADDR			(QCA_KERNEL_START_ADDR + 0x100)

#define CONFIG_OF_COMBINE			1

#define CONFIG_SMEM_VERSION_C
#define CONFIG_QCA_SMEM_BASE			0x4A800000

#define CONFIG_IPQ_FDT_HIGH			0x48500000
#define CONFIG_ENV_IS_IN_SPI_FLASH		1
#define CONFIG_ENV_SECT_SIZE			(64 * 1024)

#define CONFIG_QCA_UBOOT_OFFSET			0xA100000
#define CONFIG_UBOOT_END_ADDR			0x4A500000


#define CONFIG_SMP_CMD_SUPPORT

#ifdef CONFIG_SMP_CMD_SUPPORT
#define NR_CPUS				4

#define ARM_PSCI_TZ_FN_BASE			0x84000000
#define ARM_PSCI_TZ_FN(n)			(ARM_PSCI_TZ_FN_BASE + (n))

#define ARM_PSCI_TZ_FN_CPU_OFF			ARM_PSCI_TZ_FN(2)
#define ARM_PSCI_TZ_FN_CPU_ON			ARM_PSCI_TZ_FN(3)
#define ARM_PSCI_TZ_FN_AFFINITY_INFO		ARM_PSCI_TZ_FN(4)

#endif

/*
* IPQ_TFTP_MIN_ADDR: Starting address of Linux HLOS region.
* CONFIG_TZ_END_ADDR: Ending address of Trust Zone and starting
* address of WLAN Area.
* TFTP file can only be written in Linux HLOS region and WLAN AREA.
*/
#define IPQ_TFTP_MIN_ADDR			(CONFIG_SYS_SDRAM_BASE + (16 << 20))
#define CONFIG_TZ_END_ADDR			0x4AA00000
#define CONFIG_SYS_SDRAM_END			((long long)CONFIG_SYS_SDRAM_BASE + gd->ram_size)

#ifndef __ASSEMBLY__
#include <compiler.h>
extern loff_t board_env_offset;
extern loff_t board_env_range;
extern loff_t board_env_size;
#endif

#define CONFIG_IPQ5332_ENV			1
#define CONFIG_ENV_OFFSET			board_env_offset
#define CONFIG_ENV_SIZE				CONFIG_ENV_SIZE_MAX
#define CONFIG_ENV_RANGE			board_env_range
#ifdef CONFIG_IPQ_TINY
#define CONFIG_SYS_MALLOC_LEN			(832 << 10)
#else
#define CONFIG_SYS_MALLOC_LEN		(CONFIG_ENV_SIZE_MAX + (768 << 10))
#endif

#define CONFIG_IPQ_NO_MACS			2

/*
 * Block Device & Disk  Partition Config
 */
#define HAVE_BLOCK_DEVICE
#define CONFIG_DOS_PARTITION

/*
* Expose SPI driver as a pseudo NAND driver to make use
* of U-Boot's MTD framework.
*/
#define CONFIG_SYS_MAX_NAND_DEVICE		CONFIG_IPQ_MAX_NAND_DEVICE + \
							CONFIG_IPQ_MAX_SPI_DEVICE

#define CONFIG_IPQ_MAX_NAND_DEVICE		1
#define CONFIG_IPQ_MAX_SPI_DEVICE		1

#define CONFIG_IPQ_MAX_BLSP_QUPS		3
#define CONFIG_QPIC_NAND_NAND_INFO_IDX		0
#define CONFIG_IPQ_SPI_NOR_INFO_IDX		1

#define CONFIG_NAND_FLASH_INFO_IDX		CONFIG_QPIC_NAND_NAND_INFO_IDX
#define CONFIG_SPI_FLASH_INFO_IDX		CONFIG_IPQ_SPI_NOR_INFO_IDX

#define QCA_SPI_NOR_DEVICE			"spi0.0"

/*
* U-Boot Env Configs
*/
#define CONFIG_OF_LIBFDT			1
#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_CMD_XIMG

/* MTEST */
#define CONFIG_SYS_MEMTEST_START		CONFIG_SYS_SDRAM_BASE + 0x1300000
#define CONFIG_SYS_MEMTEST_END			CONFIG_SYS_MEMTEST_START + 0x100

#define CONFIG_BOOTCOMMAND			"bootipq"
#define CONFIG_BOOTARGS				"console=ttyMSM0,115200n8"
#define QCA_ROOT_FS_PART_NAME			"rootfs"

#define CONFIG_BOOTDELAY			5

#define NUM_ALT_PARTITION			16

#define CONFIG_CMD_BOOTZ

/* Mii command support */
#define CONFIG_CMD_MII

/*
* Ethernet Configs
*/
#define CONFIG_IPQ5332_EDMA
#ifdef CONFIG_IPQ5332_EDMA
#define CONFIG_IPQ5332_BRIDGED_MODE	1
#define CONFIG_NET_RETRY_COUNT		5
#define CONFIG_SYS_RX_ETH_BUFFER	128
#define CONFIG_TFTP_BLOCKSIZE		1280
#define CONFIG_CMD_PING
#define CONFIG_CMD_DHCP
#define CONFIG_MII
#define CONFIG_IPADDR          192.168.10.10
#define CONFIG_NETMASK         255.255.255.0
#define CONFIG_SERVERIP        192.168.10.1
#define CONFIG_CMD_TFTPPUT
#define CONFIG_IPQ_MDIO			1
#define CONFIG_IPQ_ETH_INIT_DEFER
/* MDIO clock update for AQ firmware downlaod */
#define MDIO_IO_CLK_315M
#endif

/* L1 cache line size is 64 bytes, L2 cache line size is 128 bytes
* Cache flush and invalidation based on L1 cache, so the cache line
* size is configured to 64 */
#define CONFIG_SYS_CACHELINE_SIZE		64
#define CONFIG_CMD_CACHE

/*
* SPI Flash Configs
*/
#define CONFIG_QCA_SPI
#define CONFIG_SPI_FLASH
#define CONFIG_CMD_SF

#ifndef CONFIG_IPQ_TINY_SPI_NOR
#define CONFIG_SPI_FLASH_STMICRO
#define CONFIG_SPI_FLASH_WINBOND
#define CONFIG_SPI_FLASH_MACRONIX
#define CONFIG_SPI_FLASH_GIGADEVICE
#define CONFIG_SPI_FLASH_SPANSION
#else /* Needed for manufacturer specific driver support, if any */
#define CONFIG_SPI_FLASH_GIGADEVICE
#endif

#define CONFIG_SF_DEFAULT_BUS			0
#define CONFIG_SF_DEFAULT_CS			0
#define CONFIG_SF_DEFAULT_MODE			SPI_MODE_0
#define CONFIG_SF_DEFAULT_SPEED			(48 * 1000 * 1000)
#define CONFIG_SPI_FLASH_BAR			1
#define CONFIG_SPI_FLASH_USE_4K_SECTORS
#define CONFIG_IPQ_4B_ADDR_SWITCH_REQD

#define CONFIG_QUP_SPI_USE_DMA			1
#define CONFIG_QCA_BAM				1

/*
 * NAND Flash Configs
 */

/* CONFIG_QPIC_NAND: QPIC NAND in BAM mode
 * CONFIG_IPQ_NAND: QPIC NAND in FIFO/block mode.
 * BAM is enabled by default.
 */
#define CONFIG_CMD_MTDPARTS
#define CONFIG_SYS_NAND_SELF_INIT

#ifdef CONFIG_NAND_FLASH
#define CONFIG_CMD_NAND
#define CONFIG_ENV_IS_IN_NAND			1
#define CONFIG_QPIC_NAND
#define CONFIG_SYS_NAND_ONFI_DETECTION
#define CONFIG_CMD_NAND_YAFFS
#define CONFIG_MTD_DEVICE
#define CONFIG_MTD_PARTITIONS
#endif

#ifdef CONFIG_QPIC_SERIAL
#define CONFIG_QPIC_NODE			"/soc/nand@79b0000/"
#ifdef QSPI_SERIAL_DEBUG /* QSPI DEBUG */
#define qspi_debug(fmt,args...)	printf (fmt ,##args)
#else
#define qspi_debug(fmt,args...)
#endif /* QSPI DEBUG */
#define CONFIG_PAGE_SCOPE_MULTI_PAGE_READ
#define CONFIG_QSPI_SERIAL_TRAINING
#define CONFIG_QSPI_LAYOUT_SWITCH
#endif

/*
 * UBI write command
 */
#ifdef CONFIG_UBI_WRITE
#define CONFIG_CMD_UBI
#define CONFIG_RBTREE
#define IPQ_UBI_VOL_WRITE_SUPPORT
#endif

/*
 * MMC configs
 */
#ifdef CONFIG_MMC_FLASH
#define CONFIG_QCA_MMC
#define CONFIG_MMC
#define CONFIG_CMD_MMC
#define CONFIG_GENERIC_MMC
#define CONFIG_SDHCI
#define CONFIG_SDHCI_QCA
#define CONFIG_ENV_IS_IN_MMC
#define CONFIG_SYS_MMC_ENV_DEV			0
#define CONFIG_SDHCI_SUPPORT
#define CONFIG_MMC_ADMA
#define CONFIG_EFI_PARTITION
/*
* eMMC controller support only 4-bit
* force SDHC driver to 4-bit mode
*/
#define CONFIG_MMC_FORCE_CAP_4BIT_BUSWIDTH
#endif

#define CONFIG_FDT_FIXUP_PARTITIONS
/*
 * PCIE Enable
 */
#define PCI_MAX_DEVICES				3
#ifdef CONFIG_PCI_IPQ
#define CONFIG_PCI
#define CONFIG_CMD_PCI
#define CONFIG_PCI_SCAN_SHOW
#define CONFIG_IPQ_PCI_INIT_DEFER
#endif

/*
 * USB Support
 */
#ifdef CONFIG_USB_XHCI_IPQ
#define CONFIG_USB_XHCI
#define CONFIG_USB_XHCI_DWC3
#define CONFIG_CMD_USB
#define CONFIG_USB_STORAGE
#define CONFIG_SYS_USB_XHCI_MAX_ROOT_PORTS      2
#define CONFIG_USB_MAX_CONTROLLER_COUNT         1

/*
 * USB crashdump collection
 */
#define CONFIG_FS_FAT
#define CONFIG_FAT_WRITE
#define CONFIG_CMD_FAT

/*
 * Block Device & Disk  Partition Config
 */
#define HAVE_BLOCK_DEVICE
#define CONFIG_DOS_PARTITION
#endif

/*
 * Crash dump support
 */
#define CONFIG_OF_BOARD_SETUP

#define TCSR_BOOT_MISC_REG	((u32 *)0x193D100)

#ifdef CONFIG_OF_BOARD_SETUP
#define DLOAD_DISABLE		(~BIT(4))
#define DLOAD_ENABLE		BIT(4)
#define CRASHDUMP_RESET        BIT(11)
#define SET_MAGIC				0x1
#define CLEAR_MAGIC				0x0
#define SCM_CMD_TZ_CONFIG_HW_FOR_RAM_DUMP_ID	0x9
#define SCM_CMD_TZ_FORCE_DLOAD_ID		0x10
#define SCM_CMD_TZ_PSHOLD			0x15
#define BOOT_VERSION				0
#define TZ_VERSION				1
#endif

/*
 * CRASH DUMP ENABLE
 */
#define CONFIG_QCA_APPSBL_DLOAD
#ifdef CONFIG_QCA_APPSBL_DLOAD

#undef CONFIG_NET_RETRY_COUNT
#define CONFIG_NET_RETRY_COUNT			500

#define IPQ_TEMP_DUMP_ADDR			0x44000000
#endif
#define CONFIG_QCA_KERNEL_CRASHDUMP_ADDRESS	*((unsigned int *)0x08600658)
#define CONFIG_CPU_CONTEXT_DUMP_SIZE		4096
/* TZ generally stores the base address allocated by ctx-save driver
 * in the imem location 0x08600658. the first 300K is used
 * for TMEL ctxt. TZ stores the base address + 300K in the imem.
 * In the minidump path, TLV_BUF_OFFSET is added to base addr.
 * So update TLV_BUF_OFFSET to subtract 300K from the base.
 */
#define TME_CTXT_SIZE				300 * 1024
#define TLV_BUF_OFFSET				(500 * 1024) - TME_CTXT_SIZE
#define CONFIG_TLV_DUMP_SIZE			12 * 1024

/*
 * ARM PSCI command support
 */
#define CONFIG_ARMV7_PSCI

/*
 * I2C Enable
 */
#ifdef CONFIG_IPQ_I2C
#define CONFIG_SYS_I2C_QUP
#define CONFIG_CMD_I2C
#define CONFIG_DM_I2C
#endif

/*
 * TINY NOR 16M Profile
 */
#ifdef CONFIG_IPQ_TINY_SPI_NOR
#define CONFIG_CMD_DISABLE_BASE
#define CONFIG_CMD_DISABLE_BOOTP
#define CONFIG_CMD_DISABLE_CHPART
#define CONFIG_CMD_DISABLE_FDT
#define CONFIG_FIT_DISABLE_MD5
#define CONFIG_FIT_DISABLE_SHA1
#define CONFIG_FIT_DISABLE_SHA256
#define CONFIG_DISABLE_CMD_SF_UPDATE
#define CONFIG_DISABLE_CMD_SF_PROTECT
#define CONFIG_DISABLE_CMD_SF_BULKERASE
#define CONFIG_DISABLE_CMD_UART
#define CONFIG_DISABLE_KERNEL64
#define CONFIG_CMD_DISABLE_EXECTZT
#define CONFIG_DISABLE_RAMDISK
#define CONFIG_DISABLE_SIGNED_BOOT
#undef CONFIG_GZIP
#undef CONFIG_ZLIB
#else
#define CONFIG_IPQ_ELF_AUTH

/* compress crash dump support */
#define CONFIG_CMD_ZIP
#define CONFIG_GZIP_COMPRESSED

/* Enable DTB compress */
#define CONFIG_COMPRESSED_DTB_MAX_SIZE		0x40000
#define CONFIG_COMPRESSED_DTB_BASE		CONFIG_SYS_TEXT_BASE -\
						CONFIG_COMPRESSED_DTB_MAX_SIZE
#endif

#define CONFIG_IPQ_FDT_FIXUP

/*
 * ELF authentication
 */
#define CONFIG_VERSION_ROLLBACK_PARTITION_INFO

#undef CONFIG_BOOTM_NETBSD
#undef CONFIG_BOOTM_PLAN9
#undef CONFIG_BOOTM_RTEMS
#undef CONFIG_BOOTM_VXWORKS

#define CONFIG_CMD_IPQ_FLASH_INIT

/* Flash Protect */
#define CONFIG_FLASH_PROTECT

#define CONFIG_BITBANGMII
#ifdef CONFIG_BITBANGMII
#define CONFIG_IPQ_QTI_BIT_BANGMII
#define GPIO_IN_OUT_BIT			9
#define CONFIG_BITBANGMII_MULTI
#endif

#define CONFIG_LIST_OF_CONFIG_NAMES_SUPPORT

#ifdef CONFIG_LIST_OF_CONFIG_NAMES_SUPPORT
#define CONFIG_NAME_MAX_ENTRIES	6
#define CONFIG_NAME_MAX_LEN	32
#endif

#endif /* _IPQ5332_H */
