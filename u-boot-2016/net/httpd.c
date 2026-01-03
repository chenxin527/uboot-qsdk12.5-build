/*
 *	Copyright 1994, 1995, 2000 Neil Russell.
 *	(See License)
 *	Copyright 2000, 2001 DENX Software Engineering, Wolfgang Denk, wd@denx.de
 */

#include <common.h>
#include <command.h>
#include <net.h>
#include <asm/byteorder.h>
#include "httpd.h"

#include "../httpd/uipopt.h"
#include "../httpd/uip.h"
#include "../httpd/uip_arp.h"
#include <ipq_api.h>
#include <asm/gpio.h>
#include <asm/arch-qca-common/smem.h>

static int arptimer = 0;
struct in_addr net_httpd_ip;

// start http daemon
void HttpdStart(void) {
	struct uip_eth_addr eaddr;
	unsigned short int ip[2];
	ulong tmp_ip_addr = ntohl(net_ip.s_addr);

	printf("HTTP server is starting at IP: %ld.%ld.%ld.%ld\n",
		(tmp_ip_addr & 0xff000000) >> 24,
		(tmp_ip_addr & 0x00ff0000) >> 16,
		(tmp_ip_addr & 0x0000ff00) >> 8,
		(tmp_ip_addr & 0x000000ff));

	eaddr.addr[0] = net_ethaddr[0];
	eaddr.addr[1] = net_ethaddr[1];
	eaddr.addr[2] = net_ethaddr[2];
	eaddr.addr[3] = net_ethaddr[3];
	eaddr.addr[4] = net_ethaddr[4];
	eaddr.addr[5] = net_ethaddr[5];
	// set MAC address
	uip_setethaddr(eaddr);

	uip_init();
	httpd_init();

	ip[0] =  htons((tmp_ip_addr & 0xFFFF0000) >> 16);
	ip[1] = htons(tmp_ip_addr & 0x0000FFFF);

	uip_sethostaddr(ip);

	printf("done set host addr 0x%x 0x%x\n", uip_hostaddr[0], uip_hostaddr[1]);
	// set network mask (255.255.255.0 -> local network)
	ip[0] = htons((0xFFFFFF00 & 0xFFFF0000) >> 16);
	ip[1] = htons(0xFFFFFF00 & 0x0000FFFF);

	net_netmask.s_addr = 0x00FFFFFF;
	uip_setnetmask(ip);

	// should we also set default router ip address?
	//uip_setdraddr();
	do_http_progress(WEBFAILSAFE_PROGRESS_START);
	webfailsafe_is_running = 1;
}

void HttpdStop(void) {
	webfailsafe_is_running = 0;
	webfailsafe_ready_for_upgrade = 0;
	webfailsafe_upgrade_type = WEBFAILSAFE_UPGRADE_TYPE_FIRMWARE;
	do_http_progress(WEBFAILSAFE_PROGRESS_UPGRADE_FAILED);
}

void HttpdDone(void) {
	webfailsafe_is_running = 0;
	webfailsafe_ready_for_upgrade = 0;
	webfailsafe_upgrade_type = WEBFAILSAFE_UPGRADE_TYPE_FIRMWARE;
	do_http_progress(WEBFAILSAFE_PROGRESS_UPGRADE_READY);
}

#ifdef CONFIG_MD5
#include <u-boot/md5.h>

void printChecksumMd5(int address, unsigned int size)
{
	void *buf = (void*)(address);
	int i = 0;
	u8 output[16];
	md5_wd(buf, size, output, CHUNKSZ_MD5);
	printf("md5 for 0x%08x ... 0x%08x ==> ", address, address + size);
	for (i = 0; i < 16; i++)
		printf("%02x", output[i] & 0xFF);
	printf("\n");
}
#else
void printChecksumMd5(int address, unsigned int size)
{
}
#endif

