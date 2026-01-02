/*
 * Copyright (c) 2015-2016, 2018 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include <common.h>
#include <asm/io.h>
#include <asm/arch-ipq6018/clk.h>
#include <asm/errno.h>

static void uart_configure_mux(u8 id)
{
	unsigned long cfg_rcgr;

	cfg_rcgr = readl(GCC_BLSP1_UART_APPS_CFG_RCGR(id));
	/* Clear mode, src sel, src div */
	cfg_rcgr &= ~(GCC_UART_CFG_RCGR_MODE_MASK |
			GCC_UART_CFG_RCGR_SRCSEL_MASK |
			GCC_UART_CFG_RCGR_SRCDIV_MASK);

	cfg_rcgr |= ((UART_RCGR_SRC_SEL << GCC_UART_CFG_RCGR_SRCSEL_SHIFT)
			& GCC_UART_CFG_RCGR_SRCSEL_MASK);

	cfg_rcgr |= ((UART_RCGR_SRC_DIV << GCC_UART_CFG_RCGR_SRCDIV_SHIFT)
			& GCC_UART_CFG_RCGR_SRCDIV_MASK);

	cfg_rcgr |= ((UART_RCGR_MODE << GCC_UART_CFG_RCGR_MODE_SHIFT)
			& GCC_UART_CFG_RCGR_MODE_MASK);

	writel(cfg_rcgr, GCC_BLSP1_UART_APPS_CFG_RCGR(id));
}

static int uart_trigger_update(u8 id)
{
	unsigned long cmd_rcgr;
	int timeout = 0;

	cmd_rcgr = readl(GCC_BLSP1_UART_APPS_CMD_RCGR(id));
	cmd_rcgr |= UART_CMD_RCGR_UPDATE;
	writel(cmd_rcgr, GCC_BLSP1_UART_APPS_CMD_RCGR(id));

	while (readl(GCC_BLSP1_UART_APPS_CMD_RCGR(id)) & UART_CMD_RCGR_UPDATE) {
		if (timeout++ >= CLOCK_UPDATE_TIMEOUT_US) {
			printf("Timeout waiting for UART clock update\n");
			return -ETIMEDOUT;
		}
		udelay(1);
	}
	cmd_rcgr = readl(GCC_BLSP1_UART_APPS_CMD_RCGR(id));
	return 0;
}

int uart_clock_config(struct ipq_serial_platdata *plat)
{
	unsigned long cbcr_val;
	int ret;

	uart_configure_mux(plat->port_id);

	writel(plat->m_value, GCC_BLSP1_UART_APPS_M(plat->port_id));
	writel(NOT_N_MINUS_M(plat->n_value, plat->m_value),
				GCC_BLSP1_UART_APPS_N(plat->port_id));
	writel(NOT_2D(plat->d_value), GCC_BLSP1_UART_APPS_D(plat->port_id));

	ret = uart_trigger_update(plat->port_id);
	if (ret)
		return ret;

	cbcr_val = readl(GCC_BLSP1_UART_APPS_CBCR(plat->port_id));
	cbcr_val |= UART_CBCR_CLK_ENABLE;
	writel(cbcr_val, GCC_BLSP1_UART_APPS_CBCR(plat->port_id));
	return 0;
}

