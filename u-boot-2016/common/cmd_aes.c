/*
 * Copyright (C) 2014 Marek Vasut <marex@denx.de>
 *
 * Command for en/de-crypting block of memory with AES-128-CBC cipher.
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */

#include <common.h>
#include <command.h>
#include <environment.h>
#include <aes.h>
#include <malloc.h>
#include <asm/byteorder.h>
#include <linux/compiler.h>
#include <asm/arch-qca-common/scm.h>
#include <errno.h>

DECLARE_GLOBAL_DATA_PTR;

#ifdef CONFIG_CMD_AES_256
enum tz_crypto_service_aes_cmd_t {
	TZ_CRYPTO_SERVICE_AES_ENC_ID = 0x7,
	TZ_CRYPTO_SERVICE_AES_DEC_ID = 0x8,
#ifdef CONFIG_IPQ_DERIVE_KEY
	TZ_CRYPTO_SERVICE_AES_DERIVE_KEY_ID = 0x9,
	TZ_CRYPTO_SERVICE_AES_DERIVE_128_KEY_ID = 0xE,
	TZ_CRYPTO_SERVICE_AES_CLEAR_KEY_ID = 0xA,
#endif
};

enum tz_crypto_service_aes_type_t {
	TZ_CRYPTO_SERVICE_AES_SHK = 0x1,
	TZ_CRYPTO_SERVICE_AES_PHK = 0x2,
	TZ_CRYPTO_SERVICE_AES_TYPE_MAX,

};

enum tz_crypto_service_aes_mode_t {
       TZ_CRYPTO_SERVICE_AES_ECB = 0x0,
       TZ_CRYPTO_SERVICE_AES_CBC = 0x1,
	TZ_CRYPTO_SERVICE_AES_MODE_MAX,
};

#ifndef CONFIG_IPQ_DERIVE_KEY
struct crypto_aes_req_data_t {
	uint64_t type;
	uint64_t mode;
        uint64_t req_buf;
        uint64_t req_len;
        uint64_t ivdata;
        uint64_t iv_len;
        uint64_t resp_buf;
        uint64_t resp_len;
};
#else
#define MAX_CONTEXT_BUFFER_LEN_V1	64
#define MAX_CONTEXT_BUFFER_LEN_V2	128
#define DEFAULT_POLICY_DESTINATION	0
#define DEFAULT_KEY_TYPE		2
struct crypto_aes_operation_policy {
	uint32_t operations;
	uint32_t algorithm;
};

struct crypto_aes_hwkey_policy  {
	struct crypto_aes_operation_policy op_policy;
	uint32_t kdf_depth;
	uint32_t permissions;
	uint32_t key_type;
	uint32_t destination;
};

struct crypto_aes_hwkey_bindings_v1 {
	uint32_t bindings;
	uint32_t context_len;
	uint8_t context[MAX_CONTEXT_BUFFER_LEN_V1];
};

struct crypto_aes_derive_key_cmd_t_v1 {
	struct crypto_aes_hwkey_policy policy;
	struct crypto_aes_hwkey_bindings_v1 hw_key_bindings;
	uint32_t source;
	uint64_t mixing_key;
	uint64_t key;
};

struct crypto_aes_hwkey_bindings_v2 {
	uint32_t bindings;
	uint32_t context_len;
	uint8_t context[MAX_CONTEXT_BUFFER_LEN_V2];
};

struct crypto_aes_derive_key_cmd_t_v2 {
	struct crypto_aes_hwkey_policy policy;
	struct crypto_aes_hwkey_bindings_v2 hw_key_bindings;
	uint32_t source;
	uint64_t mixing_key;
	uint64_t key;
};

struct crypto_aes_req_data_t {
	uint64_t key_handle;
	uint64_t type;
	uint64_t mode;
	uint64_t req_buf;
	uint64_t req_len;
	uint64_t ivdata;
	uint64_t iv_len;
	uint64_t resp_buf;
	uint64_t resp_len;
};

unsigned char toBinary(char c)
{
	if (c >= '0' && c <= '9')
		return c - '0';

	return (c - 'a') + 10;
}
/**
 * do_derive_aes_256_key() - Handle the "derive_key" command-line command
 * @cmdtp:	Command data struct pointer
 * @flag:	Command flag
 * @argc:	Command-line argument count
 * @argv:	Array of command-line arguments
 *
 * Returns zero on success, CMD_RET_USAGE in case of misuse and negative
 * on error.
 */
