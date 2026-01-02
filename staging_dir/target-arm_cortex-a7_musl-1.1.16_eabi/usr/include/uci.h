/*
 * libuci - Library for the Unified Configuration Interface
 * Copyright (C) 2008 Felix Fietkau <nbd@openwrt.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 2.1
 * as published by the Free Software Foundation
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 */

#ifndef __LIBUCI_H
#define __LIBUCI_H

#ifdef __cplusplus
extern "C" {
#endif

#include "uci_config.h"

/*
 * you can use these defines to enable debugging behavior for
 * apps compiled against libuci:
 *
 * #define UCI_DEBUG_TYPECAST:
 *   enable uci_element typecast checking at run time
 *
 */

#include <stdbool.h>
#include <setjmp.h>
#include <stdio.h>
#include <stdint.h>

#define UCI_CONFDIR "/etc/config"
#define UCI_SAVEDIR "/tmp/.uci"
#define UCI_DIRMODE 0700
#define UCI_FILEMODE 0600

enum
{
	UCI_OK = 0,
	UCI_ERR_MEM,
	UCI_ERR_INVAL,
	UCI_ERR_NOTFOUND,
	UCI_ERR_IO,
	UCI_ERR_PARSE,
	UCI_ERR_DUPLICATE,
	UCI_ERR_UNKNOWN,
	UCI_ERR_LAST
};

struct uci_list;
struct uci_list
{
	struct uci_list *next;
	struct uci_list *prev;
};

struct uci_ptr;
struct uci_element;
struct uci_package;
struct uci_section;
struct uci_option;
struct uci_delta;
struct uci_context;
struct uci_backend;
struct uci_parse_option;
struct uci_parse_context;


/**
 * uci_alloc_context: Allocate a new uci context
 */
extern struct uci_context *uci_alloc_context(void);

/**
 * uci_free_context: Free the uci context including all of its data
 */
extern void uci_free_context(struct uci_context *ctx);

/**
 * uci_perror: Print the last uci error that occured
 * @ctx: uci context
 * @str: string to print before the error message
 */
extern void uci_perror(struct uci_context *ctx, const char *str);

/**
 * uci_geterror: Get an error string for the last uci error
 * @ctx: uci context
 * @dest: target pointer for the string
 * @str: prefix for the error message
 *
 * Note: string must be freed by the caller
 */
extern void uci_get_errorstr(struct uci_context *ctx, char **dest, const char *str);

/**
 * uci_import: Import uci config data from a stream
 * @ctx: uci context
 * @stream: file stream to import from
 * @name: (optional) assume the config has the given name
 * @package: (optional) store the last parsed config package in this variable
 * @single: ignore the 'package' keyword and parse everything into a single package
 *
 * the name parameter is for config files that don't explicitly use the 'package <...>' keyword
 * if 'package' points to a non-null struct pointer, enable delta tracking and merge
 */
extern int uci_import(struct uci_context *ctx, FILE *stream, const char *name, struct uci_package **package, bool single);

/**
 * uci_export: Export one or all uci config packages
 * @ctx: uci context
 * @stream: output stream
 * @package: (optional) uci config package to export
 * @header: include the package header
 */
extern int uci_export(struct uci_context *ctx, FILE *stream, struct uci_package *package, bool header);

/**
 * uci_load: Parse an uci config file and store it in the uci context
 *
 * @ctx: uci context
 * @name: name of the config file (relative to the config directory)
 * @package: store the loaded config package in this variable
 */
extern int uci_load(struct uci_context *ctx, const char *name, struct uci_package **package);

/**
 * uci_unload: Unload a config file from the uci context
 *
 * @ctx: uci context
 * @package: pointer to the uci_package struct
 */
extern int uci_unload(struct uci_context *ctx, struct uci_package *p);

/**
 * uci_lookup_ptr: Split an uci tuple string and look up an element tree
 * @ctx: uci context
 * @ptr: lookup result struct
 * @str: uci tuple string to look up
 * @extended: allow extended syntax lookup
 *
 * if extended is set to true, uci_lookup_ptr supports the following
 * extended syntax:
 *
 * Examples:
 *   network.@interface[0].ifname ('ifname' option of the first interface section)
 *   network.@interface[-1]       (last interface section)
 * Note: uci_lookup_ptr will automatically load a config package if necessary
 * @str must not be constant, as it will be modified and used for the strings inside @ptr,
 * thus it must also be available as long as @ptr is in use.
 *
 * This function returns UCI_ERR_NOTFOUND if the package specified in the tuple
 * string cannot be found.  Otherwise it will return UCI_OK.
 *
 * Note that failures in looking up other parts, if they are also specfied,
 * including section and option, will also have a return value UCI_OK but with
 * ptr->flags * UCI_LOOKUP_COMPLETE not set.
 */
extern int uci_lookup_ptr(struct uci_context *ctx, struct uci_ptr *ptr, char *str, bool extended);

/**
 * uci_add_section: Add an unnamed section
 * @ctx: uci context
 * @p: package to add the section to
 * @type: section type
 * @res: pointer to store a reference to the new section in
 */
extern int uci_add_section(struct uci_context *ctx, struct uci_package *p, const char *type, struct uci_section **res);

/**
 * uci_set: Set an element's value; create the element if necessary
 * @ctx: uci context
 * @ptr: uci pointer
 *
 * The updated/created element is stored in ptr->last
 */
extern int uci_set(struct uci_context *ctx, struct uci_ptr *ptr);

/**
 * uci_add_list: Append a string to an element list
 * @ctx: uci context
 * @ptr: uci pointer (with value)
 *
 * Note: if the given option already contains a string value,
 * it will be converted to an 1-element-list before appending the next element
 */
extern int uci_add_list(struct uci_context *ctx, struct uci_ptr *ptr);

/**
 * uci_del_list: Remove a string from an element list
 * @ctx: uci context
 * @ptr: uci pointer (with value)
 *
 */
extern int uci_del_list(struct uci_context *ctx, struct uci_ptr *ptr);

/**
 * uci_reorder: Reposition a section
 * @ctx: uci context
 * @s: uci section to reposition
 * @pos: new position in the section list
 */
extern int uci_reorder_section(struct uci_context *ctx, struct uci_section *s, int pos);

/**
 * uci_rename: Rename an element
 * @ctx: uci context
 * @ptr: uci pointer (with value)
 */
extern int uci_rename(struct uci_context *ctx, struct uci_ptr *ptr);

/**
 * uci_delete: Delete a section or option
 * @ctx: uci context
 * @ptr: uci pointer
 */
extern int uci_delete(struct uci_context *ctx, struct uci_ptr *ptr);

/**
 * uci_save: save change delta for a package
 * @ctx: uci context
 * @p: uci_package struct
 */
extern int uci_save(struct uci_context *ctx, struct uci_package *p);

/**
 * uci_commit: commit changes to a package
 * @ctx: uci context
 * @p: uci_package struct pointer
 * @overwrite: overwrite existing config data and flush delta
 *
 * committing may reload the whole uci_package data,
 * the supplied pointer is updated accordingly
 */
extern int uci_commit(struct uci_context *ctx, struct uci_package **p, bool overwrite);

/**
 * uci_list_configs: List available uci config files
 * @ctx: uci context
 *
 * caller is responsible for freeing the allocated memory behind list
 */
extern int uci_list_configs(struct uci_context *ctx, char ***list);

/**
 * uci_set_savedir: override the default delta save directory
 * @ctx: uci context
 * @dir: directory name
 *
 * This will also try adding the specified dir to the end of delta pathes.
 */
extern int uci_set_savedir(struct uci_context *ctx, const char *dir);

/**
 * uci_set_savedir: override the default config storage directory
 * @ctx: uci context
 * @dir: directory name
 */
extern int uci_set_confdir(struct uci_context *ctx, const char *dir);

/**
 * uci_add_delta_path: add a directory to the search path for change delta files
 * @ctx: uci context
 * @dir: directory name
 *
 * This function allows you to add directories, which contain 'overlays'
 * for the active config, that will never be committed.
 *
 * Adding a duplicate directory will cause UCI_ERR_DUPLICATE be returned.
 */
extern int uci_add_delta_path(struct uci_context *ctx, const char *dir);

/**
 * uci_revert: revert all changes to a config item
 * @ctx: uci context
 * @ptr: uci pointer
 */
extern int uci_revert(struct uci_context *ctx, struct uci_ptr *ptr);

/**
 * uci_parse_argument: parse a shell-style argument, with an arbitrary quoting style
 * @ctx: uci context
 * @stream: input stream
 * @str: pointer to the current line (use NULL for parsing the next line)
 * @result: pointer for the result
 */
extern int uci_parse_argument(struct uci_context *ctx, FILE *stream, char **str, char **result);

/**
 * uci_set_backend: change the default backend
 * @ctx: uci context
 * @name: name of the backend
 *
 * The default backend is "file", which uses /etc/config for config storage
 */
extern int uci_set_backend(struct uci_context *ctx, const char *name);

/**
 * uci_validate_text: validate a value string for uci options
 * @str: value
 *
 * this function checks whether a given string is acceptable as value
 * for uci options
 */
extern bool uci_validate_text(const char *str);

/**
 * uci_parse_ptr: parse a uci string into a uci_ptr
 * @ctx: uci context
 * @ptr: target data structure
 * @str: string to parse
 *
 * str is modified by this function
 */
int uci_parse_ptr(struct uci_context *ctx, struct uci_ptr *ptr, char *str);

/**
 * uci_lookup_next: lookup a child element
 * @ctx: uci context
 * @e: target element pointer
 * @list: list of elements
 * @name: name of the child element
 *
 * if parent is NULL, the function looks up the package with the given name
 */
int uci_lookup_next(struct uci_context *ctx, struct uci_element **e, struct uci_list *list, const char *name);

/**
 * uci_parse_section: look up a set of options
 * @s: uci section
 * @opts: list of options to look up
 * @n_opts: number of options to look up
 * @tb: array of pointers to found options
 */
void uci_parse_section(struct uci_section *s, const struct uci_parse_option *opts,
		       int n_opts, struct uci_option **tb);

/**
 * uci_hash_options: build a hash over a list of options
 * @tb: list of option pointers
 * @n_opts: number of options
 */
uint32_t uci_hash_options(struct uci_option **tb, int n_opts);


/* UCI data structures */
enum uci_type {
	UCI_TYPE_UNSPEC = 0,
	UCI_TYPE_DELTA = 1,
	UCI_TYPE_PACKAGE = 2,
	UCI_TYPE_SECTION = 3,
	UCI_TYPE_OPTION = 4,
	UCI_TYPE_PATH = 5,
	UCI_TYPE_BACKEND = 6,
	UCI_TYPE_ITEM = 7,
	UCI_TYPE_HOOK = 8,
};

enum uci_option_type {
	UCI_TYPE_STRING = 0,
	UCI_TYPE_LIST = 1,
};

enum uci_flags {
	UCI_FLAG_STRICT =        (1 << 0), /* strict mode for the parser */
	UCI_FLAG_PERROR =        (1 << 1), /* print parser error messages */
	UCI_FLAG_EXPORT_NAME =   (1 << 2), /* when exporting, name unnamed sections */
	UCI_FLAG_SAVED_DELTA = (1 << 3), /* store the saved delta in memory as well */
};

struct uci_element
{
	struct uci_list list;
	enum uci_type type;
	char *name;
};

struct uci_backend
{
	struct uci_element e;
	char **(*list_configs)(struct uci_context *ctx);
	struct uci_package *(*load)(struct uci_context *ctx, const char *name);
	void (*commit)(struct uci_context *ctx, struct uci_package **p, bool overwrite);

	/* private: */
	const void *ptr;
	void *priv;
};

struct uci_context
{
	/* list of config packages */
	struct uci_list root;

	/* parser context, use for error handling only */
	struct uci_parse_context *pctx;

	/* backend for import and export */
	struct uci_backend *backend;
	struct uci_list backends;

	/* uci runtime flags */
	enum uci_flags flags;

	char *confdir;
	char *savedir;

	/* search path for delta files */
	struct uci_list delta_path;

	/* private: */
	int err;
	const char *func;
	jmp_buf trap;
	bool internal, nested;
	char *buf;
	int bufsz;
};

struct uci_package
{
	struct uci_element e;
	struct uci_list sections;
	struct uci_context *ctx;
	bool has_delta;
	char *path;

	/* private: */
	struct uci_backend *backend;
	void *priv;
	int n_section;
	struct uci_list delta;
	struct uci_list saved_delta;
};

struct uci_section
{
	struct uci_element e;
	struct uci_list options;
	struct uci_package *package;
	bool anonymous;
	char *type;
};

struct uci_option
{
	struct uci_element e;
	struct uci_section *section;
	enum uci_option_type type;
	union {
		struct uci_list list;
		char *string;
	} v;
};

/*
 * UCI_CMD_ADD is used for anonymous sections or list values
 */
enum uci_command {
	UCI_CMD_ADD,
	UCI_CMD_REMOVE,
	UCI_CMD_CHANGE,
	UCI_CMD_RENAME,
	UCI_CMD_REORDER,
	UCI_CMD_LIST_ADD,
	UCI_CMD_LIST_DEL,
	__UCI_CMD_MAX,
	__UCI_CMD_LAST = __UCI_CMD_MAX - 1
};
extern char const uci_command_char[];

struct uci_delta
{
	struct uci_element e;
	enum uci_command cmd;
	char *section;
	char *value;
};

struct uci_ptr
{
	enum uci_type target;
	enum {
		UCI_LOOKUP_DONE =     (1 << 0),
		UCI_LOOKUP_COMPLETE = (1 << 1),
		UCI_LOOKUP_EXTENDED = (1 << 2),
	} flags;

	struct uci_package *p;
	struct uci_section *s;
	struct uci_option *o;
	struct uci_element *last;

	const char *package;
	const char *section;
	const char *option;
	const char *value;
};

struct uci_parse_option {
	const char *name;
	enum uci_option_type type;
};


/* linked list handling */
#ifndef offsetof
#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)
#endif

/**
 * container_of - cast a member of a structure out to the containing structure
 * @ptr:    the pointer to the member.
 * @type:   the type of the container struct this is embedded in.
 * @member: the name of the member within the struct.
 */
#ifndef container_of
#define container_of(ptr, type, member) \
	((type *) ((char *)ptr - offsetof(type,member)))
#endif


/**
 * uci_list_entry: casts an uci_list pointer to the containing struct.
 * @_type: config, section or option
 * @_ptr: pointer to the uci_list struct
 */
#define list_to_element(ptr) \
	container_of(ptr, struct uci_element, list)

/**
 * uci_foreach_entry: loop through a list of uci elements
 * @_list: pointer to the uci_list struct
 * @_ptr: iteration variable, struct uci_element
 *
 * use like a for loop, e.g:
 *   uci_foreach(&list, p) {
 *   	...
 *   }
 */
#define uci_foreach_element(_list, _ptr)		\
	for(_ptr = list_to_element((_list)->next);	\
		&_ptr->list != (_list);			\
		_ptr = list_to_element(_ptr->list.next))

/**
 * uci_foreach_entry_safe: like uci_foreach_safe, but safe for deletion
 * @_list: pointer to the uci_list struct
 * @_tmp: temporary variable, struct uci_element *
 * @_ptr: iteration variable, struct uci_element *
 *
 * use like a for loop, e.g:
 *   uci_foreach(&list, p) {
 *   	...
 *   }
 */
#define uci_foreach_element_safe(_list, _tmp, _ptr)		\
	for(_ptr = list_to_element((_list)->next),		\
		_tmp = list_to_element(_ptr->list.next);	\
		&_ptr->list != (_list);			\
		_ptr = _tmp, _tmp = list_to_element(_ptr->list.next))

/**
 * uci_list_empty: returns true if a list is empty
 * @list: list head
 */
#define uci_list_empty(list) ((list)->next == (list))

/* wrappers for dynamic type handling */
#define uci_type_backend UCI_TYPE_BACKEND
#define uci_type_delta UCI_TYPE_DELTA
#define uci_type_package UCI_TYPE_PACKAGE
#define uci_type_section UCI_TYPE_SECTION
#define uci_type_option UCI_TYPE_OPTION

/* element typecasting */
#ifdef UCI_DEBUG_TYPECAST
static const char *uci_typestr[] = {
	[uci_type_backend] = "backend",
	[uci_type_delta] = "delta",
	[uci_type_package] = "package",
	[uci_type_section] = "section",
	[uci_type_option] = "option",
};

static void uci_typecast_error(int from, int to)
{
	fprintf(stderr, "Invalid typecast from '%s' to '%s'\n", uci_typestr[from], uci_typestr[to]);
}

#define BUILD_CAST(_type) \
	static inline struct uci_ ## _type *uci_to_ ## _type (struct uci_element *e) \
	{ \
		if (e->type != uci_type_ ## _type) { \
			uci_typecast_error(e->type, uci_type_ ## _type); \
		} \
		return (struct uci_ ## _type *) e; \
	}

BUILD_CAST(backend)
BUILD_CAST(delta)
BUILD_CAST(package)
BUILD_CAST(section)
BUILD_CAST(option)

#else
#define uci_to_backend(ptr) container_of(ptr, struct uci_backend, e)
#define uci_to_delta(ptr) container_of(ptr, struct uci_delta, e)
#define uci_to_package(ptr) container_of(ptr, struct uci_package, e)
#define uci_to_section(ptr) container_of(ptr, struct uci_section, e)
#define uci_to_option(ptr)  container_of(ptr, struct uci_option, e)
#endif

/**
 * uci_alloc_element: allocate a generic uci_element, reserve a buffer and typecast
 * @ctx: uci context
 * @type: {package,section,option}
 * @name: string containing the name of the element
 * @datasize: additional buffer size to reserve at the end of the struct
 */
#define uci_alloc_element(ctx, type, name, datasize) \
	uci_to_ ## type (uci_alloc_generic(ctx, uci_type_ ## type, name, sizeof(struct uci_ ## type) + datasize))

#define uci_dataptr(ptr) \
	(((char *) ptr) + sizeof(*ptr))

/**
 * uci_lookup_package: look up a package
 * @ctx: uci context
 * @name: name of the package
 */
static inline struct uci_package *
uci_lookup_package(struct uci_context *ctx, const char *name)
{
	struct uci_element *e = NULL;
	if (uci_lookup_next(ctx, &e, &ctx->root, name) == 0)
		return uci_to_package(e);
	else
		return NULL;
}

/**
 * uci_lookup_section: look up a section
 * @ctx: uci context
 * @p: package that the section belongs to
 * @name: name of the section
 */
static inline struct uci_section *
uci_lookup_section(struct uci_context *ctx, struct uci_package *p, const char *name)
{
	struct uci_element *e = NULL;
	if (uci_lookup_next(ctx, &e, &p->sections, name) == 0)
		return uci_to_section(e);
	else
		return NULL;
}

/**
 * uci_lookup_option: look up an option
 * @ctx: uci context
 * @section: section that the option belongs to
 * @name: name of the option
 */
static inline struct uci_option *
uci_lookup_option(struct uci_context *ctx, struct uci_section *s, const char *name)
{
	struct uci_element *e = NULL;
	if (uci_lookup_next(ctx, &e, &s->options, name) == 0)
		return uci_to_option(e);
	else
		return NULL;
}

static inline const char *
uci_lookup_option_string(struct uci_context *ctx, struct uci_section *s, const char *name)
{
	struct uci_option *o;

	o = uci_lookup_option(ctx, s, name);
	if (!o || o->type != UCI_TYPE_STRING)
		return NULL;

	return o->v.string;
}

#ifdef __cplusplus
}
#endif

#endif
