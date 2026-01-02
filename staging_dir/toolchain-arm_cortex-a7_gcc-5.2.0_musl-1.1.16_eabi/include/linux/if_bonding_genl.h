/* Copyright (c) 2016, The Linux Foundation. All rights reserved.
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

#ifndef __LINUX_IF_BONDING_GENL_H
#define __LINUX_IF_BONDING_GENL_H

/* Bond GENL related defines - to be used by user space application for
 * communication with bonding driver via GENL
 */
#define BOND_GENL_NAME "bond"
#define BOND_GENL_VERSION 0x1

/**
 * enum bond_genl_commands - supported bonding commands
 *
 * @BOND_GENL_CMD_UNSPEC: unspecified command to catch errors
 *
 * @BOND_GENL_CMD_L2DA_SET_DEFAULT: set default L2DA slave, requires
 *     %BOND_GENL_ATTR_BOND_NAME and %BOND_GENL_ATTR_SLAVE_NAME
 *
 * @BOND_GENL_CMD_L2DA_GET_DEFAULT: get default L2DA slave, requires
 *     %BOND_GENL_ATTR_BOND_NAME
 *     Returns the default L2DA slave name in %BOND_GENL_ATTR_SLAVE_NAME string
 *
 * @BOND_GENL_CMD_L2DA_ADD_MAP_ENTRY: add L2DA map entry, requires
 *     %BOND_GENL_ATTR_BOND_NAME, %BOND_GENL_ATTR_SLAVE_NAME and
 *     %BOND_GENL_ATTR_MAC
 *
 * @BOND_GENL_CMD_L2DA_DEL_MAP_ENTRY: delete L2DA map entry, requires
 *     %BOND_GENL_ATTR_BOND_NAME and %BOND_GENL_ATTR_MAC
 *
 * @BOND_GENL_CMD_L2DA_GET_MAP: get entire L2DA map, requires
 *     %BOND_GENL_ATTR_BOND_NAME
 *     Returns the L2DA map entries as %BOND_GENL_ATTR_L2DA_MAP
 *
 * @BOND_GENL_CMD_L2DA_RESET_MAP: deletes all the L2DA map entries, requires
 *     %BOND_GENL_ATTR_BOND_NAME
 *
 * @BOND_GENL_CMD_L2DA_SET_OPTS: set L2DA mode options, requires
 *     %BOND_GENL_ATTR_BOND_NAME and %BOND_GENL_ATTR_L2DA_OPTS
 *
 * @BOND_GENL_CMD_L2DA_GET_OPTS: get L2DA mode options, requires
 *     %BOND_GENL_ATTR_BOND_NAME
 *     Returns L2DA mode options value in %BOND_GENL_ATTR_L2DA_OPTS
 *
 */

enum bond_genl_commands {
	BOND_GENL_CMD_UNSPEC,
	BOND_GENL_CMD_L2DA_SET_DEFAULT,
	BOND_GENL_CMD_L2DA_GET_DEFAULT,
	BOND_GENL_CMD_L2DA_ADD_MAP_ENTRY,
	BOND_GENL_CMD_L2DA_DEL_MAP_ENTRY,
	BOND_GENL_CMD_L2DA_GET_MAP,
	BOND_GENL_CMD_L2DA_RESET_MAP,
	BOND_GENL_CMD_L2DA_SET_OPTS,
	BOND_GENL_CMD_L2DA_GET_OPTS,
	BOND_GENL_CMD_LAST,
};

/**
 * enum bond_genl_attrs - bonding netlink attributes
 *
 * @BOND_GENL_ATTR_UNSPEC: unspecified attribute to catch errors
 * @BOND_GENL_ATTR_BOND_NAME: bonding interface name,
 *     enclosed data - string of max IFNAMSIZ + 1 chars
 * @BOND_GENL_ATTR_SLAVE_NAME: slave interface name
 *     enclosed data - string of max IFNAMSIZ + 1 chars
 * @BOND_GENL_ATTR_MAC: MAC address,
 *     enclosed data - ETH_ALEN bytes
 * @BOND_GENL_ATTR_L2DA_MAP: L2DA map,
 *     enclosed data - nested array of slave interface name/MAC address
 *     pairs, i.e. %BOND_GENL_ATTR_SLAVE_NAME and %BOND_GENL_ATTR_MAC
 *     correspondingly
 * @BOND_GENL_ATTR_L2DA_OPTS: L2DA mode options, bitmask of
 *     enum bond_genl_l2da_opts values
 *     enclosed data - u32
 */
enum bond_genl_attrs {
	BOND_GENL_ATTR_UNSPEC,
	BOND_GENL_ATTR_BOND_NAME,
	BOND_GENL_ATTR_SLAVE_NAME,
	BOND_GENL_ATTR_MAC,
	BOND_GENL_ATTR_L2DA_MAP,
	BOND_GENL_ATTR_L2DA_OPTS,
	BOND_GENL_ATTR_LAST,
};

/**
 * enum bond_genl_l2da_opts -  L2DA mode related options
 *
 * @BOND_L2DA_OPT_DUP_MC_TX: duplicate multicast packets on TX and send them
 *     over all the available slaves
 * @BOND_L2DA_OPT_DEDUP_RX: de-duplicate RX traffic, allowing EAPOLs from all
 *     interfaces and any other packets from active interface only
 * @BOND_L2DA_OPT_FORWARD_RX: forward received packets between slaves according
 *     to the following logic:
 *           - for multicast packets: clone and send to all the slaves
 *             (except the one it came from) and also deliver to local network
 *             stack
 *           - for unicast packets: search packet's destination address in
 *             L2DA map; if found, send the packet to the corresponding slave;
 *             otherwise - deliver to local network stack
 * @BOND_L2DA_OPT_REPLACE_MAC: replace source MAC on TX and dest MAC on RX in
 *      ETH header. In case of ARP packet, replace in payload as well.
 * @BOND_L2DA_OPT_AUTO_ARP_ANNOUNCE: automatically send ARP after active slave
 *      has been modified.
 */
enum bond_genl_l2da_opts {
	BOND_L2DA_OPT_DUP_MC_TX = 1<<0,
	BOND_L2DA_OPT_DEDUP_RX  = 1<<1,
	BOND_L2DA_OPT_FORWARD_RX  = 1<<2,
	BOND_L2DA_OPT_REPLACE_MAC  = 1<<3,
	BOND_L2DA_OPT_AUTO_ARP_ANNOUNCE  = 1<<4,
};

#endif /* __LINUX_IF_BONDING_GENL_H */
