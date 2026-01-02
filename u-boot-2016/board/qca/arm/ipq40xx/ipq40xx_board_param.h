/*
 * Copyright (c) 2015-2017 The Linux Foundation. All rights reserved.
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

#ifndef _IPQ40XX_BOARD_PARAM_H_
#define _IPQ40XX_BOARD_PARAM_H_

#include <asm/arch-qca-common/iomap.h>
#include <asm/arch-qca-common/gpio.h>
#include <linux/sizes.h>
#include "ipq40xx.h"

gpio_func_data_t mmc_ap_dk04[] = {
	{
		.gpio = 23,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_10MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 24,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_10MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 25,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_10MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 26,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_10MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 27,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 28,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_10MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 29,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_10MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 30,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_10MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 31,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_10MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 32,
		.func = 1,
		.pull = GPIO_NO_PULL,
		.drvstr = GPIO_10MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
};


gpio_func_data_t spi_nor_bga[] = {
	{
		.gpio = 12,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 13,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 14,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 15,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
};

gpio_func_data_t nand_gpio_bga[] = {
	{
		.gpio = 52,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 53,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 54,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 55,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 56,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 57,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 58,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 59,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 60,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 61,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 62,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 63,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 64,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 65,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 66,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 67,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 68,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 69,
		.func = 1,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},

};

gpio_func_data_t rgmii_gpio_cfg[] = {
	{
		.gpio = 22,
		.func = 1,	/* RGMMI0 */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 23,
		.func = 2,	/* RGMII1 */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 24,
		.func = 2,	/* RGMII2 */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 25,
		.func = 2,	/* RGMII3 */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 26,
		.func = 2,	/* RGMII RX */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 27,
		.func = 2,	/* RGMII_TXC */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 28,
		.func = 2,	/* RGMII0 */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 29,
		.func = 2,	/* RGMII1 */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 30,
		.func = 2,	/* RGMII2 */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 31,
		.func = 2,	/* RGMII3 */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 32,
		.func = 2,	/* RGMII RX_C */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
	{
		.gpio = 33,
		.func = 1,	/* RGMII TX */
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_16MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_DISABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES0
	},
};

