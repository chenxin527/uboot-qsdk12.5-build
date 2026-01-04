// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2025
 *
 * Author: Yuzhii
 *
 * Minimal DHCPv4 server for MediaTek web failsafe.
 *
 * Goals:
 * - Provide IP/netmask/gateway/DNS to a directly connected PC
 * - Auto-start with web failsafe (httpd)
 * - Small and self-contained
 */

/* Source Code based on:
 * https://github.com/Yuzhii0718/bl-mt798x-dhcpd/blob/master/uboot-mtk-20250711/net/mtk_dhcpd.c
 */

#include <common.h>
#include <net.h>

#include <net/dhcpd.h>

#define DHCPD_SERVER_PORT	67
#define DHCPD_CLIENT_PORT	68

/*
 * BOOTP/DHCP has a historical minimum message size of 300 bytes.
 * Some clients (notably Windows) may ignore shorter replies.
 */
#define DHCPD_MIN_BOOTP_LEN	300

/* BOOTP/DHCP message header (RFC 2131) */
struct dhcpd_pkt {
	u8 op;
	u8 htype;
	u8 hlen;
	u8 hops;
	u32 xid;
	u16 secs;
	u16 flags;
	u32 ciaddr;
	u32 yiaddr;
	u32 siaddr;
	u32 giaddr;
	u8 chaddr[16];
	u8 sname[64];
	u8 file[128];
	u8 vend[312];
} __packed;

#define BOOTREQUEST		1
#define BOOTREPLY		2

#define HTYPE_ETHER		1
#define HLEN_ETHER		6

#define DHCPDISCOVER	1
#define DHCPOFFER		2
#define DHCPREQUEST		3
#define DHCPACK			5
#define DHCPNAK			6

#define DHCP_OPTION_PAD		0
#define DHCP_OPTION_SUBNET_MASK	1
#define DHCP_OPTION_ROUTER	3
#define DHCP_OPTION_DNS_SERVER	6
#define DHCP_OPTION_REQ_IPADDR	50
#define DHCP_OPTION_LEASE_TIME	51
#define DHCP_OPTION_MSG_TYPE	53
#define DHCP_OPTION_SERVER_ID	54
#define DHCP_OPTION_MESSAGE		56
#define DHCP_OPTION_END		255

#define DHCP_FLAG_BROADCAST	0x8000

#define DHCPD_POOL_START_STR	"192.168.1.100"
#define DHCPD_POOL_END_STR	"192.168.1.200"

#define DHCPD_DEFAULT_IP_STR	"192.168.1.1"
#define DHCPD_DEFAULT_NETMASK_STR "255.255.255.0"

#define DHCPD_MAX_CLIENTS	8

static const u8 dhcp_magic_cookie[4] = { 99, 130, 83, 99 };

struct dhcpd_lease {
	bool used;
	u8 mac[6];
	struct in_addr ip;
};

static struct dhcpd_lease leases[DHCPD_MAX_CLIENTS];
static u32 next_ip_host;

static rxhand_f *prev_udp_handler;
static bool dhcpd_running;

static struct in_addr dhcpd_get_server_ip(void)
{
	if (net_ip.s_addr)
		return net_ip;

	return string_to_ip(DHCPD_DEFAULT_IP_STR);
}

static struct in_addr dhcpd_get_netmask(void)
{
	if (net_netmask.s_addr)
		return net_netmask;

	return string_to_ip(DHCPD_DEFAULT_NETMASK_STR);
}

static struct in_addr dhcpd_get_gateway(void)
{
	if (net_gateway.s_addr)
		return net_gateway;

	return dhcpd_get_server_ip();
}

static struct in_addr dhcpd_get_dns(void)
{
	if (net_dns_server.s_addr)
		return net_dns_server;

	return dhcpd_get_server_ip();
}

static bool dhcpd_mac_equal(const u8 *a, const u8 *b)
{
	return memcmp(a, b, 6) == 0;
}

static struct dhcpd_lease *dhcpd_find_lease(const u8 *mac)
{
	int i;

	for (i = 0; i < DHCPD_MAX_CLIENTS; i++) {
		if (leases[i].used && dhcpd_mac_equal(leases[i].mac, mac))
			return &leases[i];
	}

	return NULL;
}