int do_http_upgrade(const ulong size, const int upgrade_type) {
	char buf[576];
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;
	int fw_type = check_fw_type((void *)WEBFAILSAFE_UPLOAD_RAM_ADDRESS);

	//printf checksum if defined
	printChecksumMd5(WEBFAILSAFE_UPLOAD_RAM_ADDRESS, size);

	// include/ipq_api.h
	// WEBFAILSAFE_UPLOAD_RAM_ADDRESS = 0x50000000 为了可以上传更大的固件，将上传地址从 0x44000000 改为 0x50000000 避免内存 crash 重启
	// FW_TYPE_EMMC	              这个是 eMMC 的 GPT 分区表或镜像，只要开头有GPT信息即可
	// FW_TYPE_JDCLOUD	          这个是 JDCloud 官方原厂固件
	// FW_TYPE_UBI	              这个是 UBI 固件，eMMC 没有 UBI 固件
	// FW_TYPE_CDT                这个是 CDT 文件
	// FW_TYPE_ELF                这个是 ELF 文件 (除了 U-Boot 外, SBL1, QSEE, RPM, DEVCFG 也是 ELF 文件)
	// FW_TYPE_FACTORY_KERNEL6M	  这个是 Factory 格式的固件 (Kernel 大小: 6MB)
	// FW_TYPE_FACTORY_KERNEL12M  这个是 Factory 格式的固件 (Kernel 大小: 12MB)
	// FW_TYPE_FIT                这个是 FIT Image，包括 Factory Image 和 FIT uImage

	switch (upgrade_type) {
		case WEBFAILSAFE_UPGRADE_TYPE_FIRMWARE:
			if (sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
				if (fw_type == FW_TYPE_FACTORY_KERNEL6M) {
					printf("\n\n******************************\n* FACTORY FIRMWARE UPGRADING *\n* FIRMWARE KERNEL SIZE: 6MB  *\n*  DO NOT POWER OFF DEVICE!  *\n******************************\n\n");
					sprintf(buf,
						"flash 0:HLOS 0x%lx 0x%lx && flash rootfs 0x%lx 0x%lx && "
						"bootconfig set primary",
						// factory.bin 由 kernel + rootfs 组成，其中 kernel 固定 6MB 大小
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS,
						(ulong)0x600000,
						(ulong)(WEBFAILSAFE_UPLOAD_RAM_ADDRESS + 0x600000),
						(ulong)(size - 0x600000));
				} else if (fw_type == FW_TYPE_FACTORY_KERNEL12M) {
					printf("\n\n******************************\n* FACTORY FIRMWARE UPGRADING *\n* FIRMWARE KERNEL SIZE: 12MB *\n*  DO NOT POWER OFF DEVICE!  *\n******************************\n\n");
					sprintf(buf,
						"flash 0:HLOS 0x%lx 0x%lx && flash rootfs 0x%lx 0x%lx && "
						"bootconfig set primary",
						// factory.bin 由 kernel + rootfs 组成，其中 kernel 固定 12MB 大小
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS,
						(ulong)0xC00000,
						(ulong)(WEBFAILSAFE_UPLOAD_RAM_ADDRESS + 0xC00000),
						(ulong)(size - 0xC00000));
				} else if (fw_type == FW_TYPE_JDCLOUD) {
					printf("\n\n*******************************\n* JDCLOUD FIRMWARE UPGRADING  *\n*  DO NOT POWER OFF DEVICE!   *\n*******************************\n\n");
					sprintf(buf,
						"imxtract 0x%lx hlos-0cc33b23252699d495d79a843032498bfa593aba && flash 0:HLOS $fileaddr $filesize && imxtract 0x%lx rootfs-f3c50b484767661151cfb641e2622703e45020fe && flash rootfs $fileaddr $filesize && imxtract 0x%lx wififw-45b62ade000c18bfeeb23ae30e5a6811eac05e2f && flash 0:WIFIFW $fileaddr $filesize && flasherase rootfs_data && "
						"bootconfig set primary",
						// 执行 imxtract 时不带目标地址，则不进行复制，但会修改环境变量 $fileaddr $filesize，可以直接用
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS,
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS,
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS);
				} else if (fw_type == FW_TYPE_SYSUPGRADE) {
					printf("\n\n*********************************\n* SYSUPGRADE FIRMWARE UPGRADING *\n*   DO NOT POWER OFF DEVICE!    *\n*********************************\n\n");
					sprintf(buf,
						"untar 0x%lx 0x%lx && flash 0:HLOS $kernel_addr $kernel_size && flash rootfs $rootfs_addr $rootfs_size && "
						"bootconfig set primary",
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS,
						(ulong)size);
				} else {
					return (-1);
				}
			} else {
				printf("\n\n* Update FIRMWARE is NOT supported for this FLASH TYPE yet!! *\n\n");
				return (-1);
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_UBOOT:
			printf("\n\n****************************\n*     U-BOOT UPGRADING     *\n* DO NOT POWER OFF DEVICE! *\n****************************\n\n");
			if (sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
				if (fw_type == FW_TYPE_ELF) {
					sprintf(buf,
						"flash 0:APPSBL 0x%lx $filesize && flash 0:APPSBL_1 0x%lx $filesize",
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS,
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS);
				} else {
					return (-1);
				}
			} else {
				printf("\n\n* Update U-boot is NOT supported for this FLASH TYPE yet!! *\n\n");
				return (-1);
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_ART:
			printf("\n\n****************************\n*      ART  UPGRADING      *\n* DO NOT POWER OFF DEVICE! *\n****************************\n\n");
			if (sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
				sprintf(buf,
					"flash 0:ART 0x%lx $filesize",
					(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS);
			} else {
				printf("\n\n* Update ART is NOT supported for this FLASH TYPE yet!! *\n\n");
				return (-1);
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_IMG:
			printf("\n\n****************************\n*      IMG  UPGRADING      *\n* DO NOT POWER OFF DEVICE! *\n****************************\n\n");
			if (sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
				if (fw_type == FW_TYPE_EMMC) {
					sprintf(buf,
						"mmc erase 0x0 0x%lx && mmc write 0x%lx 0x0 0x%lx",
						(ulong)((size - 1) / 512 + 1),
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS,
						(ulong)((size - 1) / 512 + 1));
				} else {
					return (-1);
				}
			} else {
				printf("\n\n* Update IMG is NOT supported for this FLASH TYPE yet!! *\n\n");
				return (-1);
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_CDT:
			printf("\n\n****************************\n*      CDT  UPGRADING      *\n* DO NOT POWER OFF DEVICE! *\n****************************\n\n");
			if (sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
				if (fw_type == FW_TYPE_CDT) {
					sprintf(buf,
						"flash 0:CDT 0x%lx $filesize && flash 0:CDT_1 0x%lx $filesize",
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS,
						(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS);
				} else {
					return (-1);
				}
			} else {
				printf("\n\n* Update CDT is NOT supported for this FLASH TYPE yet!! *\n\n");
				return (-1);
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_UIMAGE:
			printf("\n\n****************************\n*      UIMAGE BOOTING      *\n* DO NOT POWER OFF DEVICE! *\n****************************\n\n");
			if (fw_type == FW_TYPE_FIT) {
				sprintf(buf,
					"bootm 0x%lx",
					(ulong)WEBFAILSAFE_UPLOAD_RAM_ADDRESS);
			} else {
				return (-1);
			}
			break;
		default:
			return (-1);
	}

	printf("Executing: %s\n\n", buf);

	return (run_command(buf, 0));
}

// info about current progress of failsafe mode
int do_http_progress(const int state) {
	/* toggle LED's here */
	switch(state) {
		case WEBFAILSAFE_PROGRESS_START:
			led_off("power_led");
			led_on("blink_led");
			led_off("system_led");
			printf("HTTP server is ready!\n\n");
			break;

		case WEBFAILSAFE_PROGRESS_TIMEOUT:
			//printf("Waiting for request...\n");
			break;

		case WEBFAILSAFE_PROGRESS_UPLOAD_READY:
			printf("HTTP upload is done! Upgrading...\n");
			break;

		case WEBFAILSAFE_PROGRESS_UPGRADE_READY:
			led_off("power_led");
			led_off("blink_led");
			led_on("system_led");
			printf("HTTP upgrade is done! Rebooting...\n\n");
			mdelay(3000);
			break;

		case WEBFAILSAFE_PROGRESS_UPGRADE_FAILED:
			led_on("power_led");
			led_off("blink_led");
			led_off("system_led");
			printf("## Error: HTTP upgrade failed!\n\n");
			break;
	}

	return 0;
}

void NetSendHttpd(void) {

	volatile uchar *tmpbuf = net_tx_packet;
	int i;

	for (i = 0; i < 40 + UIP_LLH_LEN; i++) {

		tmpbuf[i] = uip_buf[i];
	}

	for (; i < uip_len; i++) {

		tmpbuf[i] = uip_appdata[i - 40 - UIP_LLH_LEN];
	}

	eth_send(net_tx_packet, uip_len);
}

void NetReceiveHttpd(volatile uchar * inpkt, int len) {

	memcpy(uip_buf, (const void *)inpkt, len);
	uip_len = len;
	struct uip_eth_hdr * tmp = (struct uip_eth_hdr *)&uip_buf[0];
	if (tmp->type == htons(UIP_ETHTYPE_IP)) {
		uip_arp_ipin();
		uip_input();

		if (uip_len > 0) {
			uip_arp_out();
			NetSendHttpd();
		}
	} else if (tmp->type == htons(UIP_ETHTYPE_ARP)) {
		uip_arp_arpin();

		if (uip_len > 0)
			NetSendHttpd();
	}
}

void HttpdHandler(void) {
	int i;

	for (i = 0; i < UIP_CONNS; i++) {
		uip_periodic(i);

		if (uip_len > 0) {
			uip_arp_out();
			NetSendHttpd();
		}
	}

	if (++arptimer == 20) {
		uip_arp_timer();
		arptimer = 0;
	}
}