gpio_func_data_t sw_gpio_bga[] = {
	{
		.gpio = 6,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 7,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 47,
		.func = 0,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_ENABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
};

gpio_func_data_t ap_dk04_1_c2_sw_gpio_bga[] = {
	{
		.gpio = 6,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 7,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 67,
		.func = 0,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_ENABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
};

gpio_func_data_t ap_dk06_1_c1_sw_gpio_bga[] = {
	{
		.gpio = 6,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 7,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 19,
		.func = 0,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_ENABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
};

gpio_func_data_t ap_dk07_1_c1_sw_gpio_bga[] = {
	{
		.gpio = 6,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 7,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 41,
		.func = 0,
		.pull = GPIO_PULL_DOWN,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_ENABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
};

gpio_func_data_t db_dk_2_1_sw_gpio_bga[] = {
	{
		.gpio = 6,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 7,
		.func = 1,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
};

gpio_func_data_t sw_gpio_qfn[] = {
	{
		.gpio = 52,
		.func = 2,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 53,
		.func = 2,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 59,
		.func = 0,
		.pull = GPIO_NO_PULL,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_ENABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
};

gpio_func_data_t ap_dk01_1_c2_sw_gpio_qfn[] = {
	{
		.gpio = 52,
		.func = 2,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 53,
		.func = 2,
		.pull = GPIO_PULL_UP,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_DISABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
	{
		.gpio = 62,
		.func = 0,
		.pull = GPIO_NO_PULL,
		.drvstr = GPIO_2MA,
		.oe = GPIO_OE_ENABLE,
		.vm = GPIO_VM_ENABLE,
		.od_en = GPIO_OD_DISABLE,
		.pu_res = GPIO_PULL_RES2
	},
};

gpio_func_data_t uart1_gpio_dk01[] = {
	{
		.gpio = 60,
		.func = 2,
		.pull = GPIO_NO_PULL,
		.oe = GPIO_OE_ENABLE
	},
	{
		.gpio = 61,
		.func = 2,
		.pull = GPIO_NO_PULL,
		.oe = GPIO_OE_ENABLE
	},
};

gpio_func_data_t uart1_gpio_dk04[] = {
	{
		.gpio = 16,
		.func = 1,
		.pull = GPIO_NO_PULL,
		.oe = GPIO_OE_ENABLE
	},
	{
		.gpio = 17,
		.func = 1,
		.pull = GPIO_NO_PULL,
		.oe = GPIO_OE_ENABLE
	},
};

gpio_func_data_t uart2_gpio[] = {
	{
		.gpio = 8,
		.func = 1,
		.pull = GPIO_NO_PULL,
		.oe = GPIO_OE_ENABLE
	},
	{
		.gpio = 9,
		.func = 1,
		.pull = GPIO_NO_PULL,
		.oe = GPIO_OE_ENABLE
	},
};

#ifdef CONFIG_IPQ40XX_I2C
gpio_func_data_t i2c0_gpio[] = {
	{
		.gpio = 20,
		.func = 1,
		.pull = GPIO_NO_PULL,
		.oe = GPIO_OE_ENABLE
	},
	{
		.gpio = 21,
		.func = 1,
		.pull = GPIO_NO_PULL,
		.oe = GPIO_OE_ENABLE
	},
};
#endif

uart_cfg_t uart1_console_uart_dk01 = {
	.uart_dm_base = UART1_DM_BASE,
	.dbg_uart_gpio = uart1_gpio_dk01,
};

uart_cfg_t uart1_console_uart_dk04 = {
	.uart_dm_base = UART1_DM_BASE,
	.dbg_uart_gpio = uart1_gpio_dk04,
};

uart_cfg_t uart2 = {
	.uart_dm_base = UART2_DM_BASE,
	.dbg_uart_gpio = uart2_gpio,
};

#ifdef CONFIG_IPQ40XX_I2C
i2c_cfg_t i2c0 = {
	.i2c_base = I2C0_BASE,
	.i2c_gpio = i2c0_gpio,
};
#endif

#define ipq40xx_edma_cfg(_b, _pn, _p, ...)		\
{							\
	.base		= IPQ40XX_EDMA_CFG_BASE,	\
	.unit		= _b,				\
	.phy		= PHY_INTERFACE_MODE_##_p,	\
	.phy_addr	= {.count = _pn, {__VA_ARGS__}},\
	.phy_name	= "IPQ MDIO"#_b			\
}

#define TLMM_GPIO_OUT_1		0x01200004
#define TLMM_GPIO_OE_1		0x01200084

#define ipq40xx_edma_cfg_invalid()	{ .unit = -1, }
/* Board specific parameter Array */
board_ipq40xx_params_t board_params[] = {
	{
		.machid = MACH_TYPE_IPQ40XX_AP_DK01_1_S1,
		.ddr_size = (128 << 20),
		.console_uart_cfg = &uart1_console_uart_dk01,
		.sw_gpio = ap_dk01_1_c2_sw_gpio_qfn,
		.sw_gpio_count = ARRAY_SIZE(ap_dk01_1_c2_sw_gpio_qfn),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
					0, 1, 2, 3, 4)
		},
#endif
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@4", "config@ap.dk01.1-s1" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_AP_DK01_1_C1,
		.ddr_size = (256 << 20),
		.console_uart_cfg = &uart1_console_uart_dk01,
		.sw_gpio = sw_gpio_qfn,
		.sw_gpio_count = ARRAY_SIZE(sw_gpio_qfn),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
					0, 1, 2, 3, 4)
		},
#endif
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@4", "config@ap.dk01.1-c1" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_AP_DK01_1_C2,
		.ddr_size = (256 << 20),
		.console_uart_cfg = &uart1_console_uart_dk01,
		.sw_gpio = ap_dk01_1_c2_sw_gpio_qfn,
		.sw_gpio_count = ARRAY_SIZE(ap_dk01_1_c2_sw_gpio_qfn),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
					0, 1, 2, 3, 4)
		},
#endif
		.spi_nand_available = 1,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@5", "config@ap.dk01.1-c2" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_AP_DK04_1_C1,
		.ddr_size = (256 << 20),
		//.spi_nor_gpio = spi_nor_bga,
		//.spi_nor_gpio_count = ARRAY_SIZE(spi_nor_bga),
		.nand_gpio = nand_gpio_bga,
		.nand_gpio_count = ARRAY_SIZE(nand_gpio_bga),
		.sw_gpio = sw_gpio_bga,
		.sw_gpio_count = ARRAY_SIZE(sw_gpio_bga),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
					0, 1, 2, 3, 4)
		},
#endif
		//.uart_cfg = &uart2,
		.console_uart_cfg = &uart1_console_uart_dk04,
#ifdef CONFIG_IPQ40XX_I2C
		.i2c_cfg = &i2c0,
#endif
		.mmc_gpio = mmc_ap_dk04,
		.mmc_gpio_count = ARRAY_SIZE(mmc_ap_dk04),
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@1", "config@ap.dk04.1-c1" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_AP_DK04_1_C4,
		.ddr_size = (256 << 20),
		//.spi_nor_gpio = spi_nor_bga,
		//.spi_nor_gpio_count = ARRAY_SIZE(spi_nor_bga),
		.nand_gpio = nand_gpio_bga,
		.nand_gpio_count = ARRAY_SIZE(nand_gpio_bga),
		.sw_gpio = sw_gpio_bga,
		.sw_gpio_count = ARRAY_SIZE(sw_gpio_bga),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
					0, 1, 2, 3, 4)
		},
