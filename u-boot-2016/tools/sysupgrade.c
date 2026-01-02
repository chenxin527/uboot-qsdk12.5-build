/*
 * Copyright (c) 2015-2016, The Linux Foundation. All rights reserved.
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

#include <sysupgrade.h>

#define SBL_VERSION_FILE       "sbl_version"
#define TZ_VERSION_FILE        "tz_version"
#define HLOS_VERSION_FILE      "hlos_version"
#define APPSBL_VERSION_FILE    "appsbl_version"
#define RPM_VERSION_FILE       "rpm_version"
#define DEVCFG_VERSION_FILE	"devcfg_version"
#define APDP_VERSION_FILE	"apdp_version"
#define VERSION_FILE_BASENAME  "/sys/devices/system/qfprom/qfprom0/"
#define AUTHENTICATE_FILE	"/sys/devices/system/qfprom/qfprom0/authenticate"
#define SEC_AUTHENTICATE_FILE  "/sys/sec_upgrade/sec_auth"
#define TEMP_KERNEL_PATH	"/tmp/tmp_kernel.bin"
#define TEMP_ROOTFS_PATH	"/tmp/rootfs_tmp.bin"
#define TEMP_METADATA_PATH	"/tmp/metadata.bin"
#define TEMP_SHA_KEY_PATH	"/tmp/sha_keyXXXXXX"
#define ROOTFS_OFFSET		65536
#define MAX_SBL_VERSION	11
#define MAX_HLOS_VERSION	32
#define MAX_TZ_VERSION		14
#define MAX_APPSBL_VERSION	14
#define MAX_RPM_VERSION	8
#define MAX_DEVCFG_VERSION	11
#define MAX_APDP_VERSION	8
#define HASH_P_FLAG		0x02200000
#define TMP_FILE_DIR		"/tmp/"
#define CERT_SIZE		2048
#define PRESENT		1
#define MBN_HDR_SIZE		40
#define SBL_HDR_SIZE		80
#define SIG_SIZE		256
#define NOT_PRESENT		0
#define SIG_CERT_2_SIZE	4352
#define SIG_CERT_3_SIZE	6400
#define SBL_NAND_PREAMBLE	10240
#define SBL_HDR_RESERVED	12
#define UBI_EC_HDR_MAGIC  0x55424923
#define UBI_VID_HDR_MAGIC 0x55424921
#define NO_OF_PROGRAM_HDRS   3

struct image_section sections[] = {
	{
		.section_type		= UBOOT_TYPE,
		.type			= "u-boot",
		.max_version		= MAX_APPSBL_VERSION,
		.file			= TMP_FILE_DIR,
		.version_file		= APPSBL_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0x9"
	},
	{
		.section_type		= HLOS_TYPE,
		.type			= "hlos",
		.max_version		= MAX_HLOS_VERSION,
		.tmp_file		= TMP_FILE_DIR,
		.pre_op			= parse_elf_image_phdr,
		.file			= TMP_FILE_DIR,
		.version_file		= HLOS_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0x17"
	},
	{
		.section_type		= HLOS_TYPE,
		.type			= "rootfs",
		.max_version		= MAX_HLOS_VERSION,
		.tmp_file		= TMP_FILE_DIR,
		.pre_op			= compute_sha_hash,
		.file			= TMP_FILE_DIR,
		.version_file		= HLOS_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0x17"
	},
	{
		.section_type		= HLOS_TYPE,
		.type			= "ubi",
		.tmp_file		= TMP_FILE_DIR,
		.pre_op			= extract_binary,
		.max_version		= MAX_HLOS_VERSION,
		.file			= TEMP_KERNEL_PATH,
		.version_file		= HLOS_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0x17"
	},
	{
		.section_type		= TZ_TYPE,
		.type			= "tz",
		.max_version		= MAX_TZ_VERSION,
		.file			= TMP_FILE_DIR,
		.version_file		= TZ_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0x7"
	},
	{
		.section_type		= SBL_TYPE,
		.type			= "sbl1",
		.max_version		= MAX_SBL_VERSION,
		.file			= TMP_FILE_DIR,
		.version_file		= SBL_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0x0"
	},
	{
		.section_type		= SBL_TYPE,
		.type			= "sbl2",
		.max_version		= MAX_SBL_VERSION,
		.file			= TMP_FILE_DIR,
		.version_file		= SBL_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0x5"
	},
	{
		.section_type		= SBL_TYPE,
		.type			= "sbl3",
		.max_version		= MAX_SBL_VERSION,
		.file			= TMP_FILE_DIR,
		.version_file		= SBL_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0x6"
	},
	{
		.section_type		= RPM_TYPE,
		.type			= "rpm",
		.max_version		= MAX_RPM_VERSION,
		.file			= TMP_FILE_DIR,
		.version_file		= RPM_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0xA"
	},
	{
		.section_type		= DEVCFG_TYPE,
		.type			= "devcfg",
		.max_version		= MAX_DEVCFG_VERSION,
		.file			= TMP_FILE_DIR,
		.version_file		= DEVCFG_VERSION_FILE,
		.is_present		= NOT_PRESENT,
		.img_code		= "0x5"
	},
	{
		.section_type           = APDP_TYPE,
		.type                   = "apdp",
		.max_version            = MAX_APDP_VERSION,
		.file                   = TMP_FILE_DIR,
		.version_file           = APDP_VERSION_FILE,
		.is_present             = NOT_PRESENT,
		.img_code               = "0x200"
	},
};

#define NO_OF_SECTIONS	ARRAY_SIZE(sections)
int src_size;

int check_mbn_elf(struct image_section **sec)
{
	int fd = open((*sec)->file, O_RDONLY);
	struct stat sb;
	uint8_t *fp;
	Elf32_Ehdr *elf;

	if (fd < 0) {
		perror((*sec)->file);
		return 0;
	}

	memset(&sb, 0, sizeof(struct stat));
	if (fstat(fd, &sb) == -1) {
		perror("fstat");
		close(fd);
		return 0;
	}

	fp = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (fp == MAP_FAILED) {
		perror("mmap");
		close(fd);
		return 0;
	}

	elf = (Elf32_Ehdr *)fp;
	if (!strncmp((char *)&(elf->e_ident[1]), "ELF", 3)) {
		/* EI_CLASS Check for 32/64-bit */
		if( ((int)(elf->e_ident[4])) == 2) {
			(*sec)->get_sw_id = get_sw_id_from_component_bin_elf64;
			(*sec)->split_components = split_code_signature_cert_from_component_bin_elf64;
		} else {
			(*sec)->get_sw_id = get_sw_id_from_component_bin_elf;
			(*sec)->split_components = split_code_signature_cert_from_component_bin_elf;
		}
	} else if (!strncmp((char *)&(((Elf32_Ehdr *)(fp + SBL_NAND_PREAMBLE))->e_ident[1]), "ELF", 3)) {
		if( ((int)(elf->e_ident[4])) == 2) {
			(*sec)->get_sw_id = get_sw_id_from_component_bin_elf64;
			(*sec)->split_components = split_code_signature_cert_from_component_bin_elf64;
		} else {
			(*sec)->get_sw_id = get_sw_id_from_component_bin_elf;
			(*sec)->split_components = split_code_signature_cert_from_component_bin_elf;
		}
	} else {
		(*sec)->get_sw_id = get_sw_id_from_component_bin;
		(*sec)->split_components = split_code_signature_cert_from_component_bin;
	}

	return 1;
}

