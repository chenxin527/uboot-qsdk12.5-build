/*
 * Copyright (c) 2015-2017, The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/

#include <linux/bitops.h>
#include <linux/compat.h>
#include <common.h>
#include <command.h>
#include <miiphy.h>
#include <phy.h>
#include <asm/io.h>
#include <errno.h>
#include "ipq_mdio.h"

#ifdef DEBUG
#define pr_debug(fmt, args...) printf(fmt, ##args);
#else
#define pr_debug(fmt, args...)
#endif

#define MDIO_DEFAULT		0
#define MDIO_BITBANG		1

static int mdio_mode = 0;
static int bus_no = 0;

struct ipq_mdio_data {
	struct mii_bus *bus;
	int phy_irq[PHY_MAX_ADDR];
};

void ipq_set_mdio_mode(const int mode, const int bus)
{
	mdio_mode = mode;
	bus_no = bus;
}

static int ipq_mdio_wait_busy(void)
{
	int i;
	u32 busy;
	for (i = 0; i < IPQ_MDIO_RETRY; i++) {
		busy = readl(IPQ_MDIO_BASE +
			MDIO_CTRL_4_REG) &
			MDIO_CTRL_4_ACCESS_BUSY;
		if (!busy)
			return 0;
	}
	printf("%s: MDIO operation timed out\n",
			__func__);
	return -ETIMEDOUT;
}

int ipq_mdio_write1(int mii_id, int regnum, u16 value)
{
	u32 cmd;

	if (regnum & MII_ADDR_C45) {
		unsigned int mmd = (regnum >> 16) & 0x1F;
	        unsigned int reg = regnum & 0xFFFF;

		writel(CTRL_0_REG_C45_DEFAULT_VALUE_3_1M,
			IPQ_MDIO_BASE + MDIO_CTRL_0_REG);

		/* Issue the phy address and reg */
		writel((mii_id << 8) | mmd,
			IPQ_MDIO_BASE + MDIO_CTRL_1_REG);

		writel(reg, IPQ_MDIO_BASE + MDIO_CTRL_2_REG);

		/* issue read command */
		cmd = MDIO_CTRL_4_ACCESS_START | MDIO_CTRL_4_ACCESS_CODE_C45_ADDR;

		writel(cmd, IPQ_MDIO_BASE + MDIO_CTRL_4_REG);

		if (ipq_mdio_wait_busy())
			return -ETIMEDOUT;
	} else {
		writel(CTRL_0_REG_DEFAULT_VALUE,
			IPQ_MDIO_BASE + MDIO_CTRL_0_REG);

		/* Issue the phy addreass and reg */
		writel((mii_id << 8 | regnum),
			IPQ_MDIO_BASE + MDIO_CTRL_1_REG);
	}

	/* Issue a write data */
	writel(value, IPQ_MDIO_BASE + MDIO_CTRL_2_REG);

	if (regnum & MII_ADDR_C45) {
		cmd = MDIO_CTRL_4_ACCESS_START | MDIO_CTRL_4_ACCESS_CODE_C45_WRITE ;
	} else {
		cmd = MDIO_CTRL_4_ACCESS_START | MDIO_CTRL_4_ACCESS_CODE_WRITE ;
	}

	writel(cmd, IPQ_MDIO_BASE + MDIO_CTRL_4_REG);
	/* Wait for write complete */

	if (ipq_mdio_wait_busy())
		return -ETIMEDOUT;

	return 0;
}

