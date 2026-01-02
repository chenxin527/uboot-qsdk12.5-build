#define CONFIG_MIPS32 1   /* MIPS32 CPU core  */
#define CONFIG_BOOTDELAY 2   /* autoboot after 4 seconds */
#define CONFIG_TIMESTAMP	/* Print image info with timestamp */

/*
 * Console I/O configuration
 */
#define CONFIG_BAUDRATE 115200
#define CONFIG_SYS_BAUDRATE_TABLE  {115200}

/* Console I/O Buffer Size */
#define CONFIG_SYS_CBSIZE               512
/* Print Buffer Size */
#define CONFIG_SYS_PBSIZE (CONFIG_SYS_CBSIZE+sizeof(CONFIG_SYS_PROMPT)+16)

#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_SYS_PROMPT_HUSH_PS2      "hush>"

/*
 * FLASH and environment organization
 */
#ifndef FLASH_SIZE
#define FLASH_SIZE 16
#endif

#define CONFIG_SYS_MAX_FLASH_BANKS 1       /* max number of memory banks */
#define CFG_MAX_FLASH_BANKS 1 /* max number of memory banks */

#if (FLASH_SIZE == 16)
#define CFG_MAX_FLASH_SECT      256     /* max number of sectors on one chip */
#define ATH_MTDPARTS_MIB0       "8256k(mib0)"
#elif (FLASH_SIZE == 8)
#define CFG_MAX_FLASH_SECT      128     /* max number of sectors on one chip */
#define ATH_MTDPARTS_MIB0       "64k(mib0)"
#else
#define CFG_MAX_FLASH_SECT      64      /* max number of sectors on one chip */
#define ATH_MTDPARTS_MIB0       "64k(mib0)"
#endif

#define CFG_FLASH_SECTOR_SIZE   (64*1024)
#if (FLASH_SIZE == 16)
#define CFG_FLASH_SIZE          0x01000000      /* Total flash size */
#elif (FLASH_SIZE == 8)
#define CFG_FLASH_SIZE          0x00800000      /* max number of sectors on one chip */
#else
#define CFG_FLASH_SIZE          0x00400000      /* Total flash size */
#endif

#ifndef COMPRESSED_UBOOT
#define ENABLE_DYNAMIC_CONF     1
#endif

#if (CFG_MAX_FLASH_SECT * CFG_FLASH_SECTOR_SIZE) != CFG_FLASH_SIZE
#       error "Invalid flash configuration"
#endif

#define CFG_FLASH_WORD_SIZE     unsigned short

#if defined(CONFIG_ATH_NAND_BR) && defined(COMPRESSED_UBOOT)
#define CFG_FLASH_BASE                  0xa0100000
#else
/* NOR Flash start address */
#define CFG_FLASH_BASE	0x9f000000
#define CONFIG_SYS_TEXT_BASE	0x9f000000
#endif

#ifdef COMPRESSED_UBOOT
#define BOOTSTRAP_TEXT_BASE             CFG_FLASH_BASE
#define BOOTSTRAP_CFG_MONITOR_BASE      BOOTSTRAP_TEXT_BASE
#endif

#define CONFIG_PCI_CONFIG_DATA_IN_OTP

/*
 * Defines to change flash size on reboot
 */
#ifdef ENABLE_DYNAMIC_CONF
#define UBOOT_FLASH_SIZE                (256 * 1024)
#define UBOOT_ENV_SEC_START             (CFG_FLASH_BASE + UBOOT_FLASH_SIZE)

#define CFG_FLASH_MAGIC                 0xaabacada
#define CFG_FLASH_MAGIC_F               (UBOOT_ENV_SEC_START + CFG_FLASH_SECTOR_SIZE - 0x20)
#define CFG_FLASH_SECTOR_SIZE_F         *(volatile int *)(CFG_FLASH_MAGIC_F + 0x4)
#define CFG_FLASH_SIZE_F                *(volatile int *)(CFG_FLASH_MAGIC_F + 0x8) /* Total flash size */
#else
#define CFG_FLASH_SIZE_F                CFG_FLASH_SIZE
#define CFG_FLASH_SECTOR_SIZE_F         CFG_FLASH_SECTOR_SIZE
#endif

