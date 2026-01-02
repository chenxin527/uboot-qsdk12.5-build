/* Copyright (c) 2015-2017 The Linux Foundation. All rights reserved.
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
#ifndef __MACH_SCM_H
#define __MACH_SCM_H

#define SCM_SVC_BOOT			0x1
#define SCM_SVC_PIL			0x2
#define SCM_SVC_UTIL			0x3
#define SCM_SVC_TZ			0x4
#define SCM_SVC_IO			0x5
#define SCM_SVC_INFO			0x6
#define SCM_SVC_SSD			0x7
#define SCM_SVC_FUSE			0x8
#define SCM_SVC_PWR			0x9
#define SCM_SVC_CRYPTO			0xA
#define SCM_SVC_CP			0xC
#define SCM_SVC_DCVS			0xD
#define SCM_SVC_TZSCHEDULER		0xFC
#define SCM_SVC_WR			0x10
#define SCM_SVC_RD			0x12
#define QFPROM_IS_AUTHENTICATE_CMD	0x7
#define TZBSP_BUILD_VER_QUERY_CMD	0x4
#define SCM_BOOT_ADDR			0x1
#define SCM_FLAG_COLDBOOT_CPU1		0x1
#define SCM_SVC_ID_SHIFT		0xA
#define IS_CALL_AVAIL_CMD		0x1
#define PART_INFO_CMD			0x22
#define GET_SECURE_STATE_CMD		0x4

#ifdef CONFIG_IPQ_BT_SUPPORT
#define SCM_PAS_INIT_IMAGE_CMD		0x1
#define SCM_PAS_AUTH_AND_RESET_CMD	0x5
#define SCM_CMD_OTP  			0x15
#define SCM_SVC_BT_ECO_BIT		0x2
#define SCM_BT_ECO_BIT_TOGGLE_CMD	0x21
#endif

/* scm_v8 */
#define SCM_VAL				0x0
#define SCM_IO_READ			0x1
#define SCM_IO_WRITE			0x2

#define CE_CHN_SWITCH_CMD		0x2

#define SCM_EBUSY		-6
#define SCM_ENOMEM		-5
#define SCM_EOPNOTSUPP		-4
#define SCM_EINVAL_ADDR		-3
#define SCM_EINVAL_ARG		-2
#define SCM_ERROR		-1
#define SCM_INTERRUPTED		 1

/* OWNER IDs */
#define SCM_OWNR_SIP		2
#define SCM_OWNR_QSEE_OS	50
#define SCM_OWNR_TEE_HLOS	51

/* SVC IDs  */
#define SCM_SVC_APP_MGR		1	/* Application service manager */
#define SCM_SVC_LISTENER	2	/* Listener service manager */
#define SCM_SVC_EXTERNAL	3	/* External Image loading */
#define SCM_SVC_MON_SAT		252	/* Monitor SAT test calls */
#define SCM_SVC_TEST_1		253	/* TZ test calls (continued). */
#define SCM_SVC_TEST_0		254	/* TZ test calls */

/* to align the pointer to the (next) page boundary */
#define PAGE_ALIGN(addr) ALIGN(addr, PAGE_SIZE)

/**
 * struct scm_command - one SCM command buffer
 * @len: total available memory for command and response
 * @buf_offset: start of command buffer
 * @resp_hdr_offset: start of response buffer
 * @id: command to be executed
 * @buf: buffer returned from scm_get_command_buffer()
 *
 * An SCM command is laid out in memory as follows:
 *
 *	------------------- <--- struct scm_command
 *	| command header  |
 *	------------------- <--- scm_get_command_buffer()
 *	| command buffer  |
 *	------------------- <--- struct scm_response and
 *	| response header |      scm_command_to_response()
 *	------------------- <--- scm_get_response_buffer()
 *	| response buffer |
 *	-------------------
 *
 * There can be arbitrary padding between the headers and buffers so
 * you should always use the appropriate scm_get_*_buffer() routines
 * to access the buffers in a safe manner.
 */
struct scm_command {
	u32	len;
	u32	buf_offset;
	u32	resp_hdr_offset;
	u32	id;
	u32	buf[0];
};

/**
 * struct scm_response - one SCM response buffer
 * @len: total available memory for response
 * @buf_offset: start of response data relative to start of scm_response
 * @is_complete: indicates if the command has finished processing
 */
struct scm_response {
	u32	len;
	u32	buf_offset;
	u32	is_complete;
};

int scm_init(void);
extern int scm_call(u32 svc_id, u32 cmd_id, const void *cmd_buf, size_t cmd_len,
		void *resp_buf, size_t resp_len);
extern int qca_scm_call(u32 svc_id, u32 cmd_id, void *buf, size_t len);