int get_sections(void)
{
	DIR *dir = opendir(TMP_FILE_DIR);
	struct dirent *file;
	int i,data_size;
	struct image_section *sec;

	if (dir == NULL) {
		printf("Error accessing the image directory\n");
		return 0;
	}

	data_size = find_mtd_part_size("kernel");
	while ((file = readdir(dir)) != NULL) {
		for (i = 0, sec = &sections[0]; i < NO_OF_SECTIONS; i++, sec++) {
			/* Skip loading of ubi section if board is not from nand boot */
			if (data_size == -1 && !strncmp(sec->type, "ubi", strlen("ubi")))
				continue;
			if (!strncmp(file->d_name, sec->type, strlen(sec->type))) {
				strlcat(sec->file, file->d_name, sizeof(sec->file));
				if (sec->pre_op) {
					strlcat(sec->tmp_file, file->d_name,
							sizeof(sec->tmp_file));
					if (!sec->pre_op(sec)) {
						printf("Error extracting kernel from ubi\n");
						return 0;
					}
				}
				if (!check_mbn_elf(&sec)) {
					closedir(dir);
					return 0;
				}
				if (!sec->get_sw_id(sec)) {
					closedir(dir);
					return 0;
				}
				get_local_image_version(sec);
				sec->is_present = PRESENT;
				break;
			}
		}
	}
	closedir(dir);
	return 1;
}

int load_sections(void)
{
	DIR *dir;
	int i,data_size;
	struct dirent *file;
	struct image_section *sec;

	dir = opendir(TMP_FILE_DIR);
	if (dir == NULL) {
		printf("Error accessing the %s image directory\n", TMP_FILE_DIR);
		return 0;
	}

	data_size = find_mtd_part_size("kernel");
	while ((file = readdir(dir)) != NULL) {
		for (i = 0, sec = &sections[0]; i < NO_OF_SECTIONS; i++, sec++) {
			/* Skip loading of ubi section if board is not from nand boot */
			if (data_size == -1 && !strncmp(sec->type, "ubi", strlen("ubi")))
				continue;
			if (!strncmp(file->d_name, sec->type, strlen(sec->type))) {
				strlcat(sec->file, file->d_name, sizeof(sec->file));
				if (sec->pre_op) {
					strlcat(sec->tmp_file, file->d_name,
							sizeof(sec->tmp_file));
					if (!sec->pre_op(sec)) {
						printf("Error extracting %s from ubi\n",
									   sec->tmp_file);
						closedir(dir);
						return 0;
					}
				}
				sec->is_present = PRESENT;
				break;
			}
		}
	}
	closedir(dir);
	return 1;
}

/**
 * is_authentication_check_enabled() - checks whether installed image is
 * secure(1) or not(0)
 *
 */
int is_authentication_check_enabled(void)
{
	int fd = open(AUTHENTICATE_FILE, O_RDONLY);
	char authenticate_string[4];
	int len;

	if (fd == -1) {
		perror(AUTHENTICATE_FILE);
		return 0;
	}

	len = read(fd, authenticate_string, 1);
	close(fd);

	if (len > 0 && authenticate_string[0] == '0') {
		return 0;
	}

	return 1;
}

int is_tz_authentication_enabled(void)
{
	struct stat sb;

	if (stat(SEC_AUTHENTICATE_FILE, &sb) == -1) {
		perror("stat");
		return 0;
	}
	return 1;
}

int is_rootfs_auth_enabled(void)
{
	char command[36];
	int retval;

	snprintf(command, sizeof(command),"fw_printenv | grep -q rootfs_auth");

	retval = system(command);
	if (retval != 0) {
		return 0;
	}

	return 1;
}

/**
 * get_local_image_version() check the version file & if it exists, read the
 * value & save it into global variable local_version
 *
 */
int get_local_image_version(struct image_section *section)
{
	int len, fd;
	char local_version_string[16], version_file[64];
	struct stat st;

	snprintf(version_file, sizeof(version_file), "%s%s", VERSION_FILE_BASENAME, section->version_file);
	fd = open(version_file, O_RDONLY);
	if (fd == -1) {
		perror(version_file);
		return 0;
	}

	memset(&st, 0, sizeof(struct stat));
	fstat(fd, &st);

	len = st.st_size < sizeof(local_version_string) - 1 ? st.st_size :
							sizeof(local_version_string) - 1;
	if (read(fd, local_version_string, len) == -1) {
		close(fd);
		return 0;
	}
	local_version_string[len] = '\0';
	close(fd);

	section->local_version = atoi(local_version_string);
	printf("Local image version:%s\n", local_version_string);

	return 1;
}

/**
 * set_local_image_version() update the version of the image by writing the version
 * to the version file
 *
 */
int set_local_image_version(struct image_section *section)
{
	int fd;
	char version_string[16], version_file[64];
	int len;

	snprintf(version_file, sizeof(version_file), "%s%s", TMP_FILE_DIR, section->version_file);
	fd = open(version_file, O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR);
	if (fd == -1) {
		perror(version_file);
		return 0;
	}

	len = snprintf(version_string, 8, "%d", section->img_version);
	if (len < 0) {
		printf("Error in formatting the version string");
		return 0;
	}

	printf("Version to be updated:%s\n", version_string);
	if (write(fd, version_string, len) == -1) {
		printf("Error writing version to %s\n", version_file);
		close(fd);
		return 0;
	}

	close(fd);
	return 1;
}

/**
 * is_version_check_enabled() checks whether version check is
 * enabled(non-zero value) or not
 *
 */
int is_version_check_enabled()
{
	if (get_local_image_version(&sections[0]) != -1) {
		printf("Returning 1 from is_version_check_enabled because local_version_string is non-ZERO\n");
		return 1;
	}

	return 0;
}

char *find_value(char *buffer, char *search, int size)
{
	char *value = malloc(size * sizeof(char));
	int i, j;

	if (value == NULL) {
		return NULL;
	}

	for (i = 0; i < CERT_SIZE; i++) {
		for (j = 0; search[j] && (buffer[i + j] == search[j]); j++);
		if (search[j] == '\0') {
			strlcpy(value, &buffer[i - size], size);
			value[size - 1] = '\0';
			return value;
		}
	}
	free(value);
	return NULL;
}

/**
 * check_nand_preamble() compares first 12 bytes of section with
 * pre defined PREAMBLE value and returns 0 if both value matches
 */
int check_nand_preamble(uint8_t *mfp)
{
	char magic[12] = { 0xd1, 0xdc, 0x4b, 0x84,
			   0x34, 0x10, 0xd7, 0x73,
			   0x5a, 0x43, 0x0b, 0x7d };
	return memcmp(magic, mfp, sizeof(magic));
}

/**
 * get_sw_id_from_component_bin() parses the MBN header & checks image size v/s
 * code size. If both differ, it means signature & certificates are
 * appended at end.
 * Extract the attestation certificate & read the Subject & retreive the SW_ID.
 *
 * @bin_file: struct image_section *
 */
