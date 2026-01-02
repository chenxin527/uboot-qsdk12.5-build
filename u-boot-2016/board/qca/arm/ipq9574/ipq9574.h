/*
 * Copyright (c) 2016-2021 The Linux Foundation. All rights reserved.
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

#ifndef _IPQ9574_CDP_H_
#define _IPQ9574_CDP_H_

#include <configs/ipq9574.h>
#include <asm/u-boot.h>
#include <asm/arch-qca-common/qca_common.h>

#define CMN_BLK_ADDR		0x0009B780
#define FREQUENCY_MASK		0xfffffdf0
#define INTERNAL_48MHZ_CLOCK	0x7
#define PORT_WRAPPER_MAX	0xFF

/*
 * EDMA HW ASSERT and DEASSERT values
 */
#define NSS_CC_EDMA_HW_RESET_ASSERT		0x18000
#define	NSS_CC_EDMA_HW_RESET_DEASSERT		0x0
#define NSS_CC_PORT1_RX_CMD_RCGR		0x39B28110
#define NSS_CC_PORT5_RX_CMD_RCGR		0x39B28170
#define NSS_CC_PORT5_TX_CMD_RCGR		0x39B2817C
#define NSS_CC_PORT1_RX_CFG_RCGR		0x39B28114
#define NSS_CC_PORT1_RX_CBCR			0x39B281A0
#define NSS_CC_UNIPHY_PORT1_RX_CBCR		0x39B28904
#define IPQ9574_PPE_BASE_ADDR			0x3a000000
#define IPQ9574_PPE_REG_SIZE			0x1000000
#define GCC_CBCR_CLK_ENABLE			0x1
#define GCC_CMN_BLK_ADDR			0x183A000
#define GCC_CMN_BLK_AHB_CBCR_OFFSET		0x4
#define GCC_CMN_BLK_SYS_CBCR_OFFSET		0x8
#define GCC_UNIPHY_SYS_ADDR			0x1817048
#define GCC_PORT_MAC_ADDR			0x39B2824C
#define NSS_CC_PPE_SWITCH_CFG_ADDR		0x39B2822C
#define NSS_CC_PPE_SWITCH_CBCR			0x39B28230
#define NSS_CC_PPE_SWITCH_CFG_CBCR		0x39B28234
#define NSS_CC_PPE_EDMA_CBCR			0x39B28238
#define NSS_CC_PPE_EDMA_CFG_CBCR		0x39B2823C
#define NSS_CC_CRYPTO_PPE_CBCR			0x39B28240
#define NSS_CC_NSSNOC_PPE_CBCR			0x39B28244
#define NSS_CC_NSSNOC_PPE_CFG_CBCR		0x39B28248
#define NSS_CC_PPE_SWITCH_BTQ_ADDR		0x39B2827C
#define GCC_MDIO_AHB_CBCR_ADDR			0x1817040
#define GCC_MEM_NOC_NSSNOC_CLK			0x01819014
#define GCC_NSSCFG_CLK				0x0181702C
#define GCC_NSSNOC_ATB_CLK			0x01817014
#define GCC_NSSNOC_MEM_NOC_1_CLK		0x01817084
#define GCC_NSSNOC_MEMNOC_CLK			0x01817024
#define GCC_NSSNOC_QOSGEN_REF_CLK		0x0181701C
#define GCC_NSSNOC_TIMEOUT_REF_CLK		0x01817020
#define GCC_NSSNOC_SNOC_CBCR			0x1817028
#define GCC_NSSNOC_SNOC_1_CBCR			0x181707C
#define GCC_MEM_NOC_SNOC_AXI_CBCR		0x1819018
#define NSS_CC_UNIPHY_PORT1_RX_ADDR		0x39B28904
#define NSS_CC_PPE_RESET_ADDR			0x39B28A08
#define NSS_CC_UNIPHY_MISC_RESET		0x39B28A24
#define GCC_UNIPHY0_MISC			0x1817050
#define GCC_UNIPHY1_MISC			0x1817060
#define GCC_UNIPHY2_MISC			0x1817070
#define GCC_PPE_PORT1_MAC_ARES			0x800
#define GCC_PPE_PORT2_MAC_ARES			0x400
#define GCC_PPE_PORT3_MAC_ARES			0x200
#define GCC_PPE_PORT4_MAC_ARES			0x100
#define GCC_PPE_PORT5_MAC_ARES			0x80
#define GCC_PPE_PORT6_MAC_ARES			0x40
#define GCC_PORT1_ARES				0xC00
#define GCC_PORT2_ARES				0x300
#define GCC_PORT3_ARES				0xC0
#define GCC_PORT4_ARES				0x30
#define GCC_PORT5_ARES				0xC
#define GCC_PORT6_ARES				0x3
#define NSS_CC_PORT_SPEED_DIVIDER		0x39B28110
#define NSS_CC_PPE_FREQUENCY_RCGR		0x39B28204

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

