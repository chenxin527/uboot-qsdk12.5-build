/*
* Copyright (c) 2016-2020, The Linux Foundation. All rights reserved.
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License version 2 and
* only version 2 as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*/

#include <common.h>
#include <asm/global_data.h>
#include <asm/io.h>
#include <asm/errno.h>
#include <environment.h>
#include <fdtdec.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/uart.h>
#include <asm/arch-qca-common/scm.h>
#include <asm/arch-qca-common/iomap.h>
#include <ipq5018.h>
#include <spi.h>
#include <spi_flash.h>
#if defined(CONFIG_ART_COMPRESSED) &&   \
        (defined(CONFIG_GZIP) || defined(CONFIG_LZMA))
#ifndef CONFIG_COMPRESSED_LOAD_ADDR
#define CONFIG_COMPRESSED_LOAD_ADDR CONFIG_SYS_LOAD_ADDR
#endif
#include <mapmem.h>
#include <lzma/LzmaTools.h>
#endif
#ifdef CONFIG_QCA_MMC
#include <mmc.h>
#include <sdhci.h>
#endif
#ifdef CONFIG_USB_XHCI_IPQ
#include <usb.h>
#endif
#ifdef CONFIG_QPIC_NAND
#include <asm/arch-qca-common/qpic_nand.h>
#include <nand.h>
#endif
#ifdef CONFIG_IPQ_BT_SUPPORT
#include <malloc.h>
#include "bt.h"
#include "bt_binary_array.h"
#include <linux/compat.h>
#endif

#define DLOAD_MAGIC_COOKIE	BIT(4)

#define TCSR_SOC_HW_VERSION_REG 0x194D000

ipq_gmac_board_cfg_t gmac_cfg[CONFIG_IPQ_NO_MACS];

DECLARE_GLOBAL_DATA_PTR;

#ifdef CONFIG_QCA_MMC
struct sdhci_host mmc_host;
#endif

#ifdef CONFIG_MTD_DEVICE
extern int ipq_spi_init(u16);
#endif

extern void ppe_uniphy_set_forceMode(void);
extern void ppe_uniphy_refclk_set(void);

unsigned int qpic_frequency = 0, qpic_phase = 0;

const char *rsvd_node = "/reserved-memory";
const char *del_node[] = {"uboot",
			  "sbl",
			  NULL};
const add_node_t add_fdt_node[] = {{}};

struct dumpinfo_t dumpinfo_n[] = {
	/* TZ stores the DDR physical address at which it stores the
	 * APSS regs, UTCM copy dump. We will have the TZ IMEM
	 * IMEM Addr at which the DDR physical address is stored as
	 * the start
	 *     --------------------
         *     |  DDR phy (start) | ----> ------------------------
         *     --------------------       | APSS regsave (8k)    |
         *                                ------------------------
         *                                |                      |
	 *                                | 	 UTCM copy	 |
         *                                |        (192k)        |
	 *                                |                      |
         *                                ------------------------
	 *				  |			 |
	 *				  |	BTRAM Copy	 |
	 *				  |	  (352k)	 |
	 *				  |			 |
	 *				  ------------------------
	 */
	{ "EBICS0.BIN", 0x40000000, 0x10000000, 0 },
	/*
	 * The below 3 config enable compress crash dump support.
	 * the RAM region will be split in 3 section and collect based on the
	 * config as given below. NOT SUPPORT IN  TINY_NOR profile.
	 * Note : EBICS2.BIN start and size varies dynamically based on RAM size.
	 *  basically it's seconds half of ram region.
	*/
#ifndef CONFIG_IPQ_TINY
	{ "EBICS2.BIN", 0x60000000, 0x20000000, 0, 0, 0, 0, 1 },
	{ "EBICS1.BIN", CONFIG_UBOOT_END_ADDR, 0x10000000, 0, 0, 0, 0, 1 },
	{ "EBICS0.BIN", 0x40000000, CONFIG_QCA_UBOOT_OFFSET, 0, 0, 0, 0, 1 },
#endif
	{ "IMEM.BIN", 0x08600000, 0x00001000, 0 },
	{ "NSSUTCM.BIN", 0x08600658, 0x00030000, 0, 1, 0x2000 },
	{ "BTRAM.BIN", 0x08600658, 0x00058000, 0, 1, 0x00032000 },
	{ "UNAME.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "CPU_INFO.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "DMESG.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "PT.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "WLAN_MOD.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
};
int dump_entries_n = ARRAY_SIZE(dumpinfo_n);

struct dumpinfo_t dumpinfo_s[] = {
	{ "EBICS_S0.BIN", 0x40000000, 0xAC00000, 0 },
	{ "EBICS_S1.BIN", CONFIG_TZ_END_ADDR, 0x10000000, 0 },
#ifndef CONFIG_IPQ_TINY
	{ "EBICS_S2.BIN", CONFIG_TZ_END_ADDR, 0x10000000, 0, 0, 0, 0, 1 },
	{ "EBICS_S1.BIN", CONFIG_UBOOT_END_ADDR, 0x200000, 0, 0, 0, 0, 1 },
	{ "EBICS_S0.BIN", 0x40000000, CONFIG_QCA_UBOOT_OFFSET, 0, 0, 0, 0, 1 },
#endif
	{ "IMEM.BIN", 0x08600000, 0x00001000, 0 },
	{ "NSSUTCM.BIN", 0x08600658, 0x00030000, 0, 1, 0x2000 },
	{ "BTRAM.BIN", 0x08600658, 0x00058000, 0, 1, 0x00032000 },
	{ "UNAME.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "CPU_INFO.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "DMESG.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "PT.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "WLAN_MOD.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
};
int dump_entries_s = ARRAY_SIZE(dumpinfo_s);
u32 *tz_wonce = (u32 *)CONFIG_IPQ5018_TZ_WONCE_4_ADDR;

void uart1_configure_mux(void)
{
	unsigned long cfg_rcgr;

	cfg_rcgr = readl(GCC_BLSP1_UART1_APPS_CFG_RCGR);
	/* Clear mode, src sel, src div */
	cfg_rcgr &= ~(GCC_UART_CFG_RCGR_MODE_MASK |
			GCC_UART_CFG_RCGR_SRCSEL_MASK |
			GCC_UART_CFG_RCGR_SRCDIV_MASK);

	cfg_rcgr |= ((UART1_RCGR_SRC_SEL << GCC_UART_CFG_RCGR_SRCSEL_SHIFT)
			& GCC_UART_CFG_RCGR_SRCSEL_MASK);

	cfg_rcgr |= ((UART1_RCGR_SRC_DIV << GCC_UART_CFG_RCGR_SRCDIV_SHIFT)
			& GCC_UART_CFG_RCGR_SRCDIV_MASK);

	cfg_rcgr |= ((UART1_RCGR_MODE << GCC_UART_CFG_RCGR_MODE_SHIFT)
			& GCC_UART_CFG_RCGR_MODE_MASK);

	writel(cfg_rcgr, GCC_BLSP1_UART1_APPS_CFG_RCGR);
}

void uart1_set_rate_mnd(unsigned int m,
		unsigned int n, unsigned int two_d)
{
	writel(m, GCC_BLSP1_UART1_APPS_M);
	writel(n, GCC_BLSP1_UART1_APPS_N);
	writel(two_d, GCC_BLSP1_UART1_APPS_D);
}

int get_ap2mdm_gpio(void)
{
	int ap2mdm_gpio = -1, node;

	node = fdt_path_offset(gd->fdt_blob, "/sdx-gpio");
	if (node >= 0) {
		ap2mdm_gpio = fdtdec_get_uint(gd->fdt_blob, node, "ap2mdm", -1);
	} else
		return node;

	return ap2mdm_gpio;
}

void indicate_sdx_device(void)
{
	int ap2mdm_gpio;
	unsigned int *ap2mdm_gpio_base;

	unsigned int machid = gd->bd->bi_arch_number;
	if (machid != 0x8040003)
		return;

	ap2mdm_gpio = get_ap2mdm_gpio();
	if(ap2mdm_gpio >= 0) {
		/* Enabling OE in gpio cfg reg */
		ap2mdm_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(ap2mdm_gpio);
		writel(0x2c0, ap2mdm_gpio_base);
		/* Indicate SDx by writing low to ap2mdm */
		gpio_set_value(ap2mdm_gpio, 0x1);
		gpio_set_value(ap2mdm_gpio, 0x0);
	}

}

void reset_board(void)
{
	run_command("reset", 0);
}

void uart1_toggle_clock(void)
{
	unsigned long cbcr_val;

	cbcr_val = readl(GCC_BLSP1_UART1_APPS_CBCR);
	cbcr_val |= UART1_CBCR_CLK_ENABLE;
	writel(cbcr_val, GCC_BLSP1_UART1_APPS_CBCR);
}

int uart1_trigger_update(void)
{
	unsigned long cmd_rcgr;
	int timeout = 0;

	cmd_rcgr = readl(GCC_BLSP1_UART1_APPS_CMD_RCGR);
	cmd_rcgr |= UART1_CMD_RCGR_UPDATE | UART1_CMD_RCGR_ROOT_EN;
	writel(cmd_rcgr, GCC_BLSP1_UART1_APPS_CMD_RCGR);

	while (readl(GCC_BLSP1_UART1_APPS_CMD_RCGR) & UART1_CMD_RCGR_UPDATE) {
		if (timeout++ >= CLOCK_UPDATE_TIMEOUT_US) {
			printf("Timeout waiting for UART1 clock update\n");
			return -ETIMEDOUT;
			udelay(1);
		}
	}
	uart1_toggle_clock();
	return 0;
}

int uart1_clock_config(struct ipq_serial_platdata *plat)
{

	uart1_configure_mux();
	uart1_set_rate_mnd(plat->m_value,
		plat->n_value,
		plat->d_value);
	return uart1_trigger_update();
}

void qca_serial_init(struct ipq_serial_platdata *plat)
{
	int ret;

	if (plat->gpio_node < 0) {
		printf("serial_init: unable to find gpio node \n");
		return;
	}
	qca_gpio_init(plat->gpio_node);
	ret = uart1_clock_config(plat);
	if (ret)
		printf("UART clock config failed %d \n", ret);
}

/*
 * Set the uuid in bootargs variable for mounting rootfilesystem
 */
#ifdef CONFIG_QCA_MMC
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen, bool gpt_flag)
{
	int ret, len;
	block_dev_desc_t *blk_dev;
	disk_partition_t disk_info;

	blk_dev = mmc_get_dev(mmc_host.dev_num);
	if (!blk_dev) {
		printf("Invalid block device name\n");
		return -EINVAL;
	}

	if (buflen <= 0 || buflen > MAX_BOOT_ARGS_SIZE)
		return -EINVAL;

#ifdef CONFIG_PARTITION_UUIDS
	ret = get_partition_info_efi_by_name(blk_dev,
			part_name, &disk_info);
	if (ret) {
		printf("bootipq: unsupported partition name %s\n",part_name);
		return -EINVAL;
	}
	if ((len = strlcpy(boot_args, "root=PARTUUID=", buflen)) >= buflen)
		return -EINVAL;
#else
	if ((len = strlcpy(boot_args, "rootfsname=", buflen)) >= buflen)
		return -EINVAL;
#endif
	boot_args += len;
	buflen -= len;

#ifdef CONFIG_PARTITION_UUIDS
	if ((len = strlcpy(boot_args, disk_info.uuid, buflen)) >= buflen)
		return -EINVAL;
#else
	if ((len = strlcpy(boot_args, part_name, buflen)) >= buflen)
		return -EINVAL;
#endif
	boot_args += len;
	buflen -= len;

	if (gpt_flag && strlcpy(boot_args, " gpt", buflen) >= buflen)
		return -EINVAL;

	return 0;
}
#else
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen, bool gpt_flag)
{
	return 0;
}
#endif

