/*
 * Copyright (c) 2015-2016, 2020 The Linux Foundation. All rights reserved.
 *
 * Copyright (c) 2022, Qualcomm Innovation Center, Inc. All rights reserved.
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

/*
 * Manage the QTI S17C ethernet PHY.
 *
 * All definitions in this file are operating system independent!
 */

#include <common.h>
#include "athrs17_phy.h"

/*
 * Externel Common mdio read, PHY Name : IPQ MDIO1
 */

extern int ipq_mdio_write(int mii_id, int regnum, u16 value);
extern int ipq_mdio_read(int mii_id, int regnum, ushort *data);

/******************************************************************************
 * FUNCTION DESCRIPTION: Read switch internal register.
 *                       Switch internal register is accessed through the
 *                       MDIO interface. MDIO access is only 16 bits wide so
 *                       it needs the two time access to complete the internal
 *                       register access.
 * INPUT               : register address
 * OUTPUT              : Register value
 *
 *****************************************************************************/
static uint32_t athrs17_reg_read(uint32_t reg_addr)
{
	uint32_t reg_word_addr;
	uint32_t phy_addr, reg_val;
	uint16_t phy_val;
	uint16_t tmp_val;
	uint8_t phy_reg;

	/* change reg_addr to 16-bit word address, 32-bit aligned */
	reg_word_addr = (reg_addr & 0xfffffffc) >> 1;

	/* configure register high address */
	phy_addr = 0x18;
	phy_reg = 0x0;
	phy_val = (uint16_t) ((reg_word_addr >> 8) & 0x1ff);  /* bit16-8 of reg address */
	ipq_mdio_write(phy_addr, phy_reg, phy_val);
	/*
	 * For some registers such as MIBs, since it is read/clear, we should
	 * read the lower 16-bit register then the higher one
	 */

	/* read register in lower address */
	phy_addr = 0x10 | ((reg_word_addr >> 5) & 0x7); /* bit7-5 of reg address */
	phy_reg = (uint8_t) (reg_word_addr & 0x1f);   /* bit4-0 of reg address */
	ipq_mdio_read(phy_addr, phy_reg, &phy_val);

	/* read register in higher address */
	reg_word_addr++;
	phy_addr = 0x10 | ((reg_word_addr >> 5) & 0x7); /* bit7-5 of reg address */
	phy_reg = (uint8_t) (reg_word_addr & 0x1f);   /* bit4-0 of reg address */
	ipq_mdio_read(phy_addr, phy_reg, &tmp_val);
	reg_val = (tmp_val << 16 | phy_val);

	return reg_val;
}

/******************************************************************************
 * FUNCTION DESCRIPTION: Write switch internal register.
 *                       Switch internal register is accessed through the
 *                       MDIO interface. MDIO access is only 16 bits wide so
 *                       it needs the two time access to complete the internal
 *                       register access.
 * INPUT               : register address, value to be written
 * OUTPUT              : NONE
 *
 *****************************************************************************/
static void athrs17_reg_write(uint32_t reg_addr, uint32_t reg_val)
{
	uint32_t reg_word_addr;
	uint32_t phy_addr;
	uint16_t phy_val;
	uint8_t phy_reg;

	/* change reg_addr to 16-bit word address, 32-bit aligned */
	reg_word_addr = (reg_addr & 0xfffffffc) >> 1;

	/* configure register high address */
	phy_addr = 0x18;
	phy_reg = 0x0;
	phy_val = (uint16_t) ((reg_word_addr >> 8) & 0x1ff);  /* bit16-8 of reg address */
	ipq_mdio_write(phy_addr, phy_reg, phy_val);

	/*
	 * For some registers such as ARL and VLAN, since they include BUSY bit
	 * in lower address, we should write the higher 16-bit register then the
	 * lower one
	 */

	/* read register in higher address */
	reg_word_addr++;
	phy_addr = 0x10 | ((reg_word_addr >> 5) & 0x7); /* bit7-5 of reg address */
	phy_reg = (uint8_t) (reg_word_addr & 0x1f);   /* bit4-0 of reg address */
	phy_val = (uint16_t) ((reg_val >> 16) & 0xffff);
	ipq_mdio_write(phy_addr, phy_reg, phy_val);

	/* write register in lower address */
	reg_word_addr--;
	phy_addr = 0x10 | ((reg_word_addr >> 5) & 0x7); /* bit7-5 of reg address */
	phy_reg = (uint8_t) (reg_word_addr & 0x1f);   /* bit4-0 of reg address */
	phy_val = (uint16_t) (reg_val & 0xffff);
	ipq_mdio_write(phy_addr, phy_reg, phy_val);
}

