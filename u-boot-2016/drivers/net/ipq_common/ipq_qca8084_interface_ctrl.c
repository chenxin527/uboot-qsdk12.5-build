/*
 * Copyright (c) 2022, The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/
#include "ipq_phy.h"
#include "ipq_qca8084.h"
#include "ipq_qca8084_clk.h"
#include "ipq_qca8084_interface_ctrl.h"
#include <malloc.h>

#ifdef DEBUG
#define pr_debug(fmt, args...) printf(fmt, ##args);
#else
#define pr_debug(fmt, args...)
#endif

extern void qca8084_phy_reset(u32 phy_id);
extern u16 qca8084_phy_reg_read(u32 phy_id, u32 reg_id);
extern u16 qca8084_phy_reg_write(u32 phy_id, u32 reg_id, u16 value);
extern u16 qca8084_phy_mmd_read(u32 phy_id, u16 mmd_num, u16 reg_id);
extern u16 qca8084_phy_mmd_write(u32 phy_id, u16 mmd_num, u16 reg_id,
				 u16 value);
extern void qca8084_phy_modify_mmd(uint32_t phy_addr, uint32_t mmd_num,
				uint32_t mmd_reg, uint32_t mask, uint32_t value);
extern void qca8084_phy_modify_mii(uint32_t phy_addr, uint32_t mii_reg,
				uint32_t mask, uint32_t value);
extern uint32_t ipq_mii_read(uint32_t reg);
extern void ipq_mii_write(uint32_t reg, uint32_t val);
extern void ipq_mii_update(uint32_t reg, uint32_t mask, uint32_t val);
extern void qca8084_port_clk_en_set(uint32_t qca8084_port_id, uint8_t mask,
				    uint8_t enable);
extern void qca8084_clk_assert(const char *clock_id);
extern void qca8084_port_clk_reset(uint32_t qca8084_port_id, uint8_t mask);
extern void qca8084_port_clk_rate_set(uint32_t qca8084_port_id, uint32_t rate);

#ifdef CONFIG_QCA8084_PHY_MODE
extern void qca8084_clk_deassert(const char *clock_id);
#endif

#ifdef CONFIG_QCA8084_SWT_MODE
extern void qca8084_uniphy_raw_clock_set(qca8084_clk_parent_t uniphy_clk,
		uint64_t rate);
#endif

#ifdef CONFIG_QCA8084_BYPASS_MODE
extern void qca8084_phy_sgmii_speed_fixup (u32 phy_addr, u32 link,
		fal_port_speed_t new_speed);
#endif

void qca8084_serdes_addr_get(uint32_t serdes_id, uint32_t *address)
{
	uint32_t data = 0;

	data = ipq_mii_read(SERDES_CFG_OFFSET);
	switch(serdes_id)
	{
		case QCA8084_UNIPHY_SGMII_0:
			*address = (data >> SERDES_CFG_S0_ADDR_BOFFSET) & 0x1f;
			break;
		case QCA8084_UNIPHY_SGMII_1:
			*address = (data >> SERDES_CFG_S1_ADDR_BOFFSET) & 0x1f;
			break;
		case QCA8084_UNIPHY_XPCS:
			*address = (data >> SERDES_CFG_S1_XPCS_ADDR_BOFFSET) & 0x1f;
			break;
		default:
			pr_debug("Serdes id not matching\n");
			break;
	}
}

static void qca8084_uniphy_calibration(uint32_t uniphy_addr)
{
	uint16_t uniphy_data = 0;
	uint32_t retries = 100, calibration_done = 0;

	/* wait calibration done to uniphy*/
	while (calibration_done != QCA8084_UNIPHY_MMD1_CALIBRATION_DONE) {
		mdelay(1);
		if (retries-- == 0)
			pr_debug("uniphy callibration time out!\n");
		uniphy_data = qca8084_phy_mmd_read(uniphy_addr, QCA8084_UNIPHY_MMD1,
			QCA8084_UNIPHY_MMD1_CALIBRATION4);

		calibration_done = (uniphy_data & QCA8084_UNIPHY_MMD1_CALIBRATION_DONE);
	}
}

