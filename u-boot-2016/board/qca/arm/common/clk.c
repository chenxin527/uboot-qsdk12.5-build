/*
 * Copyright (c) 2015-2016, 2018-2020 The Linux Foundation. All rights reserved.
 *
 * Copyright (c) 2022, Qualcomm Innovation Center, Inc. All rights reserved.
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

#include <common.h>
#include <asm/global_data.h>
#include <asm/io.h>
#include <asm/arch-qca-common/clk.h>
#include <asm/errno.h>
#include <fdtdec.h>

DECLARE_GLOBAL_DATA_PTR;

#ifdef CONFIG_IPQ_I2C
void i2c_clock_config(void)
{
	int cfg, i2c_id;
	int i2c_node;
	const u32 *i2c_base;
	int i;
	char alias[6];

	for (i = 0; i < CONFIG_IPQ_MAX_BLSP_QUPS; i++) {
		memset(alias, 0, 6);
		snprintf(alias, 5, "i2c%d", i);

		i2c_node = fdt_path_offset(gd->fdt_blob, alias);
		if (i2c_node >= 0) {
			i2c_base = fdt_getprop(gd->fdt_blob, i2c_node, "reg", NULL);
			if (i2c_base) {
				i2c_id = I2C_PORT_ID(fdt32_to_cpu(i2c_base[0]));

				/* Configure qup1_i2c_apps_clk_src */
				cfg = (GCC_BLSP1_QUP1_I2C_APPS_CFG_RCGR_SRC_SEL |
						GCC_BLSP1_QUP1_I2C_APPS_CFG_RCGR_SRC_DIV);
				writel(cfg, GCC_BLSP1_QUP_I2C_APPS_CFG_RCGR(i2c_id));

				writel(CMD_UPDATE, GCC_BLSP1_QUP_I2C_APPS_CMD_RCGR(i2c_id));
				mdelay(100);
				writel(ROOT_EN, GCC_BLSP1_QUP_I2C_APPS_CMD_RCGR(i2c_id));

				/* Configure CBCR */
				writel(CLK_ENABLE, GCC_BLSP1_QUP_I2C_APPS_CBCR(i2c_id));
			}
		}
	}
}
#endif

#ifdef CONFIG_QCA_SPI
void spi_clock_init(int spi_id)
{
	int cfg;

	/* Configure qup1_spi_apps_clk_src */
	cfg = (GCC_BLSP_QUP_SPI_SRC_SEL |
		GCC_BLSP_QUP_SPI_SRC_DIV);

	writel(cfg, GCC_BLSP1_QUP_SPI_APPS_CFG_RCGR(spi_id));
	writel(CMD_UPDATE, GCC_BLSP1_QUP_SPI_APPS_CMD_RCGR(spi_id));
	mdelay(100);
	writel(ROOT_EN, GCC_BLSP1_QUP_SPI_APPS_CMD_RCGR(spi_id));

	/* Configure CBCR */
	writel(CLK_ENABLE, GCC_BLSP1_QUP_SPI_APPS_CBCR(spi_id));
}
#endif

#if defined(CONFIG_QPIC_NAND) && defined(CONFIG_QSPI_SERIAL_TRAINING)
__weak void qpic_set_clk_rate(unsigned int clk_rate, int blk_type,
				int req_clk_src_type)
{
	switch (blk_type) {
	case QPIC_IO_MACRO_CLK:
		/* select the clk source for IO_PAD_MACRO
		 * clk source wil be either XO = 24MHz. or GPLL0 = 800MHz.
		 */
		if (req_clk_src_type == XO_CLK_SRC) {
			/* default XO clock will enabled
			 * i.e XO clock = 24MHz.
			 * so div value will 0.
			 * Input clock to IO_MACRO will be divided by 4 by default
			 * by hardware and then taht clock will be go on bus.
			 * i.e 24/4MHz = 6MHz i.e 6MHz will go onto the bus.
			 */
			writel(0x0, GCC_QPIC_IO_MACRO_CFG_RCGR);

		} else if (req_clk_src_type == GPLL0_CLK_SRC) {
			/* selct GPLL0 clock source 800MHz
			 * so 800/4 = 200MHz.
			 * Input clock to IO_MACRO will be divided by 4 by default
			 * by hardware and then that clock will be go on bus.
			 * i.e 200/4MHz = 50MHz i.e 50MHz will go onto the bus.
			 */
			if (clk_rate == IO_MACRO_CLK_320_MHZ)
			       writel(0x104, GCC_QPIC_IO_MACRO_CFG_RCGR);
			else if (clk_rate == IO_MACRO_CLK_266_MHZ)
				writel(0x105, GCC_QPIC_IO_MACRO_CFG_RCGR);
			else if (clk_rate == IO_MACRO_CLK_228_MHZ)
				writel(0x106, GCC_QPIC_IO_MACRO_CFG_RCGR);
			else if (clk_rate == IO_MACRO_CLK_100_MHZ)
				writel(0x10F, GCC_QPIC_IO_MACRO_CFG_RCGR);
			else if (clk_rate == IO_MACRO_CLK_200_MHZ)
				writel(0x107, GCC_QPIC_IO_MACRO_CFG_RCGR);
		} else {
			printf("wrong clk src selection requested.\n");
		}

		/* Enablle update bit to update the new configuration */
		writel((UPDATE_EN | readl(GCC_QPIC_IO_MACRO_CMD_RCGR)),
				GCC_QPIC_IO_MACRO_CMD_RCGR);

		/* Enable the QPIC_IO_MACRO_CLK */
		writel(0x1, GCC_QPIC_IO_MACRO_CBCR);
		break;
	case QPIC_CORE_CLK:
	       /* To DO if needed for QPIC core clock setting */
	       break;
	default:
	       printf("wrong qpic block type\n");
	       break;
	}
}
#endif