static bool dhcpd_ip_in_pool(u32 ip_host)
{
	u32 start = ntohl(string_to_ip(DHCPD_POOL_START_STR).s_addr);
	u32 end = ntohl(string_to_ip(DHCPD_POOL_END_STR).s_addr);

	return ip_host >= start && ip_host <= end;
}

/* 检查IP地址是否已经被分配（给任何客户端） */
static bool dhcpd_ip_is_allocated(u32 ip_host)
{
    int i;

    for (i = 0; i < DHCPD_MAX_CLIENTS; i++) {
        if (leases[i].used && leases[i].ip.s_addr == htonl(ip_host)) {
            return true;
        }
    }
    return false;
}

/* 检查IP地址是否被指定的MAC地址租用 */
static bool dhcpd_ip_allocated_to_mac(u32 ip_host, const u8 *mac)
{
    int i;

    for (i = 0; i < DHCPD_MAX_CLIENTS; i++) {
        if (leases[i].used &&
            leases[i].ip.s_addr == htonl(ip_host) &&
            dhcpd_mac_equal(leases[i].mac, mac)) {
            return true;
        }
    }
    return false;
}

/* 计算MAC地址的哈希值（用于确定IP分配） */
static u32 dhcpd_mac_hash(const u8 *mac)
{
    /*
     * 使用简单的Fowler-Noll-Vo (FNV-1a)哈希算法
     * 确保不同MAC有较好的哈希分布
     */
    u32 hash = 2166136261u;  // FNV offset basis

    for (int i = 0; i < 6; i++) {
        hash ^= mac[i];
        hash *= 16777619u;   // FNV prime
    }

    return hash;
}

/* 基于MAC哈希分配IP地址 */
static struct in_addr dhcpd_alloc_ip(const u8 *mac)
{
    struct dhcpd_lease *l;
    u32 start, end, pool_size;
    u32 hash_value, base_ip, try_ip;
    int max_attempts;

    // 1. 检查客户端是否已有租约
    l = dhcpd_find_lease(mac);
    if (l)
        return l->ip;

    // 2. 获取IP池范围
    start = ntohl(string_to_ip(DHCPD_POOL_START_STR).s_addr);
    end = ntohl(string_to_ip(DHCPD_POOL_END_STR).s_addr);
    pool_size = end - start + 1;

    if (pool_size == 0) {
        debug_cond(DEBUG_DEV_PKT, "dhcpd: IP pool size is zero\n");
        struct in_addr ip;
        ip.s_addr = htonl(start);
        return ip;
    }

    // 3. 计算MAC哈希值
    hash_value = dhcpd_mac_hash(mac);

    // 4. 计算基础IP（哈希值映射到IP池）
    base_ip = start + (hash_value % pool_size);
    try_ip = base_ip;

    max_attempts = pool_size;  // 最多尝试整个池子

    debug_cond(DEBUG_DEV_PKT,
              "dhcpd: MAC %pM hash=0x%08x, base_ip=%u\n",
              mac, hash_value, base_ip);

    // 5. 寻找可用IP（线性探测解决冲突）
    for (int attempt = 0; attempt < max_attempts; attempt++) {
        // 检查IP是否可用
        if (!dhcpd_ip_is_allocated(try_ip)) {
            // 找到可用IP，创建租约
            for (int j = 0; j < DHCPD_MAX_CLIENTS; j++) {
                if (!leases[j].used) {
                    leases[j].used = true;
                    memcpy(leases[j].mac, mac, 6);
                    leases[j].ip.s_addr = htonl(try_ip);

                    debug_cond(DEBUG_DEV_PKT,
                              "dhcpd: allocated %pI4 to %pM (hash-based, attempt=%d)\n",
                              &leases[j].ip, mac, attempt + 1);

                    // 更新next_ip_host为下一个IP（保持向后兼容）
                    next_ip_host = try_ip + 1;
                    if (next_ip_host > end)
                        next_ip_host = start;

                    return leases[j].ip;
                }
            }

            // 没有空闲租约槽位
            debug_cond(DEBUG_DEV_PKT,
                      "dhcpd: no free lease slots for %pM\n", mac);
            break;
        }

        // 检查此IP是否属于此客户端（可能已有租约但未在第一步找到）
        if (dhcpd_ip_allocated_to_mac(try_ip, mac)) {
            // 此IP已分配给此客户端（可能是租约表中的不一致状态）
            debug_cond(DEBUG_DEV_PKT,
                      "dhcpd: IP %u already assigned to %pM (inconsistency)\n",
                      try_ip, mac);

            // 返回此IP
            struct in_addr ip;
            ip.s_addr = htonl(try_ip);
            return ip;
        }

        // 线性探测：尝试下一个IP
        try_ip++;
        if (try_ip > end)
            try_ip = start;

        // 如果回到起点，说明已遍历整个池子
        if (try_ip == base_ip)
            break;
    }