static int do_derive_aes_256_key(cmd_tbl_t *cmdtp, int flag,
				 int argc, char *const argv[])
{
	struct crypto_aes_derive_key_cmd_t_v1 *req_ptr = NULL;
	int ret = CMD_RET_USAGE;
	uintptr_t *key_handle = NULL;
	uint8_t *context_buf = NULL;
	int context_len = 0;
	int i = 0, j = 0;

	if (argc != 5)
		return ret;
	context_buf = (uint8_t *)simple_strtoul(argv[3], NULL, 16);;
	context_len = simple_strtoul(argv[4], NULL, 16);
	if (context_len > MAX_CONTEXT_BUFFER_LEN_V1) {
		printf("Error: context length should be less than %d\n",
					MAX_CONTEXT_BUFFER_LEN_V1);
		return ret;
	}
	key_handle = (uintptr_t *)memalign(ARCH_DMA_MINALIGN, sizeof(uint64_t));
	req_ptr = (struct crypto_aes_derive_key_cmd_t_v1 *)memalign(
			ARCH_DMA_MINALIGN, sizeof(struct crypto_aes_derive_key_cmd_t_v1));
	if (!req_ptr) {
		printf("Error allocating memory for key handle request buf");
		return -ENOMEM;
	}

	req_ptr->policy.key_type = DEFAULT_KEY_TYPE;
	req_ptr->policy.destination = DEFAULT_POLICY_DESTINATION;
	req_ptr->source = simple_strtoul(argv[1], NULL, 16);
	req_ptr->hw_key_bindings.bindings = simple_strtoul(argv[2], NULL, 16);
	req_ptr->key = (uintptr_t) key_handle;
	req_ptr->mixing_key = 0;
	req_ptr->hw_key_bindings.context_len = context_len;

	while (i < context_len) {
		req_ptr->hw_key_bindings.context[j++] = context_buf[i++];
	}
	ret = qca_scm_crypto(TZ_CRYPTO_SERVICE_AES_DERIVE_KEY_ID,
		(void *)req_ptr, sizeof(struct crypto_aes_derive_key_cmd_t_v1));
	if (ret)
		printf("Scm call failed with error code: %d\n", ret);
	else
		printf("Key handle is %u\n", (unsigned int)*key_handle);

	if (key_handle)
		free(key_handle);
	if (req_ptr)
		free(req_ptr);

	return ret;
}

/***************************************************/
U_BOOT_CMD(
	derive_aes_256_key, 5, 1, do_derive_aes_256_key,
	"Derive AES 256 key before encrypt/decrypt in TME-L based systems",
	"Key Derivation: derive_aes_256_key <source_data> <bindings_data>"
	"<context_data address> <context data len>"
);

/**
 * do_derive_aes_256_max_ctxt_key() - Handle the "derive_key" command-line
 *                                    command for 128 byte context
 * @cmdtp:      Command data struct pointer
 * @flag:       Command flag
 * @argc:       Command-line argument count
 * @argv:       Array of command-line arguments
 *
 * Returns zero on success, CMD_RET_USAGE in case of misuse and negative
 * on error.
 */
static int do_derive_aes_256_max_ctxt_key(cmd_tbl_t *cmdtp, int flag,
					  int argc, char *const argv[])
{
	struct crypto_aes_derive_key_cmd_t_v2 *req_ptr = NULL;
	int ret = CMD_RET_USAGE;
	uintptr_t *key_handle = NULL;
	uint8_t *context_buf = NULL;
	int context_len = 0;
	int i = 0, j = 0;

	if (argc != 5)
		return ret;

	ret = is_scm_sec_auth_available(SCM_SVC_CRYPTO,
			TZ_CRYPTO_SERVICE_AES_DERIVE_128_KEY_ID);
	if (ret <= 0) {
		printf("Aes 256 Max context key derivation"
			"scm call is not supported. ret = %d\n", ret);
		return CMD_RET_SUCCESS;
	}

	context_buf = (uint8_t *)simple_strtoul(argv[3], NULL, 16);
	context_len = simple_strtoul(argv[4], NULL, 16);
	if (context_len > MAX_CONTEXT_BUFFER_LEN_V2) {
		printf("Error: context length should be less than %d\n",
			MAX_CONTEXT_BUFFER_LEN_V2);
		return ret;
	}
	key_handle = (uintptr_t *)memalign(ARCH_DMA_MINALIGN, sizeof(uint64_t));
	req_ptr = (struct crypto_aes_derive_key_cmd_t_v2 *)memalign(ARCH_DMA_MINALIGN,
				sizeof(struct crypto_aes_derive_key_cmd_t_v2));
	if (!req_ptr) {
		printf("Error allocating memory for key handle request buf");
		return -ENOMEM;
	}

	req_ptr->policy.key_type = DEFAULT_KEY_TYPE;
	req_ptr->policy.destination = DEFAULT_POLICY_DESTINATION;
	req_ptr->source = simple_strtoul(argv[1], NULL, 16);
	req_ptr->hw_key_bindings.bindings = simple_strtoul(argv[2], NULL, 16);
	req_ptr->key = (uintptr_t) key_handle;
	req_ptr->mixing_key = 0;
	req_ptr->hw_key_bindings.context_len = context_len;

	while (i < context_len) {
		req_ptr->hw_key_bindings.context[j++] = context_buf[i++];
	}

	ret = qca_scm_crypto(TZ_CRYPTO_SERVICE_AES_DERIVE_128_KEY_ID,
		(void *)req_ptr, sizeof(struct crypto_aes_derive_key_cmd_t_v2));
	if (ret)
		printf("Scm call failed with error code: %d\n", ret);
	else
		printf("Key handle is %u\n", (unsigned int)*key_handle);

	if (key_handle)
		free(key_handle);
	if (req_ptr)
		free(req_ptr);

	return ret;
}


