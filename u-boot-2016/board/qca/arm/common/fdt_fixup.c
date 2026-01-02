/*
 * Copyright (c) 2015-2017, 2020 The Linux Foundation. All rights reserved.
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
#include <asm/arch-qca-common/smem.h>
#include <asm/arch-qca-common/scm.h>
#include <jffs2/load_kernel.h>
#include <fdtdec.h>
#include <stdlib.h>
#include "fdt_info.h"

DECLARE_GLOBAL_DATA_PTR;

#ifdef CONFIG_QPIC_SERIAL
extern unsigned int qpic_training_offset;
#endif

#ifdef CONFIG_IPQ_FDT_FIXUP
#define FDT_EDIT "fdtedit"
/* Buffer size to hold numbers from 0-99 + 1 NULL character */
#define NUM_BUF_SIZE 3
#endif
/*
 * Don't have this as a '.bss' variable. The '.bss' and '.rel.dyn'
 * sections seem to overlap.
 *
 * $ arm-none-linux-gnueabi-objdump -h u-boot
 * . . .
 *  8 .rel.dyn      00004ba8  40630b0c  40630b0c  00038b0c  2**2
 *                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 *  9 .bss          0000559c  40630b0c  40630b0c  00000000  2**3
 *                  ALLOC
 * . . .
 *
 * board_early_init_f() initializes this variable, resulting in one
 * of the relocation entries present in '.rel.dyn' section getting
 * corrupted. Hence, when relocate_code()'s 'fixrel' executes, it
 * patches a wrong address, which incorrectly modifies some global
 * variable resulting in a crash.
 *
 * Moral of the story: Global variables that are written before
 * relocate_code() gets executed cannot be in '.bss'
 */

#ifdef CONFIG_OF_BOARD_SETUP

extern int fdt_node_set_part_info(void *blob, int parent_offset,
                                  struct mtd_device *dev);

struct flash_node_info {
	const char *compat;	/* compatible string */
	int type;		/* mtd flash type */
	int idx;		/* flash index */
};

int ipq_fdt_fixup_spi_nor_params(void *blob)
{
	int nodeoff, ret;
	qca_smem_flash_info_t sfi;
	uint32_t val;

	/* Get flash parameters from smem */
	smem_get_boot_flash(&sfi.flash_type,
				&sfi.flash_index,
				&sfi.flash_chip_select,
				&sfi.flash_block_size,
				&sfi.flash_density);
	nodeoff = fdt_node_offset_by_compatible(blob, -1, "n25q128a11");

	if (nodeoff < 0) {
		nodeoff = fdt_node_offset_by_compatible(blob,
				-1, "micron,n25q128a11");
		if (nodeoff < 0) {
			printf("fdt-fixup: unable to find compatible node\n");
			return nodeoff;
		}
	}

	val = cpu_to_fdt32(sfi.flash_block_size);
	ret = fdt_setprop(blob, nodeoff, "sector-size",
			&val, sizeof(uint32_t));
	if (ret) {
		printf("fdt-fixup: unable to set sector size(%d)\n", ret);
		return -1;
	}

	if (sfi.flash_density != 0) {
		val = cpu_to_fdt32(sfi.flash_density);
		ret = fdt_setprop(blob, nodeoff, "density",
				&val, sizeof(uint32_t));
		if (ret) {
			printf("fdt-fixup: unable to set density(%d)\n", ret);
			return -1;
		}
	}

	return 0;
}

void ipq_fdt_fixup_version(void *blob)
{
	int nodeoff, ret;
	char ver[OEM_VERSION_STRING_LENGTH + VERSION_STRING_LENGTH + 1];
	uint32_t machid;

	nodeoff = fdt_path_offset(blob, "/");

	if (nodeoff < 0) {
		debug("fdt-fixup: fdt fixup unable to find root node\n");
		return;
	}

	machid = smem_get_board_platform_type();

	if (machid) {
		ret = fdt_setprop(blob, nodeoff, "machid",
				  &machid, sizeof(uint32_t));

		if (ret)
			debug("fdt-fixup: unable to set machid(%d)\n", ret);
	}

	if (!smem_get_build_version(ver, sizeof(ver), BOOT_VERSION)) {
		debug("BOOT Build Version:  %s\n", ver);
		ret = fdt_setprop(blob, nodeoff, "boot_version",
				ver, strlen(ver));
		if (ret)
			debug("fdt-fixup: unable to set Boot version(%d)\n", ret);
	}
	/* ipq806x doesn't have image version table in SMEM */
	else if (!ipq_smem_get_boot_version(ver, sizeof(ver))) {
		debug("BOOT Build Version:  %s\n", ver);
		ret = fdt_setprop(blob, nodeoff, "boot_version",
				ver, strlen(ver));
		if (ret)
			debug("fdt-fixup: unable to set Boot version(%d)\n", ret);
	}

	if (!smem_get_build_version(ver, sizeof(ver), TZ_VERSION)) {
		debug("TZ Build Version:  %s\n", ver);
		ret = fdt_setprop(blob, nodeoff, "tz_version",
				ver, strlen(ver));
		if (ret)
			debug("fdt-fixup: unable to set TZ version(%d)\n", ret);
	}
	/* for ipq806x, get the tz_version through scm_call */
	else if (!ipq_get_tz_version(ver, sizeof(ver))) {
		debug("TZ Build Version:  %s\n", ver);
		ret = fdt_setprop(blob, nodeoff, "tz_version",
				ver, strlen(ver));
		if (ret)
			debug("fdt-fixup: unable to set TZ version(%d)\n", ret);
	}

#ifdef RPM_VERSION
	if (!smem_get_build_version(ver, sizeof(ver), RPM_VERSION)) {
		debug("RPM Build Version:  %s\n", ver);
		ret = fdt_setprop(blob, nodeoff, "rpm_version",
				ver, strlen(ver));
		if (ret)
			debug("fdt-fixup: unable to set RPM version(%d)\n", ret);
	}
#endif /* RPM_VERSION */
}

