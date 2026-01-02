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
#include <asm/addrspace.h>
#include <atheros.h>

#define ATH_MAX_DDR_SIZE		(256 * 1024 * 1024)
#define ATH_DDR_SIZE_INCR		(4 * 1024 * 1024)

int
ath_ddr_find_size(void)
{
	uint8_t  *p = (uint8_t *)KSEG1, pat = 0x77;
	int i;

#define max_i		(ATH_MAX_DDR_SIZE / ATH_DDR_SIZE_INCR)

	*p = pat;

	/*
	 * DDR wraps around. Write a pattern to 0x0000_0000. Write an
	 * address pattern at 4M, 8M, 16M etc. and check when
	 * 0x0000_0000 gets overwritten.
	 */
	for(i = 1; (i < max_i); i++) {
		*(p + i * ATH_DDR_SIZE_INCR) = (uint8_t)(i);
		if (*p != pat) {
			break;
		}
	}

	return ((i < max_i) ? (i * ATH_DDR_SIZE_INCR) : ATH_MAX_DDR_SIZE);
}

inline int
ath_ram_type(uint32_t bs)
{
	if (RST_BOOTSTRAP_DDR_SELECT_GET(bs)) {
		return ATH_MEM_DDR1;
	} else {
		return ATH_MEM_DDR2;
	}
}

/* Notice the value CFG_DDR2_DRAGONFLY_CAS_LATENCY
 * Should Sync with CFG_PLL_FREQ
 * */
#ifndef CFG_DDR2_DRAGONFLY_CAS_LATENCY
#define CFG_DDR2_DRAGONFLY_CAS_LATENCY	4
#endif

#ifdef CONFIG_TB614
#	define DDR_CONFIG2_SWAP_A26_A27_VAL	(0x1)
#else
#	define DDR_CONFIG2_SWAP_A26_A27_VAL	(0x0)
#endif

#if CFG_DDR2_DRAGONFLY_CAS_LATENCY == 3

#define CFG_DDR2_CONFIG_VAL			DDR_CONFIG_CAS_LATENCY_MSB_SET(0x0) | \
						DDR_CONFIG_OPEN_PAGE_SET(0x1) | \
						DDR_CONFIG_CAS_LATENCY_SET(0x7) | \
						DDR_CONFIG_TMRD_SET(0x6) | \
						DDR_CONFIG_TRFC_SET(0x10) | \
						DDR_CONFIG_TRRD_SET(0x5) | \
						DDR_CONFIG_TRP_SET(0x8) | \
						DDR_CONFIG_TRCD_SET(0x8) | \
						DDR_CONFIG_TRAS_SET(0x17)

#define CFG_DDR2_CONFIG2_VAL			DDR_CONFIG2_HALF_WIDTH_LOW_SET(0x1) | \
						DDR_CONFIG2_SWAP_A26_A27_SET(DDR_CONFIG2_SWAP_A26_A27_VAL) | \
						DDR_CONFIG2_GATE_OPEN_LATENCY_SET(0x6) | \
						DDR_CONFIG2_TWTR_SET(0x12) | \
						DDR_CONFIG2_TRTP_SET(0xa) | \
						DDR_CONFIG2_TRTW_SET(0xe) | \
						DDR_CONFIG2_TWR_SET(0xf) | \
						DDR_CONFIG2_CKE_SET(0x1) | \
						DDR_CONFIG2_CNTL_OE_EN_SET(0x1) | \
						DDR_CONFIG2_BURST_LENGTH_SET(0x8)

#define CFG_DDR2_CONFIG3_VAL			0x00000002
#define CFG_DDR2_EXT_MODE_VAL1			0x782
#define CFG_DDR2_EXT_MODE_VAL2			0x402
#define CFG_DDR2_MODE_VAL_INIT			0x733
#define CFG_DDR2_MODE_VAL			0x633
#define CFG_DDR2_TAP_VAL			0x10
#define CFG_DDR2_EN_TWL_VAL			0x00000e65
#define CFG_DDR2_RD_DATA_THIS_CYCLE_VAL_16	0xffff
#define CFG_DDR2_RD_DATA_THIS_CYCLE_VAL_32	0xff

#elif CFG_DDR2_DRAGONFLY_CAS_LATENCY == 4

