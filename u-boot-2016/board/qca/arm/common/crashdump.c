/*
 * Copyright (c) 2015-2018, 2020 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include <common.h>
#include <mmc.h>
#include <nand.h>
#include <spi.h>
#include <spi_flash.h>
#include <usb.h>
#include <fat.h>
#include <asm/errno.h>
#include <asm/io.h>
#include <asm/arch-qca-common/scm.h>
#include <asm/arch-qca-common/iomap.h>
#include <asm/arch-qca-common/qca_common.h>

#define MAX_TFTP_SIZE 0x40000000
#define MAX_SEARCH_PARTITIONS 16

#define MAX_UNAME_SIZE			1024
#define QCA_WDT_SCM_TLV_TYPE_SIZE	1
#define QCA_WDT_SCM_TLV_LEN_SIZE	2
#define QCA_WDT_SCM_TLV_TYPE_LEN_SIZE (QCA_WDT_SCM_TLV_TYPE_SIZE +\
						QCA_WDT_SCM_TLV_LEN_SIZE)
#define MAX_NAND_PAGE_SIZE		4096
#define MAX_EMMC_BLK_LEN		1024

#ifndef CONFIG_CRASHDUMP_SPI_SPEED
#define CONFIG_CRASHDUMP_SPI_SPEED	1000000
#endif

#ifndef CONFIG_CRASHDUMP_SPI_MODE
#define CONFIG_CRASHDUMP_SPI_MODE	SPI_MODE_3
#endif

#ifndef CONFIG_SYS_MMC_CRASHDUMP_DEV
#define CONFIG_SYS_MMC_CRASHDUMP_DEV	0
#endif

#define MINIDUMP_MAGIC1_COOKIE				0x4D494E49
#define MINIDUMP_MAGIC2_COOKIE				0x44554D50
#define DEFAULT_MINIDUMP_LIST_ENTRY_MAX			256
#define MINIDUMP_LIST_ENTRY_INC_ORDER			128

#define CONFIG_TZ_SIZE			0x400000
DECLARE_GLOBAL_DATA_PTR;
static qca_smem_flash_info_t *sfi = &qca_smem_flash_info;
/* USB device id and part index used by usbdump */
static int usb_dev_indx, usb_dev_part;
int crashdump_tlv_count=0;
char *dump_prefix = "";

enum {
    /*Basic DDR segments */
	QCA_WDT_LOG_DUMP_TYPE_INVALID,
	QCA_WDT_LOG_DUMP_TYPE_UNAME,
	QCA_WDT_LOG_DUMP_TYPE_DMESG,
	QCA_WDT_LOG_DUMP_TYPE_LEVEL1_PT,
	/* Module structures are in highmem zone*/
	QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD,
	QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD_DEBUGFS,
	QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD_INFO,
	QCA_WDT_LOG_DUMP_TYPE_WLAN_MMU_INFO,
	QCA_WDT_LOG_DUMP_TYPE_EMPTY,
};
/* This will be used for parsing the TLV data */
struct qca_wdt_scm_tlv_msg {
      unsigned char *msg_buffer;
      unsigned char *cur_msg_buffer_pos;
      unsigned int len;
};

/* Structure to hold crashdump related pointers */
struct st_tlv_info {
    uint64_t start;
    uint64_t size;
};
/* Actual crashdump related data */
struct qca_wdt_crashdump_data {
	unsigned char uname[MAX_UNAME_SIZE];
	unsigned int uname_length;
	unsigned char *cpu_context;
	unsigned char *log_buf;
	unsigned int log_buf_len;
	unsigned char *pt_start;
	unsigned int pt_len;
};

/* Context for NAND Flash memory */
struct crashdump_flash_nand_cxt {
       loff_t start_crashdump_offset;
       loff_t cur_crashdump_offset;
       int cur_page_data_len;
       int write_size;
       unsigned char temp_data[MAX_NAND_PAGE_SIZE];
       uint32_t part_start;
       uint32_t part_size;
};

#ifdef CONFIG_QCA_SPI
/* Context for SPI NOR Flash memory */
struct crashdump_flash_spi_cxt {
       loff_t start_crashdump_offset;
       loff_t cur_crashdump_offset;
};
#endif

#ifdef CONFIG_QCA_MMC
/* Context for EMMC Flash memory */
struct crashdump_flash_emmc_cxt {
       loff_t start_crashdump_offset;
       loff_t cur_crashdump_offset;
       int cur_blk_data_len;
       int write_size;
       unsigned char temp_data[MAX_EMMC_BLK_LEN];
};
#endif

struct memdumps_list_info {
	char name[20];
	uint64_t offset;
	uint64_t size;
};

struct memdump_hdr {
	uint32_t magic1;
	uint32_t magic2;
	uint32_t nos_dumps;
	uint32_t total_dump_sz;
	uint64_t dumps_list_info_offset;
	uint32_t reserved[2];
};

struct dump2nvmem_config {
	int flash_type;
	uint32_t offset;
	uint32_t dump_off;
	uint32_t size;
	uint32_t blksize;
};

void *crashdump_cnxt;
int (*crashdump_flash_write)(void *cnxt, unsigned char *data, unsigned int size);
int (*crashdump_flash_write_init)(void *cnxt, loff_t offset, unsigned int total_size);
int (*crashdump_flash_write_deinit)(void *cnxt);

#ifdef CONFIG_MTD_DEVICE
static struct crashdump_flash_nand_cxt crashdump_nand_cnxt;
#endif
#ifdef CONFIG_QCA_SPI
static struct spi_flash *crashdump_spi_flash;
static struct crashdump_flash_spi_cxt crashdump_flash_spi_cnxt;
#endif
#ifdef CONFIG_QCA_MMC
static struct mmc *mmc;
static struct crashdump_flash_emmc_cxt crashdump_emmc_cnxt;
#endif
static struct qca_wdt_crashdump_data g_crashdump_data;
struct qca_wdt_scm_tlv_msg tlv_msg ;

static ulong dump2mem_addr_curr = 0, dump2mem_addr = 0, dump2mem_addr_limit =0;
static uint32_t dumplist_entrymax = DEFAULT_MINIDUMP_LIST_ENTRY_MAX;
static struct memdump_hdr dump2mem_hdr;
static struct dump2nvmem_config dump2nvmem_info;
static struct memdumps_list_info *dumps_list = NULL;

__weak int scm_set_boot_addr(bool enable_sec_core)
{
	return -1;
}

__weak void crashdump_exit(void)
{
#ifdef CONFIG_SKIP_RESET
	run_command("bootipq", 0);
#else
	reset_board();
#endif
}

static int krait_release_secondary(void)
{
	writel(0xa4, CPU1_APCS_SAW2_VCTL);
	barrier();
	udelay(512);

	writel(0x109, CPU1_APCS_CPU_PWR_CTL);
	writel(0x101, CPU1_APCS_CPU_PWR_CTL);
	barrier();
	udelay(1);

	writel(0x121, CPU1_APCS_CPU_PWR_CTL);
	barrier();
	udelay(2);

	writel(0x120, CPU1_APCS_CPU_PWR_CTL);
	barrier();
	udelay(2);

	writel(0x100, CPU1_APCS_CPU_PWR_CTL);
	barrier();
	udelay(100);

	writel(0x180, CPU1_APCS_CPU_PWR_CTL);
	barrier();

	return 0;
}