/***************************************************/
U_BOOT_CMD(
        derive_aes_256_max_ctxt_key, 5, 1, do_derive_aes_256_max_ctxt_key,
        "Derive AES 256 key with 128 byte context before"
	"encrypt/decrypt in TME-L based systems",
        "Key Derivation: derive_aes_256_max_ctxt_key <source_data>"
        "<bindings_data> <context_data address> <context data len>"
);

/**
 * do_clear_aes_key() - Handle the "clear_key" command-line command
 *
 * @cmdtp:      Command data struct pointer
 * @flag:       Command flag
 * @argc:       Command-line argument count
 * @argv:       Array of command-line arguments
 *
 * Returns zero on success, CMD_RET_USAGE in case of misuse and negative
 * on error.
 */

static int do_clear_aes_key(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
	int ret;
	uint32_t key_handle;

	if (argc != 2) {
		return CMD_RET_USAGE;
	}

	key_handle = simple_strtoul(argv[1], NULL, 10);

	ret = qca_scm_clear_key(key_handle, TZ_CRYPTO_SERVICE_AES_CLEAR_KEY_ID);
	if (!ret)
          	printf("AES key = %u cleared successfully\n",key_handle);
	else
          	printf("AES key clear failed with err %d\n",ret);

	return ret ? CMD_RET_FAILURE:CMD_RET_SUCCESS;
}

/***************************************************/
U_BOOT_CMD(
        clear_aes_key, 2, 0, do_clear_aes_key,
	"Clear AES 256 key in TME-L based systems",
	"Clear key: clear_aes_key <key_handle>"
);

#endif

/**
 * do_aes_256() - Handle the "aes" command-line command
 * @cmdtp:	Command data struct pointer
 * @flag:	Command flag
 * @argc:	Command-line argument count
 * @argv:	Array of command-line arguments
 *
 * Returns zero on success, CMD_RET_USAGE in case of misuse and negative
 * on error.
 */
static int do_aes_256(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
	uint64_t src_addr, dst_addr, ivdata;
	uint64_t req_len, iv_len, resp_len, type, mode;
	struct crypto_aes_req_data_t *req_ptr = NULL;
	int cmd_id = -1;
	int ret = CMD_RET_USAGE;

#ifndef CONFIG_IPQ_DERIVE_KEY
	if (argc != 10)
		return ret;
#else
	if (argc != 11)
		return ret;
#endif

	if (!strncmp(argv[1], "enc", 3))
		cmd_id = TZ_CRYPTO_SERVICE_AES_ENC_ID;
	else if (!strncmp(argv[1], "dec", 3))
		cmd_id = TZ_CRYPTO_SERVICE_AES_DEC_ID;
	else
		return ret;

	type = simple_strtoul(argv[2], NULL, 16);
	if (type >= TZ_CRYPTO_SERVICE_AES_TYPE_MAX) {
		printf("unkown type specified, use 0x1 - SHK, 0x2 - PHK\n");
		return ret;
	}

	mode = simple_strtoul(argv[3], NULL, 16);
        if (mode >= TZ_CRYPTO_SERVICE_AES_MODE_MAX) {
                printf("unkown mode specified, use 0x0 - ECB, 0x1 - CBC\n");
                return ret;
        }

	src_addr = simple_strtoull(argv[4], NULL, 16);
	req_len = simple_strtoul(argv[5], NULL, 16);
	if (req_len <= 0 || (req_len % 16) != 0) {
		printf("Invalid request buffer length, length "
			"should be multiple of AES block size (16)\n");
		return ret;
	}

	ivdata = simple_strtoull(argv[6], NULL, 16);
	iv_len = simple_strtoul(argv[7], NULL, 16);
	if (iv_len != 16) {
		printf("Error: iv length should be equal to AES block size (16)\n");
		return ret;
	}

	dst_addr = simple_strtoull(argv[8], NULL, 16);
	resp_len =  simple_strtoul(argv[9], NULL, 16);
	if (resp_len < req_len) {
		printf("Error: response buffer cannot be less then request buffer\n");
		return ret;
	}

	req_ptr = (struct crypto_aes_req_data_t *)memalign(ARCH_DMA_MINALIGN,
					sizeof(struct crypto_aes_req_data_t));
	if (!req_ptr) {
		printf("Error allocating memory");
		return -ENOMEM;
	}

#ifdef CONFIG_IPQ_DERIVE_KEY
	req_ptr->key_handle = simple_strtoul(argv[10], NULL, 16);
#endif
	req_ptr->type = type;
	req_ptr->mode = mode;
	req_ptr->req_buf = (uint64_t)src_addr;
	req_ptr->req_len = req_len;
	req_ptr->ivdata = (mode == TZ_CRYPTO_SERVICE_AES_CBC) ? (uint64_t)ivdata : 0;
	req_ptr->iv_len = iv_len;
	req_ptr->resp_buf = (uint64_t)dst_addr;
	req_ptr->resp_len = resp_len;
	ret = qca_scm_crypto(cmd_id, (void *)req_ptr,
					sizeof(struct crypto_aes_req_data_t));
	if (ret)
		printf("Scm call failed with error code: %d\n", ret);
	else
		printf("Encryption/Decryption successful\n");

	if (req_ptr)
		free(req_ptr);
	return ret;
}

