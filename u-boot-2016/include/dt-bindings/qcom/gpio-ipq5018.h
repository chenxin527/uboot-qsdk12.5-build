/*
* Copyright (c) 2016-2019, The Linux Foundation. All rights reserved.
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

#ifndef __DT_BINDINGS_IPQ5018_GPIO_H__
#define __DT_BINDINGS_IPQ5018_GPIO_H__

/* GPIO TLMM: Direction */
#define GPIO_INPUT              0
#define GPIO_OUTPUT             1

/* GPIO TLMM: Output value */
#define GPIO_OUT_LOW            0
#define GPIO_OUT_HIGH           1

/* GPIO TLMM: Pullup/Pulldown */
#define GPIO_NO_PULL            0
#define GPIO_PULL_DOWN          1
#define GPIO_KEEPER             2
#define GPIO_PULL_UP            3

/* GPIO TLMM: Drive Strength */
#define GPIO_2MA                0
#define GPIO_4MA                1
#define GPIO_6MA                2
#define GPIO_8MA                3
#define GPIO_10MA               4
#define GPIO_12MA               5
#define GPIO_14MA               6
#define GPIO_16MA               7

/* GPIO TLMM: Status */
#define GPIO_OE_DISABLE         0
#define GPIO_OE_ENABLE          1

/* GPIO OD */
#define GPIO_OD_ENABLE          1
#define GPIO_OD_DISABLE         0

/* GPIO SR */
#define GPIO_SR_ENABLE          1
#define GPIO_SR_DISABLE         0

/* GPIO PULLUP RES */
#define GPIO_PULL_RES0          0
#define GPIO_PULL_RES1          1
#define GPIO_PULL_RES2          2
#define GPIO_PULL_RES3          3

#endif