int get_sw_id_from_component_bin(struct image_section *section)
{
	Mbn_Hdr *mbn_hdr;
	int fd = open(section->file, O_RDONLY);
	struct stat sb;
	uint8_t *fp;
	int cert_offset;
	char *sw_version;
	int sig_cert_size;

	if (fd == -1) {
		perror(section->file);
		return 0;
	}

	memset(&sb, 0, sizeof(struct stat));
	if (fstat(fd, &sb) == -1) {
		perror("fstat");
		close(fd);
		return 0;
	}

	fp = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (fp == MAP_FAILED) {
		perror("mmap");
		close(fd);
		return 0;
	}

	mbn_hdr = (Mbn_Hdr *)fp;
	if (strstr(section->file, sections[4].type)) {
		uint32_t preamble = !check_nand_preamble(fp) ? SBL_NAND_PREAMBLE : 0;
		Sbl_Hdr *sbl_hdr = (Sbl_Hdr *)(fp + preamble);

		sig_cert_size = sbl_hdr->image_size - sbl_hdr->code_size;
		cert_offset = preamble + sbl_hdr->cert_ptr - sbl_hdr->image_dest_ptr +
				SBL_HDR_SIZE;
	} else {
		sig_cert_size = mbn_hdr->image_size - mbn_hdr->code_size;
		cert_offset = mbn_hdr->cert_ptr - mbn_hdr->image_dest_ptr + 40;
	}
	if (sig_cert_size != SIG_CERT_2_SIZE && sig_cert_size != SIG_CERT_3_SIZE) {
		printf("WARNING: signature certificate size is different\n");
		// ipq807x has certificate size as dynamic, hence ignore this check
	}

	printf("Image with version information\n");
	sw_version = find_value((char *)(fp + cert_offset), "SW_ID", 17);
	if (sw_version != NULL) {
		sw_version[8] = '\0';
		sscanf(sw_version, "%x", &section->img_version);
		printf("SW ID:%d\n", section->img_version);
		free(sw_version);
	}

	close(fd);
	return 1;
}

int process_elf(char *bin_file, uint8_t **fp, Elf32_Ehdr **elf, Elf32_Phdr **phdr, Mbn_Hdr **mbn_hdr)
{
	int fd = open(bin_file, O_RDONLY);
	struct stat sb;
	int version = 0;
	int i = 0;

	if (fd < 0) {
		perror(bin_file);
		return 0;
	}

	memset(&sb, 0, sizeof(struct stat));
	if (fstat(fd, &sb) == -1) {
		perror("fstat");
		close(fd);
		return 0;
	}

	*fp = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (*fp == MAP_FAILED) {
		perror("mmap");
		close(fd);
		return 0;
	}

	*elf = (Elf32_Ehdr *)*fp;
	while (strncmp((char *)&((*elf)->e_ident[1]), "ELF", 3)) {
		*fp = (uint8_t *)((char *)(*fp) + SBL_NAND_PREAMBLE);
		*elf = (Elf32_Ehdr *)*fp;
	}

	*phdr = (Elf32_Phdr *)(*fp + (*elf)->e_phoff);
	for (i = 0; i < (*elf)->e_phnum; i++, (*phdr)++) {
		if ((*phdr)->p_flags == HASH_P_FLAG) {
			*mbn_hdr = (Mbn_Hdr *)(*fp + (*phdr)->p_offset);
			if ((*mbn_hdr)->image_size != (*mbn_hdr)->code_size) {
				version = 1;
				break;
			} else {
				printf("Error: Image without version information\n");
				close(fd);
				return 0;
			}
		}
	}

	if (version != 1) {
		printf("Error: Image without version information\n");
		return 0;
	}

	close(fd);
	return 1;
}

int process_elf64(char *bin_file, uint8_t **fp, Elf64_Ehdr **elf, Elf64_Phdr **phdr, Mbn_Hdr **mbn_hdr)
{
	struct stat sb;
	int i, fd, version = 0;

	fd = open(bin_file, O_RDONLY);
	if (fd < 0) {
		perror(bin_file);
		return 0;
	}

	memset(&sb, 0, sizeof(struct stat));
	if (fstat(fd, &sb) == -1) {
		perror("fstat");
		close(fd);
		return 0;
	}

	*fp = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (*fp == MAP_FAILED) {
		perror("mmap");
		close(fd);
		return 0;
	}

	*elf = (Elf64_Ehdr *)*fp;
	while (strncmp((char *)&((*elf)->e_ident[1]), "ELF", 3)) {
		*fp = (uint8_t *)((char *)(*fp) + SBL_NAND_PREAMBLE);
		*elf = (Elf64_Ehdr *)*fp;
	}

	*phdr = (Elf64_Phdr *)(*fp + (*elf)->e_phoff);
	for (i = 0; i < (*elf)->e_phnum; i++, (*phdr)++) {
		if ((*phdr)->p_flags == HASH_P_FLAG) {
			*mbn_hdr = (Mbn_Hdr *)(*fp + (*phdr)->p_offset);
			if ((*mbn_hdr)->image_size != (*mbn_hdr)->code_size) {
				version = 1;
				break;
			} else {
				printf("Error: Image without version information\n");
				close(fd);
				return 0;
			}
		}
	}

	if (version != 1) {
		printf("Error: Image without version information\n");
		return 0;
	}

	close(fd);
	return 1;
}

/**
 * get_sw_id_from_component_bin_elf() parses the ELF header to get the MBN header
 * of the hash table segment. Parses the MBN header of hash table segment & checks
 * total size v/s actual component size. If both differ, it means signature &
 * certificates are appended at end.
 * Extract the attestation certificate & read the Subject & retreive the SW_ID.
 *
 * @bin_file: struct image_section *
 */
int get_sw_id_from_component_bin_elf(struct image_section *section)
{
	Elf32_Ehdr *elf;
	Elf32_Phdr *phdr;
	Mbn_Hdr *mbn_hdr;
	uint8_t *fp;
	int cert_offset;
	char *sw_version;

	if (!process_elf(section->file, &fp, &elf, &phdr, &mbn_hdr)) {
		return 0;
	}

	cert_offset = mbn_hdr->cert_ptr - mbn_hdr->image_dest_ptr + 40;
	printf("Image with version information\n");
	sw_version = find_value((char *)(fp + phdr->p_offset + cert_offset), "SW_ID", 17);
	if (sw_version) {
		sw_version[8] = '\0';
		sscanf(sw_version, "%x", &section->img_version);
		printf("SW ID:%d\n", section->img_version);
		free(sw_version);
	}

	return 1;
}

/**
 * get_sw_id_from_component_bin_elf64() parses the ELF64 header to get the MBN header
 * of the hash table segment. Parses the MBN header of hash table segment & checks
 * total size v/s actual component size. If both differ, it means signature &
 * certificates are appended at end.
 * Extract the attestation certificate & read the Subject & retreive the SW_ID.
 *
 32_Phdr *phdr;* @bin_file: struct image_section *
 */