#define BLSP1_UART0_BASE			0x078AF000
#define UART_PORT_ID(reg)			((reg - BLSP1_UART0_BASE) / 0x1000)

#define CLOCK_UPDATE_TIMEOUT_US			1000

#define KERNEL_AUTH_CMD				0x1E
#define SCM_CMD_SEC_AUTH			0x1F
#define TME_DPR_PROCESSING			0x21

#ifdef CONFIG_SMEM_VERSION_C
#define RAM_PART_NAME_LENGTH			16

#define SECONDARY_CORE_STACKSZ			(8 * 1024)
#define CPU_POWER_DOWN				(1 << 16)

#define ARM_PSCI_TZ_FN_BASE			0x84000000
#define ARM_PSCI_TZ_FN(n)			(ARM_PSCI_TZ_FN_BASE + (n))

#define ARM_PSCI_TZ_FN_CPU_OFF			ARM_PSCI_TZ_FN(2)
#define ARM_PSCI_TZ_FN_CPU_ON			ARM_PSCI_TZ_FN(3)
#define ARM_PSCI_TZ_FN_AFFINITY_INFO		ARM_PSCI_TZ_FN(4)

/*
 * GCC-QPIC Registers
 */
#define QPIC_CBCR_VAL				0x80004FF1

#define PSCI_RESET_SMC_ID			0x84000009

#define set_mdelay_clearbits_le32(addr, value, delay)	\
	 setbits_le32(addr, value);			\
	 mdelay(delay);					\
	 clrbits_le32(addr, value);			\

/* USB Registers */
#define USB30_PHY_1_QUSB2PHY_BASE		0x7B000
#define USB30_PHY_1_USB3PHY_AHB2PHY_BASE	0x7D000
#define USB3_PHY_POWER_DOWN_CONTROL		0x804

#define USB30_1_GUCTL				0x8A0C12C
#define USB30_1_FLADJ				0x8A0C630


