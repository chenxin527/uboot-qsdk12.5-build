/*
 * Copyright 2015 Freescale Semiconductor, Inc.
 *
 * DWC3 controller driver
 *
 * Author: Ramneek Mehresh<ramneek.mehresh@freescale.com>
 *
 * SPDX-License-Identifier:     GPL-2.0+

 * Copyright (c) 2014, 2015 The Linux Foundation. All rights reserved.
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
#include <dm.h>
#include <usb.h>
#include <linux/compat.h>
#include <asm-generic/errno.h>
#include <linux/usb/dwc3.h>
#include "xhci.h"

/* Declare global data pointer */
DECLARE_GLOBAL_DATA_PTR;

struct ipq_xhci_platdata {
	fdt_addr_t hcd_base;
	unsigned int rst_ctrl;
	unsigned int hs_only;
};

struct ipq_xhci {
	struct ipq_xhci_platdata usb_plat;
	struct xhci_ctrl ctrl;
	struct udevice* dev;
	struct xhci_hccr *hcd;
	struct dwc3 *dwc3_reg;
};

void ipq_reset_usb_phy(void *data)
{
	unsigned int gcc_rst_ctrl;
	struct ipq_xhci_platdata *platdata;
	struct ipq_xhci *ipq = (struct ipq_xhci *)data;

	platdata = dev_get_platdata(ipq->dev);
	if (platdata == NULL) {
		printf("Error: %s Failed\n", __func__);
		return;
	}

	gcc_rst_ctrl = platdata->rst_ctrl;

	if (gcc_rst_ctrl) {
		/* assert HS PHY POR reset */
		setbits_le32(gcc_rst_ctrl, 0x10);
		mdelay(10);

		/* assert HS PHY SRIF reset */
		setbits_le32(gcc_rst_ctrl, 0x4);
		mdelay(10);

		/* deassert HS PHY SRIF reset and program HS PHY registers */
		clrbits_le32(gcc_rst_ctrl, 0x4);
		mdelay(10);

		/* de-assert USB3 HS PHY POR reset */
		clrbits_le32(gcc_rst_ctrl, 0x10);
		mdelay(10);

		if (!platdata->hs_only) {
			/* assert SS PHY POR reset */
			setbits_le32(gcc_rst_ctrl, 0x20);
			mdelay(10);

			/* deassert SS PHY POR reset */
			clrbits_le32(gcc_rst_ctrl, 0x20);
		}
	}
}

static int ipq_xhci_core_init(struct ipq_xhci *ipq)
{
	int ret = 0;

	ipq_reset_usb_phy((void *)ipq);

	ret = dwc3_core_init(ipq->dwc3_reg);
	if (ret) {
		debug("%s:failed to initialize core\n", __func__);
		return ret;
	}

	/* We are hard-coding DWC3 core to Host Mode */
	dwc3_set_mode(ipq->dwc3_reg, DWC3_GCTL_PRTCAP_HOST);

	return ret;
}

static void ipq_xhci_core_exit(struct ipq_xhci *ipq)
{

}

static int xhci_usb_remove(struct udevice *dev)
{
	int ret;
	ret = xhci_deregister(dev);

	if (ret != 0) {
		debug("%s:xhci deregistration failed\n", __func__);
		return ret;
	}

	ipq_xhci_core_exit(dev_get_priv(dev));

	return 0;
}

static int xhci_usb_probe(struct udevice *dev)
{
	struct ipq_xhci *context;
	struct ipq_xhci_platdata *platdata;
	struct xhci_hcor *hcor;
	int ret;

	platdata = dev_get_platdata(dev);
	if (platdata == NULL) {
		printf("Error: %s Failed\n", __func__);
		return -ENODEV;
	}

	context = dev_get_priv(dev);
	if (context == NULL) {
		printf("Error: %s Failed\n", __func__);
		return -ENODEV;
	}

	context->hcd = (struct xhci_hccr *)platdata->hcd_base;
	context->dev = dev;
	context->dwc3_reg = (struct dwc3 *)((char *)(context->hcd) + DWC3_REG_OFFSET);
	hcor = (struct xhci_hcor *)((uint32_t)context->hcd +
			HC_LENGTH(xhci_readl(&context->hcd->cr_capbase)));

	ret = ipq_xhci_core_init(context);

	if (ret) {
		puts("Error initializing the XHCI controller\n");
		return -EINVAL;
	}

	return xhci_register(dev, context->hcd, hcor);
}

static int xhci_ofdata_to_platdata(struct udevice *dev)
{
	struct ipq_xhci_platdata *platdata;
	const void *blob = gd->fdt_blob;

	platdata = dev_get_platdata(dev);
	if (platdata == NULL) {
		printf("Error: %s Failed\n", __func__);
		return -ENODEV;
	}

	platdata->hcd_base = dev_get_addr(dev);
	if (platdata->hcd_base == FDT_ADDR_T_NONE) {
		debug("Error getting DWC3 base address\n");
		return -ENXIO;
	}

	platdata->rst_ctrl = fdtdec_get_int(blob, dev->of_offset, "rst_ctrl", 0);
	platdata->hs_only = fdtdec_get_int(blob, dev->of_offset, "hs_only", 0);

	return 0;
}

static const struct udevice_id xhci_match_ids[] = {
	{ .compatible = "qca,dwc3-ipq" },
	{}
};

U_BOOT_DRIVER(usb_xhci) = {
	.name	= "xhci_ipq",
	.id	= UCLASS_USB,
	.of_match = xhci_match_ids,
	.ofdata_to_platdata = xhci_ofdata_to_platdata,
	.probe = xhci_usb_probe,
	.remove = xhci_usb_remove,
	.ops	= &xhci_usb_ops,
	.platdata_auto_alloc_size = sizeof(struct ipq_xhci_platdata),
	.priv_auto_alloc_size = sizeof(struct ipq_xhci),
	.flags	= DM_FLAG_ALLOC_PRIV_DMA,
};
