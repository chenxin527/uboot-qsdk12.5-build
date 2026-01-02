/*
 * Copyright (c) 2015-2017 The Linux Foundation. All rights reserved.
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

#ifndef _IPQ40XX_CDP_H_
#define _IPQ40XX_CDP_H_

#include <configs/ipq40xx.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/qca_common.h>
#include <asm/u-boot.h>
#include <phy.h>

#define NO_OF_DBG_UART_GPIOS	2
#ifdef CONFIG_IPQ40XX_I2C
#define NO_OF_I2C_GPIOS		2
#endif
#define MAX_CONF_NAME		5
#define GCC_BLSP1_UART1_APPS_CBCR       0x0180203c
#define GCC_SDCC1_BCR		0x1818000

#define MSM_SDC1_BASE		0x7824000
#define MSM_SDC1_MCI_HC_MODE	0x7824078
#define MSM_SDC1_SDHCI_BASE	0x7824900

#define KERNEL_AUTH_CMD		0x13
#define SCM_CMD_SEC_AUTH	0x15

unsigned int smem_get_board_machtype(void);

#define IPQ40XX_EDMA_DEV	1
typedef struct {
	uint count;
	u8 addr[7];
} ipq40xx_edma_phy_addr_t;

/* ipq40xx edma Paramaters */
typedef struct {
	uint base;
	int unit;
	uint mac_conn_to_phy;
	phy_interface_t phy;
	ipq40xx_edma_phy_addr_t phy_addr;
	const char phy_name[MDIO_NAME_LEN];
} ipq40xx_edma_board_cfg_t;

typedef struct {
	unsigned int uart_dm_base;
	gpio_func_data_t *dbg_uart_gpio;
} uart_cfg_t;

#ifdef CONFIG_IPQ40XX_I2C
typedef struct {
	unsigned int i2c_base;
	gpio_func_data_t *i2c_gpio;
} i2c_cfg_t;
#endif

void board_pci_init(int id);
__weak void board_pcie_clock_init(int id) {}
__weak void aquantia_phy_reset_init_done(void) {}
__weak void aquantia_phy_reset_init(void) {}
__weak void qgic_init(void) {}
__weak void handle_noc_err(void) {}
__weak int ipq_get_tz_version(char *version_name, int buf_size)
{
	return 1;
}

void disable_audio_clks(void);

/* Board specific parameters */
typedef struct {
	unsigned int machid;
	unsigned int ddr_size;
	gpio_func_data_t *spi_nor_gpio;
	unsigned int spi_nor_gpio_count;
	gpio_func_data_t *nand_gpio;
	unsigned int nand_gpio_count;
	gpio_func_data_t *sw_gpio;
	unsigned int sw_gpio_count;
	gpio_func_data_t *rgmii_gpio;
	unsigned int rgmii_gpio_count;
	ipq40xx_edma_board_cfg_t edma_cfg[IPQ40XX_EDMA_DEV];
	uart_cfg_t *uart_cfg;
	uart_cfg_t *console_uart_cfg;
#ifdef CONFIG_IPQ40XX_I2C
	i2c_cfg_t *i2c_cfg;
#endif
	gpio_func_data_t *mmc_gpio;
	unsigned int mmc_gpio_count;
	unsigned int spi_nand_available;
	unsigned int nor_nand_available;
	const char *dtb_config_name[MAX_CONF_NAME];
} __attribute__ ((__packed__)) board_ipq40xx_params_t;

struct smem_ram_ptn {
	char name[16];
	unsigned long long start;
	unsigned long long size;

	/* RAM Partition attribute: READ_ONLY, READWRITE etc.  */
	unsigned attr;

	/* RAM Partition category: EBI0, EBI1, IRAM, IMEM */
	unsigned category;

	/* RAM Partition domain: APPS, MODEM, APPS & MODEM (SHARED) etc. */
	unsigned domain;

	/* RAM Partition type: system, bootloader, appsboot, apps etc. */
	unsigned type;

	/* reserved for future expansion without changing version number */
	unsigned reserved2, reserved3, reserved4, reserved5;
} __attribute__ ((__packed__));

struct smem_ram_ptable {
#define _SMEM_RAM_PTABLE_MAGIC_1 0x9DA5E0A8
#define _SMEM_RAM_PTABLE_MAGIC_2 0xAF9EC4E2
	unsigned magic[2];
	unsigned version;
	unsigned reserved1;
	unsigned len;
	unsigned buf;
	struct smem_ram_ptn parts[32];
} __attribute__ ((__packed__));

int smem_ram_ptable_init(struct smem_ram_ptable *smem_ram_ptable);

typedef enum {
	SMEM_SPINLOCK_ARRAY = 7,
	SMEM_AARM_PARTITION_TABLE = 9,
	SMEM_HW_SW_BUILD_ID = 137,
	SMEM_USABLE_RAM_PARTITION_TABLE = 402,
	SMEM_POWER_ON_STATUS_INFO = 403,
	SMEM_MACHID_INFO_LOCATION = 425,
	SMEM_IMAGE_VERSION_TABLE = 469,
	SMEM_BOOT_FLASH_TYPE = 478,
	SMEM_BOOT_FLASH_INDEX = 479,
	SMEM_BOOT_FLASH_CHIP_SELECT = 480,
	SMEM_BOOT_FLASH_BLOCK_SIZE = 481,
	SMEM_BOOT_FLASH_DENSITY = 482,
	SMEM_PARTITION_TABLE_OFFSET = 483,
	SMEM_BOOT_DUALPARTINFO = 484,
	SMEM_NUM_CPUINFO = 485,
	SMEM_FIRST_VALID_TYPE = SMEM_SPINLOCK_ARRAY,
	SMEM_LAST_VALID_TYPE = SMEM_NUM_CPUINFO,
	SMEM_MAX_SIZE = SMEM_NUM_CPUINFO + 1,
} smem_mem_type_t;

unsigned smem_read_alloc_entry(smem_mem_type_t type, void *buf, int len);
/* Reserved-memory node names*/
extern const char *rsvd_node;
extern const char *del_node[];
extern const add_node_t add_fdt_node[];

unsigned int get_board_index(unsigned int machid);
void reset_crashdump(void);
void ipq_fdt_fixup_socinfo(void *blob);
void reset_board(void);

#endif