int get_sw_id_from_component_bin_elf64(struct image_section *section)
{
	Elf64_Ehdr *elf;
	Elf64_Phdr *phdr;
	Mbn_Hdr *mbn_hdr;
	uint8_t *fp;
	int cert_offset;
	char *sw_version;

	if (!process_elf64(section->file, &fp, &elf, &phdr, &mbn_hdr)) {
		return 0;
	}

	cert_offset = mbn_hdr->code_size + mbn_hdr->sig_sz + 40;
	printf("Image with version information64\n");
	sw_version = find_value((char *)(fp + phdr->p_offset + cert_offset), "SW_ID", 17);
	if (sw_version) {
		sw_version[8] = '\0';
		sscanf(sw_version, "%x", &section->img_version);
		printf("SW ID:%d\n", section->img_version);
		free(sw_version);
	}

	return 1;
}

int find_mtd_part_size(char *mtdname)
{
	char prefix[] = "/dev/mtd";
	char dev[PATH_MAX];
	int i = -1, fd;
	int vol_size;
	int flag = 0;
	char mtd_part[256];
	FILE *fp = fopen("/proc/mtd", "r");
	mtd_info_t mtd_dev_info = {0};

	if (fp == NULL) {
		printf("Error finding mtd part\n");
		return -1;
	}

	while (fgets(dev, sizeof(dev), fp)) {
		if (strstr(dev, mtdname)) {
			flag = 1;
			break;
		}
		i++;
	}
	fclose(fp);

	if (flag != 1) {
		printf("%s block not found\n", mtdname);
		return -1;
	}

	snprintf(mtd_part, sizeof(mtd_part), "%s%d", prefix, i);

	fd = open(mtd_part, O_RDWR);
	if (fd == -1) {
		return -1;
	}

	if (ioctl(fd, MEMGETINFO, &mtd_dev_info) == -1) {
		printf("Error getting block size\n");
		close(fd);
		return -1;
	}

	vol_size = mtd_dev_info.erasesize;
	close(fd);

	return vol_size;
}

/**
 * Helper function to dynamically get volume id
 */
int get_ubi_volume_id(char *vol_name)
{
	int i, number_of_ubi_volumes;
	char ubi_vol_count[] = "/sys/class/ubi/ubi0/volumes_count";
	char prefix[] = "/sys/class/ubi/ubi0_";
	char suffix[] = "/name";
	char ubi_vol[256];
	char ubi_vol_name[256];
	char current_ubi_volumes_count[256];
	FILE *fp;

	fp = fopen(ubi_vol_count, "r");
	if (fp == NULL) {
		printf("Error finding volumes count\n");
		return 0;
	}

	if (fgets(current_ubi_volumes_count, sizeof(current_ubi_volumes_count), fp) == NULL) {
		printf(" Failed to get ubi volumes count \n");
		return 0;
	}
	number_of_ubi_volumes = atoi(current_ubi_volumes_count);
	printf("number of ubi volumes = %d\n", number_of_ubi_volumes);

	for (i = 0; i < number_of_ubi_volumes; i++)
	{
		snprintf(ubi_vol, sizeof(ubi_vol), "%s%d%s", prefix, i, suffix);
		fp = fopen(ubi_vol, "r");
		if (fp == NULL) {
			printf("Error opening ubi volumes count\n");
			return 0;
		}
		if (fgets(ubi_vol_name, sizeof(ubi_vol_name), fp) == NULL) {
			printf(" Failed to get ubi volume name \n");
			return 0;
		}
		if (strstr(ubi_vol_name, vol_name)) {
			printf("%s volume id = %d\n", vol_name, i);
			fclose(fp);
			return i;
		}
	}

	return -1;
}

/**
 * For NAND image, kernel and rootfs image is ubinized.
 * Hence need to un-ubinize the ubi image and extract both kernel
 * and rootfs images. Kernel image section and volume name are passed as
 * argument in extract_kernel_binary(). After kernel extraction,
 * parse_elf_image_phdr() is called which parses the ELF32 program header
 * to get the ELF header of rootfs metadata.
 */

int extract_binary(struct image_section *section)
{
	extract_kernel_binary(section, "kernel");
	parse_elf_image_phdr(section);
	return 1;
}

/**
 * In case of NAND image, Kernel image is ubinized & version information is
 * part of Kernel image. Hence need to un-ubinize the image.
 * To get the kernel image, Find the volume with kernel's volume id. Kernel image
 * is fragmented and hence we need to assemble it to get complete image.
 * In UBI image, first look for UBI#, which is the magic number used to identify
 * each eraseble block. Parse the UBI header, which starts with UBI# & get
 * the VID(volume ID) header offset as well as Data offset.
 * Traverse to VID header offset & check the volume ID. If it is matching with
 * kernel Volume id extracted based on ubi sysfs, Kernel image is stored in
 * this volume. Use Data offset to extract the Kernel image.
 *
 * @bin_file: struct image_section *
 */

int extract_kernel_binary(struct image_section *section, char *volname)
{
	char *ifname, *ofname;

	strlcpy(section->file, TEMP_KERNEL_PATH, sizeof(TEMP_KERNEL_PATH));
	ifname = section->tmp_file;
	ofname = section->file;

	if (extract_ubi_volume(volname, ifname, ofname) != 1) {
		printf("Image extraction failed\n");
		return 0;
	}
	return 1;
}

/**
 * extract_ubi_volume() extracts both kernel image and rootfs image
 * from UBI image. extract_kernel_binary() passes volume name,
 * UBI image as Input file name, kernel or rootfs as Output file name.
 * This function finds respective UBI volume ID, identifies each eraseble
 * block. Parses UBI header and gets Volume ID header offset as well as
 * Data offset. When volume ID matches for kernel and rootfs, Uses data offset
 * to extract both images separately.
 */

int extract_ubi_volume(char *vol_name, char *if_name, char *of_name)
{
	struct ubi_ec_hdr *ubi_ec;
	struct ubi_vid_hdr *ubi_vol;
	uint8_t *fp;
	int fd, ofd, magic, data_size, vid_hdr_offset, data_offset;
	int ret_vol_id, curr_vol_id;
	struct stat sb;

	if (if_name == NULL) {
		return 0;
	}

	fd = open(if_name, O_RDONLY);
	if (fd < 0) {
		perror(if_name);
		return 0;
	}

	memset(&sb, 0, sizeof(struct stat));
	if (fstat(fd, &sb) == -1) {
		perror("fstat");
		close(fd);
		return 0;
	}

	fp = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (fp == MAP_FAILED) {
		perror("mmap");
		close(fd);
		return 0;
	}

	ofd = open(of_name, O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR);
	if (ofd == -1) {
		perror(of_name);
		close(fd);
		return 0;
	}

	data_size = find_mtd_part_size(vol_name);
	if (data_size == -1) {
		printf("Error finding data size\n");
		return 0;
	}

	ret_vol_id = get_ubi_volume_id(vol_name);
	if (ret_vol_id == -1) {
		printf("Wrong ubi volume id for kernel\n");
		return 0;
	}

	ubi_ec = (struct ubi_ec_hdr *)fp;
	magic = be32_to_cpu(ubi_ec->magic);
	while (magic == UBI_EC_HDR_MAGIC) {
		vid_hdr_offset = be32_to_cpu(ubi_ec->vid_hdr_offset);
		data_offset = be32_to_cpu(ubi_ec->data_offset);
		ubi_vol = (struct ubi_vid_hdr *)((uint8_t *)ubi_ec + vid_hdr_offset);
		magic = be32_to_cpu(ubi_vol->magic);
		if (magic != UBI_VID_HDR_MAGIC) {
			printf("Wrong ubi format\n");
			close(ofd);
			close(fd);
			return 0;
		}
		curr_vol_id = be32_to_cpu(ubi_vol->vol_id);
		if (curr_vol_id == ret_vol_id) {
			if (write(ofd, (void *)((uint8_t *)ubi_ec + data_offset), data_size) == -1) {
				printf("Write error\n");
				close(fd);
				close(ofd);
				return 0;
			}
		}
		ubi_ec = (struct ubi_ec_hdr *)((uint8_t *)ubi_ec + data_offset + data_size);
		magic = be32_to_cpu(ubi_ec->magic);
	}
	if (munmap(fp, sb.st_size) == -1) {
		perror("munmap");
		close(ofd);
		close(fd);
		return 0;
	}
	close(ofd);
	close(fd);
	if (!strncmp(vol_name, "ubi_rootfs", strlen("ubi_rootfs"))) {
		extract_rootfs_binary(of_name);
	}
	printf("%s extracted from ubi image\n", vol_name);
	return 1;
}