    // 6. 所有IP都被占用，返回池中第一个IP（回退方案）
    debug_cond(DEBUG_DEV_PKT,
              "dhcpd: IP pool exhausted for %pM, using first IP\n", mac);

    for (int j = 0; j < DHCPD_MAX_CLIENTS; j++) {
        if (!leases[j].used) {
            leases[j].used = true;
            memcpy(leases[j].mac, mac, 6);
            leases[j].ip.s_addr = htonl(start);

            next_ip_host = start + 1;
            if (next_ip_host > end)
                next_ip_host = start;

            return leases[j].ip;
        }
    }

    // 7. 极端情况：所有租约槽位都已满
    debug_cond(DEBUG_DEV_PKT,
              "dhcpd: all lease slots and IPs exhausted for %pM\n", mac);

    struct in_addr ip;
    ip.s_addr = htonl(start);  // 返回池中第一个IP
    return ip;
}

/* 为其他可能调用顺序分配的地方添加兼容性，保持原有的顺序分配逻辑，作为回退方案 */
/* static struct in_addr dhcpd_alloc_ip_sequential(const u8 *mac)
{
    u32 start, end;
    int i;

    start = ntohl(string_to_ip(DHCPD_POOL_START_STR).s_addr);
    end = ntohl(string_to_ip(DHCPD_POOL_END_STR).s_addr);

    if (!next_ip_host)
        next_ip_host = start;

    // 尝试分配IP，确保不重复
    for (i = 0; i <= (end - start); i++) {
        u32 try_ip = next_ip_host;

        // 跳过已经分配的IP
        if (dhcpd_ip_is_allocated(try_ip)) {
            next_ip_host++;
            if (next_ip_host > end)
                next_ip_host = start;
            continue;
        }

        // 找到未分配的IP，创建租约
        for (int j = 0; j < DHCPD_MAX_CLIENTS; j++) {
            if (!leases[j].used) {
                leases[j].used = true;
                memcpy(leases[j].mac, mac, 6);
                leases[j].ip.s_addr = htonl(try_ip);

                next_ip_host = try_ip + 1;
                if (next_ip_host > end)
                    next_ip_host = start;

                debug_cond(DEBUG_DEV_PKT, "dhcpd: sequential allocated %pI4 to %pM\n",
                          &leases[j].ip, mac);
                return leases[j].ip;
            }
        }

        next_ip_host++;
        if (next_ip_host > end)
            next_ip_host = start;
    }

    // 所有IP都被分配了，返回池中第一个IP
    debug_cond(DEBUG_DEV_PKT, "dhcpd: pool exhausted, using first IP for %pM\n", mac);
    struct in_addr ip;
    ip.s_addr = htonl(start);
    return ip;
} */

static u8 dhcpd_parse_msg_type(const struct dhcpd_pkt *bp, unsigned int len)
{
	unsigned int fixed = offsetof(struct dhcpd_pkt, vend);
	const u8 *opt;
	unsigned int optlen;

	if (len < fixed + 4)
		return 0;

	opt = (const u8 *)bp->vend;
	optlen = len - fixed;

	if (memcmp(opt, dhcp_magic_cookie, sizeof(dhcp_magic_cookie)))
		return 0;

	opt += 4;
	optlen -= 4;

	while (optlen) {
		u8 code;
		u8 olen;

		code = *opt++;
		optlen--;

		if (code == DHCP_OPTION_PAD)
			continue;
		if (code == DHCP_OPTION_END)
			break;

		if (!optlen)
			break;
		olen = *opt++;
		optlen--;

		if (olen > optlen)
			break;

		if (code == DHCP_OPTION_MSG_TYPE) {
			if (olen >= 1)
				return opt[0];
		}

		opt += olen;
		optlen -= olen;
	}

	return 0;
}