static int dump_to_dst (int is_aligned_access, uint32_t memaddr, uint32_t size, char *name,
		unsigned int dump_level)
{
	char runcmd[256];
	char *usb_dump = NULL, *dump2mem = NULL, *dump2nvmem = NULL;
	ulong is_usb_dump = 0;
	int ret = 0;

	if (!size) {
		printf("Skipping %s dump, due to size zero\n", name);
		return CMD_RET_SUCCESS;
	}

	dump2nvmem = getenv("dump_to_nvmem");
	dump2mem = getenv("dump_to_mem");
	usb_dump = getenv("dump_to_usb");
	if (usb_dump) {
		ret = str2long(usb_dump, &is_usb_dump);
		if (!ret) {
			printf("\nError: Failed to decode dump_to_usb value\n");
			return -EINVAL;
		}
	}

	if (is_aligned_access) {
		if (IPQ_TEMP_DUMP_ADDR) {
			snprintf(runcmd, sizeof(runcmd), "cp.l 0x%x 0x%x 0x%x", memaddr,
					IPQ_TEMP_DUMP_ADDR, size / 4);
			if (run_command(runcmd, 0) != CMD_RET_SUCCESS)
				return CMD_RET_FAILURE;

			memaddr = IPQ_TEMP_DUMP_ADDR;
		} else {
			printf("%s  needs aligned access and temp address is not defined. Skipping...", name);
			return CMD_RET_FAILURE;
		}
	}

	if (is_usb_dump == 1)
		snprintf(runcmd, sizeof(runcmd), "fatwrite usb %x:%x 0x%x %s 0x%x",
					usb_dev_indx, usb_dev_part, memaddr, name, size);
	else if (dump2mem && (dump_level == MINIMAL_DUMP)) {
		int idx = dump2mem_hdr.nos_dumps++;

		if (idx >= dumplist_entrymax) {
			dumplist_entrymax += MINIDUMP_LIST_ENTRY_INC_ORDER;
			dumps_list = realloc(dumps_list,
					dumplist_entrymax * sizeof(struct memdumps_list_info));
			if (!dumps_list) {
				printf("failed to do realloc the minidumps list entry table\n");
				return CMD_RET_FAILURE;
			}
		}

		strlcpy(dumps_list[idx].name, name, sizeof(dumps_list[idx].name));
		dumps_list[idx].offset = dump2mem_addr_curr - dump2mem_addr;
		dumps_list[idx].size = size;
		snprintf(runcmd, sizeof(runcmd), "cp.l 0x%x 0x%lx 0x%x",
				memaddr, dump2mem_addr_curr, size);

		if (roundup(dump2mem_addr_curr + size, ARCH_DMA_MINALIGN) > dump2mem_addr_limit) {
			printf("Error: Not enough memory in rsvd mem to save dumps\n");
			return CMD_RET_FAILURE;
		}

		printf("Dumping %s @ 0x%lX \n", dumps_list[idx].name, dump2mem_addr_curr);
		dump2mem_addr_curr = roundup(dump2mem_addr_curr + size, ARCH_DMA_MINALIGN);

	} else if (dump2nvmem && (dump_level == MINIMAL_DUMP)) {
		int idx = dump2mem_hdr.nos_dumps++;

		if (idx >= dumplist_entrymax) {
			dumplist_entrymax += MINIDUMP_LIST_ENTRY_INC_ORDER;
			dumps_list = realloc(dumps_list,
					dumplist_entrymax * sizeof(struct memdumps_list_info));
			if (!dumps_list) {
				printf("failed to do realloc the minidumps list entry table\n");
				return CMD_RET_FAILURE;
			}
		}

		strlcpy(dumps_list[idx].name, name, sizeof(dumps_list[idx].name));
		dumps_list[idx].offset = dump2mem_addr_curr;
		dumps_list[idx].size = size;

		if (dump2mem_addr_curr + size > dump2nvmem_info.size) {
			printf("Error: Not enough memory in %s partition to save dumps\n", dump2nvmem);
			return CMD_RET_FAILURE;
		}

		ret = crashdump_flash_write(crashdump_cnxt, (unsigned char *)memaddr, size);
		if (ret)
			return ret;

		printf("Writing %s in %s @ offset 0x%lx\n", dumps_list[idx].name,
				dump2nvmem, dump2mem_addr_curr);
		dump2mem_addr_curr += size;

		return CMD_RET_SUCCESS;
	} else {
		char *dumpdir;
		dumpdir = getenv("dumpdir");
		if (dumpdir != NULL) {
			printf("Using directory %s in TFTP server\n", dumpdir);
		} else {
			dumpdir = "";
			printf("Env 'dumpdir' not set. Using / dir in TFTP server\n");
		}

		snprintf(runcmd, sizeof(runcmd), "tftpput 0x%x 0x%x %s/%s",
						memaddr, size, dumpdir, name);
	}

	if (run_command(runcmd, 0) != CMD_RET_SUCCESS)
		return CMD_RET_FAILURE;

	return CMD_RET_SUCCESS;

}

/* Extracts the type and length in TLV for current offset */
static int qca_wdt_scm_extract_tlv_info(
                struct qca_wdt_scm_tlv_msg *scm_tlv_msg,
                unsigned char *type,
                unsigned int *size)
{
	unsigned char *x = scm_tlv_msg->cur_msg_buffer_pos;
	unsigned char *y = scm_tlv_msg->msg_buffer +
                                scm_tlv_msg->len;

        if ((x + QCA_WDT_SCM_TLV_TYPE_LEN_SIZE) >= y)
                return -EINVAL;

        *type = x[0];
        *size = x[1] | (x[2] << 8);
        return 0;
}

/* Extracts the value from TLV for current offset */
static int qca_wdt_scm_extract_tlv_data(
		struct qca_wdt_scm_tlv_msg *scm_tlv_msg,
		unsigned char *data,
		unsigned int size)
{
	unsigned char *x = scm_tlv_msg->cur_msg_buffer_pos;
	unsigned char *y = scm_tlv_msg->msg_buffer + scm_tlv_msg->len;

	if ((x + QCA_WDT_SCM_TLV_TYPE_LEN_SIZE + size) >= y)
		return -EINVAL;

	memcpy(data, x + 3, size);

	scm_tlv_msg->cur_msg_buffer_pos +=
		(size + QCA_WDT_SCM_TLV_TYPE_LEN_SIZE);
	return 0;
}

/*
* This function parses the TLV message and stores the actual values
* in crashdump_data. For each TLV, It first determines the type and
* length, then it extracts the actual value and stores in the appropriate
* field in crashdump_data.
*/
static int qca_wdt_extract_crashdump_data(
		struct qca_wdt_scm_tlv_msg *scm_tlv_msg,
		struct qca_wdt_crashdump_data *crashdump_data)
{
	unsigned char cur_type = QCA_WDT_LOG_DUMP_TYPE_INVALID;
	unsigned int cur_size = 0;
	int ret_val = 0;
	struct st_tlv_info tlv_info;
	int static_enum_count = 0;
	int tlv_size = 0;

	while (static_enum_count < 3) {
		ret_val = qca_wdt_scm_extract_tlv_info(scm_tlv_msg,
			&cur_type, &cur_size);
		if (ret_val)
			return ret_val;

		switch (cur_type) {
		case QCA_WDT_LOG_DUMP_TYPE_UNAME:
			crashdump_data->uname_length = cur_size;
			ret_val = qca_wdt_scm_extract_tlv_data(scm_tlv_msg,
					crashdump_data->uname, cur_size);
			crashdump_tlv_count++;
			static_enum_count++;
			break;
		case QCA_WDT_LOG_DUMP_TYPE_DMESG:
			ret_val = qca_wdt_scm_extract_tlv_data(scm_tlv_msg,
				(unsigned char *)&tlv_info,
				cur_size);
			if (!ret_val) {
				crashdump_data->log_buf =(unsigned char *)(uintptr_t)tlv_info.start;
				crashdump_data->log_buf_len = *(uint32_t *)(uintptr_t)tlv_info.size;
		         }
			crashdump_tlv_count++;
			static_enum_count++;
			break;
		case QCA_WDT_LOG_DUMP_TYPE_LEVEL1_PT:
			ret_val = qca_wdt_scm_extract_tlv_data(scm_tlv_msg,(unsigned char *)&tlv_info,cur_size);
			if (!ret_val) {
				crashdump_data->pt_start =(unsigned char *)(uintptr_t)tlv_info.start;
				crashdump_data->pt_len = tlv_info.size;
			}
			crashdump_tlv_count++;
			static_enum_count++;
			break;
		case QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD:
			tlv_size = (cur_size + QCA_WDT_SCM_TLV_TYPE_LEN_SIZE);
			scm_tlv_msg->cur_msg_buffer_pos += tlv_size;
			break;
		default:
			printf("%s: No valid dump found\n", __func__);
			ret_val = -EINVAL;
			goto err;
		}
	}
err:
	return ret_val;
}

