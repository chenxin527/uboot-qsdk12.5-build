#include <common.h>
#include <cli.h>
#include <ipq_api.h>
#include <asm/gpio.h>
#include <fdtdec.h>
#include <part.h>
#include <mmc.h>
#include <sdhci.h>
#include <cmd_untar.h>

#ifndef CONFIG_SDHCI_SUPPORT
extern qca_mmc mmc_host;
#else
extern struct sdhci_host mmc_host;
#endif

DECLARE_GLOBAL_DATA_PTR;

void led_toggle(const char *gpio_name)
{

	int node, value;
	unsigned int gpio;
	node = fdt_path_offset(gd->fdt_blob, gpio_name);
	if (node < 0) {
		printf("Could not find %s node in fdt\n", gpio_name);
		return;
	}
	gpio = fdtdec_get_uint(gd->fdt_blob, node, "gpio", 0);
	if (gpio < 0) {
		printf("Could not find %s node's gpio in fdt\n", gpio_name);
		return;
	}

	value = gpio_get_value(gpio);
	value = !value;
	gpio_set_value(gpio, value);
}

void led_on(const char *gpio_name)
{
	int node;
	unsigned int gpio;
	node = fdt_path_offset(gd->fdt_blob, gpio_name);
	if (node < 0) {
		printf("Could not find %s node in fdt\n", gpio_name);
		return;
	}
	gpio = fdtdec_get_uint(gd->fdt_blob, node, "gpio", 0);
	if (gpio < 0) {
		printf("Could not find %s node's gpio in fdt\n", gpio_name);
		return;
	}

	gpio_set_value(gpio, 1);
}

void led_off(const char *gpio_name)
{
	int node;
	unsigned int gpio;
	node = fdt_path_offset(gd->fdt_blob, gpio_name);
	if (node < 0) {
		printf("Could not find %s node in fdt\n", gpio_name);
		return;
	}
	gpio = fdtdec_get_uint(gd->fdt_blob, node, "gpio", 0);
	if (gpio < 0) {
		printf("Could not find %s node's gpio in fdt\n", gpio_name);
		return;
	}

	gpio_set_value(gpio, 0);
}

bool button_is_pressed(const char *gpio_name, int value)
{
	int node;
	unsigned int gpio;
	node = fdt_path_offset(gd->fdt_blob, gpio_name);
	if (node < 0) {
		printf("Could not find %s node in fdt\n", gpio_name);
		return false;
	}
	gpio = fdtdec_get_uint(gd->fdt_blob, node, "gpio", 0);
	if (gpio < 0) {
		printf("Could not find %s node's gpio in fdt\n", gpio_name);
		return false;
	}

	if (gpio_get_value(gpio) == value)
	{
		mdelay(10);
		if (gpio_get_value(gpio) == value)
			return true;
		else
			return false;
	}
	else
		return false;
}