static bool dhcpd_parse_req_ip(const struct dhcpd_pkt *bp, unsigned int len,
			      struct in_addr *req_ip)
{
	unsigned int fixed = offsetof(struct dhcpd_pkt, vend);
	const u8 *opt;
	unsigned int optlen;

	if (len < fixed + 4)
		return false;

	opt = (const u8 *)bp->vend;
	optlen = len - fixed;

	if (memcmp(opt, dhcp_magic_cookie, sizeof(dhcp_magic_cookie)))
		return false;

	opt += 4;
	optlen -= 4;

	while (optlen) {
		u8 code;
		u8 olen;

		code = *opt++;
		optlen--;

		if (code == DHCP_OPTION_PAD)
			continue;
		if (code == DHCP_OPTION_END)
			break;

		if (!optlen)
			break;
		olen = *opt++;
		optlen--;

		if (olen > optlen)
			break;

		if (code == DHCP_OPTION_REQ_IPADDR && olen == 4) {
			memcpy(&req_ip->s_addr, opt, 4);
			return true;
		}

		opt += olen;
		optlen -= olen;
	}

	return false;
}

static u8 *dhcpd_opt_add_u8(u8 *p, u8 code, u8 val)
{
	*p++ = code;
	*p++ = 1;
	*p++ = val;
	return p;
}

static u8 *dhcpd_opt_add_u32(u8 *p, u8 code, __be32 val)
{
	*p++ = code;
	*p++ = 4;
	memcpy(p, &val, 4);
	return p + 4;
}

static u8 *dhcpd_opt_add_inaddr(u8 *p, u8 code, struct in_addr addr)
{
	return dhcpd_opt_add_u32(p, code, addr.s_addr);
}

static int dhcpd_send_reply(const struct dhcpd_pkt *req, unsigned int req_len,
			    u8 dhcp_msg_type, struct in_addr yiaddr, const char *nak_message)
{
	struct dhcpd_pkt *bp;
	struct in_addr server_ip, netmask, gw, dns;
	struct in_addr bcast;
	uchar *pkt;
	uchar *payload;
	int eth_hdr_size;
	u8 *opt;
	int payload_len;
	__be32 lease;

	(void)req_len;

	server_ip = dhcpd_get_server_ip();

	/* 对于NAK，不需要网络配置信息 */
	if (dhcp_msg_type != DHCPNAK) {
		netmask = dhcpd_get_netmask();
		gw = dhcpd_get_gateway();
		dns = dhcpd_get_dns();
	}

	bcast.s_addr = 0xFFFFFFFF;

	pkt = net_tx_packet;
	eth_hdr_size = net_set_ether(pkt, net_bcast_ethaddr, PROT_IP);
	net_set_udp_header(pkt + eth_hdr_size, bcast,
			   DHCPD_CLIENT_PORT, DHCPD_SERVER_PORT, 0);

	payload = pkt + eth_hdr_size + IP_UDP_HDR_SIZE;
	bp = (struct dhcpd_pkt *)payload;
	memset(bp, 0, sizeof(*bp));

	bp->op = BOOTREPLY;
	bp->htype = HTYPE_ETHER;
	bp->hlen = HLEN_ETHER;
	bp->hops = 0;
	bp->xid = req->xid;
	bp->secs = req->secs;
	bp->flags = htons(DHCP_FLAG_BROADCAST);
	bp->ciaddr = 0;

	/* 对于NAK，yiaddr设为0 */
	if (dhcp_msg_type == DHCPNAK) {
		bp->yiaddr = 0;
		bp->siaddr = 0;
	} else {
		bp->yiaddr = yiaddr.s_addr;
		bp->siaddr = server_ip.s_addr;
	}

	bp->giaddr = 0;
	memcpy(bp->chaddr, req->chaddr, sizeof(bp->chaddr));

	opt = (u8 *)bp->vend;
	memcpy(opt, dhcp_magic_cookie, sizeof(dhcp_magic_cookie));
	opt += 4;

	opt = dhcpd_opt_add_u8(opt, DHCP_OPTION_MSG_TYPE, dhcp_msg_type);

	/* 对于NAK，只包含Server Identifier和Message选项 */
	if (dhcp_msg_type == DHCPNAK) {
		opt = dhcpd_opt_add_inaddr(opt, DHCP_OPTION_SERVER_ID, server_ip);

		/* 添加NAK消息（如果有） */
		if (nak_message && *nak_message) {
			int msg_len = strlen(nak_message);
			if (msg_len > 0 && msg_len <= 255) {
				*opt++ = DHCP_OPTION_MESSAGE;
				*opt++ = msg_len;
				memcpy(opt, nak_message, msg_len);
				opt += msg_len;
			}
		}
	} else {
		/* 对于OFFER/ACK，包含完整的网络配置 */
		opt = dhcpd_opt_add_inaddr(opt, DHCP_OPTION_SERVER_ID, server_ip);
		opt = dhcpd_opt_add_inaddr(opt, DHCP_OPTION_SUBNET_MASK, netmask);
		opt = dhcpd_opt_add_inaddr(opt, DHCP_OPTION_ROUTER, gw);
		opt = dhcpd_opt_add_inaddr(opt, DHCP_OPTION_DNS_SERVER, dns);

		lease = htonl(3600);
		opt = dhcpd_opt_add_u32(opt, DHCP_OPTION_LEASE_TIME, lease);
	}

	*opt++ = DHCP_OPTION_END;

	payload_len = (int)((uintptr_t)opt - (uintptr_t)payload);
    if (payload_len < DHCPD_MIN_BOOTP_LEN)
		payload_len = DHCPD_MIN_BOOTP_LEN;

	/* Update UDP header with actual payload length */
	net_set_udp_header(pkt + eth_hdr_size, bcast,
			   DHCPD_CLIENT_PORT, DHCPD_SERVER_PORT, payload_len);

	net_send_packet(pkt, eth_hdr_size + IP_UDP_HDR_SIZE + payload_len);

	return 0;
}