#if defined (CONFIG_IPQ_TINY) && !defined(CONFIG_NAND_FLASH)
#define		OFFSET_NOT_SPECIFIED	(~0llu)
struct reg_cell {
	unsigned int r0;
	unsigned int r1;
};

extern int fdt_del_partitions(void *blob, int parent_offset);

int parse_nor_partition(const char *const partdef,
			const char **ret,
			struct part_info **retpart);

void free_parse(struct list_head *head);

static void ipq_nor_fdt_fixup(void *blob, struct flash_node_info *ni)
{
	int parent_offset;
	struct part_info *part, *pPartInfo;
	struct reg_cell cell;
	int off, ndepth = 0;
	int part_num, ret, newoff;
	char buf[64];
	int offset = 0;
	struct list_head *pentry;
	LIST_HEAD(tmp_list);
	const char *pMtdparts =  getenv("mtdparts");

	if (!pMtdparts)
		return;

	for (; ni->compat; ni++) {
		parent_offset = fdt_node_offset_by_compatible(
					blob, -1, ni->compat);
		if (parent_offset != -FDT_ERR_NOTFOUND)
			break;
	}

	if (parent_offset == -FDT_ERR_NOTFOUND){
		printf(" compatible not found \n");
		return;
	}

	ret = fdt_del_partitions(blob, parent_offset);
	if (ret < 0)
		return;

	/*
	 * Check if it is nand {}; subnode, adjust
	 * the offset in this case
	 */
	off = fdt_next_node(blob, parent_offset, &ndepth);
	if (off > 0 && ndepth == 1)
		parent_offset = off;

	if (strncmp(pMtdparts, "mtdparts=", 9) == 0) {
		pMtdparts += 9;
		pMtdparts = strchr(pMtdparts, ':');
		pMtdparts++;
	} else {
		printf("mtdparts variable doesn't start with 'mtdparts='\n");
		return;
	}

	part_num = 0;

	while (pMtdparts && (*pMtdparts != '\0') && (*pMtdparts != ';')) {
		if ((parse_nor_partition(pMtdparts, &pMtdparts, &pPartInfo) != 0))
			break;

		/* calculate offset when not specified */
		if (pPartInfo->offset == OFFSET_NOT_SPECIFIED)
			pPartInfo->offset = offset;
		else
			offset = pPartInfo->offset;

		offset += pPartInfo->size;
		/* partition is ok, add it to the list */
		list_add_tail(&pPartInfo->link, &tmp_list);
	}
	list_for_each_prev(pentry, &tmp_list) {

		part = list_entry(pentry, struct part_info, link);

		debug("%2d: %-20s0x%08llx\t0x%08llx\t%d\n",
			part_num, part->name, part->size,
			part->offset, part->mask_flags);

		snprintf(buf, sizeof(buf), "partition@%llx", part->offset);
add_sub:
		ret = fdt_add_subnode(blob, parent_offset, buf);
		if (ret == -FDT_ERR_NOSPACE) {
			ret = fdt_increase_size(blob, 512);
			if (!ret)
				goto add_sub;
			else
				goto err_size;
		} else if (ret < 0) {
			printf("Can't add partition node: %s\n",
				fdt_strerror(ret));
			return;
		}
		newoff = ret;

		/* Check MTD_WRITEABLE_CMD flag */
		if (pPartInfo->mask_flags & 1) {
add_ro:
			ret = fdt_setprop(blob, newoff, "read_only", NULL, 0);
			if (ret == -FDT_ERR_NOSPACE) {
				ret = fdt_increase_size(blob, 512);
				if (!ret)
					goto add_ro;
				else
					goto err_size;
			} else if (ret < 0)
				goto err_prop;
		}

		cell.r0 = cpu_to_fdt32(part->offset);
		cell.r1 = cpu_to_fdt32(part->size);
add_reg:
		ret = fdt_setprop(blob, newoff, "reg", &cell, sizeof(cell));
		if (ret == -FDT_ERR_NOSPACE) {
			ret = fdt_increase_size(blob, 512);
			if (!ret)
				goto add_reg;
			else
				goto err_size;
		} else if (ret < 0)
			goto err_prop;

add_label:
		ret = fdt_setprop_string(blob, newoff, "label", part->name);
		if (ret == -FDT_ERR_NOSPACE) {
			ret = fdt_increase_size(blob, 512);
			if (!ret)
				goto add_label;
			else
				goto err_size;
		} else if (ret < 0)
			goto err_prop;

		part_num++;
	}
	goto remove_list;
err_size:
	printf("Can't increase blob size: %s\n", fdt_strerror(ret));
	goto remove_list;
err_prop:
	printf("Can't add property: %s\n", fdt_strerror(ret));
	goto remove_list;
remove_list:
	free_parse(&tmp_list);
	return;
}
#else
void ipq_fdt_fixup_mtdparts(void *blob, struct flash_node_info *ni)
{
	struct mtd_device *dev;
	char *parts;
	int noff;

	parts = getenv("mtdparts");
	if (!parts)
		return;

	if (mtdparts_init() != 0)
		return;

	for (; ni->compat; ni++) {
		noff = fdt_node_offset_by_compatible(blob, -1, ni->compat);

		while (noff != -FDT_ERR_NOTFOUND) {
			dev = device_find(ni->type, ni->idx);
			if (dev) {
				if (fdt_node_set_part_info(blob, noff, dev))
					return; /* return on error */
			}

			/* Jump to next flash node */
			noff = fdt_node_offset_by_compatible(blob, noff,
							     ni->compat);
		}
	}
}
#endif

