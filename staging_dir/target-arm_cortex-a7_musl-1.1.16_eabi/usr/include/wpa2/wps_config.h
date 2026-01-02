/**************************************************************************
//
//  Copyright (c) 2006-2007 Sony Corporation. All Rights Reserved.
//
//  File Name: wps_config.h
//  Description: EAP-WPS config source header
//
//   Redistribution and use in source and binary forms, with or without
//   modification, are permitted provided that the following conditions
//   are met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in
//       the documentation and/or other materials provided with the
//       distribution.
//     * Neither the name of Sony Corporation nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
//   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**************************************************************************/

#ifndef WPS_CONFIG_H
#define WPS_CONFIG_H

/* WPS_HACK_PADDING -- 
 * wsccmd (for no good reason) put out the maximum size fields
 * for manufacturer, model name, model number and device name
 * by adding null character padding... but for M* messages only,
 * not for probe responses.
 * Apparently in response to this bug in the wsccmd, some supplicants
 * (Ralink, Buffalo) reject M* messages that have shorter fields,
 * even though allowed (required?) by the WPS spec.
 * Set WPS_HACK_PADDING to add null padding to maximum length for M*
 * messages.
 */
#define WPS_HACK_PADDING() 1

#ifdef _MSC_VER
#pragma pack(push, 1)
#endif /* _MSC_VER */

/* Wi-Fi Protected Setup Version */
#define WPS_VERSION		0x10
#define WPS_VERSION_EX	0x11