/* 解析 Server Identifier 选项 */
static bool dhcpd_parse_server_id(const struct dhcpd_pkt *bp, unsigned int len,
                                 struct in_addr *server_id)
{
    unsigned int fixed = offsetof(struct dhcpd_pkt, vend);
    const u8 *opt;
    unsigned int optlen;

    if (len < fixed + 4)
        return false;

    opt = (const u8 *)bp->vend;
    optlen = len - fixed;

    if (memcmp(opt, dhcp_magic_cookie, sizeof(dhcp_magic_cookie)))
        return false;

    opt += 4;
    optlen -= 4;

    while (optlen) {
        u8 code;
        u8 olen;

        code = *opt++;
        optlen--;

        if (code == DHCP_OPTION_PAD)
            continue;
        if (code == DHCP_OPTION_END)
            break;

        if (!optlen)
            break;
        olen = *opt++;
        optlen--;

        if (olen > optlen)
            break;

        if (code == DHCP_OPTION_SERVER_ID && olen == 4) {
            memcpy(&server_id->s_addr, opt, 4);
            return true;
        }

        opt += olen;
        optlen -= olen;
    }

    return false;
}

/* 验证 DHCP 请求的有效性 */
static bool dhcpd_validate_request(const u8 *client_mac, struct in_addr req_ip,
                                  const char **nak_msg)
{
    u32 ip_host = ntohl(req_ip.s_addr);

    // 检查请求的IP是否在我们的子网内
    struct in_addr netmask = dhcpd_get_netmask();
    struct in_addr server_ip = dhcpd_get_server_ip();
    u32 network = server_ip.s_addr & netmask.s_addr;
    u32 req_network = req_ip.s_addr & netmask.s_addr;

    if (req_network != network) {
        *nak_msg = "requested address not on local network";
        return true;  // 需要发送NAK
    }

    // 检查请求的IP是否在我们的IP池中
    if (!dhcpd_ip_in_pool(ip_host)) {
        *nak_msg = "requested address not available";
        return true;  // 需要发送NAK
    }

    // 检查这个IP是否已经被其他MAC地址占用
    if (dhcpd_ip_is_allocated(ip_host) &&
        !dhcpd_ip_allocated_to_mac(ip_host, client_mac)) {
        *nak_msg = "requested address already assigned";
        return true;  // 需要发送NAK
    }

    return false;  // 请求有效
}