#ifdef CONFIG_IPQ_FDT_FIXUP
void ipq_fdt_dload_disable_fixup(void *blob)
{
	u32 dload = 1;
	int parentoff, nodeoff, ret, i;

	dload = htonl(dload);

	/* Reserve only the TZ and SMEM memory region and free the rest */
	parentoff = fdt_path_offset(blob, rsvd_node);
	if (parentoff >= 0) {
		for (i = 0; del_node[i]; i++) {
			nodeoff = fdt_subnode_offset(blob, parentoff,
						     del_node[i]);
			if (nodeoff < 0) {
				debug("fdt-fixup: unable to findnode (%s)\n",
					del_node[i]);
				continue;
			}
			ret = fdt_del_node(blob, nodeoff);
			if (ret != 0)
				debug("fdt-fixup: unable to delete node (%s)\n",
					del_node[i]);
		}

		for (i = 0; add_fdt_node[i].nodename; i++) {
			nodeoff = fdt_add_subnode(blob, parentoff,
						  add_fdt_node[i].nodename);
			if (nodeoff < 0) {
				debug("fdt-fixup: unable to add subnode (%s)\n",
					add_fdt_node[i].nodename);
				continue;
			}
			ret = fdt_setprop(blob, nodeoff, "no-map", NULL, 0);
			if (ret != 0)
				debug("fdt-fixup: unable to set property\n");

			ret = fdt_setprop(blob, nodeoff, "reg",
					  add_fdt_node[i].val,
					  sizeof(add_fdt_node[i].val));
			if (ret != 0)
				debug("fdt-fixup: unable to set property\n");
		}
	} else {
		debug("fdt-fixup: unable to find node \n");
	}

	/* Set the dload_status to DLOAD_DISABLE */
	nodeoff = fdt_path_offset(blob, "/soc/qca,scm_restart_reason");
	if (nodeoff < 0) {
		nodeoff = fdt_path_offset(blob, "/qti,scm_restart_reason");
		if (nodeoff < 0) {
			nodeoff = fdt_path_offset(blob, "/soc/qti,scm_restart_reason");
			if (nodeoff < 0) {
				debug("fdt-fixup: unable to find compatible node\n");
				return;
			}
		}
	}

	ret = fdt_setprop(blob, nodeoff, "dload_status", &dload, sizeof(dload));
	if (ret != 0) {
		debug("fdt-fixup: unable to find compatible node\n");
		return;
	}
}

struct vlan_tag {
	unsigned int r0;
	unsigned int r1;
};

struct eth_param{
	int nodeoff;
	int mdio_addr;
	int poll;
	int speed;
	int duplex;
	unsigned long gmac_no;
};

static void ipq40xx_set_setprop(void *blob, int nodeoff, unsigned long gmac_no,
							char *str, int val)
{
	int ret;

	ret = fdt_setprop(blob, nodeoff, str, &val, sizeof(val));
	if (ret)
		debug("unable to set property %s for %lu with error %d\n",
		      str, gmac_no, ret);
}

static void ipq40xx_populate_eth_params(void *blob, struct eth_param *port)
{
	ipq40xx_set_setprop(blob, port->nodeoff, port->gmac_no,
				"qcom,phy_mdio_addr", htonl(port->mdio_addr));
	ipq40xx_set_setprop(blob, port->nodeoff, port->gmac_no,
				"qcom,poll_required", htonl(port->poll));
	ipq40xx_set_setprop(blob, port->nodeoff, port->gmac_no,
				"qcom,forced_speed", htonl(port->speed));
	ipq40xx_set_setprop(blob, port->nodeoff, port->gmac_no,
				"qcom,forced_duplex", htonl(port->duplex));
}

/*
 * Logic to patch Ethernet params.
 */