/* Data Element Definitions */
#define WPS_TYPE_AP_CHANNEL				0x1001
#define WPS_TYPE_ASSOC_STATE			0x1002
#define WPS_TYPE_AUTH_TYPE				0x1003
#define WPS_TYPE_AUTH_TYPE_FLAGS		0x1004
#define WPS_TYPE_AUTHENTICATOR			0x1005
#define WPS_TYPE_CONFIG_METHODS			0x1008
#define WPS_TYPE_CONFIG_ERROR			0x1009
#define WPS_TYPE_CONF_URL4				0x100A
#define WPS_TYPE_CONF_URL6				0x100B
#define WPS_TYPE_CONN_TYPE				0x100C
#define WPS_TYPE_CONN_TYPE_FLAGS		0x100D
#define WPS_TYPE_CREDENTIAL				0x100E
#define WPS_TYPE_DEVICE_NAME			0x1011
#define WPS_TYPE_DEVICE_PWD_ID			0x1012
#define WPS_TYPE_E_HASH1				0x1014
#define WPS_TYPE_E_HASH2				0x1015
#define WPS_TYPE_E_SNONCE1				0x1016
#define WPS_TYPE_E_SNONCE2				0x1017
#define WPS_TYPE_ENCR_SETTINGS			0x1018
#define WPS_TYPE_ENCR_TYPE				0x100F
#define WPS_TYPE_ENCR_TYPE_FLAGS		0x1010
#define WPS_TYPE_ENROLLEE_NONCE			0x101A
#define WPS_TYPE_FEATURE_ID				0x101B
#define WPS_TYPE_IDENTITY				0x101C
#define WPS_TYPE_IDENTITY_PROOF			0x101D
#define WPS_TYPE_KEY_WRAP_AUTH			0x101E
#define WPS_TYPE_KEY_IDENTIFIER			0x101F
#define WPS_TYPE_MAC_ADDR				0x1020
#define WPS_TYPE_MANUFACTURER			0x1021
#define WPS_TYPE_MSG_TYPE				0x1022
#define WPS_TYPE_MODEL_NAME				0x1023
#define WPS_TYPE_MODEL_NUMBER			0x1024
#define WPS_TYPE_NW_INDEX				0x1026
#define WPS_TYPE_NW_KEY					0x1027
#define WPS_TYPE_NW_KEY_INDEX			0x1028
#define WPS_TYPE_NEW_DEVICE_NAME		0x1029
#define WPS_TYPE_NEW_PWD				0x102A
#define WPS_TYPE_OOB_DEV_PWD			0x102C
#define WPS_TYPE_OS_VERSION				0x102D
#define WPS_TYPE_POWER_LEVEL			0x102F
#define WPS_TYPE_PSK_CURRENT			0x1030
#define WPS_TYPE_PSK_MAX				0x1031
#define WPS_TYPE_PUBLIC_KEY				0x1032
#define WPS_TYPE_RADIO_ENABLED			0x1033
#define WPS_TYPE_REBOOT					0x1034
#define WPS_TYPE_REGISTRAR_CURRENT		0x1035
#define WPS_TYPE_REGISTRAR_ESTBLSHD		0x1036
#define WPS_TYPE_REGISTRAR_LIST			0x1037
#define WPS_TYPE_REGISTRAR_MAX			0x1038
#define WPS_TYPE_REGISTRAR_NONCE		0x1039
#define WPS_TYPE_REQ_TYPE				0x103A
#define WPS_TYPE_RESP_TYPE				0x103B
#define WPS_TYPE_RF_BANDS				0x103C
#define WPS_TYPE_R_HASH1				0x103D
#define WPS_TYPE_R_HASH2				0x103E
#define WPS_TYPE_R_SNONCE1				0x103F
#define WPS_TYPE_R_SNONCE2				0x1040
#define WPS_TYPE_SEL_REGISTRAR			0x1041
#define WPS_TYPE_SERIAL_NUM				0x1042
#define WPS_TYPE_WPSSTATE				0x1044
#define WPS_TYPE_SSID					0x1045
#define WPS_TYPE_TOT_NETWORKS			0x1046
#define WPS_TYPE_UUID_E					0x1047
#define WPS_TYPE_UUID_R					0x1048
#define WPS_TYPE_VENDOR_EXT				0x1049
#define WPS_TYPE_VERSION				0x104A
#define WPS_TYPE_X509_CERT_REQ			0x104B
#define WPS_TYPE_X509_CERT				0x104C
#define WPS_TYPE_EAP_IDENTITY			0x104D
#define WPS_TYPE_MSG_COUNTER			0x104E
#define WPS_TYPE_PUBKEY_HASH			0x104F
#define WPS_TYPE_REKEY_KEY				0x1050
#define WPS_TYPE_KEY_LIFETIME			0x1051
#define WPS_TYPE_PERM_CFG_METHODS		0x1052
#define WPS_TYPE_SEL_REG_CFG_METHODS	0x1053
#define WPS_TYPE_PRIM_DEV_TYPE			0x1054
#define WPS_TYPE_SEC_DEV_TYPE_LIST		0x1055
#define WPS_TYPE_PORTABLE_DEVICE		0x1056
#define WPS_TYPE_AP_SETUP_LOCKED		0x1057
#define WPS_TYPE_APP_EXT				0x1058
#define WPS_TYPE_EAP_TYPE				0x1059
#define WPS_TYPE_INIT_VECTOR			0x1060
#define WPS_TYPE_KEY_PROVIDED_AUTO		0x1061
#define WPS_TYPE_8021X_ENABLED			0x1062
#define WPS_TYPE_APP_SESS_KEY			0x1063
#define WPS_TYPE_WEP_TX_KEY				0x1064

/* Association states */
#define WPS_ASSOC_NOT_ASSOCIATED	0
#define WPS_ASSOC_CONN_SUCCESS		1
#define WPS_ASSOC_CONFIG_FAIL		2
#define WPS_ASSOC_ASSOC_FAIL		3
#define WPS_ASSOC_IP_FAIL			4