#ifdef CONFIG_QCA_MMC
void emmc_clock_config(void)
{
	/* Enable root clock generator */
	writel(readl(GCC_SDCC1_APPS_CBCR)|0x1, GCC_SDCC1_APPS_CBCR);
	/* Add 10us delay for CLK_OFF to get cleared */
	udelay(10);
	writel(readl(GCC_SDCC1_AHB_CBCR)|0x1, GCC_SDCC1_AHB_CBCR);
	/* PLL0 - 192Mhz */
	writel(0x20B, GCC_SDCC1_APPS_CFG_RCGR);
	/* Delay for clock operation complete */
	udelay(10);
	writel(0x1, GCC_SDCC1_APPS_M);
	/* check this M, N D value while debugging
	 * because as per clock tool the actual M, N, D
	 * values are M=1, N=FA, D=F9
	 */
	writel(0xFC, GCC_SDCC1_APPS_N);
	writel(0xFD, GCC_SDCC1_APPS_D);
	/* Delay for clock operation complete */
	udelay(10);
	/* Update APPS_CMD_RCGR to reflect source selection */
	writel(readl(GCC_SDCC1_APPS_CMD_RCGR)|0x1, GCC_SDCC1_APPS_CMD_RCGR);
	/* Add 10us delay for clock update to complete */
	udelay(10);
}

void mmc_iopad_config(struct sdhci_host *host)
{
	u32 val;
	val = sdhci_readb(host, SDHCI_VENDOR_IOPAD);
	/*set bit 15 & 16*/
	val |= 0x18000;
	writel(val, host->ioaddr + SDHCI_VENDOR_IOPAD);
}

void sdhci_bus_pwr_off(struct sdhci_host *host)
{
	u32 val;

	val = sdhci_readb(host, SDHCI_HOST_CONTROL);
	sdhci_writeb(host,(val & (~SDHCI_POWER_ON)), SDHCI_POWER_CONTROL);
}

__weak void board_mmc_deinit(void)
{
	/*since we do not have misc register in ipq5018
	 * so simply return from this function
	 */
	return;
}

void emmc_clock_reset(void)
{
	writel(0x1, GCC_SDCC1_BCR);
	udelay(10);
	writel(0x0, GCC_SDCC1_BCR);
}

int board_mmc_init(bd_t *bis)
{
	int node, gpio_node;
	int ret = 0;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;
	node = fdt_path_offset(gd->fdt_blob, "mmc");
	if (node < 0) {
		printf("sdhci: Node Not found, skipping initialization\n");
		return -1;
	}

	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "mmc_gpio");
	qca_gpio_init(gpio_node);

	mmc_host.ioaddr = (void *)MSM_SDC1_SDHCI_BASE;
	mmc_host.voltages = MMC_VDD_165_195;
	mmc_host.version = SDHCI_SPEC_300;
	mmc_host.cfg.part_type = PART_TYPE_EFI;
	mmc_host.quirks = SDHCI_QUIRK_BROKEN_VOLTAGE;

	emmc_clock_reset();
	udelay(10);
	emmc_clock_config();

	if (add_sdhci(&mmc_host, 200000000, 400000)) {
		printf("add_sdhci fail!\n");
		return -1;
	}

	if (!ret && sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
		ret = board_mmc_env_init(mmc_host);
	}

	return ret;
}
#else
int board_mmc_init(bd_t *bis)
{
	return 0;
}
#endif

__weak int ipq_get_tz_version(char *version_name, int buf_size)
{
	return 1;
}

int ipq_read_tcsr_boot_misc(void)
{
	u32 *dmagic = TCSR_BOOT_MISC_REG;
	return *dmagic;
}

int apps_iscrashed(void)
{
	u32 dmagic = ipq_read_tcsr_boot_misc();

	if (dmagic & DLOAD_MAGIC_COOKIE)
		return 1;

	return 0;
}

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_auto_restart(void *blob)
{
	const char *paniconwcssfatal;

	paniconwcssfatal = getenv("paniconwcssfatal");

	if (!paniconwcssfatal)
		return;

	if (strncmp(paniconwcssfatal, "1", sizeof("1"))) {
		printf("fixup_auto_restart: invalid variable 'paniconwcssfatal'");
	} else {
		parse_fdt_fixup("/soc/q6v5_wcss@CD00000%delete%?qca,auto-restart", blob);
	}
	return;
}
#endif

#ifdef CONFIG_IPQ_BT_SUPPORT
int bt_running;

unsigned char hci_reset[] =
{0x01, 0x03, 0x0c, 0x00};

unsigned char adv_data[] =
{0x01, 0X08, 0X20, 0X20, 0X1F, 0X0A, 0X09, 0X71,
 0X75, 0X61, 0X6c, 0X63, 0X6f, 0X6d, 0X6d, 0X00,
 0X00, 0X00, 0X00, 0X00, 0X00, 0X00, 0X00, 0X00,
 0X00, 0X00, 0X00, 0X00, 0X00, 0X00, 0X00, 0X00,
 0X00, 0X00, 0X00, 0X00};

unsigned char set_interval[] =
{0X01, 0X06, 0X20, 0X0F, 0X20, 0X00, 0X20, 0X00,
 0X00, 0X00, 0X00, 0X00, 0X00, 0X00, 0X00, 0X00,
 0X00, 0X07, 0X00};

unsigned char start_beacon[] =
{0x01, 0x0A, 0x20, 0x01, 0x01};

struct hci_cmd{
	unsigned char* data;
	unsigned int len;
};

struct hci_cmd hci_cmds[] = {
	{ hci_reset, sizeof(hci_reset) },
	{ adv_data, sizeof(adv_data) },
	{ set_interval, sizeof(set_interval) },
	{ start_beacon, sizeof(start_beacon) },
};

int wait_for_bt_event(struct bt_descriptor *btDesc, u8 bt_wait)
{
	int val, timeout = 0;

	do{
		udelay(10);
		bt_ipc_worker(btDesc);

		if (bt_wait == BT_WAIT_FOR_START)
			val = !atomic_read(&btDesc->state);
		else
			val = atomic_read(&btDesc->tx_in_progress);

		if (timeout++ >= BT_TIMEOUT_US/10) {
			printf(" %s timed out \n", __func__);
			return -ETIMEDOUT;
		}

	} while (val);

	return 0;
}

static int initialize_nvm(struct bt_descriptor *btDesc,
						void *fileaddr, u32 filesize)
{
	unsigned char *buffer = fileaddr;
	int bytes_read = 0, bytes_consumed = 0, ret;
	HCI_Packet_t *hci_packet = NULL;

	while(bytes_consumed < filesize )
	{
		bytes_read = (filesize - bytes_consumed) > NVM_SEGMENT_SIZE ?
			NVM_SEGMENT_SIZE : filesize - bytes_consumed;
		/* Constructing a HCI Packet to write NVM Segments to BTSS */
		hci_packet = (HCI_Packet_t*)malloc(sizeof(HCI_Packet_t) +
							NVM_SEGMENT_SIZE);

		if(!hci_packet)
		{
			printf("Cannot allocate memory to HCI Packet \n");
			return -ENOMEM;
		}

		/* Initializing HCI Packet Header */
		hci_packet->HCIPacketType = ptHCICommandPacket;

		/* Populating TLV Request Packet in HCI */
		LE_UNALIGNED(&(hci_packet->HCIPayload.opcode), TLV_REQ_OPCODE);
		LE_UNALIGNED(&(hci_packet->HCIPayload.parameter_total_length),
				(bytes_read + DATA_REMAINING_LENGTH));
		hci_packet->HCIPayload.command_request = TLV_COMMAND_REQUEST;
		hci_packet->HCIPayload.tlv_segment_length = bytes_read;
		memcpy(hci_packet->HCIPayload.tlv_segment_data, buffer,
								bytes_read);

		bt_ipc_sendmsg(btDesc, (u8*)hci_packet,
				sizeof(HCI_Packet_t) + bytes_read);

		free(hci_packet);
		bytes_consumed += bytes_read;
		buffer = fileaddr + bytes_consumed;

		ret = wait_for_bt_event(btDesc, BT_WAIT_FOR_TX_COMPLETE);
		if(ret || *((u8 *)btDesc->buf + TLV_RESPONSE_STATUS_INDEX) != 0)
		{
			printf( "\n NVM download failed\n");
			if (!ret) {
				kfree(btDesc->buf);
				btDesc->buf = NULL;
			}
			return -EINVAL;
		}
		kfree(btDesc->buf);
		btDesc->buf = NULL;
	}

	printf("NVM download successful \n");
	bt_ipc_worker(btDesc);
	return 0;
}