void qca8084_port_speed_clock_set(uint32_t qca8084_port_id,
				  fal_port_speed_t speed)
{
	uint32_t clk_rate = 0;

	switch(speed)
	{
		case FAL_SPEED_2500:
			clk_rate = UQXGMII_SPEED_2500M_CLK;
			break;
		case FAL_SPEED_1000:
			clk_rate = UQXGMII_SPEED_1000M_CLK;
			break;
		case FAL_SPEED_100:
			clk_rate = UQXGMII_SPEED_100M_CLK;
			break;
		case FAL_SPEED_10:
			clk_rate = UQXGMII_SPEED_10M_CLK;
			break;
		default:
			pr_debug("Unknown speed\n");
			return;
	}

	qca8084_port_clk_rate_set(qca8084_port_id, clk_rate);
}

void qca8084_ephy_addr_get(uint32_t qca8084_port_id, uint32_t *phy_addr)
{
	uint32_t data = 0;

	data = ipq_mii_read(EPHY_CFG_OFFSET);
	switch(qca8084_port_id)
	{
		case PORT1:
			*phy_addr = (data >> EPHY_CFG_EPHY0_ADDR_BOFFSET) & 0x1f;
			break;
		case PORT2:
			*phy_addr = (data >> EPHY_CFG_EPHY1_ADDR_BOFFSET) & 0x1f;
			break;
		case PORT3:
			*phy_addr = (data >> EPHY_CFG_EPHY2_ADDR_BOFFSET) & 0x1f;
			break;
		case PORT4:
			*phy_addr = (data >> EPHY_CFG_EPHY3_ADDR_BOFFSET) & 0x1f;
			break;
		default:
			pr_debug("qca8084_port_id not matching\n");
			break;
	}
}

#ifdef CONFIG_QCA8084_PHY_MODE
static uint16_t qca8084_uniphy_xpcs_mmd_read(uint16_t mmd_num, uint16_t mmd_reg)
{
	uint32_t uniphy_xpcs_addr = 0;

	qca8084_serdes_addr_get(QCA8084_UNIPHY_XPCS, &uniphy_xpcs_addr);

	return qca8084_phy_mmd_read(uniphy_xpcs_addr, mmd_num, mmd_reg);
}

static void qca8084_uniphy_xpcs_mmd_write(uint16_t mmd_num, uint16_t mmd_reg,
					  uint16_t reg_val)
{
	uint32_t uniphy_xpcs_addr = 0;
#ifdef DEBUG
	uint16_t phy_data = 0;
#endif

	qca8084_serdes_addr_get(QCA8084_UNIPHY_XPCS, &uniphy_xpcs_addr);

	qca8084_phy_mmd_write(uniphy_xpcs_addr, mmd_num, mmd_reg, reg_val);
	/*check the mmd register value*/
#ifdef DEBUG
	phy_data =
#endif
		qca8084_uniphy_xpcs_mmd_read(mmd_num, mmd_reg);

	pr_debug("phy_addr:0x%x, mmd_num:0x%x, mmd_reg:0x%x, phy_data:0x%x\n",
		uniphy_xpcs_addr, mmd_num, mmd_reg, phy_data);
}

static void qca8084_uniphy_xpcs_modify_mmd(uint32_t mmd_num, uint32_t mmd_reg,
					   uint32_t mask, uint32_t value)
{
	uint16_t phy_data = 0, new_phy_data = 0;

	phy_data = qca8084_uniphy_xpcs_mmd_read(mmd_num, mmd_reg);
	new_phy_data = (phy_data & ~mask) | value;
	qca8084_uniphy_xpcs_mmd_write(mmd_num, mmd_reg, new_phy_data);
}

static uint32_t qca8084_uniphy_xpcs_port_to_mmd(uint32_t qca8084_port_id)
{
	uint32_t mmd_id = 0;

	switch(qca8084_port_id)
	{
		case PORT1:
			mmd_id = QCA8084_UNIPHY_MMD31;
			break;
		case PORT2:
			mmd_id = QCA8084_UNIPHY_MMD26;
			break;
		case PORT3:
			mmd_id = QCA8084_UNIPHY_MMD27;
			break;
		case PORT4:
			mmd_id = QCA8084_UNIPHY_MMD28;
			break;
		default:
			pr_debug("Port not matching qca8084 ports\n");
	}

	return mmd_id;
}