/**
 * check_image_exist() used to check whether the ubi image for NAND
 * or rootfs image for EMMC are available in /tmp directory.
 * If respective image was found, the filename will be passed. If
 * not found, it returns NULL
 */

char * check_image_exist(char *imgname) {
	DIR* FD;
	struct dirent* in_file;
	char extension[256] = "/tmp/";

	/* Scanning the in directory */
	if (NULL == (FD = opendir ("/tmp")))
	{
		fprintf(stderr, "Error : Failed to open input directory\n");
		return NULL;
	}

	while ((in_file = readdir(FD)))
	{
		if (strstr(in_file->d_name, imgname)) {
			printf("%s file found\n", in_file->d_name);
			strlcat(extension, in_file->d_name, sizeof(extension));
			strlcpy(in_file->d_name, extension, sizeof(extension));
			return in_file->d_name;
		}
	}
	return NULL;
}

/**
 * In case of EMMC, extract_rootfs_binary() extracts the rootfs image
 * till Deadcode from existing rootfs image. After extraction, the new rootfs
 * image will replace old rootfs image. This function removes padded
 * binaries and helps to authenticate rootfs image using sec_auth
 */

int extract_rootfs_binary(char *filename)
{
	int ifd;
	uint8_t *fp;
	struct stat sb;

	if (filename == NULL) {
		return 0;
	}

	ifd = open(filename, O_RDWR);
	if (ifd < 0) {
		perror(filename);
		return 0;
	}

	memset(&sb, 0, sizeof(struct stat));
	if (fstat(ifd, &sb) == -1) {
		perror("fstat");
		close(ifd);
		return 0;
	}

	fp = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, ifd, 0);
	if (fp == MAP_FAILED) {
		perror("mmap");
		close(ifd);
		return 0;
	}

	int offset = 0,dead_off = sb.st_size;
	while (offset <= (sb.st_size - 3))
	{
		if ((fp[offset] == 0xde) && (fp[offset+1] == 0xad) && (fp[offset+2] == 0xc0) && (fp[offset+3] == 0xde)) {
			dead_off=offset;
			break;
		}
		offset += ROOTFS_OFFSET;
	}

	if (munmap(fp, sb.st_size) == -1) {
		perror("munmap");
		close(ifd);
		return 0;
	}

	close(ifd);
	if (!truncate(filename, dead_off)) {
		printf(" Failed to extract rootfs \n");
		return 0;
	}
	return 1;
}

/**
 * The digest functions output the message digest of a supplied file and
 * write sha-hash key to /tmp/sha_keyXXXXXX file
 */
int compute_sha_hash(struct image_section *section)
{
	char sha_hash[] = TEMP_SHA_KEY_PATH;
	char command[300] = {0};
	int retval = 0;

#ifdef USE_SHA384
	retval = snprintf(command, sizeof(command),
		"openssl dgst -sha384 -binary -out %s %s", sha_hash, section->tmp_file);
#endif
#ifdef USE_SHA256
	retval = snprintf(command, sizeof(command),
		"openssl dgst -sha256 -binary -out %s %s", sha_hash, section->tmp_file);
#endif
	if (retval < 0) {
		return retval;
	}
	retval = system(command);
	if (retval != 0) {
		printf("Error generating sha-hash, command : %s\n",command);
		return 0;
	}

	printf("sha_hash file is created: %s \n",sha_hash);
	return 1;
}
/**
 * is_image_version_higher() iterates through each component and check
 * versions against locally installed version.
 * If newer component version is lower than locally insatlled image,
 * abort the FW upgrade process.
 *
 * @img: char *
 */
int is_image_version_higher(void)
{
	int i;
	for (i = 0; i < NO_OF_SECTIONS; i++) {
		if (!sections[i].is_present) {
			continue;
		}

		if (sections[i].local_version > sections[i].img_version) {
			printf("Version of image %s (%d) is lower than minimal supported version(%d)\n",
					sections[i].file,
					sections[i].img_version,
					sections[i].local_version);
			return 0;
		}

		if (sections[i].img_version > sections[i].max_version) {
			printf("Version of image %s (%d) is higher than maximum supported version(%d)\n",
					sections[i].file,
					sections[i].img_version,
					sections[i].max_version);
		}
	}

	return 1;
}

/**
 * Update the version information file based on currently SW_ID being installed.
 *
 */
int update_version(void)
{
	int i;
	for (i = 0; i < NO_OF_SECTIONS; i++) {
		if (!sections[i].is_present) {
			continue;
		}

		if (set_local_image_version(&sections[i]) != 1) {
			printf("Error updating version of %s\n", sections[i].file);
			return 0;
		}
	}

	return 1;
}

int check_image_version(void)
{
	if (is_version_check_enabled() == 0) {
		printf("Version check is not enabled, upgrade to continue !!!\n");
		return 1;
	}

	if (is_image_version_higher() == 0) {
		printf("New image versions are lower than existing image, upgrade to STOP !!!\n");
		return 0;
	}

	if (update_version() != 1) {
		printf("Error while updating verison information\n");
		return 0;
	}
	printf("Update completed!\n");

	return 1;
}

/**
 * split_code_signature_cert_from_component_bin splits the component
 * binary by splitting into code(including MBN header), signature file &
 * attenstation certificate.
 *
 * @bin_file: char *
 * @src: char *
 * @sig: char *
 * @cert: char *
 */
