/*
 * Copyright (c) 2015-2019 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include <common.h>
#include <command.h>
#include <asm/arch-qca-common/scm.h>

#define PRINT_BUF_LEN		0x400
#define MDT_SIZE 0x1B88
/* Region for loading test application */
#define TZT_LOAD_ADDR		0x49B00000
/* Reserved size for application */
#define TZT_LOAD_SIZE		0x00200000

#define LOAD_TZTESTEXEC_IMG_ID	0x0
#define REGION_NOTIFICATION_ID	0x5
#define REGISTER_LOG_BUFFER_ID	0x6
#define SEC_TEST_ID		0x2C
#define XPU_TEST_ID		0x80100004

static int tzt_loaded;

struct xpu_tzt {
	u64 test_id;
	u64 num_param;
	u64 param1;
	u64 param2;
	u64 param3;
	u64 param4;
	u64 param5;
	u64 param6;
	u64 param7;
	u64 param8;
	u64 param9;
	u64 param10;
};

struct resp {
	u64 status;
	u64 index;
	u64 total_tests;
};

struct log_buff {
	u16 wrap;
	u16 log_pos;
	char buffer[PRINT_BUF_LEN];
};

static int run_xpu_config_tst(void)
{
	int i = 0;
	struct xpu_tzt xputzt = {0};
	struct resp resp_buf __aligned(CONFIG_SYS_CACHELINE_SIZE);
	u32 passed = 0, failed = 0;
	u32 args_log[MAX_QCA_SCM_ARGS + 1];
	u32 args[MAX_QCA_SCM_ARGS + 1];
	struct log_buff logbuff;

	xputzt.test_id = XPU_TEST_ID;
	xputzt.num_param = 0x3;
	xputzt.param1 = 0;
	xputzt.param2 = 0;
	xputzt.param3 = (u64)((u32)&resp_buf);

	args_log[0] = QCA_SCM_ARGS(2, SCM_IO_WRITE);
	args_log[1] = (u32)&logbuff;
	args_log[2] = PRINT_BUF_LEN;

	args[0] = QCA_SCM_ARGS(2, SCM_IO_WRITE);
	args[1] = (u32)&xputzt;
	args[2] = sizeof(struct xpu_tzt);

	printf("****** xPU Configuration Validation Test Begin ******\n");

	do {
		qca_scm(SCM_SVC_APP_MGR, REGISTER_LOG_BUFFER_ID,
			SCM_OWNR_QSEE_OS, args_log, 3);

		xputzt.param2 = i++;
		qca_scm(SCM_SVC_TEST_1, SEC_TEST_ID, SCM_OWNR_SIP, args, 3);

		invalidate_dcache_range((unsigned long)&resp_buf,
					(unsigned long)&resp_buf +
					CONFIG_SYS_CACHELINE_SIZE);

		if (resp_buf.status == 0)
			passed++;
		else if (resp_buf.status == 1)
			failed++;

		logbuff.buffer[logbuff.log_pos] = '\0';
		printf("%s", logbuff.buffer);

	} while (i < resp_buf.total_tests);

	printf("******************************************************\n");
	printf("Test Result: Passed %u Failed %u (total %u)\n",
	       passed, failed, (u32)resp_buf.total_tests);
	printf("****** xPU Configuration Validation Test End ******\n");
	return 0;
}

static int do_tzt(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
	char *cmd;
	u32 img_addr;
	u32 img_size;
	u32 args[MAX_QCA_SCM_ARGS + 1];
	int ret;

	/* at least two arguments should be there */
	if (argc < 2)
		return -1;

	cmd = argv[1];
	if (strcmp(cmd, "load") == 0) {
		if (argc < 4)
			return -1;

		img_addr = simple_strtoul(argv[2], NULL, 16);
		img_size = simple_strtoul(argv[3], NULL, 16);

		args[0] = QCA_SCM_ARGS(2, SCM_IO_WRITE);
		args[1] = TZT_LOAD_ADDR;
		args[2] = TZT_LOAD_SIZE;
		ret = qca_scm(SCM_SVC_APP_MGR, REGION_NOTIFICATION_ID,
			SCM_OWNR_QSEE_OS, args, 3);
		if (ret) {
			printf("tzt load failed ret = %d\n", ret);
			return -1;
		}

		args[0] = QCA_SCM_ARGS(3);
		args[1] = MDT_SIZE;
		args[2] = img_size - MDT_SIZE;
		args[3] = img_addr;
		ret = qca_scm(SCM_SVC_EXTERNAL, LOAD_TZTESTEXEC_IMG_ID,
			SCM_OWNR_QSEE_OS, args, 4);
		if (ret) {
			printf("tzt load failed ret = %d\n", ret);
			return -1;
		}

		tzt_loaded = 1;
		return 0;
	}

	if (!tzt_loaded) {
		printf("load tzt image before running test cases\n");
		return -1;
	}

	if (strcmp(cmd, "xpu") == 0)
		return run_xpu_config_tst();

	return -1;
}

U_BOOT_CMD(tzt, 4, 0, do_tzt,
	   "load and run tzt\n",
	   "tzt load address size - To load tzt image\n"
	   "tzt xpu - To run xpu config test\n");