/* 处理租约（创建或更新） */
static struct in_addr dhcpd_process_lease(const u8 *client_mac, struct in_addr req_ip)
{
    struct dhcpd_lease *lease = dhcpd_find_lease(client_mac);
	u32 ip_host = ntohl(req_ip.s_addr);

    // 首先检查请求的IP是否已被其他客户端占用
    if (dhcpd_ip_is_allocated(ip_host) &&
        !dhcpd_ip_allocated_to_mac(ip_host, client_mac)) {
        // IP已被其他客户端占用，不能分配
        debug_cond(DEBUG_DEV_PKT,
                  "dhcpd: cannot assign %pI4 to %pM - already assigned to another client\n",
                  &req_ip, client_mac);
        // 返回一个错误指示或分配新IP
        return dhcpd_alloc_ip(client_mac);
    }

	// 查找现有租约
    if (lease) {
        // 更新现有租约的IP
        lease->ip = req_ip;
        debug_cond(DEBUG_DEV_PKT, "dhcpd: renew lease %pI4 for %pM\n", &req_ip, client_mac);
    } else {
        // 创建新租约
        for (int i = 0; i < DHCPD_MAX_CLIENTS; i++) {
            if (!leases[i].used) {
                leases[i].used = true;
                memcpy(leases[i].mac, client_mac, 6);
                leases[i].ip = req_ip;
                debug_cond(DEBUG_DEV_PKT, "dhcpd: new lease %pI4 for %pM\n", &req_ip, client_mac);
                break;
            }
        }
    }

    return req_ip;
}

/* 处理 DHCPREQUEST 消息 */
static int dhcpd_handle_request(const struct dhcpd_pkt *bp, unsigned int len)
{
    struct in_addr req_ip, yiaddr, server_id;
    bool send_nak = false;
    const char *nak_msg = NULL;

    // 检查请求是否针对我们的服务器
    if (dhcpd_parse_server_id(bp, len, &server_id)) {
        struct in_addr our_server_ip = dhcpd_get_server_ip();
        if (server_id.s_addr != our_server_ip.s_addr) {
            debug_cond(DEBUG_DEV_PKT,
                      "dhcpd: request for server %pI4, ignoring (we are %pI4)\n",
                      &server_id, &our_server_ip);
            return -1;  // 不是给我们的请求，忽略
        }
    }

    // 解析请求的IP地址
    if (!dhcpd_parse_req_ip(bp, len, &req_ip)) {
        // 没有指定请求IP，分配新IP
        yiaddr = dhcpd_alloc_ip(bp->chaddr);
        goto send_ack;
    }

    // 验证请求的IP地址
    send_nak = dhcpd_validate_request(bp->chaddr, req_ip, &nak_msg);
    if (send_nak) {
        goto send_nak;
    }

    // 请求有效，处理租约
    yiaddr = dhcpd_process_lease(bp->chaddr, req_ip);

send_ack:
    debug_cond(DEBUG_DEV_PKT, "dhcpd: ACK %pI4 to %pM\n", &yiaddr, bp->chaddr);
    dhcpd_send_reply(bp, len, DHCPACK, yiaddr, NULL);
    return 0;

send_nak:
    debug_cond(DEBUG_DEV_PKT, "dhcpd: NAK to %pM: %s\n", bp->chaddr, nak_msg ? nak_msg : "");
    dhcpd_send_reply(bp, len, DHCPNAK, (struct in_addr){0}, nak_msg);
    return 0;
}

/* 处理 DHCPDISCOVER 消息 */
static struct in_addr dhcpd_handle_discover(const u8 *client_mac)
{
    // 查找现有租约
    struct dhcpd_lease *lease = dhcpd_find_lease(client_mac);

    if (lease) {
        // 检查租约中的IP是否仍然可用（未被其他客户端占用）
        u32 ip_host = ntohl(lease->ip.s_addr);

        if (!dhcpd_ip_is_allocated(ip_host) ||
            dhcpd_ip_allocated_to_mac(ip_host, client_mac)) {
            // IP可用或仍属于此客户端
            debug_cond(DEBUG_DEV_PKT,
                      "dhcpd: existing lease %pI4 for %pM\n",
                      &lease->ip, client_mac);
            return lease->ip;
        } else {
            // IP已被其他客户端占用，重新分配
            debug_cond(DEBUG_DEV_PKT,
                      "dhcpd: existing lease IP %pI4 taken by another client, reallocating\n",
                      &lease->ip);

            // 删除旧租约（标记为未使用）
            for (int i = 0; i < DHCPD_MAX_CLIENTS; i++) {
                if (leases[i].used && dhcpd_mac_equal(leases[i].mac, client_mac)) {
                    leases[i].used = false;
                    memset(leases[i].mac, 0, 6);
                    break;
                }
            }
        }
    }

