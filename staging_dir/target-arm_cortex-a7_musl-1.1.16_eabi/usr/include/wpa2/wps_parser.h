/**************************************************************************
//
//  Copyright (c) 2006-2007 Sony Corporation. All Rights Reserved.
//
//  File Name: wps_parser.h
//  Description: EAP-WPS parser source header
//
//   Redistribution and use in source and binary forms, with or without
//   modification, are permitted provided that the following conditions
//   are met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in
//       the documentation and/or other materials provided with the
//       distribution.
//     * Neither the name of Sony Corporation nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
//   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**************************************************************************/

#ifndef WPS_PARSER_H
#define WPS_PARSER_H

#define WPS_VALTYPE_BOOL	0
#define WPS_VALTYPE_U8		1
#define WPS_VALTYPE_U16		2
#define WPS_VALTYPE_U32		3
#define	WPS_VALTYPE_PTR		4

struct wps_tlv {
	u16		type;
	u16		length;
	u16		value_type;
	union _value {
		Boolean	bool_;
		u8		u8_;
		u16		u16_;
		u32		u32_;
		u8 *	ptr_;
	} value;
};

struct wps_data {
	u8 count;
	struct wps_tlv **tlvs;
};

int wps_create_wps_data(struct wps_data **data);
int wps_destroy_wps_data(struct wps_data **data);

int wps_parse_wps_ie(const u8 *wps_ie, size_t wps_ie_len, struct wps_data *data);
int wps_parse_wps_data(const u8 *buf, size_t len, struct wps_data *data);

int wps_write_wps_ie(struct wps_data * data, u8 **ie, size_t *length);
int wps_write_wps_data(struct wps_data * data, u8 **buf, size_t *length);

int wps_tlv_get_value(const struct wps_tlv *tlv, void *value, size_t *length);
int wps_get_value(const struct wps_data *data, u16 type, void *value, size_t *length);
int wps_set_value(const struct wps_data *data, u16 type, void *value, size_t length);
int wps_remove_value(struct wps_data *data, u16 type);
int wps_get_nw_key_len(const struct wps_data *data, size_t *length);

u8 wps_get_message_type(u8 *buf, size_t length);
#endif /* WPS_PARSER_H */