/* Authentication types */
#define WPS_AUTHTYPE_OPEN		0x0001
#define WPS_AUTHTYPE_WPAPSK		0x0002
#define WPS_AUTHTYPE_SHARED		0x0004
#define WPS_AUTHTYPE_WPA		0x0008
#define WPS_AUTHTYPE_WPA2		0x0010
#define WPS_AUTHTYPE_WPA2PSK	0x0020
#define WPS_AUTHTYPE_WPA_WPA2_PSK   0x0022  /* for WSC 2.0 mixed mode: both WPA/WPA2-PSK enabled */
#define WPS_AUTHTYPE_WPA3		0x0040

/* Config methods */
#define WPS_CONFMET_USBA		0x0001
#define WPS_CONFMET_ETHERNET	0x0002
#define WPS_CONFMET_LABEL		0x0004
#define WPS_CONFMET_DISPLAY		0x0008
#define WPS_CONFMET_EXT_NFC_TOK	0x0010
#define WPS_CONFMET_INT_NFC_TOK	0x0020
#define WPS_CONFMET_NFC_INTF	0x0040
#define WPS_CONFMET_PBC			0x0080
#define WPS_CONFMET_KEYPAD		0x0100

/* WPS error messages */
#define WPS_ERROR_NO_ERROR				0
#define WPS_ERROR_OOB_INT_READ_ERR		1
#define WPS_ERROR_DECRYPT_CRC_FAIL		2
#define WPS_ERROR_CHAN24_NOT_SUPP		3
#define WPS_ERROR_CHAN50_NOT_SUPP		4
#define WPS_ERROR_SIGNAL_WEAK			5
#define WPS_ERROR_NW_AUTH_FAIL			6
#define WPS_ERROR_NW_ASSOC_FAIL			7
#define WPS_ERROR_NO_DHCP_RESP			8
#define WPS_ERROR_FAILED_DHCP_CONF		9
#define WPS_ERROR_IP_ADDR_CONFLICT		10
#define WPS_ERROR_FAIL_CONN_REGISTRAR	11
#define WPS_ERROR_MULTI_PBC_DETECTED	12
#define WPS_ERROR_ROGUE_SUSPECTED		13
#define WPS_ERROR_DEVICE_BUSY			14
#define WPS_ERROR_SETUP_LOCKED			15
#define WPS_ERROR_MSG_TIMEOUT			16
#define WPS_ERROR_REG_SESSION_TIMEOUT	17
#define WPS_ERROR_DEV_PWD_AUTH_FAIL		18

/* Connection types */
#define WPS_CONNTYPE_ESS	0x01
#define WPS_CONNTYPE_IBSS	0x02

/* Device password ID */
#define WPS_DEVICEPWDID_DEFAULT			0x0000
#define WPS_DEVICEPWDID_USER_SPEC		0x0001
#define WPS_DEVICEPWDID_MACHINE_SPEC	0x0002
#define WPS_DEVICEPWDID_REKEY			0x0003
#define WPS_DEVICEPWDID_PUSH_BTN		0x0004
#define WPS_DEVICEPWDID_REG_SPEC		0x0005

/* Device type */
/*
#define WPS_DEVICETYPE_COMPUTER			"Computer"
#define WPS_DEVICETYPE_AP				"Access_Point"
#define WPS_DEVICETYPE_ROUTER_AP		"Router_AP"
#define WPS_DEVICETYPE_PRINTER			"Printer"
#define WPS_DEVICETYPE_PRINTER_BRIDGE	"Printer_Brigde"
#define WPS_DEVICETYPE_ELECT_PIC_FRAME	"Electronic_Picture_Frame"
#define WPS_DEVICETYPE_DIG_AUDIO_RECV	"Digital_Audio_Receiver"
#define WPS_DEVICETYPE_WIN_MCE			"Windows_Media_Center_Extender"
#define WPS_DEVICETYPE_WIN_MOBILE		"Windows_Mobile"
#define WPS_DEVICETYPE_PVR				"Personal_Video_Recorder"
#define WPS_DEVICETYPE_VIDEO_STB		"Video_STB"
#define WPS_DEVICETYPE_PROJECTOR		"Projector"
#define WPS_DEVICETYPE_IP_TV			"IP_TV"
#define WPS_DEVICETYPE_DIG_STILL_CAM	"Digital_Still_Camera"
#define WPS_DEVICETYPE_PHONE			"Phone"
#define WPS_DEVICETYPE_VOID_PHONE		"VoIP_Phone"
#define WPS_DEVICETYPE_GAME_CONSOLE		"Game_console"
#define WPS_DEVICETYPE_OTHER			"Other"
*/