uint32_t dump_minimal(struct dumpinfo_t *dumpinfo, int indx) {

	if (g_crashdump_data.pt_start &&
		!strncmp(dumpinfo[indx].name,
			"PT.BIN", strlen("PT.BIN"))) {
		dumpinfo[indx].start =(uintptr_t) g_crashdump_data.pt_start;
		dumpinfo[indx].size = g_crashdump_data.pt_len;
	} else if (g_crashdump_data.log_buf &&
		!strncmp(dumpinfo[indx].name,
		"DMESG.BIN", strlen("DMESG.BIN"))) {
		dumpinfo[indx].start =(uintptr_t) g_crashdump_data.log_buf;
		dumpinfo[indx].size = g_crashdump_data.log_buf_len;
	} else if (!strncmp(dumpinfo[indx].name,
		"UNAME", strlen("UNAME"))) {
		dumpinfo[indx].start =(uintptr_t) g_crashdump_data.uname;
		dumpinfo[indx].size =
		g_crashdump_data.uname_length;
	} else if (!strncmp(dumpinfo[indx].name,
		"CPU_INFO", strlen("CPU_INFO"))) {
		dumpinfo[indx].start =
		(uintptr_t)g_crashdump_data.cpu_context;
		dumpinfo[indx].size =
		CONFIG_CPU_CONTEXT_DUMP_SIZE;
	}
	return dumpinfo[indx].start;
}

static int dump_wlan_segments(struct dumpinfo_t *dumpinfo, int indx)
{
	uint32_t memaddr;
	struct qca_wdt_scm_tlv_msg *scm_tlv_msg = &tlv_msg;
	unsigned char cur_type = QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD;
	unsigned int cur_size = 0;
	int ret_val = 0;
	int tlv_size = 0;
	struct st_tlv_info tlv_info;
	uint32_t wlan_tlv_size;

	char wlan_segment_name[32];

	if(strncmp(dumpinfo[indx].name, "WLAN_MOD" ,strlen("WLAN_MOD"))) {
		return CMD_RET_FAILURE;
	}

	scm_tlv_msg->cur_msg_buffer_pos = scm_tlv_msg->msg_buffer;

	do {
		ret_val = qca_wdt_scm_extract_tlv_info(scm_tlv_msg,
			&cur_type, &cur_size);

		/* Each Dump segment is represented by a TLV representing
		the type,size and physical addresses of	the dump segments.
		QCA_WDT_LOG_DUMP_TYPE_EMPTY type indicates that the TLV has
		been invalidated. When type QCA_WDT_LOG_DUMP_TYPE_EMPTY is encountered,
		we skip over the TLV by moving the current message buffer pointer
		ahead by one TLV */

		if(cur_type == QCA_WDT_LOG_DUMP_TYPE_EMPTY) {
			tlv_size = (cur_size + QCA_WDT_SCM_TLV_TYPE_LEN_SIZE);
			scm_tlv_msg->cur_msg_buffer_pos += tlv_size;
		}

		/* While iterating over the crashdump buffer, if MetaData file
		* TLV types are found (QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD_INFO or
		* QCA_WDT_LOG_DUMP_TYPE_WLAN_MMU_INFO), we dump the segment with
		* name "MOD_INFO.txt"/"MMU_INFO.txt". If DEBUFGS TLV type is found
		* we prefix the Dump binary with “DEBUGFS_” which is useful in
		* post processing step. If we encounter a QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD
		* TLV type, we dump the binary with name equal to the physical address
		* of the binary.
		*/
		if (!ret_val && ( cur_type == QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD ||
						cur_type == QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD_INFO ||
						cur_type == QCA_WDT_LOG_DUMP_TYPE_WLAN_MMU_INFO ||
						cur_type == QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD_DEBUGFS )) {
			ret_val = qca_wdt_scm_extract_tlv_data(scm_tlv_msg,
				(unsigned char *)&tlv_info,cur_size);
			memaddr = tlv_info.start;

			if (cur_type == QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD_INFO) {
				snprintf(wlan_segment_name,	sizeof(wlan_segment_name),
							 "MOD_INFO.txt");
				wlan_tlv_size = *(uint32_t *)(uintptr_t)tlv_info.size;
			} else if (cur_type == QCA_WDT_LOG_DUMP_TYPE_WLAN_MMU_INFO) {
				snprintf(wlan_segment_name, sizeof(wlan_segment_name),
							"MMU_INFO.txt");
				wlan_tlv_size = *(uint32_t *)(uintptr_t)tlv_info.size;
			} else if (cur_type == QCA_WDT_LOG_DUMP_TYPE_WLAN_MOD_DEBUGFS) {
				snprintf(wlan_segment_name, sizeof(wlan_segment_name),
					"DEBUGFS_%lx.BIN",(long unsigned int)memaddr);
				wlan_tlv_size = tlv_info.size;
			} else {
				snprintf(wlan_segment_name,
						 sizeof(wlan_segment_name), "%lx.BIN",(long unsigned int)memaddr);
				 wlan_tlv_size = tlv_info.size;
			}

			ret_val = dump_to_dst (dumpinfo[indx].is_aligned_access,memaddr,
						wlan_tlv_size, wlan_segment_name, dumpinfo[indx].dump_level);
			crashdump_tlv_count++;
			udelay(10000); /* give some delay for server */
			if (ret_val == CMD_RET_FAILURE)
				return CMD_RET_FAILURE;
		} else {
            tlv_size = (cur_size + QCA_WDT_SCM_TLV_TYPE_LEN_SIZE);
            scm_tlv_msg->cur_msg_buffer_pos += tlv_size;
        }
	}while (cur_type != QCA_WDT_LOG_DUMP_TYPE_INVALID);

	printf("\nMinidump: Dumped %d TLVs\n",crashdump_tlv_count);
	return CMD_RET_SUCCESS;
};

int is_length_valid(struct dumpinfo_t *dumpinfo, int dump_entries)
{
	int indx = 0;
	int ret = 0;
	for (indx = 0; indx < dump_entries; indx++) {
		/* max size of name allocated in dumpinfo struct is 256 */
		if ((strlen(dump_prefix) + strlen(dumpinfo[indx].name) + 1) > 256)
			ret = 1;
	}
	return ret;
}

void add_prefix(struct dumpinfo_t *dumpinfo, int dump_entries)
{
	int indx = 0;
	char temp[256];

	if (is_length_valid(dumpinfo, dump_entries)) {
		printf("WARN: Prefix length exceeds size, removing prefix for dumpfiles");
		dump_prefix = "";
	}
	for (indx = 0; indx < dump_entries; indx++) {
		snprintf(temp, sizeof(temp), "%s%s", dump_prefix, dumpinfo[indx].name);
		strlcpy(dumpinfo[indx].name, temp, strlen(temp)+1);
	}
}

