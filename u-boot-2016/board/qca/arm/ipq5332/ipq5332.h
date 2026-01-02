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

#ifndef _IPQ5332_CDP_H_
#define _IPQ5332_CDP_H_

#include <configs/ipq5332.h>
#include <asm/u-boot.h>
#include <asm/arch-qca-common/qca_common.h>
#include "phy.h"

extern const char *rsvd_node;
extern const char *del_node[];
extern const add_node_t add_fdt_node[];

#define KERNEL_AUTH_CMD				0x1E
#define SCM_CMD_SEC_AUTH			0x1F
#define TME_DPR_PROCESSING			0x21

#define PSCI_RESET_SMC_ID			0x84000009

#define BLSP1_UART0_BASE			0x078AF000
#define UART_PORT_ID(reg)			((reg - BLSP1_UART0_BASE) / 0x1000)

#define MSM_SDC1_BASE				0x7800000
#define MSM_SDC1_SDHCI_BASE			0x7804000

#define TCSR_MODE_CTRL_2PORT_2LANE		0x1947544

#define DLOAD_MAGIC_COOKIE			0x10
#define DLOAD_DISABLED				0x40
#define DLOAD_BITS				0xFF

/* TME  DUMP */

#ifndef DUMP_TME_LOG
#define DUMP_TME_LOG			1
#endif

#ifndef	TME_LOG_DUMP_FEATURE_ID
#define TME_LOG_DUMP_FEATURE_ID		0x7
#endif

#ifndef TME_LOG_DUMP_FEATURE_VERSION
#define TME_LOG_DUMP_FEATURE_VERSION	0x401000
#endif

/* USB Registers */
#define TCSR_USB_PCIE_SEL			0x01947540
#define TCSR_USB_PCIE_SEL_USB			0x1
#define TCSR_USB_PCIE_SEL_PCI			0x0
#define USB30_GENERAL_CFG			0x8AF8808
#define USB30_GUCTL				0x8A0C12C
#define USB30_FLADJ				0x8A0C630
#define GUCTL					0x700C12C
#define FLADJ					0x700C630

#define SW_COLLAPSE_ENABLE			(1 << 0)
#define SW_OVERRIDE_ENABLE			(1 << 2)
#define XCFG_COARSE_TUNE_NUM			(2 << 0)
#define XCFG_FINE_TUNE_NUM			(1 << 3)
#define FSEL_VALUE				(5 << 4)

#define QUSB2PHY_BASE				0x7B000

#define USB3PHY_APB_BASE			0x4B0000

#define SSCG_CTRL_REG_1				0x9c
#define SSCG_CTRL_REG_2				0xa0
#define SSCG_CTRL_REG_3				0xa4
#define SSCG_CTRL_REG_4				0xa8
#define SSCG_CTRL_REG_5				0xac
#define SSCG_CTRL_REG_6				0xb0
#define CDR_CTRL_REG_1				0x80
#define CDR_CTRL_REG_2				0x84
#define CDR_CTRL_REG_3				0x88
#define CDR_CTRL_REG_4				0x8C
#define CDR_CTRL_REG_5				0x90
#define CDR_CTRL_REG_6				0x94
#define CDR_CTRL_REG_7				0x98

#define USB_PHY_CFG0				0x94
#define USB_PHY_UTMI_CTRL0			0x3C
#define USB_PHY_UTMI_CTRL5			0x50
#define USB_PHY_FSEL_SEL			0xB8
#define USB_PHY_HS_PHY_CTRL_COMMON0		0x54
#define USB_PHY_REFCLK_CTRL			0xA0
#define USB_PHY_HS_PHY_CTRL2			0x64
#define USB2PHY_USB_PHY_M31_XCFGI_1		0xBC
#define USB2PHY_USB_PHY_M31_XCFGI_4		0xC8
#define USB2PHY_USB_PHY_M31_XCFGI_5		0xCC
#define USB2PHY_USB_PHY_M31_XCFGI_9		0xDC
#define USB2PHY_USB_PHY_M31_XCFGI_11		0xE4

#define USB2_0_TX_ENABLE			BIT(2)
#define HSTX_SLEW_RATE_400PS			7
#define PLL_CHARGING_PUMP_CURRENT_35UA		(3 << 3)
#define ODT_VALUE_38_02_OHM			(3 << 6)
#define HSTX_PRE_EMPHASIS_LEVEL_0_55MA		(1)
#define HSTX_CURRENT_17_1MA_385MV		BIT(1)

#define UTMI_PHY_OVERRIDE_EN			BIT(1)
#define SLEEPM					BIT(1)
#define POR_EN					BIT(1)
#define FREQ_SEL				BIT(0)
#define COMMONONN				BIT(7)
#define FSEL					BIT(4)
#define RETENABLEN				BIT(3)
#define USB2_SUSPEND_N_SEL			BIT(3)
#define USB2_SUSPEND_N				BIT(2)
#define USB2_UTMI_CLK_EN			BIT(1)
#define CLKCORE					BIT(1)
#define ATERESET				~BIT(0)