#endif
		//.uart_cfg = &uart2,
		.console_uart_cfg = &uart1_console_uart_dk04,
#ifdef CONFIG_IPQ40XX_I2C
		.i2c_cfg = &i2c0,
#endif
		.mmc_gpio = mmc_ap_dk04,
		.mmc_gpio_count = ARRAY_SIZE(mmc_ap_dk04),
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@8", "config@ap.dk04.1-c4" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_AP_DK04_1_C2,
		.ddr_size = (256 << 20),
		//.uart_cfg = &uart2,
		.console_uart_cfg = &uart1_console_uart_dk04,
#ifdef CONFIG_IPQ40XX_I2C
		.i2c_cfg = &i2c0,
#endif
		//.spi_nor_gpio = spi_nor_bga,
		//.spi_nor_gpio_count = ARRAY_SIZE(spi_nor_bga),
		.sw_gpio = ap_dk04_1_c2_sw_gpio_bga,
		.sw_gpio_count = ARRAY_SIZE(ap_dk04_1_c2_sw_gpio_bga),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
					0, 1, 2, 3, 4)
		},
#endif
		.mmc_gpio = mmc_ap_dk04,
		.mmc_gpio_count = ARRAY_SIZE(mmc_ap_dk04),
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@2", "config@ap.dk04.1-c2" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_AP_DK04_1_C3,
		.ddr_size = (256 << 20),
		.console_uart_cfg = &uart1_console_uart_dk04,
		//.spi_nor_gpio = spi_nor_bga,
		//.spi_nor_gpio_count = ARRAY_SIZE(spi_nor_bga),
		.nand_gpio = nand_gpio_bga,
		.nand_gpio_count = ARRAY_SIZE(nand_gpio_bga),
		.sw_gpio = sw_gpio_bga,
		.sw_gpio_count = ARRAY_SIZE(sw_gpio_bga),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
					0, 1, 2, 3, 4)
		},