static int ipq40xx_patch_eth_params(void *blob, unsigned long gmac_no)
{
	int nodeoff, nodeoff_c;
	int ret, i;
	struct vlan_tag vlan;
	struct eth_param port_config;
	const char *eth2_prop[] = {"/soc/edma/gmac2", "/soc/edma/gmac3",
							"/soc/edma/gmac4"};
	const char *alias_prop[] = {"ethernet2", "ethernet3", "ethernet4"};
	const char *gmac_node[] = {"gmac2", "gmac3", "gmac4"};

	nodeoff = fdt_path_offset(blob, "/aliases");
	if (nodeoff < 0) {
		printf("ipq: fdt fixup unable to find compatible node\n");
		return -1;
	} else {
		debug("Node Found\n");
	}

	for (i = 0; i < (gmac_no - 2); i++) {
		ret = fdt_setprop(blob, nodeoff, alias_prop[i],
			eth2_prop[i], (strlen(eth2_prop[i]) + 1));
		if (ret)
			debug("%d: unable to patch alias\n", ret);
		nodeoff_c = fdt_path_offset(blob, "/soc/edma");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}

		ret = fdt_add_subnode(blob, nodeoff_c, gmac_node[i]);
		if (ret < 0)
			debug("%d: unable to add node\n", ret);
	}

	switch (gmac_no) {
	case 3:
		nodeoff_c = fdt_path_offset(blob, "/soc/edma/gmac1");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}
		vlan.r0 = htonl(0x1);
		vlan.r1 = htonl(0x10);
		ret = fdt_setprop(blob, nodeoff_c, "vlan_tag",
			&vlan, sizeof(vlan));
		if (ret)
			debug("%d: unable to set property\n", ret);

		nodeoff_c = fdt_path_offset(blob, "/soc/edma/gmac2");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}
		vlan.r0 = htonl(0x3);
		vlan.r1 = htonl(0xE);
		ret = fdt_setprop(blob, nodeoff_c, "vlan_tag",
			&vlan, sizeof(vlan));
		if (ret)
			debug("%d: unable to set property\n", ret);
		break;
	case 4:
		nodeoff_c = fdt_path_offset(blob, "/soc/edma/gmac1");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}
		vlan.r0 = htonl(0x1);
		vlan.r1 = htonl(0x10);
		ret = fdt_setprop(blob, nodeoff_c, "vlan_tag",
			&vlan, sizeof(vlan));
		if (ret)
			debug("%d: unable to set property\n", ret);

		nodeoff_c = fdt_path_offset(blob, "/soc/edma/gmac2");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}
		vlan.r0 = htonl(0x3);
		vlan.r1 = htonl(0x8);
		ret = fdt_setprop(blob, nodeoff_c, "vlan_tag",
			&vlan, sizeof(vlan));
		if (ret)
			debug("%d: unable to set property\n", ret);

		nodeoff_c = fdt_path_offset(blob, "/soc/edma/gmac3");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}
		vlan.r0 = htonl(0x4);
		vlan.r1 = htonl(0x6);
		ret = fdt_setprop(blob, nodeoff_c, "vlan_tag",
			&vlan, sizeof(vlan));
		if (ret)
			debug("%d: unable to set property\n", ret);
		break;
	case 5:
		nodeoff_c = fdt_path_offset(blob, "/soc/edma/gmac1");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}
		vlan.r0 = htonl(0x1);
		vlan.r1 = htonl(0x10);
		ret = fdt_setprop(blob, nodeoff_c, "vlan_tag",
			&vlan, sizeof(vlan));
		if (ret)
			debug("%d: unable to set property\n", ret);

		port_config.nodeoff = nodeoff_c;
		port_config.mdio_addr = 3;
		port_config.poll = 1;
		port_config.speed = 1000;
		port_config.duplex = 1;
		port_config.gmac_no = gmac_no;
		ipq40xx_populate_eth_params(blob, &port_config);

		nodeoff_c = fdt_path_offset(blob, "/soc/edma/gmac2");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}
		vlan.r0 = htonl(0x3);
		vlan.r1 = htonl(0x8);
		ret = fdt_setprop(blob, nodeoff_c, "vlan_tag",
			&vlan, sizeof(vlan));
		if (ret)
			debug("%d: unable to set property\n", ret);

		port_config.nodeoff = nodeoff_c;
		port_config.mdio_addr = 2;
		port_config.poll = 1;
		port_config.speed = 1000;
		port_config.duplex = 1;
		port_config.gmac_no = gmac_no;
		ipq40xx_populate_eth_params(blob, &port_config);

		nodeoff_c = fdt_path_offset(blob, "/soc/edma/gmac3");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}
		vlan.r0 = htonl(0x4);
		vlan.r1 = htonl(0x4);
		ret = fdt_setprop(blob, nodeoff_c, "vlan_tag",
			&vlan, sizeof(vlan));
		if (ret)
			debug("%d: unable to set property\n", ret);

		port_config.nodeoff = nodeoff_c;
		port_config.mdio_addr = 1;
		port_config.poll = 1;
		port_config.speed = 1000;
		port_config.duplex = 1;
		port_config.gmac_no = gmac_no;
		ipq40xx_populate_eth_params(blob, &port_config);

		nodeoff_c = fdt_path_offset(blob, "/soc/edma/gmac4");
		if (nodeoff_c < 0) {
			printf("ipq: unable to find compatiable edma node\n");
			return -1;
		}
		vlan.r0 = htonl(0x5);
		vlan.r1 = htonl(0x2);
		ret = fdt_setprop(blob, nodeoff_c, "vlan_tag",
			&vlan, sizeof(vlan));
		if (ret)
			debug("%d: unable to set property\n", ret);

		port_config.nodeoff = nodeoff_c;
		port_config.mdio_addr = 0;
		port_config.poll = 1;
		port_config.speed = 1000;
		port_config.duplex = 1;
		port_config.gmac_no = gmac_no;
		ipq40xx_populate_eth_params(blob, &port_config);

		break;
	}
	nodeoff = fdt_node_offset_by_compatible(blob,
			-1, "qcom,ess-edma");
	if (nodeoff < 0) {
		printf("ipq: unable to find compatible edma node\n");
		return -1;
	}

	gmac_no = htonl(gmac_no);
	ret = fdt_setprop(blob, nodeoff, "qcom,num_gmac",
		&gmac_no, sizeof(gmac_no));
	if (ret)
		debug("%d: unable to set property\n", ret);
	return 0;
}
#endif

