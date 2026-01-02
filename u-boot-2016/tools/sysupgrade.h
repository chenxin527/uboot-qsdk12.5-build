/*
 * Copyright (c) 2015, The Linux Foundation. All rights reserved.
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

#include <dumpimage.h>
#include <elf.h>
#include <dirent.h>
#include <sys/ioctl.h>
#include <mtd/mtd-user.h>
#include <limits.h>
#include <linux/string.h>
#include <linux/types.h>

typedef enum {HLOS_TYPE, UBOOT_TYPE, SBL_TYPE, TZ_TYPE, RPM_TYPE, DEVCFG_TYPE, APDP_TYPE}type;

struct image_section {
	type section_type;
	int max_version;
	char file[256];
	char *type;
	char tmp_file[256];
	int img_version;
	int local_version;
	char *version_file;
	int is_present;
	char *img_code;
	int (*pre_op)(struct image_section *);
	int (*get_sw_id)(struct image_section *);
	int (*split_components)(struct image_section *, char **, char**, char**);
};

typedef struct mbn_header {
	uint32_t image_id;
	uint32_t ver_num;
	uint32_t image_src;
	uint8_t *image_dest_ptr;
	uint32_t image_size;
	uint32_t code_size;
	uint8_t *sig_ptr;
	uint32_t sig_sz;
	uint8_t *cert_ptr;
	uint32_t cert_sz;
}Mbn_Hdr;

struct ubi_ec_hdr {
	__be32  magic;
	__u8    version;
	__u8    padding1[3];
	__be64  ec; /* Warning: the current limit is 31-bit anyway! */
	__be32  vid_hdr_offset;
	__be32  data_offset;
	__be32  image_seq;
	__u8    padding2[32];
	__be32  hdr_crc;
};

struct ubi_vid_hdr {
	__be32  magic;
	__u8    version;
	__u8    vol_type;
	__u8    copy_flag;
	__u8    compat;
	__be32  vol_id;
	__be32  lnum;
	__u8    padding1[4];
	__be32  data_size;
	__be32  used_ebs;
	__be32  data_pad;
	__be32  data_crc;
	__u8    padding2[4];
	__be64  sqnum;
	__u8    padding3[12];
	__be32  hdr_crc;
};

typedef struct {
	uint32_t  codeword;
	uint32_t  magic;
	uint32_t  RESERVED_0;
	uint32_t  RESERVED_1;
	uint32_t  RESERVED_2;
	uint32_t  image_src;
	uint8_t  *image_dest_ptr;
	uint32_t  image_size;
	uint32_t  code_size;
	uint8_t  *sig_ptr;
	uint32_t  sig_size;
	uint8_t  *cert_ptr;
	uint32_t  cert_size;
	uint32_t  root_cert_sel;
	uint32_t  num_root_certs;
	uint32_t  RESERVED_5;
	uint32_t  RESERVED_6;
	uint32_t  RESERVED_7;
	uint32_t  RESERVED_8;
	uint32_t  RESERVED_9;
} Sbl_Hdr;

size_t strlcpy(char *, const char *, size_t);
size_t strlcat(char *, const char *, size_t);
int get_sections(void);
int is_authentication_check_enabled(void);
int get_local_image_version(struct image_section *);
int set_local_image_version(struct image_section *);
int is_version_check_enabled(void);
int get_sw_id_from_component_bin(struct image_section *);
int get_sw_id_from_component_bin_elf(struct image_section *);
int get_sw_id_from_component_bin_elf64(struct image_section *);
int extract_binary(struct image_section *);
int extract_kernel_binary(struct image_section *, char *);
int extract_ubi_volume(char *, char *, char *);
int extract_rootfs_binary(char *);
int is_image_version_higher(void);
int update_version(void);
int check_image_version(void);
int split_code_signature_cert_from_component_bin(struct image_section *, char **, char **, char **);
int split_code_signature_cert_from_component_bin_elf(struct image_section *, char **, char **, char **);
int split_code_signature_cert_from_component_bin_elf64(struct image_section *, char **, char **, char **);
void generate_swid_ipad(char *, unsigned long long *);
void generate_hwid_opad(char *, char *, char *, unsigned long long *);
int generate_hash(char *, char *, char *);
int is_component_authenticated(char *, char *, char *);
int is_image_authenticated(void);
int do_board_upgrade_check(char *);
int check_nand_preamble(uint8_t *);
int find_mtd_part_size(char *);
int create_file(char *, char *, int );
int parse_elf_image_phdr(struct image_section *);
int compute_sha_hash(struct image_section *);
char *check_image_exist(char *);