int ipq_mdio_read1(int mii_id, int regnum, ushort *data)
{
	u32 val,cmd;

	if (regnum & MII_ADDR_C45) {

		unsigned int mmd = (regnum >> 16) & 0x1F;
	        unsigned int reg = regnum & 0xFFFF;

		writel(CTRL_0_REG_C45_DEFAULT_VALUE_3_1M,
			IPQ_MDIO_BASE + MDIO_CTRL_0_REG);

		/* Issue the phy address and reg */
		writel((mii_id << 8) | mmd,
			IPQ_MDIO_BASE + MDIO_CTRL_1_REG);


		writel(reg, IPQ_MDIO_BASE + MDIO_CTRL_2_REG);

		/* issue read command */
		cmd = MDIO_CTRL_4_ACCESS_START | MDIO_CTRL_4_ACCESS_CODE_C45_ADDR;
	} else {

		writel(CTRL_0_REG_DEFAULT_VALUE,
			IPQ_MDIO_BASE + MDIO_CTRL_0_REG);

		/* Issue the phy address and reg */
		writel((mii_id << 8 | regnum ) ,
			IPQ_MDIO_BASE + MDIO_CTRL_1_REG);

		/* issue read command */
		cmd = MDIO_CTRL_4_ACCESS_START | MDIO_CTRL_4_ACCESS_CODE_READ ;
	}

	/* issue read command */
	writel(cmd, IPQ_MDIO_BASE + MDIO_CTRL_4_REG);

	if (ipq_mdio_wait_busy())
		return -ETIMEDOUT;


	 if (regnum & MII_ADDR_C45) {
		cmd = MDIO_CTRL_4_ACCESS_START | MDIO_CTRL_4_ACCESS_CODE_C45_READ;
		writel(cmd, IPQ_MDIO_BASE + MDIO_CTRL_4_REG);

		if (ipq_mdio_wait_busy())
			return -ETIMEDOUT;
	}

	/* Read data */
	val = readl(IPQ_MDIO_BASE + MDIO_CTRL_3_REG);

	if (data != NULL)
		*data = val;

	return val;
}

int ipq_mdio_write(int mii_id, int regnum, u16 value)
{
	u32 cmd;
#ifdef CONFIG_BITBANGMII
	char name[16];

	if (mdio_mode == MDIO_BITBANG) {
		snprintf(name, sizeof(name), "MDIO%d", bus_no);

		bb_miiphy_write_v2(name, mii_id, regnum, value);
	} else
#endif
	{
		if (regnum & MII_ADDR_C45) {
			unsigned int mmd = (regnum >> 16) & 0x1F;
			unsigned int reg = regnum & 0xFFFF;

			writel(CTRL_0_REG_C45_DEFAULT_VALUE,
				IPQ_MDIO_BASE + MDIO_CTRL_0_REG);

			/* Issue the phy address and reg */
			writel((mii_id << 8) | mmd,
				IPQ_MDIO_BASE + MDIO_CTRL_1_REG);

			writel(reg, IPQ_MDIO_BASE + MDIO_CTRL_2_REG);

			/* issue read command */
			cmd = MDIO_CTRL_4_ACCESS_START |
					MDIO_CTRL_4_ACCESS_CODE_C45_ADDR;

			writel(cmd, IPQ_MDIO_BASE + MDIO_CTRL_4_REG);

			if (ipq_mdio_wait_busy())
				return -ETIMEDOUT;
		} else {
			writel(CTRL_0_REG_DEFAULT_VALUE,
				IPQ_MDIO_BASE + MDIO_CTRL_0_REG);

			/* Issue the phy addreass and reg */
			writel((mii_id << 8 | regnum),
				IPQ_MDIO_BASE + MDIO_CTRL_1_REG);
		}

		/* Issue a write data */
		writel(value, IPQ_MDIO_BASE + MDIO_CTRL_2_REG);

		if (regnum & MII_ADDR_C45) {
			cmd = MDIO_CTRL_4_ACCESS_START |
					MDIO_CTRL_4_ACCESS_CODE_C45_WRITE ;
		} else {
			cmd = MDIO_CTRL_4_ACCESS_START |
					MDIO_CTRL_4_ACCESS_CODE_WRITE ;
		}

		writel(cmd, IPQ_MDIO_BASE + MDIO_CTRL_4_REG);
		/* Wait for write complete */

		if (ipq_mdio_wait_busy())
			return -ETIMEDOUT;
	}

	return 0;
}