/* Encryption type */
#define WPS_ENCRTYPE_NONE	0x0001
#define WPS_ENCRTYPE_WEP	0x0002
#define WPS_ENCRTYPE_TKIP	0x0004
#define WPS_ENCRTYPE_AES	0x0008
#define WPS_ENCRTYPE_TKIPAES  0x000C  /* for WSC 2.0 mixed mode: both WPA-TKIP and WPA2-AES enabled */


/* WPS Message Types */
#define WPS_MSGTYPE_BEACON		0x01
#define WPS_MSGTYPE_PROBE_REQ	0x02
#define WPS_MSGTYPE_PROBE_RESP	0x03
#define WPS_MSGTYPE_M1			0x04
#define WPS_MSGTYPE_M2			0x05
#define WPS_MSGTYPE_M2D			0x06
#define WPS_MSGTYPE_M3			0x07
#define WPS_MSGTYPE_M4			0x08
#define WPS_MSGTYPE_M5			0x09
#define WPS_MSGTYPE_M6			0x0A
#define WPS_MSGTYPE_M7			0x0B
#define WPS_MSGTYPE_M8			0x0C
#define WPS_MSGTYPE_ACK			0x0D
#define WPS_MSGTYPE_NACK		0x0E
#define WPS_MSGTYPE_DONE		0x0F

/*Device Type categories for primary and secondary device types */
#define WPS_DEVICE_TYPE_CAT_COMPUTER		1
#define WPS_DEVICE_TYPE_CAT_INPUT_DEVICE	2
#define WPS_DEVICE_TYPE_CAT_PRINTER			3
#define WPS_DEVICE_TYPE_CAT_CAMERA			4
#define WPS_DEVICE_TYPE_CAT_STORAGE			5
#define WPS_DEVICE_TYPE_CAT_NW_INFRA		6
#define WPS_DEVICE_TYPE_CAT_DISPLAYS		7
#define WPS_DEVICE_TYPE_CAT_MM_DEVICES		8
#define WPS_DEVICE_TYPE_CAT_GAME_DEVICES	9
#define WPS_DEVICE_TYPE_CAT_TELEPHONE		10

/* Device Type sub categories for primary and secondary device types */
#define WPS_DEVICE_TYPE_SUB_CAT_COMP_PC			1
#define WPS_DEVICE_TYPE_SUB_CAT_COMP_SERVER		2
#define WPS_DEVICE_TYPE_SUB_CAT_COMP_MEDIA_CTR	3
#define WPS_DEVICE_TYPE_SUB_CAT_PRTR_PRINTER	1
#define WPS_DEVICE_TYPE_SUB_CAT_PRTR_SCANNER	2
#define WPS_DEVICE_TYPE_SUB_CAT_CAM_DGTL_STILL	1
#define WPS_DEVICE_TYPE_SUB_CAT_STOR_NAS		1
#define WPS_DEVICE_TYPE_SUB_CAT_NW_AP			1
#define WPS_DEVICE_TYPE_SUB_CAT_NW_ROUTER		2
#define WPS_DEVICE_TYPE_SUB_CAT_NW_SWITCH		3
#define WPS_DEVICE_TYPE_SUB_CAT_DISP_TV			1
#define WPS_DEVICE_TYPE_SUB_CAT_DISP_PIC_FRAME	2
#define WPS_DEVICE_TYPE_SUB_CAT_DISP_PROJECTOR	3
#define WPS_DEVICE_TYPE_SUB_CAT_MM_DAR			1
#define WPS_DEVICE_TYPE_SUB_CAT_MM_PVR			2
#define WPS_DEVICE_TYPE_SUB_CAT_MM_MCX			3
#define WPS_DEVICE_TYPE_SUB_CAT_GAM_XBOX		1
#define WPS_DEVICE_TYPE_SUB_CAT_GAM_XBOX_360	2
#define WPS_DEVICE_TYPE_SUB_CAT_GAM_PS			3
#define WPS_DEVICE_TYPE_SUB_CAT_PHONE_WM		1

