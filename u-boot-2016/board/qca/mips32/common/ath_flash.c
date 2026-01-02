/*
 * Copyright (c) 2016 The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 */

#include <common.h>
#include <jffs2/jffs2.h>
#include <asm/addrspace.h>
#include <asm/types.h>
#include <atheros.h>
#include "ath_flash.h"

#if !defined(ATH_DUAL_FLASH)
#	define	ath_spi_flash_print_info	flash_print_info
#endif

#define ATH_16M_FLASH_SIZE		0x1000000
#define ATH_GET_EXT_3BS(addr)		((addr) % ATH_16M_FLASH_SIZE)
#define ATH_GET_EXT_4B(addr)		((addr) >> 24)


/*
 * globals
 */
flash_info_t flash_info[CFG_MAX_FLASH_BANKS];

/*
 * statics
 */
static void ath_spi_write_enable(void);
static void ath_spi_poll(void);
#if !defined(ATH_SST_FLASH)
static void ath_spi_write_page(uint32_t addr, uint8_t * data, int len);
#endif
static void ath_spi_sector_erase(uint32_t addr);

#if defined(ATH_DUAL_NOR)
static void ath_spi_enter_ext_addr(u8 addr)
{
	ath_spi_write_enable();
	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
	ath_spi_bit_banger(ATH_SPI_CMD_WR_EXT);
	ath_spi_bit_banger(addr);
	ath_spi_go();
	ath_spi_poll();
}

static void ath_spi_exit_ext_addr(int ext)
{
	if (ext)
		ath_spi_enter_ext_addr(0);
}
#else
#define ath_spi_enter_ext_addr(addr)
#define ath_spi_exit_ext_addr(ext)
#endif

static void
ath_spi_read_id(void)
{
	u32 rd;

	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
	ath_spi_bit_banger(ATH_SPI_CMD_RDID);
	ath_spi_delay_8();
	ath_spi_delay_8();
	ath_spi_delay_8();
	ath_spi_go();

	rd = ath_reg_rd(ATH_SPI_RD_STATUS);

	printf("Flash Manuf Id 0x%x, DeviceId0 0x%x, DeviceId1 0x%x\n",
		(rd >> 16) & 0xff, (rd >> 8) & 0xff, (rd >> 0) & 0xff);
}


#ifdef ATH_SST_FLASH
void ath_spi_flash_unblock(void)
{
	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_WRITE_SR);
	ath_spi_bit_banger(0x0);
	ath_spi_go();
	ath_spi_poll();
}
#endif

#if  defined(CONFIG_ATH_SPI_CS1_GPIO)

#define ATH_SPI_CS0_GPIO		5

static void ath_gpio_config_output(int gpio)
{
#if defined(CONFIG_MACH_AR934x) || \
	defined(CONFIG_MACH_QCA955x) || \
	defined(CONFIG_MACH_QCA953x) || \
	defined(CONFIG_MACH_QCA956x)
	ath_reg_rmw_clear(ATH_GPIO_OE, (1 << gpio));
#else
	ath_reg_rmw_set(ATH_GPIO_OE, (1 << gpio));
#endif
}

static void ath_gpio_set_fn(int gpio, int fn)
{
#define gpio_fn_reg(x)  ((x) / 4)
#define gpio_lsb(x)     (((x) % 4) * 8)
#define gpio_msb(x)     (gpio_lsb(x) + 7)
#define gpio_mask(x)    (0xffu << gpio_lsb(x))
#define gpio_set(x, f)  (((f) & 0xffu) << gpio_lsb(x))

	uint32_t *reg = ((uint32_t *)GPIO_OUT_FUNCTION0_ADDRESS) +
				gpio_fn_reg(gpio);

	ath_reg_wr(reg, (ath_reg_rd(reg) & ~gpio_mask(gpio)) | gpio_set(gpio, fn));
}

int ath_spi_flash_get_fn_cs0(void)
{
#if CONFIG_MACH_QCA934x
	return 0x09;
#elif (CONFIG_MACH_QCA953x || CONFIG_MACH_QCA955x)
	return 0x09;
#endif
	return -1;
}

int ath_spi_flash_get_fn_cs1(void)
{
#if CONFIG_MACH_QCA934x
	return 0x07;
#elif (CONFIG_MACH_QCA953x || CONFIG_MACH_QCA955x)
	return 0x0a;
#endif
	return -1;
}

