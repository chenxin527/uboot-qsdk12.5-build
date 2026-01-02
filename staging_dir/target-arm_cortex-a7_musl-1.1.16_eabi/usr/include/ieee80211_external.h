/*****************************************************************************/
/* \file ieee80211_external.h
** \brief External Header File References
**
**  This header file refers to the internal header files that provide the
**  data structure definitions and parameters required by external programs
**  that interface via ioctl or similiar mechanisms.  This hides the location
**  of the specific header files, and provides a control to limit what is
**  being exported for external use.
**
**  Copyright (c) 2009 Atheros Communications Inc.  All rights reserved.
**
** Permission to use, copy, modify, and/or distribute this software for any
** purpose with or without fee is hereby granted, provided that the above
** copyright notice and this permission notice appear in all copies.
**
** THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
** WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
** MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
** ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
** WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
** ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
** OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
**/

/* 
 * Copyright (c) 2013 Qualcomm Atheros, Inc.
 * All Rights Reserved. 
 * Qualcomm Atheros Confidential and Proprietary. 
 */ 

#ifndef IEEE80211_EXTERNAL_H
#define IEEE80211_EXTERNAL_H

#ifndef __packed
#define __packed    __attribute__((__packed__))
#endif
#define EXTERNAL_USE_ONLY
#if 0
#include "include/ieee80211.h"
#include "include/ieee80211_defines.h"
#include "os/linux/include/ieee80211_ioctl.h"
#include "lmac/ath_devif_athioctl.h"
#include "os/linux/include/ath_ald_external.h"
#include "os/linux/include/ieee80211_ev.h"
#else
#ifndef BUILD_X86
#include <ieee80211_external_config.h>
#endif
#include "ieee80211.h"
#include "ieee80211_defines.h"
#include "ieee80211_ioctl.h"
#include "if_athioctl.h"
#include "ath_ald_external.h"
#include "ieee80211_ev.h"
#include "ext_ioctl_drv_if.h"
#endif

/*
** Key definitions moved to here to allow them to be published externally
** without having to export all of the other stuff.  These need to be consistent
** with the definitions in ieee80211_crypto.h
*/

#define	IEEE80211_KEY_XMIT	0x01	/* key used for xmit */
#define	IEEE80211_KEY_RECV	0x02	/* key used for recv */
#define	IEEE80211_KEY_GROUP	0x04	/* key used for WPA group operation */
#define IEEE80211_KEY_MFP   0x08    /* key also used for management frames */
#define	IEEE80211_KEY_SWENCRYPT	0x10	/* host-based encryption */
#define	IEEE80211_KEY_SWENMIC	0x20	/* host-based enmic */
#define IEEE80211_KEY_PERSISTENT 0x40   /* do not remove unless OS commands us to do so */
#define IEEE80211_KEY_PERSTA    0x80    /* per STA default key */
#define IEEE80211_KEY_SWDECRYPT 0x100   /* host-based decryption */
#define IEEE80211_KEY_SWDEMIC   0x200   /* host-based demic */
#define IEEE80211_KEY_SWCRYPT   (IEEE80211_KEY_SWENCRYPT | IEEE80211_KEY_SWDECRYPT)
#define IEEE80211_KEY_SWMIC     (IEEE80211_KEY_SWENMIC | IEEE80211_KEY_SWDEMIC)

/*
** Wireless Mode related definitions replicated here to allow them to be published
** externally without having to export all of the other stuff.  These need to be consistent
** with the definitions in ath_dev.h
*/

#ifndef WIRELESS_MODE_MAX
#define WIRELESS_MODE_MAX   (12)
#endif

#ifndef IEEE80211_IPV4_LEN
#define IEEE80211_IPV4_LEN 4
#endif

#ifndef IEEE80211_IPV6_LEN
#define IEEE80211_IPV6_LEN 16
#endif
#endif /* IEEE80211_EXTERNAL_H */
