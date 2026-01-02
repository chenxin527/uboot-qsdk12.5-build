/*
 * Copyright (c) 2010, 2018 Qualcomm Technologies, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Technologies, Inc.
 *
 * 2010 Qualcomm Atheros, Inc.
 *
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

/*-M- interface -- 
*/

#ifndef interface__h
#define interface__h

                    /*-,- From interface.c */
/*-M- interface -- linux network interface utilities
 */

                    /*-,- From interface.c */
/*-D- Required includes -- 
 */


                    /*-,- From interface.c */
/*-D- Required includes -- 
 */
#include <sys/ioctl.h>
#if !defined(__GLIBC__) && !defined(__UCLIBC__)
#define _LINUX_IF_ETHER_H /* Don't include the linux/if_ether.h file, use the netinet/if_ether.h definitions */
#include <netinet/if_ether.h>
#endif
#include <linux/ethtool.h>
#include <netinet/in.h>         /* sockaddr* definitions */
#include <netinet/ip.h>

/* -D- ipaddress -- union of addressing forms
*       This just formalizes the existing unix/linux scheme which
*       uses struct sockaddr to refer to an anonymous address type,
*       sockaddr_in for IPv4 addresses and sockaddr_in6 for IPv6 addresses.
*       There is no easy to understand union defined in unix/linux...
*       We rectify that here.
*       An object of type "union ipaddress" will be big enough to
*       hold any address we care about.
*
*       Per unix/linux tradition, all of the address types begin with
*       the address family identifier sa_family; or you can directly
*       access it via the sa_family memory of our union.
*       A zero value for sa_family is "unspecified" which is good.
*/
typedef union ipaddress {
    unsigned short sa_family;   /* all members begin with sa_family */
    struct sockaddr sockaddr;   /* anonymous address */
    struct sockaddr_in sockaddr_in;     /* IPv4 address (AF_INET) */
    struct sockaddr_in6 sockaddr_in6;   /* IPv6 address (AF_INET6) */
} ipaddress_t;



#define ADD_VLAN_CMD 0
#define DEL_VLAN_CMD 1
struct vlan_ioctl_args {
    int cmd; /* Should be one of the vlan_ioctl_cmds enum above. */
    char device1[24];
    
    union {
        char device2[24];
        int VID;
        unsigned int skb_priority;
        unsigned int name_type;
        unsigned int bind_type;
        unsigned int flag; /* Matches vlan_dev_info flags */
    } u;
    
    short vlan_qos;
};




                    /*-,- From interface.c */
/*-D- NetDeviceStats --
 */
struct NetDeviceStats {
    unsigned long long rx_bytes;    /* total bytes received         */
    unsigned long long rx_packets;  /* total packets received       */
    unsigned int rx_errors;    /* bad packets received         */
    unsigned int rx_dropped;   /* no space in linux buffers    */
    unsigned int rx_fifo_errors;   /* recv'r fifo overrun          */
    unsigned int rx_frame_errors;  /* recv'd frame alignment error */
    unsigned int rx_compressed;
    unsigned int rx_multicast; /* multicast packets received   */
    unsigned long long tx_bytes;    /* total bytes transmitted      */
    unsigned long long tx_packets;  /* total packets transmitted    */
    unsigned int tx_errors;    /* packet transmit problems     */
    unsigned int tx_dropped;   /* no space available in linux  */
    unsigned int tx_fifo_errors;
    unsigned int tx_collisions;
    unsigned int tx_carrier_errors;
    unsigned int tx_compressed; 
    unsigned int tx_mcast;
    unsigned int rx_mcast;
    unsigned int tx_bcast;
    unsigned int rx_bcast;
    unsigned int tx_ucast;
    unsigned int rx_ucast;
    unsigned int tx_rate;
    unsigned int rx_rate;
    unsigned int tx_fail;
};

typedef struct {
    unsigned char addr[6];
} mac_addr_t;

typedef struct {
	mac_addr_t hwaddr;
	int port_map;
	int sa_drop; 
} arl_struct_t;



                    /*-,- From interface.c */
                    extern
/*-F- interfaceEthernetPortUnMap(int Port) */
int interfaceEthernetPortUnMap(int Port)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceHostToIPString -- 
 */

int interfaceHostToIPString(
    const char *HostString,
    char *IPString,
    const int IPStrLen)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceAddVlan -- 
 */
int interfaceAddVlan(const char* Interface, const int VlanID)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceDelVlan --
 */