/* Device request type */
#define WPS_REQTYPE_ENROLLEE_INFO_ONLY	0x00
#define WPS_REQTYPE_ENROLLEE_OPEN_8021X	0x01
#define WPS_REQTYPE_REGISTRAR			0x02
#define WPS_REQTYPE_AP_WLAN_MGR			0x03

/* Device response type */
#define WPS_RESTYPE_ENROLLEE_INFO_ONLY	0x00
#define WPS_RESTYPE_ENROLLEE_OPEN_8021X	0x01
#define WPS_RESTYPE_REGISTRAR			0x02
#define WPS_RESTYPE_AP					0x03

/* RF Band */
#define WPS_RFBAND_24GHZ	0x01
#define WPS_RFBAND_50GHZ	0x02
#define WPS_RFBAND_600GHZ	0x03

/* Wi-Fi Protected Setup State */
#define WPS_WPSSTATE_UNCONFIGURED	0x01
#define WPS_WPSSTATE_CONFIGURED		0x02

/* WPS OUI for primary and secondary device type sub-category */
#define WPS_DEVTYPE_OUI	0x0050f204

#if IGNORE_LONG_PUSH
/* WPS Default Push button duration Ignore in seconds */
#define WPS_DEF_PUSH_BUTTON_DUR_IGNORE_SECS     10
#endif

#define SIZE_1_BYTE		1
#define SIZE_2_BYTES		2
#define SIZE_4_BYTES		4
#define SIZE_6_BYTES		6
#define SIZE_8_BYTES		8
#define SIZE_16_BYTES		16
#define SIZE_20_BYTES		20
#define SIZE_32_BYTES		32
#define SIZE_64_BYTES		64
#define SIZE_80_BYTES		80
#define SIZE_128_BYTES		128
#define SIZE_192_BYTES		192


#define SIZE_64_BITS		SIZE_8_BYTES
#define SIZE_128_BITS		SIZE_16_BYTES
#define SIZE_160_BITS		SIZE_20_BYTES
#define SIZE_256_BITS		SIZE_32_BYTES
#define SIZE_512_BITS		SIZE_64_BYTES
#define SIZE_1024_BITS		SIZE_128_BYTES
#define SIZE_1536_BITS		SIZE_192_BYTES

#define SIZE_ENCR_IV			SIZE_128_BITS
#define ENCR_DATA_BLOCK_SIZE		SIZE_128_BITS
/* #define SIZE_DATA_HASH			SIZE_160_BITS */
/* #define SIZE_PUB_KEY_HASH		SIZE_160_BITS  */
#define SIZE_UUID				SIZE_16_BYTES
#define SIZE_MAC_ADDR			SIZE_6_BYTES
#define SIZE_PUB_KEY			SIZE_1536_BITS
#define SIZE_NONCE				SIZE_128_BITS
#define SIZE_WPS_HASH            32   /* related to sha256 output size */
#define SIZE_DHKEY               32   /* related to sha256 output size */
#define SIZE_KDK                 32   /* related to sha256 output size */
#define SIZE_AUTH_KEY            32   /* related to sha256 output size */
#define SIZE_PSK                 16
#define SIZE_KEY_WRAP_KEY        16
#define SIZE_EMSK                32

