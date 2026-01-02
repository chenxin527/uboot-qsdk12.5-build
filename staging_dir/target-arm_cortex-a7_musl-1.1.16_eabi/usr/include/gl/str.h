#ifndef _GL_STR_H_
#define _GL_STR_H_

#ifdef __cplusplus
extern "C" {
#endif

/**
 * get the key and value pair from a string
 * The string can be separated by space, =, tab, or multiple of them
 * Only the first two words will be used, all the char after will be droped
 * @key: key to be stored
 * @value: value to be stored
 * @return: 0 if success, -1 if only one word
 */
extern int get_key_value(const char* s, char key[], char value[]);

/**
 * Split the string into a list words by space, or tab
 * @s: e.g. "remote my.domain.com 3333 udp, this string will be changed
 * @new: char** result=
 * 				char* remote
 * 				char* mydomain.com
 * 				char* 333
 * 				char* udp
 * @return number of strings
 * free the return after use ret, no eed to free the strings it points to
 */
extern int split_string(char* s, const char* delim, char** result);

/**
 * trim the string from white space, tab and '\r\n'
 * @return: the multed string
 */
extern char* trim_string(char* s);

/** return a new string with every instance of ch replaced by repl
 * @return: the new string, which size maybe longer or shorter, free it after use
 * */
 
extern int str_to_int(char *str);

extern char* trim_string_with(char* s, const char *dilema);

extern char *replace_string(const char *s, const char *ch, const char *repl);

/**
 * change a string to UCI format
 * Deal with sigle quota ' in values
 * This is only useful for shell system call
 */
extern int toUciValue(char *from, char*to);
extern char* generate_token();
extern char* strtok_new(char * string, char const * delimiter);

extern void increase_escape_function(char *in, char *out, int count);

#include <stdbool.h>
bool check_char_in_str(const char *str, const char ch);
bool check_str_start_with(const char *str, const char *sub_str);
bool check_str_end_with(const char *str, const char *sub_str);
bool check_str_is_number(const char *str);

char *str_to_upper(char *str);
char *str_to_lower(char *str);
char* str_trim_white_space(char *str);
void str_remove_quotation_marks(char *ssid, char *str);
bool str_check_ip_format(char *str) ;

void del_char(char *string,char c);

#ifdef __cplusplus
}
#endif

#endif