#ifdef CONFIG_IPQ_FDT_FIXUP
/* setenv fdteditnum <num>   - here <num> represents number of envs to parse
 * Note: without setting 'fdteditnum' fdtedit envs will not parsed
 *
 * fdtedit<num> <node>%<property>%<node_value>   - dts patching env format
 * here '%' is separator; <num> can be between 1 to 99;
 *
 * 1. To change add/change a particular property of a node:
 *       setenv fdtedit0 <node_path>%<property>%<value>
 *
 *    This can be used to add properties which doesn't have any value associated
 *       eg: qca,secure; property of q6v5_wcss@CD00000 node can be added as:
 *       setenv fdtedit0 /soc/q6v5_wcss@CD00000/%qca,secure%1
 *    other eg:
 *       fdtedit0=/soc/q6v5_wcss@CD00000%qca,sec-reset-cmd%0x19
 *       fdtedit1=/soc/usb3@8A00000/dwc3@8A00000%dr_mode%?peripheral
 *       fdtedit2=/soc/qcom,gadget_diag@0/%status%?ok
 *
 * 2. To delete a property of a node:
 *       setenv fdtedit0 <node_path>%delete%<property>
 *    example:
 *       fdtedit0=/soc/q6v5_wcss@CD00000%delete%?qca,secure
 *
 * The last param in both add or delete case, if it is a string, it should
 * start with '?' else if it is a number, it can be put directly.
 * check above examples for reference.
 *
 * 3. To add 32bit or 64bit array values:
 *       setenv fdtedit0 <node_path>%<bit_value>?<num_values>?<property_name>%<value1>?<value2>?<value3>?..
 *       <bit_value> can be 32 / 64;  <num_values> is number of array elements
 *       to be patched; <property_name> is the actual name of the property to
 *       be patched; each array value has to be separated by '?'
 *       for reg = <addr> <size>; <num_values> is 2 in this case
 *    example:
 *       setenv fdtedit0 /soc/dbm@0x8AF8000/%32?2?reg%0x8AF8000?0x500
 *       setenv fdtedit1 /soc/pci@20000000/%32?2?bus-range%0xee?0xee
 *       setenv fdtedit2 /soc/usb3@8A00000/%32?4?reg%0x8AF8600?0x200?0x8A00000?0xcb00
 *       setenv fdtedit3 /reserved-memory/tzapp@49B00000/%64?2?reg%0x49A00000?0x500000
 */
void parse_fdt_fixup(char* buf, void *blob)
{
	int nodeoff, value, ret, num_values, i;
	char *node, *property, *node_value, *sliced_string;
	bool if_string = true, bit32 = true;
	u32 *values32;
	u64 *values64;

	/* env is split into <node>%<property>%<node_value>. '%' is separator */
	node = strsep(&buf, "%");
	property = strsep(&buf, "%");
	node_value = strsep(&buf, "%");

	debug("node: %s  property: %s  node_value: %s\n", node, property, node_value);

	/* if '?' is present then node_value is string;
	 * else, node_value is 32bit value
	 */
	if (node_value && node_value[0] != '?') {
		if_string = false;
		value = simple_strtoul(node_value, NULL, 10);
	} else {
		/* skip '?' */
		node_value++;
	}

	nodeoff = fdt_path_offset(blob, node);
	if (nodeoff < 0) {
		printf("%s: unable to find node '%s'\n", __func__, node);
		return;
	}

	if (!strncmp(property, "delete", strlen("delete"))) {
		/* handle property deletes */
		ret = fdt_delprop(blob, nodeoff, node_value);
		if (ret) {
			printf("%s: unable to delete %s\n", __func__, node_value);
			return;
		}
	} else if (!strncmp(property, "32", strlen("32")) || !strncmp(property, "64", strlen("64"))) {
		/* if property name starts with '32' or '64', then it is used
		 * for patching array of 32bit / 64bit values correspondingly.
		 * 32bit patching is usually used to patch reg = <addr> <size>;
		 * but could also be used to patch multiple addresses & sizes
		 * <property> = <addr1> <size1> <addr2> <size2> ..
		 * 64bit patching is usually used to patch reserved memory nodes
		 */
		sliced_string = strsep(&property, "?");
		if (simple_strtoul(sliced_string, NULL, 10) == 64)
			bit32 = false;

		/* get the number of array values */
		sliced_string = strsep(&property, "?");
		num_values = simple_strtoul(sliced_string, NULL, 10);

		if (bit32 == true) {
			values32 = malloc(num_values * sizeof(u32));

			for (i = 0; i < num_values; i++)  {
				sliced_string = strsep(&node_value, "?");
				values32[i] =  cpu_to_fdt32(simple_strtoul(sliced_string, NULL, 10));
			}

			ret = fdt_setprop(blob, nodeoff, property, values32, num_values * sizeof(u32));
			if (ret) {
				printf("%s: failed to set prop %s\n", __func__, property);
				return;
			}
		} else {
			values64 = malloc(num_values * sizeof(u64));

			for (i = 0; i < num_values; i++)  {
				sliced_string = strsep(&node_value, "?");
				values64[i] =  cpu_to_fdt64(simple_strtoul(sliced_string, NULL, 10));
			}

			ret = fdt_setprop(blob, nodeoff, property, values64, num_values * sizeof(u64));
			if (ret) {
				printf("%s: failed to set prop %s\n", __func__, property);
				return;
			}
		}
	} else if (!if_string) {
		/* handle 32bit integer value patching */
		ret = fdt_setprop_u32(blob, nodeoff, property, value);
		if (ret) {
			printf("%s: failed to set prop %s\n", __func__, property);
			return;
		}
	} else {
		/* handle string value patching
		 * usually used to patch status = "ok"; status = "disabled";
		 */
		ret = fdt_setprop(blob, nodeoff, property,
				node_value,
				(strlen(node_value) + 1));
		if (ret) {
			printf("%s: failed to set prop %s\n", __func__, property);
			return;
		}
	}
}