/*********************************************************************
 * FUNCTION DESCRIPTION: V-lan configuration given by Switch team
			 Vlan 1:PHY0,1,2,3 and Mac 6 of s17c
			 Vlan 2:PHY4 and Mac 0 of s17c
 * INPUT : NONE
 * OUTPUT: NONE
 *********************************************************************/
void athrs17_vlan_config(void)
{
	athrs17_reg_write(S17_P0LOOKUP_CTRL_REG, 0x00140020);
	athrs17_reg_write(S17_P0VLAN_CTRL0_REG, 0x20001);

	athrs17_reg_write(S17_P1LOOKUP_CTRL_REG, 0x0014005c);
	athrs17_reg_write(S17_P1VLAN_CTRL0_REG, 0x10001);

	athrs17_reg_write(S17_P2LOOKUP_CTRL_REG, 0x0014005a);
	athrs17_reg_write(S17_P2VLAN_CTRL0_REG, 0x10001);

	athrs17_reg_write(S17_P3LOOKUP_CTRL_REG, 0x00140056);
	athrs17_reg_write(S17_P3VLAN_CTRL0_REG, 0x10001);

	athrs17_reg_write(S17_P4LOOKUP_CTRL_REG, 0x0014004e);
	athrs17_reg_write(S17_P4VLAN_CTRL0_REG, 0x10001);

	athrs17_reg_write(S17_P5LOOKUP_CTRL_REG, 0x00140001);
	athrs17_reg_write(S17_P5VLAN_CTRL0_REG, 0x20001);

	athrs17_reg_write(S17_P6LOOKUP_CTRL_REG, 0x0014001e);
	athrs17_reg_write(S17_P6VLAN_CTRL0_REG, 0x10001);
	printf("%s ...done\n", __func__);
}

/*******************************************************************
* FUNCTION DESCRIPTION: Reset S17 register
* INPUT: NONE
* OUTPUT: NONE
*******************************************************************/
int athrs17_init_switch(void)
{
	uint32_t data;
	uint32_t i = 0;

	/* Reset the switch before initialization */
	athrs17_reg_write(S17_MASK_CTRL_REG, S17_MASK_CTRL_SOFT_RET);
	do {
		udelay(10);
		data = athrs17_reg_read(S17_MASK_CTRL_REG);
		i++;
		if (i == 10){
			printf("QCA_8337: Failed to reset\n");
			return -1;
		}
	} while (data & S17_MASK_CTRL_SOFT_RET);

	i = 0;

	do {
		udelay(10);
		data = athrs17_reg_read(S17_GLOBAL_INT0_REG);
		i++;
		if (i == 10)
			return -1;
	} while ((data & S17_GLOBAL_INITIALIZED_STATUS) != S17_GLOBAL_INITIALIZED_STATUS);

	return 0;
}

/*********************************************************************
 * FUNCTION DESCRIPTION: Configure S17 register
 * INPUT : NONE
 * OUTPUT: NONE
 *********************************************************************/
void athrs17_reg_init(ipq_s17c_swt_cfg_t *swt_cfg)
{
	athrs17_reg_write(S17_MAC_PWR_REG, swt_cfg->mac_pwr);

	athrs17_reg_write(S17_GLOFW_CTRL1_REG, (S17_IGMP_JOIN_LEAVE_DPALL |
						S17_BROAD_DPALL |
						S17_MULTI_FLOOD_DPALL |
						S17_UNI_FLOOD_DPALL));

	if (swt_cfg->update) {
		athrs17_reg_write(S17_P0STATUS_REG, swt_cfg->port0_status);
		athrs17_reg_write(S17_P5PAD_MODE_REG, swt_cfg->pad5_mode);
		athrs17_reg_write(S17_P0PAD_MODE_REG, swt_cfg->pad0_mode);
	} else {
		athrs17_reg_write(S17_P0STATUS_REG, (S17_SPEED_1000M |
						S17_TXMAC_EN |
						S17_RXMAC_EN |
						S17_DUPLEX_FULL));

		athrs17_reg_write(S17_P5PAD_MODE_REG, S17_MAC0_RGMII_RXCLK_DELAY);

		athrs17_reg_write(S17_P0PAD_MODE_REG, (S17_MAC0_RGMII_EN |
						S17_MAC0_RGMII_TXCLK_DELAY |
						S17_MAC0_RGMII_RXCLK_DELAY |
					(0x1 << S17_MAC0_RGMII_TXCLK_SHIFT) |
					(0x2 << S17_MAC0_RGMII_RXCLK_SHIFT)));
	}

	printf("%s: complete\n", __func__);
}

