/*
 * Copyright (c) 2015-2017, The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/
#include <common.h>
#include <asm-generic/errno.h>
#include <asm/io.h>
#include <malloc.h>
#include <net.h>
#include <phy.h>
#include <miiphy.h>
#include "ipq_phy.h"
#include "ipq9574_qca8075.h"

extern int ipq_mdio_write(int mii_id,
		int regnum, u16 value);
extern int ipq_mdio_read(int mii_id,
		int regnum, ushort *data);

struct phy_ops *ipq9574_qca8075_ops;
static u32 ipq9574_qca8075_id;
static u16 ipq9574_qca8075_phy_reg_write(u32 dev_id, u32 phy_id,
		u32 reg_id, u16 reg_val)
{
	ipq_mdio_write(phy_id, reg_id, reg_val);
	return 0;
}

static u16 ipq9574_qca8075_phy_reg_read(u32 dev_id, u32 phy_id, u32 reg_id)
{
	return ipq_mdio_read(phy_id, reg_id, NULL);
}

/*
 * phy4 prfer medium
 * get phy4 prefer medum, fiber or copper;
 */
static qca8075_phy_medium_t __phy_prefer_medium_get(u32 dev_id,
                                                   u32 phy_id)
{
	u16 phy_medium;
	phy_medium =
		ipq9574_qca8075_phy_reg_read(dev_id, phy_id,
			QCA8075_PHY_CHIP_CONFIG);

	return ((phy_medium & QCA8075_PHY4_PREFER_FIBER) ?
		QCA8075_PHY_MEDIUM_FIBER : QCA8075_PHY_MEDIUM_COPPER);
}

/*
 *  phy4 activer medium
 *  get phy4 current active medium, fiber or copper;
 */
static qca8075_phy_medium_t __phy_active_medium_get(u32 dev_id,
                                                   u32 phy_id)
{
	u16 phy_data = 0;
	u32 phy_mode;

	phy_mode = ipq9574_qca8075_phy_reg_read(dev_id, phy_id,
				QCA8075_PHY_CHIP_CONFIG);
	phy_mode &= 0x000f;

	if (phy_mode == QCA8075_PHY_PSGMII_AMDET) {
		phy_data = ipq9574_qca8075_phy_reg_read(dev_id,
			phy_id, QCA8075_PHY_SGMII_STATUS);

		if ((phy_data & QCA8075_PHY4_AUTO_COPPER_SELECT)) {
			return QCA8075_PHY_MEDIUM_COPPER;
		} else if ((phy_data & QCA8075_PHY4_AUTO_BX1000_SELECT)) {
			/* PHY_MEDIUM_FIBER_BX1000 */
			return QCA8075_PHY_MEDIUM_FIBER;
		} else if ((phy_data & QCA8075_PHY4_AUTO_FX100_SELECT)) {
			 /* PHY_MEDIUM_FIBER_FX100 */
			return QCA8075_PHY_MEDIUM_FIBER;
		}
		/* link down */
		return __phy_prefer_medium_get(dev_id, phy_id);
	} else if ((phy_mode == QCA8075_PHY_PSGMII_BASET) ||
			(phy_mode == QCA8075_PHY_SGMII_BASET)) {
		return QCA8075_PHY_MEDIUM_COPPER;
	} else if ((phy_mode == QCA8075_PHY_PSGMII_BX1000) ||
			(phy_mode == QCA8075_PHY_PSGMII_FX100)) {
		return QCA8075_PHY_MEDIUM_FIBER;
	} else {
		return QCA8075_PHY_MEDIUM_COPPER;
	}
}

/*
 *  phy4 copper page or fiber page select
 *  set phy4 copper or fiber page
 */

static u8  __phy_reg_pages_sel(u32 dev_id, u32 phy_id,
		qca8075_phy_reg_pages_t phy_reg_pages)
{
	u16 reg_pages;
	reg_pages = ipq9574_qca8075_phy_reg_read(dev_id,
			phy_id, QCA8075_PHY_CHIP_CONFIG);

	if (phy_reg_pages == QCA8075_PHY_COPPER_PAGES) {
		reg_pages |= 0x8000;
	} else if (phy_reg_pages == QCA8075_PHY_SGBX_PAGES) {
		reg_pages &= ~0x8000;
	} else
		return -EINVAL;

	ipq9574_qca8075_phy_reg_write(dev_id, phy_id,
		QCA8075_PHY_CHIP_CONFIG, reg_pages);
	return 0;
}

