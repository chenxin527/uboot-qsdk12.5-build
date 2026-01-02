/*
 * @@-COPYRIGHT-START-@@
 *
 * Copyright (c) 2014 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 *
 * @@-COPYRIGHT-END-@@
 */


#ifndef _QCA_SUPPORT_SSID_STEERING__
#define _QCA_SUPPORT_SSID_STEERING___

#define NETLINK_ATH_SSID_EVENT (NETLINK_GENERIC + 13)
#define MAC_ADDR_LEN           6
enum {
    ATH_EVENT_SSID_NODE_ASSOCIATED = 1,
};

/** vdev type is defined for ssid steering
 */
enum {
    SON_SSID_STEERING_DEFAULT_VDEV = 0,
    SON_SSID_STEERING_PRIVATE_VDEV = 1,
    SON_SSID_STEERING_PUBLIC_VDEV = 2,
};

typedef struct ssidsteering_event {
    u_int32_t type;
    u_int8_t mac[MAC_ADDR_LEN];
    u_int32_t datalen;
} ssidsteering_event_t;

int ath_ssid_steering_netlink_init(void);
int ath_ssid_steering_netlink_delete(void);
void ath_ssid_steering_netlink_send(ssidsteering_event_t *event);
#endif /* _QCA_SUPPORT_SSID_STEERING___*/