/*********************************************************************
 * FUNCTION DESCRIPTION: Configure S17 register
 * INPUT : NONE
 * OUTPUT: NONE
 *********************************************************************/
void athrs17_reg_init_lan(ipq_s17c_swt_cfg_t *swt_cfg)
{
	uint32_t reg_val;

	if (swt_cfg->update) {
		athrs17_reg_write(S17_P6STATUS_REG, swt_cfg->port6_status);
		athrs17_reg_write(S17_MAC_PWR_REG, swt_cfg->mac_pwr);
		athrs17_reg_write(S17_P6PAD_MODE_REG, swt_cfg->pad6_mode);
		athrs17_reg_write(S17_PWS_REG, swt_cfg->port0);
		athrs17_reg_write(S17_SGMII_CTRL_REG, swt_cfg->sgmii_ctrl);
	} else {

		athrs17_reg_write(S17_P6STATUS_REG, (S17_SPEED_1000M |
							S17_TXMAC_EN |
							S17_RXMAC_EN |
							S17_DUPLEX_FULL));

		athrs17_reg_write(S17_MAC_PWR_REG, swt_cfg->mac_pwr);
		reg_val = athrs17_reg_read(S17_P6PAD_MODE_REG);
		athrs17_reg_write(S17_P6PAD_MODE_REG, (reg_val | S17_MAC6_SGMII_EN));

		athrs17_reg_write(S17_PWS_REG, 0x2613a0);

		athrs17_reg_write(S17_SGMII_CTRL_REG,(S17c_SGMII_EN_PLL |
						S17c_SGMII_EN_RX |
						S17c_SGMII_EN_TX |
						S17c_SGMII_EN_SD |
						S17c_SGMII_BW_HIGH |
						S17c_SGMII_SEL_CLK125M |
						S17c_SGMII_TXDR_CTRL_600mV |
						S17c_SGMII_CDR_BW_8 |
						S17c_SGMII_DIS_AUTO_LPI_25M |
						S17c_SGMII_MODE_CTRL_SGMII_PHY |
						S17c_SGMII_PAUSE_SG_TX_EN_25M |
						S17c_SGMII_ASYM_PAUSE_25M |
						S17c_SGMII_PAUSE_25M |
						S17c_SGMII_HALF_DUPLEX_25M |
						S17c_SGMII_FULL_DUPLEX_25M));
	}
	athrs17_reg_write(S17_MODULE_EN_REG, S17_MIB_COUNTER_ENABLE);
}

struct athrs17_regmap {
	uint32_t start;
	uint32_t end;
};

struct athrs17_regmap regmap[] = {
	{ 0x000,  0x0e4  },
	{ 0x100,  0x168  },
	{ 0x200,  0x270  },
	{ 0x400,  0x454  },
	{ 0x600,  0x718  },
	{ 0x800,  0xb70  },
	{ 0xC00,  0xC80  },
	{ 0x1100, 0x11a7 },
	{ 0x1200, 0x12a7 },
	{ 0x1300, 0x13a7 },
	{ 0x1400, 0x14a7 },
	{ 0x1600, 0x16a7 },
};

int do_ar8xxx_dump(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[]) {
	int i;

	for (i = 0; i < ARRAY_SIZE(regmap); i++) {
		uint32_t reg;
		struct athrs17_regmap *section = &regmap[i];

		for (reg = section->start; reg <= section->end; reg += sizeof(uint32_t)) {
			uint32_t val = athrs17_reg_read(reg);
			printf("%03zx: %08zx\n", reg, val);
		}
	}

	return 0;
};
U_BOOT_CMD(
	ar8xxx_dump,    1,    1,    do_ar8xxx_dump,
	"Dump ar8xxx registers",
	"\n    - print all ar8xxx registers\n"
);