int split_code_signature_cert_from_component_bin(struct image_section *section,
		char **src, char **sig, char **cert)
{
	Mbn_Hdr *mbn_hdr;
	Sbl_Hdr *sbl_hdr;
	int fd = open(section->file, O_RDONLY);
	uint8_t *fp;
	int sig_offset = 0;
	int src_offset = 0;
	int cert_offset = 0;
	struct stat sb;
	int sig_cert_size;

	if (fd == -1) {
		perror(section->file);
		return 0;
	}

	memset(&sb, 0, sizeof(struct stat));
	if (fstat(fd, &sb) == -1) {
		perror("fstat");
		close(fd);
		return 0;
	}

	fp = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (fp == MAP_FAILED) {
		perror("mmap");
		close(fd);
		return 0;
	}

	mbn_hdr = (Mbn_Hdr *)fp;
	if (strstr(section->file, sections[4].type)) {
		uint32_t preamble = !check_nand_preamble(fp) ? SBL_NAND_PREAMBLE : 0;

		sbl_hdr = (Sbl_Hdr *)(fp + preamble);
		src_offset = preamble;
		sig_offset = preamble + sbl_hdr->sig_ptr - sbl_hdr->image_dest_ptr +
				SBL_HDR_SIZE;
		cert_offset = preamble + sbl_hdr->cert_ptr - sbl_hdr->image_dest_ptr +
				SBL_HDR_SIZE;
		sig_cert_size = sbl_hdr->image_size - sbl_hdr->code_size;
		src_size = sbl_hdr->sig_ptr - sbl_hdr->image_dest_ptr + SBL_HDR_SIZE;
	} else {
		sig_cert_size = mbn_hdr->image_size - mbn_hdr->code_size;
		src_size = mbn_hdr->sig_ptr - mbn_hdr->image_dest_ptr + MBN_HDR_SIZE;
		sig_offset += mbn_hdr->sig_ptr - mbn_hdr->image_dest_ptr + MBN_HDR_SIZE;
		cert_offset += mbn_hdr->cert_ptr - mbn_hdr->image_dest_ptr + MBN_HDR_SIZE;
	}

	if (sig_cert_size != SIG_CERT_2_SIZE && sig_cert_size != SIG_CERT_3_SIZE) {
		printf("WARNING: signature certificate size is different\n");
	}
        *src = malloc(src_size + 1);
	if (*src == NULL) {
		close(fd);
		return 0;
	}
	memcpy(*src, fp + src_offset, src_size);
	(*src)[src_size] = '\0';

	*sig = malloc((SIG_SIZE + 1) * sizeof(char));
	if (*sig == NULL) {
		free(*src);
		return 0;
	}
	memcpy(*sig, fp + sig_offset, SIG_SIZE);
	(*sig)[SIG_SIZE] = '\0';

	*cert = malloc((CERT_SIZE + 1) * sizeof(char));
	if (*cert == NULL) {
		free(*src);
		free(*sig);
		return 0;
	}
	memcpy(*cert, fp + cert_offset, CERT_SIZE);
	(*cert)[CERT_SIZE] = '\0';

	close(fd);
	return 1;
}

/**
 * split_code_signature_cert_from_component_bin_elf splits the component
 * binary by splitting into code(including ELF header), signature file &
 * attenstation certificate.
 *
 * @bin_file: char *
 * @src: char *
 * @sig: char *
 * @cert: char *
 */
int split_code_signature_cert_from_component_bin_elf(struct image_section *section,
		char **src, char **sig, char **cert)
{
	Elf32_Ehdr *elf;
	Elf32_Phdr *phdr;
	Mbn_Hdr *mbn_hdr;
	uint8_t *fp;
	int sig_offset;
	int cert_offset;
	int len;

	if (!process_elf(section->file, &fp, &elf, &phdr, &mbn_hdr)) {
		return 0;
	}

	sig_offset = mbn_hdr->sig_ptr - mbn_hdr->image_dest_ptr + MBN_HDR_SIZE;
	len = sig_offset;
	*src = malloc((len + 1) * sizeof(char));
	if (*src == NULL) {
		return 0;
	}
	memcpy(*src, fp + phdr->p_offset, len);
	src_size = len;
	(*src)[len] = '\0';

	*sig = malloc((SIG_SIZE + 1) * sizeof(char));
	if (*sig == NULL) {
		free(*src);
		return 0;
	}
	memcpy(*sig, fp + phdr->p_offset + sig_offset, SIG_SIZE);
	(*sig)[SIG_SIZE] = '\0';

	cert_offset = mbn_hdr->cert_ptr - mbn_hdr->image_dest_ptr + MBN_HDR_SIZE;
	*cert = malloc((CERT_SIZE + 1) * sizeof(char));
	if (*cert == NULL) {
		free(*src);
		free(*sig);
		return 0;
	}
	memcpy(*cert, fp + phdr->p_offset + cert_offset, CERT_SIZE);
	(*cert)[CERT_SIZE] = '\0';

	return 1;
}

/**
 * split_code_signature_cert_from_component_bin_elf64 splits the component
 * binary by splitting into code(including ELF header), signature file &
 * attenstation certificate.
 *
 * @bin_file: char *
 * @src: char *
 * @sig: char *
 * @cert: char *
 */
int split_code_signature_cert_from_component_bin_elf64(struct image_section *section,
                char **src, char **sig, char **cert)
{
	Elf64_Ehdr *elf;
	Elf64_Phdr *phdr;
	Mbn_Hdr *mbn_hdr;
	uint8_t *fp;
	int len, sig_offset, cert_offset;

	if (!process_elf64(section->file, &fp, &elf, &phdr, &mbn_hdr)) {
		return 0;
	}

	sig_offset = mbn_hdr->code_size + MBN_HDR_SIZE;
	len = sig_offset;
	*src = malloc((len + 1) * sizeof(char));
	if (*src == NULL) {
		return 0;
	}

	memcpy(*src, fp + phdr->p_offset, len);
	src_size = len;
	(*src)[len] = '\0';

	*sig = malloc((SIG_SIZE + 1) * sizeof(char));
	if (*sig == NULL) {
		free(*src);
		return 0;
	}

	memcpy(*sig, fp + phdr->p_offset + sig_offset, SIG_SIZE);
	(*sig)[SIG_SIZE] = '\0';

	cert_offset = mbn_hdr->code_size + mbn_hdr->sig_sz + MBN_HDR_SIZE;
	*cert = malloc((CERT_SIZE + 1) * sizeof(char));
	if (*cert == NULL) {
		free(*src);
		free(*sig);
		return 0;
	}
	memcpy(*cert, fp + phdr->p_offset + cert_offset, CERT_SIZE);
	(*cert)[CERT_SIZE] = '\0';

	return 1;
}

/**
 * parse_elf_image_phdr() parses the ELF32 program header to get the
 * ELF header of rootfs metadata. It parses the metadata and writes
 * to a new /tmp/metadata.bin file.
 */