static void qca8084_uniphy_xpcs_modify_port_mmd(uint32_t qca8084_port_id,
						uint32_t mmd_reg, uint32_t mask,
						uint32_t value)
{
	uint32_t mmd_id = 0;

	mmd_id = qca8084_uniphy_xpcs_port_to_mmd(qca8084_port_id);

	qca8084_uniphy_xpcs_modify_mmd(mmd_id, mmd_reg, mask, value);
}

static void qca8084_uniphy_xpcs_8023az_enable(void)
{
	uint16_t uniphy_data = 0;

	uniphy_data = qca8084_uniphy_xpcs_mmd_read(QCA8084_UNIPHY_MMD3,
		QCA8084_UNIPHY_MMD3_AN_LP_BASE_ABL2);
	if(!(uniphy_data & QCA8084_UNIPHY_MMD3_XPCS_EEE_CAP))
		return;

	/*Configure the EEE related timer*/
	qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
					QCA8084_UNIPHY_MMD3_EEE_MODE_CTRL,
					0x0f40, QCA8084_UNIPHY_MMD3_EEE_RES_REGS |
					QCA8084_UNIPHY_MMD3_EEE_SIGN_BIT_REGS);

	qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
					QCA8084_UNIPHY_MMD3_EEE_TX_TIMER,
					0x1fff, QCA8084_UNIPHY_MMD3_EEE_TSL_REGS|
					QCA8084_UNIPHY_MMD3_EEE_TLU_REGS |
					QCA8084_UNIPHY_MMD3_EEE_TWL_REGS);

	qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
					QCA8084_UNIPHY_MMD3_EEE_RX_TIMER,
					0x1fff, QCA8084_UNIPHY_MMD3_EEE_100US_REG_REGS|
					QCA8084_UNIPHY_MMD3_EEE_RWR_REG_REGS);

	/*enable TRN_LPI*/
	qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
					QCA8084_UNIPHY_MMD3_EEE_MODE_CTRL1,
					0x101, QCA8084_UNIPHY_MMD3_EEE_TRANS_LPI_MODE|
					QCA8084_UNIPHY_MMD3_EEE_TRANS_RX_LPI_MODE);

	/*enable TX/RX LPI pattern*/
	qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
					QCA8084_UNIPHY_MMD3_EEE_MODE_CTRL,
					0x3, QCA8084_UNIPHY_MMD3_EEE_EN);
}

static void qca8084_uniphy_xpcs_10g_r_linkup(void)
{
	uint16_t uniphy_data = 0;
	uint32_t retries = 100, linkup = 0;

	/* wait 10G_R link up */
	while (linkup != QCA8084_UNIPHY_MMD3_10GBASE_R_UP) {
		mdelay(1);
		if (retries-- == 0)
			pr_debug("10g_r link up timeout\n");
		uniphy_data = qca8084_uniphy_xpcs_mmd_read(QCA8084_UNIPHY_MMD3,
			QCA8084_UNIPHY_MMD3_10GBASE_R_PCS_STATUS1);

		linkup = (uniphy_data & QCA8084_UNIPHY_MMD3_10GBASE_R_UP);
	}
}

static void qca8084_uniphy_xpcs_soft_reset(void)
{
	uint16_t uniphy_data = 0;
	uint32_t retries = 100, reset_done = QCA8084_UNIPHY_MMD3_XPCS_SOFT_RESET;

	qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
					QCA8084_UNIPHY_MMD3_DIG_CTRL1, 0x8000,
					QCA8084_UNIPHY_MMD3_XPCS_SOFT_RESET);

	while (reset_done) {
		mdelay(1);
		if (retries-- == 0)
			pr_debug("xpcs soft reset timeout\n");
		uniphy_data = qca8084_uniphy_xpcs_mmd_read(QCA8084_UNIPHY_MMD3,
						QCA8084_UNIPHY_MMD3_DIG_CTRL1);

		reset_done = (uniphy_data & QCA8084_UNIPHY_MMD3_XPCS_SOFT_RESET);
	}
}