#define CFG_DDR2_CONFIG_VAL			DDR_CONFIG_CAS_LATENCY_MSB_SET(0x1) | \
						DDR_CONFIG_OPEN_PAGE_SET(0x1) | \
						DDR_CONFIG_CAS_LATENCY_SET(0x1) | \
						DDR_CONFIG_TMRD_SET(0x6) | \
						DDR_CONFIG_TRFC_SET(0x11) | \
						DDR_CONFIG_TRRD_SET(0x6) | \
						DDR_CONFIG_TRP_SET(0x8) | \
						DDR_CONFIG_TRCD_SET(0x8) | \
						DDR_CONFIG_TRAS_SET(0x18)

#define CFG_DDR2_CONFIG2_VAL			DDR_CONFIG2_HALF_WIDTH_LOW_SET(0x1) | \
						DDR_CONFIG2_SWAP_A26_A27_SET(DDR_CONFIG2_SWAP_A26_A27_VAL) | \
						DDR_CONFIG2_GATE_OPEN_LATENCY_SET(0x8) | \
						DDR_CONFIG2_TWTR_SET(0x12) | \
						DDR_CONFIG2_TRTP_SET(0xa) | \
						DDR_CONFIG2_TRTW_SET(0xe) | \
						DDR_CONFIG2_TWR_SET(0xf) | \
						DDR_CONFIG2_CKE_SET(0x1) | \
						DDR_CONFIG2_CNTL_OE_EN_SET(0x1) | \
						DDR_CONFIG2_BURST_LENGTH_SET(0x8)

#define CFG_DDR2_CONFIG3_VAL			0x0000000a
#define CFG_DDR2_EXT_MODE_VAL1			0x782
#define CFG_DDR2_EXT_MODE_VAL2			0x402
#define CFG_DDR2_MODE_VAL_INIT			0x743
#define CFG_DDR2_MODE_VAL			0x643
#define CFG_DDR2_TAP_VAL			0x10
#define CFG_DDR2_EN_TWL_VAL			0x0000166d
#define CFG_DDR2_RD_DATA_THIS_CYCLE_VAL_16	0xffff
#define CFG_DDR2_RD_DATA_THIS_CYCLE_VAL_32	0xff

#elif CFG_DDR2_DRAGONFLY_CAS_LATENCY == 5

#define CFG_DDR2_CONFIG_VAL			DDR_CONFIG_CAS_LATENCY_MSB_SET(0x1) | \
						DDR_CONFIG_OPEN_PAGE_SET(0x1) | \
						DDR_CONFIG_CAS_LATENCY_SET(0x4) | \
						DDR_CONFIG_TMRD_SET(0x6) | \
						DDR_CONFIG_TRFC_SET(0x16) | \
						DDR_CONFIG_TRRD_SET(0x7) | \
						DDR_CONFIG_TRP_SET(0xb) | \
						DDR_CONFIG_TRCD_SET(0xb) | \
						DDR_CONFIG_TRAS_SET(0)

#define CFG_DDR2_CONFIG2_VAL			DDR_CONFIG2_HALF_WIDTH_LOW_SET(0x1) | \
						DDR_CONFIG2_SWAP_A26_A27_SET(DDR_CONFIG2_SWAP_A26_A27_VAL) | \
						DDR_CONFIG2_GATE_OPEN_LATENCY_SET(0xa) | \
						DDR_CONFIG2_TWTR_SET(0x16) | \
						DDR_CONFIG2_TRTP_SET(0xa) | \
						DDR_CONFIG2_TRTW_SET(0xe) | \
						DDR_CONFIG2_TWR_SET(0x2) | \
						DDR_CONFIG2_CKE_SET(0x1) | \
						DDR_CONFIG2_CNTL_OE_EN_SET(0x1) | \
						DDR_CONFIG2_BURST_LENGTH_SET(0x8)


#define CFG_DDR2_CONFIG3_VAL            0x0000000e
#define CFG_DDR2_EXT_MODE_VAL1			0x782
#define CFG_DDR2_EXT_MODE_VAL2          0x402
#define CFG_DDR2_MODE_VAL_INIT          0xb53
#define CFG_DDR2_MODE_VAL               0xa53
#define CFG_DDR2_TAP_VAL                0x10
#define CFG_DDR2_EN_TWL_VAL             0x00001e91
#define CFG_DDR2_RD_DATA_THIS_CYCLE_VAL_16	0xffff
#define CFG_DDR2_RD_DATA_THIS_CYCLE_VAL_32	0xff

#elif CFG_DDR2_DRAGONFLY_CAS_LATENCY == 6

