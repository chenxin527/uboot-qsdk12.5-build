/*
 * Copyright (c) 2016-2017, The Linux Foundation. All rights reserved.
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

#ifndef _IPQ806X_H_
#define _IPQ806X_H_

#include <configs/ipq806x.h>
#include <asm/u-boot.h>
#include <asm/arch-ipq806x/clk.h>
#include <asm/arch-qca-common/qca_common.h>
#include "phy.h"

#define GSBI4_BASE		0x16300000
#define GMAC_AHB_RESET		0x903E24

#define KERNEL_AUTH_CMD                 0x7
#define SCM_CMD_SEC_AUTH		0x15

#define MSM_TMR_BASE        0x0200A000

#define APCS_WDT0_EN        (MSM_TMR_BASE + 0x0040)
#define APCS_WDT0_RST       (MSM_TMR_BASE + 0x0038)
#define APCS_WDT0_BARK_TIME (MSM_TMR_BASE + 0x004C)
#define APCS_WDT0_BITE_TIME (MSM_TMR_BASE + 0x005C)

#define APCS_WDT0_CPU0_WDOG_EXPIRED_ENABLE (MSM_CLK_CTL_BASE + 0x3820)

/* Watchdog bite time set to default reset value */
#define RESET_WDT_BITE_TIME 0x31F3

/* Watchdog bark time value is kept larger than the watchdog timeout
 * of 0x31F3, effectively disabling the watchdog bark interrupt
 */
#define RESET_WDT_BARK_TIME (5 * RESET_WDT_BITE_TIME)

#define L2ESR_IND_ADDR          (0x204)

/* L2ESR bit fields */
#define L2ESR_MPDCD             BIT(0)
#define L2ESR_MPSLV             BIT(1)
#define L2ESR_TSESB             BIT(2)
#define L2ESR_TSEDB             BIT(3)
#define L2ESR_DSESB             BIT(4)
#define L2ESR_DSEDB             BIT(5)
#define L2ESR_MSE               BIT(6)
#define L2ESR_MPLDREXNOK        BIT(8)

#define CE1_REG_USAGE           (0)
#define CE1_ADM_USAGE           (1)
#define CE1_RESOURCE            (1)

#define IPQ_XHCI_BASE_1		0x11000000
#define IPQ_XHCI_BASE_2		0x10000000
#define USB30_RESET		0x00903B50
#define USB30_1_RESET		0x00903B58
#define DWC3_SSUSB_REG_GCTL		0xC110
#define DWC3_SSUSB_REG_GUSB2PHYCFG_PHYSOFTRST		(1 << 31)
#define DWC3_SSUSB_REG_GUSB2PHYCFG(n)		(0xC200 + ((n) * 0x16))
#define DWC3_SSUSB_REG_GUSB3PIPECTL_PHYSOFTRST		(1 << 31)
#define DWC3_SSUSB_REG_GUSB3PIPECTL(n)		(0xC2C0 + ((n) * 0x16))
#define DWC3_SSUSB_PHY_RTUNE_RTUNE_CTRL_REG		0x34
#define DWC3_SSUSB_PHY_RTUNE_DEBUG_REG		0x3
#define RX_TERM_VALUE		0
#define RX_EQ_VALUE		4
#define DWC3_SSUSB_PHY_RX_OVRD_IN_HI_REG		0x1006
#define DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ_EN		6
#define DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ_EN_OVRD	7
#define DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ_MASK		0x7
#define DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ		8
#define DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ_OVRD		11
#define AMPLITUDE_VALUE		110
#define TX_DEEMPH_3_5DB		23
#define DWC3_SSUSB_PHY_TX_OVRD_DRV_LO_REG		0x1002
#define DWC3_SSUSB_PHY_TX_DEEMPH_MASK		0x3F80
#define DWC3_SSUSB_PHY_AMP_MASK		0x7F
#define DWC3_SSUSB_PHY_AMP_EN		(1 << 14)
#define DWC3_SSUSB_REG_GUCTL		0xC12C
#define DWC3_SSUSB_PHY_TX_ALT_BLOCK_REG		0x102D
#define DWC3_SSUSB_PHY_TX_ALT_BLOCK_EN_ALT_BUS		(1 << 7)
#define DWC3_GCTL_U2EXIT_LFPS		(1 << 2)
#define DWC3_GCTL_SOFITPSYNC		(1 << 10)
#define DWC3_GCTL		0xc110
#define DWC3_SSUSB_REG_GUSB2PHYCFG_SUSPENDUSB20		(1 << 6)
#define DWC3_SSUSB_REG_GUSB2PHYCFG_ENBLSLPM		(1 << 8)
#define DWC3_SSUSB_REG_GUSB2PHYCFG_USBTRDTIM(n)		((n) << 10)
#define DWC3_SSUSB_REG_GUSB3PIPECTL_ELASTIC_BUFFER_MODE		(1 << 0)
#define DWC3_SSUSB_REG_GUSB3PIPECTL_TX_DE_EPPHASIS(n)		((n) << 1)
#define DWC3_SSUSB_REG_GUSB3PIPECTL_TX_MARGIN(n)		((n) << 3)
#define DWC3_SSUSB_REG_GUSB3PIPECTL_DELAYP1TRANS		(1 << 18)
#define DWC3_SSUSB_REG_GUSB3PIPECTL_DELAYP1P2P3(n)		((n) << 19)
#define DWC3_SSUSB_REG_GUSB3PIPECTL_U1U2EXITFAIL_TO_RECOV		(1 << 25)
#define DWC3_SSUSB_REG_GUSB3PIPECTL_REQUEST_P1P2P3		(1 << 24)
#define DWC3_SSUSB_PHY_TX_DEEMPH_SHIFT		7
#define DWC3_SSUSB_XHCI_REV_10		1

