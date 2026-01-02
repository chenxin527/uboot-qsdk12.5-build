/*
 * Copyright (c) 2018 The Linux Foundation. All rights reserved.
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
#include <asm/arch-qca-common/smem.h>

#define PRIMARY_PARTITION	1
#define SECONDARY_PARTITION	2

extern int qca_scm_part_info(void *cmd_buf, size_t cmd_len);

int is_sec_boot_enabled(void)
{
	int ret;
	char buf;

	ret = qca_scm_call(SCM_SVC_FUSE, QFPROM_IS_AUTHENTICATE_CMD, &buf,
								sizeof(char));

	if (ret) {
		printf("%s: scm call failed. ret = %d\n", __func__, ret);
		return -1;
	}
	else if (buf == 1) {
		printf("secure boot fuse is enabled\n");
		return 1;
	}
	else {
		printf("secure boot fuse is not enabled\n");
		return 0;
	}
}

static int do_is_sec_boot_enabled(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
	if (is_sec_boot_enabled() >= 0)
		return CMD_RET_SUCCESS;
	else
		return CMD_RET_FAILURE;
}

U_BOOT_CMD(is_sec_boot_enabled, 1, 0, do_is_sec_boot_enabled,
		"check secure boot fuse is enabled or not\n",
		"is_sec_boot_enabled - check secure boot fuse is enabled or not\n");


static int do_secure_authenticate(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
	int ret;
#ifdef CONFIG_VERSION_ROLLBACK_PARTITION_INFO
	int part = PRIMARY_PARTITION;
#endif

	struct cmd_buf {
		unsigned long type;
		unsigned long size;
		unsigned long addr;
	} cmd_buf;

	if (argc != 4) {
		printf("command usage: secure_authenticate <sw_id> <img_addr> <img_size>\n");
		return CMD_RET_FAILURE;
	}

	ret = is_scm_sec_auth_available(SCM_SVC_BOOT, SCM_CMD_SEC_AUTH);
	if (ret <= 0) {
		printf("secure authentication scm call is not supported. ret = %d\n", ret);
		return CMD_RET_SUCCESS;
	}

	cmd_buf.type = simple_strtoul(argv[1], NULL, 16);
	cmd_buf.addr = simple_strtoul(argv[2], NULL, 16);
	cmd_buf.size = simple_strtoul(argv[3], NULL, 16);

#ifdef CONFIG_VERSION_ROLLBACK_PARTITION_INFO
	if (smem_bootconfig_info() == 0){
		ret = get_rootfs_active_partition();
		if (ret){
			part = SECONDARY_PARTITION;
		}
	}
	ret = qca_scm_part_info(&part, sizeof(part));
	if (ret) {
		printf(" Partition info authentication failed \n");
		BUG();
	}
#endif

	ret = qca_scm_secure_authenticate(&cmd_buf, sizeof(cmd_buf));
	if (ret) {
		printf("secure image authentication failed. ret = %d\n", ret);
		return CMD_RET_FAILURE;
	}
	else {
		printf("secure image authentication success\n");
		return CMD_RET_SUCCESS;
	}
}

U_BOOT_CMD(secure_authenticate, 4, 0, do_secure_authenticate,
		"authenticate the signed image\n",
		"secure_authenticate <sw_id> <img_addr> <img_size>\n"
		"	- authenticate the signed image\n");
