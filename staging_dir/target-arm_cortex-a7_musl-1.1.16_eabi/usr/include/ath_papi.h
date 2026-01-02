/*
 * @@-COPYRIGHT-START-@@
 *
 * Copyright (c) 2017 Qualcomm Innovation Center, Inc.
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Innovation Center, Inc.
 *
 * @@-COPYRIGHT-END-@@
 */

#include <osdep.h>
#include "osif_private.h"

#ifndef _ATH_PARAMETER_API__
#define _ATH_PARAMETER_API__

#if ATH_PARAMETER_API
int ath_papi_netlink_init(void);
int ath_papi_netlink_delete(void);
void ath_papi_netlink_send(ath_netlink_papi_event_t *event);
#else
#define ath_papi_netlink_init() do {} while (0)
#define ath_papi_netlink_delete() do {} while (0)
#define ath_papi_netlink_send(ev) do {} while (0)
#endif /* ATH_PARAMETER_API */

#endif /* _ATH_PARAMETER_API__ */