    // 新客户端或需要重新分配，使用基于MAC的分配
    debug_cond(DEBUG_DEV_PKT, "dhcpd: new/relocating client %pM\n", client_mac);
    return dhcpd_alloc_ip(client_mac);
}

static void dhcpd_handle_packet(uchar *pkt, unsigned int dport,
                               struct in_addr sip, unsigned int sport,
                               unsigned int len)
{
    const struct dhcpd_pkt *bp = (const struct dhcpd_pkt *)pkt;
    u8 msg_type;
    struct in_addr yiaddr;

    (void)sip;

    if (!dhcpd_running)
        return;

    if (dport != DHCPD_SERVER_PORT || sport != DHCPD_CLIENT_PORT)
        return;

    if (len < offsetof(struct dhcpd_pkt, vend))
        return;

    if (bp->op != BOOTREQUEST)
        return;

    if (bp->htype != HTYPE_ETHER || bp->hlen != HLEN_ETHER)
        return;

    msg_type = dhcpd_parse_msg_type(bp, len);
    if (!msg_type)
        return;

    debug_cond(DEBUG_DEV_PKT, "dhcpd: msg=%u from %pM\n", msg_type, bp->chaddr);

    switch (msg_type) {
    case DHCPDISCOVER:
        yiaddr = dhcpd_handle_discover(bp->chaddr);
        debug_cond(DEBUG_DEV_PKT, "dhcpd: offer %pI4 to %pM\n", &yiaddr, bp->chaddr);
        dhcpd_send_reply(bp, len, DHCPOFFER, yiaddr, NULL);
        break;

    case DHCPREQUEST:
        dhcpd_handle_request(bp, len);
        break;

    default:
        break;
    }
}

static void dhcpd_udp_handler(uchar *pkt, unsigned int dport,
			     struct in_addr sip, unsigned int sport,
			     unsigned int len)
{
	dhcpd_handle_packet(pkt, dport, sip, sport, len);

	if (prev_udp_handler)
		prev_udp_handler(pkt, dport, sip, sport, len);
}

int dhcpd_start(void)
{
	struct in_addr pool_start;

	/*
	 * Be robust against net_init()/net_clear_handlers() resetting handlers.
	 * If we're already running but the UDP handler is no longer ours, re-hook.
	 */
	if (dhcpd_running) {
		rxhand_f *cur = net_get_udp_handler();

		if (cur != dhcpd_udp_handler) {
			prev_udp_handler = cur;
			net_set_udp_handler(dhcpd_udp_handler);
		}
		return 0;
	}

	/* Ensure we have a usable local IP, otherwise UDP replies will use 0.0.0.0 */
	if (!net_ip.s_addr)
		net_ip = string_to_ip(DHCPD_DEFAULT_IP_STR);
	if (!net_netmask.s_addr)
		net_netmask = string_to_ip(DHCPD_DEFAULT_NETMASK_STR);
	if (!net_gateway.s_addr)
		net_gateway = net_ip;
	if (!net_dns_server.s_addr)
		net_dns_server = net_ip;

	memset(leases, 0, sizeof(leases));

	pool_start = string_to_ip(DHCPD_POOL_START_STR);
	next_ip_host = ntohl(pool_start.s_addr);

	prev_udp_handler = net_get_udp_handler();
	net_set_udp_handler(dhcpd_udp_handler);

	dhcpd_running = true;

	return 0;
}

void dhcpd_stop(void)
{
	if (!dhcpd_running)
		return;

	/*
	 * If the network loop already cleared handlers, don't resurrect another
	 * handler here. We only restore the previous handler if we are still
	 * installed.
	 */
	if (net_get_udp_handler() == dhcpd_udp_handler)
		net_set_udp_handler(prev_udp_handler);
	prev_udp_handler = NULL;
	dhcpd_running = false;
}