int parse_elf_image_phdr(struct image_section *section)
{
	Elf32_Ehdr *ehdr; /* Elf header structure pointer */
	Elf32_Phdr *phdr; /* Program header structure pointer */
        struct stat sb;
        uint8_t *fp;
	int i;

	if (!is_rootfs_auth_enabled()) {
		return 1;
	}

        int fd = open(section->file, O_RDONLY);

        if (fd < 0) {
                perror(section->file);
                return 0;
        }

        memset(&sb, 0, sizeof(struct stat));
        if (fstat(fd, &sb) == -1) {
                perror("fstat");
                close(fd);
                return 0;
        }

        fp = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (fp == MAP_FAILED) {
                perror("mmap");
                close(fd);
                return 0;
        }

        ehdr = (Elf32_Ehdr *)fp;
	phdr = (Elf32_Phdr *)(((char*)fp) + ehdr->e_phoff);
	printf(" ELF headers are initialized\n");

	if (ehdr->e_type != ET_EXEC) {
		printf("Not a valid elf image\n");
		close(fd);
		return 0;
	}

	/* Load each program header */
	for (i = 0; i < NO_OF_PROGRAM_HDRS; ++i) {
		if(phdr->p_type == PT_LOAD) {
			printf(" PT_LOAD Segment Found\n");
			printf("Parsing img_info load addr 0x%x offset 0x%x size 0x%x type 0x%x\n",
			phdr->p_paddr, phdr->p_offset, phdr->p_filesz, phdr->p_type);

			int size = sb.st_size - (phdr->p_offset + phdr->p_filesz );
			create_file(TEMP_METADATA_PATH, (char *)(fp + phdr->p_offset + phdr->p_filesz), size);
			printf("rootfs meta data file: %s created with size:%x\n",TEMP_METADATA_PATH, size);

			close(fd);
			return 1;
		}
		++phdr;
	}

	close(fd);
	return 1;
}

/**
 * being used to calculate the image hash
 *
 */
#define SW_MASK		0x3636363636363636ull

void generate_swid_ipad(char *sw_id, unsigned long long *swid_xor_ipad)
{
	unsigned long long int val;

	val = strtoull(sw_id, NULL, 16);
	*swid_xor_ipad = val ^ SW_MASK;

	printf("%llx\n", *swid_xor_ipad);
}

/**
 * being used to calculate the image hash
 *
 */
#define HW_ID_MASK		0x5c5c5c5cull
#define OEM_ID_MASK		0x00005c5cull
#define OEM_MODEL_ID_MASK	0x00005c5cull

void generate_hwid_opad(char *hw_id, char *oem_id, char *oem_model_id,
					unsigned long long *hwid_xor_opad)
{
	unsigned long long val;

	val = strtoull(hw_id, NULL, 16);
	*hwid_xor_opad = (((val >> 32) ^ HW_ID_MASK) << 32);

	val = strtoul(oem_id, NULL, 16);
	*hwid_xor_opad |= ((val ^ OEM_ID_MASK) << 16);

	val = strtoul(oem_model_id, NULL, 16);
	*hwid_xor_opad |= (val ^ OEM_MODEL_ID_MASK) & 0xffff;

	printf("%llx\n", *hwid_xor_opad);
}

int create_file(char *name, char *buffer, int size)
{
	int fd;

	fd = open(name, O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR);
	if (fd == -1) {
		perror(name);
		return 0;
	}

	if (write(fd, buffer, size) == -1) {
		close(fd);
		return 0;
	}

	close(fd);
	return 1;
}

char *create_xor_ipad_opad(char *f_xor, unsigned long long *xor_buffer)
{
	int fd;
	char *file;
	unsigned long long sw_id, sw_id_be;

	file = mkdtemp(f_xor);
	if (file == NULL) {
		printf("Error creating directory\n");
		return 0;
	}

	fd = open(file, O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR);
	if (fd == -1) {
		perror(file);
		return NULL;
	}

	sw_id = *xor_buffer;
	sw_id_be = htobe64(sw_id);
	if (!write(fd, &sw_id_be, sizeof(sw_id_be))) {
		printf(" Write Failed \n");
		return NULL;
	}
	close(fd);
	return file;
}

char *read_file(char *file_name, size_t *file_size)
{
	int fd;
	struct stat st;
	char *buffer;

	fd = open(file_name, O_RDONLY);
	if (fd == -1) {
		perror(file_name);
		return NULL;
	}

	memset(&st, 0, sizeof(struct stat));
	fstat(fd, &st);
	buffer = malloc(st.st_size * sizeof(char));
	if (buffer == NULL) {
		close(fd);
		return NULL;
	}

	if (read(fd, buffer, st.st_size) == -1) {
		close(fd);
		return NULL;
	}

	*file_size = (size_t) st.st_size;
	close(fd);
	return buffer;
}

int generate_hash(char *cert, char *sw_file, char *hw_file)
{
	unsigned long long swid_xor_ipad, hwid_xor_opad;
	char *tmp;
	char *sw_id_str = find_value(cert, "SW_ID", 17);
	char *hw_id_str = find_value(cert, "HW_ID", 17);
	char *oem_id_str = find_value(cert, "OEM_ID", 5);
	char *oem_model_id_str = find_value(cert, "MODEL_ID", 5);
	char f_sw_xor[] = "/tmp/swid_xor_XXXXXX";
	char f_hw_xor[] = "/tmp/hwid_xor_XXXXXX";

	if (sw_id_str == NULL || hw_id_str == NULL || oem_id_str == NULL || oem_model_id_str == NULL) {
		if (sw_id_str != NULL) {
			free(sw_id_str);
		}
		if (hw_id_str != NULL) {
			free(hw_id_str);
		}
		if (oem_id_str != NULL) {
			free(oem_id_str);
		}
		if (oem_model_id_str != NULL) {
			free(oem_model_id_str);
		}
		return 0;
	}
	printf("sw_id=%s\thw_id=%s\t", sw_id_str, hw_id_str);
	printf("oem_id=%s\toem_model_id=%s\n", oem_id_str, oem_model_id_str);

	sw_id_str[16] = '\0';
	generate_swid_ipad(sw_id_str, &swid_xor_ipad);
	tmp = create_xor_ipad_opad(f_sw_xor, &swid_xor_ipad);
	if (tmp == NULL) {
		free(sw_id_str);
		free(hw_id_str);
		free(oem_id_str);
		free(oem_model_id_str);
		return 0;
	}
	strlcpy(sw_file, tmp, 32);

	hw_id_str[16] = '\0';
	generate_hwid_opad(hw_id_str, oem_id_str, oem_model_id_str, &hwid_xor_opad);
	tmp = create_xor_ipad_opad(f_hw_xor, &hwid_xor_opad);
	if (tmp == NULL) {
		free(sw_id_str);
		free(hw_id_str);
		free(oem_id_str);
		free(oem_model_id_str);
		return 0;
	}
	strlcpy(hw_file, tmp, 32);

	free(sw_id_str);
	free(hw_id_str);
	free(oem_id_str);
	free(oem_model_id_str);

	return 1;
}

void remove_file(char *sw_file, char *hw_file, char *code_file, char *pub_file)
{
	remove(sw_file);
	remove(hw_file);
	remove(code_file);
	remove(pub_file);
	remove("src");
	remove("sig");
	remove("cert");
}

/**
 * is_component_authenticated() usage the code, signature & public key retrieved
 * for each component.
 *
 * @src: char *
 * @sig: char *
 * @cert: char *
 */