#define CFG_DDR2_CONFIG_VAL			DDR_CONFIG_CAS_LATENCY_MSB_SET(0x1) | \
						DDR_CONFIG_OPEN_PAGE_SET(0x1) | \
						DDR_CONFIG_CAS_LATENCY_SET(0x6) | \
						DDR_CONFIG_TMRD_SET(0x6) | \
						DDR_CONFIG_TRFC_SET(0x16) | \
						DDR_CONFIG_TRRD_SET(0x7) | \
						DDR_CONFIG_TRP_SET(0xb) | \
						DDR_CONFIG_TRCD_SET(0xb) | \
						DDR_CONFIG_TRAS_SET(0)

#define CFG_DDR2_CONFIG2_VAL			DDR_CONFIG2_HALF_WIDTH_LOW_SET(0x1) | \
						DDR_CONFIG2_SWAP_A26_A27_SET(DDR_CONFIG2_SWAP_A26_A27_VAL) | \
						DDR_CONFIG2_GATE_OPEN_LATENCY_SET(0xc) | \
						DDR_CONFIG2_TWTR_SET(0x18) | \
						DDR_CONFIG2_TRTP_SET(0xa) | \
						DDR_CONFIG2_TRTW_SET(0xe) | \
						DDR_CONFIG2_TWR_SET(0x2) | \
						DDR_CONFIG2_CKE_SET(0x1) | \
						DDR_CONFIG2_CNTL_OE_EN_SET(0x1) | \
						DDR_CONFIG2_BURST_LENGTH_SET(0x8)


#define CFG_DDR2_CONFIG3_VAL            0x0000000e
#define CFG_DDR2_EXT_MODE_VAL1		    0x782
#define CFG_DDR2_EXT_MODE_VAL2          0x402
#define CFG_DDR2_MODE_VAL_INIT          0xb63
#define CFG_DDR2_MODE_VAL               0xa63
#define CFG_DDR2_TAP_VAL                0x10
#define CFG_DDR2_EN_TWL_VAL             0x00002691
#define CFG_DDR2_RD_DATA_THIS_CYCLE_VAL_16	0xffff
#define CFG_DDR2_RD_DATA_THIS_CYCLE_VAL_32	0xff

#endif

/* CAL = 3 FOR DDR */
#define CFG_DDR1_CONFIG_VAL			DDR_CONFIG_OPEN_PAGE_SET(0x1) | \
						DDR_CONFIG_CAS_LATENCY_SET(0x7) | \
						DDR_CONFIG_TMRD_SET(0x6) | \
						DDR_CONFIG_TRFC_SET(0x9) | \
						DDR_CONFIG_TRRD_SET(0x5) | \
						DDR_CONFIG_TRP_SET(0x8) | \
						DDR_CONFIG_TRCD_SET(0x8) | \
						DDR_CONFIG_TRAS_SET(0x15)


#define CFG_DDR1_CONFIG2_VAL			DDR_CONFIG2_HALF_WIDTH_LOW_SET(0x1) | \
						DDR_CONFIG2_GATE_OPEN_LATENCY_SET(0x6) | \
						DDR_CONFIG2_TWTR_SET(0x10) | \
						DDR_CONFIG2_TRTP_SET(0xa) | \
						DDR_CONFIG2_TRTW_SET(0x10) | \
						DDR_CONFIG2_TWR_SET(0xf) | \
						DDR_CONFIG2_CKE_SET(0x1) | \
						DDR_CONFIG2_CNTL_OE_EN_SET(0x1) | \
						DDR_CONFIG2_BURST_LENGTH_SET(0x8)
#define CFG_DDR1_CONFIG3_VAL			0x0
#define CFG_DDR1_EXT_MODE_VAL			0x2
#define CFG_DDR1_MODE_VAL_INIT			0x133
#define CFG_DDR1_MODE_VAL			0x33
#define CFG_DDR1_RD_DATA_THIS_CYCLE_VAL_16	0xffff
#define CFG_DDR1_RD_DATA_THIS_CYCLE_VAL_32	0xff
#define CFG_DDR1_TAP_VAL			0x10
#define CFG_DDR1_EN_TWL_VAL			0x00000664