int send_bt_hci_cmds(struct bt_descriptor *btDesc)
{
	int ret, i;
	int count = sizeof hci_cmds/ sizeof(struct hci_cmd);

	for (i = 0; i < count; i++) {
		bt_ipc_sendmsg(btDesc, hci_cmds[i].data, hci_cmds[i].len);

		ret = wait_for_bt_event(btDesc, BT_WAIT_FOR_TX_COMPLETE);
		if (ret)
			return ret;

		/*btDesc->buf will have response data with length btDesc->len*/
		kfree(btDesc->buf);
		btDesc->buf = NULL;
	}
	return 0;
}

int bt_init(void)
{
	struct bt_descriptor *btDesc;
	int ret;

	btDesc = kzalloc(sizeof(*btDesc), GFP_KERNEL);
	if (!btDesc)
		return -ENOMEM;

	bt_ipc_init(btDesc);

	enable_btss_lpo_clk();
	ret = qti_scm_pas_init_image(PAS_ID, (u32)bt_fw_patchmdt);
	if (ret) {
		printf("patch auth failed\n");
		return ret;
	}

	printf("patch authenticated successfully\n");

	memcpy((void*)BT_RAM_PATCH, (void*)bt_fw_patchb02,
					sizeof bt_fw_patchb02);

	ret = qti_pas_and_auth_reset(PAS_ID);

	if (ret) {
		printf("BT out of reset failed\n");
		return ret;
	}

	ret = wait_for_bt_event(btDesc, BT_WAIT_FOR_START);
	if (ret)
		return ret;

	ret = initialize_nvm(btDesc, (void*)mpnv10bin, sizeof mpnv10bin);
	if (ret)
		return ret;

	ret = wait_for_bt_event(btDesc, BT_WAIT_FOR_START);
	if (ret)
		return ret;

	send_bt_hci_cmds(btDesc);

	bt_running = 1;
	return 0;
}

void fdt_fixup_bt_running(void *blob)
{
	if (bt_running) {
		parse_fdt_fixup("/soc/bt@7000000%qcom,bt-running%1", blob);
	}
}
#endif

void reset_crashdump(void)
{
	unsigned int ret = 0;
	unsigned int cookie = 0;

	qca_scm_sdi();

	cookie = ipq_read_tcsr_boot_misc();
	/* Set CRASHDUMP_RESET in crashdump path,
	 * for TZ to differentiate it from normal reset */
	if (cookie & DLOAD_ENABLE) {
		cookie |= CRASHDUMP_RESET;
	}
	cookie &= DLOAD_DISABLE;
	ret = qca_scm_dload(cookie);
	if (ret)
		printf ("Error in reseting the Magic cookie\n");
	return;
}

void psci_sys_reset(void)
{
	__invoke_psci_fn_smc(0x84000009, 0, 0, 0);
}

void qti_scm_pshold(void)
{
	int ret;

	ret = scm_call(SCM_SVC_BOOT, SCM_CMD_TZ_PSHOLD, NULL, 0, NULL, 0);

	if (ret != 0)
		writel(0, GCNT_PSHOLD);
}

void reset_cpu(unsigned long a)
{
	reset_crashdump();
	if (is_scm_armv8()) {
		psci_sys_reset();
	} else {
		qti_scm_pshold();
	}
	while(1);
}

void board_nand_init(void)
{
#ifdef CONFIG_QPIC_SERIAL
	/* check for nand node in dts
	 * if nand node in dts is disabled then
	 * simply return from here without
	 * initializing
	 */
	int node;
	node = fdt_path_offset(gd->fdt_blob, "/nand-controller");
	if (!fdtdec_get_is_enabled(gd->fdt_blob, node)) {
		printf("QPIC: disabled, skipping initialization\n");
	} else {
		qpic_nand_init(NULL);
	}
#endif

#ifdef CONFIG_IPQ_BT_SUPPORT
	bt_init();
#endif
#ifdef CONFIG_QCA_SPI
	int gpio_node;
	gpio_node = fdt_path_offset(gd->fdt_blob, "/spi/spi_gpio");
	if (gpio_node >= 0) {
		qca_gpio_init(gpio_node);
		spi_clock_init(0);
#ifdef CONFIG_MTD_DEVICE
		ipq_spi_init(CONFIG_IPQ_SPI_NOR_INFO_IDX);
#endif
	}
#endif
}

void enable_caches(void)
{
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;
	smem_get_boot_flash(&sfi->flash_type,
		&sfi->flash_index,
		&sfi->flash_chip_select,
		&sfi->flash_block_size,
		&sfi->flash_density);
	icache_enable();
	/*Skips dcache_enable during JTAG recovery */
	if (sfi->flash_type)
		dcache_enable();
}

void disable_caches(void)
{
	icache_disable();
	dcache_disable();
}

unsigned long timer_read_counter(void)
{
	return 0;
}

static void set_ext_mdio_gpio(int node)
{
	unsigned int mdio_gpio[2] = {0};
	int status = -1;
	unsigned int *mdio_gpio_base;

	status = fdtdec_get_int_array(gd->fdt_blob,
					node,
					"ext_mdio_gpio",
					mdio_gpio,
					2);
	if (status >= 0) {
		/*  mdc  */
		mdio_gpio_base =
			(unsigned int *)GPIO_CONFIG_ADDR(mdio_gpio[0]);
		writel(0x7, mdio_gpio_base);
		/*  mdio */
		mdio_gpio_base =
			(unsigned int *)GPIO_CONFIG_ADDR(mdio_gpio[1]);
		writel(0x7, mdio_gpio_base);
	}
}

static void reset_sfp_gpio(int gpio)
{
	unsigned int *sfp_gpio_base;

	sfp_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(gpio);
	writel(0x2c3, sfp_gpio_base);
	writel(0x0, GPIO_IN_OUT_ADDR(gpio));
}

static void reset_napa_phy_gpio(int gpio)
{
	unsigned int *napa_gpio_base;

	napa_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(gpio);
	writel(0x203, napa_gpio_base);
	writel(0x0, GPIO_IN_OUT_ADDR(gpio));
	mdelay(500);
	writel(0x2, GPIO_IN_OUT_ADDR(gpio));
}

static void reset_8033_phy_gpio(int gpio)
{
	unsigned int *phy_8033_gpio_base;

	ppe_uniphy_refclk_set();
	phy_8033_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(gpio);
	writel(0x2C1, phy_8033_gpio_base);
	writel(0x0, GPIO_IN_OUT_ADDR(gpio));
	mdelay(500);
	writel(0x2, GPIO_IN_OUT_ADDR(gpio));
}

static void reset_s17c_switch_gpio(int gpio)
{
	unsigned int *switch_gpio_base =
		(unsigned int *)GPIO_CONFIG_ADDR(gpio);
/*
 * Set ref clock 25MHZ and enable Force mode
 */
	ppe_uniphy_refclk_set();
	ppe_uniphy_set_forceMode();

	writel(0x203, switch_gpio_base);
	writel(0x0, GPIO_IN_OUT_ADDR(gpio));
	mdelay(500);
	writel(0x2, GPIO_IN_OUT_ADDR(gpio));
}

static void cmn_blk_clk_set(void)
{
	/* GMN block */
	writel(0x1, GCC_CMN_BLK_AHB_CBCR);
	mdelay(20);
	writel(0x1, GCC_CMN_BLK_SYS_CBCR);
	mdelay(20);
}

static void uniphy_clk_set(void)
{
	writel(0x1, GCC_UNIPHY_AHB_CBCR);
	mdelay(20);
	writel(0x1, GCC_UNIPHY_SYS_CBCR);
	mdelay(20);
	writel(0x1, GCC_UNIPHY_RX_CBCR);
	mdelay(20);
	writel(0x1, GCC_UNIPHY_TX_CBCR);
	mdelay(20);

}

static void gephy_uniphy_clock_disable(void)
{
	u32 reg_val = 0;

	reg_val = readl(GCC_GEPHY_RX_CBCR);
	reg_val &= ~GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_GEPHY_RX_CBCR);
	mdelay(20);

	reg_val = readl(GCC_GEPHY_TX_CBCR);
	reg_val &= ~GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_GEPHY_TX_CBCR);
	mdelay(20);

	reg_val = readl(GCC_UNIPHY_RX_CBCR);
	reg_val &= ~GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_UNIPHY_RX_CBCR);
	mdelay(20);

	reg_val = readl(GCC_UNIPHY_TX_CBCR);
	reg_val &= ~GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_UNIPHY_TX_CBCR);
	mdelay(20);

}

static void gmac_clock_disable(void)
{
        u32 reg_val = 0;

	reg_val = readl(GCC_GMAC0_RX_CBCR);
	reg_val &= ~GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_GMAC0_RX_CBCR);
	mdelay(20);

	reg_val = readl(GCC_GMAC0_TX_CBCR);
	reg_val &= ~GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_GMAC0_TX_CBCR);
	mdelay(20);

	reg_val = readl(GCC_GMAC1_RX_CBCR);
	reg_val &= ~GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_GMAC1_RX_CBCR);
	mdelay(20);

	reg_val = readl(GCC_GMAC1_TX_CBCR);
	reg_val &= ~GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_GMAC1_TX_CBCR);
	mdelay(20);

}