/*
 *  phy4 reg pages selection by active medium
 *  phy4 reg pages selection
 */
static  u32 __phy_reg_pages_sel_by_active_medium(u32 dev_id,
						u32 phy_id)
{
	qca8075_phy_medium_t phy_medium;
	qca8075_phy_reg_pages_t reg_pages;

	phy_medium = __phy_active_medium_get(dev_id, phy_id);
	if (phy_medium == QCA8075_PHY_MEDIUM_FIBER) {
		reg_pages = QCA8075_PHY_SGBX_PAGES;
	} else if (phy_medium == QCA8075_PHY_MEDIUM_COPPER) {
		reg_pages = QCA8075_PHY_COPPER_PAGES;
	} else {
		return -1;
	}

	return __phy_reg_pages_sel(dev_id, phy_id, reg_pages);
}

static u8 ipq9574_qca8075_phy_get_link_status(u32 dev_id, u32 phy_id)
{
	u16 phy_data;
	if (phy_id == COMBO_PHY_ID)
		__phy_reg_pages_sel_by_active_medium(dev_id, phy_id);
	phy_data = ipq9574_qca8075_phy_reg_read(dev_id,
			phy_id, QCA8075_PHY_SPEC_STATUS);
	if (phy_data & QCA8075_STATUS_LINK_PASS)
		return 0;

	return 1;
}

static u32 ipq9574_qca8075_phy_get_duplex(u32 dev_id, u32 phy_id,
                      fal_port_duplex_t * duplex)
{
	u16 phy_data;

	if (phy_id == COMBO_PHY_ID) {
		__phy_reg_pages_sel_by_active_medium(dev_id, phy_id);
	}

	phy_data = ipq9574_qca8075_phy_reg_read(dev_id, phy_id,
				QCA8075_PHY_SPEC_STATUS);

	/*
	 * Read duplex
	 */
	if (phy_data & QCA8075_STATUS_FULL_DUPLEX)
		*duplex = FAL_FULL_DUPLEX;
	else
		*duplex = FAL_HALF_DUPLEX;

	return 0;
}

static u32 ipq9574_qca8075_phy_get_speed(u32 dev_id, u32 phy_id,
                     fal_port_speed_t * speed)
{
	u16 phy_data;

	if (phy_id == COMBO_PHY_ID) {
		__phy_reg_pages_sel_by_active_medium(dev_id, phy_id);
	}
	phy_data = ipq9574_qca8075_phy_reg_read(dev_id,
			phy_id, QCA8075_PHY_SPEC_STATUS);

	switch (phy_data & QCA8075_STATUS_SPEED_MASK) {
	case QCA8075_STATUS_SPEED_1000MBS:
		*speed = FAL_SPEED_1000;
		break;
	case QCA8075_STATUS_SPEED_100MBS:
		*speed = FAL_SPEED_100;
		break;
	case QCA8075_STATUS_SPEED_10MBS:
		*speed = FAL_SPEED_10;
		break;
	default:
		return -EINVAL;
	}
	return 0;
}

static u32 ipq9574_qca8075_phy_mmd_write(u32 dev_id, u32 phy_id,
                     u16 mmd_num, u16 reg_id, u16 reg_val)
{
	ipq9574_qca8075_phy_reg_write(dev_id, phy_id,
			QCA8075_MMD_CTRL_REG, mmd_num);
	ipq9574_qca8075_phy_reg_write(dev_id, phy_id,
			QCA8075_MMD_DATA_REG, reg_id);
	ipq9574_qca8075_phy_reg_write(dev_id, phy_id,
			QCA8075_MMD_CTRL_REG,
			0x4000 | mmd_num);
	ipq9574_qca8075_phy_reg_write(dev_id, phy_id,
		QCA8075_MMD_DATA_REG, reg_val);

	return 0;
}

static u16 ipq9574_qca8075_phy_mmd_read(u32 dev_id, u32 phy_id,
		u16 mmd_num, u16 reg_id)
{
	ipq9574_qca8075_phy_reg_write(dev_id, phy_id,
			QCA8075_MMD_CTRL_REG, mmd_num);
	ipq9574_qca8075_phy_reg_write(dev_id, phy_id,
			QCA8075_MMD_DATA_REG, reg_id);
	ipq9574_qca8075_phy_reg_write(dev_id, phy_id,
			QCA8075_MMD_CTRL_REG,
			0x4000 | mmd_num);
	return ipq9574_qca8075_phy_reg_read(dev_id, phy_id,
			QCA8075_MMD_DATA_REG);
}