#define CFG_DDR_CTL_CONFIG			DDR_CTL_CONFIG_SRAM_TSEL_SET(0x1) | \
						DDR_CTL_CONFIG_GE0_SRAM_SYNC_SET(0x1) | \
						DDR_CTL_CONFIG_GE1_SRAM_SYNC_SET(0x1) | \
						DDR_CTL_CONFIG_USB_SRAM_SYNC_SET(0x1) | \
						DDR_CTL_CONFIG_PCIE_SRAM_SYNC_SET(0x1) | \
						DDR_CTL_CONFIG_WMAC_SRAM_SYNC_SET(0x1) | \
						DDR_CTL_CONFIG_MISC_SRC1_SRAM_SYNC_SET(0x1) | \
						DDR_CTL_CONFIG_MISC_SRC2_SRAM_SYNC_SET(0x1)

int /* ram type */
ath_ddr_initial_config(uint32_t refresh)
{
#if !defined(CONFIG_ATH_NAND_BR) && !defined(CONFIG_ATH_EMULATION)
	int ddr_config, ddr_config2, ddr_config3, ext_mod, mod_val,
			mod_val_init, cycle_val, tap_val, type, ctl_config;
	uint32_t *pll_config = (unsigned *)PLL_CONFIG_VAL_F;
	uint32_t bootstrap;

#if !defined(CONFIG_DISPLAY_BOARDINFO)
	prmsg("\nsri\n");
#endif

	bootstrap = ath_reg_rd(RST_BOOTSTRAP_ADDRESS);

	switch(type = ath_ram_type(bootstrap)) {
	case ATH_MEM_DDR2:
		ddr_config	= CFG_DDR2_CONFIG_VAL;
		ddr_config2	= CFG_DDR2_CONFIG2_VAL;
		ddr_config3	= CFG_DDR2_CONFIG3_VAL;
		ext_mod		= CFG_DDR2_EXT_MODE_VAL2;
		mod_val_init	= CFG_DDR2_MODE_VAL_INIT;
		mod_val		= CFG_DDR2_MODE_VAL;
		tap_val		= CFG_DDR2_TAP_VAL;

		ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x10);
		udelay(10);
		ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x20);
		udelay(10);
		prmsg("%s(%d): (", __func__, __LINE__);

        ctl_config =	CFG_DDR_CTL_CONFIG |
					DDR_CTL_CONFIG_PAD_DDR2_SEL_SET(0x1) |
					DDR_CTL_CONFIG_HALF_WIDTH_SET(0x1);

        cycle_val = CFG_DDR2_RD_DATA_THIS_CYCLE_VAL_16;


		ctl_config |= CPU_DDR_SYNC_MODE;

		ath_reg_wr_nf(DDR_CTL_CONFIG_ADDRESS, ctl_config);

		prmsg("ddr2 init)\n");
		udelay(10);
		break;
	case ATH_MEM_DDR1:
		ddr_config	= CFG_DDR1_CONFIG_VAL;
		ddr_config2	= CFG_DDR1_CONFIG2_VAL;
		ddr_config3	= CFG_DDR1_CONFIG3_VAL;
		ext_mod		= CFG_DDR1_EXT_MODE_VAL;
		mod_val_init	= CFG_DDR1_MODE_VAL_INIT;
		mod_val		= CFG_DDR1_MODE_VAL;
		tap_val		= CFG_DDR1_TAP_VAL;

		prmsg("%s(%d): (", __func__, __LINE__);
        cycle_val = CFG_DDR1_RD_DATA_THIS_CYCLE_VAL_16;
        ctl_config = CFG_DDR_CTL_CONFIG |
                         DDR_CTL_CONFIG_HALF_WIDTH_SET(0x1);

		ctl_config |= CPU_DDR_SYNC_MODE;

		ath_reg_wr_nf(DDR_CTL_CONFIG_ADDRESS, ctl_config);
		udelay(10);
		prmsg("ddr1 init)\n");

		break;
	}
#if 0
	if (*pll_config == PLL_MAGIC) {
		uint32_t cas = pll_config[5];
		if (cas == 3 || cas == 4) {
			cas = (cas * 2) + 2;
			ddr_config &= ~(DDR_CONFIG_CAS_LATENCY_MSB_MASK |
					DDR_CONFIG_CAS_LATENCY_MASK);
			ddr_config |= DDR_CONFIG_CAS_LATENCY_SET(cas & 0x7) |
				DDR_CONFIG_CAS_LATENCY_MSB_SET((cas >> 3) & 1);

			cas = pll_config[5];

			ddr_config2 &= ~DDR_CONFIG2_GATE_OPEN_LATENCY_MASK;
			ddr_config2 |= DDR_CONFIG2_GATE_OPEN_LATENCY_SET((2 * cas) + 1);

			if (type == ATH_MEM_DDR2) {
				uint32_t tmp;
				tmp = ath_reg_rd(DDR2_CONFIG_ADDRESS);
				tmp &= ~DDR2_CONFIG_DDR2_TWL_MASK;
				tmp |= DDR2_CONFIG_DDR2_TWL_SET(cas == 3 ? 3 : 5);
				ath_reg_wr_nf(DDR2_CONFIG_ADDRESS, tmp);
			}

			mod_val = (cas == 3 ? 0x33 : 0x43);
			mod_val_init = 0x100 | mod_val;
		}
	}
