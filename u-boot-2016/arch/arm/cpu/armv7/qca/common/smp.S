/* Copyright (c) 2017, The Linux Foundation. All rights reserved.
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

#include <asm/system.h>
#include <linux/linkage.h>

ENTRY(ak_secondary_cpu_reinit)
ENTRY(dk_secondary_cpu_reinit)
        mrc     p15, 0, r0, c0, c0, 5   /* read MPIDR */
	and     r1, r0, #0xf          /* return CPU ID in cluster */
	sub	r0, r1, #1
	/* Now r1 has the cpu number,
	 *  this will serve as index to "struct cpu_entry_arg"
         * struct cpu_entry_arg {
	 * void *stack_ptr;       +0 1c   38 54
	 * volatile void *gd_ptr; +4 20   3c
	 * void *arg_ptr;         +8 24   40
	 * int  cpu_up;           +0xc 28 44
	 * int cmd_complete;      +0x10 2c 48
	 * int cmd_result;        +0x14 30 4c
	 * void *stack_top_ptr;   +0x18 34 50
	 *                         +0x1c (next entry in core[])
	 * };
         */
	ldr r4, =globl_core_array
	mov r3, #0x1c
	mul r2, r0, r3
	ldr r0, [r4]
	add r0, r0, r2
	/* For us r0 has the arg structure pointer
		struct cpu_entry_arg {
		        void *stack_ptr;
			void *gd_ptr;
			void *arg_ptr;
			int  cpu_up;
			int cmd_complete;
			int cmd_result;
		};
	*/
	ldr sp, [r0] /* stack_ptr */
	bic     sp, sp, #7 /* 8-byte alignment required for stack */
	/* gd address is always in r9, but if u-boot changes Tomorrow,
	 * we have to change here. Note :- --> ARM: use r9 for gd
	*/
	ldr r9, [r0, #0x4]
	/* store success in cpu_up */
	mov r3, #1
	str r3, [r0, #0xc]
	add r1, r0, #0x10
	add r2, r0, #0x14
	ldr r0, [r0, #0x8]
	bl secondary_core_entry
self_reloop:
	b self_reloop
ENDPROC(ak_secondary_cpu_reinit)
ENDPROC(dk_secondary_cpu_reinit)

ENTRY(dk_secondary_cpu_init)
ENTRY(ak_secondary_cpu_init)
        mrc     p15, 0, r0, c0, c0, 5   /* read MPIDR */
        and     r1, r0, #0xf          /* return CPU ID in cluster */
	sub	r0, r1, #1
	/* Now r1 has the cpu number,
	 *  this will serve as index to "struct cpu_entry_arg"
         * struct cpu_entry_arg {
	 * void *stack_ptr;       +0 1c   38 54
	 * volatile void *gd_ptr; +4 20   3c
	 * void *arg_ptr;         +8 24   40
	 * int  cpu_up;           +0xc 28 44
	 * int cmd_complete;      +0x10 2c 48
	 * int cmd_result;        +0x14 30 4c
	 * void *stack_top_ptr;   +0x18 34 50
	 *                         +0x1c (next entry in core[])
	 * };
         */
	ldr r4, =globl_core_array
	mov r3, #0x1c
	mul r2, r0, r3
	ldr r0, [r4]
	add r0, r0, r2
ENTRY(secondary_cpu_init)
	/* For us r0 has the arg structure pointer
		struct cpu_entry_arg {
		        void *stack_ptr;
			void *gd_ptr;
			void *arg_ptr;
			int  cpu_up;
			int cmd_complete;
			int cmd_result;
		};
	*/
	ldr sp, [r0] /* stack_ptr */
	bic     sp, sp, #7 /* 8-byte alignment required for stack */
	stmfd sp!, {r0}

	/*
	 * disable interrupts (FIQ and IRQ), also set the cpu to SVC32 mode
	 */
	mrs	r0, cpsr
	bic	r0, r0, #0x1f		@ clear all mode bits
	orr	r0, r0, #0x13		@ set SVC mode
	orr	r0, r0, #0xc0		@ disable FIQ and IRQ
	msr	cpsr,r0

	/* Enable barrier instructions */
	mrc p15, 0, r0, c1, c0, 0	@Read SCTLR to r0
	orr r0, r0, #0x20		@set the cp15 barrier enable bit
	mcr p15, 0, r0, c1, c0, 0	@write back to SCTLR

        /* Vector address setup - going to be same as core0 for secondary cpus */
        mrc p15, 0, r0, c1, c0, 0   @ Read CP15 SCTLR Register
        bic r0, #CR_V               @ V = 0
        mcr p15, 0, r0, c1, c0, 0   @ Write CP15 SCTLR Register

        /* Set vector address in CP15 VBAR register */
        ldr r0, =_start
        mcr p15, 0, r0, c12, c0, 0  @Set VBAR

	bl cpu_init_cp15

	ldmfd sp!, {r0}

	/* gd address is always in r9, but if u-boot changes Tomorrow,
	 * we have to change here. Note :- --> ARM: use r9 for gd
	*/
	ldr r9, [r0, #0x4]
	/* store success in cpu_up */
	mov r3, #1
	str r3, [r0, #0xc]
	add r1, r0, #0x10
	add r2, r0, #0x14
	ldr r0, [r0, #0x8]

	bl secondary_core_entry
self_loop:
	b self_loop
ENDPROC(secondary_cpu_init)
ENDPROC(ak_secondary_cpu_init)
ENDPROC(dk_secondary_cpu_init)

ENTRY(send_event)
	dsb
	sev
	mov pc, lr
ENDPROC(send_event)

ENTRY(wait_event)
	dsb
	wfe
	dsb
	bx r0
ENDPROC(wait_event)

ENTRY(get_cpu_id)
	mrc	p15, 0, r0, c0, c0, 5	/* read MPIDR */
	and	r0, r0, #0xf		/* return CPU ID in cluster */
	bx	lr
ENDPROC(get_cpu_id)

.globl globl_core_array
globl_core_array:
        .word 0
