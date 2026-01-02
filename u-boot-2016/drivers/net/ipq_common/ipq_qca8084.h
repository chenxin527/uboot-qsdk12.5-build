/*
 * Copyright (c) 2022, The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/

#ifndef _QCA8084_PHY_H_
#define _QCA8084_PHY_H_

#include <linux/compat.h>

#ifdef __cplusplus
extern "C" {
#endif

/*QCA8084 PHY Fixup definitions */
#define PORT_UQXGMII						0x1
#define PHY_SGMII_BASET						0x2
#define PORT_SGMII_PLUS						0x3

/*MII register*/
#define QCA8084_PHY_FIFO_CONTROL				0x19

/*MII register field*/
#define QCA8084_PHY_FIFO_RESET					0x3

/*MMD1 register*/
#define QCA8084_PHY_MMD1_NUM					0x1

/*MMD3 register*/
#define QCA8084_PHY_MMD3_NUM					0x3
#define QCA8084_PHY_MMD3_ADDR_8023AZ_EEE_2500M_CAPABILITY	0x15
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL3			0x8074
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL4			0x8075
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL5			0x8076
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL6			0x8077
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL7			0x8078
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL9			0x807a
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL13			0x807e
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL14			0x807f

/*MMD3 register field*/
#define QCA8084_PHY_EEE_CAPABILITY_2500M			0x1
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL3_VAL			0xc040
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL4_VAL			0xa060
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL5_VAL			0xc040
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL6_VAL			0xa060
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL7_VAL			0xc050
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL9_VAL			0xc060
#define QCA8084_PHY_MMD3_CDT_THRESH_CTRL13_VAL			0xb060
#define QCA8084_PHY_MMD3_NEAR_ECHO_THRESH_VAL			0x1eb0

/*MMD7 register*/
#define QCA8084_PHY_MMD7_NUM					0x7
#define QCA8084_PHY_MMD7_ADDR_8023AZ_EEE_2500M_CTRL		0x3e
#define QCA8084_PHY_MMD7_ADDR_8023AZ_EEE_2500M_PARTNER		0x3f
#define QCA8084_PHY_MMD7_IPG_10_11_ENABLE			0x901d

/*MMD7 register field*/
#define QCA8084_PHY_8023AZ_EEE_2500BT				0x1
#define QCA8084_PHY_MMD7_IPG_10_EN				0
#define QCA8084_PHY_MMD7_IPG_11_EN				0x1

/*DEBUG port analog register*/
#define QCA8084_PHY_DEBUG_ANA_INTERFACE_CLK_SEL			0x8b80
#define QCA8084_DEBUG_PORT_ADDRESS				29
#define QCA8084_DEBUG_PORT_DATA					30

#define QCA8084_PHY_CONTROL					0
#define QCA8084_AUTONEG_ADVERT                   4
#define QCA8084_LINK_PARTNER_ABILITY             5
#define QCA8084_1000BASET_CONTROL                9
#define QCA8084_1000BASET_STATUS                 10
#define QCA8084_PHY_SPEC_STATUS					17
#define QCA8084_CTRL_AUTONEGOTIATION_ENABLE			0x1000
#define QCA8084_CTRL_SOFTWARE_RESET				0x8000


#define QCA8084_STATUS_LINK_PASS				0x0400
#define PHY_INVALID_DATA			0xffff

#define QCA8084_PHY_MMD7_AUTONEGOTIATION_CONTROL 0x20
#define QCA8084_PHY_MMD7_LP_2500M_ABILITY        0x21

  /* Auto-Negotiation Advertisement register. offset:4 */
#define QCA8084_ADVERTISE_SELECTOR_FIELD         0x0001

  /* 10T   Half Duplex Capable */
#define QCA8084_ADVERTISE_10HALF                 0x0020

  /* 10T   Full Duplex Capable */
#define QCA8084_ADVERTISE_10FULL                 0x0040

  /* 100TX Half Duplex Capable */
#define QCA8084_ADVERTISE_100HALF                0x0080

  /* 100TX Full Duplex Capable */
#define QCA8084_ADVERTISE_100FULL                0x0100

  /* 100T4 Capable */
#define QCA8084_ADVERTISE_100T4                  0x0200

  /* Pause operation desired */
#define QCA8084_ADVERTISE_PAUSE                  0x0400

  /* Asymmetric Pause Direction bit */
#define QCA8084_ADVERTISE_ASYM_PAUSE             0x0800

  /* Remote Fault detected */
#define QCA8084_ADVERTISE_REMOTE_FAULT           0x2000

  /* 1000TX Half Duplex Capable */
#define QCA8084_ADVERTISE_1000HALF               0x0100

  /* 1000TX Full Duplex Capable */
#define QCA8084_ADVERTISE_1000FULL               0x0200

  /* 2500TX Full Duplex Capable */
