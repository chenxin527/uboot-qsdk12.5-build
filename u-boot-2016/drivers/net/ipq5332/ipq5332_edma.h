/*
 **************************************************************************
 * Copyright (c) 2016-2019, 2021, The Linux Foundation. All rights reserved.
 *
 * Copyright (c) 2022, Qualcomm Innovation Center, Inc. All rights reserved.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 **************************************************************************
*/
#ifndef __IPQ5332_EDMA__
#define __IPQ5332_EDMA__

#define IPQ5332_NSS_DP_START_PHY_PORT   1
#define IPQ5332_NSS_DP_MAX_PHY_PORTS    2

#define IPQ5332_EDMA_DEVICE_NODE_NAME	"edma"

/* Number of descriptors in each ring is defined with below macro */
#define IPQ5332_EDMA_TX_RING_SIZE	128
#define IPQ5332_EDMA_RX_RING_SIZE	128

/* Number of byte in a descriptor is defined with below macros for each of
 * the rings respectively */
#define IPQ5332_EDMA_TXDESC_DESC_SIZE	(sizeof(struct ipq5332_edma_txdesc_desc))
#define IPQ5332_EDMA_TXCMPL_DESC_SIZE	(sizeof(struct ipq5332_edma_txcmpl_desc))
#define IPQ5332_EDMA_RXDESC_DESC_SIZE	(sizeof(struct ipq5332_edma_rxdesc_desc))
#define IPQ5332_EDMA_RXFILL_DESC_SIZE	(sizeof(struct ipq5332_edma_rxfill_desc))
#define IPQ5332_EDMA_RX_SEC_DESC_SIZE	(sizeof(struct ipq5332_edma_rx_sec_desc))
#define IPQ5332_EDMA_TX_SEC_DESC_SIZE	(sizeof(struct ipq5332_edma_tx_sec_desc))

#define IPQ5332_EDMA_START_GMACS	IPQ5332_NSS_DP_START_PHY_PORT
#define IPQ5332_EDMA_MAX_GMACS		IPQ5332_NSS_DP_MAX_PHY_PORTS

#define IPQ5332_EDMA_TX_BUFF_SIZE	2048
#define IPQ5332_EDMA_RX_BUFF_SIZE	2048

/* Max number of rings of each type is defined with below macro */
#define IPQ5332_EDMA_MAX_TXCMPL_RINGS	24	/* Max TxCmpl rings */
#define IPQ5332_EDMA_MAX_TXDESC_RINGS	24	/* Max TxDesc rings */
#define IPQ5332_EDMA_MAX_RXDESC_RINGS	16	/* Max RxDesc rings */
#define IPQ5332_EDMA_MAX_RXFILL_RINGS	8	/* Max RxFill rings */

#define IPQ5332_EDMA_GET_DESC(R, i, type) (&(((type *)((R)->desc))[i]))
#define IPQ5332_EDMA_RXFILL_DESC(R, i) 	IPQ5332_EDMA_GET_DESC(R, i, struct ipq5332_edma_rxfill_desc)
#define IPQ5332_EDMA_RXDESC_DESC(R, i) 	IPQ5332_EDMA_GET_DESC(R, i, struct ipq5332_edma_rxdesc_desc)
#define IPQ5332_EDMA_TXDESC_DESC(R, i) 	IPQ5332_EDMA_GET_DESC(R, i, struct ipq5332_edma_txdesc_desc)
#define IPQ5332_EDMA_TXCMPL_DESC(R, i) 	IPQ5332_EDMA_GET_DESC(R, i, struct ipq5332_edma_txcmpl_desc)

#define IPQ5332_EDMA_DEV		1

/* Only 1 ring of each type will be used in U-Boot which is defined with
 * below macros */
#define IPQ5332_EDMA_TX_DESC_RING_START	23
#define IPQ5332_EDMA_TX_DESC_RING_NOS	1
#define IPQ5332_EDMA_TX_DESC_RING_SIZE	\
(IPQ5332_EDMA_TX_DESC_RING_START + IPQ5332_EDMA_TX_DESC_RING_NOS)