/* check parse_fdt_fixup for detailed explanation */
void ipq_fdt_fixup(void *blob)
{
	int i, fdteditnum;
	char buf[sizeof(FDT_EDIT) + NUM_BUF_SIZE], num[NUM_BUF_SIZE];
	char *s;

	/* fdteditnum - defines the number of envs to parse
	 * starting from 0. eg: fdtedit0, fdtedit1, and so on.
	 */
	s = getenv("fdteditnum");
	if (s)
		fdteditnum = simple_strtoul(s, NULL, 10);
	else
		return;

	printf("%s: fixup fdtedits\n", __func__);

	for (i = 0; i <= fdteditnum; i++) {
		/* Generate env names fdtedit0, fdtedit1,..fdteditn */
		strlcpy(buf, FDT_EDIT, sizeof(buf));
		snprintf(num, sizeof(num), "%d", i);
		strlcat(buf, num, sizeof(buf));

		s = getenv(buf);
		if (s)
			parse_fdt_fixup(s, blob);
	}
}

__weak void fdt_fixup_sd_ldo_gpios_toggle(void *blob)
{
	return;
}

__weak void fdt_low_memory_fixup(void *blob)
{
	return;
}

__weak void fdt_fixup_cpr(void *blob)
{
	return;
}

__weak void fdt_fixup_cpus_node(void * blob)
{
	return;
}

__weak void fdt_fixup_set_dload_warm_reset(void *blob)
{
	return;
}

__weak void fdt_fixup_set_qce_fixed_key(void *blob)
{
	return;
}

__weak void fdt_fixup_set_qca_cold_reboot_enable(void *blob)
{
	return;
}

__weak void fdt_fixup_for_atf(void *blob)
{
	return;
}

#ifdef CONFIG_IPQ_BT_SUPPORT
__weak void fdt_fixup_bt_running(void *blob)
{
	return;
}
#endif

__weak void fdt_fixup_bt_debug(void *blob)
{
	return;
}
__weak void fdt_fixup_flash(void *blob)
{
	return;
}

__weak void fdt_fixup_qpic(void *blob)
{
	return;
}

__weak void fdt_fixup_qpic_serial_training_offset(void *blob)
{
#if defined(CONFIG_QPIC_SERIAL) && defined(CONFIG_IPQ_FDT_FIXUP)
	char node_name[128];

	if (qpic_training_offset != 0xBAD0FF5E){
		snprintf(node_name, sizeof(node_name), "%s%s%d",
				CONFIG_QPIC_NODE,
				"%qcom,training_offset%",
				qpic_training_offset);

		parse_fdt_fixup(node_name, blob);
	}
#else
	return;
#endif
}

__weak void fdt_fixup_sdx65_gpio(void *blob)
{
	return;
}

__weak void ipq_fdt_fixup_usb_device_mode(void *blob)
{
	const char *usb_cfg;

	usb_cfg = getenv("usb_mode");
	if (!usb_cfg)
		return;

	if (!strncmp(usb_cfg, "peripheral", sizeof("peripheral"))) {
		goto peripheral;
	} else if (!strncmp(usb_cfg, "diag_gadget", sizeof("diag_gadget"))) {
		if (fdt_path_offset(blob, "/soc/qcom,gadget_diag@0") < 0){
			parse_fdt_fixup(
				"/qti,gadget_diag@0%status%?ok", blob);
		} else {
			parse_fdt_fixup(
				"/soc/qcom,gadget_diag@0%status%?ok", blob);
		}
	} else {
		printf("%s: invalid param for usb_mode\n", __func__);
		return;
	}

peripheral:
	parse_fdt_fixup(
		"/soc/usb3@8A00000/dwc3@8A00000%dr_mode%?peripheral",
		blob);
	parse_fdt_fixup(
		"/soc/usb3@8A00000/dwc3@8A00000%maximum-speed%?high-speed",
		blob);
}

__weak void fdt_fixup_auto_restart(void *blob)
{
	return;
}
#endif

__weak void fdt_fixup_art_format(void *blob)
{
	return;
}

