/*
 * Copyright (c) 2014, 2016-2017 The Linux Foundation. All rights reserved.
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
#include <command.h>
#include <asm/mipsregs.h>
#include <asm/addrspace.h>
#include <config.h>
#include <version.h>
#include <atheros.h>

#ifdef CONFIG_ATH_NAND_BR
#include <nand.h>
#endif

#ifdef CONFIG_ATH_NAND_BR
void *
ath_get_nand_cal_data(void)
{
	extern unsigned long long ath_nand_get_cal_offset(const char *ba);

	ulong off,size;
	int ret;
	static u_char nand_cal_data[256 * 1024];
	nand_info_t *nand;

	/*
	 * caldata partition is of 128k
	 *
	 */
	nand = &nand_info[nand_curr_device];
	size = nand->erasesize;

	/*
	 * Get the Offset of Caldata partition
	 */

	off = ath_nand_get_cal_offset(getenv("bootargs"));
	if(off == ATH_CAL_OFF_INVAL) {
		printf("Invalid CAL offset \n");
		return 1;
	}

	/*
	 * Get the values from flash, and program into the MAC address
	 * registers
	 */

	ret = nand_read(nand, (loff_t)off, &size, nand_cal_data);
	printf(" %d bytes %s: %s\n", size,
		"read", ret ? "ERROR" : "OK");
	if(ret != 0 ) {
		return NULL;
	}

	return nand_cal_data;
}
#endif

void ath_set_tuning_caps(void)
{
	typedef struct {
		u_int8_t pad[0x28],
		params_for_tuning_caps[2],
		featureEnable;
	} __attribute__((__packed__)) ar9300_eeprom_t;

	ar9300_eeprom_t	*eep;
	uint32_t	val;

#ifdef CONFIG_ATH_NAND_BR
	eep = (ar9300_eeprom_t *)ath_get_nand_cal_data();
#else
	eep = (ar9300_eeprom_t *)WLANCAL;
#endif /* CONFIG_ATH_NAND_BR */

	val =	XTAL_TCXODET_SET(0x0) |
		XTAL_XTAL_DRVSTR_SET(0x3) |
		XTAL_XTAL_CAPINDAC_SET(0x45) |
		XTAL_XTAL_CAPOUTDAC_SET(0x45) |
		XTAL_XTAL_SHORTXIN_SET(0x0) |
		XTAL_XTAL_LOCALBIAS_SET(0x1) |
		XTAL_XTAL_PWDCLKD_SET(0x0) |
		XTAL_XTAL_BIAS2X_SET(0x0) |
		XTAL_XTAL_LBIAS2X_SET(0x0) |
		XTAL_XTAL_ATBVREG_SET(0x0) |
		XTAL_XTAL_OSCON_SET(0x1) |
		XTAL_XTAL_PWDCLKIN_SET(0x0) |
		XTAL_LOCAL_XTAL_SET(0x1) |
		XTAL_PWD_SWREGCLK_SET(0x0) |
		XTAL_SWREGCLK_EDGE_SEL_SET(0x0) |
		XTAL_SPARE_SET(0xf);

	/* checking feature enable bit 6 and caldata is valid */
	if ((eep) && (eep->featureEnable & 0x40) && (eep->pad[0x0] != 0xff)) {
		val &= ~(XTAL_XTAL_CAPINDAC_MASK | XTAL_XTAL_CAPOUTDAC_MASK);
		val |=	XTAL_XTAL_CAPINDAC_SET(eep->params_for_tuning_caps[0]) |
			XTAL_XTAL_CAPOUTDAC_SET(eep->params_for_tuning_caps[0]);

	}

	ath_reg_wr(XTAL_ADDRESS, val);

#define __str(x)	# x
#define str(x)		__str(x)

	printf("Setting " str(XTAL_ADDRESS) " to 0x%x\n", val);
	return;
}

#ifdef CONFIG_LAST_STAGE_INIT
int last_stage_init(void)
{
	ath_set_tuning_caps();
	return 0;
}
#endif