typedef struct {
	uint count;
	u8 addr[7];
} ipq_gmac_phy_addr_t;

typedef struct {
	uint base;
	int unit;
	uint is_macsec;
	uint mac_pwr0;
	uint mac_pwr1;
	uint mac_conn_to_phy;
	phy_interface_t phy;
	ipq_gmac_phy_addr_t phy_addr;
	const char phy_name[MDIO_NAME_LEN];
} ipq_gmac_board_cfg_t;

typedef struct {
	unsigned int resource;
	unsigned int channel_id;
} switch_ce_chn_buf_t;

#define gmac_board_cfg(_b, _sec, _p, _p0, _p1, _mp, _pn, ...)           \
{                                                                       \
	.base                   = NSS_GMAC##_b##_BASE,                  \
	.unit                   = _b,                                   \
	.is_macsec              = _sec,                                 \
	.phy                    = PHY_INTERFACE_MODE_##_p,              \
	.phy_addr               = { .count = _pn, { __VA_ARGS__ } },    \
	.mac_pwr0               = _p0,                                  \
	.mac_pwr1               = _p1,                                  \
	.mac_conn_to_phy        = _mp,                                  \
	.phy_name               = "IPQ MDIO"#_b                         \
}

extern ipq_gmac_board_cfg_t gmac_cfg[];
static inline int gmac_cfg_is_valid(ipq_gmac_board_cfg_t *cfg)
{
	/*
	 * 'cfg' is valid if and only if
	 *      unit number is non-negative and less than CONFIG_IPQ_NO_MACS.
	 *      'cfg' pointer lies within the array range of
	 *              board_ipq806x_params_t->gmac_cfg[]
	 */
	return ((cfg >= &gmac_cfg[0]) &&
			(cfg < &gmac_cfg[CONFIG_IPQ_NO_MACS]) &&
			(cfg->unit >= 0) && (cfg->unit < CONFIG_IPQ_NO_MACS));
}

__weak void aquantia_phy_reset_init_done(void) {}
__weak void aquantia_phy_reset_init(void) {}
__weak void qgic_init(void) {}
__weak void handle_noc_err(void) {}

struct smem_ram_ptn {
	char name[16];
	unsigned start;
	unsigned size;

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
#define _SMEM_RAM_PTABLE_MAGIC_1 0x9DA5E0A8
#define _SMEM_RAM_PTABLE_MAGIC_2 0xAF9EC4E2
	unsigned magic[2];
	unsigned version;
	unsigned reserved1;
	unsigned len;
	struct smem_ram_ptn parts[32];
	unsigned buf;
} __attribute__ ((__packed__));

int smem_ram_ptable_init(struct smem_ram_ptable *smem_ram_ptable);

typedef enum {
	SMEM_SPINLOCK_ARRAY = 7,
	SMEM_AARM_PARTITION_TABLE = 9,
	SMEM_APPS_BOOT_MODE = 106,
	SMEM_HW_SW_BUILD_ID = 137,
	SMEM_USABLE_RAM_PARTITION_TABLE = 402,
	SMEM_POWER_ON_STATUS_INFO = 403,
	SMEM_RLOCK_AREA = 404,
	SMEM_BOOT_INFO_FOR_APPS = 418,
	SMEM_BOOT_FLASH_TYPE = 421,
	SMEM_BOOT_FLASH_INDEX = 422,
	SMEM_BOOT_FLASH_CHIP_SELECT = 423,
	SMEM_BOOT_FLASH_BLOCK_SIZE = 424,
	SMEM_MACHID_INFO_LOCATION = 425,
	SMEM_BOOT_DUALPARTINFO = 427,
	SMEM_PARTITION_TABLE_OFFSET = 428,
	SMEM_BOOT_FLASH_DENSITY = 429,
	SMEM_IMAGE_VERSION_TABLE = 430,
	SMEM_FIRST_VALID_TYPE = SMEM_SPINLOCK_ARRAY,
	SMEM_LAST_VALID_TYPE = SMEM_IMAGE_VERSION_TABLE,
	SMEM_MAX_SIZE = SMEM_PARTITION_TABLE_OFFSET + 1,
} smem_mem_type_t;

unsigned smem_read_alloc_entry(smem_mem_type_t type, void *buf, int len);
int ipq_get_tz_version(char *version_name, int buf_size);
/* Reserved-memory node names*/
extern const char *rsvd_node;
extern const char *del_node[];
extern const add_node_t add_fdt_node[];
void reset_crashdump(void);
void ipq_fdt_fixup_socinfo(void *blob);
void board_pci_init(int id);
void board_pcie_clock_init(int id);

void reset_board(void);

#endif /* _IPQ806X_H_ */