#define WPS_PERSONALIZATION_STRING "Wi-Fi Easy and Secure Key Derivation"
#define PRF_DIGEST_SIZE         SIZE_256_BITS
#define KDF_KEY_BITS            640
#define KDF_N_ITERATIONS (((KDF_KEY_BITS/8)+PRF_DIGEST_SIZE-1)/PRF_DIGEST_SIZE) /* == 3 */
#define KDF_OUTPUT_SIZE (KDF_N_ITERATIONS * 32)

#define WPS_IDENTITY_ENROLLEE	"WFA-SimpleConfig-Enrollee-1-0"
#define WPS_IDENTITY_REGISTRAR	"WFA-SimpleConfig-Registrar-1-0"

enum wps_supplicant_reg_mode {
	WPS_SUPPLICANT_REGMODE_NONE = 0,
	WPS_SUPPLICANT_REGMODE_CONFIGURE_AP,
	WPS_SUPPLICANT_REGMODE_REGISTER_AP,
	WPS_SUPPLICANT_REGMODE_REGISTER_STA
};

#if 0   /* was */
enum wps_ap_reg_mode {
        /* This enum is used for hostapd only.
         * These names are from the Sony code.
         * REGISTRAR_STA means that we serve as a registrar and
         * provide configuration to station enrollees;
         * this should be the most common case.
         * NONE_GET_CONF means that it is the AP is to be configured
         * (is "enrollee").
         * NONE_ADDED means that the AP is to act as if it is to be 
         * configured, but actually never changes it's configuration
         * (e.g. the peer can learn what it needs from M7 messages
         * we send it)... this is a weird way of doing things that is
         * used by e.g. JumpStart.
         */
	WPS_AP_REGMODE_NONE_GET_CONF = 0,
	WPS_AP_REGMODE_NONE_ADDED,
	WPS_AP_REGMODE_REGISTER_STA
};
#endif

enum wps_config_who {
        WPS_CONFIG_WHO_UNKNOWN = 0,     /* no registrar selected */
        WPS_CONFIG_WHO_ME = 1,          /* job via CONFIGME command */
        WPS_CONFIG_WHO_THEM = 2,        /* job via CONFIGTHEM command */
        WPS_CONFIG_WHO_EXTERNAL_REGISTRAR = 3  /* job via external registrar */
};

struct wps_config {
        /* --------- Fields from config file: --------- */
        u8              wps_disable;   /* nonzero to disable use of WPS entirely */
        u8              wps_upnp_disable; /* nonzero to disable UPnP w/ WPS*/
	u8		version;
	u8		uuid[SIZE_UUID];
	int		uuid_set;
	u8		mac[SIZE_MAC_ADDR];
	int		mac_set;
	u16		auth_type_flags;
	u16		encr_type_flags;
	u8		conn_type_flags;
	u16		config_methods;
        /* wpa_state indicates whether the device thinks it has been
         * configured or not. This is derived from config file field
         * wps_configured.
         */
	u8		wps_state;      /* WPS_WPSSTATE_... */
        /* The following descriptive strings are actually null terminated;
         * the "len" field is an artifact.
         */
	char		*manufacturer;
	size_t	manufacturer_len;
	char		*model_name;
	size_t	model_name_len;
	char		*model_number;
	size_t	model_number_len;
	char		*serial_number;
	size_t	serial_number_len;
	u16		dev_category;
	u16		dev_sub_category;
	u8		dev_oui[SIZE_4_BYTES];
	u8		prim_dev_type[SIZE_8_BYTES];
	char		*dev_name;
	size_t	dev_name_len;
	u8		rf_bands;
	u32		os_version;
        /* Access point use only for now (used for UPnP): */
        char            *friendly_name;
        char            *manufacturer_url;
        char            *model_description;
        char            *model_url;
        char            *upc_string;
        /* end Access point use only */
        /* UPnP configuration : always compiled, even if not using UPNP:  */
	char	*upnp_root_dir;         /* NOT used with tiny UPnP */
	char	*upnp_desc_url;         /* NOT used with tiny UPnP */
        /* NOTE! If default_pin is set, it is accepted at any time for
         * WPS EAP sessions when a WPS job (via commands 
         * CONFIGTHEM and CONFIGME) is not in progress.
         * This is essentially the "label method" described in WPS spec.
         * It is not very secure since it is unchanging.
         */
        char            *default_pin;   /* access point use only */
        int             default_timeout;  /* seconds; -1 for unlimited; 0 -> 120 */
        int             atheros_extension;    /* nonzero == use atheros WPS extension*/
        /* Atheros (extension) device type flags are:
         *              0x0001 -- access point
         *              0x0002 -- station
         *              0x0004 -- repeater
         * atheros_device_type_flags is a bit-or of the above indicating
         * the types of devices that the host may be
         * (zero -> suitable default).
         * atheros_device_type is one only of the above, and is the type
         * of device the host currently is (zero -> default).
         * If atheros_extension is set, both of these are passed in
         * certain WPS information elements.
         */
        u16             atheros_device_type_flags;
        u16             atheros_device_type;
        /* newsettings_command is a program to be executed (in the background)
         * whenever new settings to be applied to the configuration are
         * received via WPS for the given station (wpa_supplicant only).
         * If newsettings_command is provided, the WPS settings information
         * elements are stored in a file and the file path is passed
         * as argument to the program specified by newsettings_command.
         */
        char            *newsettings_command;
        /* -------- end fields from config file ---------- */