static void gmac_clk_src_init(void)
{
	u32 reg_val, iGmac_id, iTxRx;

	/*select source of GMAC*/
	reg_val = readl(GCC_GMAC0_RX_CFG_RCGR);
	reg_val &= ~GCC_GMAC_CFG_RCGR_SRC_SEL_MASK;
	reg_val |= GCC_GMAC0_RX_SRC_SEL_GEPHY_TX;
	writel(reg_val, GCC_GMAC0_RX_CFG_RCGR);

	reg_val = readl(GCC_GMAC0_TX_CFG_RCGR);
	reg_val &= ~GCC_GMAC_CFG_RCGR_SRC_SEL_MASK;
	reg_val |= GCC_GMAC0_TX_SRC_SEL_GEPHY_TX;
	writel(reg_val, GCC_GMAC0_TX_CFG_RCGR);

	reg_val = readl(GCC_GMAC1_RX_CFG_RCGR);
	reg_val &= ~GCC_GMAC_CFG_RCGR_SRC_SEL_MASK;
	reg_val |= GCC_GMAC1_RX_SRC_SEL_UNIPHY_RX;
	writel(reg_val, GCC_GMAC1_RX_CFG_RCGR);

	reg_val = readl(GCC_GMAC1_TX_CFG_RCGR);
	reg_val &= ~GCC_GMAC_CFG_RCGR_SRC_SEL_MASK;
	reg_val |= GCC_GMAC1_TX_SRC_SEL_UNIPHY_TX;
	writel(reg_val, GCC_GMAC1_TX_CFG_RCGR);

	/* update above clock configuration */
	for (iGmac_id = 0; iGmac_id < 2; ++iGmac_id) {
		for (iTxRx = 0; iTxRx < 2; ++iTxRx){
			reg_val = 0;
			reg_val = readl(GCC_GMAC0_RX_CMD_RCGR +
				(iTxRx * 8) + (iGmac_id * 0x10));
			reg_val &= ~0x1;
			reg_val |= 0x1;
			writel(reg_val, GCC_GMAC0_RX_CMD_RCGR +
				(iTxRx * 8) + (iGmac_id * 0x10));
		}
	}
	reg_val = readl(GCC_GMAC_CFG_RCGR);
	reg_val = 0x209;
	writel(reg_val, GCC_GMAC_CFG_RCGR);

	reg_val = readl(GCC_GMAC_CMD_RCGR);
	reg_val &= ~0x1;
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC_CMD_RCGR);
}

static void gephy_reset(void)
{
	u32 reg_val;

	reg_val = readl(GCC_GEPHY_BCR);
	writel(reg_val | (GCC_GEPHY_BCR_BLK_ARES),
		GCC_GEPHY_BCR);
	mdelay(20);
	writel(reg_val & (~GCC_GEPHY_BCR_BLK_ARES),
		GCC_GEPHY_BCR);
	reg_val = readl(GCC_GEPHY_MISC);
	writel(reg_val | (GCC_GEPHY_MISC_ARES),
		GCC_GEPHY_MISC);
	mdelay(20);
	writel(reg_val & (~GCC_GEPHY_MISC_ARES),
		GCC_GEPHY_MISC);
}

static void uniphy_reset(void)
{
	u32 reg_val;

	reg_val = readl(GCC_UNIPHY_BCR);
	writel(reg_val | (GCC_UNIPHY_BCR_BLK_ARES),
		GCC_UNIPHY_BCR);
	mdelay(20);
	writel(reg_val & (~GCC_UNIPHY_BCR_BLK_ARES),
		GCC_UNIPHY_BCR);
}

static void gmac_reset(void)
{
	u32 reg_val;

	reg_val = readl(GCC_GMAC0_BCR);
	writel(reg_val | (GCC_GMAC0_BCR_BLK_ARES),
		GCC_GMAC0_BCR);
	mdelay(20);
	writel(reg_val & (~GCC_GMAC0_BCR_BLK_ARES),
		GCC_GMAC0_BCR);

	reg_val = readl(GCC_GMAC1_BCR);
	writel(reg_val | (GCC_GMAC1_BCR_BLK_ARES),
		GCC_GMAC1_BCR);
	mdelay(200);
	writel(reg_val & (~GCC_GMAC1_BCR_BLK_ARES),
		GCC_GMAC1_BCR);

}

static void cmn_clock_init (void)
{
	u32 reg_val = 0;
#ifdef INTERNAL_96MHZ
	reg_val = readl(CMN_BLK_PLL_SRC_ADDR);
	reg_val = ((reg_val & PLL_CTRL_SRC_MASK) |
			(CMN_BLK_PLL_SRC_SEL_FROM_REG << 0x8));
	writel(reg_val, CMN_BLK_PLL_SRC_ADDR);
	reg_val = readl(CMN_BLK_ADDR + 4);
	reg_val = (reg_val & PLL_REFCLK_DIV_MASK) | PLL_REFCLK_DIV_2;
	writel(reg_val, CMN_BLK_ADDR + 0x4);
#else
	reg_val = readl(CMN_BLK_ADDR + 4);
	reg_val = (reg_val & FREQUENCY_MASK) | INTERNAL_48MHZ_CLOCK;
	writel(reg_val, CMN_BLK_ADDR + 0x4);
#endif
	reg_val = readl(CMN_BLK_ADDR);
	reg_val = reg_val | 0x40;
	writel(reg_val, CMN_BLK_ADDR);
	mdelay(1);
	reg_val = reg_val & (~0x40);
	writel(reg_val, CMN_BLK_ADDR);
	mdelay(1);
	writel(0xbf, CMN_BLK_ADDR);
	mdelay(1);
	writel(0xff, CMN_BLK_ADDR);
	mdelay(1);
}

static void cmnblk_enable(void)
{
	u32 reg_val;

	reg_val = readl(TCSR_ETH_LDO_RDY_REG);
	reg_val |= ETH_LDO_RDY;
	writel(reg_val, TCSR_ETH_LDO_RDY_REG);
}

static void cmnblk_check_state(void)
{
	u32 reg_val, times = 20;

	while(times--)
	{
		reg_val = readl(CMN_PLL_PLL_LOCKED_REG);
		if(reg_val & CMN_PLL_LOCKED) {
			printf("cmbblk is stable %x\n",
			reg_val);
			break;
		}
		mdelay(10);
	}
	if(!times) {
		printf("200ms have been over %x\n",
		readl(CMN_PLL_PLL_LOCKED_REG));
	}
}

static void gcc_clock_enable(void)
{
	u32 reg_val;

	reg_val = readl(GCC_MDIO0_BASE + 0x4);
	reg_val |= 0x1;
	writel(reg_val, GCC_MDIO0_BASE + 0x4);

	reg_val = readl(GCC_MDIO0_BASE + 0x14);
	reg_val |= 0x1;
	writel(reg_val, GCC_MDIO0_BASE + 0x14);

	reg_val = readl(GCC_GMAC0_SYS_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC0_SYS_CBCR);

	reg_val = readl(GCC_GMAC0_PTP_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC0_PTP_CBCR);

	reg_val = readl(GCC_GMAC0_CFG_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC0_CFG_CBCR);

	reg_val = readl(GCC_GMAC1_SYS_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC1_SYS_CBCR);

	reg_val = readl(GCC_GMAC1_PTP_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC1_PTP_CBCR);

	reg_val = readl(GCC_GMAC1_CFG_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC1_CFG_CBCR);

	reg_val = readl(GCC_GMAC0_RX_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC0_RX_CBCR);

	reg_val = readl(GCC_GMAC0_TX_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC0_TX_CBCR);

	reg_val = readl(GCC_GMAC1_RX_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC1_RX_CBCR);

	reg_val = readl(GCC_GMAC1_TX_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_GMAC1_TX_CBCR);

	reg_val = readl(GCC_SNOC_GMAC0_AHB_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_SNOC_GMAC0_AHB_CBCR);

	reg_val = readl(GCC_SNOC_GMAC1_AHB_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_SNOC_GMAC1_AHB_CBCR);

	reg_val = readl(GCC_SNOC_GMAC0_AXI_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_SNOC_GMAC0_AXI_CBCR);

	reg_val = readl(GCC_SNOC_GMAC1_AXI_CBCR);
	reg_val |= 0x1;
	writel(reg_val, GCC_SNOC_GMAC1_AXI_CBCR);
}

static void ethernet_clock_enable(void)
{
	cmn_blk_clk_set();
	uniphy_clk_set();
	gephy_uniphy_clock_disable();
	gmac_clock_disable();
	gmac_clk_src_init();
	cmn_clock_init();
	cmnblk_enable();
	cmnblk_check_state();
	gephy_reset();
	uniphy_reset();
	gmac_reset();
	gcc_clock_enable();
}

static void enable_gephy_led(int gpio)
{
	unsigned int *led_gpio_base =
		(unsigned int *)GPIO_CONFIG_ADDR(gpio);

	writel(0xc5, led_gpio_base);
}

