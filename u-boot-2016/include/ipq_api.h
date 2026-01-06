#define RESET_BUTTON_IS_PRESSED        0
#define WPS_BUTTON_IS_PRESSED          0
#define SCREEN_BUTTON_IS_PRESSED       0

/* 有 WPS 键的机型*/
#if defined(CONFIG_TARGET_IPQ6018_CMIOT_AX18) || \
    defined(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_02) || \
    defined(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_SS_01) || \
    defined(CONFIG_TARGET_IPQ6018_LINK_NN6000) || \
    defined(CONFIG_TARGET_IPQ6018_QIHOO_360V6) || \
    defined(CONFIG_TARGET_IPQ6018_ZN_M2)
#define HAS_WPS_KEY 1
#endif

/* 有 SCREEN 键的机型*/
#if defined(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_02)
#define HAS_SCREEN_KEY 1
#endif

/* eMMC 机型*/
#if defined(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_02) || \
    defined(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_CS_07) || \
    defined(CONFIG_TARGET_IPQ6018_JDCLOUD_RE_SS_01) || \
    defined(CONFIG_TARGET_IPQ6018_LINK_NN6000) || \
    defined(CONFIG_TARGET_IPQ6018_REDMI_AX5_JDCLOUD)
#define MACHINE_FLASH_TYPE_EMMC 1
#endif

/* NOR + eMMC 机型*/
#if defined(CONFIG_TARGET_IPQ6018_PHILIPS_LY1800) || \
    defined(CONFIG_TARGET_IPQ6018_SY_Y6010)
#define MACHINE_FLASH_TYPE_NORPLUSEMMC 1
#endif

/* NAND 机型 */
#if defined(CONFIG_TARGET_IPQ6018_CMIOT_AX18) || \
    defined(CONFIG_TARGET_IPQ6018_QIHOO_360V6) || \
    defined(CONFIG_TARGET_IPQ6018_ZN_M2)
#define MACHINE_FLASH_TYPE_NAND 1
#endif

/* 原生内存只有 256MB 的机型 */
#if defined(CONFIG_TARGET_IPQ6018_CMIOT_AX18) || \
    defined(CONFIG_TARGET_IPQ6018_ZN_M2)
#define MACHINE_ORIGINAL_RAM_SIZE_256M 1
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
    FW_TYPE_CDT,                /* CDT 文件 */
    FW_TYPE_ELF,                /* ELF 文件 (除了 U-Boot 外, SBL1, QSEE, RPM, DEVCFG 等也是 ELF 文件) */
    FW_TYPE_EMMC,               /* eMMC 的 GPT 分区表或镜像，只要开头有 GPT 信息即可 */
    FW_TYPE_FACTORY_KERNEL6M,   /* Factory 格式的固件 (Kernel 大小: 6MB) */
    FW_TYPE_FACTORY_KERNEL12M,  /* Factory 格式的固件 (Kernel 大小: 12MB) */
    FW_TYPE_FIT,                /* FIT Image，包括 Factory Image 和 FIT uImage */
    FW_TYPE_JDCLOUD,            /* JDCloud 官方原厂固件 */
    FW_TYPE_MIBIB_NAND,         /* NAND 的 MIBIB 分区表 */
    FW_TYPE_MIBIB_NOR,          /* SPI-NOR 的 MIBIB 分区表 */
    FW_TYPE_NAND,               /* NAND 的镜像，只需以 SBL1 开头即可 */
    FW_TYPE_NOR,                /* SPI-NOR 的镜像，至少包含 SBL1 和 MIBIB */
    FW_TYPE_SYSUPGRADE,         /* Sysupgrade Tar 格式的固件 */
    FW_TYPE_UBI,                /* UBI 固件（针对 NAND 机型） */
};

/*
 * 为了可以上传更大的固件，将上传地址从 0x44000000 改为 0x50000000 避免内存 crash 重启
 * 针对原生内存只有 256MB 的机型，上传地址仍使用 0x44000000
 */
#if defined(MACHINE_ORIGINAL_RAM_SIZE_256M)
#define WEBFAILSAFE_UPLOAD_RAM_ADDRESS                  0x44000000
#else
#define WEBFAILSAFE_UPLOAD_RAM_ADDRESS                  0x50000000
#endif
#define CONFIG_LOADADDR                                 0x44000000

#define WEBFAILSAFE_UPLOAD_PADDING_SIZE_IN_BYTES        (1024*1024)
#define WEBFAILSAFE_UPLOAD_UBOOT_SIZE_IN_BYTES          (640*1024)
#define WEBFAILSAFE_UPLOAD_ART_SIZE_IN_BYTES            (256*1024)
#define WEBFAILSAFE_UPLOAD_ART_BIG_SIZE_IN_BYTES        (512*1024)
#define WEBFAILSAFE_UPLOAD_CDT_SIZE_IN_BYTES            (256*1024)

#define WEBFAILSAFE_UPLOAD_CDT_SIZE_IN_BYTES_NAND       (512*1024)
#define WEBFAILSAFE_UPLOAD_MIBIB_SIZE_IN_BYTES_NAND     (1024*1024)
#define WEBFAILSAFE_UPLOAD_UBOOT_SIZE_IN_BYTES_NAND     (1536*1024)

#define WEBFAILSAFE_UPLOAD_CDT_SIZE_IN_BYTES_NOR        (64*1024)
#define WEBFAILSAFE_UPLOAD_MIBIB_SIZE_IN_BYTES_NOR      (64*1024)

/*
 * MIBIB for SPI-NOR or NAND FLASH
 * MBN Header Magic: AC 9F 56 FE 7A 12 7F CD
 * Partition Table offset for SPI-NOR: 0x100, for NAND: 0x800.
 * Partition Table Header Magic: AA 73 EE 55 DB BD 5E E3
 */
#define HEADER_MAGIC_MBN1        0xFE569FAC
#define HEADER_MAGIC_MBN2        0xCD7F127A
#define HEADER_MAGIC_MBN         0xCD7F127AFE569FAC
#define HEADER_MAGIC_PTABLE      0xE35EBDDB55EE73AA

/*
 * For NAND IMAGE, only check SBL1 Header: D1 DC 4B 84 34 10 D7 73
 */
#define HEADER_MAGIC_SBL_NAND1   0x844BDCD1
#define HEADER_MAGIC_SBL_NAND2   0x73D71034

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
