/*
 * @@-COPYRIGHT-START-@@
 *
 * Copyright (c) 2016 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 *
 * @@-COPYRIGHT-END-@@
 */

/*
 * Maximum amount of ethernet interfaces
 * Dakota   - 2 GMACs
 * Akronite - 4 GMACs
 */
#define IEEE1905_QCA_VENDOR_MAX_ETH_INTERFACES ( 4 )

/*
 * Maximum number of Radios
 */
#define IEEE1905_QCA_VENDOR_MAX_RADIOS ( 4 )

/*
 * Maximum number of BSSes set to 15 including bSTA
 */
#define IEEE1905_QCA_VENDOR_MAX_BSS ( 15 )

/*
 * Maximum amount of interfaces
 */
#define IEEE1905_QCA_VENDOR_MAX_INTERFACE ( IEEE1905_QCA_VENDOR_MAX_BSS \
        * IEEE1905_QCA_VENDOR_MAX_RADIOS \
        + IEEE1905_QCA_VENDOR_MAX_ETH_INTERFACES )
