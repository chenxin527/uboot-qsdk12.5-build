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
#include "ipq_qca8081.h"
#include "ipq_qca8084.h"
#include "ipq_qca8084_clk.h"
#include "ipq_qca8084_interface_ctrl.h"
#include <asm/global_data.h>
#include <linux/compat.h>
#include <fdtdec.h>
#include <malloc.h>

DECLARE_GLOBAL_DATA_PTR;
#ifdef DEBUG
#define pr_debug(fmt, args...) printf(fmt, ##args);
#else
#define pr_debug(fmt, args...)
#endif

extern uint32_t ipq_mii_read(uint32_t reg);
extern void ipq_mii_write(uint32_t reg, uint32_t val);
extern int ipq_mdio_read(int mii_id,
		int regnum, ushort *data);
extern int ipq_mdio_write(int mii_id,
		int regnum, u16 data);
extern void qca8084_gcc_clock_init(qca8084_work_mode_t clk_mode, u32 pbmp);
extern void qca8084_port_speed_clock_set(uint32_t qca8084_port_id,
						fal_port_speed_t speed);
extern void qca8084_port_clk_en_set(uint32_t qca8084_port_id, uint8_t mask,
						uint8_t enable);
extern void qca8084_port_clk_reset(uint32_t qca8084_port_id, uint8_t mask);

extern u8 qca8081_phy_get_link_status(u32 dev_id, u32 phy_id);
extern u32 qca8081_phy_get_duplex(u32 dev_id, u32 phy_id, fal_port_duplex_t *duplex);
extern u32 qca8081_phy_get_speed(u32 dev_id, u32 phy_id, fal_port_speed_t *speed);

#ifdef CONFIG_QCA8084_PHY_MODE
extern void qca8084_uniphy_xpcs_autoneg_restart(uint32_t qca8084_port_id);
extern void qca8084_uniphy_xpcs_speed_set(uint32_t qca8084_port_id,
						fal_port_speed_t speed);
extern void qca8084_interface_uqxgmii_mode_set(void);
extern void qca8084_uniphy_uqxgmii_function_reset(uint32_t qca8084_port_id);
#endif /* CONFIG_QCA8084_PHY_MODE */

#ifdef CONFIG_QCA8084_SWT_MODE
extern void qca8084_gcc_port_clk_parent_set(qca8084_work_mode_t clk_mode,
		uint32_t qca8084_port_id);
extern void qca8084_uniphy_sgmii_function_reset(u32 uniphy_index);
extern void qca8084_interface_sgmii_mode_set(u32 uniphy_index, u32
		qca8084_port_id, mac_config_t *config);
extern uint8_t qca8084_uniphy_mode_check(uint32_t uniphy_index,
		qca8084_uniphy_mode_t uniphy_mode);
extern void qca8084_clk_disable(const char *clock_id);
extern void qca8084_clk_reset(const char *clock_id);

bool qca8084_port_txfc_forcemode[QCA8084_MAX_PORTS] = {};
bool qca8084_port_rxfc_forcemode[QCA8084_MAX_PORTS] = {};
#endif /* CONFIG_QCA8084_SWT_MODE */

#ifdef CONFIG_QCA8084_BYPASS_MODE
extern void qca8084_phy_sgmii_mode_set(uint32_t phy_addr, u32 interface_mode,
		u32 link, fal_port_speed_t speed);
#endif /* CONFIG_QCA8084_BYPASS_MODE */

static int qca8084_reg_field_get(u32 reg_addr, u32 bit_offset,
		u32 field_len, u8 value[]);
static int qca8084_reg_field_set(u32 reg_addr, u32 bit_offset,
		u32 field_len, const u8 value[]);

u16 qca8084_phy_reg_read(u32 phy_addr, u32 reg_id)
{
	return ipq_mdio_read(phy_addr, reg_id, NULL);
}

u16 qca8084_phy_reg_write(u32 phy_addr, u32 reg_id, u16 value)
{
	return ipq_mdio_write(phy_addr, reg_id, value);
}

u16 qca8084_phy_mmd_read(u32 phy_addr, u16 mmd_num, u16 reg_id)
{
	uint32_t reg_id_c45 = QCA8084_REG_C45_ADDRESS(mmd_num, reg_id);

	return ipq_mdio_read(phy_addr, reg_id_c45, NULL);
}

u16 qca8084_phy_mmd_write(u32 phy_addr, u16 mmd_num, u16 reg_id, u16 value)
{
	uint32_t reg_id_c45 = QCA8084_REG_C45_ADDRESS(mmd_num, reg_id);

	return ipq_mdio_write(phy_addr, reg_id_c45, value);
}

void qca8084_phy_modify_mii(uint32_t phy_addr, uint32_t mii_reg, uint32_t mask,
			    uint32_t value)
{
	uint16_t phy_data = 0, new_phy_data = 0;

	phy_data = qca8084_phy_reg_read(phy_addr, mii_reg);
	new_phy_data = (phy_data & ~mask) | value;
	qca8084_phy_reg_write(phy_addr, mii_reg, new_phy_data);
	/*check the mii register value*/
	phy_data = qca8084_phy_reg_read(phy_addr, mii_reg);
	pr_debug("phy_addr:0x%x, mii_reg:0x%x, phy_data:0x%x\n",
		phy_addr, mii_reg, phy_data);
}

void qca8084_phy_modify_mmd(uint32_t phy_addr, uint32_t mmd_num,
			    uint32_t mmd_reg, uint32_t mask, uint32_t value)
{
	uint16_t phy_data = 0, new_phy_data = 0;

	phy_data = qca8084_phy_mmd_read(phy_addr, mmd_num, mmd_reg);
	new_phy_data = (phy_data & ~mask) | value;
	qca8084_phy_mmd_write(phy_addr, mmd_num, mmd_reg, new_phy_data);
	/* check the mmd register value */
	phy_data = qca8084_phy_mmd_read(phy_addr, mmd_num, mmd_reg);
	pr_debug("phy_addr:0x%x, mmd_reg:0x%x, phy_data:0x%x\n",
		phy_addr, mmd_reg, phy_data);
}

void qca8084_phy_function_reset(uint32_t phy_id)
{
	uint16_t phy_data = 0;

	phy_data = qca8084_phy_reg_read(phy_id, QCA8084_PHY_FIFO_CONTROL);

	qca8084_phy_reg_write(phy_id, QCA8084_PHY_FIFO_CONTROL,
				phy_data & (~QCA8084_PHY_FIFO_RESET));

	mdelay(50);

	qca8084_phy_reg_write(phy_id, QCA8084_PHY_FIFO_CONTROL,
				phy_data | QCA8084_PHY_FIFO_RESET);
}

/***************************** QCA8084 Pinctrl APIs *************************/
/****************************************************************************
 *
 * 1) PINs default Setting
 *
 ****************************************************************************/
#ifdef IN_PINCTRL_DEF_CONFIG
static u64 pin_configs[] = {
	QCA8084_PIN_CONFIG_OUTPUT_ENABLE,
	QCA8084_PIN_CONFIG_BIAS_PULL_DOWN,
};
#endif

