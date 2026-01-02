/*
 * Copyright (c) 2016-2017, 2019 The Linux Foundation. All rights reserved.
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

#include <asm/io.h>
#include <common.h>
#include <asm/types.h>
#include <fdtdec.h>
#include <asm/arch-qca-common/gpio.h>

DECLARE_GLOBAL_DATA_PTR;

/***********************************************************
* Function description: configure GPIO functinality
* Arguments :
* struct qca_gpio_config gpio_config - GPIO Configuration bits
*
* Return : None
************************************************************/
void gpio_tlmm_config(struct qca_gpio_config *gpio_config)
{
	unsigned int val = 0;
	val |= gpio_config->pull;
	val |= gpio_config->func << 2;
	val |= gpio_config->drvstr << 6;
	val |= gpio_config->oe << 9;
#ifdef CONFIG_IPQ5018
	val |= gpio_config->od_en << 10;
	val |= gpio_config->sr_en << 11;
	val |= gpio_config->pu_res << 12;
#else
	val |= gpio_config->vm << 11;
	val |= gpio_config->od_en << 12;
	val |= gpio_config->pu_res << 13;
#endif
	unsigned int *addr =
		(unsigned int *)GPIO_CONFIG_ADDR(gpio_config->gpio);
	writel(val, addr);

	/* Output value is only relevant if GPIO has been configured for fixed
	 * output setting - i.e. func == 0
	 */
	if (gpio_config->func == 0) {
		addr = (unsigned int *)GPIO_IN_OUT_ADDR(gpio_config->gpio);
		val = readl(addr);
		val |= gpio_config->out << 1;
		writel(val, addr);
	}

	return;
}

void gpio_set_value(unsigned int gpio, unsigned int out)
{
	unsigned int *addr = (unsigned int *)GPIO_IN_OUT_ADDR(gpio);
	unsigned int val = 0;

	val = readl(addr);
	val &= ~(0x2);
	val |= out << 1;
	writel(val, addr);
}

int gpio_get_value(unsigned int gpio)
{
	unsigned int *addr = (unsigned int *)GPIO_IN_OUT_ADDR(gpio);
	unsigned int val = readl(addr);

	return (val & 1);
}

void gpio_direction_output(unsigned int gpio, unsigned int out)
{
	unsigned int *addr = (unsigned int *)GPIO_CONFIG_ADDR(gpio);
	unsigned int val = 0;

	gpio_set_value(gpio, out);
	val = readl(addr);
	val |= 1 << 9;
	writel(val, addr);
}

int qca_gpio_init(int offset)
{
	struct qca_gpio_config gpio_config;

	for (offset = fdt_first_subnode(gd->fdt_blob, offset); offset > 0;
	     offset = fdt_next_subnode(gd->fdt_blob, offset)) {

		gpio_config.gpio	= fdtdec_get_uint(gd->fdt_blob,
							  offset, "gpio", 0);
		gpio_config.func	= fdtdec_get_uint(gd->fdt_blob,
							  offset, "func", 0);
		gpio_config.out		= fdtdec_get_uint(gd->fdt_blob,
							  offset, "out", 0);
		gpio_config.pull	= fdtdec_get_uint(gd->fdt_blob,
							  offset, "pull", 0);
		gpio_config.drvstr	= fdtdec_get_uint(gd->fdt_blob,
							  offset, "drvstr", 0);
		gpio_config.oe		= fdtdec_get_uint(gd->fdt_blob,
							  offset, "oe", 0);
		gpio_config.vm		= fdtdec_get_uint(gd->fdt_blob,
							  offset, "vm", 0);
		gpio_config.od_en	= fdtdec_get_uint(gd->fdt_blob,
							  offset, "od_en", 0);
		gpio_config.pu_res	= fdtdec_get_uint(gd->fdt_blob,
							  offset, "pu_res", 0);
		gpio_config.sr_en	= fdtdec_get_uint(gd->fdt_blob,
							  offset, "sr_en", 0);
		gpio_tlmm_config(&gpio_config);
	}
	return 0;
}

int qca_gpio_deinit(int offset)
{
	struct qca_gpio_config gpio_config;

	for (offset = fdt_first_subnode(gd->fdt_blob, offset); offset > 0;
	     offset = fdt_next_subnode(gd->fdt_blob, offset)) {

		gpio_config.gpio	= fdtdec_get_uint(gd->fdt_blob,
							  offset, "gpio", 0);
		unsigned int *addr =
			(unsigned int *)GPIO_CONFIG_ADDR(gpio_config.gpio);
		writel(1, addr);
		addr = (unsigned int *)GPIO_IN_OUT_ADDR(gpio_config.gpio);
		writel(1, addr);
	}
	return 0;
}