int board_eth_init(bd_t *bis)
{
	int status;
	int led_gpio;
	int gmac_cfg_node = 0, offset = 0;
	int loop = 0;
	int switch_gpio = 0;
	unsigned int tmp_phy_array[8] = {0};

	gmac_cfg_node = fdt_path_offset(gd->fdt_blob, "/gmac_cfg");
	if (gmac_cfg_node >= 0) {
		/*
		 * Clock enable
		 */
		ethernet_clock_enable();
		led_gpio = fdtdec_get_uint(gd->fdt_blob,
				gmac_cfg_node, "gephy_led", 0);
		if (led_gpio)
			enable_gephy_led(led_gpio);

		set_ext_mdio_gpio(gmac_cfg_node);

		for (offset = fdt_first_subnode(gd->fdt_blob, gmac_cfg_node);
			offset > 0;
			offset = fdt_next_subnode(gd->fdt_blob, offset) , loop++) {

			gmac_cfg[loop].base = fdtdec_get_uint(gd->fdt_blob,
					offset, "base", 0);

			gmac_cfg[loop].unit = fdtdec_get_uint(gd->fdt_blob,
					offset, "unit", 0);

			gmac_cfg[loop].phy_addr = fdtdec_get_uint(gd->fdt_blob,
					offset, "phy_address", 0);

			gmac_cfg[loop].phy_interface_mode = fdtdec_get_uint(gd->fdt_blob,
					offset, "phy_interface_mode", 0);

			gmac_cfg[loop].phy_external_link = fdtdec_get_uint(gd->fdt_blob,
					offset, "phy_external_link", 0);

			gmac_cfg[loop].sfp_mode = fdtdec_get_uint(gd->fdt_blob,
					offset, "switch_mac_mode", 0);
			gmac_cfg[loop].sfp_rx_gpio
				= fdtdec_get_uint(gd->fdt_blob, offset,
					"sfp_rx_gpio", 0);
			gmac_cfg[loop].sfp_tx_gpio
				= fdtdec_get_uint(gd->fdt_blob, offset,
					"sfp_tx_gpio", 0);
			if (gmac_cfg[loop].sfp_tx_gpio) {
				reset_sfp_gpio(gmac_cfg[loop].sfp_tx_gpio);
			}

			gmac_cfg[loop].phy_napa_gpio = fdtdec_get_uint(gd->fdt_blob,
					offset, "napa_gpio", 0);
			if (gmac_cfg[loop].phy_napa_gpio){
				reset_napa_phy_gpio(gmac_cfg[loop].phy_napa_gpio);
			}
			gmac_cfg[loop].phy_8033_gpio = fdtdec_get_uint(gd->fdt_blob,
					offset, "8033_gpio", 0);
			if (gmac_cfg[loop].phy_8033_gpio){
				reset_8033_phy_gpio(gmac_cfg[loop].phy_8033_gpio);
			}
			switch_gpio =  fdtdec_get_uint(gd->fdt_blob, offset, "switch_gpio", 0);
			if (switch_gpio) {
				reset_s17c_switch_gpio(switch_gpio);
			}
			gmac_cfg[loop].phy_type = fdtdec_get_uint(gd->fdt_blob,
					offset, "phy_type", -1);

			gmac_cfg[loop].mac_pwr = fdtdec_get_uint(gd->fdt_blob,
					offset, "mac_pwr", 0);

			gmac_cfg[loop].ipq_swith = fdtdec_get_uint(gd->fdt_blob,
					offset, "s17c_switch_enable", 0);
			if (gmac_cfg[loop].ipq_swith) {
				gmac_cfg[loop].switch_port_count = fdtdec_get_uint(
					gd->fdt_blob,
					offset, "switch_port_count", 0);

				fdtdec_get_int_array(gd->fdt_blob, offset, "switch_phy_address",
					tmp_phy_array, gmac_cfg[loop].switch_port_count);

				for(int inner_loop = 0; inner_loop < gmac_cfg[loop].switch_port_count;
					inner_loop++){
				gmac_cfg[loop].switch_port_phy_address[inner_loop] =
					(char)tmp_phy_array[inner_loop];
				}
			}
		}
	}

	if (loop < CONFIG_IPQ_NO_MACS)
		 gmac_cfg[loop].unit = -1;

	status = ipq_gmac_init(gmac_cfg);
	board_update_caldata();

	return status;
}

void set_flash_secondary_type(qca_smem_flash_info_t *smem)
{
	return;
};

#ifdef CONFIG_USB_XHCI_IPQ
void board_usb_deinit(int id)
{
	int nodeoff, ssphy, gpio_node;
	char node_name[8];

	if(readl(EUD_EUD_EN2))
	/*
	 * Eud enable skipping deinit part
	 */
		return;

	snprintf(node_name, sizeof(node_name), "usb%d", id);
	nodeoff = fdt_path_offset(gd->fdt_blob, node_name);
	if (fdtdec_get_int(gd->fdt_blob, nodeoff, "qcom,emulation", 0))
		return;

	ssphy = fdtdec_get_int(gd->fdt_blob, nodeoff, "ssphy", 0);
	/* Enable USB PHY Power down */
	setbits_le32(QUSB2PHY_BASE + 0xA4, 0x0);
	/* Disable clocks */
	writel(0x0, GCC_USB0_PHY_CFG_AHB_CBCR);
	writel(0x4220, GCC_USB0_MASTER_CBCR);
	writel(0x0, GCC_SYS_NOC_USB0_AXI_CBCR);
	writel(0x0, GCC_USB0_SLEEP_CBCR);
	writel(0x0, GCC_USB0_MOCK_UTMI_CBCR);
	writel(0x0, GCC_USB0_AUX_CBCR);
	writel(0x0, GCC_USB0_LFPS_CBCR);
	/* GCC_QUSB2_0_PHY_BCR */
	set_mdelay_clearbits_le32(GCC_QUSB2_0_PHY_BCR, 0x1, 10);
	/* GCC_USB0_PHY_BCR */
	if (ssphy)
		set_mdelay_clearbits_le32(GCC_USB0_PHY_BCR, 0x1, 10);
	/* GCC Reset USB BCR */
	set_mdelay_clearbits_le32(GCC_USB0_BCR, 0x1, 10);
	/* Deselect the usb phy mux */
	if (ssphy)
		writel(0x0, TCSR_USB_PCIE_SEL);

	/* skip gpio pull config if bt_debug is enabled */
	if(getenv("bt_debug"))
		return;

	/* deinit USB power GPIO for drive 5V */
	gpio_node = fdt_subnode_offset(gd->fdt_blob, nodeoff, "usb_gpio");
	if (gpio_node >= 0){
		gpio_node = fdt_first_subnode(gd->fdt_blob, gpio_node);
		if (gpio_node > 0) {
			int gpio = fdtdec_get_uint(gd->fdt_blob,
					gpio_node, "gpio", 0);
			unsigned int *gpio_base =
				(unsigned int *)GPIO_CONFIG_ADDR(gpio);
			int usb_pwr_gpio = fdtdec_get_int(gd->fdt_blob, nodeoff, "usb_pwr_gpio", 0);
			writel(0xC1, gpio_base);
			gpio_set_value(usb_pwr_gpio, GPIO_OUT_LOW);
		}
	}

}

static void usb_clock_init(int id, int ssphy)
{
	int cfg;

	/* select usb phy mux */
	if (ssphy)
		writel(0x1, TCSR_USB_PCIE_SEL);

	/* Configure usb0_master_clk_src */
	cfg = (GCC_USB0_MASTER_CFG_RCGR_SRC_SEL |
		GCC_USB0_MASTER_CFG_RCGR_SRC_DIV);
	writel(cfg, GCC_USB0_MASTER_CFG_RCGR);
	writel(CMD_UPDATE, GCC_USB0_MASTER_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_USB0_MASTER_CMD_RCGR);

	/* Configure usb0_mock_utmi_clk_src */
	cfg = (GCC_USB_MOCK_UTMI_SRC_SEL |
		GCC_USB_MOCK_UTMI_SRC_DIV);
	writel(cfg, GCC_USB0_MOCK_UTMI_CFG_RCGR);
	writel(GCC_USB_MOCK_UTMI_CLK_DIV, GCC_USB0_MOCK_UTMI_CBCR);
	writel(CMD_UPDATE, GCC_USB0_MOCK_UTMI_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_USB0_MOCK_UTMI_CMD_RCGR);

	/* Configure usb0_aux_clk_src */
	cfg = (GCC_USB0_AUX_CFG_SRC_SEL |
		GCC_USB0_AUX_CFG_SRC_DIV);
	writel(cfg, GCC_USB0_AUX_CFG_RCGR);
	writel(CMD_UPDATE, GCC_USB0_AUX_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_USB0_AUX_CMD_RCGR);

	/* Configure usb0_lfps_cmd_rcgr */
	cfg = (GCC_USB0_LFPS_CFG_SRC_SEL |
		GCC_USB0_LFPS_CFG_SRC_DIV);
	writel(cfg, GCC_USB0_LFPS_CFG_RCGR);
	writel(LFPS_M, GCC_USB0_LFPS_M);
	writel(LFPS_N, GCC_USB0_LFPS_N);
	writel(LFPS_D, GCC_USB0_LFPS_D);
	writel(readl(GCC_USB0_LFPS_CFG_RCGR) | GCC_USB0_LFPS_MODE,
			GCC_USB0_LFPS_CFG_RCGR);
	writel(CMD_UPDATE, GCC_USB0_LFPS_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_USB0_LFPS_CMD_RCGR);

	/* Configure CBCRs */
	writel(CLK_DISABLE, GCC_SYS_NOC_USB0_AXI_CBCR);
	writel(CLK_ENABLE, GCC_SYS_NOC_USB0_AXI_CBCR);
	writel((readl(GCC_USB0_MASTER_CBCR) | CLK_ENABLE),
		GCC_USB0_MASTER_CBCR);
	writel(CLK_ENABLE, GCC_USB0_SLEEP_CBCR);
	writel((GCC_USB_MOCK_UTMI_CLK_DIV | CLK_ENABLE),
		GCC_USB0_MOCK_UTMI_CBCR);
	writel(CLK_DISABLE, GCC_USB0_PIPE_CBCR);
	writel(CLK_ENABLE, GCC_USB0_PHY_CFG_AHB_CBCR);
	writel(CLK_ENABLE, GCC_USB0_AUX_CBCR);
	writel(CLK_ENABLE, GCC_USB0_LFPS_CBCR);
}

