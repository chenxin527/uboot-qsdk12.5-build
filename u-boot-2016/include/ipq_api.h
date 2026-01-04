#define RESET_BUTTON_IS_PRESSED        0
#define WPS_BUTTON_IS_PRESSED          0
#define SCREEN_BUTTON_IS_PRESSED       0

#if defined(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_02) || \
    defined(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_SS_01) || \
    defined(CONFIG_TARGET_IPQ6018_LINK_NN6000)
#define HAS_WPS_KEY 1
#endif

#if defined(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_02)
#define HAS_SCREEN_KEY 1
#endif

enum {
    WEBFAILSAFE_PROGRESS_START,
    WEBFAILSAFE_PROGRESS_TIMEOUT,
    WEBFAILSAFE_PROGRESS_UPLOAD_READY,
    WEBFAILSAFE_PROGRESS_UPGRADE_READY,
    WEBFAILSAFE_PROGRESS_UPGRADE_FAILED,
};

enum {
    WEBFAILSAFE_UPGRADE_TYPE_FIRMWARE,
    WEBFAILSAFE_UPGRADE_TYPE_UBOOT,
    WEBFAILSAFE_UPGRADE_TYPE_ART,
    WEBFAILSAFE_UPGRADE_TYPE_IMG,
    WEBFAILSAFE_UPGRADE_TYPE_CDT,
    WEBFAILSAFE_UPGRADE_TYPE_UIMAGE,
};

enum {
    FW_TYPE_UNKNOWN = -1,
    FW_TYPE_CDT,
    FW_TYPE_ELF,
    FW_TYPE_EMMC,
    FW_TYPE_FACTORY_KERNEL6M,
    FW_TYPE_FACTORY_KERNEL12M,
    FW_TYPE_FIT,
    FW_TYPE_JDCLOUD,
    FW_TYPE_SYSUPGRADE,
    FW_TYPE_UBI,
};

#define CONFIG_LOADADDR                                 0x44000000
#define WEBFAILSAFE_UPLOAD_RAM_ADDRESS                  0x50000000

#define WEBFAILSAFE_UPLOAD_PADDING_SIZE_IN_BYTES        (1024*1024)
#define WEBFAILSAFE_UPLOAD_UBOOT_SIZE_IN_BYTES          (640*1024)
#define WEBFAILSAFE_UPLOAD_ART_SIZE_IN_BYTES            (256*1024)
#define WEBFAILSAFE_UPLOAD_ART_BIG_SIZE_IN_BYTES        (512*1024)
#define WEBFAILSAFE_UPLOAD_CDT_SIZE_IN_BYTES            (256*1024)

#define HEADER_MAGIC_CDT         0x00544443
#define HEADER_MAGIC_ELF         0x464C457F
#define HEADER_MAGIC_EMMC        0xAA55
#define HEADER_MAGIC_FIT         0xEDFE0DD0
#define HEADER_MAGIC_JDCLOUD     0x73616C46
#define HEADER_MAGIC_SQUASHFS    0x73717368
#define HEADER_MAGIC_SYSUPGRADE1 0x75737973
#define HEADER_MAGIC_SYSUPGRADE2 0x61726770
#define HEADER_MAGIC_UBI         0x23494255

int check_fw_type(void *address);
int check_fw_compat(const int upgrade_type, const int fw_type, const ulong file_size_in_bytes);
void print_fw_type(int fw_type);
void led_toggle(const char *gpio_name);
void led_on(const char *gpio_name);
void led_off(const char *gpio_name);
void check_button_is_pressed(void);