int interfaceDelVlan(const char* Interface)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceStartPortVlan --
 */
int interfaceStartPortVlan(
        const char* Interface)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceAddPortVlan -- 
 */
int interfaceAddPortVlan(
        const char* Interface,
        int Port,
        int VlanID)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceDelPortVlan -- 
 */
int interfaceDelPortVlan(
        const char* Interface,
        int Port,
        int VlanID)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceSetPortMode --
 */
int interfaceSetPortMode(
        const char* Interface,
        int Port,
        int Mode)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceSetDefaultVlanID --
 */
int interfaceSetDefaultVlanID(
        const char* Interface,
        int Port,
        int DefaultVlanID)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceSetMTUByName --
 */
int interfaceSetMTUByName(
        const char* Interface,
        const int MTU)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceControlByName --
 */
int interfaceControlByName(
        const char* Interface,
        const int Up)           /* 1=bring up, 0=take down*/
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetIPAddressByName -- 
 */
int interfaceGetIPAddressByName(
        const char* Interface,
        ipaddress_t* IpAddress)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceSetIPAddressByName --
 */
int interfaceSetIPAddressByName(
        const char* Interface,
        const char* IpAddress,
        const char* SubnetMask)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetMACAddressForInterface -- get six byte mac address
*       Returns nonzero on error.
*/
int interfaceGetMACAddressForInterface(
        const char* Interface,
        unsigned char MACAddress[6])    /* output */
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetMACAddressByName -- get text represenation of mac address
*       Returns nonzero on error.
*/
int interfaceGetMACAddressByName(
        const char* Interface,
        char* MACAddress,       /* output */
        int MACAddressSize)     /* size of output buffer */
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetStatusByName --
 */
int interfaceGetStatusByName(
        const char* Interface)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetPortLinkStatus --
 */
int interfaceGetPortLinkStatus(const char* Interface, int Port)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetStatsByName --
 */
int interfaceGetStatsByName(
        const char* Interface,
        struct NetDeviceStats* NDStats)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetLinkOnOffByName --
*/
int interfaceGetLinkOnOffByName(
		const char * Interface)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetStatsByName --
 */
int interfaceGetStatsByPort(
        const char* BaseInterface,
        int Port,
        struct NetDeviceStats* NDStats)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceSetDuplex --
 */
int interfaceSetDuplex(
        const char* Interface,
        int Mode, /* DUPLEX_HALF, DUPLEX_FULL, 0 for AUTO */
        int Advertise)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceIgmpSnoopingSet --
 */
int interfaceIgmpSnoopingSet(
        unsigned int vlanId,
		int enable)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceAddARL --
 */
int interfaceAddARL(
	const char* Interface,
        mac_addr_t macAddr,
	unsigned int Port)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceDelARL --
 */
int interfaceDelARL(
	const char* Interface,
        mac_addr_t mac)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceArlFlush --
 */
int interfaceArlFlush(
        const char* Interface)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetPlcPort --
 */
int interfaceGetPlcPort(
	const char* Interface, unsigned char *MAC)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceSetPacketFlag --
 */
int interfaceSetPacketFlag(const char *Interface,
        int Op)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetLinkStats --
 * Inforamtion: byte one   -- 1:up/0:down
 *              byte two   -- 1:FULL/0:HALF duplex
 *              byte three -- 0:10M/1:100M/2:1G
 */
int interfaceGetLinkInformation(const char *InterfaceName, int *Information, int Port)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetLanLinkSpeed --
 *  return 0: 10M
 *         1: 100M
 *         2: 1000M
 */
int interfaceGetLanLinkSpeed(const char *InterfaceName)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetWanLinkStats --
 */
int interfaceGetWanLinkStats(const char *InterfaceName, int *Stats)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetNetmaskByName --
 */
int interfaceGetNetmaskByName(const char *ifName,
    unsigned int *netmask)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceSetIFFlag --
 */
int interfaceSetIFFlag(const char *ifName, unsigned int IFFlag)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetDefaultGateway --
 */
int interfaceGetDefaultGateway(char *DefaultGateway)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetSignalStrengthByName --
 */
int interfaceGetSignalStrengthByName(const char *Interface)
;
                              /*-;-*/


                    /*-,- From interface.c */
                    extern
/*-F- interfaceGetVapTR181StatsByName --
 */
int interfaceGetVapTR181StatsByName(const char *Interface,
				 struct NetDeviceStats* NDStats)
;


#endif // interface__h