#define QCA8084_ADVERTISE_2500FULL               0x80

#define QCA8084_ADVERTISE_ALL \
    (QCA8084_ADVERTISE_10HALF | QCA8084_ADVERTISE_10FULL | \
     QCA8084_ADVERTISE_100HALF | QCA8084_ADVERTISE_100FULL | \
     QCA8084_ADVERTISE_1000FULL)

#define QCA8084_ADVERTISE_MEGA_ALL \
    (QCA8084_ADVERTISE_10HALF | QCA8084_ADVERTISE_10FULL | \
     QCA8084_ADVERTISE_100HALF | QCA8084_ADVERTISE_100FULL | \
     QCA8084_ADVERTISE_PAUSE | QCA8084_ADVERTISE_ASYM_PAUSE)

/* FDX =1, half duplex =0 */
#define QCA8084_CTRL_FULL_DUPLEX                 0x0100

  /* Restart auto negotiation */
#define QCA8084_CTRL_RESTART_AUTONEGOTIATION     0x0200

  /* 1=Duplex 0=Half Duplex */
#define QCA8084_STATUS_FULL_DUPLEX               0x2000
#define QCA8084_PHY_RX_FLOWCTRL_STATUS           0x4
#define QCA8084_PHY_TX_FLOWCTRL_STATUS           0x8

  /* Speed, bits 9:7 */
#define QCA8084_STATUS_SPEED_MASK               0x380


  /* 000=10Mbs */
#define QCA8084_STATUS_SPEED_10MBS              0x0000

  /* 001=100Mbs */
#define QCA8084_STATUS_SPEED_100MBS             0x80

  /* 010=1000Mbs */
#define QCA8084_STATUS_SPEED_1000MBS            0x100

  /* 100=2500Mbs */
#define QCA8084_STATUS_SPEED_2500MBS            0x200


#define QCA8084_MII_ADDR_C45			(1<<30)
#define QCA8084_REG_C45_ADDRESS(dev_type, reg_num) (QCA8084_MII_ADDR_C45 | \
			((dev_type & 0x1f) << 16) | (reg_num & 0xffff))

typedef enum {
	ADC_RISING = 0,
	ADC_FALLING = 0xf0,
}
qca8084_adc_edge_t;

//phy autoneg adv
#define FAL_PHY_ADV_10T_HD      0x01
#define FAL_PHY_ADV_10T_FD      0x02
#define FAL_PHY_ADV_100TX_HD    0x04
#define FAL_PHY_ADV_100TX_FD    0x08
//#define FAL_PHY_ADV_1000T_HD    0x100
#define FAL_PHY_ADV_1000T_FD    0x200
#define FAL_PHY_ADV_1000BX_HD    0x400
#define FAL_PHY_ADV_1000BX_FD    0x800
#define FAL_PHY_ADV_2500T_FD    0x1000
#define FAL_PHY_ADV_5000T_FD    0x2000
#define FAL_PHY_ADV_10000T_FD    0x4000
#define FAL_PHY_ADV_10G_R_FD    0x8000

#define FAL_DEFAULT_MAX_FRAME_SIZE 0x5ee

#define FAL_PHY_ADV_PAUSE       0x10
#define FAL_PHY_ADV_ASY_PAUSE   0x20


/** Bit manipulation macros */
#ifndef BITSM
#define BITSM(_s, _n)                                 (((1UL << (_n)) - 1) << _s)
#endif

#define SW_BIT_MASK_U32(nr) (~(0xFFFFFFFF << (nr)))

#define SW_FIELD_MASK_U32(offset, len) \
	((SW_BIT_MASK_U32(len) << (offset)))

#define SW_FIELD_MASK_NOT_U32(offset,len) \
	(~(SW_BIT_MASK_U32(len) << (offset)))

#define SW_FIELD_2_REG(field_val, bit_offset) \
	(field_val << (bit_offset) )

#define SW_REG_2_FIELD(reg_val, bit_offset, field_len) \
	(((reg_val) >> (bit_offset)) & ((1 << (field_len)) - 1))

#define SW_FIELD_GET_BY_REG_U32(reg_value, field_value, bit_offset, field_len)\
	do { \
		(field_value) = \
		(((reg_value) >> (bit_offset)) & SW_BIT_MASK_U32(field_len)); \
	} while (0)

#define SW_REG_SET_BY_FIELD_U32(reg_value, field_value, bit_offset, field_len)\
	do { \
		(reg_value) = \
		(((reg_value) & SW_FIELD_MASK_NOT_U32((bit_offset),(field_len))) \
		 | (((field_value) & SW_BIT_MASK_U32(field_len)) << (bit_offset)));\
	} while (0)