#endif

	ath_reg_wr_nf(DDR_RD_DATA_THIS_CYCLE_ADDRESS, cycle_val);
	udelay(100);
	ath_reg_wr_nf(DDR_BURST_ADDRESS, 0x74444444);
	udelay(100);
	ath_reg_wr_nf(DDR_BURST2_ADDRESS, 0x44444444);
	udelay(100);
	ath_reg_wr_nf(DDR_FSM_WAIT_CTRL_ADDRESS, DDR_FSM_WAIT_CTRL_VAL);
	udelay(100);
	ath_reg_wr_nf(DDR_AHB_MASTER_TIMEOUT_MAX_ADDRESS, 0xfffff);
	udelay(100);
	ath_reg_wr_nf(DDR_CONFIG_ADDRESS, ddr_config);
	udelay(100);
	ath_reg_wr_nf(DDR_CONFIG2_ADDRESS, ddr_config2);
	udelay(100);
	ath_reg_wr(DDR_CONFIG_3_ADDRESS, ddr_config3);
	udelay(100);

	if (type == ATH_MEM_DDR2) {
		ath_reg_wr_nf(DDR2_CONFIG_ADDRESS, CFG_DDR2_EN_TWL_VAL);
		udelay(100);
	}
	if (type == ATH_MEM_DDR1) {
		ath_reg_wr_nf(DDR2_CONFIG_ADDRESS, CFG_DDR1_EN_TWL_VAL);
		udelay(100);
	}

	ath_reg_wr_nf(DDR_CONFIG2_ADDRESS, ddr_config2 | 0x80);	// CKE Enable
	udelay(100);

	ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x8);	// Precharge
	udelay(10);

	if (type == ATH_MEM_DDR2) {
		ath_reg_wr_nf(DDR_EMR2_ADDRESS, 0);
		ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x10);	// EMR2
		udelay(10);
		ath_reg_wr_nf(DDR_EMR3_ADDRESS, 0);
		ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x20);	// EMR3
		udelay(10);
	}

	if (type == ATH_MEM_DDR1 || type == ATH_MEM_DDR2) {
		ath_reg_wr_nf(DDR_EXTENDED_MODE_REGISTER_ADDRESS, CFG_DDR2_EXT_MODE_VAL2); // EMR DLL enable, Reduced Driver Impedance control, Differential DQS disabled
		udelay(100);
		ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x2); // EMR write
		udelay(10);
	}

	ath_reg_wr_nf(DDR_MODE_REGISTER_ADDRESS, mod_val_init);
	udelay(1000);

	ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x1);	// MR Write
	udelay(10);

	ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x8);	// Precharge
	udelay(10);

	ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x4);	// Auto Refresh
	udelay(10);

	ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x4);	// Auto Refresh
	udelay(10);

	// Issue MRS to remove DLL out-of-reset
	ath_reg_wr_nf(DDR_MODE_REGISTER_ADDRESS, mod_val);
	udelay(100);

	ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x1); // MR write
	udelay(100);

	if (type == ATH_MEM_DDR2) {
		ath_reg_wr_nf(DDR_EXTENDED_MODE_REGISTER_ADDRESS, CFG_DDR2_EXT_MODE_VAL1);
		udelay(100);

		ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x2); // EMR write
		udelay(100);

		ath_reg_wr_nf(DDR_EXTENDED_MODE_REGISTER_ADDRESS, CFG_DDR2_EXT_MODE_VAL2);
		udelay(100);

		ath_reg_wr_nf(DDR_CONTROL_ADDRESS, 0x2); // EMR write
		udelay(100);

		refresh = CFG_DDR2_REFRESH_VAL;
	}
	ath_reg_wr_nf(DDR_REFRESH_ADDRESS, refresh);
	udelay(100);

    ath_reg_wr(TAP_CONTROL_0_ADDRESS, tap_val);
    ath_reg_wr(TAP_CONTROL_1_ADDRESS, tap_val);

    ath_reg_wr (TAP_CONTROL_2_ADDRESS, tap_val);
    ath_reg_wr (TAP_CONTROL_3_ADDRESS, tap_val);

	if (type == ATH_MEM_DDR2) {
		ath_reg_wr(PMU1_ADDRESS, 0x633c8176);
		// Set DDR2 Voltage to 1.8 volts
		ath_reg_wr(PMU2_ADDRESS, PMU2_SWREGMSB_SET(0x40) |
					 PMU2_PGM_SET(0x1));
	}

	/*
	* Based on SGMII validation for stucks, packet errors were  observed and it was
         * mostly due to noise pickup on SGMII lines. Switching regulator register is to
         * be programmed with proper setting to avoid such stucks.
	 */
	if (type == ATH_MEM_DDR1){
		ath_reg_wr(PMU1_ADDRESS, 0x633c8176);
		ath_reg_wr(PMU2_ADDRESS, 0x10200000);
	}
	ath_sys_frequency();
	return type;