        /* ---------------- Beacon/Probe Response I.E. values ------------*/
        /* This information is included into beacon and probe response
         * information elements and is driven by the current job , or 
         * lack of current job.
         * Refer to WPS standard for values.
         */
	u16		dev_pwd_id; /* tell world e.g. push button or PIN */
	u8		selreg;     /* tell world a registar is selected */
	u16		selreg_config_methods;
        /* ------------- end Beacon/Probe Response I.E. values ------------*/

        /* -------------- WPS label method ---------------------------*/
        /* The "label method" refers to the use of a fixed PIN for an
         * access point, which can be used with any number of stations
         * without having to enter a PIN or push a button on the access
         * point.
         * The following prevents abuse of WPS without a command
         * being issued to allow it (using default_pin above).
         * When there are too many failures, we don't do WPS anymore
         * until restarted... this may prevent breakins by trying PINs
         * until one works.
         * Access point only.
         */
        int             nfailure;     /* hostapd: count failures for lockout*/
	u8		ap_setup_locked;  /* hostapd: lockout flag */
        /* -------------- end WPS label method ---------------------------*/

        /* ---------- WPS proxying control (access point only) ----------*/
        /* upnp_enabled is set nonzero when an external UPnP host
         * tells us that it will be the "selected external registrar";
         * (which should happen due to a user action only at that host
         * only).
         * In this state, WPS requests from stations will be forwarded
         * to the external registrar, and vice versa.
         * We implement a timeout on this state, and the external registrar
         * may also.
         *
         * NOTE: there is currently no protection against multiple
         * external registrars declaring that they selected...
         */
	u8	        upnp_enabled; /* if external registrar is "selected" */
        /* ---------- end WPS proxying control (access point only) ----------*/


        /* --------- WPS command-driven job -------------------------------*/
        /*
         * The following tracks the state of a WPS meta-session or "job",
         * which is initiated by a CONFIGME or CONFIGTHEM command.
         * In some cases we are doing an "internal registrar".
         * During the duration of such a job, multiple WPS EAP sessions
         * may occur which are assumed to be for the job, or might cause
         * the job to be aborted if there appears to be a conflict.
         *
         * WPS EAP sessions that occur outside of the job do not use
         * any of this, but use wps_default_pin (or do not happen if
         * wps_default_pin is not provided).
         */
	u8		wps_job_busy;    /* set when doing wps job */
        enum wps_config_who config_who;  /* who started the job */
	int /* enum wps_*_reg_mode */ reg_mode;
	u8		*config;
	size_t	config_len;