static void usb_init_hsphy(void __iomem *phybase, int ssphy)
{
	if (!ssphy) {
		/*Enable utmi instead of pipe*/
		writel((readl(USB30_GENERAL_CFG) | PIPE_UTMI_CLK_DIS), USB30_GENERAL_CFG);

		udelay(100);

		writel((readl(USB30_GENERAL_CFG) | PIPE_UTMI_CLK_SEL | PIPE3_PHYSTATUS_SW), USB30_GENERAL_CFG);

		udelay(100);

		writel((readl(USB30_GENERAL_CFG) & ~PIPE_UTMI_CLK_DIS), USB30_GENERAL_CFG);
	}
	/* Disable USB PHY Power down */
	setbits_le32(phybase + 0xA4, 0x1);
	/* Enable override ctrl */
	writel(UTMI_PHY_OVERRIDE_EN, phybase + USB_PHY_CFG0);
	/* Enable POR*/
	writel(POR_EN, phybase + USB_PHY_UTMI_CTRL5);
	udelay(15);
	/* Configure frequency select value*/
	writel(FREQ_SEL, phybase + USB_PHY_FSEL_SEL);
	/* Configure refclk frequency */
	writel(COMMONONN | FSEL | RETENABLEN,
			phybase + USB_PHY_HS_PHY_CTRL_COMMON0);
	/* select refclk source */
	writel(CLKCORE, phybase + USB_PHY_REFCLK_CTRL);
	/* select ATERESET*/
	writel(POR_EN & ATERESET, phybase + USB_PHY_UTMI_CTRL5);
	writel(USB2_SUSPEND_N_SEL | USB2_SUSPEND_N | USB2_UTMI_CLK_EN,
			phybase + USB_PHY_HS_PHY_CTRL2);
	writel(0x0, phybase + USB_PHY_UTMI_CTRL5);
	writel(USB2_SUSPEND_N | USB2_UTMI_CLK_EN,
			phybase + USB_PHY_HS_PHY_CTRL2);
	/* Disable override ctrl */
	writel(0x0, phybase + USB_PHY_CFG0);
}

static void usb_init_ssphy(void __iomem *phybase)
{
	writel(CLK_ENABLE, GCC_USB0_PHY_CFG_AHB_CBCR);
	writel(CLK_ENABLE, GCC_USB0_PIPE_CBCR);
	udelay(100);
	/*set frequency initial value*/
	writel(0x1cb9, phybase + SSCG_CTRL_REG_4);
	writel(0x023a, phybase + SSCG_CTRL_REG_5);
	/*set spectrum spread count*/
	writel(0xd360, phybase + SSCG_CTRL_REG_3);
	/*set fstep*/
	writel(0x1, phybase + SSCG_CTRL_REG_1);
	writel(0xeb, phybase + SSCG_CTRL_REG_2);
	return;
}

static void usb_init_phy(int index, int ssphy)
{
	void __iomem *boot_clk_ctl, *usb_bcr, *qusb2_phy_bcr;

	boot_clk_ctl = (u32 *)GCC_USB_0_BOOT_CLOCK_CTL;
	usb_bcr = (u32 *)GCC_USB0_BCR;
	qusb2_phy_bcr = (u32 *)GCC_QUSB2_0_PHY_BCR;

	/* Disable USB Boot Clock */
	clrbits_le32(boot_clk_ctl, 0x0);

	/* GCC Reset USB BCR */
	set_mdelay_clearbits_le32(usb_bcr, 0x1, 10);

	if (ssphy)
		setbits_le32(GCC_USB0_PHY_BCR, 0x1);
	setbits_le32(qusb2_phy_bcr, 0x1);
	udelay(1);
	/* Config user control register */
	writel(0x4004010, USB30_GUCTL);
	writel(0x4945920, USB30_FLADJ);
	if (ssphy)
		clrbits_le32(GCC_USB0_PHY_BCR, 0x1);
	clrbits_le32(qusb2_phy_bcr, 0x1);
	udelay(30);

	if (ssphy)
		usb_init_ssphy((u32 *)USB3PHY_APB_BASE);
	usb_init_hsphy((u32 *)QUSB2PHY_BASE, ssphy);
}

int ipq_board_usb_init(void)
{
	int i, nodeoff, ssphy, gpio_node, usb_pwr_gpio;
	char node_name[8];

	if(readl(EUD_EUD_EN2)) {
		printf("USB: EUD Enable, skipping initialization\n");
		return 0;
	}

	for (i=0; i<CONFIG_USB_MAX_CONTROLLER_COUNT; i++) {
		snprintf(node_name, sizeof(node_name), "usb%d", i);
		nodeoff = fdt_path_offset(gd->fdt_blob, node_name);
		if (nodeoff < 0){
			printf("USB: Node Not found, skipping initialization\n");
			return 0;
		}

		ssphy = fdtdec_get_int(gd->fdt_blob, nodeoff, "ssphy", 0);
		if (!fdtdec_get_int(gd->fdt_blob, nodeoff, "qcom,emulation", 0)) {

			usb_clock_init(i, ssphy);
			usb_init_phy(i, ssphy);
		}else {
			/* Config user control register */
			writel(0x0C804010, USB30_GUCTL);
		}
	}
	/* skip gpio pull config if bt_debug is enabled */
	if(!getenv("bt_debug")){
		/* USB power GPIO for drive 5V */
		gpio_node =
			fdt_subnode_offset(gd->fdt_blob, nodeoff, "usb_gpio");
		if (gpio_node >= 0) {
			qca_gpio_init(gpio_node);
			usb_pwr_gpio = fdtdec_get_int(gd->fdt_blob, nodeoff, "usb_pwr_gpio", 0);
			gpio_set_value(usb_pwr_gpio, GPIO_OUT_HIGH);
		}
	}

	return 0;
}
#endif

#ifdef CONFIG_PCI_IPQ
static void pcie_v2_clock_init(int lane)
{
#ifdef CONFIG_PCI
	u32 reg_val;
	void __iomem *base;

	/*single lane*/
	/* Enable SYS_NOC clock */
	if (lane == 1) {
		base = (void __iomem *)GCC_PCIE1_BOOT_CLOCK_CTL;
		writel(CLK_ENABLE, GCC_SYS_NOC_PCIE1_AXI_CBCR);
		mdelay(1);
		/* Configure pcie1_aux_clk_src */
		writel((GCC_PCIE1_AUX_CFG_RCGR_SRC_SEL |
			GCC_PCIE1_AUX_CFG_RCGR_SRC_DIV),
			base + PCIE_AUX_CFG_RCGR);
		mdelay(1);
		reg_val = readl(base + PCIE_AUX_CMD_RCGR);
		reg_val &= ~0x1;
		reg_val |= 0x1;
		writel(reg_val, base + PCIE_AUX_CMD_RCGR);

		/* Configure pcie1_axi_clk_src */
		writel((GCC_PCIE1_AXI_CFG_RCGR_SRC_SEL |
			GCC_PCIE1_AXI_CFG_RCGR_SRC_DIV),
			base + PCIE_AXI_CFG_RCGR);
		mdelay(1);
		reg_val = readl(base + PCIE_AXI_CMD_RCGR);
		reg_val &= ~0x1;
		reg_val |= 0x1;
		writel(reg_val, base + PCIE_AXI_CMD_RCGR);
	} else { /*double lane*/
		base = (void __iomem *)GCC_PCIE0_BOOT_CLOCK_CTL;
		writel(CLK_ENABLE, GCC_SYS_NOC_PCIE0_AXI_CBCR);
		mdelay(1);
		/* Configure pcie1_aux_clk_src */
		writel((GCC_PCIE0_AUX_CFG_RCGR_SRC_SEL |
			GCC_PCIE0_AUX_CFG_RCGR_SRC_DIV),
			base + PCIE_AUX_CFG_RCGR);
		mdelay(1);
		reg_val = readl(base + PCIE_AUX_CMD_RCGR);
		reg_val &= ~0x1;
		reg_val |= 0x1;
		writel(reg_val, base + PCIE_AUX_CMD_RCGR);

		/* Configure pcie1_axi_clk_src */
		writel((GCC_PCIE0_AXI_CFG_RCGR_SRC_SEL |
			GCC_PCIE0_AXI_CFG_RCGR_SRC_DIV),
			base + PCIE_AXI_CFG_RCGR);
		mdelay(1);
		reg_val = readl(base + PCIE_AXI_CMD_RCGR);
		reg_val &= ~0x1;
		reg_val |= 0x1;
		writel(reg_val, base + PCIE_AXI_CMD_RCGR);
	}
	mdelay(1);
	reg_val= readl(base + PCIE_AXI_M_CBCR);
	reg_val |= CLK_ENABLE;
	writel(reg_val, base + PCIE_AXI_M_CBCR);

	mdelay(1);
	reg_val = readl(base + PCIE_AXI_S_CBCR);
	reg_val |= CLK_ENABLE;
	writel(reg_val, base + PCIE_AXI_S_CBCR);

	mdelay(1);
	writel(CLK_ENABLE, base + PCIE_AHB_CBCR);

	mdelay(1);
	writel(CLK_ENABLE, base + PCIE_AUX_CBCR);

	mdelay(1);
	writel(CLK_ENABLE, base + PCIE_AXI_S_BRIDGE_CBCR);

	mdelay(1);
	reg_val= readl(base + PCIE_PIPE_CBCR);
	reg_val |= CLK_ENABLE;
	writel(reg_val, base + PCIE_PIPE_CBCR);
	mdelay(1);
#endif
	return;
}

static void pcie_v2_clock_deinit(int lane)
{
#ifdef CONFIG_PCI
	void __iomem *base;

	/*single lane*/
	if (lane == 1) {
		base = (void __iomem *)GCC_PCIE1_BOOT_CLOCK_CTL;
		writel(0x0, GCC_SYS_NOC_PCIE1_AXI_CBCR);
	} else { /*double lane*/
		base = (void __iomem *)GCC_PCIE0_BOOT_CLOCK_CTL;
		writel(0x0, GCC_SYS_NOC_PCIE0_AXI_CBCR);
	}
	mdelay (5);
	writel(0x0, base + PCIE_AHB_CBCR);
	writel(0x0, base + PCIE_AXI_M_CBCR);
	writel(0x0, base + PCIE_AXI_S_CBCR);
	writel(0x0, base + PCIE_AUX_CBCR);
	writel(0x0, base + PCIE_PIPE_CBCR);
	writel(0x0, base + PCIE_AXI_S_BRIDGE_CBCR);
#endif
	return;
}