static struct qca8084_pinctrl_setting qca8084_pin_settings[] = {
	/*PINs default MUX Setting*/
	QCA8084_PIN_SETTING_MUX(0,  QCA8084_PIN_FUNC_INTN_WOL),
	QCA8084_PIN_SETTING_MUX(1,  QCA8084_PIN_FUNC_INTN),
	QCA8084_PIN_SETTING_MUX(2,  QCA8084_PIN_FUNC_P0_LED_0),
	QCA8084_PIN_SETTING_MUX(3,  QCA8084_PIN_FUNC_P1_LED_0),
	QCA8084_PIN_SETTING_MUX(4,  QCA8084_PIN_FUNC_P2_LED_0),
	QCA8084_PIN_SETTING_MUX(5,  QCA8084_PIN_FUNC_P3_LED_0),
	QCA8084_PIN_SETTING_MUX(6,  QCA8084_PIN_FUNC_PPS_IN),
	QCA8084_PIN_SETTING_MUX(7,  QCA8084_PIN_FUNC_TOD_IN),
	QCA8084_PIN_SETTING_MUX(8,  QCA8084_PIN_FUNC_RTC_REFCLK_IN),
	QCA8084_PIN_SETTING_MUX(9,  QCA8084_PIN_FUNC_P0_PPS_OUT),
	QCA8084_PIN_SETTING_MUX(10, QCA8084_PIN_FUNC_P1_PPS_OUT),
	QCA8084_PIN_SETTING_MUX(11, QCA8084_PIN_FUNC_P2_PPS_OUT),
	QCA8084_PIN_SETTING_MUX(12, QCA8084_PIN_FUNC_P3_PPS_OUT),
	QCA8084_PIN_SETTING_MUX(13, QCA8084_PIN_FUNC_P0_TOD_OUT),
	QCA8084_PIN_SETTING_MUX(14, QCA8084_PIN_FUNC_P0_CLK125_TDI),
	QCA8084_PIN_SETTING_MUX(15, QCA8084_PIN_FUNC_P0_SYNC_CLKO_PTP),
	QCA8084_PIN_SETTING_MUX(16, QCA8084_PIN_FUNC_P0_LED_1),
	QCA8084_PIN_SETTING_MUX(17, QCA8084_PIN_FUNC_P1_LED_1),
	QCA8084_PIN_SETTING_MUX(18, QCA8084_PIN_FUNC_P2_LED_1),
	QCA8084_PIN_SETTING_MUX(19, QCA8084_PIN_FUNC_P3_LED_1),
	QCA8084_PIN_SETTING_MUX(20, QCA8084_PIN_FUNC_MDC_M),
	QCA8084_PIN_SETTING_MUX(21, QCA8084_PIN_FUNC_MDC_M),

#ifdef IN_PINCTRL_DEF_CONFIG
	/*PINs default Config Setting*/
	QCA8084_PIN_SETTING_CONFIG(0,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(1,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(2,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(3,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(4,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(5,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(6,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(7,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(8,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(9,  pin_configs),
	QCA8084_PIN_SETTING_CONFIG(10, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(11, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(12, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(13, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(14, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(15, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(16, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(17, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(18, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(19, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(20, pin_configs),
	QCA8084_PIN_SETTING_CONFIG(21, pin_configs),
#endif
};

/****************************************************************************
 *
 * 2) PINs Operations
 *
 ****************************************************************************/
int qca8084_gpio_set_bit(u32 pin, u32 value)
{
	int rv = 0;

	QCA8084_REG_FIELD_SET(TLMM_GPIO_IN_OUTN, pin, GPIO_OUTE, (u8 *) (&value));
	pr_debug("[%s] select pin:%d value:%d\n", __func__, pin, value);

	return rv;
}

int qca8084_gpio_get_bit(u32 pin, u32 *data)
{
	int rv = 0;

	QCA8084_REG_FIELD_GET(TLMM_GPIO_IN_OUTN, pin, GPIO_IN, (u8 *) (data));
	pr_debug("[%s] select pin:%d value:%d\n", __func__, pin, *data);

	return rv;
}

int qca8084_gpio_pin_mux_set(u32 pin, u32 func)
{
	int rv = 0;

	pr_debug("[%s] select pin:%d func:%d\n", __func__, pin, func);
	QCA8084_REG_FIELD_SET(TLMM_GPIO_CFGN, pin, FUNC_SEL, (u8 *) (&func));

	return rv;
}

int qca8084_gpio_pin_cfg_set_bias(u32 pin, enum qca8084_pin_config_param bias)
{
	int rv = 0;
	u32 data = 0;

	switch (bias)
	{
		case QCA8084_PIN_CONFIG_BIAS_DISABLE:
			data = QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_DISABLE;
			break;
		case QCA8084_PIN_CONFIG_BIAS_PULL_DOWN:
			data = QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_DOWN;
			break;
		case QCA8084_PIN_CONFIG_BIAS_BUS_HOLD:
			data = QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_BUS_HOLD;
			break;
		case QCA8084_PIN_CONFIG_BIAS_PULL_UP:
			data = QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_UP;
			break;
		default:
			printf("[%s] doesn't support bias:%d\n", __func__, bias);
			return -1;
	}

	QCA8084_REG_FIELD_SET(TLMM_GPIO_CFGN, pin, GPIO_PULL,
			(u8 *) (&data));
	pr_debug("[%s]pin:%d bias:%d", __func__, pin, bias);

	return rv;
}

int qca8084_gpio_pin_cfg_get_bias(u32 pin, enum qca8084_pin_config_param *bias)
{
	int rv = 0;
	u32 data = 0;

	QCA8084_REG_FIELD_GET(TLMM_GPIO_CFGN, pin, GPIO_PULL,
			(u8 *) (&data));
	switch (data)
	{
		case QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_DISABLE:
			*bias = QCA8084_PIN_CONFIG_BIAS_DISABLE;
			break;
		case QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_DOWN:
			*bias = QCA8084_PIN_CONFIG_BIAS_PULL_DOWN;
			break;
		case QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_BUS_HOLD:
			*bias = QCA8084_PIN_CONFIG_BIAS_BUS_HOLD;
			break;
		case QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_UP:
			*bias = QCA8084_PIN_CONFIG_BIAS_PULL_UP;
			break;
		default:
			printf("[%s] doesn't support bias:%d\n", __func__, data);
			return -1;
	}
	pr_debug("[%s]pin:%d bias:%d", __func__, pin, *bias);

	return rv;
}

int qca8084_gpio_pin_cfg_set_drvs(u32 pin, u32 drvs)
{
	int rv = 0;

	if((drvs < QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_2_MA) ||
			(drvs > QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_16_MA)) {
		printf("[%s] doesn't support drvs:%d\n", __func__, drvs);
		return -1;
	}

	QCA8084_REG_FIELD_SET(TLMM_GPIO_CFGN, pin, DRV_STRENGTH,
			(u8 *) (&drvs));
	pr_debug("[%s]%d", __func__, pin);

	return rv;
}

int qca8084_gpio_pin_cfg_get_drvs(u32 pin, u32 *drvs)
{
	int rv = 0;

	QCA8084_REG_FIELD_GET(TLMM_GPIO_CFGN, pin, DRV_STRENGTH,
			(u8 *) (drvs));
	pr_debug("[%s]%d", __func__, pin);

	return rv;
}

int qca8084_gpio_pin_cfg_set_oe(u32 pin, bool oe)
{
	int rv = 0;

	pr_debug("[%s]%d oe:%d", __func__, pin, oe);

	QCA8084_REG_FIELD_SET(TLMM_GPIO_CFGN, pin, GPIO_OEA,
			(u8 *) (&oe));

	return rv;
}

int qca8084_gpio_pin_cfg_get_oe(u32 pin, bool *oe)
{
	int rv = 0;
	u32 data = 0;

	QCA8084_REG_FIELD_GET(TLMM_GPIO_CFGN, pin, GPIO_OEA,
			(u8 *) (&data));
	*oe = data ? true : false;

	pr_debug("[%s]%d oe:%d", __func__, pin, *oe);

	return rv;
}

static enum qca8084_pin_config_param pinconf_to_config_param(unsigned long config)
{
	return (enum qca8084_pin_config_param) (config & 0xffUL);
}

static u32 pinconf_to_config_argument(unsigned long config)
{
	return (u32) ((config >> 8) & 0xffffffUL);
}

static int qca8084_gpio_pin_cfg_set(u32 pin,
		u64 *configs, u32 num_configs)
{
	enum qca8084_pin_config_param param;
	u32 i, arg;
	int rv = 0;

	for (i = 0; i < num_configs; i++) {
		param = pinconf_to_config_param(configs[i]);
		arg = pinconf_to_config_argument(configs[i]);

		switch (param) {
			case QCA8084_PIN_CONFIG_BIAS_BUS_HOLD:
			case QCA8084_PIN_CONFIG_BIAS_DISABLE:
			case QCA8084_PIN_CONFIG_BIAS_PULL_DOWN:
			case QCA8084_PIN_CONFIG_BIAS_PULL_UP:
				rv = qca8084_gpio_pin_cfg_set_bias(pin, param);
				break;

			case QCA8084_PIN_CONFIG_DRIVE_STRENGTH:
				rv = qca8084_gpio_pin_cfg_set_drvs(pin, arg);
				break;

			case QCA8084_PIN_CONFIG_OUTPUT:
				rv = qca8084_gpio_pin_cfg_set_oe(pin, true);
				rv = qca8084_gpio_set_bit(pin, arg);
				break;

			case QCA8084_PIN_CONFIG_INPUT_ENABLE:
				rv = qca8084_gpio_pin_cfg_set_oe(pin, false);
				break;

			case QCA8084_PIN_CONFIG_OUTPUT_ENABLE:
				rv = qca8084_gpio_pin_cfg_set_oe(pin, true);
				break;

			default:
				printf("%s %d doesn't support:%d \n", __func__, __LINE__, param);
				return -1;
		}
	}

	return rv;
}


/****************************************************************************
 *
 * 3) PINs Init
 *
 ****************************************************************************/
int qca8084_pinctrl_clk_gate_set(bool gate_en)
{
	int rv = 0;

	QCA8084_REG_FIELD_SET(TLMM_CLK_GATE_EN, 0, AHB_HCLK_EN,
			(u8 *) (&gate_en));
	QCA8084_REG_FIELD_SET(TLMM_CLK_GATE_EN, 0, SUMMARY_INTR_EN,
			(u8 *) (&gate_en));
	QCA8084_REG_FIELD_SET(TLMM_CLK_GATE_EN, 0, CRIF_READ_EN,
			(u8 *) (&gate_en));

	pr_debug("[%s] gate_en:%d", __func__, gate_en);

	return rv;
}

static int qca8084_pinctrl_rev_check(void)
{
	int rv = 0;
	u32 version_id = 0, mfg_id = 0, start_bit = 0;

	QCA8084_REG_FIELD_GET(TLMM_HW_REVISION_NUMBER, 0, VERSION_ID,
			(u8 *) (&version_id));
	QCA8084_REG_FIELD_GET(TLMM_HW_REVISION_NUMBER, 0, MFG_ID,
			(u8 *) (&mfg_id));
	QCA8084_REG_FIELD_GET(TLMM_HW_REVISION_NUMBER, 0, START_BIT,
			(u8 *) (&start_bit));

	pr_debug("[%s] version_id:0x%x mfg_id:0x%x start_bit:0x%x",
			__func__, version_id, mfg_id, start_bit);

	if((version_id == 0x0) && (mfg_id == 0x70) && (start_bit == 0x1)) {
		pr_debug(" Pinctrl Version Check Pass\n");
	} else {
		printf("Error: Pinctrl Version Check Fail\n");
		rv = -1;
	}

	return rv;
}

static int qca8084_pinctrl_hw_init(void)
{
	int rv = 0;

	rv = qca8084_pinctrl_clk_gate_set(true);
	rv = qca8084_pinctrl_rev_check();

	return rv;
}

static int qca8084_pinctrl_setting_init(const struct qca8084_pinctrl_setting *pin_settings,
		u32 num_setting)
{
	int rv = 0;
	u32 i;

	for(i = 0; i < num_setting; i++) {
		const struct qca8084_pinctrl_setting *setting = &pin_settings[i];
		if (setting->type == QCA8084_PIN_MAP_TYPE_MUX_GROUP) {
			rv = qca8084_gpio_pin_mux_set(setting->data.mux.pin, setting->data.mux.func);

		} else if (setting->type == QCA8084_PIN_MAP_TYPE_CONFIGS_PIN) {
			rv = qca8084_gpio_pin_cfg_set(setting->data.configs.pin,
					setting->data.configs.configs,
					setting->data.configs.num_configs);
		}
	}

	return rv;
}

int ipq_qca8084_pinctrl_init(void)
{
	qca8084_pinctrl_hw_init();
	qca8084_pinctrl_setting_init(qca8084_pin_settings, ARRAY_SIZE(qca8084_pin_settings));
	return 0;
}

void qca8084_phy_reset(u32 phy_addr)
{
	u16 phy_data;

	phy_data = qca8084_phy_reg_read(phy_addr, QCA8084_PHY_CONTROL);
	qca8084_phy_reg_write(phy_addr, QCA8084_PHY_CONTROL,
				 phy_data | QCA8084_CTRL_SOFTWARE_RESET);
}

#ifdef CONFIG_QCA8084_PHY_MODE
void qca8084_phy_ipg_config(uint32_t phy_id, fal_port_speed_t speed)
{
	uint16_t phy_data = 0;

	phy_data = qca8084_phy_mmd_read(phy_id, QCA8084_PHY_MMD7_NUM,
					QCA8084_PHY_MMD7_IPG_10_11_ENABLE);

	phy_data &= ~QCA8084_PHY_MMD7_IPG_11_EN;

	/*If speed is 1G, enable 11 ipg tuning*/
	pr_debug("if speed is 1G, enable 11 ipg tuning\n");
	if (speed == FAL_SPEED_1000)
		phy_data |= QCA8084_PHY_MMD7_IPG_11_EN;

	qca8084_phy_mmd_write(phy_id, QCA8084_PHY_MMD7_NUM,
				QCA8084_PHY_MMD7_IPG_10_11_ENABLE, phy_data);
}

void qca8084_phy_uqxgmii_speed_fixup(uint32_t phy_addr, uint32_t qca8084_port_id,
				     uint32_t status, fal_port_speed_t new_speed)
{
	uint32_t port_clock_en = 0;

	/*Restart the auto-neg of uniphy*/
	pr_debug("Restart the auto-neg of uniphy\n");
	qca8084_uniphy_xpcs_autoneg_restart(qca8084_port_id);

	/*set gmii+ clock to uniphy1 and ethphy*/
	pr_debug("set gmii,xgmii clock to uniphy and gmii to ethphy\n");
	qca8084_port_speed_clock_set(qca8084_port_id, new_speed);

	/*set xpcs speed*/
	pr_debug("set xpcs speed\n");
	qca8084_uniphy_xpcs_speed_set(qca8084_port_id, new_speed);

	/*GMII/XGMII clock and ETHPHY GMII clock enable/disable*/
	pr_debug("GMII/XGMII clock and ETHPHY GMII clock enable/disable\n");
	if (status == 0)
		port_clock_en = 1;
	qca8084_port_clk_en_set(qca8084_port_id,
				QCA8084_CLK_TYPE_UNIPHY | QCA8084_CLK_TYPE_EPHY,
				port_clock_en);

	pr_debug("UNIPHY GMII/XGMII interface and ETHPHY GMII interface reset and release\n");
	qca8084_port_clk_reset(qca8084_port_id,
			       QCA8084_CLK_TYPE_UNIPHY | QCA8084_CLK_TYPE_EPHY);

	pr_debug("ipg_tune and xgmii2gmii reset for uniphy and ETHPHY, function reset\n");
	qca8084_uniphy_uqxgmii_function_reset(qca8084_port_id);

	/*do ethphy function reset: PHY_FIFO_RESET*/
	pr_debug("do ethphy function reset\n");
	qca8084_phy_function_reset(phy_addr);

	/*change IPG from 10 to 11 for 1G speed*/
	qca8084_phy_ipg_config(phy_addr, new_speed);
}

void qca8084_phy_interface_mode_set(void)
{
	pr_debug("Configure QCA8084 as PORT_UQXGMII..\n");
	/*the work mode is PORT_UQXGMII in default*/
	qca8084_interface_uqxgmii_mode_set();

	/*init clock for PORT_UQXGMII*/
	qca8084_gcc_clock_init(QCA8084_PHY_UQXGMII_MODE, 0);

	/*init pinctrl for phy mode to be added later*/
}
#endif /* CONFIG_QCA8084_PHY_MODE */

void qca8084_cdt_thresh_init(u32 phy_id)
{
	qca8084_phy_mmd_write(phy_id, QCA8084_PHY_MMD3_NUM,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL3,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL3_VAL);
	qca8084_phy_mmd_write(phy_id, QCA8084_PHY_MMD3_NUM,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL4,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL4_VAL);
	qca8084_phy_mmd_write(phy_id, QCA8084_PHY_MMD3_NUM,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL5,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL5_VAL);
	qca8084_phy_mmd_write(phy_id, QCA8084_PHY_MMD3_NUM,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL6,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL6_VAL);
	qca8084_phy_mmd_write(phy_id, QCA8084_PHY_MMD3_NUM,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL7,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL7_VAL);
	qca8084_phy_mmd_write(phy_id, QCA8084_PHY_MMD3_NUM,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL9,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL9_VAL);
	qca8084_phy_mmd_write(phy_id, QCA8084_PHY_MMD3_NUM,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL13,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL13_VAL);
	qca8084_phy_mmd_write(phy_id, QCA8084_PHY_MMD3_NUM,
				QCA8084_PHY_MMD3_CDT_THRESH_CTRL14,
				QCA8084_PHY_MMD3_NEAR_ECHO_THRESH_VAL);
}

void qca8084_phy_modify_debug(u32 phy_addr, u32 debug_reg,
				u32 mask, u32 value)
{
	u16 phy_data = 0, new_phy_data = 0;

	qca8084_phy_reg_write(phy_addr, QCA8084_DEBUG_PORT_ADDRESS, debug_reg);
	phy_data = qca8084_phy_reg_read(phy_addr, QCA8084_DEBUG_PORT_DATA);
	if (phy_data == PHY_INVALID_DATA)
		pr_debug("qca8084_phy_reg_read failed\n");

	new_phy_data = (phy_data & ~mask) | value;
	qca8084_phy_reg_write(phy_addr, QCA8084_DEBUG_PORT_ADDRESS, debug_reg);
	qca8084_phy_reg_write(phy_addr, QCA8084_DEBUG_PORT_DATA, new_phy_data);

	/* check debug register value */
	qca8084_phy_reg_write(phy_addr, QCA8084_DEBUG_PORT_ADDRESS, debug_reg);
	phy_data = qca8084_phy_reg_read(phy_addr, QCA8084_DEBUG_PORT_DATA);
	pr_debug("phy_addr:0x%x, debug_reg:0x%x, phy_data:0x%x\n",
		phy_addr, debug_reg, phy_data);
}

void qca8084_phy_adc_edge_set(u32 phy_addr, u32 adc_edge)
{
	qca8084_phy_modify_debug(phy_addr,
		QCA8084_PHY_DEBUG_ANA_INTERFACE_CLK_SEL, 0xf0, adc_edge);
	qca8084_phy_reset(phy_addr);
}

void ipq_qca8084_phy_hw_init(struct phy_ops **ops, u32 phy_addr)
{
#ifdef DEBUG
	u16 phy_data;
#endif
	struct phy_ops *qca8084_ops;

	qca8084_ops = (struct phy_ops *)malloc(sizeof(struct phy_ops));
	if (!qca8084_ops) {
		pr_debug("Error allocating memory for phy ops\n");
		return;
	}

	/* Note that qca8084 PHY is based on qca8081 PHY and so the following
	 * ops functions required would be re-used from qca8081 */

	qca8084_ops->phy_get_link_status = qca8081_phy_get_link_status;
	qca8084_ops->phy_get_speed = qca8081_phy_get_speed;
	qca8084_ops->phy_get_duplex = qca8081_phy_get_duplex;
	*ops = qca8084_ops;

#ifdef DEBUG
	phy_data = qca8084_phy_reg_read(phy_addr, QCA8081_PHY_ID1);
	printf("PHY ID1: 0x%x\n", phy_data);
	phy_data = qca8084_phy_reg_read(phy_addr, QCA8081_PHY_ID2);
	printf("PHY ID2: 0x%x\n", phy_data);
#endif

	/* adjust CDT threshold */
	qca8084_cdt_thresh_init(phy_addr);

	/* invert ADC clock edge as falling edge to fix link issue */
	qca8084_phy_adc_edge_set(phy_addr, ADC_FALLING);
}

static int qca8084_reg_field_get(u32 reg_addr, u32 bit_offset,
		u32 field_len, u8 value[])
{
	u32 reg_val = ipq_mii_read(reg_addr);

	*((u32 *) value) = SW_REG_2_FIELD(reg_val, bit_offset, field_len);
	return 0;
}

static int qca8084_reg_field_set(u32 reg_addr, u32 bit_offset,
		u32 field_len, const u8 value[])
{
	u32 field_val = *((u32 *) value);
	u32 reg_val = ipq_mii_read(reg_addr);

	SW_REG_SET_BY_FIELD_U32(reg_val, field_val, bit_offset, field_len);

	ipq_mii_write(reg_addr, reg_val);
	return 0;
}

#ifdef CONFIG_QCA8084_SWT_MODE
static void ipq_qca8084_switch_reset(void)
{
	/* Reset switch core */
	qca8084_clk_reset(QCA8084_SWITCH_CORE_CLK);

	/* Reset MAC ports */
	qca8084_clk_reset(QCA8084_MAC0_TX_CLK);
	qca8084_clk_reset(QCA8084_MAC0_RX_CLK);
	qca8084_clk_reset(QCA8084_MAC1_TX_CLK);
	qca8084_clk_reset(QCA8084_MAC1_RX_CLK);
	qca8084_clk_reset(QCA8084_MAC2_TX_CLK);
	qca8084_clk_reset(QCA8084_MAC2_RX_CLK);
	qca8084_clk_reset(QCA8084_MAC3_TX_CLK);
	qca8084_clk_reset(QCA8084_MAC3_RX_CLK);
	qca8084_clk_reset(QCA8084_MAC4_TX_CLK);
	qca8084_clk_reset(QCA8084_MAC4_RX_CLK);
	qca8084_clk_reset(QCA8084_MAC5_TX_CLK);
	qca8084_clk_reset(QCA8084_MAC5_RX_CLK);
	return;
}

static void ipq_qca8084_work_mode_set(qca8084_work_mode_t work_mode)
{
	u32 data = 0;

	data = ipq_mii_read(WORK_MODE_OFFSET);
	data &= ~QCA8084_WORK_MODE_MASK;
	data |= work_mode;

	ipq_mii_write(WORK_MODE_OFFSET, data);
	return;
}

static void ipq_qca8084_work_mode_get(qca8084_work_mode_t *work_mode)
{
	u32 data = 0;

	data = ipq_mii_read(WORK_MODE_OFFSET);
	pr_debug("work mode reg is 0x%x\n", data);

	*work_mode = data & QCA8084_WORK_MODE_MASK;
	return;
}

static int ipq_qca8084_work_mode_init(int mac_mode0, int mac_mode1)
{
	int ret = 0;

	switch (mac_mode0) {
		case EPORT_WRAPPER_SGMII_PLUS:
		case EPORT_WRAPPER_SGMII_CHANNEL0:
			break;
		default:
			/** not supported */
			printf("%s %d Error: Unsupported mac_mode0 \n", __func__, __LINE__);
			return -1;
	}

	if (qca8084_uniphy_mode_check(QCA8084_UNIPHY_SGMII_0, QCA8084_UNIPHY_PHY)){
		pr_debug("%s %d QCA8084 Uniphy 0 is in SGMII Mode \n",
				__func__, __LINE__);
		ipq_qca8084_work_mode_set(QCA8084_SWITCH_BYPASS_PORT5_MODE);
		return ret;
	}

	switch (mac_mode1) {
		case EPORT_WRAPPER_SGMII_PLUS:
		case EPORT_WRAPPER_MAX:
			ipq_qca8084_work_mode_set(QCA8084_SWITCH_MODE);
			break;
		default:
			printf("%s %d Error: Unsupported mac_mode1 \n", __func__, __LINE__);
			return -1;
	}

	return ret;
}

static int chip_ver_get(void)
{
	int ret = 0;
	u8 chip_ver;
	u32 reg_val = ipq_mii_read(0);

	chip_ver = (reg_val & 0xFF00) >> 8;

	/*qca8084_start*/
	switch (chip_ver) {
		case QCA_VER_QCA8084:
			ret = CHIP_QCA8084;
			break;
		default:
			printf("Error: Unsupported chip \n");
			ret = -1;
			break;
	}

	return ret;
}

bool qca8084_port_phy_connected(u32 port_id)
{
	u32 cpu_bmp = 0x1;
	if ((cpu_bmp & BIT(port_id)) || (port_id == PORT0) ||
		(port_id == PORT5))
		return false;

	return true;
}


static void qca8084_port_txmac_status_set(u32 port_id, bool enable)
{
	u32 reg, force, val = 0, tmp;

	QCA8084_REG_ENTRY_GET(PORT_STATUS, port_id, (u8 *) (&reg));

	if (true == enable)
	{
		val = 1;
	}
	else if (false == enable)
	{
		val = 0;
	}
	tmp = reg;

	/* for those ports without PHY device we set MAC register */
	if (false == qca8084_port_phy_connected(port_id))
	{
		SW_SET_REG_BY_FIELD(PORT_STATUS, LINK_EN,  0, reg);
		SW_SET_REG_BY_FIELD(PORT_STATUS, TXMAC_EN, val, reg);
	}
	else
	{
		SW_GET_FIELD_BY_REG(PORT_STATUS, LINK_EN,  force, reg);
		if (force)
		{
			/* link isn't in force mode so can't set */
			printf("%s %d Error: SW disable \n", __func__, __LINE__);
			return;
		}
		else
		{
			SW_SET_REG_BY_FIELD(PORT_STATUS, TXMAC_EN, val, reg);
		}
	}

	if (tmp == reg)
		return;

	QCA8084_REG_ENTRY_SET(PORT_STATUS, port_id, (u8 *) (&reg));
	return;
}

static void qca8084_port_rxmac_status_set(u32 port_id, bool enable)
{
	u32 reg = 0, force, val = 0, tmp;

	QCA8084_REG_ENTRY_GET(PORT_STATUS, port_id, (u8 *) (&reg));

	if (true == enable)
	{
		val = 1;
	}
	else if (false == enable)
	{
		val = 0;
	}
	tmp = reg;

	/* for those ports without PHY device we set MAC register */
	if (false == qca8084_port_phy_connected(port_id))
	{
		SW_SET_REG_BY_FIELD(PORT_STATUS, LINK_EN,  0, reg);
		SW_SET_REG_BY_FIELD(PORT_STATUS, RXMAC_EN, val, reg);
	}
	else
	{
		SW_GET_FIELD_BY_REG(PORT_STATUS, LINK_EN,  force, reg);
		if (force)
		{
			/* link isn't in force mode so can't set */
			printf("%s %d Error: SW disable \n", __func__, __LINE__);
			return;
		}
		else
		{
			SW_SET_REG_BY_FIELD(PORT_STATUS, RXMAC_EN, val, reg);
		}
	}
	if (tmp == reg)
		return;
	QCA8084_REG_ENTRY_SET(PORT_STATUS, port_id, (u8 *) (&reg));
	return;
}

static void qca8084_port_rxfc_status_set(u32 port_id, bool enable)
{
	u32 val = 0, reg, tmp;

	if (true == enable)
	{
	    val = 1;
	}
	else if (false == enable)
	{
	    val = 0;
	}

	QCA8084_REG_ENTRY_GET(PORT_STATUS, port_id, (u8 *) (&reg));
	tmp = reg;

	SW_SET_REG_BY_FIELD(PORT_STATUS, RX_FLOW_EN, val, reg);

	if ( tmp == reg)
		return;

	QCA8084_REG_ENTRY_SET(PORT_STATUS, port_id, (u8 *) (&reg));
	return;
}

static void qca8084_port_txfc_status_set(u32 port_id, bool enable)
{
	u32 val, reg = 0, tmp;

	if (true == enable)
	{
	    val = 1;
	}
	else if (false == enable)
	{
	    val = 0;
	}

	QCA8084_REG_ENTRY_GET(PORT_STATUS, port_id, (u8 *) (&reg));
	tmp = reg;

	SW_SET_REG_BY_FIELD(PORT_STATUS, TX_FLOW_EN, val, reg);
	SW_SET_REG_BY_FIELD(PORT_STATUS, TX_HALF_FLOW_EN, val, reg);

	if (tmp == reg)
		return;
	QCA8084_REG_ENTRY_SET(PORT_STATUS, port_id, (u8 *) (&reg));

	return;
}

static void qca8084_port_flowctrl_set(u32 port_id, bool enable)
{
	qca8084_port_txfc_status_set(port_id, enable);
	qca8084_port_rxfc_status_set(port_id, enable);
	return;
}

static void qca8084_port_flowctrl_forcemode_set(u32 port_id, bool enable)
{
	qca8084_port_txfc_forcemode[port_id] = enable;
	qca8084_port_rxfc_forcemode[port_id] = enable;
	return;
}

static void header_type_set(bool enable, u32 type)
{
	u32 reg = 0;

	QCA8084_REG_ENTRY_GET(HEADER_CTL, 0, (u8 *) (&reg));

	if (true == enable)
	{
		if (0xffff < type)
		{
			printf("%s %d Error: Bad param \n", __func__, __LINE__);
			return;
		}
		SW_SET_REG_BY_FIELD(HEADER_CTL, TYPE_LEN, 1, reg);
		SW_SET_REG_BY_FIELD(HEADER_CTL, TYPE_VAL, type, reg);
	}
	else if (false == enable)
	{
		SW_SET_REG_BY_FIELD(HEADER_CTL, TYPE_LEN, 0, reg);
		SW_SET_REG_BY_FIELD(HEADER_CTL, TYPE_VAL, 0, reg);
	}

	QCA8084_REG_ENTRY_SET(HEADER_CTL, 0, (u8 *) (&reg));
	return;
}

static void port_rxhdr_mode_set(u32 port_id, port_header_mode_t mode)
{
	u32 val = 0;
	if (FAL_NO_HEADER_EN == mode)
	{
		val = 0;
	}
	else if (FAL_ONLY_MANAGE_FRAME_EN == mode)
	{
		val = 1;
	}
	else if (FAL_ALL_TYPE_FRAME_EN == mode)
	{
		val = 2;
	}
	else
	{
		printf("%s %d Error: Bad param \n", __func__, __LINE__);
		return;
	}

	QCA8084_REG_FIELD_SET(PORT_HDR_CTL, port_id, RXHDR_MODE,(u8 *) (&val));
	return;
}

static void port_txhdr_mode_set(u32 port_id, port_header_mode_t mode)
{
	u32 val = 0;
	if (FAL_NO_HEADER_EN == mode)
	{
		val = 0;
	}
	else if (FAL_ONLY_MANAGE_FRAME_EN == mode)
	{
		val = 1;
	}
	else if (FAL_ALL_TYPE_FRAME_EN == mode)
	{
		val = 2;
	}
	else
	{
		printf("%s %d Error: Bad param \n", __func__, __LINE__);
		return;
	}

	QCA8084_REG_FIELD_SET(PORT_HDR_CTL, port_id, TXHDR_MODE, (u8 *) (&val));
	return;
}


int qca8084_phy_get_status(u32 phy_id, struct port_phy_status *phy_status)
{
	u16 phy_data;

	phy_data = qca8084_phy_reg_read(phy_id, QCA8084_PHY_SPEC_STATUS);

	/*get phy link status*/
	if (phy_data & QCA8084_STATUS_LINK_PASS) {
		phy_status->link_status = true;
	}
	else {
		phy_status->link_status = false;

		/*when link down, phy speed is set as 10M*/
		phy_status->speed = FAL_SPEED_10;
		return 0;
	}

	/*get phy speed*/
	switch (phy_data & QCA8084_STATUS_SPEED_MASK) {
		case QCA8084_STATUS_SPEED_2500MBS:
			phy_status->speed = FAL_SPEED_2500;
			break;
		case QCA8084_STATUS_SPEED_1000MBS:
			phy_status->speed = FAL_SPEED_1000;
			break;
		case QCA8084_STATUS_SPEED_100MBS:
			phy_status->speed = FAL_SPEED_100;
			break;
		case QCA8084_STATUS_SPEED_10MBS:
			phy_status->speed = FAL_SPEED_10;
			break;
		default:
			return -1;
	}

	/*get phy duplex*/
	if (phy_data & QCA8084_STATUS_FULL_DUPLEX) {
		phy_status->duplex = FAL_FULL_DUPLEX;
	} else {
		phy_status->duplex = FAL_HALF_DUPLEX;
	}

	/* get phy flowctrl resolution status */
	if (phy_data & QCA8084_PHY_RX_FLOWCTRL_STATUS) {
		phy_status->rx_flowctrl = true;
	} else {
		phy_status->rx_flowctrl = false;
	}

	if (phy_data & QCA8084_PHY_TX_FLOWCTRL_STATUS) {
		phy_status->tx_flowctrl = true;
	} else {
		phy_status->tx_flowctrl = false;
	}

	return 0;
}


static void qca8084_port_mac_dupex_set(u32 port_id, u32 duplex)
{
	u32 reg_val = 0, tmp;
	u32 duplex_val;

	QCA8084_REG_ENTRY_GET(PORT_STATUS, port_id, (u8 *) (&reg_val));
	tmp = reg_val;

	if (FAL_HALF_DUPLEX == duplex) {
		duplex_val = QCA8084_PORT_HALF_DUPLEX;
	} else {
		duplex_val = QCA8084_PORT_FULL_DUPLEX;
	}
	SW_SET_REG_BY_FIELD(PORT_STATUS, DUPLEX_MODE, duplex_val, reg_val);

	if (tmp == reg_val)
		return;

	QCA8084_REG_ENTRY_SET(PORT_STATUS, port_id, (u8 *) (&reg_val));
	return;
}

static void qca8084_port_duplex_set(u32 port_id, fal_port_duplex_t duplex,
		phy_info_t * phy_info)
{
	/* for those ports without PHY device we set MAC register */
	if (false == qca8084_port_phy_connected(port_id))
	{
		qca8084_port_mac_dupex_set(port_id, duplex);
	}
	else
	{
		printf("%s %d Error: Duplex/Speed set for QCA8084 PORT1-4"
				"is not implemented \n", __func__, __LINE__);
	}
	return;
}

static void qca8084_port_mac_speed_set(u32 port_id, u32 speed)
{
	u32 reg_val = 0, tmp;
	u32 speed_val;

	QCA8084_REG_ENTRY_GET(PORT_STATUS, port_id, (u8 *) (&reg_val));
	tmp = reg_val;

	if (FAL_SPEED_10 == speed) {
		speed_val = QCA8084_PORT_SPEED_10M;
	} else if (FAL_SPEED_100 == speed) {
		speed_val = QCA8084_PORT_SPEED_100M;
	} else if (FAL_SPEED_1000 == speed) {
		speed_val = QCA8084_PORT_SPEED_1000M;
	} else if (FAL_SPEED_2500 == speed) {
		speed_val = QCA8084_PORT_SPEED_2500M;
	} else {
		printf("%s %d Bad param \n",__func__, __LINE__);
		return;
	}
	SW_SET_REG_BY_FIELD(PORT_STATUS, SPEED_MODE, speed_val, reg_val);

	if (tmp == reg_val)
		return;

	QCA8084_REG_ENTRY_SET(PORT_STATUS, port_id, (u8 *) (&reg_val));
	return;
}

static void qca8084_port_speed_set(u32 port_id, fal_port_speed_t speed,
		phy_info_t * phy_info)
{
	/* for those ports without PHY device we set MAC register */
	if (false == qca8084_port_phy_connected(port_id))
	{
		qca8084_port_mac_speed_set(port_id, speed);
	}
	else
	{
		printf("%s %d Error: Duplex/Speed set for QCA8084 PORT1-4"
				"is not implemented \n", __func__, __LINE__);
	}
	return;
}

static int _qca8084_interface_mode_init(u32 port_id, u32 mac_mode,
		phy_info_t * phy_info)
{
	u32 uniphy_index = 0;
	mac_config_t config;
	u32 force_speed = FAL_SPEED_BUTT;
	qca8084_work_mode_t work_mode = QCA8084_SWITCH_MODE;

	if (phy_info->forced_speed) {
		force_speed = phy_info->forced_speed;

		qca8084_port_speed_set(port_id, force_speed, phy_info);

		qca8084_port_duplex_set(port_id, FAL_FULL_DUPLEX, phy_info);

		/* The clock parent need to be configured before initializing
		 * the interface mode. */
		ipq_qca8084_work_mode_get(&work_mode);
		qca8084_gcc_port_clk_parent_set(work_mode, port_id);
	}


	if(mac_mode == EPORT_WRAPPER_SGMII_PLUS)
		config.mac_mode = QCA8084_MAC_MODE_SGMII_PLUS;
	else if (mac_mode == EPORT_WRAPPER_SGMII_CHANNEL0)
		config.mac_mode = QCA8084_MAC_MODE_SGMII;
	else if (mac_mode == EPORT_WRAPPER_MAX)
		config.mac_mode = QCA8084_MAC_MODE_MAX;
	else {
		printf("%s %d Unsupported mac mode \n", __func__, __LINE__);
		return -1;
	}

	/*get uniphy index*/
	if(port_id == PORT0)
		uniphy_index = QCA8084_UNIPHY_SGMII_1;
	else if(port_id == PORT5)
		uniphy_index = QCA8084_UNIPHY_SGMII_0;
	else {
		printf("%s %d Unsupported mac_mode \n", __func__, __LINE__);
		return -1;
	}

	config.clock_mode = QCA8084_INTERFACE_CLOCK_MAC_MODE;
	config.auto_neg = !(phy_info->forced_speed);
	config.force_speed = force_speed;


	if (port_id == PORT5) {
		if (qca8084_uniphy_mode_check(QCA8084_UNIPHY_SGMII_0, QCA8084_UNIPHY_PHY))
			pr_debug("%s %d QCA8084 Uniphy 0 is in SGMII Mode \n",
					__func__, __LINE__);
		else {
			if (config.mac_mode == QCA8084_MAC_MODE_MAX) {
				pr_debug("%s %d QCA8084 Port 5 clk disable \n",
						__func__, __LINE__);
				qca8084_clk_disable(QCA8084_SRDS0_SYS_CLK);
			}
		}
	} else {
		qca8084_interface_sgmii_mode_set(uniphy_index, port_id, &config);

		/*do sgmii function reset*/
		pr_debug("ipg_tune reset and function reset\n");
		qca8084_uniphy_sgmii_function_reset(uniphy_index);
	}
	return 0;
}

static int ipq_qca8084_interface_mode_init(u32 mac_mode0, u32 mac_mode1, phy_info_t * phy_info[])
{
	int ret = 0;

	ret = _qca8084_interface_mode_init(PORT0, mac_mode0, phy_info[PORT0]);
	if (ret < 0)
		return ret;

	ret = _qca8084_interface_mode_init(PORT5, mac_mode1, phy_info[PORT5]);
	if (ret < 0)
		return ret;

	if (phy_info[PORT0]->forced_speed) {
		qca8084_port_txmac_status_set(PORT0, true);
		qca8084_port_rxmac_status_set(PORT0, true);
	}

	if (phy_info[PORT5]->forced_speed) {
		qca8084_port_txmac_status_set(PORT5, true);
		qca8084_port_rxmac_status_set(PORT5, true);
	}
	return ret;
}


void port_link_update(u32 port_id, struct port_phy_status phy_status)
{
	/* configure gcc uniphy and mac speed frequency*/
	qca8084_port_speed_clock_set(port_id, phy_status.speed);

	/* configure mac speed and duplex */
	qca8084_port_mac_speed_set(port_id, phy_status.speed);
	qca8084_port_mac_dupex_set(port_id, phy_status.duplex);
	pr_debug("mht port %d link %d update speed %d duplex %d\n",
			port_id, phy_status.speed,
			phy_status.speed, phy_status.duplex);
	if (phy_status.link_status == PORT_LINK_UP)
	{
		/* sync mac flowctrl */
		if (qca8084_port_txfc_forcemode[port_id] != true) {
			qca8084_port_txfc_status_set(port_id, phy_status.tx_flowctrl);
			pr_debug("mht port %d link up update txfc %d\n",
			port_id, phy_status.tx_flowctrl);
		}
		if (qca8084_port_rxfc_forcemode[port_id] != true) {
			qca8084_port_rxfc_status_set(port_id, phy_status.rx_flowctrl);
			pr_debug("mht port %d link up update rxfc %d\n",
			port_id, phy_status.rx_flowctrl);
		}
		if (port_id != PORT5) {
			/* enable eth phy clock */
			qca8084_port_clk_en_set(port_id, QCA8084_CLK_TYPE_EPHY, true);
		}
	}
	if (port_id != PORT5) {
		if (phy_status.link_status == PORT_LINK_DOWN) {
			/* disable eth phy clock */
			qca8084_port_clk_en_set(port_id, QCA8084_CLK_TYPE_EPHY, false);
		}
		/* reset eth phy clock */
		qca8084_port_clk_reset(port_id, QCA8084_CLK_TYPE_EPHY);
		/* reset eth phy fifo */
		qca8084_phy_function_reset(port_id);
	}
	return;
}

static void port_3az_status_set(u32 port_id, bool enable)
{
	u32 reg = 0, field, offset, device_id, reverse = 0;
	u32 eee_mask = 0;

	QCA8084_REG_ENTRY_GET(MASK_CTL, 0, (u8 *) (&reg));

	SW_GET_FIELD_BY_REG(MASK_CTL, DEVICE_ID, device_id, reg);
	switch (device_id) {
		case QCA_VER_QCA8084:
			eee_mask = 3;
			reverse = 0;
			break;
		default:
			printf("%s %d Unsupported DEV_ID \n", __func__, __LINE__);
			return;
	}

	QCA8084_REG_ENTRY_GET(EEE_CTL, 0, (u8 *) (&reg));

	if (true == enable)
	{
		field  = eee_mask;
	}
	else if (false == enable)
	{
		field  = 0;
	}

	if (reverse)
	{
		field = (~field) & eee_mask;
	}

	offset = (port_id - 1) * ISISC_LPI_BIT_STEP + ISISC_LPI_PORT1_OFFSET;
	reg &= (~(eee_mask << offset));
	reg |= (field << offset);

	QCA8084_REG_ENTRY_SET(EEE_CTL, 0, (u8 *) (&reg));
	return;
}

static void qos_port_tx_buf_nr_set(u32 port_id, u32 * number)
{
	u32 val = 0;
	if (ISISC_QOS_PORT_TX_BUFFER_MAX < *number)
	{
		printf("%s %d Bad param \n", __func__, __LINE__);
		return;
	}

	val = *number / ISISC_QOS_HOL_STEP;
	*number = val << ISISC_QOS_HOL_MOD;
	QCA8084_REG_FIELD_SET(PORT_HOL_CTL0, port_id, PORT_DESC_NR,
			(u8 *) (&val));
	return;
}

static void qos_port_rx_buf_nr_set(u32 port_id, u32 * number)
{
	u32 val = 0;
	if (ISISC_QOS_PORT_RX_BUFFER_MAX < *number)
	{
		printf("%s %d Bad param \n", __func__, __LINE__);
		return;
	}

	val = *number / ISISC_QOS_HOL_STEP;
	*number = val << ISISC_QOS_HOL_MOD;
	QCA8084_REG_FIELD_SET(PORT_HOL_CTL1, port_id, PORT_IN_DESC_EN,
			(u8 *) (&val));
	return;
}

void qca_switch_init(u32 port_bmp, u32 cpu_bmp, phy_info_t * phy_info[])
{
	u32 port_hol_ctrl[2] = {0};
	int i = 0;
	u32 temp;

	port_bmp |= cpu_bmp;
	while (port_bmp) {
		pr_debug("configuring port: %d \n", i);
		if (port_bmp & 1) {
			temp = 0;
			QCA8084_REG_FIELD_GET(FORWARD_CTL1, 0, BC_FLOOD_DP, (u8 *) (&temp));
			temp |= (0x1 << i);
			QCA8084_REG_FIELD_SET(FORWARD_CTL1, 0, BC_FLOOD_DP, (u8 *) (&temp));

			qca8084_port_txmac_status_set(i, false);
			qca8084_port_rxmac_status_set(i, false);

			if (cpu_bmp & BIT(i)) {
				qca8084_port_flowctrl_set(i, false);
				qca8084_port_flowctrl_forcemode_set(i, true);

				header_type_set(true, QCA8084_HEADER_TYPE_VAL);
				port_rxhdr_mode_set(i, FAL_ONLY_MANAGE_FRAME_EN);
				port_txhdr_mode_set(i, FAL_NO_HEADER_EN);

				/* port tx buf number */
				port_hol_ctrl[0] = 600;
				/* port rx buf number */
				port_hol_ctrl[1] = 48;
			} else {
				qca8084_port_flowctrl_set(i, true);
				qca8084_port_flowctrl_forcemode_set(i, false);
			}

			port_3az_status_set(i, false);

			temp=1;
			QCA8084_REG_FIELD_SET(PORT_HOL_CTL1, i, PORT_RED_EN, (u8 *) (&temp));

			qos_port_tx_buf_nr_set(i, &port_hol_ctrl[0]);
			qos_port_rx_buf_nr_set(i, &port_hol_ctrl[1]);

		}
		port_bmp >>=1;
		i++;
	}
	return;
}

int ipq_qca8084_link_update(phy_info_t * phy_info[])
{
	struct port_phy_status phy_status = {0};
	int rv, port_id, status = 1;

	printf("QCA8084-switch status:\n");
	for (int i=PORT1; i<PORT5; i++) {
		port_id = phy_info[i]->phy_address;
		if (phy_info[i]->phy_type == UNUSED_PHY_TYPE)
			continue;

		rv = qca8084_phy_get_status(port_id, &phy_status);
		if (rv < 0) {
			printf("%s %d failed get phy status of idx %d \n",
				__func__, __LINE__, port_id);
			return status;
		}

		printf("PORT%d %s Speed :%d %s duplex\n", port_id,
			(phy_status.link_status?"Up":"Down"),
			phy_status.speed, (phy_status.duplex?"Full":"Half"));

		if (phy_status.link_status == PORT_LINK_DOWN) {
			/* enable mac rx function */
			qca8084_port_rxmac_status_set(port_id, false);
			/* enable mac tx function */
			qca8084_port_txmac_status_set(port_id, false);
			/* update gcc, mac speed, mac duplex and phy stauts */
			port_link_update(port_id, phy_status);
		}

		if (phy_status.link_status == PORT_LINK_UP) {
			/* update gcc, mac speed, mac duplex and phy stauts */
			port_link_update(port_id, phy_status);
			/* enable mac tx function */
			qca8084_port_txmac_status_set(port_id, true);
			/* enable mac rx function */
			qca8084_port_rxmac_status_set(port_id, true);

			status = 0;
		}
	}

	return status;
}

int ipq_qca8084_hw_init(phy_info_t * phy_info[])
{
	int ret = 0;
	int mode0 = -1, mode1 = -1, node = -1;
	qca8084_work_mode_t work_mode;
	u32 port_bmp, cpu_bmp;

	int chip_type = chip_ver_get();

	if (chip_type != CHIP_QCA8084) {
		printf("Error: Unsupported chip_type \n");
		return -1;
	}

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch/qca8084_swt_info");
	mode0 = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode0", -1);
	if (mode0 < 0) {
		printf("Error: switch_mac_mode0 not specified in dts\n");
		return mode0;
	}

	mode1 = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode1", -1);
	if (mode1 < 0) {
		printf("Error: switch_mac_mode1 not specified in dts\n");
		return mode1;
	}

	port_bmp = fdtdec_get_uint(gd->fdt_blob, node, "switch_lan_bmp", 0x3e);

	cpu_bmp = fdtdec_get_uint(gd->fdt_blob, node, "switch_cpu_bmp", 0x1);

	ipq_qca8084_switch_reset();

	ret = ipq_qca8084_work_mode_init(mode0, mode1);
	if (ret < 0)
		return ret;

	qca_switch_init(port_bmp, cpu_bmp, phy_info);

	ret = ipq_qca8084_interface_mode_init(mode0, mode1, phy_info);
	if (ret < 0)
		return ret;

	port_bmp |= cpu_bmp;

	ipq_qca8084_work_mode_get(&work_mode);
	qca8084_gcc_clock_init(work_mode, port_bmp);

	return ret;
}

void ipq_qca8084_switch_hw_reset(int gpio)
{
	unsigned int *switch_gpio_base =
		(unsigned int *)GPIO_CONFIG_ADDR(gpio);

	writel(0x203, switch_gpio_base);
	writel(0x0, GPIO_IN_OUT_ADDR(gpio));
	mdelay(500);
	writel(0x2, GPIO_IN_OUT_ADDR(gpio));
}
#endif /* CONFIG_QCA8084_SWT_MODE */

#ifdef CONFIG_QCA8084_BYPASS_MODE
void qca8084_phy_sgmii_speed_fixup (u32 phy_addr, u32 link,
		fal_port_speed_t new_speed)
{
	/*disable ethphy3 and uniphy0 clock*/
	pr_debug("disable ethphy3 and uniphy0 clock\n");
	qca8084_port_clk_en_set(PORT4, QCA8084_CLK_TYPE_EPHY, false);
	qca8084_port_clk_en_set(PORT5, QCA8084_CLK_TYPE_UNIPHY, false);

	/*set gmii clock for ethphy3 and uniphy0*/
	pr_debug("set speed clock for eth3 and uniphy0\n");
	qca8084_port_speed_clock_set(PORT4, new_speed);

	/*uniphy and ethphy gmii clock enable/disable*/
	pr_debug("uniphy and ethphy GMII clock enable/disable\n");
	if(!link)
	{
		pr_debug("enable ethphy3 and uniphy0 clock\n");
		qca8084_port_clk_en_set(PORT4, QCA8084_CLK_TYPE_EPHY, true);
		qca8084_port_clk_en_set(PORT5, QCA8084_CLK_TYPE_UNIPHY, true);
	}
	/*uniphy and ethphy gmii reset and release*/
	pr_debug("uniphy and ethphy GMII interface reset and release\n");
	qca8084_port_clk_reset(PORT4, QCA8084_CLK_TYPE_EPHY);
	qca8084_port_clk_reset(PORT5, QCA8084_CLK_TYPE_UNIPHY);

	/*uniphy and ethphy ipg_tune reset, function reset*/
	pr_debug("uniphy and ethphy ipg_tune reset, function reset\n");
	qca8084_uniphy_sgmii_function_reset(QCA8084_UNIPHY_SGMII_0);

	/*do ethphy function reset*/
	pr_debug("do ethphy function reset\n");
	qca8084_phy_function_reset(phy_addr);
	return;
}

void qca8084_bypass_interface_mode_set(u32 interface_mode)
{
	ipq_qca8084_work_mode_set(QCA8084_PHY_SGMII_UQXGMII_MODE);
	qca8084_phy_sgmii_mode_set(PORT4, interface_mode, false, FAL_SPEED_1000);

	pr_debug("ethphy3 software reset\n");
	qca8084_phy_reset(PORT4);

	/*init pinctrl for phy mode to be added later*/
}
#endif /* CONFIG_QCA8084_BYPASS_MODE */