void check_button_is_pressed(void)
{
	int counter = 0;
	char *button_name = NULL;

	// 检测哪个按键被按下
    if (button_is_pressed("reset_key", RESET_BUTTON_IS_PRESSED)) {
        button_name = "RESET";
    }
#if defined(HAS_WPS_KEY)
	else if (button_is_pressed("wps_key", WPS_BUTTON_IS_PRESSED)) {
        button_name = "WPS";
    }
#endif
#if defined(HAS_SCREEN_KEY)
	else if (button_is_pressed("screen_key", SCREEN_BUTTON_IS_PRESSED)) {
        button_name = "SCREEN";
    }
#endif

	// 如果任一按键被按下
	while (button_name != NULL) {
		// 重新检测按键状态
        int still_pressed = 0;

        if (strcmp(button_name, "RESET") == 0) {
            still_pressed = button_is_pressed("reset_key", RESET_BUTTON_IS_PRESSED);
        }
#if defined(HAS_WPS_KEY)
		else if (strcmp(button_name, "WPS") == 0) {
            still_pressed = button_is_pressed("wps_key", WPS_BUTTON_IS_PRESSED);
        }
#endif
#if defined(HAS_SCREEN_KEY)
		else if (strcmp(button_name, "SCREEN") == 0) {
            still_pressed = button_is_pressed("screen_key", SCREEN_BUTTON_IS_PRESSED);
        }
#endif

        if (!still_pressed)
            break;  // 按键已释放

		if (counter == 0) {
#if defined(CONFIG_IPQ_ETH_INIT_DEFER)
			puts("Net:   ");
			eth_initialize();
#endif
			printf("%s button is pressed for: %2d ", button_name, counter);
		}

		// LED 闪烁
		led_off("power_led");
		mdelay(350);
		led_on("power_led");
		mdelay(350);

		counter++;

		// how long the button is pressed?
		printf("\b\b\b%2d ", counter);

		if (counter >= 5) {
			led_off("power_led");
			led_on("blink_led");
			printf("\n");
			run_command("httpd 192.168.1.1", 0);
			cli_loop();
			break;
		}
	}

	if (counter != 0)
		printf("\n");

	return;
}

// 只检查文件的开头几个特殊 Magic Num
int check_fw_type(void *address) {
	u32 *header_magic1 = (u32 *)(address);
	u32 *header_magic2 = (u32 *)(address + 0x4);

	switch (*header_magic1) {
		case HEADER_MAGIC_CDT:
			return FW_TYPE_CDT;
		case HEADER_MAGIC_ELF:
			return FW_TYPE_ELF;
		case HEADER_MAGIC_FIT:
			if (*((u32 *)(address + 0x5C)) == HEADER_MAGIC_JDCLOUD)
				return FW_TYPE_JDCLOUD;
			else if (*((u32 *)(address + 0x600000)) == HEADER_MAGIC_SQUASHFS)
				return FW_TYPE_FACTORY_KERNEL6M;
			else if (*((u32 *)(address + 0xC00000)) == HEADER_MAGIC_SQUASHFS)
				return FW_TYPE_FACTORY_KERNEL12M;
			else
				return FW_TYPE_FIT;
		case HEADER_MAGIC_SYSUPGRADE1:
			if (*header_magic2 == HEADER_MAGIC_SYSUPGRADE2)
				return FW_TYPE_SYSUPGRADE;
			return FW_TYPE_UNKNOWN;
		case HEADER_MAGIC_UBI:
			return FW_TYPE_UBI;
		default:
			if (*((u16 *)(address + 0x1FE)) == HEADER_MAGIC_EMMC)
				return FW_TYPE_EMMC;
			else
				return FW_TYPE_UNKNOWN;
	}
}

void print_fw_type(int fw_type) {
	printf("* The upload file type: ");
	switch (fw_type) {
		case FW_TYPE_CDT:
			printf("CDT");
			break;
		case FW_TYPE_ELF:
			printf("ELF");
			break;
		case FW_TYPE_EMMC:
			printf("EMMC IMAGE");
			break;
		case FW_TYPE_FACTORY_KERNEL6M:
			printf("FACTORY FIRMWARE (KERNEL SIZE: 6MB)");
			break;
		case FW_TYPE_FACTORY_KERNEL12M:
			printf("FACTORY FIRMWARE (KERNEL SIZE: 12MB)");
			break;
		case FW_TYPE_FIT:
			printf("FIT IMAGE");
			break;
		case FW_TYPE_JDCLOUD:
			printf("JDCLOUD OFFICIAL FIRMWARE");
			break;
		case FW_TYPE_SYSUPGRADE:
			printf("SYSUPGRADE FIRMWARE");
			break;
		case FW_TYPE_UBI:
			printf("UBI FIRMWARE");
			break;
		case FW_TYPE_UNKNOWN:
		default:
			printf("UNKNOWN");
	}
	printf(" *");
	return;
}

