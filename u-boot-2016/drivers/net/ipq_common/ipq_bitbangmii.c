/*
 * Copyright (c) 2012 - 2013,2016-2017, The Linux Foundation. All rights reserved.
 *
 * Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
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
#include <miiphy.h>
#include <linux/compat.h>
#include <fdtdec.h>

DECLARE_GLOBAL_DATA_PTR;

struct bitbang_nodes {
	int mdio;
	int mdc;
} __attribute__ ((aligned(8)));

#define MAX_MDIO_BUS			2

struct bitbang_nodes ipq_mdio_gpio[MAX_MDIO_BUS];

static int ipq_mii_init(struct bb_miiphy_bus *bus)
{
	struct bitbang_nodes *bb_node = bus->priv;
	struct bitbang_nodes *bb_node_base = &ipq_mdio_gpio[0];
	int gpio_node, i = 0;

	if (bb_node_base == bb_node) {
		gpio_node = fdt_path_offset(gd->fdt_blob,
					"/ess-switch/mdiobitbang0");
		if (gpio_node >= 0)
			qca_gpio_init(gpio_node);

	} else {
		gpio_node = fdt_path_offset(gd->fdt_blob,
					"/ess-switch/mdiobitbang1");
		if (gpio_node >= 0)
			qca_gpio_init(gpio_node);
	}

	for (gpio_node = fdt_first_subnode(gd->fdt_blob, gpio_node);
		gpio_node > 0;
		gpio_node = fdt_next_subnode(gd->fdt_blob, gpio_node), ++i) {

		if (i)
			bb_node->mdio = fdtdec_get_uint(gd->fdt_blob,
					gpio_node, "gpio", 0);
		else
			bb_node->mdc = fdtdec_get_uint(gd->fdt_blob,
					gpio_node, "gpio", 0);
	}

	return 0;
}

static int ipq_mii_mdio_active(struct bb_miiphy_bus *bus)
{
	struct bitbang_nodes *bb_node = bus->priv;
	unsigned int *gpio_base;

	gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(bb_node->mdio);

	writel((readl(gpio_base) | (1 << GPIO_IN_OUT_BIT)), gpio_base);
	gpio_set_value(bb_node->mdio, 1);

	return 0;
}

static int ipq_mii_mdio_tristate(struct bb_miiphy_bus *bus)
{
	struct bitbang_nodes *bb_node = bus->priv;
	unsigned int *gpio_base;

	gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(bb_node->mdio);

	writel((readl(gpio_base) & ~(1 << GPIO_IN_OUT_BIT)), gpio_base);
	gpio_set_value(bb_node->mdio, 0);

	return 0;
}

static int ipq_mii_set_mdio(struct bb_miiphy_bus *bus, int v)
{
	struct bitbang_nodes *bb_node = bus->priv;

	gpio_set_value(bb_node->mdio, v);

	return 0;
}

static int ipq_mii_get_mdio(struct bb_miiphy_bus *bus, int *v)
{
	struct bitbang_nodes *bb_node = bus->priv;

	*v = gpio_get_value(bb_node->mdio);

	return 0;
}

static int ipq_mii_set_mdc(struct bb_miiphy_bus *bus, int v)
{
	struct bitbang_nodes *bb_node = bus->priv;

	gpio_set_value(bb_node->mdc, v);

	return 0;
}

static int ipq_mii_delay(struct bb_miiphy_bus *bus)
{
	ndelay(350);

	return 0;
}

struct bb_miiphy_bus bb_miiphy_buses[] = {
	{
		.name = "MDIO0",
		.init = ipq_mii_init,
		.mdio_active = ipq_mii_mdio_active,
		.mdio_tristate = ipq_mii_mdio_tristate,
		.set_mdio = ipq_mii_set_mdio,
		.get_mdio = ipq_mii_get_mdio,
		.set_mdc = ipq_mii_set_mdc,
		.delay = ipq_mii_delay,
		.priv = &ipq_mdio_gpio[0],
	},

	{
		.name = "MDIO1",
		.init = ipq_mii_init,
		.mdio_active = ipq_mii_mdio_active,
		.mdio_tristate = ipq_mii_mdio_tristate,
		.set_mdio = ipq_mii_set_mdio,
		.get_mdio = ipq_mii_get_mdio,
		.set_mdc = ipq_mii_set_mdc,
		.delay = ipq_mii_delay,
		.priv = &ipq_mdio_gpio[1],
	},

};

int bb_miiphy_buses_num = sizeof(bb_miiphy_buses) /
			  sizeof(bb_miiphy_buses[0]);