static int do_dumpqca_data(unsigned int dump_level)
{
	uint32_t memaddr, comp_addr = 0x0;
	uint32_t remaining;
	int indx;
	int ebi_indx = 0;
	int ret = CMD_RET_FAILURE;
#if defined(CONFIG_IPQ5018) && !defined(CONFIG_DISABLE_SIGNED_BOOT)
	char buf = 1;
#endif
	struct dumpinfo_t *dumpinfo = dumpinfo_n;
	int dump_entries = dump_entries_n;
	char wlan_segment_name[32], runcmd[128], *s;
	char *usb_dump = NULL, *compress = NULL;
	char *dump2mem = NULL, *dump2mem_addr_s = NULL, *dump2mem_sz_s = NULL;
	char *dump2nvmem = NULL;
	ulong is_usb_dump = 0, is_compress = 0, dump2mem_sz = 0;
	char temp[256];

	dump2mem = getenv("dump_to_mem");
	if (dump2mem && (dump_level == MINIMAL_DUMP)) {
		dump2mem_addr_s = strsep(&dump2mem, " ");
		if (!dump2mem_addr_s ||
				!str2long(dump2mem_addr_s, &dump2mem_addr)) {
			printf("\nError: Failed to decode dump_to_mem addr\n");
			return -EINVAL;
		}

		dump2mem_sz_s = strsep(&dump2mem, " ");
		if (!dump2mem_sz_s ||
				!str2long(dump2mem_sz_s, &dump2mem_sz)) {
			printf("\nError: Failed to decode dump_to_mem size\n");
			return -EINVAL;
		}

		/* range check for the dump2mem_addr */
		if ((dump2mem_addr < CONFIG_SYS_SDRAM_BASE) ||
			(dump2mem_addr > CONFIG_SYS_SDRAM_BASE
			 + gd->ram_size - dump2mem_sz)) {
			printf("\nError: Invalid dump_to_mem param\n");
			return -EINVAL;
		}

		snprintf(runcmd, sizeof(runcmd), "mw 0x%lx 0xffffffff 0x8",
				dump2mem_addr);
		if (run_command(runcmd, 0) != CMD_RET_SUCCESS) {
			printf("\nError: failed to access memory region\n");
			return -EIO;
		}

		dump2mem_addr_curr = dump2mem_addr;
		dump2mem_hdr.magic1 = MINIDUMP_MAGIC1_COOKIE;
		dump2mem_hdr.magic2 = MINIDUMP_MAGIC2_COOKIE;
		dump2mem_hdr.nos_dumps = 0;
		dump2mem_hdr.total_dump_sz = 0;
		dump2mem_hdr.dumps_list_info_offset = 0;
		dumps_list = malloc(dumplist_entrymax *	sizeof(struct memdumps_list_info));
		dump2mem_addr_limit = dump2mem_addr + dump2mem_sz;

		dump2mem_addr_curr = roundup(dump2mem_addr_curr +
				sizeof(struct memdump_hdr), ARCH_DMA_MINALIGN);

	}

	dump2nvmem = getenv("dump_to_nvmem");
	if (dump2nvmem && (dump_level == MINIMAL_DUMP)) {
		snprintf(runcmd, sizeof(runcmd), "flasherase %s", dump2nvmem);
		ret = run_command(runcmd, 0);
		if (ret)
			return ret;

		dump2mem_addr = dump2nvmem_info.offset;
		dump2mem_hdr.magic1 = MINIDUMP_MAGIC1_COOKIE;
		dump2mem_hdr.magic2 = MINIDUMP_MAGIC2_COOKIE;
		dump2mem_hdr.nos_dumps = 0;
		dump2mem_hdr.total_dump_sz = 0;
		dump2mem_hdr.dumps_list_info_offset = 0;
		dumps_list = malloc(dumplist_entrymax *	sizeof(struct memdumps_list_info));
		dump2mem_addr_curr = dump2nvmem_info.blksize;

		ret = crashdump_flash_write_init(crashdump_cnxt,
				dump2nvmem_info.offset + dump2nvmem_info.dump_off, 0);
		if (ret)
			return ret;
	}

	usb_dump = getenv("dump_to_usb");
	if (usb_dump) {
		ret = str2long(usb_dump, &is_usb_dump);
		if (!ret) {
			printf("\nError: Failed to decode dump_to_usb value\n");
			return -EINVAL;
		}
	}

	if (is_usb_dump != 1) {
		char *serverip = NULL;
		/* dump to root of TFTP server if none specified */
		serverip = getenv("serverip");
		if (serverip != NULL) {
			printf("Using serverip from env %s\n", serverip);
		} else {
			printf("\nServer ip not found, run dhcp or configure\n");
			return CMD_RET_FAILURE;
		}
	}
	else {
#if defined(CONFIG_USB_STORAGE) && defined(CONFIG_FS_FAT)
		static block_dev_desc_t *stor_dev;
		disk_partition_t info;
		int dev_indx, max_dev_avail = 0;
		int part_indx = 0, part = -1;
		int fat_fs = 0;
		char dev_str[5]; /* dev:part */

		if(run_command("usb start", 0) != CMD_RET_SUCCESS) {
			printf("USB enumeration failed\n");
			return CMD_RET_FAILURE;
		}

		max_dev_avail = usb_max_dev_avail();
		for(dev_indx = 0; (fat_fs != 1) && (dev_indx < max_dev_avail); dev_indx++) {

			// get storage device
			stor_dev = usb_stor_get_dev(dev_indx);
			if(stor_dev == NULL) {
				printf("No storage device available\n");
				goto stop_dump;
			}

			// get valid partition
			for(part_indx = 1; part_indx <= MAX_SEARCH_PARTITIONS; part_indx++) {

				snprintf(dev_str, sizeof(dev_str)+1, "%x:%x", dev_indx, part_indx);
				part = get_device_and_partition("usb", dev_str, &stor_dev, &info, 1);

				if (fat_set_blk_dev(stor_dev, &info) == 0) {
					fat_fs = 1;
					printf("Selected Device for USBdump:\n");
					dev_print(stor_dev);
					break;
				}
			}

			if (part < 0)
				printf("No valid partition available for device %d\n", dev_indx);
		}

		if (fat_fs == 1)
			dev_indx = dev_indx - 1;
		if (dev_indx == max_dev_avail) {
			printf("No devices available for usbdump collection\n");
			goto stop_dump;
		}
		usb_dev_indx = dev_indx;
		usb_dev_part = part_indx;
		printf("Collecting crashdump on Partition %d of USB device %d\n", usb_dev_part, usb_dev_indx);
#else
		printf("\nWarning: Enable FAT FS configs for USBdump\n");
#endif
	}

#if defined(CONFIG_IPQ5018) && !defined(CONFIG_DISABLE_SIGNED_BOOT)
	ret = qca_scm_call(SCM_SVC_FUSE,
			   QFPROM_IS_AUTHENTICATE_CMD, &buf, sizeof(char));
	if (ret == 0 && buf == 1) {
		dumpinfo = dumpinfo_s;
		dump_entries = dump_entries_s;
	}
#endif

	dump_prefix = getenv("dump_prefix");
	if (dump_prefix != NULL)
		add_prefix(dumpinfo, dump_entries);
	else
		dump_prefix = "";

	if (scm_set_boot_addr(false) == 0) {
		/* Pull Core-1 out of reset, iff scm call succeeds */
		krait_release_secondary();
	}

	for (indx = 0; indx < dump_entries; indx++) {

#ifdef DUMP_TME_LOG
		if(!strncmp(dumpinfo[indx].name, "IMEM2.BIN", 9) &&
			qca_scm_is_feature_available(TME_LOG_DUMP_FEATURE_ID) \
			!= TME_LOG_DUMP_FEATURE_VERSION)
			continue;
#endif

		if (dump_level != dumpinfo[indx].dump_level)
			continue;

		if (dumpinfo[indx].is_redirected) {
			memaddr = *((uint32_t *)(dumpinfo[indx].start));
			if (!memaddr) {
				printf("Crashdump for %s is not available.\n",
					dumpinfo[indx].name);
				continue;
			}
		} else {
			memaddr = dumpinfo[indx].start;
		}

		if (dumpinfo[indx].offset)
			memaddr += dumpinfo[indx].offset;

		snprintf(temp, sizeof(temp), "%sEBICS", dump_prefix);
		if (!strncmp(dumpinfo[indx].name, temp, strlen(temp)))
		{
			compress = getenv("dump_compressed");
			if (compress) {
				ret = str2long(compress, &is_compress);
				if (!ret) {
					is_compress = 0;
				}
			}

			if (is_compress == 1) {
				snprintf(temp, sizeof(temp), "%sEBICS2", dump_prefix);
				if (!strncmp(dumpinfo[indx].name, temp, strlen(temp))) {
					memaddr = CONFIG_SYS_SDRAM_BASE + (gd->ram_size / 2);
					dumpinfo[indx].size = gd->ram_size / 2;
					comp_addr = memaddr;
				}
#ifndef CONFIG_DISABLE_SIGNED_BOOT
				snprintf(temp, sizeof(temp), "%sEBICS_S2", dump_prefix);
				if (!strncmp(dumpinfo[indx].name, temp, strlen(temp))) {
					dumpinfo[indx].size = gd->ram_size - (dumpinfo[indx].start - CONFIG_SYS_SDRAM_BASE);
					comp_addr = memaddr;
				}
#endif
				snprintf(temp, sizeof(temp), "%sEBICS1", dump_prefix);
				if (!strncmp(dumpinfo[indx].name, temp, strlen(temp))) {
					dumpinfo[indx].size = (gd->ram_size / 2)
								- (dumpinfo[indx + 1].size + 0x400000);
				}
			}
			else {
				snprintf(temp, sizeof(temp), "%sEBICS0", dump_prefix);
				if (!strncmp(dumpinfo[indx].name,
					     temp, strlen(temp)))
					dumpinfo[indx].size = gd->ram_size;
#ifndef CONFIG_DISABLE_SIGNED_BOOT
				snprintf(temp, sizeof(temp), "%sEBICS_S1", dump_prefix);
				if (!strncmp(dumpinfo[indx].name,
					     temp, strlen(temp)))
					dumpinfo[indx].size = gd->ram_size
							      - dumpinfo[indx - 1].size
							      - CONFIG_TZ_SIZE;
#endif
			}

			if (is_compress == 1 && (dumpinfo[indx].to_compress == 1)) {

				snprintf(runcmd, sizeof(runcmd), "zip 0x%x 0x%x 0x%x", memaddr, dumpinfo[indx].size, comp_addr);
				if (run_command(runcmd, 0) != CMD_RET_SUCCESS)
					printf("gzip compression of %s failed\n", dumpinfo[indx].name);
				else {
					s = getenv("filesize");
					dumpinfo[indx].size = (int)simple_strtol(s, NULL, 16); //compressed_file_size
					memaddr = comp_addr;
					snprintf(dumpinfo[indx].name, sizeof(dumpinfo[indx].name), "%s.gz", dumpinfo[indx].name);
				}
			}

			if ((is_compress == 1 && (dumpinfo[indx].to_compress != 1)) ||
					(is_compress != 1 && (dumpinfo[indx].to_compress == 1))) {
				continue;
			}

			if (is_usb_dump == 1 || is_compress == 1) {
				printf("\nProcessing %s:\n", dumpinfo[indx].name);
				ret = dump_to_dst (dumpinfo[indx].is_aligned_access, memaddr, dumpinfo[indx].size, dumpinfo[indx].name, dumpinfo[indx].dump_level);
				if (ret == CMD_RET_FAILURE) {
					goto stop_dump;
				}
			}
			else {
				remaining = dumpinfo[indx].size;
				while (remaining > 0) {
					snprintf(dumpinfo[indx].name, sizeof(dumpinfo[indx].name),
								"%sEBICS%d.BIN", dump_prefix, ebi_indx);
					if (remaining > MAX_TFTP_SIZE) {
						dumpinfo[indx].size = MAX_TFTP_SIZE;
					}
					else {
						dumpinfo[indx].size = remaining;
					}

					printf("\nProcessing %s:\n", dumpinfo[indx].name);
					ret = dump_to_dst (dumpinfo[indx].is_aligned_access, memaddr, dumpinfo[indx].size, dumpinfo[indx].name, dumpinfo[indx].dump_level);
					if (ret == CMD_RET_FAILURE)
						goto stop_dump;

					memaddr += dumpinfo[indx].size;
					remaining -= dumpinfo[indx].size;
					ebi_indx++;
				}
			}
		}
		else
		{
			printf("\nProcessing %s:\n", dumpinfo[indx].name);
			if (dumpinfo[indx].dump_level == MINIMAL_DUMP )
				memaddr = dump_minimal(dumpinfo, indx);
			if (dumpinfo[indx].size && memaddr) {
				if(dumpinfo[indx].dump_level == MINIMAL_DUMP){
					snprintf(wlan_segment_name, sizeof(wlan_segment_name), "%lx.BIN",(long unsigned int)memaddr);
					ret = dump_to_dst (dumpinfo[indx].is_aligned_access, memaddr, dumpinfo[indx].size, wlan_segment_name, dumpinfo[indx].dump_level);
					if (ret == CMD_RET_FAILURE)
						goto stop_dump;
				}
				else {
					ret = dump_to_dst (dumpinfo[indx].is_aligned_access, memaddr, dumpinfo[indx].size, dumpinfo[indx].name, dumpinfo[indx].dump_level);
					if (ret == CMD_RET_FAILURE)
						goto stop_dump;
				}
			}
			else {
				ret = dump_wlan_segments(dumpinfo, indx);
				if (ret == CMD_RET_FAILURE)
					goto stop_dump;
			}
		}
	}

stop_dump:
	if (getenv("dump_to_mem") && (dump_level == MINIMAL_DUMP)) {
		if (ret != CMD_RET_SUCCESS)
			return ret;

		snprintf(runcmd, sizeof(runcmd), "cp.l 0x%x 0x%lx 0x%x",
				(unsigned int)dumps_list, dump2mem_addr_curr,
				dump2mem_hdr.nos_dumps * sizeof(struct memdumps_list_info));
		if (run_command(runcmd, 0) != CMD_RET_SUCCESS) {
			printf("failed to dump at the addr 0x%lx\n", dump2mem_addr_curr);
			return -EINVAL;
		}

		free(dumps_list);

		dump2mem_hdr.total_dump_sz = dump2mem_addr_curr +
			(dump2mem_hdr.nos_dumps * sizeof(struct memdumps_list_info)) - dump2mem_addr;
		dump2mem_hdr.dumps_list_info_offset = dump2mem_addr_curr - dump2mem_addr;

		if ((dump2mem_addr + dump2mem_hdr.total_dump_sz)
				> dump2mem_addr_limit) {
			printf("Error: Not enough memory in rsvd mem to save dumps\n");
			return CMD_RET_FAILURE;
		}

		snprintf(runcmd, sizeof(runcmd), "cp.l 0x%x 0x%lx 0x%x",
				(unsigned int)&dump2mem_hdr, dump2mem_addr, sizeof(struct memdump_hdr));
		if (run_command(runcmd, 0) != CMD_RET_SUCCESS) {
			printf("failed to dump at the addr 0x%lx\n", dump2mem_addr);
			return -EINVAL;
		}
	}

	if (dump2nvmem && (dump_level == MINIMAL_DUMP)) {
		if (ret != CMD_RET_SUCCESS)
			return ret;

		/* updating dump_list in flash at the end */
		ret = crashdump_flash_write(crashdump_cnxt, (unsigned char *)dumps_list,
				dump2mem_hdr.nos_dumps * sizeof(struct memdumps_list_info));
		if (ret)
			return ret;

		ret = crashdump_flash_write_deinit(crashdump_cnxt);
		if (ret)
			return ret;

		dump2mem_hdr.total_dump_sz = dump2mem_addr_curr +
			(dump2mem_hdr.nos_dumps * sizeof(struct memdumps_list_info));
		dump2mem_hdr.dumps_list_info_offset = dump2mem_addr_curr;

		if (dump2mem_hdr.total_dump_sz > dump2nvmem_info.size) {
			printf("Error: Not enough memory in %s partition to save dumps", dump2nvmem);
			return CMD_RET_FAILURE;
		}

		/* updating memdump_hdr in flash at the first block */
		ret = crashdump_flash_write_init(crashdump_cnxt, dump2mem_addr, 0);
		if (ret)
			return ret;

		ret = crashdump_flash_write(crashdump_cnxt, (unsigned char *)&dump2mem_hdr,
				sizeof(struct memdump_hdr));
		if (ret)
			return ret;

		ret = crashdump_flash_write_deinit(crashdump_cnxt);
		if (ret)
			return ret;
	}

#if defined(CONFIG_USB_STORAGE) && defined(CONFIG_FS_FAT)
	if (is_usb_dump == 1) {
		mdelay(2000);
		run_command("usb stop", 0);
		mdelay(1000);
	}
#endif
	return ret;
}