#define SW_GET_FIELD_BY_REG(reg, field, field_value, reg_value) \
	SW_FIELD_GET_BY_REG_U32(reg_value, field_value, reg##_##field##_BOFFSET, \
			reg##_##field##_BLEN)

#define SW_SET_REG_BY_FIELD(reg, field, field_value, reg_value) \
	SW_REG_SET_BY_FIELD_U32(reg_value, field_value, reg##_##field##_BOFFSET, \
			reg##_##field##_BLEN)

#define QCA8084_REG_ENTRY_GET(reg, index, value) \
	*((u32 *) value) = ipq_mii_read(reg##_OFFSET + ((u32)index) * reg##_E_OFFSET);

#define QCA8084_REG_ENTRY_SET(reg, index, value) \
	ipq_mii_write(reg##_OFFSET + ((u32)index) * reg##_E_OFFSET, *((u32 *) value));

#define QCA8084_REG_FIELD_GET(reg, index, field, value) \
	do { \
		qca8084_reg_field_get(reg##_OFFSET + ((u32)index) * reg##_E_OFFSET,\
				reg##_##field##_BOFFSET, \
				reg##_##field##_BLEN, (u8*)value);\
	} while (0);

#define QCA8084_REG_FIELD_SET(reg, index, field, value) \
	do { \
		qca8084_reg_field_set(reg##_OFFSET + ((u32)index) * reg##_E_OFFSET,\
				reg##_##field##_BOFFSET, \
				reg##_##field##_BLEN, (u8*)value);\
	} while (0);


/* Chip information */
#define QCA_VER_QCA8084		0x17
#define CHIP_QCA8084		0x13

/* Port Status Register */
#define PORT_STATUS
#define PORT_STATUS_OFFSET	0x007c
#define PORT_STATUS_E_LENGTH	4
#define PORT_STATUS_E_OFFSET	0x0004
#define PORT_STATUS_NR_E	7

#define DUPLEX_MODE
#define PORT_STATUS_DUPLEX_MODE_BOFFSET         6
#define PORT_STATUS_DUPLEX_MODE_BLEN            1
#define PORT_STATUS_DUPLEX_MODE_FLAG            HSL_RW

#define SPEED_MODE
#define PORT_STATUS_SPEED_MODE_BOFFSET          0
#define PORT_STATUS_SPEED_MODE_BLEN             2
#define PORT_STATUS_SPEED_MODE_FLAG             HSL_RW

#define LINK_EN
#define PORT_STATUS_LINK_EN_BOFFSET             9
#define PORT_STATUS_LINK_EN_BLEN                1
#define PORT_STATUS_LINK_EN_FLAG                HSL_RW

#define RXMAC_EN
#define PORT_STATUS_RXMAC_EN_BOFFSET            3
#define PORT_STATUS_RXMAC_EN_BLEN               1
#define PORT_STATUS_RXMAC_EN_FLAG               HSL_RW

#define TXMAC_EN
#define PORT_STATUS_TXMAC_EN_BOFFSET            2
#define PORT_STATUS_TXMAC_EN_BLEN               1
#define PORT_STATUS_TXMAC_EN_FLAG               HSL_RW

#define RX_FLOW_EN
#define PORT_STATUS_RX_FLOW_EN_BOFFSET          5
#define PORT_STATUS_RX_FLOW_EN_BLEN             1
#define PORT_STATUS_RX_FLOW_EN_FLAG             HSL_RW

#define TX_FLOW_EN
#define PORT_STATUS_TX_FLOW_EN_BOFFSET          4
#define PORT_STATUS_TX_FLOW_EN_BLEN             1
#define PORT_STATUS_TX_FLOW_EN_FLAG             HSL_RW

#define TX_HALF_FLOW_EN
#define PORT_STATUS_TX_HALF_FLOW_EN_BOFFSET     7
#define PORT_STATUS_TX_HALF_FLOW_EN_BLEN        1
#define PORT_STATUS_TX_HALF_FLOW_EN_FLAG        HSL_RW

#define QCA8084_PORT_SPEED_10M          0
#define QCA8084_PORT_SPEED_100M         1
#define QCA8084_PORT_SPEED_1000M        2
#define QCA8084_PORT_SPEED_2500M        QCA8084_PORT_SPEED_1000M
#define QCA8084_PORT_HALF_DUPLEX        0
#define QCA8084_PORT_FULL_DUPLEX        1

/* Header Ctl Register */
#define HEADER_CTL
#define HEADER_CTL_OFFSET        0x0098
#define HEADER_CTL_E_LENGTH      4
#define HEADER_CTL_E_OFFSET      0x0004
#define HEADER_CTL_NR_E          1

#define TYPE_LEN
#define HEADER_CTL_TYPE_LEN_BOFFSET          16
#define HEADER_CTL_TYPE_LEN_BLEN             1
#define HEADER_CTL_TYPE_LEN_FLAG             HSL_RW

#define TYPE_VAL
#define HEADER_CTL_TYPE_VAL_BOFFSET         0
#define HEADER_CTL_TYPE_VAL_BLEN            16
#define HEADER_CTL_TYPE_VAL_FLAG            HSL_RW


/* Port Header Ctl Register */
#define PORT_HDR_CTL
#define PORT_HDR_CTL_OFFSET        0x009c
#define PORT_HDR_CTL_E_LENGTH      4
#define PORT_HDR_CTL_E_OFFSET      0x0004
#define PORT_HDR_CTL_NR_E          7

#define RXHDR_MODE
#define PORT_HDR_CTL_RXHDR_MODE_BOFFSET          2
#define PORT_HDR_CTL_RXHDR_MODE_BLEN             2
#define PORT_HDR_CTL_RXHDR_MODE_FLAG             HSL_RW

#define TXHDR_MODE
#define PORT_HDR_CTL_TXHDR_MODE_BOFFSET          0
#define PORT_HDR_CTL_TXHDR_MODE_BLEN             2
#define PORT_HDR_CTL_TXHDR_MODE_FLAG             HSL_RW

#define QCA8084_HEADER_TYPE_VAL	0xaaaa

/* Global Forward Control1 Register */
#define FORWARD_CTL1
#define FORWARD_CTL1_OFFSET             0x0624
#define FORWARD_CTL1_E_LENGTH           4
#define FORWARD_CTL1_E_OFFSET           0
#define FORWARD_CTL1_NR_E               1

#define BC_FLOOD_DP
#define FORWARD_CTL1_BC_FLOOD_DP_BOFFSET      16
#define FORWARD_CTL1_BC_FLOOD_DP_BLEN         7
#define FORWARD_CTL1_BC_FLOOD_DP_FLAG         HSL_RW

//#######
#define ISISC_PHY_MODE_PHY_ID  4
#define ISISC_LPI_PORT1_OFFSET 4
#define ISISC_LPI_BIT_STEP     2

/* ISIS Mask Control Register */
#define MASK_CTL
#define MASK_CTL_ID               0
#define MASK_CTL_OFFSET           0x0000
#define MASK_CTL_E_LENGTH         4
#define MASK_CTL_E_OFFSET         0
#define MASK_CTL_NR_E             1

#define DEVICE_ID
#define MASK_CTL_DEVICE_ID_BOFFSET            8
#define MASK_CTL_DEVICE_ID_BLEN               8
#define MASK_CTL_DEVICE_ID_FLAG               HSL_RO

#define REV_ID
#define MASK_CTL_REV_ID_BOFFSET               0
#define MASK_CTL_REV_ID_BLEN                  8
#define MASK_CTL_REV_ID_FLAG                  HSL_RO

/* EEE control Register */
#define EEE_CTL
#define EEE_CTL_OFFSET    0x0100
#define EEE_CTL_E_LENGTH  4
#define EEE_CTL_E_OFFSET  0
#define EEE_CTL_NR_E      1

/* Port Status Register */
#define PORT_STATUS
#define PORT_STATUS_OFFSET        0x007c
#define PORT_STATUS_E_LENGTH      4
#define PORT_STATUS_E_OFFSET      0x0004
#define PORT_STATUS_NR_E          7

#define FLOW_LINK_EN
#define PORT_STATUS_FLOW_LINK_EN_BOFFSET        12
#define PORT_STATUS_FLOW_LINK_EN_BLEN           1
#define PORT_STATUS_FLOW_LINK_EN_FLAG           HSL_RW

#define DUPLEX_MODE
#define PORT_STATUS_DUPLEX_MODE_BOFFSET         6
#define PORT_STATUS_DUPLEX_MODE_BLEN            1
#define PORT_STATUS_DUPLEX_MODE_FLAG            HSL_RW

#define SPEED_MODE
#define PORT_STATUS_SPEED_MODE_BOFFSET          0
#define PORT_STATUS_SPEED_MODE_BLEN             2
#define PORT_STATUS_SPEED_MODE_FLAG             HSL_RW

#define LEAVE_EN_OFFSET     2
#define JOIN_EN_OFFSET      1
#define IGMP_MLD_EN_OFFSET  0

/* Port HOL CTL0 Register */
#define PORT_HOL_CTL0
#define PORT_HOL_CTL0_OFFSET         0x0970
#define PORT_HOL_CTL0_E_LENGTH       4
#define PORT_HOL_CTL0_E_OFFSET       0x0008
#define PORT_HOL_CTL0_NR_E           7

#define PORT_DESC_NR
#define PORT_HOL_CTL0_PORT_DESC_NR_BOFFSET           24
#define PORT_HOL_CTL0_PORT_DESC_NR_BLEN              8
#define PORT_HOL_CTL0_PORT_DESC_NR_FLAG              HSL_RW

/* Port HOL CTL1 Register */
#define PORT_HOL_CTL1
#define PORT_HOL_CTL1_OFFSET         0x0974
#define PORT_HOL_CTL1_E_LENGTH       4
#define PORT_HOL_CTL1_E_OFFSET       0x0008
#define PORT_HOL_CTL1_NR_E           7

#define PORT_RED_EN
#define PORT_HOL_CTL1_PORT_RED_EN_BOFFSET            8
#define PORT_HOL_CTL1_PORT_RED_EN_BLEN               1
#define PORT_HOL_CTL1_PORT_RED_EN_FLAG               HSL_RW

#define PORT_IN_DESC_EN
#define PORT_HOL_CTL1_PORT_IN_DESC_EN_BOFFSET        0
#define PORT_HOL_CTL1_PORT_IN_DESC_EN_BLEN           6
#define PORT_HOL_CTL1_PORT_IN_DESC_EN_FLAG           HSL_RW

#define ISISC_QOS_PORT_RX_BUFFER_MAX  504
#define ISISC_QOS_PORT_TX_BUFFER_MAX  2040
#define ISISC_QOS_HOL_STEP       8
#define ISISC_QOS_HOL_MOD        3

typedef enum {
	FAL_NO_HEADER_EN = 0,
	FAL_ONLY_MANAGE_FRAME_EN,
	FAL_ALL_TYPE_FRAME_EN
} port_header_mode_t;

struct port_phy_status
{
	u32 link_status;
	fal_port_speed_t speed;
	fal_port_duplex_t duplex;
	bool tx_flowctrl;
	bool rx_flowctrl;
};


/****************************************************************************
 *
 *  1) PinCtrl/TLMM Register Definition
 *
 ****************************************************************************/
/* TLMM_GPIO_CFGn */
#define TLMM_GPIO_CFGN
#define TLMM_GPIO_CFGN_OFFSET               0xC400000
#define TLMM_GPIO_CFGN_E_LENGTH             4
#define TLMM_GPIO_CFGN_E_OFFSET             0x1000
#define TLMM_GPIO_CFGN_NR_E                 80

#define GPIO_HIHYS_EN
#define TLMM_GPIO_CFGN_GPIO_HIHYS_EN_BOFFSET        10
#define TLMM_GPIO_CFGN_GPIO_HIHYS_EN_BLEN           1
#define TLMM_GPIO_CFGN_GPIO_HIHYS_EN_FLAG           HSL_RW

#define GPIO_OEA
#define TLMM_GPIO_CFGN_GPIO_OEA_BOFFSET              9
#define TLMM_GPIO_CFGN_GPIO_OEA_BLEN                 1
#define TLMM_GPIO_CFGN_GPIO_OEA_FLAG                 HSL_RW

#define DRV_STRENGTH
#define TLMM_GPIO_CFGN_DRV_STRENGTH_BOFFSET         6
#define TLMM_GPIO_CFGN_DRV_STRENGTH_BLEN            3
#define TLMM_GPIO_CFGN_DRV_STRENGTH_FLAG            HSL_RW

enum QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH {
    QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_2_MA,
    QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_4_MA,
    QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_6_MA,
    QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_8_MA,
    QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_10_MA,
    QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_12_MA,
    QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_14_MA,
    QCA8084_TLMM_GPIO_CFGN_DRV_STRENGTH_16_MA,
};

#define FUNC_SEL
#define TLMM_GPIO_CFGN_FUNC_SEL_BOFFSET             2
#define TLMM_GPIO_CFGN_FUNC_SEL_BLEN                4
#define TLMM_GPIO_CFGN_FUNC_SEL_FLAG                HSL_RW

#define GPIO_PULL
#define TLMM_GPIO_CFGN_GPIO_PULL_BOFFSET            0
#define TLMM_GPIO_CFGN_GPIO_PULL_BLEN               2
#define TLMM_GPIO_CFGN_GPIO_PULL_FLAG               HSL_RW

enum QCA8084_QCA8084_PIN_CONFIG_PARAM {
    QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_DISABLE,   //Disables all pull
    QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_DOWN,
    QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_BUS_HOLD,  //Weak Keepers
    QCA8084_TLMM_GPIO_CFGN_GPIO_PULL_UP,
};


/* TLMM_GPIO_IN_OUTn */
#define TLMM_GPIO_IN_OUTN
#define TLMM_GPIO_IN_OUTN_OFFSET            0xC400004
#define TLMM_GPIO_IN_OUTN_E_LENGTH          4
#define TLMM_GPIO_IN_OUTN_E_OFFSET          0x1000
#define TLMM_GPIO_IN_OUTN_NR_E              80

#define GPIO_OUTE
#define TLMM_GPIO_IN_OUTN_GPIO_OUTE_BOFFSET          1
#define TLMM_GPIO_IN_OUTN_GPIO_OUTE_BLEN             1
#define TLMM_GPIO_IN_OUTN_GPIO_OUTE_FLAG             HSL_RW

#define GPIO_IN
#define TLMM_GPIO_IN_OUTN_GPIO_IN_BOFFSET           0
#define TLMM_GPIO_IN_OUTN_GPIO_IN_BLEN              1
#define TLMM_GPIO_IN_OUTN_GPIO_IN_FLAG              HSL_R

/* TLMM_CLK_GATE_EN */
#define TLMM_CLK_GATE_EN
#define TLMM_CLK_GATE_EN_OFFSET             0xC500000
#define TLMM_CLK_GATE_EN_E_LENGTH           4
#define TLMM_CLK_GATE_EN_E_OFFSET           0
#define TLMM_CLK_GATE_EN_NR_E               1

#define AHB_HCLK_EN
#define TLMM_CLK_GATE_EN_AHB_HCLK_EN_BOFFSET        2
#define TLMM_CLK_GATE_EN_AHB_HCLK_EN_BLEN           1
#define TLMM_CLK_GATE_EN_AHB_HCLK_EN_FLAG           HSL_RW

#define SUMMARY_INTR_EN
#define TLMM_CLK_GATE_EN_SUMMARY_INTR_EN_BOFFSET    1
#define TLMM_CLK_GATE_EN_SUMMARY_INTR_EN_BLEN       1
#define TLMM_CLK_GATE_EN_SUMMARY_INTR_EN_FLAG       HSL_RW

#define CRIF_READ_EN
#define TLMM_CLK_GATE_EN_CRIF_READ_EN_BOFFSET       0
#define TLMM_CLK_GATE_EN_CRIF_READ_EN_BLEN          1
#define TLMM_CLK_GATE_EN_CRIF_READ_EN_FLAG          HSL_RW

/* TLMM_HW_REVISION_NUMBER */
#define TLMM_HW_REVISION_NUMBER
#define TLMM_HW_REVISION_NUMBER_OFFSET      0xC510010
#define TLMM_HW_REVISION_NUMBER_E_LENGTH    4
#define TLMM_HW_REVISION_NUMBER_E_OFFSET    0
#define TLMM_HW_REVISION_NUMBER_NR_E        1

#define VERSION_ID
#define TLMM_HW_REVISION_NUMBER_VERSION_ID_BOFFSET  28
#define TLMM_HW_REVISION_NUMBER_VERSION_ID_BLEN     4
#define TLMM_HW_REVISION_NUMBER_VERSION_ID_FLAG     HSL_R

#define PARTNUM
#define TLMM_HW_REVISION_NUMBER_PARTNUM_BOFFSET     12
#define TLMM_HW_REVISION_NUMBER_PARTNUM_BLEN        16
#define TLMM_HW_REVISION_NUMBER_PARTNUM_FLAG        HSL_R

#define MFG_ID
#define TLMM_HW_REVISION_NUMBER_MFG_ID_BOFFSET      1
#define TLMM_HW_REVISION_NUMBER_MFG_ID_BLEN         11
#define TLMM_HW_REVISION_NUMBER_MFG_ID_FLAG         HSL_R

#define START_BIT
#define TLMM_HW_REVISION_NUMBER_START_BIT_BOFFSET   0
#define TLMM_HW_REVISION_NUMBER_START_BIT_BLEN      1
#define TLMM_HW_REVISION_NUMBER_START_BIT_FLAG      HSL_R


/****************************************************************************
 *
 *  2) PINs Functions Selection  GPIO_CFG[5:2] (FUNC_SEL)
 *
 ****************************************************************************/
/*GPIO*/
#define QCA8084_PIN_FUNC_GPIO0  0
#define QCA8084_PIN_FUNC_GPIO1  0
#define QCA8084_PIN_FUNC_GPIO2  0
#define QCA8084_PIN_FUNC_GPIO3  0
#define QCA8084_PIN_FUNC_GPIO4  0
#define QCA8084_PIN_FUNC_GPIO5  0
#define QCA8084_PIN_FUNC_GPIO6  0
#define QCA8084_PIN_FUNC_GPIO7  0
#define QCA8084_PIN_FUNC_GPIO8  0
#define QCA8084_PIN_FUNC_GPIO9  0
#define QCA8084_PIN_FUNC_GPIO10 0
#define QCA8084_PIN_FUNC_GPIO11 0
#define QCA8084_PIN_FUNC_GPIO12 0
#define QCA8084_PIN_FUNC_GPIO13 0
#define QCA8084_PIN_FUNC_GPIO14 0
#define QCA8084_PIN_FUNC_GPIO15 0
#define QCA8084_PIN_FUNC_GPIO16 0
#define QCA8084_PIN_FUNC_GPIO17 0
#define QCA8084_PIN_FUNC_GPIO18 0
#define QCA8084_PIN_FUNC_GPIO19 0
#define QCA8084_PIN_FUNC_GPIO20 0
#define QCA8084_PIN_FUNC_GPIO21 0

/*MINIMUM CONCURRENCY SET FUNCTION*/
#define QCA8084_PIN_FUNC_INTN_WOL         1
#define QCA8084_PIN_FUNC_INTN             1
#define QCA8084_PIN_FUNC_P0_LED_0         1
#define QCA8084_PIN_FUNC_P1_LED_0         1
#define QCA8084_PIN_FUNC_P2_LED_0         1
#define QCA8084_PIN_FUNC_P3_LED_0         1
#define QCA8084_PIN_FUNC_PPS_IN           1
#define QCA8084_PIN_FUNC_TOD_IN           1
#define QCA8084_PIN_FUNC_RTC_REFCLK_IN    1
#define QCA8084_PIN_FUNC_P0_PPS_OUT       1
#define QCA8084_PIN_FUNC_P1_PPS_OUT       1
#define QCA8084_PIN_FUNC_P2_PPS_OUT       1
#define QCA8084_PIN_FUNC_P3_PPS_OUT       1
#define QCA8084_PIN_FUNC_P0_TOD_OUT       1
#define QCA8084_PIN_FUNC_P0_CLK125_TDI    1
#define QCA8084_PIN_FUNC_P0_SYNC_CLKO_PTP 1
#define QCA8084_PIN_FUNC_P0_LED_1         1
#define QCA8084_PIN_FUNC_P1_LED_1         1
#define QCA8084_PIN_FUNC_P2_LED_1         1
#define QCA8084_PIN_FUNC_P3_LED_1         1
#define QCA8084_PIN_FUNC_MDC_M            1
#define QCA8084_PIN_FUNC_MDO_M            1

/*ALT FUNCTION K*/
#define QCA8084_PIN_FUNC_EVENT_TRG_I        2
#define QCA8084_PIN_FUNC_P0_EVENT_TRG_O     2
#define QCA8084_PIN_FUNC_P1_EVENT_TRG_O     2
#define QCA8084_PIN_FUNC_P2_EVENT_TRG_O     2
#define QCA8084_PIN_FUNC_P3_EVENT_TRG_O     2
#define QCA8084_PIN_FUNC_P1_TOD_OUT         2
#define QCA8084_PIN_FUNC_P1_CLK125_TDI      2
#define QCA8084_PIN_FUNC_P1_SYNC_CLKO_PTP   2
#define QCA8084_PIN_FUNC_P0_INTN_WOL        2
#define QCA8084_PIN_FUNC_P1_INTN_WOL        2
#define QCA8084_PIN_FUNC_P2_INTN_WOL        2
#define QCA8084_PIN_FUNC_P3_INTN_WOL        2

/*ALT FUNCTION L*/
#define QCA8084_PIN_FUNC_P2_TOD_OUT         3
#define QCA8084_PIN_FUNC_P2_CLK125_TDI      3
#define QCA8084_PIN_FUNC_P2_SYNC_CLKO_PTP   3

/*ALT FUNCTION M*/
#define QCA8084_PIN_FUNC_P3_TOD_OUT         4
#define QCA8084_PIN_FUNC_P3_CLK125_TDI      4
#define QCA8084_PIN_FUNC_P3_SYNC_CLKO_PTP   4

/*ALT FUNCTION N*/
#define QCA8084_PIN_FUNC_P0_LED_2           3
#define QCA8084_PIN_FUNC_P1_LED_2           2
#define QCA8084_PIN_FUNC_P2_LED_2           2
#define QCA8084_PIN_FUNC_P3_LED_2           3

/*ALT FUNCTION O*/


/*ALT FUNCTION DEBUG BUS OUT*/
#define QCA8084_PIN_FUNC_DBG_OUT_CLK        2
#define QCA8084_PIN_FUNC_DBG_BUS_OUT0       2
#define QCA8084_PIN_FUNC_DBG_BUS_OUT1       2
#define QCA8084_PIN_FUNC_DBG_BUS_OUT12      2
#define QCA8084_PIN_FUNC_DBG_BUS_OUT13      2
#define QCA8084_PIN_FUNC_DBG_BUS_OUT2       3
#define QCA8084_PIN_FUNC_DBG_BUS_OUT3       4
#define QCA8084_PIN_FUNC_DBG_BUS_OUT4       3
#define QCA8084_PIN_FUNC_DBG_BUS_OUT5       3
#define QCA8084_PIN_FUNC_DBG_BUS_OUT6       3
#define QCA8084_PIN_FUNC_DBG_BUS_OUT7       5
#define QCA8084_PIN_FUNC_DBG_BUS_OUT8       5
#define QCA8084_PIN_FUNC_DBG_BUS_OUT9       5
#define QCA8084_PIN_FUNC_DBG_BUS_OUT10      3
#define QCA8084_PIN_FUNC_DBG_BUS_OUT11      3
#define QCA8084_PIN_FUNC_DBG_BUS_OUT14      2
#define QCA8084_PIN_FUNC_DBG_BUS_OUT15      2


/****************************************************************************
 *
 *  2) PINs Functions Selection  GPIO_CFG[5:2] (FUNC_SEL)
 *
 ****************************************************************************/
struct qca8084_pinctrl_setting_mux {
	u32 pin;
	u32 func;
};

struct qca8084_pinctrl_setting_configs {
	u32 pin;
	u32 num_configs;
	u64 *configs;
};

enum qca8084_pin_config_param {
	QCA8084_PIN_CONFIG_BIAS_BUS_HOLD,
	QCA8084_PIN_CONFIG_BIAS_DISABLE,
	QCA8084_PIN_CONFIG_BIAS_HIGH_IMPEDANCE,
	QCA8084_PIN_CONFIG_BIAS_PULL_DOWN,
	QCA8084_PIN_CONFIG_BIAS_PULL_PIN_DEFAULT,
	QCA8084_PIN_CONFIG_BIAS_PULL_UP,
	QCA8084_PIN_CONFIG_DRIVE_OPEN_DRAIN,
	QCA8084_PIN_CONFIG_DRIVE_OPEN_SOURCE,
	QCA8084_PIN_CONFIG_DRIVE_PUSH_PULL,
	QCA8084_PIN_CONFIG_DRIVE_STRENGTH,
	QCA8084_PIN_CONFIG_DRIVE_STRENGTH_UA,
	QCA8084_PIN_CONFIG_INPUT_DEBOUNCE,
	QCA8084_PIN_CONFIG_INPUT_ENABLE,
	QCA8084_PIN_CONFIG_INPUT_SCHMITT,
	QCA8084_PIN_CONFIG_INPUT_SCHMITT_ENABLE,
	QCA8084_PIN_CONFIG_LOW_POWER_MODE,
	QCA8084_PIN_CONFIG_OUTPUT_ENABLE,
	QCA8084_PIN_CONFIG_OUTPUT,
	QCA8084_PIN_CONFIG_POWER_SOURCE,
	QCA8084_PIN_CONFIG_SLEEP_HARDWARE_STATE,
	QCA8084_PIN_CONFIG_SLEW_RATE,
	QCA8084_PIN_CONFIG_SKEW_DELAY,
	QCA8084_PIN_CONFIG_PERSIST_STATE,
	QCA8084_PIN_CONFIG_END = 0x7F,
	QCA8084_PIN_CONFIG_MAX = 0xFF,
};

enum qca8084_pinctrl_map_type {
	QCA8084_PIN_MAP_TYPE_INVALID,
	QCA8084_PIN_MAP_TYPE_DUMMY_STATE,
	QCA8084_PIN_MAP_TYPE_MUX_GROUP,
	QCA8084_PIN_MAP_TYPE_CONFIGS_PIN,
	QCA8084_PIN_MAP_TYPE_CONFIGS_GROUP,
};

struct qca8084_pinctrl_setting {
	enum qca8084_pinctrl_map_type type;
	union {
		struct qca8084_pinctrl_setting_mux mux;
		struct qca8084_pinctrl_setting_configs configs;
	} data;
};

#define QCA8084_PIN_SETTING_MUX(pin_id, function)		\
	{								\
		.type = QCA8084_PIN_MAP_TYPE_MUX_GROUP,				\
		.data.mux = {						\
			.pin = pin_id,					\
			.func = function				\
		},							\
	}

#define QCA8084_PIN_SETTING_CONFIG(pin_id, cfgs)		\
	{								\
		.type = QCA8084_PIN_MAP_TYPE_CONFIGS_PIN,				\
		.data.configs = {						\
			.pin = pin_id,					\
			.configs = cfgs,				\
			.num_configs = ARRAY_SIZE(cfgs)				\
		},							\
	}

int qca8084_gpio_set_bit( u32 pin, u32 value);
int qca8084_gpio_get_bit( u32 pin, u32 *data);
int qca8084_gpio_pin_mux_set( u32 pin, u32 func);
int qca8084_gpio_pin_cfg_set_bias( u32 pin, u32 bias);
int qca8084_gpio_pin_cfg_get_bias( u32 pin, u32 *bias);
int qca8084_gpio_pin_cfg_set_drvs( u32 pin, u32 drvs);
int qca8084_gpio_pin_cfg_get_drvs( u32 pin, u32 *drvs);
int qca8084_gpio_pin_cfg_set_oe( u32 pin, bool oe);
int qca8084_gpio_pin_cfg_get_oe( u32 pin, bool *oe);
int ipq_qca8084_pinctrl_init(void);


#ifdef __cplusplus
}
#endif                          /* __cplusplus */

#endif                          /* _QCA8084_PHY_H_ */