static void pcie_phy_init(u32 reg_base, int mode, int lane)
{
	for (int i = 0; i < lane; ++i) {
	/*set frequency initial value*/
	writel(0x1cb9, (reg_base + (i * 0x800)) + SSCG_CTRL_REG_4);
	writel(0x023a, (reg_base + (i * 0x800)) + SSCG_CTRL_REG_5);
	/*set spectrum spread count*/
	writel(0x1360, (reg_base + (i * 0x800)) + SSCG_CTRL_REG_3);
		if (mode == 1) {
			/*set fstep*/
			writel(0x0, (reg_base + (i * 0x800)) +
				SSCG_CTRL_REG_1);
			writel(0x0, (reg_base + (i * 0x800)) +
				SSCG_CTRL_REG_2);
		} else {
			/*set fstep*/
			writel(0x1, (reg_base + (i * 0x800)) +
				SSCG_CTRL_REG_1);
			writel(0xeb, (reg_base + (i * 0x800)) +
				SSCG_CTRL_REG_2);
			/*set FLOOP initial value*/
			writel(0x3f9, (reg_base + (i * 0x800)) +
				CDR_CTRL_REG_4);
			writel(0x1c9, (reg_base + (i * 0x800)) +
				CDR_CTRL_REG_5);
			/*set upper boundary level*/
			writel(0x419, (reg_base + (i * 0x800)) +
				CDR_CTRL_REG_2);
			/*set fixed offset*/
			writel(0x200, (reg_base + (i * 0x800)) +
				CDR_CTRL_REG_1);
		}
	}
}

static void pcie_reset(int lane)
{
	u32 reg_val;
	void __iomem *base;

	/*single lane*/
	if (lane == 1)
		base = (void __iomem *)GCC_PCIE1_BOOT_CLOCK_CTL;
	else  /*double lane*/
		base = (void __iomem *)GCC_PCIE0_BOOT_CLOCK_CTL;

	reg_val = readl(base + PCIE_BCR);
	writel(reg_val | GCC_PCIE_BCR_ENABLE,
			(base + PCIE_BCR));
	mdelay(1);
	writel(reg_val & (~GCC_PCIE_BCR_ENABLE),
			(base + PCIE_BCR));

	reg_val = readl(base + PCIE_PHY_BCR);
	writel(reg_val | GCC_PCIE_BLK_ARES,
			(base + PCIE_PHY_BCR));
	mdelay(1);
	writel(reg_val & (~GCC_PCIE_BLK_ARES),
			(base + PCIE_PHY_BCR));

	reg_val = readl(base + PCIE_PHY_PHY_BCR);
	writel(reg_val | GCC_PCIE_BLK_ARES,
			(base + PCIE_PHY_PHY_BCR));
	mdelay(1);
	writel(reg_val & (~GCC_PCIE_BLK_ARES),
			(base + PCIE_PHY_PHY_BCR));

	reg_val = readl(base + PCIE_MISC_RESET);
	writel(reg_val | GCC_PCIE_PIPE_ARES,
			(base + PCIE_MISC_RESET));
	mdelay(1);
	writel(reg_val & (~GCC_PCIE_PIPE_ARES),
			(base + PCIE_MISC_RESET));

	reg_val = readl(base + PCIE_MISC_RESET);
	writel(reg_val | GCC_PCIE_SLEEP_ARES,
			(base + PCIE_MISC_RESET));
	mdelay(1);
	writel(reg_val & (~GCC_PCIE_SLEEP_ARES),
			(base + PCIE_MISC_RESET));

	reg_val = readl(base + PCIE_MISC_RESET);
	writel(reg_val | GCC_PCIE_CORE_STICKY_ARES,
			(base + PCIE_MISC_RESET));
	mdelay(1);
	writel(reg_val & (~GCC_PCIE_CORE_STICKY_ARES),
			(base + PCIE_MISC_RESET));

	reg_val = readl(base + PCIE_MISC_RESET);
	writel(reg_val | GCC_PCIE_AXI_MASTER_ARES,
			(base + PCIE_MISC_RESET));
	mdelay(1);
	writel(reg_val & (~GCC_PCIE_AXI_MASTER_ARES),
			(base + PCIE_MISC_RESET));

	reg_val = readl(base + PCIE_MISC_RESET);
	writel(reg_val | GCC_PCIE_AXI_SLAVE_ARES,
			(base + PCIE_MISC_RESET));
	mdelay(1);
	writel(reg_val & (~GCC_PCIE_AXI_SLAVE_ARES),
			(base + PCIE_MISC_RESET));

	reg_val = readl(base + PCIE_MISC_RESET);
	writel(reg_val | GCC_PCIE_AHB_ARES,
			(base + PCIE_MISC_RESET));
	mdelay(1);
	writel(reg_val & (~GCC_PCIE_AHB_ARES),
			(base + PCIE_MISC_RESET));

	reg_val = readl(base + PCIE_MISC_RESET);
	writel(reg_val | GCC_PCI_AXI_MASTER_STICKY_ARES,
			(base + PCIE_MISC_RESET));
	mdelay(1);
	writel(reg_val & (~GCC_PCI_AXI_MASTER_STICKY_ARES),
			(base + PCIE_MISC_RESET));

	reg_val = readl(base + PCIE_MISC_RESET);
	writel(reg_val | GCC_PCI_AXI_SLAVE_STICKY_ARES,
			(base + PCIE_MISC_RESET));
	mdelay(1);
	writel(reg_val & (~GCC_PCI_AXI_SLAVE_STICKY_ARES),
			(base + PCIE_MISC_RESET));
}

void board_pci_init(int id)
{
	int node, gpio_node, mode = 0;
	struct fdt_resource pci_phy;
	char name[16];
	int err, lane;

	snprintf(name, sizeof(name), "pci%d", id);
	node = fdt_path_offset(gd->fdt_blob, name);
	if (node < 0) {
		printf("Could not find PCI in device tree\n");
		return;
	}

	err = fdt_get_named_resource(gd->fdt_blob, node,
			"reg", "reg-names", "pci_phy",&pci_phy);
	if (err < 0)
		return;

	if (!strcmp(fdt_getprop(gd->fdt_blob, node, "mode", NULL), "fixed")){
		mode = 1;
	}
	lane = fdtdec_get_int(gd->fdt_blob, node, "lane", 0);

	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
	if (gpio_node >= 0)
		qca_gpio_init(gpio_node);

	pcie_reset(lane);
	pcie_v2_clock_init(lane);
	pcie_phy_init(pci_phy.start, mode, lane);

	return;
}

void board_pci_deinit()
{
	int node, gpio_node, i, lane, err;
	char name[16];
	struct fdt_resource parf;
	struct fdt_resource pci_phy;

	for (i = 0; i < PCI_MAX_DEVICES; i++) {
		snprintf(name, sizeof(name), "pci%d", i);
		node = fdt_path_offset(gd->fdt_blob, name);
		if (node < 0) {
			printf("Could not find PCI in device tree\n");
			continue;
		}
		err = fdt_get_named_resource(gd->fdt_blob, node, "reg", "reg-names", "parf",
				&parf);
		writel(0x0, parf.start + 0x358);
		writel(0x1, parf.start + 0x40);
		err = fdt_get_named_resource(gd->fdt_blob, node, "reg", "reg-names", "pci_phy",
				     &pci_phy);
		if (err < 0)
			continue;

		writel(0x1, pci_phy.start + 800);
		writel(0x0, pci_phy.start + 804);
		gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
		if (gpio_node >= 0)
			qca_gpio_deinit(gpio_node);

		lane = fdtdec_get_int(gd->fdt_blob, node, "lane", 0);
		pcie_v2_clock_deinit(lane);
	}

	return ;
}
#endif

 /*
  * Gets the Caldata from the ART partition table and return the value
  */
int get_eth_caldata(u32 *caldata, u32 offset)
{
	s32 ret = 0 ;
	u32 flash_type=0u;
        u32 start_blocks;
        u32 size_blocks;
	u32 art_offset=0U ;
	u32 length = 4;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

        struct spi_flash *flash = NULL;

#if defined(CONFIG_ART_COMPRESSED) && (defined(CONFIG_GZIP) || defined(CONFIG_LZMA))
        void *load_buf, *image_buf;
        unsigned long img_size;
        unsigned long desMaxSize;
#endif

#ifdef CONFIG_QCA_MMC
        block_dev_desc_t *blk_dev;
        disk_partition_t disk_info;
        struct mmc *mmc;
        char mmc_blks[512];
#endif

	if ((sfi->flash_type == SMEM_BOOT_SPI_FLASH) ||
		(sfi->flash_type == SMEM_BOOT_NOR_FLASH) ||
		(sfi->flash_type == SMEM_BOOT_NORPLUSNAND) ||
		(sfi->flash_type == SMEM_BOOT_NORPLUSEMMC))
	{
		ret = smem_getpart("0:ART", &start_blocks, &size_blocks);
                if (ret < 0) {
                        printf("No ART partition found\n");
                        return ret;
                }

                /*
                 * ART partition 0th position.
                 */
                art_offset = (u32)((u32) qca_smem_flash_info.flash_block_size * start_blocks);

#ifndef CONFIG_ART_COMPRESSED
		art_offset = (art_offset + offset);
#endif

                flash = spi_flash_probe(CONFIG_SF_DEFAULT_BUS, CONFIG_SF_DEFAULT_CS,
                                CONFIG_SF_DEFAULT_SPEED, CONFIG_SF_DEFAULT_MODE);


                if (flash == NULL){
                        printf("No SPI flash device found\n");
                        ret = -1;
                }
		else {
#if defined(CONFIG_ART_COMPRESSED) && defined(CONFIG_LZMA)
                image_buf = map_sysmem(CONFIG_COMPRESSED_LOAD_ADDR, 0);
                load_buf = map_sysmem(CONFIG_COMPRESSED_LOAD_ADDR + 0x100000, 0);
                img_size = qca_smem_flash_info.flash_block_size * size_blocks;
                desMaxSize = 0x100000;
                ret = spi_flash_read(flash, art_offset, img_size, image_buf);
                if (ret == 0) {
                        ret = -1;
#ifdef CONFIG_LZMA
                        if (ret != 0){

                                ret = lzmaBuffToBuffDecompress(load_buf,
                                        (SizeT *)&desMaxSize,
                                        image_buf,
                                        (SizeT)img_size);
			}
#endif
                        if((!ret) && (memcpy(caldata, load_buf + offset , length))){}
			else {
				printf("Invalid compression type..\n");
				ret = -1;
			}
                }
#else
			ret = spi_flash_read(flash, art_offset, length, caldata);
#endif
		}

                if (ret < 0)
                        printf("ART partition read failed..\n");
	}
#ifdef CONFIG_QPIC_NAND
	else if ((sfi->flash_type == SMEM_BOOT_NAND_FLASH ) || (sfi->flash_type == SMEM_BOOT_QSPI_NAND_FLASH))
	{
		if (qca_smem_flash_info.flash_type == SMEM_BOOT_SPI_FLASH)
                        flash_type = CONFIG_SPI_FLASH_INFO_IDX;
		else{
			flash_type = CONFIG_NAND_FLASH_INFO_IDX;
		}

		ret = smem_getpart("0:ART", &start_blocks, &size_blocks);
                if (ret < 0) {
                        printf("No ART partition found\n");
                        return ret;
                }

                /*
                 * ART partition 0th position.
                 */
                art_offset = (u32)((u32) qca_smem_flash_info.flash_block_size * start_blocks);
                art_offset = /*(loff_t)*/(art_offset + offset);

		ret = nand_read(&nand_info[flash_type],art_offset, &length,(u_char*) caldata);

		if (ret < 0)
                        printf("ART partition read failed..\n");
	}
#endif
	else{
#ifdef CONFIG_QCA_MMC
		blk_dev = mmc_get_dev(mmc_host.dev_num);
                ret = get_partition_info_efi_by_name(blk_dev, "0:ART", &disk_info);
                /*
                 * ART partition 0th position will contain MAC address.
                 * Read 1 block.
                 */
                if (ret == 0) {
                        mmc = mmc_host.mmc;
                        ret = mmc->block_dev.block_read
                                (mmc_host.dev_num, (disk_info.start+(offset/512)),
                                                1, mmc_blks);
                        memcpy(caldata, (mmc_blks+(offset%512)), length);
                }
                if (ret < 0)
                        printf("ART partition read failed..\n");
#endif
	}

	/*
	*  Avoid unused warning
	*  */
	(void)flash_type;

	return ret;

}