void qca8084_uniphy_xpcs_speed_set(uint32_t qca8084_port_id,
				   fal_port_speed_t speed)
{
	uint32_t xpcs_speed = 0;

	switch(speed)
	{
		case FAL_SPEED_2500:
			xpcs_speed = QCA8084_UNIPHY_MMD_XPC_SPEED_2500;
			break;
		case FAL_SPEED_1000:
			xpcs_speed = QCA8084_UNIPHY_MMD_XPC_SPEED_1000;
			break;
		case FAL_SPEED_100:
			xpcs_speed = QCA8084_UNIPHY_MMD_XPC_SPEED_100;
			break;
		case FAL_SPEED_10:
			xpcs_speed = QCA8084_UNIPHY_MMD_XPC_SPEED_10;
			break;
		default:
			pr_debug("Unknown speed\n");
			return;
	}
	qca8084_uniphy_xpcs_modify_port_mmd(qca8084_port_id,
						QCA8084_UNIPHY_MMD_MII_CTRL,
						QCA8084_UNIPHY_MMD_XPC_SPEED_MASK,
						xpcs_speed);
}

void qca8084_uniphy_uqxgmii_function_reset(uint32_t qca8084_port_id)
{
	uint32_t uniphy_addr = 0;

	qca8084_serdes_addr_get(QCA8084_UNIPHY_SGMII_1, &uniphy_addr);

	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_USXGMII_RESET, BIT(qca8084_port_id-1), 0);
	mdelay(1);
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_USXGMII_RESET, BIT(qca8084_port_id-1),
		BIT(qca8084_port_id-1));
	if(qca8084_port_id == PORT1)
		qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
			QCA8084_UNIPHY_MMD_MII_DIG_CTRL,
			0x400, QCA8084_UNIPHY_MMD3_USXG_FIFO_RESET);
	else
		qca8084_uniphy_xpcs_modify_port_mmd(qca8084_port_id,
			QCA8084_UNIPHY_MMD_MII_DIG_CTRL,
			0x20, QCA8084_UNIPHY_MMD_USXG_FIFO_RESET);
}

void qca8084_uniphy_xpcs_autoneg_restart(uint32_t qca8084_port_id)
{
	uint32_t retries = 500, uniphy_data = 0, mmd_id = 0;

	mmd_id = qca8084_uniphy_xpcs_port_to_mmd(qca8084_port_id);
	qca8084_uniphy_xpcs_modify_mmd(mmd_id, QCA8084_UNIPHY_MMD_MII_CTRL,
		QCA8084_UNIPHY_MMD_MII_AN_RESTART, QCA8084_UNIPHY_MMD_MII_AN_RESTART);
	mdelay(1);
	uniphy_data = qca8084_uniphy_xpcs_mmd_read(mmd_id,
						QCA8084_UNIPHY_MMD_MII_ERR_SEL);
	while(!(uniphy_data & QCA8084_UNIPHY_MMD_MII_AN_COMPLETE_INT))
	{
		mdelay(1);
		if (retries-- == 0)
		{
			pr_debug("xpcs uniphy autoneg restart timeout\n");
		}
		uniphy_data = qca8084_uniphy_xpcs_mmd_read(mmd_id,
			QCA8084_UNIPHY_MMD_MII_ERR_SEL);
	}
}

