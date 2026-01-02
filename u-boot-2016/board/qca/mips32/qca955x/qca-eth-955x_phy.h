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

#ifndef _QCA_ETH_955x_PHY_H
#define _QCA_ETH_955x_PHY_H
#include <miiphy.h>


#ifdef CONFIG_ATHR_8033_PHY
extern int athrs_ar8033_reg_init(void *arg);
extern int athrs_ar8033_phy_setup(void  *arg);
extern int athrs_ar8033_phy_is_fdx(int ethUnit);
extern int athrs_ar8033_phy_is_link_alive(int phyUnit);
extern int athrs_ar8033_phy_is_up(int ethUnit);
extern int athrs_ar8033_phy_speed(int ethUnit,int phyUnit);
#endif

#ifdef CONFIG_ATHRS17_PHY
extern int athrs17_phy_setup(int ethUnit);
extern int athrs17_phy_is_up(int ethUnit);
extern int athrs17_phy_is_fdx(int ethUnit);
extern int athrs17_phy_speed(int ethUnit);
#endif

static inline void ath_gmac_phy_setup(int unit)
{
#ifdef CONFIG_ATHRS17_PHY
		if (unit == 0) {
			athrs17_phy_setup(unit);
		} else
#endif
		{
#ifdef CONFIG_VIR_PHY
			athr_vir_phy_setup(unit);
#endif
#if defined(CONFIG_ATHRS17_PHY) && !defined (CFG_DUAL_PHY_SUPPORT)
			athrs17_phy_setup(unit);
#endif

		}
}

static inline void ath_gmac_phy_link(int unit, int *link)
{
#ifdef CONFIG_ATHRS17_PHY
		if (unit == 0) {
			*link = athrs17_phy_is_up(unit);
		} else
#endif
		{
#ifdef CONFIG_VIR_PHY
			*link = athr_vir_phy_is_up(unit);
#endif
#ifdef CONFIG_ATHR_8033_PHY
			*link = athrs_ar8033_phy_is_up(unit);
#endif
#if defined(CONFIG_ATHRS17_PHY) && !defined (CFG_DUAL_PHY_SUPPORT)
			*link = athrs17_phy_is_up(unit);
#endif

		}
}

static inline void ath_gmac_phy_duplex(int unit, int *duplex)
{
#ifdef CONFIG_ATHRS17_PHY
		if (unit == 0) {
			*duplex = athrs17_phy_is_fdx(unit);
		} else
#endif
		{
#ifdef CONFIG_VIR_PHY
			*duplex = athr_vir_phy_is_fdx(unit);
#endif
#ifdef CONFIG_ATHR_8033_PHY
			*duplex = athrs_ar8033_phy_is_fdx(unit);
#endif
#if defined(CONFIG_ATHRS17_PHY) && !defined(CFG_DUAL_PHY_SUPPORT)
			*duplex = athrs17_phy_is_fdx(unit);
#endif
		}
}

static inline void ath_gmac_phy_speed(int unit, int *speed)
{
#ifdef CONFIG_ATHRS17_PHY
		if (unit == 0) {
			*speed = _1000BASET;
		} else
#endif
		{
#ifdef CONFIG_VIR_PHY
			*speed = athr_vir_phy_speed(unit);
#endif
#ifdef CONFIG_ATHR_8033_PHY
			*speed = athrs_ar8033_phy_speed(unit, 5);
#endif

#if defined(CONFIG_ATHRS17_PHY) && !defined (CFG_DUAL_PHY_SUPPORT)
			*speed = _1000BASET;
#endif
		}
}

#endif /* _QCA_ETH_955x_PHY_H */