/***************************************************/
U_BOOT_CMD(
	aes_256, 11, 1, do_aes_256,
	"AES 256 CBC/ECB encryption/decryption",
	"Encryption: aes_256 enc <type> <mode> <plain data address> <plain data len>"
	"<iv data address> <iv len> <response buf address> <response buf len>"
#ifdef CONFIG_IPQ_DERIVE_KEY
	"<key_handle>"
#endif
	"Decryption: echo dec <type> <mode> <Encrypted buf address> <encrypted"
	"buf len> <iv data address> <iv len> <response buf address> <response buf len>"
#ifdef CONFIG_IPQ_DERIVE_KEY
	"<key_handle>"
#endif
);
#endif


#ifdef CONFIG_CMD_AES_128
/**
 * do_aes() - Handle the "aes" command-line command
 * @cmdtp:	Command data struct pointer
 * @flag:	Command flag
 * @argc:	Command-line argument count
 * @argv:	Array of command-line arguments
 *
 * Returns zero on success, CMD_RET_USAGE in case of misuse and negative
 * on error.
 */
static int do_aes(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
	uint32_t key_addr, src_addr, dst_addr, len;
	uint8_t *key_ptr, *src_ptr, *dst_ptr;
	uint8_t key_exp[AES_EXPAND_KEY_LENGTH];
	uint32_t aes_blocks;
	int enc;

	if (argc != 6)
		return CMD_RET_USAGE;

	if (!strncmp(argv[1], "enc", 3))
		enc = 1;
	else if (!strncmp(argv[1], "dec", 3))
		enc = 0;
	else
		return CMD_RET_USAGE;

	key_addr = simple_strtoul(argv[2], NULL, 16);
	src_addr = simple_strtoul(argv[3], NULL, 16);
	dst_addr = simple_strtoul(argv[4], NULL, 16);
	len = simple_strtoul(argv[5], NULL, 16);

	key_ptr = (uint8_t *)key_addr;
	src_ptr = (uint8_t *)src_addr;
	dst_ptr = (uint8_t *)dst_addr;

	/* First we expand the key. */
	aes_expand_key(key_ptr, key_exp);

	/* Calculate the number of AES blocks to encrypt. */
	aes_blocks = DIV_ROUND_UP(len, AES_KEY_LENGTH);

	if (enc)
		aes_cbc_encrypt_blocks(key_exp, src_ptr, dst_ptr, aes_blocks);
	else
		aes_cbc_decrypt_blocks(key_exp, src_ptr, dst_ptr, aes_blocks);

	return 0;
}

/***************************************************/
#ifdef CONFIG_SYS_LONGHELP
static char aes_help_text[] =
	"enc key src dst len - Encrypt block of data $len bytes long\n"
	"                          at address $src using a key at address\n"
	"                          $key and store the result at address\n"
	"                          $dst. The $len size must be multiple of\n"
	"                          16 bytes and $key must be 16 bytes long.\n"
	"aes dec key src dst len - Decrypt block of data $len bytes long\n"
	"                          at address $src using a key at address\n"
	"                          $key and store the result at address\n"
	"                          $dst. The $len size must be multiple of\n"
	"                          16 bytes and $key must be 16 bytes long.";
#endif

U_BOOT_CMD(
	aes, 6, 1, do_aes,
	"AES 128 CBC encryption",
	aes_help_text
);
#endif