/*
 *  get phy4 medium is 100fx
 */
static u8 __medium_is_fiber_100fx(u32 dev_id, u32 phy_id)
{
	u16 phy_data;
	phy_data = ipq9574_qca8075_phy_reg_read(dev_id, phy_id,
				QCA8075_PHY_SGMII_STATUS);

	if (phy_data & QCA8075_PHY4_AUTO_FX100_SELECT) {
		return 1;
	}
	/* Link down */
	if ((!(phy_data & QCA8075_PHY4_AUTO_COPPER_SELECT)) &&
	    (!(phy_data & QCA8075_PHY4_AUTO_BX1000_SELECT)) &&
	    (!(phy_data & QCA8075_PHY4_AUTO_SGMII_SELECT))) {

		phy_data = ipq9574_qca8075_phy_reg_read(dev_id, phy_id,
					QCA8075_PHY_CHIP_CONFIG);
		if ((phy_data & QCA8075_PHY4_PREFER_FIBER)
		    && (!(phy_data & QCA8075_PHY4_FIBER_MODE_1000BX))) {
			return 1;
		}
	}
	return 0;
}

/*
 * ipq9574_qca8075_phy_set_hibernate - set hibernate status
 * set hibernate status
 */
static u32 ipq9574_qca8075_phy_set_hibernate(u32 dev_id, u32 phy_id, u8 enable)
{
	u16 phy_data;

	ipq9574_qca8075_phy_reg_write(dev_id, phy_id, QCA8075_DEBUG_PORT_ADDRESS,
					QCA8075_DEBUG_PHY_HIBERNATION_CTRL);

	phy_data = ipq9574_qca8075_phy_reg_read(dev_id, phy_id,
				QCA8075_DEBUG_PORT_DATA);

	if (enable) {
		phy_data |= 0x8000;
	} else {
		phy_data &= ~0x8000;
	}

	ipq9574_qca8075_phy_reg_write(dev_id, phy_id, QCA8075_DEBUG_PORT_DATA, phy_data);
	return 0;
}

/*
 * ipq9574_qca8075_restart_autoneg - restart the phy autoneg
 */
static u32 ipq9574_qca8075_phy_restart_autoneg(u32 dev_id, u32 phy_id)
{
	u16 phy_data;

	if (phy_id == COMBO_PHY_ID) {
		if (__medium_is_fiber_100fx(dev_id, phy_id))
			return -1;
		__phy_reg_pages_sel_by_active_medium(dev_id, phy_id);
	}
	phy_data = ipq9574_qca8075_phy_reg_read(dev_id, phy_id, QCA8075_PHY_CONTROL);
	phy_data |= QCA8075_CTRL_AUTONEGOTIATION_ENABLE;
	ipq9574_qca8075_phy_reg_write(dev_id, phy_id, QCA8075_PHY_CONTROL,
			phy_data | QCA8075_CTRL_RESTART_AUTONEGOTIATION);

	return 0;
}

/*
 * ipq9574_qca8075_phy_get_8023az status
 * get 8023az status
 */
static u32 ipq9574_qca8075_phy_get_8023az(u32 dev_id, u32 phy_id, u8 *enable)
{
	u16 phy_data;
	if (phy_id == COMBO_PHY_ID) {
		if (QCA8075_PHY_MEDIUM_COPPER !=
			__phy_active_medium_get(dev_id, phy_id))
			return -1;
	}
	*enable = 0;

	phy_data = ipq9574_qca8075_phy_mmd_read(dev_id, phy_id, QCA8075_PHY_MMD7_NUM,
					QCA8075_PHY_MMD7_ADDR_8023AZ_EEE_CTRL);

	if ((phy_data & 0x0004) && (phy_data & 0x0002))
		*enable = 1;

	return 0;
}

/*
 * ipq9574_qca8075_phy_set_powersave - set power saving status
 */