/**
 * Inovke the dump routine and in case of failure, do not stop unless the user
 * requested to stop
 */
void dump_func(unsigned int dump_level)
{
	uint64_t etime;
	uint64_t ptime;
	int ping_status = 0;
	char *serverip = NULL, *forced_dump = NULL;
	char runcmd[50] = {0};

#ifdef CONFIG_IPQ_ETH_INIT_DEFER
	puts("\nNet:   ");
	eth_initialize();
#endif

	forced_dump = getenv("force_collect_dump");
	if (forced_dump) {
		serverip = getenv("serverip");
		if (serverip != NULL) {
			printf("Using serverip from env %s\n", serverip);
		} else {
			printf("\nServer ip not found, run dhcp or configure\n");
			goto exit;
		}
		printf("Trying to ping server.....\n");
		snprintf(runcmd, sizeof(runcmd), "ping %s", serverip);
		ptime = get_timer_masked() + (10 * CONFIG_SYS_HZ);
		while (get_timer_masked() <= ptime) {
			if (run_command(runcmd, 0) == CMD_RET_SUCCESS) {
				ping_status = 1;
				break;
			}
			mdelay(500);
		}
		if (ping_status != 1) {
			printf("Ping failed\n");
			goto exit;
		}
		if (do_dumpqca_data(dump_level) == CMD_RET_FAILURE)
			printf("Crashdump saving failed!\n");
		goto exit;
	} else {
		etime = get_timer_masked() + (10 * CONFIG_SYS_HZ);
		printf("\nHit any key within 10s to stop dump activity...");
		while (!tstc()) {       /* while no incoming data */
			if (get_timer_masked() >= etime) {
				if (getenv("dump_minimal_and_full")) {
					/* dump minidump and full dump*/
					if (do_dumpqca_data(MINIMAL_DUMP) == CMD_RET_FAILURE)
						printf("Minidump saving failed!\n");
					if (do_dumpqca_data(FULL_DUMP) == CMD_RET_FAILURE)
						printf("Crashdump saving failed!\n");
				} else {
					if (do_dumpqca_data(dump_level) == CMD_RET_FAILURE)
						printf("Crashdump saving failed!\n");
				}
				break;
			}
		}
	}
	/* reset the system, some images might not be loaded
	 * when crashmagic is found
	 */
exit:
	crashdump_exit();
}
#ifdef CONFIG_MTD_DEVICE

