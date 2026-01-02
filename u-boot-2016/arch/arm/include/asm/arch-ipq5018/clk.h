/*
 * Copyright (c) 2015-2016, 2018-2020 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef IPQ5018_CLK_H
#define IPQ5018_CLK_H

#define CLK_ENABLE	0x1

#ifdef CONFIG_IPQ_BT_SUPPORT
#define GCC_BTSS_LPO_CBCR			0x181C004
void enable_btss_lpo_clk(void);
#endif

#endif /*IPQ5018_CLK_H*/