int is_component_authenticated(char *src, char *sig, char *cert)
{
	char command[256];
	char *computed_hash;
	char *reference_hash;
	char pub_key[] = "/tmp/pub_keyXXXXXX", *pub_file;
	char code_hash[] = "/tmp/code_hash_XXXXXX", *code_file;
	char tmp_hash[] = "/tmp/tmp_hash_XXXXXX", *tmp_file;
	char f_computed_hash[] = "/tmp/computed_hash_XXXXXX", *computed_file;
	char f_reference_hash[] = "/tmp/reference_hash_XXXXXX", *reference_file;
	char sw_file[32],hw_file[32];
	int retval;
	size_t comp_hash_size, ref_hash_size;

	if (!create_file("src", src, src_size) || !create_file("sig", sig, SIG_SIZE) ||
			!create_file("cert", cert, CERT_SIZE)) {
		return 0;
	}

	pub_file = mkdtemp(pub_key);
	if (pub_file == NULL) {
		printf("Error getting public key\n");
		return 0;
	}

	snprintf(command, sizeof(command),
		"openssl x509 -in cert -pubkey -inform DER -noout > %s", pub_file);
	retval = system(command);
	if (retval != 0) {
		remove("src");
		remove("sig");
		remove("cert");
		printf("Error generating public key\n");
		return 0;
	}

	retval = generate_hash(cert, sw_file, hw_file);
	if (retval == 0) {
		return 0;
	}

	code_file = mkdtemp(code_hash);
	snprintf(command, sizeof(command),
		"openssl dgst -sha256 -binary -out %s src", code_file);
	retval = system(command);
	if (retval != 0) {
		remove_file(sw_file, hw_file, code_file, pub_file);
		printf("Error in openssl digest\n");
		return 0;
	}

	tmp_file = mkdtemp(tmp_hash);
	snprintf(command, sizeof(command),
		"cat %s %s | openssl dgst -sha256 -binary -out %s",
						sw_file, code_file, tmp_file);
	retval = system(command);
	if (retval != 0) {
		remove_file(sw_file, hw_file, code_file, pub_file);
		remove(tmp_file);
		printf("Error generating temp has\n");
		return 0;
	}

	computed_file = mkdtemp(f_computed_hash);
	snprintf(command, sizeof(command),
		"cat %s %s | openssl dgst -sha256 -binary -out %s",
						hw_file, tmp_file, computed_file);
	retval = system(command);
	if (retval != 0) {
		remove_file(sw_file, hw_file, code_file, pub_file);
		remove(tmp_file);
		remove(computed_file);
		printf("Error generating hash\n");
		return 0;
	}

	reference_file = mkdtemp(f_reference_hash);
	snprintf(command, sizeof(command),
		"openssl rsautl -in sig -pubin -inkey %s -verify > %s",
						pub_file, reference_file);
	retval = system(command);
	if (retval != 0) {
		remove_file(sw_file, hw_file, code_file, pub_file);
		remove(tmp_file);
		remove(computed_file);
		remove(reference_file);
		printf("Error generating reference hash\n");
		return 0;
	}

	computed_hash = read_file(computed_file, &comp_hash_size);
	reference_hash = read_file(reference_file, &ref_hash_size);
	if (computed_hash == NULL || reference_hash == NULL) {
		remove_file(sw_file, hw_file, code_file, pub_file);
		remove(tmp_file);
		remove(computed_file);
		remove(reference_file);
		free(computed_hash?computed_hash:reference_hash);
		return 0;
	}

	remove_file(sw_file, hw_file, code_file, pub_file);
	remove(tmp_file);
	remove(computed_file);
	remove(reference_file);
	if (memcmp(computed_hash, reference_hash, ref_hash_size) ||
			(comp_hash_size != ref_hash_size)) {
		free(computed_hash);
		free(reference_hash);
		printf("Error: Hash or file_size not equal\n");
		return 0;
	}
	free(computed_hash);
	free(reference_hash);
	return 1;
}

/**
 * is_image_authenticated() iterates through each component and check
 * whether individual component is authenticated. If not, abort the FW
 * upgrade process.
 *
 * @img: char *
 */
int is_image_authenticated(void)
{
	int i;
	char *src, *sig, *cert;
	for (i = 0; i < NO_OF_SECTIONS; i++) {
		if (!sections[i].is_present) {
			continue;
		}
		if (!sections[i].split_components(&sections[i], &src, &sig, &cert)) {
			printf("Error while splitting code/signature/Certificate from %s\n",
					sections[i].file);
			return 0;
		}
		if (!is_component_authenticated(src, sig, cert)) {
			printf("Error while authenticating %s\n", sections[i].file);
			return 0;
		}
	}

	return 1;
}

int sec_image_auth(void)
{
	int fd, i, len;
	char *buf = NULL;

	fd = open(SEC_AUTHENTICATE_FILE, O_RDWR);
	if (-1 == fd) {
		perror(SEC_AUTHENTICATE_FILE);
		return 1;
	}
	buf = (char*)malloc(SIG_SIZE);
	if (buf == NULL) {
		perror("Memory allocation failed\n");
		close(fd);
		return 1;
	}
	for (i = 0; i < NO_OF_SECTIONS; i++) {
		if (!sections[i].is_present) {
			continue;
		}

		len = snprintf(buf, SIG_SIZE, "%s %s", sections[i].img_code, sections[i].file);
		if (!strncmp(sections[i].type, "rootfs", strlen("rootfs"))) {
			struct stat sb;
			if (stat(TEMP_METADATA_PATH, &sb) == -1)
				continue;

			len = snprintf(buf, SIG_SIZE, "%s %s %s", sections[i].img_code,
						TEMP_METADATA_PATH, TEMP_SHA_KEY_PATH);
		}

		if (len < 0 || len > SIG_SIZE) {
			perror("Array out of Index\n");
			free(buf);
			close(fd);
			return 1;
		}
		if (write(fd, buf, len) != len) {
			perror("write");
			printf("%s Image authentication failed\n", buf);
			free(buf);
			close(fd);
			return 1;
		}
	}
	close(fd);
	free(buf);
	remove_file(TEMP_KERNEL_PATH,TEMP_ROOTFS_PATH, TEMP_METADATA_PATH, TEMP_SHA_KEY_PATH);
	return 0;
}

int do_board_upgrade_check(char *img)
{
	if (is_tz_authentication_enabled()) {
		/* If image is having signed rootfs image, then extract kernel and rootfs binary for parsing metadata. */
		if (is_rootfs_auth_enabled()) {
			printf("rootfs image authentication is enabled ...\n");
			extract_rootfs_binary(check_image_exist("rootfs-"));
			extract_ubi_volume("ubi_rootfs", check_image_exist("ubi-"), TEMP_ROOTFS_PATH);
		}
		printf("TZ authentication enabled ...\n");
		if (!load_sections()) {
			printf("Error: Failed to load sections from image: %s\n", img);
			return 1;
		}
		return sec_image_auth();
	} else if (is_authentication_check_enabled()) {
		if (!get_sections()) {
			printf("Error: %s is not a signed image\n", img);
			return 1;
		}

		if (!is_image_authenticated()) {
			printf("Error: \"%s\" couldn't be authenticated. Abort...\n", img);
			return 1;
		}

		if (!check_image_version()) {
			printf("Error: \"%s\" couldn't be upgraded. Abort...\n", img);
			return 1;
		}
	}

	return 0;
}