static void _qca8084_interface_uqxgmii_mode_set(uint32_t uniphy_addr)
{
	uint32_t qca8084_port_id = 0, phy_addr = 0;

	/*reset xpcs*/
	pr_debug("reset xpcs\n");
	qca8084_clk_assert(QCA8084_UNIPHY_XPCS_RST);
	/*select xpcs mode*/
	pr_debug("select xpcs mode\n");
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_MODE_CTRL, 0x1f00, QCA8084_UNIPHY_MMD1_XPCS_MODE);
	/*config dapa pass as usxgmii*/
	pr_debug("config dapa pass as usxgmii\n");
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_GMII_DATAPASS_SEL, QCA8084_UNIPHY_MMD1_DATAPASS_MASK,
		QCA8084_UNIPHY_MMD1_DATAPASS_USXGMII);
	/*reset and release uniphy GMII/XGMII and ethphy GMII*/
	pr_debug("reset and release uniphy GMII/XGMII and ethphy GMII\n");
	for(qca8084_port_id = PORT1; qca8084_port_id <= PORT4;
		qca8084_port_id++)
	{
		qca8084_port_clk_reset(qca8084_port_id,
			QCA8084_CLK_TYPE_UNIPHY|QCA8084_CLK_TYPE_EPHY);
	}

	/*ana sw reset and release*/
	pr_debug("ana sw reset and release\n");
	qca8084_phy_modify_mii(uniphy_addr,
		QCA8084_UNIPHY_PLL_POWER_ON_AND_RESET, 0x40, QCA8084_UNIPHY_ANA_SOFT_RESET);
	mdelay(10);
	qca8084_phy_modify_mii(uniphy_addr,
		QCA8084_UNIPHY_PLL_POWER_ON_AND_RESET, 0x40, QCA8084_UNIPHY_ANA_SOFT_RELEASE);

	/*Wait calibration done*/
	pr_debug("Wait calibration done\n");
	qca8084_uniphy_calibration(uniphy_addr);
	/*Enable SSCG(Spread Spectrum Clock Generator)*/
	pr_debug("enable uniphy sscg\n");
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_CDA_CONTROL1, 0x8, QCA8084_UNIPHY_MMD1_SSCG_ENABLE);
	/*release XPCS*/
	pr_debug("release XPCS\n");
	qca8084_clk_deassert(QCA8084_UNIPHY_XPCS_RST);
	/*ethphy software reset*/
	pr_debug("ethphy software reset\n");
	for(qca8084_port_id = PORT1; qca8084_port_id <= PORT4;
		qca8084_port_id++)
	{
		qca8084_ephy_addr_get(qca8084_port_id, &phy_addr);
		qca8084_phy_reset(phy_addr);
	}
	/*Set BaseR mode*/
	pr_debug("Set BaseR mode\n");
	qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
		QCA8084_UNIPHY_MMD3_PCS_CTRL2, 0xf, QCA8084_UNIPHY_MMD3_PCS_TYPE_10GBASE_R);
	/*wait 10G base_r link up*/
	pr_debug("wait 10G base_r link up\n");
	qca8084_uniphy_xpcs_10g_r_linkup();
	/*enable UQXGMII mode*/
	pr_debug("enable UQSXGMII mode\n");
	qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
		QCA8084_UNIPHY_MMD3_DIG_CTRL1, 0x200, QCA8084_UNIPHY_MMD3_USXGMII_EN);
	/*set UQXGMII mode*/
	pr_debug("set QXGMII mode\n");
	qca8084_uniphy_xpcs_modify_mmd(QCA8084_UNIPHY_MMD3,
		QCA8084_UNIPHY_MMD3_VR_RPCS_TPC, 0x1c00, QCA8084_UNIPHY_MMD3_QXGMII_EN);
	/*set AM interval*/
	pr_debug("set AM interval\n");
	qca8084_uniphy_xpcs_mmd_write(QCA8084_UNIPHY_MMD3,
		QCA8084_UNIPHY_MMD3_MII_AM_INTERVAL, QCA8084_UNIPHY_MMD3_MII_AM_INTERVAL_VAL);
	/*xpcs software reset*/
	pr_debug("xpcs software reset\n");
	qca8084_uniphy_xpcs_soft_reset();
}

