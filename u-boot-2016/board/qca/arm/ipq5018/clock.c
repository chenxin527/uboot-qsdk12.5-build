/*
 * Copyright (c) 2015-2016, 2018-2019 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include <common.h>
#include <asm/arch-ipq5018/clk.h>
#include <asm/io.h>
#include <asm/errno.h>

#ifdef CONFIG_IPQ_BT_SUPPORT
void enable_btss_lpo_clk(void)
{
	writel(CLK_ENABLE, GCC_BTSS_LPO_CBCR);
}
#endif