int image_greater_than_partition(char *part_name, char *file_name, ulong file_size_in_bytes) {
    block_dev_desc_t *blk_dev;
    disk_partition_t disk_info = {0};
    ulong part_size_in_blocks = 0;
    ulong file_size_in_blocks = 0;

    blk_dev = mmc_get_dev(mmc_host.dev_num);
    if (blk_dev == NULL)
        return 1;
    if (get_partition_info_efi_by_name(blk_dev, part_name, &disk_info)) {
        printf("\n\nPartition %s not found!", part_name);
        return 1;
    }
    part_size_in_blocks = (ulong)disk_info.size;

    if (disk_info.blksz) {
        file_size_in_blocks = file_size_in_bytes / disk_info.blksz;
        ulong adj_size = file_size_in_bytes % disk_info.blksz;
        if (adj_size)
            file_size_in_blocks += 1;
    }

    if (file_size_in_blocks > part_size_in_blocks) {
        printf("\n\n* Error: image %s size (%lu bytes) > partition %s size (%lu bytes)! *",
			   file_name, file_size_in_bytes, part_name, part_size_in_blocks * disk_info.blksz);
        return 1;
    }

    return 0;
}

int check_fw_compat(const int upgrade_type, const int fw_type, const ulong file_size_in_bytes) {
	switch (upgrade_type) {
		case WEBFAILSAFE_UPGRADE_TYPE_FIRMWARE:
			switch (fw_type) {
				case FW_TYPE_FACTORY_KERNEL6M:
					return (image_greater_than_partition("0:HLOS", "kernel", 6*1024*1024) ||
							image_greater_than_partition("rootfs", "rootfs", file_size_in_bytes - 6*1024*1024));
				case FW_TYPE_FACTORY_KERNEL12M:
					return (image_greater_than_partition("0:HLOS", "kernel", 12*1024*1024) ||
							image_greater_than_partition("rootfs", "rootfs", file_size_in_bytes - 12*1024*1024));
				case FW_TYPE_SYSUPGRADE: {
					const void *kernel_addr, *rootfs_addr;
					size_t kernel_size, rootfs_size;
					if (parse_tar_image((void *)WEBFAILSAFE_UPLOAD_RAM_ADDRESS, (size_t)file_size_in_bytes,
										&kernel_addr, &kernel_size,
										&rootfs_addr, &rootfs_size)
					) {
						printf("\n\n* The upload file is NOT valid SYSUPGRADE IMAGE!! *");
						return 1;
					}
					return (image_greater_than_partition("0:HLOS", "kernel", kernel_size) ||
							image_greater_than_partition("rootfs", "rootfs", rootfs_size));
				}
				case FW_TYPE_JDCLOUD:
					break;
				default:
					printf("\n\n* The upload file is NOT supported FIRMWARE!! *\n\n");
					print_fw_type(fw_type);
					return 1;
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_UBOOT:
			if (fw_type != FW_TYPE_ELF) {
				printf("\n\n* The upload file is NOT supported UBOOT ELF!! *\n\n");
				print_fw_type(fw_type);
				return 1;
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_IMG:
			if (fw_type != FW_TYPE_EMMC) {
				printf("\n\n* The upload file is NOT supported EMMC IMG!! *\n\n");
				print_fw_type(fw_type);
				return 1;
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_CDT:
			if (fw_type != FW_TYPE_CDT) {
				printf("\n\n* The upload file is NOT supported CDT!! *\n\n");
				print_fw_type(fw_type);
				return 1;
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_UIMAGE:
			if (fw_type != FW_TYPE_FIT) {
				printf("\n\n* The upload file is NOT supported FIT uImage!! *\n\n");
				print_fw_type(fw_type);
				return 1;
			}
			break;
		case WEBFAILSAFE_UPGRADE_TYPE_ART:
			break;
		default:
			printf("\n\n* NOT supported WEBFAILSAFE UPGRADE TYPE!! *");
			return 1;
	}

	return 0;
}
