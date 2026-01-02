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

#include <common.h>
#include <command.h>
#include <image.h>
#include <nand.h>
#include <errno.h>
#include <asm/arch-qca-common/smem.h>
#include <asm/arch-qca-common/scm.h>
#include <linux/mtd/ubi.h>
#include <part.h>
#include <asm/arch-qca-common/qca_common.h>

#define FUSEPROV_SUCCESS		0x0
#define FUSEPROV_INVALID_HASH		0x09
#define FUSEPROV_SECDAT_LOCK_BLOWN	0xB
#define TZ_BLOW_FUSE_SECDAT		0x20
#define TZ_READ_FUSE_VALUE		0x22
#define MAX_FUSE_ADDR_SIZE		0x8

int do_fuseipq(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
	int ret;
	uint32_t fuse_status = 0;
	struct fuse_blow {
		uint32_t address;
		uint32_t status;
	} fuseip;

	if (argc != 2) {
		printf("No Arguments provided\n");
		printf("Command format: fuseipq <address>\n");
		return 1;
	}

	fuseip.address = simple_strtoul(argv[1], NULL, 16);
	fuseip.status = (uint32_t)&fuse_status;

	ret = qca_scm_fuseipq(SCM_SVC_FUSE, TZ_BLOW_FUSE_SECDAT,
			&fuseip, sizeof(fuseip));

	if (ret)
		printf("%s: Error in QFPROM write (%d)\n",
			__func__, ret);

	if (fuse_status == FUSEPROV_SECDAT_LOCK_BLOWN)
		printf("Fuse already blown\n");
	else if (fuse_status == FUSEPROV_INVALID_HASH)
		printf("Invalid sec.dat\n");
	else if (fuse_status == FUSEPROV_SUCCESS)
		printf("Fuse Blow Success\n");
	else
		printf("Fuse blow failed with err code : 0x%x\n", fuse_status);

	return 0;
}

#ifdef CONFIG_LIST_FUSE
int do_list_fuse(cmd_tbl_t *cmdtp, int flag, int argc,
					char *const argv[])
{
	extern unsigned long fuse_addr[];
	int ret;
	int index;
	struct fuse_payload *fuse = NULL;
	size_t fuse_cnt = FUSE_CNT;

	fuse = malloc(sizeof(struct fuse_payload ) * fuse_cnt);
	if (fuse == NULL) {
		return 1;
	}

	memset(fuse, 0, fuse_cnt * sizeof(struct fuse_payload));

	for (index = 0; index < fuse_cnt; index++) {
		fuse[index].fuse_addr = fuse_addr[index];
	}

	ret = qca_scm_list_fuse(SCM_SVC_FUSE, TZ_READ_FUSE_VALUE, fuse,
			sizeof(struct fuse_payload ) * fuse_cnt);

	printf("Fuse Name\tAddress\t\tValue\n");
	printf("------------------------------------------------\n");

#ifdef CONFIG_ARCH_IPQ9574
	printf("TME_AUTH_EN\t0x%08X\t0x%08X\n", fuse[0].fuse_addr,
			fuse[0].val & 0x80);
	printf("TME_OEM_ID\t0x%08X\t0x%08X\n", fuse[0].fuse_addr,
			fuse[0].val & 0xFFFF0000);
	printf("TME_PRODUCT_ID\t0x%08X\t0x%08X\n", fuse[1].fuse_addr,
			fuse[1].val & 0xFFFF);

	for (index = 2; index < fuse_cnt; index++) {
		printf("TME_MRC_HASH\t0x%08X\t0x%08X\n",
				fuse[index].fuse_addr, fuse[index].val);
	}
#elif CONFIG_ARCH_IPQ5332
	printf("TME_AUTH_EN\t0x%08X\t0x%08X\n", fuse[0].fuse_addr,
			fuse[0].lsb_val & 0x41);
	printf("TME_OEM_ID\t0x%08X\t0x%08X\n", fuse[0].fuse_addr,
			fuse[0].lsb_val & 0xFFFF0000);
	printf("TME_PRODUCT_ID\t0x%08X\t0x%08X\n", fuse[0].fuse_addr + 0x4,
			fuse[0].msb_val & 0xFFFF);

	for (index = 1; index < fuse_cnt; index++) {
		printf("TME_MRC_HASH\t0x%08X\t0x%08X\n",
				fuse[index].fuse_addr, fuse[index].lsb_val);
		printf("TME_MRC_HASH\t0x%08X\t0x%08X\n",
				fuse[index].fuse_addr + 0x4, fuse[index].msb_val);
	}
#endif

	if (ret) {
		printf("Failed to read OEM parameters at Address 0x%X\n", ret);
	}
	free(fuse);
	return 0;
}

U_BOOT_CMD(list_fuse, 1, 0, do_list_fuse,
		"fuse set of QFPROM registers from memory\n",
		"");
#endif

U_BOOT_CMD(fuseipq, 2, 0, do_fuseipq,
		"fuse QFPROM registers from memory\n",
		"fuseipq [address]  - Load fuse(s) and blows in the qfprom\n");