#endif
		.mmc_gpio = mmc_ap_dk04,
		.mmc_gpio_count = ARRAY_SIZE(mmc_ap_dk04),
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@3", "config@ap.dk04.1-c3" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_AP_DK06_1_C1,
		.ddr_size = (256 << 20),
		.console_uart_cfg = &uart1_console_uart_dk04,
		//.spi_nor_gpio = spi_nor_bga,
		//.spi_nor_gpio_count = ARRAY_SIZE(spi_nor_bga),
		.nand_gpio = nand_gpio_bga,
		.nand_gpio_count = ARRAY_SIZE(nand_gpio_bga),
		.sw_gpio = ap_dk06_1_c1_sw_gpio_bga,
		.sw_gpio_count = ARRAY_SIZE(ap_dk06_1_c1_sw_gpio_bga),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
			0, 1, 2, 3, 4)
			},
#endif
		//.mmc_gpio = mmc_ap_dk04,
		//.mmc_gpio_count = ARRAY_SIZE(mmc_ap_dk04),
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@9", "config@ap.dk06.1-c1" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_AP_DK07_1_C1,
		.ddr_size = (512 << 20),
		.console_uart_cfg = &uart1_console_uart_dk04,
		//.spi_nor_gpio = spi_nor_bga,
		//.spi_nor_gpio_count = ARRAY_SIZE(spi_nor_bga),
		.nand_gpio = nand_gpio_bga,
		.nand_gpio_count = ARRAY_SIZE(nand_gpio_bga),
		.sw_gpio = ap_dk07_1_c1_sw_gpio_bga,
		.sw_gpio_count = ARRAY_SIZE(ap_dk07_1_c1_sw_gpio_bga),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
			0, 1, 2, 3, 4)
			},
#endif
		.spi_nand_available = 0,
		.nor_nand_available = 1,
		.dtb_config_name = { "config@10", "config@ap.dk07.1-c1" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_DB_DK01_1_C1,
		.ddr_size = (256 << 20),
		.console_uart_cfg = &uart1_console_uart_dk01,
		.sw_gpio = sw_gpio_qfn,
		.sw_gpio_count = ARRAY_SIZE(sw_gpio_qfn),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, RGMII,
					0, 1, 2, 3, 4)
		},
#endif
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@6", "config@db.dk01.1-c1" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_DB_DK02_1_C1,
		.ddr_size = (256 << 20),
		.console_uart_cfg = &uart1_console_uart_dk04,
		//.spi_nor_gpio = spi_nor_bga,
		//.spi_nor_gpio_count = ARRAY_SIZE(spi_nor_bga),
		.nand_gpio = nand_gpio_bga,
		.nand_gpio_count = ARRAY_SIZE(nand_gpio_bga),
		.sw_gpio = db_dk_2_1_sw_gpio_bga,
		.sw_gpio_count = ARRAY_SIZE(db_dk_2_1_sw_gpio_bga),
		//.rgmii_gpio = rgmii_gpio_cfg,
		//.rgmii_gpio_count = ARRAY_SIZE(rgmii_gpio_cfg),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, RGMII,
					0, 1, 2, 3, 4)
		},
#endif
		//.mmc_gpio = mmc_ap_dk04,
		//.mmc_gpio_count = ARRAY_SIZE(mmc_ap_dk04),
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "config@7", "config@db.dk02.1-c1" },
	},
	{
		.machid = MACH_TYPE_IPQ40XX_TB832,
		.ddr_size = (256 << 20),
		.console_uart_cfg = &uart1_console_uart_dk04,
		.sw_gpio = sw_gpio_bga,
		.sw_gpio_count = ARRAY_SIZE(sw_gpio_bga),
#if 0
		.edma_cfg = {
			ipq40xx_edma_cfg(0, 5, PSGMII,
					0, 1, 2, 3, 4)
		},
#endif
		.spi_nand_available = 0,
		.nor_nand_available = 0,
		.dtb_config_name = { "", "" },
	},
};

#define NUM_IPQ40XX_BOARDS	ARRAY_SIZE(board_params)
#endif /* _IPQ40XX_BOARD_PARAM_H_ */
