#ifndef _JSON_API_H
#define _JSON_API_H

#include <stdbool.h>
#include <json-c/json.h>

#ifdef __cplusplus
extern "C" {
#endif

/* api for type */
extern void gjson_add_string(json_object *obj, const char *key, const char *str);
extern void gjson_add_int(json_object *obj, const char *key, int value);
extern void gjson_add_boolean(json_object *obj, const char *key, bool bval);
extern void gjson_add_double(json_object *obj, const char *key, double dval);
extern void gjson_add_object(json_object *obj, const char *key, json_object *oval);
extern void gjson_add_array(json_object *obj, const char *key, void *array, int len);
extern void gjson_array_add(json_object *obj, json_object *child);
extern void gjson_array_add_string(json_object *obj, const char *str);

/* api for get */
extern const char *gjson_get_string(json_object *parent, const char *key);
extern int gjson_get_int(json_object *parent, const char *key);
extern bool gjson_get_boolean(json_object *parent, const char *key);
extern double gjson_get_double(json_object *parent, const char *key);
extern json_object *gjson_get_object(json_object *parent, const char *key);
extern void *gjson_get_array(json_object *parent, const char *key);

extern int gjson_contain_key(json_object *parent, char *key);
extern int gjson_parameter_exist(json_object *input, json_object *output, char **parameters, int param_num);

/* api for del */
extern void gjson_del_key(json_object *parent, const char *key);

/* api for set */
extern int gjson_set_string(json_object *parent, const char *key, const char *str);
extern int gjson_set_int(json_object *parent, const char *key, int value);
extern int gjson_set_boolean(json_object *parent, const char *key, bool bval);
extern int gjson_set_double(json_object *parent, const char *key, double dval);
extern int gjson_set_object(json_object *parent, const char *key, json_object *oval);
extern int gjson_set_array(json_object *parent, const char *key, void *array, int len);

/* api for file */
extern int gjson_parse_file(const char *filename, json_object **obj);
extern int gjson_save_file(const char *filename, json_object *obj);

extern void gjson_parameter_escape(json_object* obj);
#ifdef __cplusplus
}
#endif

#endif