#define QSERDES_COM_SYSCLK_EN_SEL		0xac
#define QSERDES_COM_BIAS_EN_CLKBUFLR_EN		0x34
#define QSERDES_COM_CLK_SELECT			0x174
#define QSERDES_COM_BG_TRIM			0x70
#define QSERDES_RX_UCDR_FASTLOCK_FO_GAIN	0x440
#define QSERDES_COM_SVS_MODE_CLK_SEL		0x19c
#define QSERDES_COM_HSCLK_SEL			0x178
#define QSERDES_COM_CMN_CONFIG			0x194
#define QSERDES_COM_PLL_IVCO			0x048
#define QSERDES_COM_SYS_CLK_CTRL		0x3c
#define QSERDES_COM_DEC_START_MODE0		0xd0
#define QSERDES_COM_DIV_FRAC_START1_MODE0	0xdc
#define QSERDES_COM_DIV_FRAC_START2_MODE0	0xe0
#define QSERDES_COM_DIV_FRAC_START3_MODE0	0xe4
#define QSERDES_COM_CP_CTRL_MODE0		0x78
#define QSERDES_COM_PLL_RCTRL_MODE0		0x84
#define QSERDES_COM_PLL_CCTRL_MODE0		0x90
#define QSERDES_COM_INTEGLOOP_GAIN0_MODE0	0x108
#define QSERDES_COM_LOCK_CMP1_MODE0		0x4c
#define QSERDES_COM_LOCK_CMP2_MODE0		0x50
#define QSERDES_COM_LOCK_CMP3_MODE0		0x54
#define QSERDES_COM_CORE_CLK_EN			0x18c
#define QSERDES_COM_LOCK_CMP_CFG		0xcc
#define QSERDES_COM_VCO_TUNE_MAP		0x128
#define QSERDES_COM_BG_TIMER			0x0c
#define QSERDES_COM_SSC_EN_CENTER		0x10
#define QSERDES_COM_SSC_PER1			0x1c
#define QSERDES_COM_SSC_PER2			0x20
#define QSERDES_COM_SSC_ADJ_PER1		0x14
#define QSERDES_COM_SSC_ADJ_PER2		0x18
#define QSERDES_COM_SSC_STEP_SIZE1		0x24
#define QSERDES_COM_SSC_STEP_SIZE2		0x28
#define QSERDES_RX_UCDR_SO_GAIN			0x410
#define QSERDES_RX_RX_EQU_ADAPTOR_CNTRL2	0x4d8
#define QSERDES_RX_RX_EQU_ADAPTOR_CNTRL3	0x4dc
#define QSERDES_RX_RX_EQU_ADAPTOR_CNTRL4	0x4e0
#define QSERDES_RX_RX_EQ_OFFSET_ADAPTOR_CNTRL	0x508
#define QSERDES_RX_RX_OFFSET_ADAPTOR_CNTRL2	0x50c
#define QSERDES_RX_SIGDET_CNTRL			0x514
#define QSERDES_RX_SIGDET_DEGLITCH_CNTRL	0x51c
#define QSERDES_RX_SIGDET_ENABLES		0x510
#define QSERDES_TX_HIGHZ_TRANSCEIVEREN_BIAS_D	0x268
#define QSERDES_TX_RCV_DETECT_LVL_2		0x2ac
#define QSERDES_TX_LANE_MODE			0x294
#define PCS_TXDEEMPH_M6DB_V0			0x824
#define PCS_TXDEEMPH_M3P5DB_V0			0x828
#define PCS_FLL_CNTRL2				0x8c8
#define PCS_FLL_CNTRL1				0x8c4
#define PCS_FLL_CNT_VAL_L			0x8cc
#define PCS_FLL_CNT_VAL_H_TOL			0x8d0
#define PCS_FLL_MAN_CODE			0x8d4
#define PCS_LOCK_DETECT_CONFIG1			0x880
#define PCS_LOCK_DETECT_CONFIG2			0x884
#define PCS_LOCK_DETECT_CONFIG3			0x888
#define PCS_POWER_STATE_CONFIG2			0x864
#define PCS_RXEQTRAINING_WAIT_TIME		0x8b8
#define PCS_RXEQTRAINING_RUN_TIME		0x8bc
#define PCS_LFPS_TX_ECSTART_EQTLOCK		0x8b0
#define PCS_PWRUP_RESET_DLY_TIME_AUXCLK		0x8a0
#define PCS_TSYNC_RSYNC_TIME			0x88c
#define PCS_RCVR_DTCT_DLY_P1U2_L		0x870
#define PCS_RCVR_DTCT_DLY_P1U2_H		0x874
#define PCS_RCVR_DTCT_DLY_U3_L			0x878
#define PCS_RCVR_DTCT_DLY_U3_H			0x87c
#define PCS_RX_SIGDET_LVL			0x9d8
#define USB3_PCS_TXDEEMPH_M6DB_V0		0x824
#define USB3_PCS_TXDEEMPH_M3P5DB_V0		0x828
#define QSERDES_RX_SIGDET_ENABLES		0x510
#define USB3_PHY_START_CONTROL			0x808
#define USB3_PHY_SW_RESET			0x800
#define NOC_HANDSHAKE_FSM_EN			(1 << 15)

