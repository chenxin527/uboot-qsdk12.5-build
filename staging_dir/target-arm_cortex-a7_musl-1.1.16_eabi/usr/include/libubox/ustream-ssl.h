/*
 * ustream-ssl - library for SSL over ustream
 *
 * Copyright (C) 2012 Felix Fietkau <nbd@openwrt.org>
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

#ifndef __USTREAM_SSL_H
#define __USTREAM_SSL_H

#include <libubox/ustream.h>

struct ustream_ssl {
	struct ustream stream;
	struct ustream *conn;
	struct uloop_timeout error_timer;

	void (*notify_connected)(struct ustream_ssl *us);
	void (*notify_error)(struct ustream_ssl *us, int error, const char *str);
	void (*notify_verify_error)(struct ustream_ssl *us, int error, const char *str);

	struct ustream_ssl_ctx *ctx;
	void *ssl;

	char *peer_cn;
	const char *server_name;

	int error;
	bool connected;
	bool server;

	bool valid_cert;
	bool valid_cn;
};

struct ustream_ssl_ctx;

struct ustream_ssl_ops {

	struct ustream_ssl_ctx *(*context_new)(bool server);
	int (*context_set_crt_file)(struct ustream_ssl_ctx *ctx, const char *file);
	int (*context_set_key_file)(struct ustream_ssl_ctx *ctx, const char *file);
	int (*context_add_ca_crt_file)(struct ustream_ssl_ctx *ctx, const char *file);
	void (*context_free)(struct ustream_ssl_ctx *ctx);

	int (*init)(struct ustream_ssl *us, struct ustream *conn, struct ustream_ssl_ctx *ctx, bool server);
	int (*set_peer_cn)(struct ustream_ssl *conn, const char *name);
};

extern const struct ustream_ssl_ops ustream_ssl_ops;

#define ustream_ssl_context_new			ustream_ssl_ops.context_new
#define ustream_ssl_context_set_crt_file	ustream_ssl_ops.context_set_crt_file
#define ustream_ssl_context_set_key_file	ustream_ssl_ops.context_set_key_file
#define ustream_ssl_context_add_ca_crt_file	ustream_ssl_ops.context_add_ca_crt_file
#define ustream_ssl_context_free		ustream_ssl_ops.context_free
#define ustream_ssl_init			ustream_ssl_ops.init
#define ustream_ssl_set_peer_cn			ustream_ssl_ops.set_peer_cn

#endif