static u32 ipq9574_qca8075_phy_set_powersave(u32 dev_id, u32 phy_id, u8 enable)
{
	u16 phy_data;
	u8 status = 0;

	if (phy_id == COMBO_PHY_ID) {
		if (QCA8075_PHY_MEDIUM_COPPER !=
			__phy_active_medium_get(dev_id, phy_id))
			return -1;
	}

	if (enable) {
		ipq9574_qca8075_phy_get_8023az(dev_id, phy_id, &status);
		if (!status) {
			phy_data = ipq9574_qca8075_phy_mmd_read(dev_id, phy_id,
							QCA8075_PHY_MMD3_NUM,
					QCA8075_PHY_MMD3_ADDR_8023AZ_TIMER_CTRL);
			phy_data &= ~(1 << 14);
			ipq9574_qca8075_phy_mmd_write(dev_id, phy_id,
					QCA8075_PHY_MMD3_NUM,
					QCA8075_PHY_MMD3_ADDR_8023AZ_TIMER_CTRL,
					phy_data);
		}
		phy_data = ipq9574_qca8075_phy_mmd_read(dev_id, phy_id,
						QCA8075_PHY_MMD3_NUM,
						QCA8075_PHY_MMD3_ADDR_CLD_CTRL5);
		phy_data &= ~(1 << 14);
		ipq9574_qca8075_phy_mmd_write(dev_id, phy_id, QCA8075_PHY_MMD3_NUM,
					QCA8075_PHY_MMD3_ADDR_CLD_CTRL5,
								phy_data);

		phy_data = ipq9574_qca8075_phy_mmd_read(dev_id, phy_id,
					QCA8075_PHY_MMD3_NUM,
					QCA8075_PHY_MMD3_ADDR_CLD_CTRL3);
		phy_data &= ~(1 << 15);
		ipq9574_qca8075_phy_mmd_write(dev_id, phy_id, QCA8075_PHY_MMD3_NUM,
					QCA8075_PHY_MMD3_ADDR_CLD_CTRL3, phy_data);

	} else {
		phy_data = ipq9574_qca8075_phy_mmd_read(dev_id, phy_id,
					QCA8075_PHY_MMD3_NUM,
					QCA8075_PHY_MMD3_ADDR_8023AZ_TIMER_CTRL);
		phy_data |= (1 << 14);
		ipq9574_qca8075_phy_mmd_write(dev_id, phy_id, QCA8075_PHY_MMD3_NUM,
				QCA8075_PHY_MMD3_ADDR_8023AZ_TIMER_CTRL,
				phy_data);

		phy_data = ipq9574_qca8075_phy_mmd_read(dev_id, phy_id,
					QCA8075_PHY_MMD3_NUM,
					QCA8075_PHY_MMD3_ADDR_CLD_CTRL5);
		phy_data |= (1 << 14);
		ipq9574_qca8075_phy_mmd_write(dev_id, phy_id, QCA8075_PHY_MMD3_NUM,
				QCA8075_PHY_MMD3_ADDR_CLD_CTRL5, phy_data);

		phy_data = ipq9574_qca8075_phy_mmd_read(dev_id, phy_id,
						QCA8075_PHY_MMD3_NUM,
						QCA8075_PHY_MMD3_ADDR_CLD_CTRL3);
		phy_data |= (1 << 15);
		ipq9574_qca8075_phy_mmd_write(dev_id, phy_id, QCA8075_PHY_MMD3_NUM,
				QCA8075_PHY_MMD3_ADDR_CLD_CTRL3, phy_data);

	}
	ipq9574_qca8075_phy_reg_write(dev_id, phy_id, QCA8075_PHY_CONTROL, 0x9040);
	return 0;
}

