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

#ifndef __RPC_PLUGIN_H
#define __RPC_PLUGIN_H

#define _GNU_SOURCE /* asprintf() */

#include <dlfcn.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/types.h>

#include <libubox/blobmsg_json.h>
#include <libubus.h>
#include <json-c/json.h>

#include <rpcd/exec.h>
#include <rpcd/session.h>

/* location of plugin executables */
#define RPC_PLUGIN_DIRECTORY	"/usr/libexec/rpcd"

/* location of plugin libraries */
#define RPC_LIBRARY_DIRECTORY	"/usr/lib/rpcd"

struct rpc_daemon_ops {
    bool (*session_access)(const char *sid, const char *scope,
                           const char *object, const char *function);
    void (*session_create_cb)(struct rpc_session_cb *cb);
    void (*session_destroy_cb)(struct rpc_session_cb *cb);
    int (*exec)(const char **args,
                rpc_exec_write_cb_t in, rpc_exec_read_cb_t out,
                rpc_exec_read_cb_t err, rpc_exec_done_cb_t end,
                void *priv, struct ubus_context *ctx,
                struct ubus_request_data *req);
};

struct rpc_plugin {
    struct list_head list;
    int (*init)(const struct rpc_daemon_ops *ops, struct ubus_context *ctx);
};

int rpc_plugin_api_init(struct ubus_context *ctx);

#endif