enum uniphy_clk_type {
	NSS_PORT1_RX_CLK_E = 0,
	NSS_PORT1_TX_CLK_E,
	NSS_PORT2_RX_CLK_E,
	NSS_PORT2_TX_CLK_E,
	NSS_PORT3_RX_CLK_E,
	NSS_PORT3_TX_CLK_E,
	NSS_PORT4_RX_CLK_E,
	NSS_PORT4_TX_CLK_E,
	NSS_PORT5_RX_CLK_E,
	NSS_PORT5_TX_CLK_E,
	NSS_PORT6_RX_CLK_E,
	NSS_PORT6_TX_CLK_E,
	UNIPHY0_PORT1_RX_CLK_E,
	UNIPHY0_PORT1_TX_CLK_E,
	UNIPHY0_PORT2_RX_CLK_E,
	UNIPHY0_PORT2_TX_CLK_E,
	UNIPHY0_PORT3_RX_CLK_E,
	UNIPHY0_PORT3_TX_CLK_E,
	UNIPHY0_PORT4_RX_CLK_E,
	UNIPHY0_PORT4_TX_CLK_E,
	UNIPHY0_PORT5_RX_CLK_E,
	UNIPHY0_PORT5_TX_CLK_E,
	UNIPHY1_PORT5_RX_CLK_E,
	UNIPHY1_PORT5_TX_CLK_E,
	UNIPHY2_PORT6_RX_CLK_E,
	UNIPHY2_PORT6_TX_CLK_E,
	PORT5_RX_SRC_E,
	PORT5_TX_SRC_E,
	UNIPHYT_CLK_MAX,
};

#ifdef CONFIG_PCI_IPQ
void board_pci_init(int id);
__weak void board_pcie_clock_init(int id) {}
#endif

unsigned int __invoke_psci_fn_smc(unsigned int, unsigned int,
					 unsigned int, unsigned int);

/*
 * Eud register
 */
#define EUD_EUD_EN2				0x7A000

/*
 * QFPROM Register for SKU Validation
 */
#define QFPROM_CORR_FEATURE_CONFIG_ROW1_MSB	0xA401C
#define QFPROM_CORR_FEATURE_CONFIG_ROW2_MSB	0xA4024

#define PCIE_0_CLOCK_DISABLE_BIT		2
#define PCIE_1_CLOCK_DISABLE_BIT		3
#define PCIE_2_CLOCK_DISABLE_BIT		4
#define PCIE_3_CLOCK_DISABLE_BIT		5

#define UNIPHY_0_DISABLE_BIT			23
#define UNIPHY_1_DISABLE_BIT			24
#define UNIPHY_2_DISABLE_BIT			25

int ipq_validate_qfrom_fuse(unsigned int reg_add, int pos);

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

int smem_ram_ptable_init(struct smem_ram_ptable *smem_ram_ptable);
int smem_ram_ptable_init_v2(struct usable_ram_partition_table *usable_ram_partition_table);
void reset_crashdump(void);
void reset_board(void);

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
	SMEM_FIRST_VALID_TYPE = SMEM_SPINLOCK_ARRAY,
	SMEM_LAST_VALID_TYPE = SMEM_SPI_FLASH_ADDR_LEN,
	SMEM_MAX_SIZE = SMEM_SPI_FLASH_ADDR_LEN + 1,
} smem_mem_type_t;

#define MSM_SDC1_BASE           0x7800000
#define MSM_SDC1_SDHCI_BASE     0x7804000

#define FUSE_CNT		0x10
struct fuse_payload {
	u32 fuse_addr;
	u32 val;
};

__weak void qgic_init(void) {}
__weak void handle_noc_err(void) {}
extern const char *rsvd_node;
extern const char *del_node[];
extern const add_node_t add_fdt_node[];
int ipq_get_tz_version(char *version_name, int buf_size);
void ipq_fdt_fixup_socinfo(void *blob);
int ipq_board_usb_init(void);
void power_cycle_sdx(void);
#endif /* _IPQ9574_CDP_H_ */