int ipq_mdio_read(int mii_id, int regnum, ushort *data)
{
	u32 val,cmd;
#ifdef CONFIG_BITBANGMII
	char name[16];
	if (mdio_mode == MDIO_BITBANG) {

		snprintf(name, sizeof(name), "MDIO%d", bus_no);

		bb_miiphy_read_v2(name, mii_id, regnum,
					(unsigned short *)&val);
	} else
#endif
	{
		if (regnum & MII_ADDR_C45) {

			unsigned int mmd = (regnum >> 16) & 0x1F;
			unsigned int reg = regnum & 0xFFFF;

			writel(CTRL_0_REG_C45_DEFAULT_VALUE,
				IPQ_MDIO_BASE + MDIO_CTRL_0_REG);

			/* Issue the phy address and reg */
			writel((mii_id << 8) | mmd,
				IPQ_MDIO_BASE + MDIO_CTRL_1_REG);


			writel(reg, IPQ_MDIO_BASE + MDIO_CTRL_2_REG);

			/* issue read command */
			cmd = MDIO_CTRL_4_ACCESS_START |
					MDIO_CTRL_4_ACCESS_CODE_C45_ADDR;
		} else {

			writel(CTRL_0_REG_DEFAULT_VALUE,
				IPQ_MDIO_BASE + MDIO_CTRL_0_REG);

			/* Issue the phy address and reg */
			writel((mii_id << 8 | regnum ) ,
				IPQ_MDIO_BASE + MDIO_CTRL_1_REG);

			/* issue read command */
			cmd = MDIO_CTRL_4_ACCESS_START |
					MDIO_CTRL_4_ACCESS_CODE_READ ;
		}

		/* issue read command */
		writel(cmd, IPQ_MDIO_BASE + MDIO_CTRL_4_REG);

		if (ipq_mdio_wait_busy())
			return -ETIMEDOUT;


		 if (regnum & MII_ADDR_C45) {
			cmd = MDIO_CTRL_4_ACCESS_START |
					MDIO_CTRL_4_ACCESS_CODE_C45_READ;
			writel(cmd, IPQ_MDIO_BASE + MDIO_CTRL_4_REG);

			if (ipq_mdio_wait_busy())
				return -ETIMEDOUT;
		}

		/* Read data */
		val = readl(IPQ_MDIO_BASE + MDIO_CTRL_3_REG);
	}
	if (data != NULL)
		*data = val;

	return val;
}

int ipq_phy_write(struct mii_dev *bus,
		int addr, int dev_addr,
		int regnum, ushort value)
{
	return ipq_mdio_write(addr, regnum, value);
}

int ipq_phy_read(struct mii_dev *bus,
		int addr, int dev_addr, int regnum)
{
	return ipq_mdio_read(addr, regnum, NULL);
}

#ifdef CONFIG_QCA8084_PHY
static void split_addr(uint32_t regaddr, uint16_t *r1, uint16_t *r2,
			       uint16_t *page, uint16_t *switch_phy_id)
{
	*r1 = regaddr & 0x1c;

	regaddr >>= 5;
	*r2 = regaddr & 0x7;

	regaddr >>= 3;
	*page = regaddr & 0xffff;

	regaddr >>= 16;
	*switch_phy_id = regaddr & 0xff;
}

uint32_t ipq_mii_read(uint32_t reg)
{
	uint16_t r1, r2, page, switch_phy_id;
	uint16_t lo, hi;

	split_addr((uint32_t) reg, &r1, &r2, &page, &switch_phy_id);

	mutex_lock(&switch_mdio_lock);
	ipq_mdio_write(0x18 | (switch_phy_id >> 5), switch_phy_id & 0x1f, page);
	udelay(100);
	lo = ipq_mdio_read(0x10 | r2, r1, NULL);
	hi = ipq_mdio_read(0x10 | r2, r1 + 2, NULL);
	mutex_unlock(&switch_mdio_lock);

	return (hi << 16) | lo;
}

