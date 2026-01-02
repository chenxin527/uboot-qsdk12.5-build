#ifndef _UCI_UTIL_H_
#define _UCI_UTIL_H_

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Init and free guci context
 * guci_init()
 * guci_free()
 */
extern int guci_init();
extern int guci_free();

/**
 * guci_set("wireless.public.ssid",ssid)
 * guci_set("wireless.guest","wifi-iface")
 */
extern int guci_set(const char* key, const char* value);
extern int guci_set_idx(const char* section, int index, const char* key, char* value);
extern int guci_set_name(const char* section, const char* name, const char* key, const char* value);

/**
 * guci_get("wireless.public.ssid", ssid)
 * return UCI_OK when success
 */
extern int guci_get(const char* section_or_key, char value[]);
extern int guci_get_idx(const char* section, int index, const char* key, char value[]);
extern int guci_get_name(const char* section, const char* name, const char* key, char value[]);

/**
 * guci_commit("wireless")
 */
extern int guci_commit(const char* config);

/**
  * guci_delete("wireless.public.key")
  * guci_delete("wireless.public")
 */
extern int guci_delete(const char* section_or_key);

/**
 * guci_delete_section_index("wireless.interface",0)
 */
extern int guci_delete_section_index(char* section, int index);

/**
 * guci_add("wireless.public", "interface")
 */
extern int guci_add(const char* section, const char* type);

/**
 * guci_add_list("network.wan.dns", "192.168.1.1")
 */
extern int guci_add_list(char* key, char* value);

/**
 * guci_delete_list_value("network.wan.dns","192.168.1.1")
 * guci_delete_list("network.wan.dns")
 */
extern int guci_delete_list_value(char* key, char* value);
extern int guci_delete_list(char* key);

/**
 * guci_section_count("wireless.@wifi-iface");
 * @return 2, number of wifi-iface's
 */
extern int guci_section_count(const char* section_type);

/**
 * get the section name by index
 * guci_section_name("wireless.wifi-iface",0)
 * @return section name, e.g. "public"
 */
extern char* guci_section_name(const char* section_type,int index);

/**
 * guci_find_section("wireless.@wifi-iface.mode", "ap");
 * @return section name, e.g. "public"
 */
extern char* guci_find_section(const char* section_key, char* value);

#ifdef __cplusplus
}
#endif

#endif
