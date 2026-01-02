/*
 * rpcd - UBUS RPC server
 *
 *   Copyright (C) 2013-2014 Jo-Philipp Wich <jow@openwrt.org>
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
 */

#ifndef __RPC_UCI_H
#define __RPC_UCI_H

#include <glob.h>
#include <limits.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <inttypes.h>
#include <libubus.h>
#include <uci.h>

#define RPC_UCI_DIR_PREFIX	"/var/run/rpcd"
#define RPC_UCI_SAVEDIR_PREFIX	RPC_UCI_DIR_PREFIX "/uci-"
#define RPC_SNAPSHOT_FILES	RPC_UCI_DIR_PREFIX "/snapshot-files/"
#define RPC_SNAPSHOT_DELTA	RPC_UCI_DIR_PREFIX "/snapshot-delta/"
#define RPC_UCI_DIR		"/etc/config/"
#define RPC_APPLY_TIMEOUT	60

int rpc_uci_api_init(struct ubus_context *ctx);

void rpc_uci_purge_savedirs(void);

#endif
