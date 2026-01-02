#ifndef _UCI2_UTIL_H_
#define _UCI2_UTIL_H_

#ifdef __cplusplus
extern "C" {
#endif

/** This is a modification from guci.h to 
 * change the global variables to local
 */

/**
 * Init and free guci context
 * guci2_init()
 * guci2_free()
 */
extern struct uci_context* guci2_init();
extern int guci2_free(struct uci_context* ctx);

/**
 * guci2_set("wireless.public.ssid",ssid)
 * guci2_set("wireless.guest","wifi-iface")
 */
extern int guci2_set(struct uci_context* ctx,const char* key, const char* value);
extern int guci2_set_idx(struct uci_context* ctx,const char* section, int index, const char* key, char* value);
extern int guci2_set_name(struct uci_context* ctx,const char* section, const char* name, const char* key, const char* value);

/**
 * guci2_get("wireless.public.ssid", ssid)
 * return UCI_OK when success
 */
extern int guci2_get(struct uci_context* ctx, const char* section_or_key, char value[]);
extern int guci2_get_idx(struct uci_context* ctx,const char* section, int index, const char* key, char value[]);
extern int guci2_get_name(struct uci_context* ctx,const char* section, const char* name, const char* key, char value[]);

/**
 * guci2_get("wireless.public", private)
 * return UCI_OK when success
 */
extern int guci2_rename(struct uci_context *ctx, const char* section_or_key, char value[]);

/**
 * guci2_commit("wireless")
 */
extern int guci2_commit(struct uci_context* ctx,const char* config);

/**
  * guci2_delete("wireless.public.key")
  * guci2_delete("wireless.public")
 */
extern int guci2_delete(struct uci_context* ctx,const char* section_or_key);

/**
 * guci2_delete_section_index("wireless.interface",0)
 */
extern int guci2_delete_section_index(struct uci_context* ctx,char* section, int index);

/**
 * guci2_add("wireless.public", "interface")
 */
extern int guci2_add(struct uci_context* ctx,const char* section, const char* type);

extern int guci2_add_anonymous(const char *config, const char *session);
/**
 * guci2_add_list("network.wan.dns", "192.168.1.1")
 */
extern int guci2_add_list(struct uci_context* ctx,char* key, char* value);

/**
 * guci2_delete_list_value("network.wan.dns","192.168.1.1")
 * guci2_delete_list("network.wan.dns")
 */
extern int guci2_delete_list_value(struct uci_context* ctx,char* key, char* value);
extern int guci2_delete_list(struct uci_context* ctx,char* key);

/**
 * guci2_section_count("wireless.@wifi-iface");
 * @return 2, number of wifi-iface's
 */
extern int guci2_section_count(struct uci_context* ctx,const char* section_type);

/**
 * get the section name by index
 * guci2_section_name("wireless.wifi-iface",0)
 * @return section name, e.g. "public"
 */
extern char* guci2_section_name(struct uci_context* ctx,const char* section_type,int index);

/**
 * guci2_find_section("wireless.@wifi-iface.mode", "ap");
 * @return section name, e.g. "public"
 */
extern char* guci2_find_section(struct uci_context* ctx,const char* section_key, char* value);
/**
 * guci2_find_section(ctx,"wireless.@wifi-iface.mac", "e4:95:6e:24:30:25");
 * @return section name, e.g. "public"
 */
extern char *guci2_find_list_member(struct uci_context* ctx,const char* section_key, char* value);
/**
 * guci2_get_list_index(ctx,"wireless.@wifi-iface.mac", 1);
 * @return section name, e.g. "public"
 */
extern char *guci2_get_list_index(struct uci_context* ctx,const char* section_key, int index, char *buf);

extern int guci2_get_list_count(struct uci_context* ctx, const char* section_key);

#ifdef __cplusplus
}
#endif

#endif