void ath_spi_flash_enable_cs1(void)
{
	int fn = ath_spi_flash_get_fn_cs1();

	if (fn < 0) {
		printf("Error, enable SPI_CS_1 failed\n");
		return;
	}

	ath_gpio_set_fn(CONFIG_ATH_SPI_CS1_GPIO,
			ath_spi_flash_get_fn_cs1());
	ath_gpio_config_output(CONFIG_ATH_SPI_CS1_GPIO);
}
#else
#define ath_spi_flash_enable_cs1(...)
#endif

int flash_select(int chip)
{
#if  defined(CONFIG_ATH_SPI_CS1_GPIO)
	int fn_cs0, fn_cs1;

	fn_cs0 = ath_spi_flash_get_fn_cs0();
	fn_cs1 = ath_spi_flash_get_fn_cs1();

	if (fn_cs0 < 0 || fn_cs1 < 0) {
		printf("Error, flash select failed\n");
		return -1;
	}
#endif

	switch (chip) {
	case 0:
#if  defined(CONFIG_ATH_SPI_CS1_GPIO)
		ath_gpio_set_fn(CONFIG_ATH_SPI_CS1_GPIO, fn_cs1);
		ath_gpio_set_fn(ATH_SPI_CS0_GPIO, fn_cs0);
#elif defined(ATH_DUAL_NOR)
		ath_reg_rmw_set(ATH_SPI_FS, 1);
		ath_spi_exit_ext_addr(1);
		ath_reg_rmw_clear(ATH_SPI_FS, 1);
#endif
		break;

	case 1:
#if  defined(CONFIG_ATH_SPI_CS1_GPIO)
		ath_gpio_set_fn(ATH_SPI_CS0_GPIO, 0);
		ath_gpio_set_fn(CONFIG_ATH_SPI_CS1_GPIO, fn_cs0);
#elif defined(ATH_DUAL_NOR)
		ath_reg_rmw_set(ATH_SPI_FS, 1);
		ath_spi_enter_ext_addr(1);
		ath_reg_rmw_clear(ATH_SPI_FS, 1);
#endif
		break;

	default:
		printf("Error, please specify correct flash number 0/1\n");
		return -1;
	}

	return 0;
}

unsigned long flash_init(void)
{
#if !(defined(CONFIG_WASP_SUPPORT) || defined(CONFIG_MACH_QCA955x) || defined(CONFIG_MACH_QCA956x))
#ifdef ATH_SST_FLASH
	ath_reg_wr_nf(ATH_SPI_CLOCK, 0x3);
	ath_spi_flash_unblock();
	ath_reg_wr(ATH_SPI_FS, 0);
#else
	ath_reg_wr_nf(ATH_SPI_CLOCK, 0x43);
#endif
#endif

#if  defined(CONFIG_MACH_QCA953x) /* Added for HB-SMIC */
#ifdef ATH_SST_FLASH
	ath_reg_wr_nf(ATH_SPI_CLOCK, 0x4);
	ath_spi_flash_unblock();
	ath_reg_wr(ATH_SPI_FS, 0);
#else
	ath_reg_wr_nf(ATH_SPI_CLOCK, 0x44);
#endif
#endif 
	ath_reg_rmw_set(ATH_SPI_FS, 1);
	ath_spi_read_id();
	ath_spi_exit_ext_addr(1);
	ath_reg_rmw_clear(ATH_SPI_FS, 1);

	ath_spi_flash_enable_cs1();
	/*
	 * hook into board specific code to fill flash_info
	 */
	return (flash_get_geom(&flash_info[0]));
}

void
ath_spi_flash_print_info(flash_info_t *info)
{
	printf("The hell do you want flinfo for??\n");
}

int
flash_erase(flash_info_t *info, int s_first, int s_last)
{
	u32 addr;
	int ext = 0;
	int i, sector_size = info->size / info->sector_count;

	printf("\nFirst %#x last %#x sector size %#x\n",
		s_first, s_last, sector_size);

	addr = s_first * sector_size;
	if (addr >= ATH_16M_FLASH_SIZE) {
		ext = 1;
		ath_spi_enter_ext_addr(ATH_GET_EXT_4B(addr));
	} else if (s_last * sector_size >= ATH_16M_FLASH_SIZE) {
		printf("Erase failed, cross 16M is forbidden\n");
		return -1;
	}

	for (i = s_first; i <= s_last; i++) {
		addr = i * sector_size;

		if (ext)
			addr = ATH_GET_EXT_3BS(addr);

		printf("\b\b\b\b%4d", i);
		ath_spi_sector_erase(addr);
	}

	ath_spi_exit_ext_addr(ext);

	ath_spi_done();
	printf("\n");

	return 0;
}