void ipq_mii_write(uint32_t reg, uint32_t val)
{
	uint16_t r1, r2, page, switch_phy_id;
	uint16_t lo, hi;

	split_addr((uint32_t) reg, &r1, &r2, &page, &switch_phy_id);
	lo = val & 0xffff;
	hi = (uint16_t) (val >> 16);

	mutex_lock(&switch_mdio_lock);
	ipq_mdio_write(0x18 | (switch_phy_id >> 5), switch_phy_id & 0x1f, page);
	udelay(100);
	ipq_mdio_write(0x10 | r2, r1, lo);
	ipq_mdio_write(0x10 | r2, r1 + 2, hi);
	mutex_unlock(&switch_mdio_lock);
}

void ipq_mii_update(uint32_t reg, uint32_t mask, uint32_t val)
{
	uint32_t new_val = 0, org_val = 0;

	org_val = ipq_mii_read(reg);

	new_val = org_val & ~mask;
	new_val |= val & mask;

	if (new_val != org_val)
		ipq_mii_write(reg, new_val);
}

static void ipq_clk_enable(uint32_t reg)
{
	u32 val;

	val = ipq_mii_read(reg);
	val |= BIT(0);
	ipq_mii_write(reg, val);
}

static void ipq_clk_disable(uint32_t reg)
{
	u32 val;

	val = ipq_mii_read(reg);
	val &= ~BIT(0);
	ipq_mii_write(reg, val);
}

static void ipq_clk_reset(uint32_t reg)
{
	u32 val;

	val = ipq_mii_read(reg);
	val |= BIT(2);
	ipq_mii_write(reg, val);

	udelay(21000);

	val &= ~BIT(2);
	ipq_mii_write(reg, val);
}

static u16 ipq_phy_dbg_read(u32 phy_addr, u32 reg_id)
{
	ipq_mdio_write(phy_addr, PHY_DEBUG_PORT_ADDR, reg_id);

	return ipq_mdio_read(phy_addr, PHY_DEBUG_PORT_DATA, NULL);
}

static void ipq_phy_dbg_write(u32 phy_addr, u32 reg_id, u16 reg_val)
{

	ipq_mdio_write(phy_addr, PHY_DEBUG_PORT_ADDR, reg_id);

	ipq_mdio_write(phy_addr, PHY_DEBUG_PORT_DATA, reg_val);
}

static void ipq_qca8084_efuse_loading(u8 ethphy)
{
	u32 val = 0, ldo_efuse = 0, icc_efuse = 0, phy_addr = 0;
	u16 reg_val = 0;

	phy_addr = ipq_mii_read(EPHY_CFG) >> (ethphy * PHY_ADDR_LENGTH)
		& GENMASK(4, 0);
	switch(ethphy) {
		case 0:
			val = ipq_mii_read(QFPROM_RAW_CALIBRATION_ROW4_LSB);
			ldo_efuse = (val & GENMASK(21, 18)) >> 18;
			icc_efuse = (val & GENMASK(26, 22)) >> 22;
			break;
		case 1:
			val = ipq_mii_read(QFPROM_RAW_CALIBRATION_ROW7_LSB);
			ldo_efuse = (val & GENMASK(26, 23)) >> 23;
			icc_efuse = (val & GENMASK(31, 27)) >> 27;
			break;
		case 2:
			val = ipq_mii_read(QFPROM_RAW_CALIBRATION_ROW8_LSB);
			ldo_efuse = (val & GENMASK(26, 23)) >> 23;
			icc_efuse = (val & GENMASK(31, 27)) >> 27;
			break;
		case 3:
			val = ipq_mii_read(QFPROM_RAW_CALIBRATION_ROW6_MSB);
			ldo_efuse = (val & GENMASK(17, 14)) >> 14;
			icc_efuse = (val & GENMASK(22, 18)) >> 18;
			break;
	}
	reg_val = ipq_phy_dbg_read(phy_addr, PHY_LDO_EFUSE_REG);
	reg_val = (reg_val & ~GENMASK(7, 4)) | (ldo_efuse << 4);
	ipq_phy_dbg_write(phy_addr, PHY_LDO_EFUSE_REG, reg_val);

	reg_val = ipq_phy_dbg_read(phy_addr, PHY_ICC_EFUSE_REG);
	reg_val = (reg_val & ~GENMASK(4, 0)) | icc_efuse;
	ipq_phy_dbg_write(phy_addr, PHY_ICC_EFUSE_REG, reg_val);
}