#else	// !nand flash and !emulation
	return 0;
#endif
}

int
ath_uart_freq(void)
{
	if (ath_reg_rd(RST_BOOTSTRAP_ADDRESS) & RST_BOOTSTRAP_REF_CLK_MASK) {
		return 40 * 1000 * 1000;
	} else {
		return 25 * 1000 * 1000;
	}
}

void
ath_sys_frequency()
{
#if !defined(CONFIG_ATH_EMULATION)
	unsigned int    rdata, i;
	unsigned int	cpu_pll_low_int, cpu_pll_low_frac, cpu_pll_high_int, cpu_pll_high_frac;
	unsigned int	ddr_pll_low_int, ddr_pll_low_frac, ddr_pll_high_int, ddr_pll_high_frac;
	unsigned int	cpu_clk_low, cpu_clk_high;
	unsigned int	ddr_clk_low, ddr_clk_high;
	unsigned int	ahb_clk_low, ahb_clk_high;
	/* CPU_DDR_CLOCK_CONTROL */
	unsigned int	ahbclk_from_ddrpll, ahb_post_div, ddr_post_div, cpu_post_div;
	unsigned int	cpu_ddr_clk_from_cpupll, cpu_ddr_clk_from_ddrpll;
	unsigned int	ahb_pll_bypass, ddr_pll_bypass, cpu_pll_bypass;
	/* CPU_PLL_CONFIG, CPU_PLL_CONFIG1, CPU_PLL_DITHER1, CPU_PLL_DITHER2 */
	unsigned int cpu_pllpwd, cpu_outdiv, cpu_Refdiv, cpu_Nint;
	unsigned int cpu_dither_en, cpu_NFrac_Min, cpu_NFrac_Max;
	unsigned int cpu_NFrac_Min_17_5, cpu_NFrac_Min_4_0;
	unsigned int cpu_NFrac_Max_17_5, cpu_NFrac_Max_4_0;
	/* DDR_PLL_CONFIG, DDR_PLL_CONFIG1, DDR_PLL_DITHER1, DDR_PLL_DITHER2 */
	unsigned int ddr_pllpwd, ddr_outdiv, ddr_Refdiv, ddr_Nint;
	unsigned int ddr_dither_en, ddr_NFrac_Min, ddr_NFrac_Max;
	unsigned int ddr_NFrac_Min_17_5, ddr_NFrac_Min_4_0;
	unsigned int ddr_NFrac_Max_17_5, ddr_NFrac_Max_4_0;
	static uint32_t ath_cpu_freq, ath_ddr_freq, ath_ahb_freq;
#endif
	uint32_t ref_clk;

#if defined(CONFIG_ATH_EMULATION)
	ref_clk = (40 * 1000000);
#else
	ref_clk = ath_uart_freq();
#endif

#ifdef CONFIG_ATH_EMULATION
	ath_cpu_freq = 80000000;
	ath_ddr_freq = 80000000;
	ath_ahb_freq = 40000000;
#else
	rdata = ath_reg_rd(CPU_DDR_CLOCK_CONTROL_ADDRESS);
	ahbclk_from_ddrpll	= CPU_DDR_CLOCK_CONTROL_AHBCLK_FROM_DDRPLL_GET(rdata);
	ahb_post_div		= CPU_DDR_CLOCK_CONTROL_AHB_POST_DIV_GET(rdata);
	ddr_post_div		= CPU_DDR_CLOCK_CONTROL_DDR_POST_DIV_GET(rdata);
	cpu_post_div		= CPU_DDR_CLOCK_CONTROL_CPU_POST_DIV_GET(rdata);
	cpu_ddr_clk_from_cpupll = CPU_DDR_CLOCK_CONTROL_CPU_DDR_CLK_FROM_CPUPLL_GET(rdata);
	cpu_ddr_clk_from_ddrpll = CPU_DDR_CLOCK_CONTROL_CPU_DDR_CLK_FROM_DDRPLL_GET(rdata);
	ahb_pll_bypass		= CPU_DDR_CLOCK_CONTROL_AHB_PLL_BYPASS_GET(rdata);
	ddr_pll_bypass		= CPU_DDR_CLOCK_CONTROL_DDR_PLL_BYPASS_GET(rdata);
	cpu_pll_bypass		= CPU_DDR_CLOCK_CONTROL_CPU_PLL_BYPASS_GET(rdata);

	if (ahb_pll_bypass) {
		ath_ahb_freq = ref_clk / (ahb_post_div + 1);
        //*ahb_clk_h = ref_clk / (ahb_post_div + 1);
	}

	if (ddr_pll_bypass) {
		ath_ddr_freq = ref_clk;
		//*ddr_clk_h = ref_clk;
	}

	if (cpu_pll_bypass) {
		ath_cpu_freq = ref_clk;
		//*cpu_clk_h = ref_clk;
	}

	if (ahb_pll_bypass && ddr_pll_bypass && cpu_pll_bypass) {
		return;
	}

	rdata = ath_reg_rd(CPU_PLL_CONFIG_ADDRESS);
	cpu_pllpwd	= CPU_PLL_CONFIG_PLLPWD_GET(rdata);
	cpu_outdiv	= CPU_PLL_CONFIG_OUTDIV_GET(rdata);
	cpu_Refdiv	= CPU_PLL_CONFIG_REFDIV_GET(rdata);

	rdata = ath_reg_rd(CPU_PLL_CONFIG1_ADDRESS);
	cpu_Nint	= CPU_PLL_CONFIG1_NINT_GET(rdata);

	rdata = ath_reg_rd(CPU_PLL_DITHER1_ADDRESS);
	cpu_dither_en	= CPU_PLL_DITHER1_DITHER_EN_GET(rdata);
	cpu_NFrac_Min	= CPU_PLL_DITHER1_NFRAC_MIN_GET(rdata);
	cpu_NFrac_Min_17_5 = (cpu_NFrac_Min >> 5) & 0x1fff;
	cpu_NFrac_Min_4_0  = cpu_NFrac_Min & 0x1f;

	rdata = ath_reg_rd(CPU_PLL_DITHER1_ADDRESS);
	cpu_NFrac_Max	= CPU_PLL_DITHER2_NFRAC_MAX_GET(rdata);
	cpu_NFrac_Max_17_5 = (cpu_NFrac_Max >> 5) & 0x1fff;
	cpu_NFrac_Max_4_0  = cpu_NFrac_Max & 0x1f;

	rdata = ath_reg_rd(DDR_PLL_CONFIG_ADDRESS);
	ddr_pllpwd	= DDR_PLL_CONFIG_PLLPWD_GET(rdata);
	ddr_outdiv	= DDR_PLL_CONFIG_OUTDIV_GET(rdata);
	ddr_Refdiv	= DDR_PLL_CONFIG_REFDIV_GET(rdata);

	rdata = ath_reg_rd(DDR_PLL_CONFIG1_ADDRESS);
	ddr_Nint	= DDR_PLL_CONFIG1_NINT_GET(rdata);

	rdata = ath_reg_rd(DDR_PLL_DITHER1_ADDRESS);
	ddr_dither_en	= DDR_PLL_DITHER1_DITHER_EN_GET(rdata);
	ddr_NFrac_Min	= DDR_PLL_DITHER1_NFRAC_MIN_GET(rdata);
	ddr_NFrac_Min_17_5 = (ddr_NFrac_Min >> 5) & 0x1fff;
	ddr_NFrac_Min_4_0  = ddr_NFrac_Min & 0x1f;

	rdata = ath_reg_rd(DDR_PLL_DITHER1_ADDRESS);
	ddr_NFrac_Max	= DDR_PLL_DITHER2_NFRAC_MAX_GET(rdata);
	ddr_NFrac_Max_17_5 = (ddr_NFrac_Max >> 5) & 0x1fff;
	ddr_NFrac_Max_4_0  = ddr_NFrac_Max & 0x1f;

	/* CPU PLL */
	i = (ref_clk/cpu_Refdiv);

	cpu_pll_low_int  = i*cpu_Nint;
	cpu_pll_high_int = cpu_pll_low_int;

	cpu_pll_low_frac = (i/(25*32))*((cpu_NFrac_Min_17_5*25 + cpu_NFrac_Min_4_0)/(8192/32));
	cpu_pll_high_frac = (i/(25*32))*((cpu_NFrac_Max_17_5*25 + cpu_NFrac_Max_4_0)/(8192/32));

	if (!cpu_dither_en || cpu_pll_high_frac <= cpu_pll_low_frac) {
		cpu_pll_high_frac = cpu_pll_low_frac;
	}

	/* DDR PLL */
	i = (ref_clk/ddr_Refdiv);

	ddr_pll_low_int  = i*ddr_Nint;
	ddr_pll_high_int = ddr_pll_low_int;

	ddr_pll_low_frac = (i/(25*32))*((ddr_NFrac_Min_17_5*25 + ddr_NFrac_Min_4_0)/(8192/32));
	ddr_pll_high_frac = (i/(25*32))*((ddr_NFrac_Max_17_5*25 + ddr_NFrac_Max_4_0)/(8192/32));

	if (!ddr_dither_en || ddr_pll_high_frac <= ddr_pll_low_frac) {
		ddr_pll_high_frac = ddr_pll_low_frac;
	}

	/* CPU Clock, DDR Clock, AHB Clock (before post div) */
	if (cpu_ddr_clk_from_cpupll) {
		cpu_clk_low  = cpu_pll_low_int + cpu_pll_low_frac;
		cpu_clk_high = cpu_pll_high_int + cpu_pll_high_frac;

		if (cpu_outdiv != 0) {
			cpu_clk_low  /= (2*cpu_outdiv);
			cpu_clk_high /= (2*cpu_outdiv);
		}

	ddr_clk_low  = cpu_clk_low;
	ddr_clk_high = cpu_clk_high;
	} else if (cpu_ddr_clk_from_ddrpll) {
		ddr_clk_low  = ddr_pll_low_int + ddr_pll_low_frac;
		ddr_clk_high = ddr_pll_high_int + ddr_pll_high_frac;

		if (ddr_outdiv != 0) {
			ddr_clk_low  /= (2*ddr_outdiv);
			ddr_clk_high /= (2*ddr_outdiv);
		}

		cpu_clk_low  = ddr_clk_low;
		cpu_clk_high = ddr_clk_high;
	} else {
		cpu_clk_low  = cpu_pll_low_int + cpu_pll_low_frac;
		cpu_clk_high = cpu_pll_high_int + cpu_pll_high_frac;
		ddr_clk_low  = ddr_pll_low_int + ddr_pll_low_frac;
		ddr_clk_high = ddr_pll_high_int + ddr_pll_high_frac;

		if (cpu_outdiv != 0) {
			cpu_clk_low  /= (2*cpu_outdiv);
			cpu_clk_high /= (2*cpu_outdiv);
		}

		if (ddr_outdiv != 0) {
			ddr_clk_low  /= (2*ddr_outdiv);
			ddr_clk_high /= (2*ddr_outdiv);
		}
	}

	if (ahbclk_from_ddrpll) {
        	ahb_clk_low  = ddr_clk_low;
		ahb_clk_high = ddr_clk_high;
	} else {
		ahb_clk_low  = cpu_clk_low;
		ahb_clk_high = cpu_clk_high;
	}

	/* CPU Clock, DDR Clock, AHB Clock */
	cpu_clk_low  /= (cpu_post_div + 1);
	cpu_clk_high /= (cpu_post_div + 1);
	ddr_clk_low  /= (ddr_post_div + 1);
	ddr_clk_high /= (ddr_post_div + 1);
	ahb_clk_low  /= (ahb_post_div + 1);
	ahb_clk_high /= (ahb_post_div + 1);

	ath_cpu_freq = cpu_clk_low;
	ath_ddr_freq = ddr_clk_low;
	ath_ahb_freq = ahb_clk_low;
	//*cpu_clk_h = cpu_clk_high;
	//*ddr_clk_h = ddr_clk_high;
	//*ahb_clk_h = ahb_clk_high;
#endif
	prmsg("%s: cpu %u ddr %u ahb %u\n", __func__,
	ath_cpu_freq / 1000000,
	ath_ddr_freq / 1000000,
	ath_ahb_freq / 1000000);
}
