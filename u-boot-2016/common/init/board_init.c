/*
 * Code shared between SPL and U-Boot proper
 *
 * Copyright (c) 2015 Google, Inc
 * Written by Simon Glass <sjg@chromium.org>
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */

#include <common.h>

DECLARE_GLOBAL_DATA_PTR;
#define STACK_MARKER_LEN 32

/*
 * It isn't trivial to figure out whether memcpy() exists. The arch-specific
 * memcpy() is not normally available in SPL due to code size.
 */
#if !defined(CONFIG_SPL_BUILD) || \
		(defined(CONFIG_SPL_LIBGENERIC_SUPPORT) && \
		!defined(CONFIG_USE_ARCH_MEMSET))
#define _USE_MEMCPY
#endif

/* Unfortunately x86 can't compile this code as gd cannot be assigned */
#ifndef CONFIG_X86
__weak void arch_setup_gd(struct global_data *gd_ptr)
{
	gd = gd_ptr;
}
#endif /* !CONFIG_X86 */

ulong board_init_f_mem(ulong top)
{
	struct global_data *gd_ptr;
#ifndef _USE_MEMCPY
	int *ptr;
#endif

	/* Leave space for the stack we are running with now */
	top -= 0x40;

	top -= GENERATED_GBL_DATA_SIZE;
	gd_ptr = (struct global_data *)top;
#ifdef _USE_MEMCPY
	memset(gd_ptr, '\0', sizeof(*gd));
#else
	for (ptr = (int *)gd_ptr; ptr < (int *)(gd_ptr + 1); )
		*ptr++ = 0;
#endif
	arch_setup_gd(gd_ptr);

#if defined(CONFIG_SYS_MALLOC_F)
	top -= CONFIG_SYS_MALLOC_F_LEN;
	gd->malloc_base = top;
#endif

	top -= STACK_MARKER_LEN;

	return top;
}
