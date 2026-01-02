/*
 * Copyright (c) 2017-2018, The Linux Foundation. All rights reserved.
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
#include <malloc.h>
#include <asm/psci.h>
#include <cli.h>
#include <console.h>
#include <linux/linkage.h>

DECLARE_GLOBAL_DATA_PTR;

#define SECONDARY_CORE_STACKSZ (8 * 1024)
#define CPU_POWER_DOWN (1 << 16)

extern void *globl_core_array;

struct cpu_entry_arg {
	void *stack_ptr;
	volatile void *gd_ptr;
	void *arg_ptr;
	int  cpu_up;
	int cmd_complete;
	int cmd_result;
	void *stack_top_ptr;
};

extern void secondary_cpu_init(void);
extern void bring_secondary_core_down(int);

struct cpu_entry_arg core[NR_CPUS - 1];

asmlinkage void secondary_core_entry(char *argv, int *cmd_complete,
					int *cmd_result)
{
	unsigned int state = 0;

	/* Update here as ncessary - secondary entry point */
	*cmd_result = cli_simple_run_command(argv, CMD_FLAG_SEC_CORE);
	*cmd_complete = 1;

	state = CPU_POWER_DOWN;
	bring_secondary_core_down(state);
}

static void disable_console(void)
{
	gd->flags |= GD_FLG_SILENT | GD_FLG_DISABLE_CONSOLE;
}

static void enable_console(void)
{
	gd->flags &= ~(GD_FLG_SILENT | GD_FLG_DISABLE_CONSOLE);
}

int do_runmulticore(cmd_tbl_t *cmdtp,
			   int flag, int argc, char *const argv[])
{
	int j;
	int i;
	int ret;
	int delay = 0;
	int core_status = 0;
	int core_on_status = 0;
	char *ptr = NULL;

	if ((argc <= 1) || (argc > 4))
		return CMD_RET_USAGE;

	dcache_disable();

	/* Setting up stack for secondary cores */
	memset(core, 0, sizeof(core));

	globl_core_array = core;
	for (i = 1; i < argc; i++) {
		ptr = malloc(SECONDARY_CORE_STACKSZ);
		if (NULL == ptr) {
			j = i - 1;
			while (j >= 0) {
				free(core[i - 1].stack_ptr);
				j--;
			}
			printf("Memory allocation failure\n");
			return CMD_RET_FAILURE;
		}
		/* 0xf0 is the padding length */
		core[i - 1].stack_top_ptr = ptr;
		core[i - 1].stack_ptr = (ptr + (SECONDARY_CORE_STACKSZ) - 0xf0);

		core[i - 1].cpu_up = 0;
		core[i - 1].cmd_complete = 0;
		core[i - 1].cmd_result = -1;
		core[i - 1].gd_ptr = gd;
		core[i - 1].arg_ptr = argv[i];
	}

	/* Bringing up the secondary cores */
	for (i = 1; i < argc; i++) {
		printf("Scheduling Core %d\n", i);
		delay = 0;
		disable_console();
		ret = bring_sec_core_up(i, (unsigned int)secondary_cpu_init,
				(unsigned int)&(core[i - 1]));
		if (ret) {
			panic("Some problem to getting core %d up\n", i);
		}
		while ((delay < 5) && (!(core[i - 1].cpu_up))) {
			mdelay(1000);
			delay++;
		}
		if (!(core[i - 1].cpu_up)) {
			panic("Can't bringup core %d\n",i);
		}
		enable_console();

		core_status |= (BIT(i - 1));
		core_on_status |= (BIT(i - 1));
	}

	/* Waiting for secondary cores to complete the task */
	while (core_status) {
		for (i = 1; i < argc; i++) {
			if ((core_status & (BIT(i - 1))) &&
					(core[i - 1].cmd_complete)) {
				printf("Command on core %d is %s\n", i,
					core[i - 1].cmd_complete ?
					((core[i - 1].cmd_result == -1) ?
					"FAIL" : "PASS"):
					"INCOMPLETE");
				core_status &= (~BIT((i - 1)));
			}
		}
		if (ctrlc()) {
			run_command("reset", 0);
		}
	}

	for (i = 1; (core_status && (i < argc)); i++) {
		if (core_status & (BIT(i - 1))) {
			printf("Command on core %d is %s\n", i,
				core[i - 1].cmd_complete ?
				((core[i - 1].cmd_result == -1) ?
				 "FAIL" : "PASS"): "INCOMPLETE");
		}
	}

	/* Waiting for cores to powerdown */
	delay = 0;
	while (core_on_status) {
		for (i = 1; i < argc; i++) {
			if (core_on_status & (BIT(i - 1))) {
				if (is_secondary_core_off(i) == 1) {
					printf("core %d powered off\n", i);
					core_on_status &= (~BIT((i - 1)));
				}
			}
		}
		mdelay(1000);
		delay++;
		if (delay > 5)
			panic("Some cores can't be powered off\n");
	}

	/* Free up all the stack */
	for (i = 1; i < argc; i++) {
		free(core[i - 1].stack_top_ptr);
	}

	printf("Status:\n");
	for (i = 1; i < argc; i++) {
		printf("Core %d: %s\n", i,
				core[i - 1].cmd_complete ?
				((core[i - 1].cmd_result == -1) ?
				 "FAIL" : "PASS"): "INCOMPLETE");
	}

	invalidate_dcache_all();
	dcache_enable();

	return CMD_RET_SUCCESS;
}

U_BOOT_CMD(runmulticore, 4, 0, do_runmulticore,
	   "Enable and schedule secondary cores",
	   "runmulticore <\"command to core1\"> [core2 core3 ...]");
