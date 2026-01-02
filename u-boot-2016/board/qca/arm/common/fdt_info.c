/*
 * Copyright (c) 2016 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/

#include <common.h>
#include <fdtdec.h>

DECLARE_GLOBAL_DATA_PTR;

unsigned int is_spi_nand_available(void)
{
	return fdtdec_get_uint(gd->fdt_blob, 0, "spi_nand_available", 0);
}

unsigned int is_nor_nand_available(void)
{
	return fdtdec_get_uint(gd->fdt_blob, 0, "nor_nand_available", 0);
}