void qca8084_interface_uqxgmii_mode_set(void)
{
	uint32_t uniphy_addr = 0, qca8084_port_id = 0;

	qca8084_serdes_addr_get(QCA8084_UNIPHY_SGMII_1, &uniphy_addr);

	/*disable IPG_tuning bypass*/
	pr_debug("disable IPG_tuning bypass\n");
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_BYPASS_TUNING_IPG,
		QCA8084_UNIPHY_MMD1_BYPASS_TUNING_IPG_EN, 0);
	/*disable uniphy GMII/XGMII clock and disable ethphy GMII clock*/
	pr_debug("disable uniphy GMII/XGMII clock and ethphy GMII clock\n");
	for(qca8084_port_id = PORT1; qca8084_port_id <= PORT4;
		qca8084_port_id++)
	{
		qca8084_port_clk_en_set(qca8084_port_id,
			QCA8084_CLK_TYPE_UNIPHY|QCA8084_CLK_TYPE_EPHY, 0);
	}
	/*configure uqxgmii mode*/
	pr_debug("configure uqxgmii mode\n");
	_qca8084_interface_uqxgmii_mode_set(uniphy_addr);
	/*enable auto-neg complete interrupt,Mii using mii-4bits,
		configure as PHY mode, enable autoneg ability*/
	pr_debug("enable auto-neg complete interrupt, Mii using mii-4bits,"
		" configure as PHY mode, enable autoneg ability, disable TICD\n");
	for (qca8084_port_id = PORT1; qca8084_port_id <= PORT4;
		qca8084_port_id++)
	{
		/*enable auto-neg complete interrupt,Mii using mii-4bits,configure as PHY mode*/
		qca8084_uniphy_xpcs_modify_port_mmd(qca8084_port_id,
			QCA8084_UNIPHY_MMD_MII_AN_INT_MSK, 0x109,
			QCA8084_UNIPHY_MMD_AN_COMPLETE_INT |
			QCA8084_UNIPHY_MMD_MII_4BITS_CTRL |
			QCA8084_UNIPHY_MMD_TX_CONFIG_CTRL);

		/*enable autoneg ability*/
		qca8084_uniphy_xpcs_modify_port_mmd(qca8084_port_id,
			QCA8084_UNIPHY_MMD_MII_CTRL, 0x3060, QCA8084_UNIPHY_MMD_MII_AN_ENABLE |
			QCA8084_UNIPHY_MMD_XPC_SPEED_1000);

		/*disable TICD*/
		qca8084_uniphy_xpcs_modify_port_mmd(qca8084_port_id,
			QCA8084_UNIPHY_MMD_MII_XAUI_MODE_CTRL, 0x1,
			QCA8084_UNIPHY_MMD_TX_IPG_CHECK_DISABLE);
	}

	/*enable EEE for xpcs*/
	pr_debug("enable EEE for xpcs\n");
	qca8084_uniphy_xpcs_8023az_enable();
}
#endif /* CONFIG_QCA8084_PHY_MODE */

#ifdef CONFIG_QCA8084_SWT_MODE
void qca8084_uniphy_sgmii_function_reset(u32 uniphy_index)
{
	u32 uniphy_addr = 0;

	qca8084_serdes_addr_get(uniphy_index, &uniphy_addr);

	/*sgmii channel0 adpt reset*/
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_CHANNEL0_CFG, QCA8084_UNIPHY_MMD1_SGMII_ADPT_RESET, 0);
	mdelay(1);
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_CHANNEL0_CFG, QCA8084_UNIPHY_MMD1_SGMII_ADPT_RESET,
		QCA8084_UNIPHY_MMD1_SGMII_ADPT_RESET);
	/*ipg tune reset*/
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_USXGMII_RESET, QCA8084_UNIPHY_MMD1_SGMII_FUNC_RESET, 0);
	mdelay(1);
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_USXGMII_RESET, QCA8084_UNIPHY_MMD1_SGMII_FUNC_RESET,
		QCA8084_UNIPHY_MMD1_SGMII_FUNC_RESET);

}