/*
* NAND flash check and write. Before writing into the nand flash
* this function checks if the block is non-bad, and skips if bad. While
* skipping, there is also possiblity of crossing the partition and corrupting
* next partition with crashdump data. So this function also checks whether
* offset is within the partition, where the configured offset belongs.
*
* Returns 0 on succes and 1 otherwise
*/
static int check_and_write_crashdump_nand_flash(
			struct crashdump_flash_nand_cxt *nand_cnxt,
			nand_info_t *nand, unsigned char *data,
			unsigned int req_size)
{
	nand_erase_options_t nand_erase_options;
	uint32_t part_start = nand_cnxt->part_start;
	uint32_t part_end = nand_cnxt->part_start + nand_cnxt->part_size;
	unsigned int remaining_len = req_size;
	unsigned int write_length, data_offset = 0;
	loff_t skipoff, skipoff_cmp, *offset;
	int ret = 0;
	static int first_erase = 1;

	offset = &nand_cnxt->cur_crashdump_offset;

	memset(&nand_erase_options, 0, sizeof(nand_erase_options));
	nand_erase_options.length = nand->erasesize;

	while (remaining_len)
	{

		skipoff = *offset - (*offset & (nand->erasesize - 1));
		skipoff_cmp = skipoff;

		for (; skipoff < part_end; skipoff += nand->erasesize) {
			if (nand_block_isbad(nand, skipoff)) {
				printf("Skipping bad block at 0x%llx\n", skipoff);
				continue;
			}
			else
				break;
		}
		if (skipoff_cmp != skipoff)
			*offset = skipoff;

		if(part_start > *offset || ((*offset + remaining_len) >= part_end)) {
			printf("Failure: Attempt to write in next partition\n");
			return 1;
		}

		if((*offset & (nand->erasesize - 1)) == 0 || first_erase){
			nand_erase_options.offset = *offset;

			ret = nand_erase_opts(&nand_info[0],
					&nand_erase_options);
			if (ret)
				return ret;
			first_erase = 0;
		}

		if( remaining_len > nand->erasesize) {

			skipoff = (*offset & (nand->erasesize - 1));

			write_length = (skipoff != 0) ? (nand->erasesize - skipoff)
							: (nand->erasesize);

			ret = nand_write(nand, *offset, &write_length,
				data + data_offset);

			if (ret)
				return ret;

			remaining_len -= write_length;
			*offset += write_length;
			data_offset += write_length;
		}
		else {

			ret = nand_write(nand, *offset, &remaining_len,
				data + data_offset);

			*offset += remaining_len;
			remaining_len = 0;
		}
	}

	return ret;

}

/*
* Init function for NAND flash writing. It intializes its own context
* and erases the required sectors
*/
int init_crashdump_nand_flash_write(void *cnxt, loff_t offset,
					unsigned int total_size)
{
	struct crashdump_flash_nand_cxt *nand_cnxt = cnxt;
	int ret;

	ret = smem_getpart_from_offset(offset, &nand_cnxt->part_start,
						&nand_cnxt->part_size);
	if (ret)
		return ret;

	nand_cnxt->start_crashdump_offset = offset;
	nand_cnxt->cur_crashdump_offset = offset;
	nand_cnxt->cur_page_data_len = 0;
	nand_cnxt->write_size = nand_info[0].writesize;

	if (nand_info[0].writesize > MAX_NAND_PAGE_SIZE) {
		printf("nand page write size is more than configured size\n");
		return -ENOMEM;
	}

	return 0;
}

/*
* Deinit function for NAND flash writing. It writes the remaining data
* stored in temp buffer to NAND.
*/
int deinit_crashdump_nand_flash_write(void *cnxt)
{
	struct crashdump_flash_nand_cxt *nand_cnxt = cnxt;
	unsigned int cur_nand_write_len = nand_cnxt->cur_page_data_len;
	int ret_val = 0;
	int remaining_bytes = nand_cnxt->write_size -
			nand_cnxt->cur_page_data_len;

	if (cur_nand_write_len) {
		/*
		* Make the write data in multiple of page write size
		* and write remaining data in NAND flash
		*/
		memset(nand_cnxt->temp_data + nand_cnxt->cur_page_data_len,
			0xFF, remaining_bytes);

		cur_nand_write_len = nand_cnxt->write_size;

		ret_val = check_and_write_crashdump_nand_flash(nand_cnxt,
					&nand_info[0], nand_cnxt->temp_data,
					cur_nand_write_len);

	}

	return ret_val;
}

/*
* Write function for NAND flash. NAND writing works on page basis so
* this function writes the data in mulitple of page size and stores the
* remaining data in temp buffer. This temp buffer data will be appended
* with next write data.
*/
int crashdump_nand_flash_write_data(void *cnxt,
		unsigned char *data, unsigned int size)
{
	struct crashdump_flash_nand_cxt *nand_cnxt = cnxt;
	unsigned char *cur_data_pos = data;
	unsigned int remaining_bytes;
	unsigned int total_bytes;
	unsigned int cur_nand_write_len;
	unsigned int remaining_len_cur_page;
	int ret_val;

	remaining_bytes = total_bytes = nand_cnxt->cur_page_data_len + size;

	/*
	* Check for minimum write size and store the data in temp buffer if
	* the total size is less than it
	*/
	if (total_bytes < nand_cnxt->write_size) {
		memcpy(nand_cnxt->temp_data + nand_cnxt->cur_page_data_len,
					data, size);
		nand_cnxt->cur_page_data_len += size;

		return 0;
	}

	/*
	* Append the remaining length of data for complete nand page write in
	* currently stored data and do the nand write
	*/
	remaining_len_cur_page = nand_cnxt->write_size -
			nand_cnxt->cur_page_data_len;
	cur_nand_write_len = nand_cnxt->write_size;

	memcpy(nand_cnxt->temp_data + nand_cnxt->cur_page_data_len, data,
			remaining_len_cur_page);

	ret_val = check_and_write_crashdump_nand_flash(nand_cnxt,
					&nand_info[0], nand_cnxt->temp_data,
					cur_nand_write_len);

	if (ret_val)
		return ret_val;

	cur_data_pos += remaining_len_cur_page;

	/*
	* Calculate the write length in multiple of page length and do the nand
	* write for same length
	*/
	cur_nand_write_len = ((data + size - cur_data_pos) /
				nand_cnxt->write_size) * nand_cnxt->write_size;

	if (cur_nand_write_len > 0) {
		ret_val = check_and_write_crashdump_nand_flash(nand_cnxt,
						&nand_info[0], cur_data_pos,
						cur_nand_write_len);

		if (ret_val)
			return ret_val;

	}

	cur_data_pos += cur_nand_write_len;

	/* Store the remaining data in temp data */
	remaining_bytes = data + size - cur_data_pos;

	memcpy(nand_cnxt->temp_data, cur_data_pos, remaining_bytes);

	nand_cnxt->cur_page_data_len = remaining_bytes;

	return 0;
}
#endif
#ifdef CONFIG_QCA_SPI
/* Init function for SPI NOR flash writing. It erases the required sectors */
int init_crashdump_spi_flash_write(void *cnxt,
			loff_t offset,
			unsigned int total_size)
{
	int ret;
	unsigned int required_erase_size;
	struct crashdump_flash_spi_cxt *spi_flash_cnxt = cnxt;

	spi_flash_cnxt->start_crashdump_offset = offset;
	spi_flash_cnxt->cur_crashdump_offset = offset;

	if (total_size & (sfi->flash_block_size - 1))
		required_erase_size = (total_size &
					~(sfi->flash_block_size - 1)) +
					sfi->flash_block_size;
	else
		required_erase_size = total_size;

	ret = spi_flash_erase(crashdump_spi_flash,
				offset,
				required_erase_size);

	return ret;
}