/*********************************************************************
 *
 * FUNCTION DESCRIPTION: This function invokes RGMII,
 * 			SGMII switch init routines.
 * INPUT : ipq_s17c_swt_cfg_t *
 * OUTPUT: NONE
 *
**********************************************************************/
int ipq_athrs17_init(ipq_s17c_swt_cfg_t *swt_cfg)
{
	int ret;

	if (swt_cfg == NULL)
		return -1;

	ret = athrs17_init_switch();
	if (ret != -1) {
		athrs17_reg_init(swt_cfg);
		athrs17_reg_init_lan(swt_cfg);
		if (!(swt_cfg->skip_vlan))
			athrs17_vlan_config();
		printf ("S17c init  done\n");
	}

	return ret;
}

int ipq_qca8337_switch_init(ipq_s17c_swt_cfg_t *s17c_swt_cfg)
{
	int port;
	for (port = 0; port < s17c_swt_cfg->port_count; ++port) {
		u32 phy_val;

		/* phy powerdown */
		ipq_mdio_write(s17c_swt_cfg->port_phy_address[port], 0x0,
				0x0800);
		phy_val = ipq_mdio_read(s17c_swt_cfg->port_phy_address[port],
				0x3d, NULL);
		phy_val &= ~0x0040;
		ipq_mdio_write(s17c_swt_cfg->port_phy_address[port], 0x3d,
				phy_val);

		/*
		* PHY will stop the tx clock for a while when link is down
		* en_anychange  debug port 0xb bit13 = 0  //speed up link down tx_clk
		* sel_rst_80us  debug port 0xb bit10 = 0  //speed up speed mode change to 2'b10 tx_clk
		*/
		phy_val = ipq_mdio_read(s17c_swt_cfg->port_phy_address[port],
				0xb, NULL);
		phy_val &= ~0x2400;
		ipq_mdio_write(s17c_swt_cfg->port_phy_address[port], 0xb,
				phy_val);
		mdelay(100);
	}

	if (ipq_athrs17_init(s17c_swt_cfg) != 0) {
		printf("QCA_8337 switch init failed \n");
		return -1;
	}

	for (port = 0; port < s17c_swt_cfg->port_count; ++port) {
		ipq_mdio_write(s17c_swt_cfg->port_phy_address[port],
				MII_ADVERTISE, ADVERTISE_ALL |
				ADVERTISE_PAUSE_CAP | ADVERTISE_PAUSE_ASYM);
		/* phy reg 0x9, b10,1 = Prefer multi-port device (master) */
		ipq_mdio_write(s17c_swt_cfg->port_phy_address[port],
				MII_CTRL1000, (0x0400|ADVERTISE_1000FULL));
		ipq_mdio_write(s17c_swt_cfg->port_phy_address[port],
				MII_BMCR, BMCR_RESET | BMCR_ANENABLE);
		mdelay(100);
	}

	return 0;
}

int ipq_qca8337_link_update(ipq_s17c_swt_cfg_t *s17c_swt_cfg)
{
	uint16_t phy_data;
	int status = 1;

	for(int i = 0; i < s17c_swt_cfg->port_count; ++i){
		phy_data = ipq_mdio_read(s17c_swt_cfg->port_phy_address[i],
			0x11, NULL);

		if (phy_data == 0x50)
			continue;

		/* Atleast one port should be link up*/
		if (phy_data & LINK_UP)
			status = 0;

		printf("QCA8337: Port%d %s ", i + 1, LINK(phy_data));

		switch(SPEED(phy_data)){
		case SPEED_1000M:
			printf("Speed :1000M ");
			break;
		case SPEED_100M:
			printf("Speed :100M ");
			break;
		default:
			printf("Speed :10M ");
		}

		printf ("%s \n", DUPLEX(phy_data));
	}
	return status;
}

void ipq_s17c_switch_reset(int gpio)
{
	unsigned int *switch_gpio_base =
		(unsigned int *)GPIO_CONFIG_ADDR(gpio);

	writel(0x203, switch_gpio_base);
	writel(0x0, GPIO_IN_OUT_ADDR(gpio));
	mdelay(500);
	writel(0x2, GPIO_IN_OUT_ADDR(gpio));
}