__weak void ipq_fdt_fixup_socinfo(void *blob)
{
	uint32_t cpu_type;
	uint32_t soc_version, soc_version_major, soc_version_minor;
	int nodeoff, ret;

	nodeoff = fdt_path_offset(blob, "/");

	if (nodeoff < 0) {
		printf("ipq: fdt fixup cannot find root node\n");
		return;
	}

	ret = ipq_smem_get_socinfo_cpu_type(&cpu_type);
	if (!ret) {
		ret = fdt_setprop(blob, nodeoff, "cpu_type",
				  &cpu_type, sizeof(cpu_type));
		if (ret)
			printf("%s: cannot set cpu type %d\n", __func__, ret);
	} else {
		printf("%s: cannot get socinfo\n", __func__);
	}

	ret = ipq_smem_get_socinfo_version((uint32_t *)&soc_version);
	if (!ret) {
		soc_version_major = SOCINFO_VERSION_MAJOR(soc_version);
		soc_version_minor = SOCINFO_VERSION_MINOR(soc_version);

		ret = fdt_setprop(blob, nodeoff, "soc_version_major",
				  &soc_version_major,
				  sizeof(soc_version_major));
		if (ret)
			printf("%s: cannot set soc_version_major %d\n",
			       __func__, soc_version_major);

		ret = fdt_setprop(blob, nodeoff, "soc_version_minor",
				  &soc_version_minor,
				  sizeof(soc_version_minor));
		if (ret)
			printf("%s: cannot set soc_version_minor %d\n",
			       __func__, soc_version_minor);
	} else {
		printf("%s: cannot get soc version\n", __func__);
	}
	return;
}

void set_mtdids(void)
{
	char mtdids[256];

	if (getenv("mtdids") != NULL) {
		/* mtdids env is already set, nothing to do */
		return;
	}

	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;
	if (sfi->flash_type == SMEM_BOOT_SPI_FLASH) {
		if (get_which_flash_param("rootfs") ||
		    ((sfi->flash_secondary_type == SMEM_BOOT_NAND_FLASH) ||
			(sfi->flash_secondary_type == SMEM_BOOT_QSPI_NAND_FLASH))) {

			snprintf(mtdids, sizeof(mtdids),
				 "nand%d=nand%d,nand%d=" QCA_SPI_NOR_DEVICE,
				 is_spi_nand_available(),
				 is_spi_nand_available(),
				 CONFIG_SPI_FLASH_INFO_IDX);
		} else {

			snprintf(mtdids, sizeof(mtdids), "nand%d="
				QCA_SPI_NOR_DEVICE, CONFIG_SPI_FLASH_INFO_IDX);

		}
		setenv("mtdids", mtdids);
	} else if (((sfi->flash_type == SMEM_BOOT_NAND_FLASH) ||
			(sfi->flash_type == SMEM_BOOT_QSPI_NAND_FLASH))) {

		snprintf(mtdids, sizeof(mtdids), "nand0=nand0");
		setenv("mtdids", mtdids);
	}
}

/*
 * For newer kernel that boot with device tree (3.14+), all of memory is
 * described in the /memory node, including areas that the kernel should not be
 * touching.
 *
 * By default, u-boot will walk the dram bank info and populate the /memory
 * node; here, overwrite this behavior so we describe all of memory instead.
 */
