/*
 * blob.c - uci <-> blobmsg conversion layer
 * Copyright (C) 2012-2013 Felix Fietkau <nbd@openwrt.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 2.1
 * as published by the Free Software Foundation
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 */
#ifndef __UCI_BLOB_H
#define __UCI_BLOB_H

#include <libubox/blobmsg.h>
#include "uci.h"

struct uci_blob_param_info {
	enum blobmsg_type type;
};

struct uci_blob_param_list {
	int n_params;
	const struct blobmsg_policy *params;
	const struct uci_blob_param_info *info;
	const char * const *validate;

	int n_next;
	const struct uci_blob_param_list *next[];
};

int uci_to_blob(struct blob_buf *b, struct uci_section *s,
		const struct uci_blob_param_list *p);
bool uci_blob_check_equal(struct blob_attr *c1, struct blob_attr *c2,
			  const struct uci_blob_param_list *config);
bool uci_blob_diff(struct blob_attr **tb1, struct blob_attr **tb2,
		   const struct uci_blob_param_list *config,
		   unsigned long *diff_bits);

#endif