#define PCIE_USB_COMBO_PHY_CFG_RX_AFE_2		0x4B07C4
#define PCIE_USB_COMBO_PHY_CFG_RX_DLF_DEMUX_2	0x4B07E8
#define PCIE_USB_COMBO_PHY_CFG_MISC1		0x4B0214

#define APB_REG_UPHY_RX_RESCAL_CODE		(16 << 8)
#define APB_REG_UPHY_RX_AFE_CAP1		(7 << 4)
#define APB_REG_UPHY_RX_AFE_RES1		(6 << 0)

#define APB_REG_UPHY_RXD_BIT_WIDTH	(2 << 0)
#define APB_REG_UPHY_RX_PLOOP_GAIN	(4 << 4)
#define APB_REG_UPHY_RX_DLF_RATE	(1 << 8)
#define APB_UPHY_RX_PLOOP_EN		(1 << 12)
#define APB_REG_UPHY_RX_CDR_EN		(1 << 13)

#define APB_REG_FLOOP_GAIN		(3 << 0)

#define TCSR_SOC_HW_VERSION_REG 0x194D000

/*
 * OTP Register
 */
#define PHYA0_RFA_RFA_RFA_OTP_OTP_XO_0		0xC5D44AC
#define PHYA0_RFA_RFA_RFA_OTP_OTP_OV_1		0xC5D4484

/*
 * weak function
 */
__weak void qgic_init(void) {}
__weak void handle_noc_err(void) {}
__weak void board_pcie_clock_init(int id) {}
__weak void ubi_power_collapse(void) {}

/*
 * PCIE
 */
enum pcie_port_lane_mode_t{
	TWO_LANE_MODE =0,
	TWO_PORT_MODE
};

#define set_mdelay_clearbits_le32(addr, value, delay)	\
	 setbits_le32(addr, value);			\
	 mdelay(delay);					\
	 clrbits_le32(addr, value);			\

#define GCC_PCIE3X2_BCR				(GCC_PCIE3X2_BASE+0x000)
#define GCC_PCIE3X2_PHY_BCR			(GCC_PCIE3X2_BASE+0x060)

#define GCC_PCIE3X1_0_BCR			(GCC_PCIE3X1_0_BASE+0x000)
#define GCC_PCIE3X1_0_PHY_BCR			(GCC_PCIE3X1_0_BASE+0x060)

#define GCC_PCIE3X1_1_BCR			(GCC_PCIE3X1_1_BASE+0x000)
#define GCC_PCIE3X1_1_PHY_BCR			(GCC_PCIE3X1_1_BASE+0x030)

#define GCC_PCIE_BCR_ENABLE			(1 << 0)
#define GCC_PCIE_BLK_ARES			(1 << 0)

/*
 * QFPROM Register for SKU Validation
 */
#define QFPROM_CORR_FEATURE_CONFIG_ROW1_MSB	0xA4024

#define PCIE_0_CLOCK_DISABLE_BIT		11
#define PCIE_1_CLOCK_DISABLE_BIT		12
#define PCIE_2_CLOCK_DISABLE_BIT		10

#define PCIE_PARF_SLV_ADDR_SPACE_SIZE		0x358
#define PCIE_PARF_PHY_CTRL			0x40

#define PCIE_PHY_TEST_PWR_DOWN			0x1

/*
 * GPIO functional configs
 */
#define GPIO_DRV_2_MA				0x0 << 6
#define GPIO_DRV_4_MA				0x1 << 6
#define GPIO_DRV_6_MA				0x2 << 6
#define GPIO_DRV_8_MA				0x3 << 6
#define GPIO_DRV_10_MA				0x4 << 6
#define GPIO_DRV_12_MA				0x5 << 6
#define GPIO_DRV_14_MA				0x6 << 6
#define GPIO_DRV_16_MA				0x7 << 6

#define GPIO_OE					0x1 << 9

#define GPIO_NO_PULL				0x0
#define GPIO_PULL_DOWN				0x1
#define GPIO_KEEPER				0x2
#define GPIO_PULL_UP				0x3

#define MDC_MDIO_FUNC_SEL			0x1 << 2

/*
 * SMEM
 */
#ifdef CONFIG_SMEM_VERSION_C
#define RAM_PART_NAME_LENGTH			16
/**
 * Number of RAM partition entries which are usable by APPS.
 */