/*
 * ipq9574_qca8075_phy_set_802.3az
 */
 static u32 ipq9574_qca8075_phy_set_8023az(u32 dev_id, u32 phy_id, u8 enable)
{
	u16 phy_data;

	if (phy_id == COMBO_PHY_ID) {
		if (QCA8075_PHY_MEDIUM_COPPER !=
			 __phy_active_medium_get(dev_id, phy_id))
			return -1;
	}
	phy_data = ipq9574_qca8075_phy_mmd_read(dev_id, phy_id, QCA8075_PHY_MMD7_NUM,
				       QCA8075_PHY_MMD7_ADDR_8023AZ_EEE_CTRL);
	if (enable) {
		phy_data |= 0x0006;

		ipq9574_qca8075_phy_mmd_write(dev_id, phy_id, QCA8075_PHY_MMD7_NUM,
			     QCA8075_PHY_MMD7_ADDR_8023AZ_EEE_CTRL, phy_data);
		if (ipq9574_qca8075_id == QCA8075_PHY_V1_0_5P) {
			/*
			 * Workaround to avoid packet loss and < 10m cable
			 * 1000M link not stable under az enable
			 */
			ipq9574_qca8075_phy_mmd_write(dev_id, phy_id,
				QCA8075_PHY_MMD3_NUM,
				QCA8075_PHY_MMD3_ADDR_8023AZ_TIMER_CTRL,
				AZ_TIMER_CTRL_ADJUST_VALUE);

			ipq9574_qca8075_phy_mmd_write(dev_id, phy_id,
					QCA8075_PHY_MMD3_NUM,
					QCA8075_PHY_MMD3_ADDR_8023AZ_CLD_CTRL,
					AZ_CLD_CTRL_ADJUST_VALUE);
		}
	} else {
		phy_data &= ~0x0006;
		ipq9574_qca8075_phy_mmd_write(dev_id, phy_id, QCA8075_PHY_MMD7_NUM,
				QCA8075_PHY_MMD7_ADDR_8023AZ_EEE_CTRL, phy_data);
		if (ipq9574_qca8075_id == QCA8075_PHY_V1_0_5P) {
			ipq9574_qca8075_phy_mmd_write(dev_id, phy_id,
					QCA8075_PHY_MMD3_NUM,
					QCA8075_PHY_MMD3_ADDR_8023AZ_TIMER_CTRL,
					AZ_TIMER_CTRL_DEFAULT_VALUE);
		}
	}
	ipq9574_qca8075_phy_restart_autoneg(dev_id, phy_id);
	return 0;
}

void ipq9574_qca8075_phy_map_ops(struct phy_ops **ops)
{
	*ops = ipq9574_qca8075_ops;
}

void ipq9574_qca8075_phy_serdes_reset(u32 phy_id)
{
	ipq9574_qca8075_phy_reg_write(0,
			phy_id + QCA8075_PHY_PSGMII_ADDR_INC,
			QCA8075_MODE_RESET_REG,
			QCA8075_MODE_CHANAGE_RESET);
	mdelay(100);
	ipq9574_qca8075_phy_reg_write(0,
			phy_id + QCA8075_PHY_PSGMII_ADDR_INC,
			QCA8075_MODE_RESET_REG,
			QCA8075_MODE_RESET_DEFAULT_VALUE);

}

static  u16 ipq9574_qca8075_phy_interface_get_mode(u32 phy_id)
{
	u16 phy_data;

	phy_data = ipq9574_qca8075_phy_reg_read(0,
			phy_id + QCA8075_PHY_MAX_ADDR_INC,
			QCA8075_PHY_CHIP_CONFIG);
	phy_data &= 0x000f;
	return phy_data;
}

void ipq9574_qca8075_phy_interface_set_mode(u32 phy_id, u32 mode)
{
	u16 phy_data;

	phy_data = ipq9574_qca8075_phy_interface_get_mode(phy_id);
	if (phy_data != mode) {
		phy_data = ipq9574_qca8075_phy_reg_read(0,
			phy_id + QCA8075_PHY_MAX_ADDR_INC,
			QCA8075_PHY_CHIP_CONFIG);
		phy_data &= 0xfff0;
		ipq9574_qca8075_phy_reg_write(0,
				phy_id + QCA8075_PHY_MAX_ADDR_INC,
				QCA8075_PHY_CHIP_CONFIG,
				phy_data | mode);
		ipq9574_qca8075_phy_serdes_reset(phy_id);
	}
}