void qca8084_interface_sgmii_mode_set(u32 uniphy_index, u32 qca8084_port_id, mac_config_t *config)
{
	u32 uniphy_addr = 0, mode_ctrl = 0, speed_mode = 0;
	u32 uniphy_port_id = 0, ethphy_clk_mask = 0;
	u64 raw_clk = 0;

	/*get the uniphy address*/
	qca8084_serdes_addr_get(uniphy_index, &uniphy_addr);

	if(config->mac_mode == QCA8084_MAC_MODE_SGMII)
	{
		mode_ctrl = QCA8084_UNIPHY_MMD1_SGMII_MODE;
		raw_clk = UNIPHY_CLK_RATE_125M;
	}
	else
	{
		mode_ctrl = QCA8084_UNIPHY_MMD1_SGMII_PLUS_MODE;
		raw_clk = UNIPHY_CLK_RATE_312M;
	}

	if(config->clock_mode == QCA8084_INTERFACE_CLOCK_MAC_MODE)
		mode_ctrl |= QCA8084_UNIPHY_MMD1_SGMII_MAC_MODE;
	else
	{
		mode_ctrl |= QCA8084_UNIPHY_MMD1_SGMII_PHY_MODE;
		/*eththy clock should be accessed for phy mode*/
		ethphy_clk_mask = QCA8084_CLK_TYPE_EPHY;
	}

	pr_debug("uniphy:%d,mode:%s,autoneg_en:%d,force_speed:%d,clk_mask:0x%x\n",
		uniphy_index, (config->mac_mode == QCA8084_MAC_MODE_SGMII)?"sgmii":"sgmii plus",
		config->auto_neg, config->force_speed,
		ethphy_clk_mask);

	/*GMII interface clock disable*/
	pr_debug("GMII interface clock disable\n");
	qca8084_port_clk_en_set(qca8084_port_id, ethphy_clk_mask, 0);

	/*when access uniphy0 clock, port5 should be used, but for phy mode,
		the port 4 connect to uniphy0, so need to change the port id*/
	if(uniphy_index == QCA8084_UNIPHY_SGMII_0)
		uniphy_port_id = PORT5;
	else
		uniphy_port_id = qca8084_port_id;
	qca8084_port_clk_en_set(uniphy_port_id, QCA8084_CLK_TYPE_UNIPHY, 0);

	/*uniphy1 xpcs reset, and configure raw clk*/
	if(uniphy_index == QCA8084_UNIPHY_SGMII_1)
	{
		pr_debug("uniphy1 xpcs reset, confiugre raw clock as:%lld\n",
			raw_clk);
		qca8084_clk_assert(QCA8084_UNIPHY_XPCS_RST);
		qca8084_uniphy_raw_clock_set(QCA8084_P_UNIPHY1_RX, raw_clk);
		qca8084_uniphy_raw_clock_set(QCA8084_P_UNIPHY1_TX, raw_clk);
	}
	else
	{
		pr_debug("uniphy0 configure raw clock as %lld\n",	raw_clk);
		qca8084_uniphy_raw_clock_set(QCA8084_P_UNIPHY0_RX, raw_clk);
		qca8084_uniphy_raw_clock_set(QCA8084_P_UNIPHY0_TX, raw_clk);
	}

	/*configure SGMII mode or SGMII+ mode*/
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_MODE_CTRL, QCA8084_UNIPHY_MMD1_SGMII_MODE_CTRL_MASK,
		mode_ctrl);

	/*GMII datapass selection, 0 is for SGMII, 1 is for USXGMII*/
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_GMII_DATAPASS_SEL, QCA8084_UNIPHY_MMD1_DATAPASS_MASK, QCA8084_UNIPHY_MMD1_DATAPASS_SGMII);
	/*configue force or autoneg*/
	if(!config->auto_neg)
	{
		qca8084_port_speed_clock_set(qca8084_port_id,
			config->force_speed);
		switch (config->force_speed)
		{
			case FAL_SPEED_10:
				speed_mode = QCA8084_UNIPHY_MMD1_CH0_FORCE_ENABLE |
					QCA8084_UNIPHY_MMD1_CH0_FORCE_SPEED_10M;
				break;
			case FAL_SPEED_100:
				speed_mode = QCA8084_UNIPHY_MMD1_CH0_FORCE_ENABLE |
					QCA8084_UNIPHY_MMD1_CH0_FORCE_SPEED_100M;
				break;
			case FAL_SPEED_1000:
			case FAL_SPEED_2500:
				speed_mode = QCA8084_UNIPHY_MMD1_CH0_FORCE_ENABLE |
					QCA8084_UNIPHY_MMD1_CH0_FORCE_SPEED_1G;
				break;
			default:
				break;
		}
	}
	else
	{
		speed_mode = QCA8084_UNIPHY_MMD1_CH0_AUTONEG_ENABLE;
	}
	qca8084_phy_modify_mmd(uniphy_addr, QCA8084_UNIPHY_MMD1,
		QCA8084_UNIPHY_MMD1_CHANNEL0_CFG, QCA8084_UNIPHY_MMD1_CH0_FORCE_SPEED_MASK, speed_mode);

	/*GMII interface clock reset and release\n*/
	pr_debug("GMII interface clock reset and release\n");
	qca8084_port_clk_reset(qca8084_port_id, ethphy_clk_mask);
	qca8084_port_clk_reset(uniphy_port_id, QCA8084_CLK_TYPE_UNIPHY);

	/*analog software reset and release*/
	pr_debug("analog software reset and release\n");
	qca8084_phy_modify_mii(uniphy_addr,
		QCA8084_UNIPHY_PLL_POWER_ON_AND_RESET, 0x40, QCA8084_UNIPHY_ANA_SOFT_RESET);
	mdelay(1);
	qca8084_phy_modify_mii(uniphy_addr,
		QCA8084_UNIPHY_PLL_POWER_ON_AND_RESET, 0x40, QCA8084_UNIPHY_ANA_SOFT_RELEASE);

	/*wait uniphy calibration done*/
	pr_debug("wait uniphy calibration done\n");
	qca8084_uniphy_calibration(uniphy_addr);

	/*GMII interface clock enable*/
	pr_debug("GMII interface clock enable\n");
	qca8084_port_clk_en_set(qca8084_port_id, ethphy_clk_mask, 1);
	qca8084_port_clk_en_set(uniphy_port_id, QCA8084_CLK_TYPE_UNIPHY, 1);

	return;
}