#define IPQ5332_EDMA_TX_CMPL_RING_START	23
#define IPQ5332_EDMA_TX_CMPL_RING_NOS	1
#define IPQ5332_EDMA_TX_CMPL_RING_SIZE	\
(IPQ5332_EDMA_TX_CMPL_RING_START + IPQ5332_EDMA_TX_CMPL_RING_NOS)

#define IPQ5332_EDMA_RX_DESC_RING_START	15
#define IPQ5332_EDMA_RX_DESC_RING_NOS	1
#define IPQ5332_EDMA_RX_DESC_RING_SIZE	\
(IPQ5332_EDMA_RX_DESC_RING_START + IPQ5332_EDMA_RX_DESC_RING_NOS)

#define IPQ5332_EDMA_RX_FILL_RING_START	7
#define IPQ5332_EDMA_RX_FILL_RING_NOS	1
#define IPQ5332_EDMA_RX_FILL_RING_SIZE	\
(IPQ5332_EDMA_RX_FILL_RING_START + IPQ5332_EDMA_RX_FILL_RING_NOS)

#define NETDEV_TX_BUSY	1

/*
 * RxDesc descriptor
 */
struct ipq5332_edma_rxdesc_desc {
	uint32_t rdes0; /* Contains buffer address */
	uint32_t rdes1; /* Contains more bit, priority bit, service code */
	uint32_t rdes2; /* Contains opaque */
	uint32_t rdes3; /* Contains opaque high bits */
	uint32_t rdes4; /* Contains destination and source information */
	uint32_t rdes5; /* Contains WiFi QoS, data length */
	uint32_t rdes6; /* Contains hash value, check sum status */
	uint32_t rdes7; /* Contains DSCP, packet offsets */
};

/*
 * EDMA Rx Secondary Descriptor
 */
struct ipq5332_edma_rx_sec_desc {
	uint32_t rx_sec0; /* Contains timestamp */
	uint32_t rx_sec1; /* Contains secondary checksum status */
	uint32_t rx_sec2; /* Contains QoS tag */
	uint32_t rx_sec3; /* Contains flow index details */
	uint32_t rx_sec4; /* Contains secondary packet offsets */
	uint32_t rx_sec5; /* Contains multicast bit, checksum */
	uint32_t rx_sec6; /* Contains SVLAN, CVLAN */
	uint32_t rx_sec7; /* Contains secondary SVLAN, CVLAN */
};

/*
 * RxFill descriptor
 */
struct ipq5332_edma_rxfill_desc {
	uint32_t rdes0; /* Contains buffer address */
	uint32_t rdes1; /* Contains buffer size */
	uint32_t rdes2; /* Contains opaque */
	uint32_t rdes3; /* Contains opaque high bits */
};

/*
 * TxDesc descriptor
 */
struct ipq5332_edma_txdesc_desc {
	uint32_t tdes0; /* Low 32-bit of buffer address */
	uint32_t tdes1; /* Buffer recycling, PTP tag flag, PRI valid flag */
	uint32_t tdes2; /* Low 32-bit of opaque value */
	uint32_t tdes3; /* High 32-bit of opaque value */
	uint32_t tdes4; /* Source/Destination port info */
	uint32_t tdes5; /* VLAN offload, csum_mode, ip_csum_en, tso_en, data length */
	uint32_t tdes6; /* MSS/hash_value/PTP tag, data offset */
	uint32_t tdes7; /* L4/L3 offset, PROT type, L2 type, CVLAN/SVLAN tag, service code */
};

/*
 * EDMA Tx Secondary Descriptor
 */
struct ipq5332_edma_tx_sec_desc {
	uint32_t tx_sec0; /* Reserved */
	uint32_t tx_sec1; /* Custom csum offset, payload offset, TTL/NAT action */
	uint32_t rx_sec2; /* NAPT translated port, DSCP value, TTL value */
	uint32_t rx_sec3; /* Flow index value and valid flag */
	uint32_t rx_sec4; /* Reserved */
	uint32_t rx_sec5; /* Reserved */
	uint32_t rx_sec6; /* CVLAN/SVLAN command */
	uint32_t rx_sec7; /* CVLAN/SVLAN tag value */
};

/*
 * TxCmpl descriptor
 */