void ipq_clock_init(void)
{
	u32 val = 0;
	int i;

	/* Enable serdes */
	ipq_clk_enable(SRDS0_SYS_CBCR);
	ipq_clk_enable(SRDS1_SYS_CBCR);

	/* Reset serdes */
	ipq_clk_reset(SRDS0_SYS_CBCR);
	ipq_clk_reset(SRDS1_SYS_CBCR);

	/* Disable EPHY GMII clock */
	i = 0;
	while (i < 2 * PHY_ADDR_NUM) {
		ipq_clk_disable(GEPHY0_TX_CBCR + i*0x20);
		i++;
	}

	/* Enable ephy */
	ipq_clk_enable(EPHY0_SYS_CBCR);
	ipq_clk_enable(EPHY1_SYS_CBCR);
	ipq_clk_enable(EPHY2_SYS_CBCR);
	ipq_clk_enable(EPHY3_SYS_CBCR);

	/* Reset ephy */
	ipq_clk_reset(EPHY0_SYS_CBCR);
	ipq_clk_reset(EPHY1_SYS_CBCR);
	ipq_clk_reset(EPHY2_SYS_CBCR);
	ipq_clk_reset(EPHY3_SYS_CBCR);

	/* Deassert EPHY DSP */
	val = ipq_mii_read(QCA8084_GCC_GEPHY_MISC);
	val &= ~GENMASK(4, 0);
	ipq_mii_write(QCA8084_GCC_GEPHY_MISC, val);

	/*for ES chips, need to load efuse manually*/
	val = ipq_mii_read(QFPROM_RAW_PTE_ROW2_MSB);
	val = (val & GENMASK(23, 16)) >> 16;
	if(val == 1 || val == 2) {
		for(i = 0; i < 4; i++)
			ipq_qca8084_efuse_loading(i);
	}

	/* Enable efuse loading into analog circuit */
	val = ipq_mii_read(EPHY_CFG);
	/* BIT20 for PHY0 and PHY1, BIT21 for PHY2 and PHY3 */
	val &= ~GENMASK(21, 20);
	ipq_mii_write(EPHY_CFG, val);

	udelay(11000);
}

void ipq_phy_addr_fixup(void)
{
	int phy_index, addr;
	u32 val;
	unsigned long phyaddr_mask = 0;

	val = ipq_mii_read(EPHY_CFG);

	for (phy_index = 0, addr = 1; addr <= 4; phy_index++, addr++) {
		phyaddr_mask |= BIT(addr);
		addr &= GENMASK(4, 0);
		val &= ~(GENMASK(4, 0) << (phy_index * PHY_ADDR_LENGTH));
		val |= addr << (phy_index * PHY_ADDR_LENGTH);
	}

	pr_debug("programme EPHY reg 0x%x with 0x%x\n", EPHY_CFG, val);
	ipq_mii_write(EPHY_CFG, val);

	/* Programe the UNIPHY address if uniphyaddr_fixup specified.
	 * the UNIPHY address will select three MDIO address from
	 * unoccupied MDIO address space.
	 */
	val = ipq_mii_read(UNIPHY_CFG);

	/* For qca8386, the switch occupies the other 16 MDIO address,
	 * for example, if the phy address is in the range of 0 to 15,
	 * the switch will occupy the MDIO address from 16 to 31.
	 */
	phyaddr_mask |= GENMASK(31, 16);

	phy_index = 0;

	for_each_clear_bit_from(addr, &phyaddr_mask, PHY_MAX_ADDR) {
		if (phy_index >= UNIPHY_ADDR_NUM)
			break;
		val &= ~(GENMASK(4, 0) << (phy_index * PHY_ADDR_LENGTH));
		val |= addr << (phy_index * PHY_ADDR_LENGTH);
		phy_index++;
	}

	if (phy_index < UNIPHY_ADDR_NUM) {
		for_each_clear_bit(addr, &phyaddr_mask, PHY_MAX_ADDR) {
			if (phy_index >= UNIPHY_ADDR_NUM)
				break;
			val &= ~(GENMASK(4, 0) << (phy_index * PHY_ADDR_LENGTH));
			val |= addr << (phy_index * PHY_ADDR_LENGTH);
			phy_index++;
		}
	}

	pr_debug("programme UNIPHY reg 0x%x with 0x%x\n", UNIPHY_CFG, val);
	ipq_mii_write(UNIPHY_CFG, val);
}
#endif