int qca_scm_dpr(u32, u32, void *, size_t);
int qca_scm_usb_mode_write(u32, u32);
int qca_scm_call_write(u32, u32, u32 *, u32);
int qca_scm_call_read(u32, u32, u32 *, u32*);
long qca_scm_is_feature_available(u32);
int qca_scm_crypto(int, void *, u32);
int qca_scm_clear_key(u32, u32);
int qca_scm_sdi(void);
int qca_scm_dload(u32);
int qca_scm_fuseipq(u32, u32, void *, size_t);
#ifdef CONFIG_LIST_FUSE
int qca_scm_list_fuse(u32, u32, struct fuse_payload *, size_t);
#endif
bool is_scm_armv8(void);
int qca_scm_secure_authenticate(void *cmd_buf, size_t cmd_len);
int qca_scm_part_info(void *cmd_buf, size_t cmd_len);
s32 qca_scm_call_atomic_ver2_32(u32 svc, u32 cmd, u32 arg1, u32 arg2);
int qca_scm_auth_kernel(void *cmd_buf, size_t cmd_len);
int is_scm_sec_auth_available(u32 svc_id, u32 cmd_id);
int qca_scm_get_secure_state(void *buf, size_t len);
#ifdef CONFIG_IPQ_TZT
int qca_scm(u32 svc_id, u32 cmd_id, u32 ownr_id, u32 *addr, u32 len);
#endif
#ifdef CONFIG_IPQ_BT_SUPPORT
int qti_scm_otp(u32 peripheral);
int qti_scm_pas_init_image(u32 peripheral, u32 addr);
int qti_pas_and_auth_reset(u32 peripheral);
int qti_scm_toggle_bt_eco_bit(u32 peripheral, u32 reg_val);
#endif
#define MAX_QCA_SCM_RETS		3
#define MAX_QCA_SCM_ARGS		10
#define SCM_READ_OP			1

/**
 * struct qca_scm_desc
 *  <at> arginfo: Metadata describi`ng the arguments in args[]
 *  <at> args: The array of arguments for the secure syscall
 *  <at> ret: The values returned by the secure syscall
 *  <at> extra_arg_buf: The buffer containing extra arguments
                        (that don't fit in available registers)
 *  <at> x5: The 4rd argument to the secure syscall or physical address of
                extra_arg_buf
 */
struct qca_scm_desc {
	u32 arginfo;
	u32 args[MAX_QCA_SCM_ARGS];
	u32 ret[MAX_QCA_SCM_RETS];

	/* private */
	void *extra_arg_buf;
	u64 x5;
};

#define QCA_SCM_ARGS_IMPL(num, a, b, c, d, e, f, g, h, i, j, ...) (\
			(((a) & 0xff) << 4) | \
			(((b) & 0xff) << 6) | \
			(((c) & 0xff) << 8) | \
			(((d) & 0xff) << 10) | \
			(((e) & 0xff) << 12) | \
			(((f) & 0xff) << 14) | \
			(((g) & 0xff) << 16) | \
			(((h) & 0xff) << 18) | \
			(((i) & 0xff) << 20) | \
			(((j) & 0xff) << 22) | \
			(num & 0xffff))

#define QCA_SCM_ARGS(...) QCA_SCM_ARGS_IMPL(__VA_ARGS__, \
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

#define QCA_SCM_SIP_FNID(s, c) (((((s) & 0xFF) << 8) | \
			((c) & 0xFF)) | 0x02000000)

#define QCA_SCM_FNID(s, c, o) (((((s) & 0xFF) << 8) | \
			((c) & 0xFF)) | (((o) & 0xFF) << 24))

#define QCA_SMC_ATOMIC_MASK            0x80000000

#define QCA_MAX_ARG_LEN	5

typedef struct {
	u64 reg_x0;
	u64 reg_x1;
	u64 reg_x2;
	u64 reg_x3;
	u64 reg_x4;
	u64 reg_x5;
	u64 reg_x6;
	u64 reg_x7;
	u64 reg_x8;
	u64 kernel_start;
} kernel_params;

#define SCM_ARCH64_SWITCH_ID	0x1
#define QCA_IS_CALL_AVAIL_CMD	0x1
#define SCM_EL1SWITCH_CMD_ID	0xf

#define SCM_NULL_OP 0
#define	SCM_RW_OP   2
#define	SCM_BUF_VAL 3

#ifndef CONFIG_DISABLE_KERNEL64
void __attribute__ ((noreturn)) jump_kernel64(void *kernel_entry,
		void *fdt_addr);
#endif

#ifndef CONFIG_CMD_DISABLE_EXECTZT
void __attribute__ ((noreturn)) execute_tzt(void *entry_addr);
#endif
#endif