struct ipq5332_edma_txcmpl_desc {
	uint32_t tdes0; /* Low 32-bit opaque value */
	uint32_t tdes1; /* High 32-bit opaque value */
	uint32_t tdes2; /* More fragment, transmit ring id, pool id */
	uint32_t tdes3; /* Error indications */
};

/*
 * Tx descriptor ring
 */
struct ipq5332_edma_txdesc_ring {
	uint32_t prod_idx;		/* Producer index */
	uint32_t avail_desc;		/* Number of available descriptor to process */
	uint32_t id;			/* TXDESC ring number */
	struct ipq5332_edma_txdesc_desc *desc;	/* descriptor ring virtual address */
	dma_addr_t dma;			/* descriptor ring physical address */
	struct ipq5332_edma_tx_sec_desc *sdesc; /* Secondary descriptor ring virtual addr */
	dma_addr_t sdma;		/* Secondary descriptor ring physical address */
	uint16_t count;			/* number of descriptors */
};

/*
 * TxCmpl ring
 */
struct ipq5332_edma_txcmpl_ring {
	uint32_t cons_idx;		/* Consumer index */
	uint32_t avail_pkt;		/* Number of available packets to process */
	struct ipq5332_edma_txcmpl_desc *desc; /* descriptor ring virtual address */
	uint32_t id;			/* TXCMPL ring number */
	dma_addr_t dma;			/* descriptor ring physical address */
	uint32_t count;			/* Number of descriptors in the ring */
};

/*
 * RxFill ring
 */
struct ipq5332_edma_rxfill_ring {
	uint32_t id;			/* RXFILL ring number */
	uint32_t count;			/* number of descriptors in the ring */
	uint32_t prod_idx;		/* Ring producer index */
	struct ipq5332_edma_rxfill_desc *desc;  /* descriptor ring virtual address */
	dma_addr_t dma;			/* descriptor ring physical address */
};

/*
 * RxDesc ring
 */
struct ipq5332_edma_rxdesc_ring {
	uint32_t id;			/* RXDESC ring number */
	uint32_t count;			/* number of descriptors in the ring */
	uint32_t cons_idx;		/* Ring consumer index */
	struct ipq5332_edma_rxdesc_desc *desc; /* Primary descriptor ring virtual addr */
	struct ipq5332_edma_sec_rxdesc_ring *sdesc; /* Secondary desc ring VA */
	struct ipq5332_edma_rxfill_ring *rxfill;	/* RXFILL ring used */
	dma_addr_t dma;			/* Primary descriptor ring physical address */
	dma_addr_t sdma;		/* Secondary descriptor ring physical address */
};

enum ipq5332_edma_tx {
	EDMA_TX_OK = 0,		/* Tx success */
	EDMA_TX_DESC = 1,	/* Not enough descriptors */
	EDMA_TX_FAIL = 2,	/* Tx failure */
};


/* per core queue related information */
struct queue_per_cpu_info {
	u32 tx_mask; /* tx interrupt mask */
	u32 rx_mask; /* rx interrupt mask */
	u32 tx_status; /* tx interrupt status */
	u32 rx_status; /* rx interrupt status */
	u32 tx_start; /* tx queue start */
	u32 rx_start; /* rx queue start */
	struct ipq5332_edma_common_info *c_info; /* edma common info */
};

