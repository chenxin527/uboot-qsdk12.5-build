/*
* Copyright (c) 2018 Qualcomm Innovation Center, Inc.
* All Rights Reserved.
* Confidential and Proprietary - Qualcomm Innovation Center, Inc.
*
*/

/*
 * Copyright (c) 2010, Atheros Communications Inc.
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
 *
 */


#ifndef __APPBR_TYPES_H_
#define __APPBR_TYPES_H_

#include <qdf_status.h>
#include <qdf_types.h>

#define APPBR_NETLINK_NUM           18

/* Application IDs */
enum {
    APPBR_BYP       =   1,
    APPBR_ACFG      =   2,
    APPBR_WSUP_BR   =   3
};

#define APPBR_MAX_APPS                          16

/*
 * Error codes defined for setting args
 */
enum APPBR_STAT_VAL {
    APPBR_STAT_OK          =   QDF_STATUS_SUCCESS,
    APPBR_STAT_EARGSZ      =   QDF_STATUS_E_E2BIG,
    APPBR_STAT_ENOSOCK     =   QDF_STATUS_E_IO,
    APPBR_STAT_ENOREQACK   =   QDF_STATUS_E_ALREADY,
    APPBR_STAT_ENORESPACK  =   QDF_STATUS_E_BUSY,
    APPBR_STAT_ERECV       =   QDF_STATUS_E_FAULT,
    APPBR_STAT_ESENDCMD    =   QDF_STATUS_E_FAILURE,
    APPBR_STAT_ENOMEM      =   QDF_STATUS_E_NOMEM,
};

typedef uint32_t  appbr_status_t;

#define APPBR_MSGADDR_TO_APPID(addr)            (addr)
#define APPBR_APPID_TO_MSGADDR(addr)            (addr)

#endif