void board_update_caldata()
{
	u32 reg_val=0u;
	s32 ret = 0 ;
	u32 u32_calDataOffset = 0U;
	u32 u32_calData = 0u;
	u32 u32_CDACIN =0U, u32_CDACOUT = 0u;
	int node_off,slotId;

	node_off = fdt_path_offset(gd->fdt_blob, "/slot_Id");
	if (node_off < 0) {
                 printf("%s: Unable to find slot-Id, Default CapIn/CapOut values used\n",
                                 __func__);
                 return;
         }

	slotId = fdtdec_get_uint(gd->fdt_blob,node_off, "slotId", 0);

	u32_calDataOffset  = (u32)(((slotId*150)+4)*1024 + 0x106E4);
	ret = get_eth_caldata(&u32_calData,u32_calDataOffset);
	if (ret < 0)
		return;

	u32_CDACIN = u32_calData & 0x3FF;
	u32_CDACOUT = (u32_calData >> 16) & 0x1FFu;

	if(((u32_CDACIN == 0x0u) || (u32_CDACIN == 0x3FFu)) && ((u32_CDACOUT == 0x0u) || (u32_CDACOUT == 0x1FFu)))
	{
		u32_CDACIN = 0x230;
		u32_CDACOUT = 0xB0;
	}
	u32_CDACIN = u32_CDACIN<<22u;
	u32_CDACOUT = u32_CDACOUT<<13u;

	qca_scm_call_read(0x2, 0x22, (u32 *)IRON2G_RFA_RFA_OTP_OTP_OV_1,&reg_val);
	reg_val = (reg_val & 0xFFF9FFFF) | (0x3 << 17u);
	qca_scm_call_write(0x2, 0x23,(u32 *)IRON2G_RFA_RFA_OTP_OTP_OV_1, reg_val);

	qca_scm_call_read(0x2, 0x22, (u32 *)IRON2G_RFA_RFA_OTP_OTP_XO_0,&reg_val);

	if((u32_CDACIN == (reg_val & (0x3FF<<22u))) && (u32_CDACOUT == (reg_val & (0x1FF<<13u))))
	{
		printf("ART data same as IRON2G_RFA_RFA_OTP_OTP_XO_0\n");
		return;
	}

	reg_val = ((reg_val&0x00001FFF) | ((u32_CDACIN | u32_CDACOUT)&(~0x00001FFF)));
	qca_scm_call_write(0x2, 0x23,(u32 *)IRON2G_RFA_RFA_OTP_OTP_XO_0, reg_val);
}

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_qpic(void *blob)
{
	int node_off, ret;
	const char *qpic_node = {"/soc/qpic-nand@79b0000"};

	/* This fixup is for qpic io_macro_clk
	 * frequency & phase value
	 */
	node_off = fdt_path_offset(blob, qpic_node);
	if (node_off < 0) {
		printf("%s: QPIC: unable to find node '%s'\n",
				__func__, qpic_node);
		return;
	}

	ret = fdt_setprop_u32(blob, node_off, "qcom,iomacromax_clk", qpic_frequency);
	if (ret) {
		printf("%s : Unable to set property 'qcom,iomacromax_clk'\n",__func__);
		return;
	}

	ret = fdt_setprop_u32(blob, node_off, "qcom,phase", qpic_phase);
	if (ret) {
		printf("%s : Unable to set property 'qcom,phase'\n",__func__);
		return;
	}
}

void fdt_fixup_bt_debug(void *blob)
{
	int node, phandle;
	char node_name[32];

	if ((gd->bd->bi_arch_number == MACH_TYPE_IPQ5018_AP_MP02_1) ||
		(gd->bd->bi_arch_number == MACH_TYPE_IPQ5018_DB_MP02_1)) {
		node = fdt_path_offset(blob, "/soc/pinctrl@1000000/btss_pins");
		if (node >= 0) {
			phandle = fdtdec_get_int(blob, node, "phandle", 0);
			snprintf(node_name,
				sizeof(node_name),
				"%s%d",
				"/soc/bt@7000000%pinctrl-0%",
				phandle);
			parse_fdt_fixup("/soc/bt@7000000%pinctrl-names%?btss_pins", blob);
			parse_fdt_fixup(node_name, blob);
		}
		parse_fdt_fixup("/soc/mdio@90000/%delete%status", blob);
		parse_fdt_fixup("/soc/mdio@90000/%status%?disabled", blob);
	}
	parse_fdt_fixup("/soc/serial@78b0000/%status%?ok", blob);
	parse_fdt_fixup("/soc/usb3@8A00000/%delete%device-power-gpio", blob);
}
#endif

#ifdef CONFIG_IPQ_TINY
void fdt_fixup_art_format(void *blob)
{
	int nodeoffset;
	nodeoffset = fdt_path_offset(blob, "/");
	fdt_add_subnode(blob, nodeoffset, "compressed_art");

}
#endif

#ifndef CONFIG_CMD_DISABLE_EXECTZT
void run_tzt(void *address)
{
	execute_tzt(address);
}
#endif

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_set_dload_warm_reset(void *blob)
{
	int nodeoff, ret;
	uint32_t setval = 1;

	nodeoff = fdt_path_offset(blob, "/soc/qca,scm_restart_reason");
	if (nodeoff < 0) {
		nodeoff = fdt_path_offset(blob, "/qti,scm_restart_reason");
		if (nodeoff < 0) {
			printf("fixup_set_dload: unable to find scm_restart_reason node\n");
			return;
		}
	}

	ret = fdt_setprop_u32(blob, nodeoff, "dload_status", setval);
	if (ret)
		printf("fixup_set_dload: 'dload_status' not set");

	ret = fdt_setprop_u32(blob, nodeoff, "dload_warm_reset", setval);
	if (ret)
		printf("fixup_set_dload: 'dload_warm_reset' not set");
}
#endif

#ifdef CONFIG_SMP_CMD_SUPPORT
int is_secondary_core_off(unsigned int cpuid)
{
	int err;

	err = __invoke_psci_fn_smc(ARM_PSCI_TZ_FN_AFFINITY_INFO, cpuid, 0, 0);

	return err;
}

void bring_secondary_core_down(unsigned int state)
{
	__invoke_psci_fn_smc(ARM_PSCI_TZ_FN_CPU_OFF, state, 0, 0);
}

int bring_sec_core_up(unsigned int cpuid, unsigned int entry, unsigned int arg)
{
	int err;

	err = __invoke_psci_fn_smc(ARM_PSCI_TZ_FN_CPU_ON, cpuid, entry, arg);
	if (err) {
		printf("Enabling CPU%d via psci failed!\n", cpuid);
		return -1;
	}

	printf("Enabled CPU%d via psci successfully!\n", cpuid);
	return 0;
}
#endif

unsigned int get_dts_machid(unsigned int machid)
{
	switch (machid)
	{
		case MACH_TYPE_IPQ5018_AP_MP05_1:
			return MACH_TYPE_IPQ5018_AP_MP03_3;
		default:
			return machid;
	}
}

void ipq_uboot_fdt_fixup(void)
{
	init_config_list();
	switch (gd->bd->bi_arch_number)
	{
		case MACH_TYPE_IPQ5018_AP_MP05_1:
			add_config_entry("config@mp05.1");
			add_config_entry("config-mp05.1");
			break;
		default:
			add_config_list_from_fdt();
	}
	return;
}

int get_soc_hw_version(void)
{
	return readl(TCSR_SOC_HW_VERSION_REG);
}

void sdi_disable(void)
{
	qca_scm_sdi();
}

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_for_atf(void *blob)
{
	if (fdt_path_offset(blob, "/soc/dma@704000") >= 0) {
		parse_fdt_fixup("/soc/dma@704000%qcom,controlled-remotely%0",
				blob);
		parse_fdt_fixup("/soc/dma@704000%qti,config-pipe-trust-reg%2",
				blob);
	}
}
#endif