/* edma hw specific data */
struct ipq5332_edma_hw {
	unsigned long  __iomem *hw_addr; /* inner register address */
	u8 intr_clear_type; /* interrupt clear */
	u8 intr_sw_idx_w; /* To do chk type interrupt software index */
	u16 rx_buff_size; /* To do chk type Rx buffer size */
	u8 rss_type; /* rss protocol type */
	uint16_t rx_payload_offset; /* start of the payload offset */
	uint32_t flags; /* internal flags */
	int active; /* status */
	struct ipq5332_edma_txdesc_ring *txdesc_ring; /* Tx Descriptor Ring, SW is producer */
	struct ipq5332_edma_txcmpl_ring *txcmpl_ring; /* Tx Completion Ring, SW is consumer */
	struct ipq5332_edma_rxdesc_ring *rxdesc_ring; /* Rx Descriptor Ring, SW is consumer */
	struct ipq5332_edma_rxfill_ring *rxfill_ring; /* Rx Fill Ring, SW is producer */
	uint32_t txdesc_rings; /* Number of TxDesc rings */
	uint32_t txdesc_ring_start; /* Id of first TXDESC ring */
	uint32_t txdesc_ring_end; /* Id of the last TXDESC ring */
	uint32_t txcmpl_rings; /* Number of TxCmpl rings */
	uint32_t txcmpl_ring_start; /* Id of first TXCMPL ring */
	uint32_t txcmpl_ring_end; /* Id of last TXCMPL ring */
	uint32_t rxfill_rings; /* Number of RxFill rings */
	uint32_t rxfill_ring_start; /* Id of first RxFill ring */
	uint32_t rxfill_ring_end; /* Id of last RxFill ring */
	uint32_t rxdesc_rings; /* Number of RxDesc rings */
	uint32_t rxdesc_ring_start; /* Id of first RxDesc ring */
	uint32_t rxdesc_ring_end; /* Id of last RxDesc ring */
	uint32_t tx_intr_mask; /* tx interrupt mask */
	uint32_t rx_intr_mask; /* rx interrupt mask */
	uint32_t rxfill_intr_mask; /* Rx fill ring interrupt mask */
	uint32_t rxdesc_intr_mask; /* Rx Desc ring interrupt mask */
	uint32_t txcmpl_intr_mask; /* Tx Cmpl ring interrupt mask */
	uint32_t misc_intr_mask; /* misc interrupt interrupt mask */
};

struct ipq5332_edma_common_info {
	struct ipq5332_edma_hw hw;
};

#define MAX_PHY 6
struct ipq5332_eth_dev {
	u8 *phy_address;
	uint no_of_phys;
	uint interface;
	uint speed;
	uint duplex;
	uint sw_configured;
	uint mac_unit;
	uint mac_ps;
	int link_printed;
	u32 padding;
	struct eth_device *dev;
	struct ipq5332_edma_common_info *c_info;
	struct phy_ops *ops[MAX_PHY];
	const char phy_name[MDIO_NAME_LEN];
} __attribute__ ((aligned(8)));

static inline void* ipq5332_alloc_mem(u32 size)
{
	void *p = malloc(size);
	if (p != NULL)
		memset(p, 0, size);
	return p;
}

static inline void* ipq5332_alloc_memalign(u32 size)
{
	void *p = memalign(CONFIG_SYS_CACHELINE_SIZE, size);
	if (p != NULL)
		memset(p, 0, size);
	return p;
}

static inline void ipq5332_free_mem(void *ptr)
{
	if (ptr)
		free(ptr);
}

uint32_t ipq5332_edma_reg_read(uint32_t reg_off);
void ipq5332_edma_reg_write(uint32_t reg_off, uint32_t val);


extern int get_eth_mac_address(uchar *enetaddr, uint no_of_macs);

typedef struct {
	uint count;
	u8 addr[7];
} ipq5332_edma_phy_addr_t;

/* ipq5332 edma Paramaters */
typedef struct {
	uint base;
	int unit;
	uint mac_conn_to_phy;
	phy_interface_t phy;
	ipq5332_edma_phy_addr_t phy_addr;
	char phy_name[MDIO_NAME_LEN];
} ipq5332_edma_board_cfg_t;

extern void ipq5332_ppe_provision_init(void);
extern void ipq5332_port_mac_clock_reset(int port);
extern void ipq5332_speed_clock_set(int port, int clk[4]);
extern void ipq5332_pqsgmii_speed_set(int port, int speed, int status);
extern void ipq5332_uxsgmii_speed_set(int port, int speed, int duplex, int status);
extern void ppe_port_mux_mac_type_set(int port_id, int mode);
extern void ppe_port_bridge_txmac_set(int port, int status);
extern void ipq5332_10g_r_speed_set(int port, int status);
extern int phy_status_get_from_ppe(int port_id);

extern void ipq5332_ppe_acl_set(int rule_id, int rule_type, int pkt_type, int l4_port_no, int l4_port_mask, int permit, int deny);
extern void ppe_uniphy_mode_set(uint32_t uniphy_index, uint32_t mode);
#endif /* ___IPQ5332_EDMA__ */