        u8              wps_done;       /* set when all done */
        int             seconds_timeout; /* session timeout; -1 for unlimited; (hostapd only)*/
	struct os_time end_time;        /* if session timeout being used */
        int             do_save;        /* save to config file when done? */

        /* "dev_pwd" is the WPS PIN; 00000000 means that is_push_button
         * should be set also.
         */
	u8		dev_pwd[SIZE_64_BYTES];
	size_t	dev_pwd_len;
        int             is_push_button;

	u8		pub_key[SIZE_PUB_KEY];
	u8		set_pub_key;
	void	*dh_secret;

        /* supplicant use only: */
	int		nwid_trying_wps;  /* -1 or which network configuration was added to do WPS with */
        int             filter_bssid_flag;   /* accept only given bssid? */
        u8              filter_bssid[6];     /* used if filter_bssid_flag */
        int             filter_ssid_length;  /* accept only given essid? */
        u8              filter_ssid[32];
        /* end supplicant use only */
        /* --------- end WPS command-driven job -------------------------*/

        /* UPnP configuration and state: always compiled, 
         * even if not using UPNP:  
         */
	char	*upnp_iface;            /* determines IP address used */
	char	*cur_upnp_device;       /* AP we're controlling (supplicant only) */
	
	/* Autoconfig set to 
	 true when ever auto config is needed*/
	int autoconfig;
#if IGNORE_LONG_PUSH
    u32 push_duration_ignore_secs;
#endif
};


struct wpa_supplicant;
struct wpa_ssid;
struct wpa_scan_result;

int wps_config_free_dh(void **dh);

/* for supplicant only: */

int wps_get_supplicant_ssid_configuration(void *ctx, int index, u8 **buf, size_t *len);
int wps_set_supplicant_ssid_configuration(void *ctx, u8 *buf, size_t len);

struct wpa_scan_result *wps_select_ssid(struct wpa_supplicant *wpa_s,
									 struct wpa_scan_result *results,
									 int num, struct wpa_ssid **ssid);

int wps_config_remove_network(struct wpa_supplicant *wpa_s, int network_id);


int wps_config_create_probe_req_ie(void *ctx, u8 **buf, size_t *len);
int wps_config_create_assoc_req_ie(void *ctx, u8 **buf, size_t *len);


/* for ap only: */

/* quality argument for wps_get_ap_ssid_configuration()
*       For cases of mixed mode, a given credential can only have one mode.
*       We can either generate one credential with one mode ("quality")
*       or generate 2 credentials, one with each.
*/
enum {
    WPS_CONFIG_QUALITY_BEST = 0,
    WPS_CONFIG_QUALITY_WORST = 1
};
int wps_get_ap_ssid_configuration(void *ctx, u8 **buf, size_t *len, int inband, u8 nwIdx, int quality, int autoconfig);
int wps_get_ap_auto_configuration(void *ctx, u8 **buf, size_t *len);
char *wps_config_temp_filepath_make(
        const char *original_filepath,
        const char *filename
        );
int wps_set_ap_ssid_configuration(void *ctx, char *filename, int nbufs, u8 **bufs, size_t *lens, int wps_configured);

int wps_config_create_beacon_ie(void *hapd, u8 **buf, size_t *len);
int wps_config_create_probe_resp_ie(void *hapd, u8 **buf, size_t *len);
int wps_config_create_assoc_resp_ie(void *hapd, u8 **buf, size_t *len);

int wps_get_wps_ie_txt(void *hapd, u8 *ie, size_t ie_len, char *buf, size_t buf_len);

#ifdef _MSC_VER
#pragma pack(pop)
#endif /* _MSC_VER */

#endif /* WPS_CONFIG_H */
