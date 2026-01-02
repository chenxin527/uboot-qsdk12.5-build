/*
 * NAT46 core definitions
 *
 * Copyright (c) 2013-2014 Andrew Yourtchenko <ayourtch@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2
 * as published by the Free Software Foundation
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 */

#ifndef __NAT46_CORE_H__
#define __NAT46_CORE_H__

#include "nat46-glue.h"

// #define nat46debug(level, format, ...) debug(DBG_V6, level, format, __VA_ARGS__)
// #define nat46debug(level, format, ...)
#define nat46debug(level, format, ...) do { if(nat46->debug >= level) { printk(format "\n", ##__VA_ARGS__); } } while (0)

#define U8_MASK (uint8_t)(0xFF)
#define U32_MASK (uint32_t)(~0U)
#define BITS_PER_BYTE 8
#define PSID_LEN_MAX 16
#define NUM_RULE_PAIRS_MAX 32
#define IPV4_BITS_MAX 32
#define EA_LEN_MAX 48
#define IPV6_BITS_MAX 128

#define IPV6HDRSIZE 40
#define IPV4HDRSIZE 20
#define IPV6V4HDRDELTA (IPV6HDRSIZE - IPV4HDRSIZE)

/* Flag definations for MAP-T */
#define ADD_DUMMY_HEADER 0x01

/* 
 * A generic v4<->v6 translation structure.
 * The currently supported translation styles:
 */

typedef enum {
  NAT46_XLATE_NONE = 0,
  NAT46_XLATE_MAP,
  NAT46_XLATE_MAP0,
  NAT46_XLATE_RFC6052
} nat46_xlate_style_t;

/*
 * Enumeration for sorting pairs based on
 * type of prefix length.
 */

typedef enum {
  NAT46_IPV4_LOCAL = 0,
  NAT46_IPV4_REMOTE,
  NAT46_IPV6_LOCAL,
  NAT46_IPV6_REMOTE
} nat46_rule_type_t;

#define NAT46_SIGNATURE 0x544e3634
#define FREED_NAT46_SIGNATURE 0xdead544e
     
typedef struct nat46_xlate_rule {
  nat46_xlate_style_t style;
  struct in6_addr v6_pref;
  int 		  v6_pref_len;
  u32		  v4_pref;
  int             v4_pref_len;
  int		  ea_len;
  int             psid_offset;
  int             fmr_flag;
} nat46_xlate_rule_t;

typedef struct nat46_xlate_rulepair {
  nat46_xlate_rule_t local;
  nat46_xlate_rule_t remote;
} nat46_xlate_rulepair_t;

typedef struct {
  u32 sig; /* nat46 signature */
  int refcount;
  int debug;

  int npairs;
  nat46_xlate_rulepair_t pairs[NUM_RULE_PAIRS_MAX]; /* npairs */
  nat46_xlate_rulepair_t sorted_ipv4_local_pairs[NUM_RULE_PAIRS_MAX]; /* npairs */
  nat46_xlate_rulepair_t sorted_ipv4_remote_pairs[NUM_RULE_PAIRS_MAX]; /* npairs */
  nat46_xlate_rulepair_t sorted_ipv6_local_pairs[NUM_RULE_PAIRS_MAX]; /* npairs */
  nat46_xlate_rulepair_t sorted_ipv6_remote_pairs[NUM_RULE_PAIRS_MAX]; /* npairs */
} nat46_instance_t;

void nat46_ipv6_input(struct sk_buff *old_skb);
void nat46_ipv4_input(struct sk_buff *old_skb);

int nat46_set_ipair_config(nat46_instance_t *nat46, int ipair, char *buf, int count);
int nat46_set_config(nat46_instance_t *nat46, char *buf, int count);

int nat46_get_ipair_config(nat46_instance_t *nat46, int ipair, char *buf, int count);
int nat46_get_config(nat46_instance_t *nat46, char *buf, int count);

char *get_next_arg(char **ptail);
nat46_instance_t *get_nat46_instance(struct sk_buff *sk);

nat46_instance_t *alloc_nat46_instance(int npairs, nat46_instance_t *old, int from_ipair, int to_ipair); 
void release_nat46_instance(nat46_instance_t *nat46);

int xlate_6_to_4(struct net_device *dev, struct ipv6hdr *ip6h, uint16_t proto, __u32 *pv4saddr, __u32 *pv4daddr);
int xlate_4_to_6(struct net_device *dev, struct iphdr *hdr4, int sport, int dport, void *v6saddr, void *v6daddr);
bool nat46_get_rule_config(struct net_device *dev, nat46_xlate_rulepair_t **nat46_rule_pair, int *count);
int nat46_get_npairs(struct net_device *dev);
bool nat46_get_info(struct net_device *dev, nat46_xlate_rulepair_t **nat46_rule_pair,
		int *count, u8 *flag);

#endif