#define RAM_NUM_PART_ENTRIES 32
struct ram_partition_entry
{
	char name[RAM_PART_NAME_LENGTH];  /**< Partition name, unused for now */
	u64 start_address;             /**< Partition start address in RAM */
	u64 length;                    /**< Partition length in RAM in Bytes */
	u32 partition_attribute;       /**< Partition attribute */
	u32 partition_category;        /**< Partition category */
	u32 partition_domain;          /**< Partition domain */
	u32 partition_type;            /**< Partition type */
	u32 num_partitions;            /**< Number of partitions on device */
	u32 hw_info;                   /**< hw information such as type and frequency */
	u8 highest_bank_bit;           /**< Highest bit corresponding to a bank */
	u8 reserve0;                   /**< Reserved for future use */
	u8 reserve1;                   /**< Reserved for future use */
	u8 reserve2;                   /**< Reserved for future use */
	u32 reserved5;                 /**< Reserved for future use */
	u64 available_length;          /**< Available Partition length in RAM in Bytes */
};

struct usable_ram_partition_table
{
	u32 magic1;          /**< Magic number to identify valid RAM partition table */
	u32 magic2;          /**< Magic number to identify valid RAM partition table */
	u32 version;         /**< Version number to track structure definition changes
	                             and maintain backward compatibilities */
	u32 reserved1;       /**< Reserved for future use */

	u32 num_partitions;  /**< Number of RAM partition table entries */

	u32 reserved2;       /** < Added for 8 bytes alignment of header */

	/** RAM partition table entries */
	struct ram_partition_entry ram_part_entry[RAM_NUM_PART_ENTRIES];
};
#endif

struct smem_ram_ptn {
	char name[16];
	unsigned long long start;
	unsigned long long size;

	/* RAM Partition attribute: READ_ONLY, READWRITE etc.  */
	unsigned attr;

	/* RAM Partition category: EBI0, EBI1, IRAM, IMEM */
	unsigned category;

	/* RAM Partition domain: APPS, MODEM, APPS & MODEM (SHARED) etc. */
	unsigned domain;

	/* RAM Partition type: system, bootloader, appsboot, apps etc. */
	unsigned type;

	/* reserved for future expansion without changing version number */
	unsigned reserved2, reserved3, reserved4, reserved5;
} __attribute__ ((__packed__));

struct smem_ram_ptable {
#define _SMEM_RAM_PTABLE_MAGIC_1	0x9DA5E0A8
#define _SMEM_RAM_PTABLE_MAGIC_2	0xAF9EC4E2
	unsigned magic[2];
	unsigned version;
	unsigned reserved1;
	unsigned len;
	unsigned buf;
	struct smem_ram_ptn parts[32];
} __attribute__ ((__packed__));

typedef enum {
	SMEM_SPINLOCK_ARRAY = 7,
	SMEM_AARM_PARTITION_TABLE = 9,
	SMEM_HW_SW_BUILD_ID = 137,
	SMEM_USABLE_RAM_PARTITION_TABLE = 402,
	SMEM_POWER_ON_STATUS_INFO = 403,
	SMEM_MACHID_INFO_LOCATION = 425,
	SMEM_IMAGE_VERSION_TABLE = 469,
	SMEM_BOOT_FLASH_TYPE = 498,
	SMEM_BOOT_FLASH_INDEX = 499,
	SMEM_BOOT_FLASH_CHIP_SELECT = 500,
	SMEM_BOOT_FLASH_BLOCK_SIZE = 501,
	SMEM_BOOT_FLASH_DENSITY = 502,
	SMEM_BOOT_DUALPARTINFO = 503,
	SMEM_PARTITION_TABLE_OFFSET = 504,
	SMEM_SPI_FLASH_ADDR_LEN = 505,
	SMEM_RUNTIME_FAILSAFE_INFO = 507,
	SMEM_FIRST_VALID_TYPE = SMEM_SPINLOCK_ARRAY,
	SMEM_LAST_VALID_TYPE = SMEM_RUNTIME_FAILSAFE_INFO,
	SMEM_MAX_SIZE = SMEM_RUNTIME_FAILSAFE_INFO + 1,
} smem_mem_type_t;

#define FUSE_CNT	8
struct fuse_payload {
	u32 fuse_addr;
	u32 lsb_val;
	u32 msb_val;
};

/*
 * function declaration
 */
int smem_ram_ptable_init(struct smem_ram_ptable *smem_ram_ptable);
void reset_crashdump(void);
void reset_board(void);
int ipq_get_tz_version(char *version_name, int buf_size);
void ipq_fdt_fixup_socinfo(void *blob);
int smem_ram_ptable_init(struct smem_ram_ptable *smem_ram_ptable);
int smem_ram_ptable_init_v2(
		struct usable_ram_partition_table *usable_ram_partition_table);
void qpic_set_clk_rate(unsigned int clk_rate, int blk_type,
		int req_clk_src_type);
#ifdef CONFIG_PCI_IPQ
void board_pci_init(int id);
void pcie_reset(int pcie_id);
#endif
unsigned int __invoke_psci_fn_smc(unsigned int, unsigned int,
					 unsigned int, unsigned int);
#endif /* _IPQ5332_CDP_H_ */
