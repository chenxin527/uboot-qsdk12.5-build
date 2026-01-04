// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2021 MediaTek Inc. All Rights Reserved.
 *
 * Author: Weijie Gao <weijie.gao@mediatek.com>
 *
 * Simple TAR extractor
 */

/* Source Code comes from:
 * https://github.com/hanwckf/bl-mt798x/blob/master/uboot-mtk-20250711/board/mediatek/common/untar.c
 */

#include <common.h>
#include <command.h>
#include <errno.h>
#include <stdbool.h>
#include <cmd_untar.h>

struct tar_hdr {
	char name[100];			/*   0 */
	char mode[8];			/* 100 */
	char uid[8];			/* 108 */
	char gid[8];			/* 116 */
	char size[12];			/* 124 */
	char mtime[12];			/* 136 */
	char chksum[8];			/* 148 */
	char typeflag;			/* 156 */
	char linkname[100];		/* 157 */
	char magic[6];			/* 257 */
	char version[2];		/* 263 */
	char uname[32];			/* 265 */
	char gname[32];			/* 297 */
	char devmajor[8];		/* 329 */
	char devminor[8];		/* 337 */
	char prefix[155];		/* 345 */
	char padding[12];		/* 500 */
};

/* Values used in typeflag field.  */
#define REGTYPE  '0'			/* regular file */
#define AREGTYPE '\0'			/* regular file */
#define LNKTYPE  '1'			/* link */
#define SYMTYPE  '2'			/* reserved */
#define CHRTYPE  '3'			/* character special */
#define BLKTYPE  '4'			/* block special */
#define DIRTYPE  '5'			/* directory */
#define FIFOTYPE '6'			/* FIFO special */
#define CONTTYPE '7'			/* reserved */

static bool tar_header_is_blank(const void *buff)
{
	const u8 *p = buff;
	int i;

	for (i = 0; i < sizeof(struct tar_hdr); i++) {
		if (p[i])
			return false;
	}

	return true;
}

int tar_header_checksum(const void *buff)
{
	ulong i, old_chksum, new_chksum = 0;
	struct tar_hdr hdr;
	const u8 *p;

	memcpy(&hdr, buff, sizeof(hdr));

	old_chksum = simple_strtoul(hdr.chksum, NULL, 8);
	memset(hdr.chksum, 0x20, sizeof(hdr.chksum));

	p = (const u8 *)&hdr;
	for (i = 0; i < sizeof(struct tar_hdr); i++)
		new_chksum += (ulong)p[i];

	if (old_chksum == new_chksum)
		return 0;

	return -EINVAL;
}

int tar_ctx_init(struct tar_parse_ctx *ctx, const void *buff, size_t size)
{
	if (!ctx)
		return -EINVAL;

	ctx->head = buff;
	ctx->size = size;
	ctx->offset = 0;
	ctx->eof = 0;

	return 0;
}

int tar_ctx_next_file(struct tar_parse_ctx *ctx,
		              struct tar_file_record *file_record)
{
	struct tar_hdr *phdr;
	size_t size;

	if (!ctx)
		return -EINVAL;

	if (ctx->eof)
		return -ENODATA;

	if (ctx->size - ctx->offset < sizeof(struct tar_hdr)) {
		ctx->eof = 1;
		return -ENODATA;
	}

	if (tar_header_is_blank(ctx->head + ctx->offset)) {
		ctx->offset += sizeof(struct tar_hdr);
		ctx->eof = 1;
		return -ENODATA;
	}

	if (tar_header_checksum(ctx->head + ctx->offset))
		return -EINVAL;

	phdr = (struct tar_hdr *)(ctx->head + ctx->offset);

	size = simple_strtoul(phdr->size, NULL, 8);
	if (ctx->offset + size + sizeof(struct tar_hdr) > ctx->size)
		return -EINVAL;