uint8_t qca8084_uniphy_mode_check(uint32_t uniphy_index,
				  qca8084_uniphy_mode_t uniphy_mode)
{
	uint32_t uniphy_addr = 0;
	uint16_t uniphy_mode_ctrl_data = 0;

	qca8084_serdes_addr_get(uniphy_index, &uniphy_addr);

	uniphy_mode_ctrl_data = qca8084_phy_mmd_read(uniphy_addr,
		QCA8084_UNIPHY_MMD1, QCA8084_UNIPHY_MMD1_MODE_CTRL);
	if(uniphy_mode_ctrl_data == PHY_INVALID_DATA)
		return 0;

	if(!(uniphy_mode & uniphy_mode_ctrl_data))
		return 0;

	return 1;
}
#endif /* CONFIG_QCA8084_SWT_MODE */

#ifdef CONFIG_QCA8084_BYPASS_MODE
void qca8084_phy_sgmii_mode_set(uint32_t phy_addr, u32 interface_mode,
		u32 link, fal_port_speed_t speed)
{
	uint32_t phy_addr_tmp = 0;
	mac_config_t config = {0};

	if(interface_mode == PHY_SGMII_BASET)
		config.mac_mode = QCA8084_MAC_MODE_SGMII;
	else if(interface_mode == PORT_SGMII_PLUS)
		config.mac_mode = QCA8084_MAC_MODE_SGMII_PLUS;
	else {
		printf("Unsupported interface mode \n");
		return;
	}

	config.clock_mode = QCA8084_INTERFACE_CLOCK_PHY_MODE;
	config.auto_neg = 1;

	qca8084_ephy_addr_get(PORT4, &phy_addr_tmp);
	if(phy_addr_tmp != phy_addr)
	{
		printf("phy_addr:0x%x is not matched with port4 phy addr:0x%x\n",
			phy_addr, phy_addr_tmp);
		return;
	}

	qca8084_interface_sgmii_mode_set(QCA8084_UNIPHY_SGMII_0,
			PORT4, &config);

	qca8084_phy_sgmii_speed_fixup(phy_addr, link, speed);
	return;
}
#endif /* CONFIG_QCA8084_BYPASS_MODE */