/*
** Parameters defining the location of the calibration/initialization
** information for the two Merlin devices.
** NOTE: **This will change with different flash configurations**
*/

#define WLANCAL	0x9fff1000
#define BOARDCAL	0x9fff0000
#define ATHEROS_PRODUCT_ID	137
#define CAL_SECTOR	(CFG_MAX_FLASH_SECT - 1)

/* For Merlin, both PCI, PCI-E interfaces are valid */
#define ATH_ART_PCICFG_OFFSET           12

/*
 * The following for ENV settings
 */

#define CONFIG_SYS_MAXARGS 16
#define CONFIG_SYS_FLASH_BASE	0x9f000000
#define CONFIG_SYS_MAX_FLASH_SECT	256

#define CONFIG_ENV_IS_IN_FLASH  1
#define CONFIG_ENV_SIZE CFG_FLASH_SECTOR_SIZE //CFG_ENV_SIZE
#define CONFIG_ENV_ADDR 0x9f040000

/* Timer Specific */
#define CONFIG_SYS_MHZ  720
/* Since the count is incremented every other tick, divide by 2 -- CFG_HZ*/
#define CONFIG_SYS_MIPS_TIMER_FREQ      ((CONFIG_SYS_MHZ * 1000000)/2)

#define CFG_DDR_REFRESH_VAL             0x4138

/*
 * The following #defines are needed to get flash environment right
 */
#define CONFIG_SYS_MONITOR_BASE 0x9f000000
#define CONFIG_SYS_MONITOR_LEN  (192 << 10)
#define CONFIG_SYS_MALLOC_LEN (128*1024)
#define CONFIG_SYS_BOOTPARAMS_LEN (64*1024)
/*
 * Cache Configuration
 */
#define CONFIG_SYS_CACHELINE_SIZE 32
#define CONFIG_SYS_ICACHE_SIZE 65536
#define CONFIG_SYS_DCACHE_SIZE 32768

#define CONFIG_PCI 1
#define CONFIG_CMD_PCI
#define CONFIG_PCI_SCAN_SHOW

/*#define CONFIG_USB 1*/

#define CONFIG_ATH_SOC 1
#define CONFIG_ATHEROS	1
#define CONFIG_MACH_QCA955x 1
/*#define CFG_INIT_STACK_IN_SRAM 1 -- OBSOLETE.*/
#define __CONFIG_BOARD_NAME ap135
#define CONFIG_BOARD_NAME "ap135"
#define CFG_PLL_FREQ CFG_PLL_720_600_200
#define ATH_SGMII_FORCED 1
#define CONFIG_ATHRS17_PHY 1
#define CFG_ATH_GMAC_NMACS 2
#define CFG_ATH_GE1_IS_CONNECTED 1
#define CONFIG_ATHRS_GMAC_SGMII 1
#define CONFIG_ATH_S17_WAN 1
#define ATH_S17_MAC0_SGMII 1
#define ATH_SGMII_FORCED_MODE 1
#define ATH_RGMII_CAL 1
#define CONFIG_LAST_STAGE_INIT
#define CONFIG_DISPLAY_BOARDINFO 1
#define CONFIG_CUSTOM_BOARDINFO 1

#define CONFIG_SYS_SDRAM_BASE 0x80000000
#define CONFIG_SYS_LOAD_ADDR 0x81000000

/*
 * Cache lock for stack
 */
#define CONFIG_SYS_INIT_SP_OFFSET 0x1000
#define CFG_INIT_SRAM_SP_OFFSET 0xbd007000

/*
 * Image type
 */
#define CONFIG_LZMA 1
#define CONFIG_IMAGE_FORMAT_LEGACY

/*
 * ethernet environment
 */
#define CONFIG_SYS_RX_ETH_BUFFER 8
#define CONFIG_TFTP_BLOCKSIZE 512
#define CONFIG_MII 1
#define CFG_CMD_MII 1
#define CONFIG_COMMANDS 1