int ipq_sw_mdio_init(const char *name)
{
	struct mii_dev *bus = mdio_alloc();
	if(!bus) {
		printf("Failed to allocate IPQ MDIO bus\n");
		return -1;
	}

	bus->read = ipq_phy_read;
	bus->write = ipq_phy_write;
	bus->reset = NULL;
	snprintf(bus->name, MDIO_NAME_LEN, name);
	return mdio_register(bus);
}

#ifdef CONFIG_QCA8084_PHY
static int do_ipq_mii(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
	char op[2];
	unsigned int reg = 0;
	unsigned int data = 0;

	if (argc < 2)
		return CMD_RET_USAGE;

	op[0] = argv[1][0];
	if (strlen(argv[1]) > 1)
		op[1] = argv[1][1];
	else
		op[1] = '\0';

	if (argc >= 3)
		reg = simple_strtoul(argv[2], NULL, 16);
	if (argc >= 4)
		data = simple_strtoul(argv[3], NULL, 16);

	if (op[0] == 'r') {
		data = ipq_mii_read(reg);
		printf("0x%x\n", data);
	} else if (op[0] == 'w') {
		ipq_mii_write(reg, data);
	} else {
		return CMD_RET_USAGE;
	}

	return 0;
}

U_BOOT_CMD(
	ipq_mii, 4, 1, do_ipq_mii,
	"IPQ mii utility commands",
	"ipq_mii read <reg>		- read IPQ MII register <reg>\n"
	"ipq_mii write <reg> <data>	- write IPQ MII register <reg> with <data>\n"
);
#endif

static int do_ipq_mdio(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
	char		op[2];
	unsigned int	addr = 0, reg = 0;
	unsigned int	data = 0;

	if (argc < 2)
		return CMD_RET_USAGE;

	op[0] = argv[1][0];
	if (strlen(argv[1]) > 1)
		op[1] = argv[1][1];
	else
		op[1] = '\0';

	if (argc >= 3)
		addr = simple_strtoul(argv[2], NULL, 16);
	if (argc >= 4)
		reg = simple_strtoul(argv[3], NULL, 16);
	if (argc >= 5)
		data = simple_strtoul(argv[4], NULL, 16);

	if (op[0] == 'r') {
		data = ipq_mdio_read(addr, reg, NULL);
		printf("0x%x\n", data);
	} else if (op[0] == 'w') {
		ipq_mdio_write(addr, reg, data);
	} else {
		return CMD_RET_USAGE;
	}

	return 0;
}

U_BOOT_CMD(
	ipq_mdio, 5, 1, do_ipq_mdio,
	"IPQ mdio utility commands",
	"ipq_mdio read   <addr> <reg>               - read  IPQ MDIO PHY <addr> register <reg>\n"
	"ipq_mdio write  <addr> <reg> <data>        - write IPQ MDIO PHY <addr> register <reg>\n"
	"Addr and/or reg may be ranges, e.g. 0-7."
);