/*
 * Write a buffer from memory to flash:
 * 0. Assumption: Caller has already erased the appropriate sectors.
 * 1. call page programming for every 256 bytes
 */
#ifdef ATH_SST_FLASH
void
ath_spi_flash_chip_erase(void)
{
	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_CHIP_ERASE);
	ath_spi_go();
	ath_spi_poll();
}

int
write_buff(flash_info_t *info, uchar *src, ulong dst, ulong len)
{
	uint32_t val;

	dst = dst - CFG_FLASH_BASE;
	printf("write len: %lu dst: 0x%x src: %p\n", len, dst, src);

	for (; len; len--, dst++, src++) {
		ath_spi_write_enable();	// dont move this above 'for'
		ath_spi_bit_banger(ATH_SPI_CMD_PAGE_PROG);
		ath_spi_send_addr(dst);

		val = *src & 0xff;
		ath_spi_bit_banger(val);

		ath_spi_go();
		ath_spi_poll();
	}
	/*
	 * Disable the Function Select
	 * Without this we can't read from the chip again
	 */
	ath_reg_wr(ATH_SPI_FS, 0);

	if (len) {
		// how to differentiate errors ??
		return ERR_PROG_ERROR;
	} else {
		return ERR_OK;
	}
}
#else
int
write_buff(flash_info_t *info, uchar *source, ulong addr, ulong len)
{
	int total = 0, len_this_lp, bytes_this_page;
	ulong dst;
	uchar *src;
	int ext = 0;

	printf("write addr: %x\n", addr);
	addr = addr - CFG_FLASH_BASE;

	if (addr >= ATH_16M_FLASH_SIZE) {
		ext = 1;
		ath_spi_enter_ext_addr(ATH_GET_EXT_4B(addr));
		addr = ATH_GET_EXT_3BS(addr);
	} else if (addr + len >= ATH_16M_FLASH_SIZE) {
		printf("Write failed, cross 16M is forbidden\n");
		return -1;
	}

	while (total < len) {
		src = source + total;
		dst = addr + total;
		bytes_this_page =
			ATH_SPI_PAGE_SIZE - (addr % ATH_SPI_PAGE_SIZE);
		len_this_lp =
			((len - total) >
			bytes_this_page) ? bytes_this_page : (len - total);
		ath_spi_write_page(dst, src, len_this_lp);
		total += len_this_lp;
	}

	ath_spi_exit_ext_addr(ext);

	ath_spi_done();

	return 0;
}
#endif

static void
ath_spi_write_enable()
{
	ath_reg_wr_nf(ATH_SPI_FS, 1);
	ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
	ath_spi_bit_banger(ATH_SPI_CMD_WREN);
	ath_spi_go();
}

static void
ath_spi_poll()
{
	int rd;

	do {
		ath_reg_wr_nf(ATH_SPI_WRITE, ATH_SPI_CS_DIS);
		ath_spi_bit_banger(ATH_SPI_CMD_RD_STATUS);
		ath_spi_delay_8();
		rd = (ath_reg_rd(ATH_SPI_RD_STATUS) & 1);
	} while (rd);
}

#if !defined(ATH_SST_FLASH)
static void
ath_spi_write_page(uint32_t addr, uint8_t *data, int len)
{
	int i;
	uint8_t ch;

	display(0x77);
	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_PAGE_PROG);
	ath_spi_send_addr(addr);

	for (i = 0; i < len; i++) {
		ch = *(data + i);
		ath_spi_bit_banger(ch);
	}

	ath_spi_go();
	display(0x66);
	ath_spi_poll();
	display(0x6d);
}
#endif

static void
ath_spi_sector_erase(uint32_t addr)
{
	ath_spi_write_enable();
	ath_spi_bit_banger(ATH_SPI_CMD_SECTOR_ERASE);
	ath_spi_send_addr(addr);
	ath_spi_go();
	display(0x7d);
	ath_spi_poll();
}

#ifdef ATH_DUAL_FLASH
void flash_print_info(flash_info_t *info)
{
	ath_spi_flash_print_info(NULL);
	ath_nand_flash_print_info(NULL);
}
#endif