int ft_board_setup(void *blob, bd_t *bd)
{
	u64 memory_start = CONFIG_SYS_SDRAM_BASE;
	u64 memory_size = gd->ram_size;
#ifdef CONFIG_IPQ_FDT_FIXUP
	unsigned long gmac_no;
	char *s;
#endif
	uint32_t flash_type;
	char *mtdparts = NULL;
	char *addparts = NULL;
	char parts_str[4096];
	int len = sizeof(parts_str), ret;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;
	int activepart = 0;
#if defined (CONFIG_IPQ_TINY) && !defined(CONFIG_NAND_FLASH)
	struct flash_node_info nodes[] = {
		{ "n25q128a11", MTD_DEV_TYPE_NAND,
				CONFIG_IPQ_SPI_NOR_INFO_IDX }
		};
#else
	struct flash_node_info nodes[] = {
		{ "qcom,msm-nand", MTD_DEV_TYPE_NAND, 0 },
		{ "qcom,qcom_nand", MTD_DEV_TYPE_NAND, 0 },
		{ "qcom,ebi2-nandc-bam-v1.5.0", MTD_DEV_TYPE_NAND, 0 },
		{ "qcom,ebi2-nandc-bam-v2.1.1", MTD_DEV_TYPE_NAND, 0 },
		{ "qcom,ipq9574-nand", MTD_DEV_TYPE_NAND, 0 },
		{ "qcom,ipq8074-nand", MTD_DEV_TYPE_NAND, 0 },
		{ "qcom,ipq5332-nand", MTD_DEV_TYPE_NAND, 0 },
		{ "spinand,mt29f", MTD_DEV_TYPE_NAND, 1 },
		{ "n25q128a11", MTD_DEV_TYPE_NAND,
				CONFIG_IPQ_SPI_NOR_INFO_IDX },
		{ "micron,n25q128a11", MTD_DEV_TYPE_NAND,
				CONFIG_IPQ_SPI_NOR_INFO_IDX},
		{ "s25fl256s1", MTD_DEV_TYPE_NAND, 1 },
		{ NULL, 0, -1 },	/* Terminator */
	};
#endif
	fdt_fixup_memory_banks(blob, &memory_start, &memory_size, 1);
	ipq_fdt_fixup_version(blob);
#ifndef CONFIG_QCA_APPSBL_DLOAD
	ipq_fdt_dload_disable_fixup(blob);
#endif
	if (((sfi->flash_type == SMEM_BOOT_NAND_FLASH) ||
		(sfi->flash_type == SMEM_BOOT_QSPI_NAND_FLASH))) {
		snprintf(parts_str, sizeof(parts_str), "mtdparts=nand0");
	} else if (sfi->flash_type == SMEM_BOOT_SPI_FLASH) {
		/* Patch NOR block size and density for
		 * generic probe case */
		ipq_fdt_fixup_spi_nor_params(blob);
		snprintf(parts_str,sizeof(parts_str), "mtdparts=" QCA_SPI_NOR_DEVICE);

		if ((sfi->flash_secondary_type == SMEM_BOOT_NAND_FLASH) ||
			(sfi->flash_secondary_type == SMEM_BOOT_QSPI_NAND_FLASH)) {
			if(smem_bootconfig_info() == 0)
				activepart = get_rootfs_active_partition();
			if (!activepart) {
				snprintf(parts_str, sizeof(parts_str),
				"mtdparts=nand0:0x%x@0(rootfs),"
				"0x%x@0x%x(rootfs_1);nand1",
				IPQ_NAND_ROOTFS_SIZE,
				IPQ_NAND_ROOTFS_SIZE, IPQ_NAND_ROOTFS_SIZE);
			} else {
				snprintf(parts_str, sizeof(parts_str),
				"mtdparts=nand0:0x%x@0x%x(rootfs),"
				"0x%x@0(rootfs_1);nand1",IPQ_NAND_ROOTFS_SIZE,
				IPQ_NAND_ROOTFS_SIZE, IPQ_NAND_ROOTFS_SIZE);
			}
		}
	}
	mtdparts = parts_str;
	if (mtdparts) {
		qca_smem_part_to_mtdparts(mtdparts,len);
		if (mtdparts[0] != '\0') {
			addparts = getenv("addmtdparts");
			if (addparts) {
				debug("addmtdparts = %s\n", addparts);
				strlcat(mtdparts, ",", sizeof(parts_str));
				strlcat(mtdparts, addparts, sizeof(parts_str));
			}
			debug("mtdparts = %s\n", mtdparts);
			setenv("mtdparts", mtdparts);
		}

		set_mtdids();
		debug("MTDIDS: %s\n", getenv("mtdids"));
#if defined (CONFIG_IPQ_TINY) && !defined(CONFIG_NAND_FLASH)
		ipq_nor_fdt_fixup(blob, nodes);
#else
		ipq_fdt_fixup_mtdparts(blob, nodes);
#endif
	}

	/* Add "flash_type" to root node of the devicetree*/
	ret = get_current_flash_type(&flash_type);
	if (!ret) {
		ret = fdt_setprop(blob, 0, "flash_type", &flash_type,
				sizeof(flash_type));
		if (ret)
			printf("%s: cannot set flash type %d\n", __func__, ret);
	}
	if (is_atf_enabled()) {
		fdt_fixup_set_qca_cold_reboot_enable(blob);
		fdt_fixup_for_atf(blob);
	}

	dcache_disable();
	ipq_fdt_fixup_socinfo(blob);
#ifdef CONFIG_IPQ_FDT_FIXUP
	s = (getenv("gmacnumber"));
	if (s) {
		strict_strtoul(s, 16, &gmac_no);
		if (gmac_no > 2 && gmac_no < 6)
			ipq40xx_patch_eth_params(blob, gmac_no);
	}
	ipq_fdt_fixup(blob);
	fdt_fixup_flash(blob);
	ipq_fdt_fixup_usb_device_mode(blob);
	fdt_fixup_auto_restart(blob);
	fdt_fixup_sd_ldo_gpios_toggle(blob);
	fdt_fixup_cpr(blob);
	fdt_fixup_cpus_node(blob);
	fdt_low_memory_fixup(blob);
	fdt_fixup_qpic(blob);
	fdt_fixup_qpic_serial_training_offset(blob);
	s = getenv("dload_warm_reset");
	if (s)
		fdt_fixup_set_dload_warm_reset(blob);
	s = getenv("dload_dis");
	if ((s != NULL) && (s[0] != '\0'))
		ipq_fdt_dload_disable_fixup(blob);
	s = getenv("qce_fixed_key");
	if (s)
		fdt_fixup_set_qce_fixed_key(blob);
	s = getenv("bt_debug");
	if (s) {
		fdt_fixup_bt_debug(blob);
	}

#ifdef CONFIG_IPQ_BT_SUPPORT
	fdt_fixup_bt_running(blob);
#endif
	fdt_fixup_sdx65_gpio(blob);
#endif

	/*
	|| This features fixup compressed_art in
	|| dts if its 16M profile build.
	*/
	fdt_fixup_art_format(blob);

#ifdef CONFIG_QCA_MMC
	board_mmc_deinit();
#endif

	fdt_fixup_ethernet(blob);
	return 0;
}

#endif /* CONFIG_OF_BOARD_SETUP */
