/*
 * Copyright (c) 2013, 2015-2016 The Linux Foundation. All rights reserved.
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

#ifndef IPQ806X_NAND_H
#define IPQ806X_NAND_H

enum ipq_nand_layout {
	IPQ_NAND_LAYOUT_SBL,
	IPQ_NAND_LAYOUT_LINUX,

	IPQ_NAND_LAYOUT_MAX
};

struct ipq_nand {
	unsigned int qpic_nand_init_config;
	unsigned int ebi2cr_regs;
	unsigned int ebi2nd_regs;
	enum ipq_nand_layout layout;
	int variant;
};

int ipq_nand_init(struct ipq_nand *ipq_nand);

#endif