/* Write function for SPI NOR flash */
int crashdump_spi_flash_write_data(void *cnxt,
		unsigned char *data, unsigned int size)
{
	struct crashdump_flash_spi_cxt *spi_flash_cnxt = cnxt;
	unsigned int cur_size = size;
	int ret;

	ret = spi_flash_write(crashdump_spi_flash,
			spi_flash_cnxt->cur_crashdump_offset,
			cur_size, data);

	if (!ret)
		spi_flash_cnxt->cur_crashdump_offset += cur_size;

	return ret;
}

/* Deinit function for SPI NOR flash writing. */
int deinit_crashdump_spi_flash_write(void *cnxt)
{
	return 0;
}
#endif

#ifdef CONFIG_QCA_MMC
/* Init function for EMMC. It initialzes the EMMC */
static int crashdump_init_mmc(struct mmc *mmc)
{
	int ret;

	if (!mmc) {
		puts("No MMC card found\n");
		return -EINVAL;
	}

	ret = mmc_init(mmc);

	if (ret)
		puts("MMC init failed\n");

	return ret;
}

/*
* Init function for EMMC flash writing. It initialzes its
* own context and EMMC
*/
int init_crashdump_emmc_flash_write(void *cnxt, loff_t offset,
						unsigned int total_size)
{
	struct crashdump_flash_emmc_cxt *emmc_cnxt = cnxt;

	emmc_cnxt->start_crashdump_offset = offset;
	emmc_cnxt->cur_crashdump_offset = offset;
	emmc_cnxt->cur_blk_data_len = 0;
	emmc_cnxt->write_size =  mmc->write_bl_len;

	if (mmc->write_bl_len > MAX_EMMC_BLK_LEN) {
		printf("mmc block length is more than configured size\n");
		return -ENOMEM;
	}

	return 0;
}

/*
* Deinit function for EMMC flash writing. It writes the remaining data
* stored in temp buffer to EMMC
*/
int deinit_crashdump_emmc_flash_write(void *cnxt)
{
	struct crashdump_flash_emmc_cxt *emmc_cnxt = cnxt;
	unsigned int cur_blk_write_len = emmc_cnxt->cur_blk_data_len;
	int ret_val = 0;
	int n;
	int remaining_bytes = emmc_cnxt->write_size -
			emmc_cnxt->cur_blk_data_len;

	if (cur_blk_write_len) {
		/*
		* Make the write data in multiple of block length size
		* and write remaining data in emmc
		*/
		memset(emmc_cnxt->temp_data + emmc_cnxt->cur_blk_data_len,
			0xFF, remaining_bytes);

		cur_blk_write_len = emmc_cnxt->write_size;
		n = mmc->block_dev.block_write(CONFIG_SYS_MMC_CRASHDUMP_DEV,
						emmc_cnxt->cur_crashdump_offset,
						1,
						(u_char *)emmc_cnxt->temp_data);

		ret_val = (n == 1) ? 0 : -ENOMEM;
	}

	return ret_val;
}

/*
* Write function for EMMC flash. EMMC writing works on block basis so
* this function writes the data in mulitple of block length and stores
* remaining data in temp buffer. This temp buffer data will be appended
* with next write data.
*/
int crashdump_emmc_flash_write_data(void *cnxt,
		unsigned char *data, unsigned int size)
{
	struct crashdump_flash_emmc_cxt *emmc_cnxt = cnxt;
	unsigned char *cur_data_pos = data;
	unsigned int remaining_bytes;
	unsigned int total_bytes;
	unsigned int cur_emmc_write_len;
	unsigned int cur_emmc_blk_len;
	unsigned int remaining_len_cur_page;
	int ret_val;
	int n;

	remaining_bytes = total_bytes = emmc_cnxt->cur_blk_data_len + size;

	/*
	* Check for block size and store the data in temp buffer if
	* the total size is less than it
	*/
	if (total_bytes < emmc_cnxt->write_size) {
		memcpy(emmc_cnxt->temp_data + emmc_cnxt->cur_blk_data_len,
				data, size);
		emmc_cnxt->cur_blk_data_len += size;

		return 0;
	}

	/*
	* Append the remaining length of data for complete emmc block write in
	* currently stored data and do the block write
	*/
	remaining_len_cur_page = emmc_cnxt->write_size -
			emmc_cnxt->cur_blk_data_len;
	cur_emmc_write_len = emmc_cnxt->write_size;

	memcpy(emmc_cnxt->temp_data + emmc_cnxt->cur_blk_data_len, data,
			remaining_len_cur_page);

	n = mmc->block_dev.block_write(CONFIG_SYS_MMC_CRASHDUMP_DEV,
					emmc_cnxt->cur_crashdump_offset,
					1,
					(u_char *)emmc_cnxt->temp_data);

	ret_val = (n == 1) ? 0 : -ENOMEM;

	if (ret_val)
		return ret_val;

	cur_data_pos += remaining_len_cur_page;
	emmc_cnxt->cur_crashdump_offset += 1;
	/*
	* Calculate the write length in multiple of block length and do the
	* emmc block write for same length
	*/
	cur_emmc_blk_len = ((data + size - cur_data_pos) /
				emmc_cnxt->write_size);
	cur_emmc_write_len = cur_emmc_blk_len * emmc_cnxt->write_size;

	if (cur_emmc_write_len > 0) {
		n = mmc->block_dev.block_write(CONFIG_SYS_MMC_CRASHDUMP_DEV,
						emmc_cnxt->cur_crashdump_offset,
						cur_emmc_blk_len,
						(u_char *)cur_data_pos);

		ret_val = (n == cur_emmc_blk_len) ? 0 : -1;

		if (ret_val)
			return ret_val;
	}

	cur_data_pos += cur_emmc_write_len;
	emmc_cnxt->cur_crashdump_offset += cur_emmc_blk_len;

	/* Store the remaining data in temp data */
	remaining_bytes = data + size - cur_data_pos;

	memcpy(emmc_cnxt->temp_data, cur_data_pos, remaining_bytes);

	emmc_cnxt->cur_blk_data_len = remaining_bytes;

	return 0;
}
#endif

static int qca_wdt_write_crashdump_configure(int flash_type)
{
	int ret = 0;

	/*
	* Determine the flash type and initialize function pointer for flash
	* operations and its context which needs to be passed to these functions
	*/
	if (((flash_type == SMEM_BOOT_NAND_FLASH) ||
		(flash_type == SMEM_BOOT_QSPI_NAND_FLASH))) {
#ifdef CONFIG_MTD_DEVICE
		crashdump_cnxt = (void *)&crashdump_nand_cnxt;
		crashdump_flash_write_init = init_crashdump_nand_flash_write;
		crashdump_flash_write = crashdump_nand_flash_write_data;
		crashdump_flash_write_deinit =
			deinit_crashdump_nand_flash_write;
#endif
#ifdef CONFIG_QCA_SPI
	} else if (flash_type == SMEM_BOOT_SPI_FLASH) {
		if (!crashdump_spi_flash) {
			crashdump_spi_flash = spi_flash_probe(sfi->flash_index,
				sfi->flash_chip_select,
				CONFIG_CRASHDUMP_SPI_SPEED,
				CONFIG_CRASHDUMP_SPI_MODE);

			if (!crashdump_spi_flash) {
				printf("spi_flash_probe() failed");
				return -EIO;
			}
		}

		crashdump_cnxt = (void *)&crashdump_flash_spi_cnxt;
		crashdump_flash_write = crashdump_spi_flash_write_data;
		crashdump_flash_write_init = init_crashdump_spi_flash_write;
		crashdump_flash_write_deinit =
			deinit_crashdump_spi_flash_write;
#endif
#ifdef CONFIG_QCA_MMC
	} else if (flash_type == SMEM_BOOT_MMC_FLASH) {
		mmc = find_mmc_device(CONFIG_SYS_MMC_CRASHDUMP_DEV);

		ret = crashdump_init_mmc(mmc);

		if (ret)
			return ret;

		crashdump_cnxt = (void *)&crashdump_emmc_cnxt;
		crashdump_flash_write_init = init_crashdump_emmc_flash_write;
		crashdump_flash_write = crashdump_emmc_flash_write_data;
		crashdump_flash_write_deinit =
			deinit_crashdump_emmc_flash_write;
#endif
	} else {
		return -EINVAL;
	}

	return ret;
}

