/*
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

#define NAT46_DEVICE_SIGNATURE 0x544e36dd

int nat46_create(char *devname);
int nat46_destroy(char *devname);
int nat46_insert(char *devname, char *buf);
int nat46_configure(char *devname, char *buf);
void nat46_destroy_all(void);
void nat64_show_all_configs(struct seq_file *m);
void nat46_netdev_count_xmit(struct sk_buff *skb, struct net_device *dev);
void *netdev_nat46_instance(struct net_device *dev);

void nat46_update_stats(struct net_device *dev, uint32_t rx_packets, uint32_t rx_bytes, uint32_t tx_packets, uint32_t tx_bytes, 
							uint32_t rx_dropped, uint32_t tx_dropped);
bool is_map_t_dev(struct net_device *dev);