int ipq9574_qca8075_phy_init(struct phy_ops **ops, u32 phy_id)
{
	u16 phy_data;
	u32 port_id = 0;
	u32 first_phy_id;

	first_phy_id = phy_id;
	ipq9574_qca8075_ops = (struct phy_ops *)malloc(sizeof(struct phy_ops));
	if (!ipq9574_qca8075_ops)
		return -ENOMEM;

	ipq9574_qca8075_ops->phy_get_link_status = ipq9574_qca8075_phy_get_link_status;
	ipq9574_qca8075_ops->phy_get_speed = ipq9574_qca8075_phy_get_speed;
	ipq9574_qca8075_ops->phy_get_duplex = ipq9574_qca8075_phy_get_duplex;
	*ops = ipq9574_qca8075_ops;

	ipq9574_qca8075_id = phy_data = ipq9574_qca8075_phy_reg_read(0x0, phy_id, QCA8075_PHY_ID1);
	printf ("PHY ID1: 0x%x\n", phy_data);
	phy_data = ipq9574_qca8075_phy_reg_read(0x0, phy_id, QCA8075_PHY_ID2);
	printf ("PHY ID2: 0x%x\n", phy_data);
	ipq9574_qca8075_id = (ipq9574_qca8075_id << 16) | phy_data;

	if (ipq9574_qca8075_id == QCA8075_PHY_V1_0_5P) {
		phy_data = ipq9574_qca8075_phy_mmd_read(0, PSGMII_ID,
			QCA8075_PHY_MMD1_NUM, QCA8075_PSGMII_FIFI_CTRL);
		phy_data &= 0xbfff;
		ipq9574_qca8075_phy_mmd_write(0, PSGMII_ID, QCA8075_PHY_MMD1_NUM,
			QCA8075_PSGMII_FIFI_CTRL, phy_data);
	}

	/*
	 * Enable phy power saving function by default
	 */
	if ((ipq9574_qca8075_id == QCA8075_PHY_V1_0_5P) ||
	    (ipq9574_qca8075_id == QCA8075_PHY_V1_1_5P) ||
	    (ipq9574_qca8075_id == QCA8075_PHY_V1_1_2P)) {
		for (port_id = 0; port_id < 5; port_id++) {
			/*enable phy power saving function by default */
			phy_id = first_phy_id + port_id;
			ipq9574_qca8075_phy_set_8023az(0x0, phy_id, 0x1);
			ipq9574_qca8075_phy_set_powersave(0x0, phy_id, 0x1);
			ipq9574_qca8075_phy_set_hibernate(0x0, phy_id, 0x1);

			/*
			 * change malibu control_dac[2:0] of MMD7 0x801A bit[9:7]
			 * from 111 to 101
			 */
			phy_data = ipq9574_qca8075_phy_mmd_read(0, phy_id,
				QCA8075_PHY_MMD7_NUM, QCA8075_PHY_MMD7_DAC_CTRL);
			phy_data &= ~QCA8075_DAC_CTRL_MASK;
			phy_data |= QCA8075_DAC_CTRL_VALUE;
			ipq9574_qca8075_phy_mmd_write(0, phy_id, QCA8075_PHY_MMD7_NUM,
				QCA8075_PHY_MMD7_DAC_CTRL, phy_data);

			/* add 10M and 100M link LED behavior for QFN board*/
			phy_data = ipq9574_qca8075_phy_mmd_read(0, phy_id, QCA8075_PHY_MMD7_NUM,
				QCA8075_PHY_MMD7_LED_1000_CTRL1);
			phy_data &= ~QCA8075_LED_1000_CTRL1_100_10_MASK;
			phy_data |= QCA8075_LED_1000_CTRL1_100_10_MASK;
			ipq9574_qca8075_phy_mmd_write(0 , phy_id, QCA8075_PHY_MMD7_NUM,
				QCA8075_PHY_MMD7_LED_1000_CTRL1, phy_data);
		}
	}
	if ((ipq9574_qca8075_id == QCA8075_PHY_V1_1_2P) && (first_phy_id >= 0x3)) {
		phy_id = first_phy_id - 0x3;
	}
	else {
		phy_id = first_phy_id;
	}

	/*
	 * Enable AZ transmitting ability
	 */
	ipq9574_qca8075_phy_mmd_write(0, phy_id + 5, QCA8075_PHY_MMD1_NUM,
				QCA8075_PSGMII_MODE_CTRL,
				QCA8075_PHY_PSGMII_MODE_CTRL_ADJUST_VALUE);

	/* adjust psgmii serdes tx amp */
	ipq9574_qca8075_phy_reg_write(0, phy_id + 5, QCA8075_PSGMII_TX_DRIVER_1_CTRL,
				QCA8075_PHY_PSGMII_REDUCE_SERDES_TX_AMP);

	/* to avoid psgmii module goes into hibernation, work with psgmii self test*/
	phy_data = ipq9574_qca8075_phy_mmd_read(0, phy_id + 4, QCA8075_PHY_MMD3_NUM, 0x805a);
	phy_data &= (~(1 << 1));
	ipq9574_qca8075_phy_mmd_write(0, phy_id + 4, QCA8075_PHY_MMD3_NUM, 0x805a, phy_data);

	return 0;
}
