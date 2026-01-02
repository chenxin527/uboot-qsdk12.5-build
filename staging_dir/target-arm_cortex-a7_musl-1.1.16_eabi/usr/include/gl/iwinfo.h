#ifndef _GL_IWINFO_H_
#define _GL_IWINFO_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <iwinfo.h>

#define IWINFO_BUFSIZE	24 * 1024
#define IWINFO_ESSID_MAX_SIZE	32
#define IWINFO_AUTH_OPEN     (1 << 0)
#define IWINFO_AUTH_SHARED   (1 << 1)

#define IWINFO_80211_A       (1 << 0)
#define IWINFO_80211_B       (1 << 1)
#define IWINFO_80211_G       (1 << 2)
#define IWINFO_80211_N       (1 << 3)
#define IWINFO_80211_AC      (1 << 4)

#define IWINFO_CIPHER_NONE   (1 << 0)
#define IWINFO_CIPHER_WEP40  (1 << 1)
#define IWINFO_CIPHER_TKIP   (1 << 2)
#define IWINFO_CIPHER_WRAP   (1 << 3)
#define IWINFO_CIPHER_CCMP   (1 << 4)
#define IWINFO_CIPHER_WEP104 (1 << 5)
#define IWINFO_CIPHER_AESOCB (1 << 6)
#define IWINFO_CIPHER_CKIP   (1 << 7)

#define IWINFO_KMGMT_NONE    (1 << 0)
#define IWINFO_KMGMT_8021x   (1 << 1)
#define IWINFO_KMGMT_PSK     (1 << 2)

//this is defined in libuci as well, don't define twice
//const char *IWINFO_OPMODE_NAMES[] = {
	//"Unknown",
	//"Master",
	//"Ad-Hoc",
	//"Client",
	//"Monitor",
	//"Master (VLAN)",
	//"WDS",
	//"Mesh Point",
	//"P2P Client",
	//"P2P Go",
//};

extern char * format_bssid(unsigned char *mac);

extern char * format_ssid(char *ssid);

extern char * format_channel(int ch);

extern char * format_signal(int sig);

extern char * format_noise(int noise);

extern char * format_rate(int rate);

extern char * format_encryption(struct iwinfo_crypto_entry *c);

extern char * format_quality_max(int qmax);

extern char * format_enc_suites(int suites);

extern char * format_assocrate(struct iwinfo_rate_entry *r);

#ifdef __cplusplus
}
#endif

#endif