	if (file_record) {
		file_record->name = phdr->name;
		file_record->data = ctx->head + ctx->offset +
				     sizeof(struct tar_hdr);
		file_record->size = size;
		file_record->mode = simple_strtoul(phdr->mode, NULL, 8);
		file_record->uid = simple_strtoul(phdr->uid, NULL, 8);
		file_record->gid = simple_strtoul(phdr->gid, NULL, 8);
		file_record->uname = phdr->uname;
		file_record->gname = phdr->gname;
		file_record->linkname = phdr->linkname;

		switch (phdr->typeflag) {
		case REGTYPE:
		case AREGTYPE:
			file_record->type = TAR_FT_REGULAR;
			break;
		case LNKTYPE:
		case SYMTYPE:
			file_record->type = TAR_FT_LINK;
			break;
		case CHRTYPE:
			file_record->type = TAR_FT_CHAR;
			break;
		case BLKTYPE:
			file_record->type = TAR_FT_BLOCK;
			break;
		case DIRTYPE:
			file_record->type = TAR_FT_DIRECTORY;
			break;
		case FIFOTYPE:
			file_record->type = TAR_FT_FIFO;
			break;
		default:
			file_record->type = TAR_FT_UNKNOWN;
		}
	}

	size = ALIGN(size, sizeof(struct tar_hdr));

	ctx->offset += sizeof(struct tar_hdr) + size;

	return 0;
}

int parse_tar_image(const void *data, size_t size,
				    const void **kernel_data, size_t *kernel_size,
				    const void **rootfs_data, size_t *rootfs_size)
{
	bool has_kernel = false, has_root = false;
	struct tar_file_record file;
	struct tar_parse_ctx ctx;
	const char *p;
	int ret;

	static const char sysupgrade_str[] = "sysupgrade";

	tar_ctx_init(&ctx, data, size);

	ret = tar_ctx_next_file(&ctx, &file);

	while (!ret) {
		if (file.type != TAR_FT_REGULAR)
			goto next_file;

		if (strncmp(file.name, sysupgrade_str,
			    sizeof(sysupgrade_str) - 1))
			goto next_file;

		p = strchr(file.name, '/');
		if (!p)
			goto next_file;

		if (!strcmp(p + 1, "kernel")) {
			*kernel_data = file.data;
			*kernel_size = file.size;
			has_kernel = true;
		}

		if (!strcmp(p + 1, "root")) {
			*rootfs_data = file.data;
			*rootfs_size = file.size;
			has_root = true;
		}

		if (has_kernel && has_root)
			return CMD_RET_SUCCESS;

	next_file:
		ret = tar_ctx_next_file(&ctx, &file);
	}

	return CMD_RET_FAILURE;
}

static int do_untar(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[]) {
	int ret = CMD_RET_SUCCESS;
	char *loadaddr, *filesize;
	const void *load_addr, *kernel_addr, *rootfs_addr;
	size_t file_size, kernel_size, rootfs_size;

	switch (argc) {
		case 1:
			loadaddr = getenv("fileaddr");
			if (loadaddr != NULL)
				load_addr = (void *)simple_strtoul(loadaddr, NULL, 16);
			else
				return CMD_RET_USAGE;

			filesize = getenv("filesize");
			if (filesize != NULL)
				file_size = (size_t)simple_strtoul(filesize, NULL, 16);
			else
				return CMD_RET_USAGE;

			break;
		case 3:
			load_addr = (void *)simple_strtoul(argv[1], NULL, 16);
			file_size = (size_t)simple_strtoul(argv[2], NULL, 16);
			break;
		default:
			return CMD_RET_USAGE;
			break;
	}

	ret = parse_tar_image(load_addr, file_size,
						  &kernel_addr, &kernel_size,
			      		  &rootfs_addr, &rootfs_size);

	if (ret == CMD_RET_SUCCESS) {
		setenv_hex("kernel_addr", (ulong)kernel_addr);
		setenv_hex("kernel_size", (ulong)kernel_size);
		setenv_hex("rootfs_addr", (ulong)rootfs_addr);
		setenv_hex("rootfs_size", (ulong)rootfs_size);

		printf("  load_addr: 0x%lx,   file_size: 0x%lx\n", (ulong)load_addr, (ulong)file_size);
		printf("kernel_addr: 0x%lx, kernel_size: 0x%lx\n", (ulong)kernel_addr, (ulong)kernel_size);
		printf("rootfs_addr: 0x%lx, rootfs_size: 0x%lx\n", (ulong)rootfs_addr, (ulong)rootfs_size);
	} else {
		// 删除相应的环境变量
		char *buf = "setenv kernel_addr && setenv kernel_size && setenv rootfs_addr && setenv rootfs_size";
		run_command(buf, 0);
		printf("No valid sysupgrade tar image found.\n");
	}

	return ret;
}

U_BOOT_CMD(
	untar, 3, 0, do_untar,
	"unstar [load_addr] [file_size]",
	"get offset and size of kernel and rootfs in sysupgrade tar image\n"
);