void set_minidump_bootargs(void)
{
	char runcmd[128], *part_name = getenv("dump_to_nvmem");
	int flash_type = sfi->flash_type;
	uint32_t * buf = NULL;

	switch (sfi->flash_type) {
	case SMEM_BOOT_NAND_FLASH:
	case SMEM_BOOT_QSPI_NAND_FLASH:
	case SMEM_BOOT_MMC_FLASH:
		flash_type = sfi->flash_type;
		break;

	case SMEM_BOOT_SPI_FLASH:
		if (get_which_flash_param(part_name))
			flash_type = SMEM_BOOT_QSPI_NAND_FLASH;
		else
			flash_type = SMEM_BOOT_MMC_FLASH;
		break;
	default:
		goto retn;
	}


	if ((flash_type == SMEM_BOOT_NAND_FLASH) ||
			(flash_type == SMEM_BOOT_QSPI_NAND_FLASH)) {
#ifdef CONFIG_MTD_DEVICE
		uint32_t offset, part_size, read_size = 64;

		if (getpart_offset_size(part_name, &offset, &part_size))
			goto retn;

		buf = malloc(read_size);
		if (!buf)
			goto retn;

		snprintf(runcmd, sizeof(runcmd), "nand read 0x%x 0x%x 0x%x",
				(uint32_t)buf, offset, read_size);
#endif
	} else {
#ifdef CONFIG_QCA_MMC
		block_dev_desc_t *blk_dev = mmc_get_dev(0);
		disk_partition_t disk_info;

		if (!blk_dev)
			goto retn;

		if (get_partition_info_efi_by_name(blk_dev, part_name,
					&disk_info))
			goto retn;

		buf = malloc(disk_info.blksz);
		if (!buf)
			goto retn;

		snprintf(runcmd, sizeof(runcmd), "mmc read 0x%x 0x%lx 0x1",
				(uint32_t)buf, disk_info.start);
#endif
	}

	if (run_command(runcmd, 0)) {
		free(buf);
		goto retn;
	}

	if (buf && (buf[0] == MINIDUMP_MAGIC1_COOKIE) &&
			(buf[1] == MINIDUMP_MAGIC2_COOKIE))
		run_command("setenv bootargs ${bootargs} collect_minidump", 0);

retn:
	return;
}

/*
* This function writes the crashdump data in flash memory.
* It has function pointers for init, deinit and writing. These
* function pointers are being initialized with respective flash
* memory writing routines.
*/
static int qca_wdt_write_crashdump_data(
		struct qca_wdt_crashdump_data *crashdump_data,
		loff_t crashdump_offset)
{
	int ret = 0;
	unsigned int required_size;

	/* Start writing cpu context and uname in flash */
	required_size = CONFIG_CPU_CONTEXT_DUMP_SIZE +
				crashdump_data->uname_length;

	ret = crashdump_flash_write_init(crashdump_cnxt,
			crashdump_offset,
			required_size);

	if (ret)
		return ret;

	ret = crashdump_flash_write(crashdump_cnxt,
			crashdump_data->cpu_context,
			CONFIG_CPU_CONTEXT_DUMP_SIZE);

	if (!ret)
		ret = crashdump_flash_write(crashdump_cnxt,
			crashdump_data->uname,
			crashdump_data->uname_length);

	if (!ret)
		ret = crashdump_flash_write_deinit(crashdump_cnxt);

	return ret;
}



/*
* Function for collecting the crashdump data in flash. It extracts the
* crashdump TLV(Type Length Value) data and CPU context information from
* page allocated by kernel for crashdump data collection. It determines
* the type of boot flash memory and writes all these crashdump information
* in provided offset in flash memory.
*/
int do_dumpqca_minimal_data(const char *offset)
{
	unsigned char *kernel_crashdump_address =
		(unsigned char *) CONFIG_QCA_KERNEL_CRASHDUMP_ADDRESS;
	int flash_type;
	int ret_val;
	loff_t crashdump_offset;
	char *dump_to_flash = getenv("dump_to_flash");
	char *dump_to_nvmem = NULL;

	if (dump_to_flash) {
		setenv("dump_to_nvmem", "");
		setenv("dump_to_mem", "");
	} else {
		dump_to_nvmem = getenv("dump_to_nvmem");
		if (dump_to_nvmem)
			setenv("dump_to_mem", "");
	}

	if (sfi->flash_type == SMEM_BOOT_NAND_FLASH) {
		flash_type = SMEM_BOOT_NAND_FLASH;
	} else if (sfi->flash_type == SMEM_BOOT_QSPI_NAND_FLASH) {
		flash_type = SMEM_BOOT_QSPI_NAND_FLASH;
	} else if (sfi->flash_type == SMEM_BOOT_SPI_FLASH) {
		flash_type = SMEM_BOOT_SPI_FLASH;
#ifdef CONFIG_QCA_MMC
	} else if (sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
		flash_type = SMEM_BOOT_MMC_FLASH;
#endif
	} else {
		printf("command not supported for this flash memory\n");
		return -EINVAL;
	}

	ret_val = str2off(offset, &crashdump_offset);

	if (!ret_val)
		return -EINVAL;

	g_crashdump_data.cpu_context = kernel_crashdump_address;
	tlv_msg.msg_buffer = kernel_crashdump_address + TLV_BUF_OFFSET;
	tlv_msg.cur_msg_buffer_pos = tlv_msg.msg_buffer;
	tlv_msg.len = CONFIG_TLV_DUMP_SIZE;

	ret_val = qca_wdt_extract_crashdump_data(&tlv_msg, &g_crashdump_data);
	if (ret_val) {
		printf("%s: crashdump extraction failed\n", __func__);
		return ret_val;
	}

	if (dump_to_flash || dump_to_nvmem)
	{
		if (dump_to_nvmem) {
			if (flash_type == SMEM_BOOT_SPI_FLASH) {
				if (get_which_flash_param(dump_to_nvmem))
					flash_type = SMEM_BOOT_QSPI_NAND_FLASH;
				else
					flash_type = SMEM_BOOT_MMC_FLASH;
			}

			dump2nvmem_info.flash_type = flash_type;
			if ((flash_type == SMEM_BOOT_NAND_FLASH) ||
					(flash_type == SMEM_BOOT_QSPI_NAND_FLASH)) {
#ifdef CONFIG_MTD_DEVICE
				uint32_t off, size, valid_start_off;
				uint8_t valid_start_found = 0;
				ret_val = getpart_offset_size(dump_to_nvmem,
						&off, &size);
 				if (ret_val) {
					printf("Error: %s Invalid partition\n", dump_to_nvmem);
					return ret_val;
				}

				dump2nvmem_info.offset = valid_start_off = off;
				dump2nvmem_info.size = size;
				dump2nvmem_info.blksize = nand_info[0].erasesize;
				dump2nvmem_info.dump_off = nand_info[0].erasesize;;
				for (; off < (dump2nvmem_info.offset + size);
						off += nand_info[0].erasesize) {
					if (nand_block_isbad(&nand_info[0], off)) {
						dump2nvmem_info.size -= nand_info[0].erasesize;
					} else if (!valid_start_found) {
						valid_start_off = off;
						valid_start_found = 1;
					}
				}

				if (!dump2nvmem_info.size) {
					printf("Error: %s bad partition\n", dump_to_nvmem);
					return -EIO;
				} else
					dump2nvmem_info.offset = valid_start_off;
#endif
			} else {
#ifdef CONFIG_QCA_MMC
				block_dev_desc_t *blk_dev = mmc_get_dev(0);
				disk_partition_t disk_info;

				if (!blk_dev) {
					printf("Error: %s Invalid partition\n", dump_to_nvmem);
					return ret_val;
				}

				ret_val = get_partition_info_efi_by_name(blk_dev,
						dump_to_nvmem, &disk_info);
				if (ret_val) {
					printf("Error: %s Invalid partition\n", dump_to_nvmem);
					return ret_val;
				}

				dump2nvmem_info.offset = disk_info.start;
				dump2nvmem_info.dump_off = 1;
				dump2nvmem_info.blksize = disk_info.blksz;
				dump2nvmem_info.size = disk_info.size * disk_info.blksz;
#endif
			}
		}

		ret_val = qca_wdt_write_crashdump_configure(flash_type);
		if (ret_val) {
			printf("crashdump configure flash failure\n");
			return ret_val;
		}
	}

	if (dump_to_flash) {
		ret_val = qca_wdt_write_crashdump_data(&g_crashdump_data,
						       crashdump_offset);
		if (ret_val) {
			printf("crashdump data writing in flash failure\n");
			return -EPERM;
		}

		printf("crashdump data writing in flash successful\n");
	} else {
		dump_func(MINIMAL_DUMP);
	}

	return 0;
}
