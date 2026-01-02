/*
 * Copyright (c) 2016-2021 The Linux Foundation. All rights reserved.
 *
 * Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
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
#include <asm/arch-qca-common/scm.h>

int do_dpr(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
	int ret;
	char *loadaddr, *filesize;
	uint32_t dpr_status = 0;
	struct dpr {
		uint32_t address;
		uint32_t size;
		uint32_t status;
	} dpr;

	if (argc == 2 || argc > 3) {
		return CMD_RET_USAGE;
	}

	if (argc == 3){
		dpr.address = simple_strtoul(argv[1], NULL, 16);
		dpr.size = simple_strtoul(argv[2], NULL, 16);
	} else {
		loadaddr = getenv("fileaddr");
		filesize = getenv("filesize");

		if (loadaddr == NULL || filesize == NULL) {
			printf("No Arguments provided\n");
			printf("Command format: dpr_execute <fileaddr>"
				"<filesize>\n");
			return CMD_RET_USAGE;
		}
		if (loadaddr != NULL)
			dpr.address = simple_strtoul(loadaddr, NULL, 16);
		if (filesize != NULL)
			dpr.size = simple_strtoul(filesize, NULL, 16);
	}

	dpr.status = (uint32_t)&dpr_status;

	ret = qca_scm_dpr(SCM_SVC_FUSE, TME_DPR_PROCESSING,
			&dpr, sizeof(dpr));

	if (ret || dpr_status){
		printf("%s: Error in DPR Processing (%d, %d)\n",
			__func__, ret, dpr_status);
	} else {
		printf("DPR Process Successful\n");
	}
	return ret;
}

U_BOOT_CMD(dpr_execute, 3, 0, do_dpr,
		"Debug Policy Request processing\n",
		"dpr_execute [fileaddr] [filesize] - Processing dpr\n");

