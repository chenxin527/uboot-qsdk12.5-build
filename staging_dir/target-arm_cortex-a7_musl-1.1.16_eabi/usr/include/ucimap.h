/*
 * ucimap.h - Library for the Unified Configuration Interface
 * Copyright (C) 2008-2009 Felix Fietkau <nbd@openwrt.org>
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

/*
 * This file contains ucimap, an API for mapping UCI to C data structures
 */

#ifndef __UCIMAP_H
#define __UCIMAP_H

#include <stdbool.h>
#include "uci.h"

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))
#endif

#define BITFIELD_SIZE(_fields) (((_fields) / 8) + 1)

#define CLR_BIT(_name, _bit) do { \
	_name[(_bit) / 8] &= ~(1 << ((_bit) % 8)); \
} while (0)

#define SET_BIT(_name, _bit) do { \
	_name[(_bit) / 8] |=  (1 << ((_bit) % 8)); \
} while (0)

#define TEST_BIT(_name, _bit) \
	(_name[(_bit) / 8] & (1 << ((_bit) % 8)))

#ifndef __GNUC__

#define __optmap_gen_type(_type, _field) -1

#ifndef likely
#define likely(_expr) !!(_expr)
#endif

#ifndef unlikely
#define unlikely(_expr) !!(_expr)
#endif

#else /* __GNUC__ */

#define __compatible(_type, _field, _newtype) \
	__builtin_types_compatible_p(typeof(&(((_type *)0)->_field)), _newtype *)

#define __list_compatible(_type, _field, __val, __else) \
	__builtin_choose_expr(__compatible(_type, _field, struct ucimap_list *), __val, __else)

#define __int_compatible(_type, _field, __val, __else) \
	__builtin_choose_expr(__compatible(_type, _field, int), __val, \
		__builtin_choose_expr(__compatible(_type, _field, unsigned int), __val, \
			__else))

#define __string_compatible(_type, _field, __val, __else) \
	__builtin_choose_expr(__compatible(_type, _field, char *), __val, \
		__builtin_choose_expr(__compatible(_type, _field, unsigned char *), __val, \
			__builtin_choose_expr(__compatible(_type, _field, const char *), __val, \
				__builtin_choose_expr(__compatible(_type, _field, const unsigned char *), __val, \
					__else))))

#define __bool_compatible(_type, _field, __val, __else) \
	__builtin_choose_expr(__compatible(_type, _field, bool), __val, __else)


#define __optmap_gen_type(_type, _field) \
	__list_compatible(_type, _field, UCIMAP_LIST, \
	__int_compatible(_type, _field, UCIMAP_INT, \
	__string_compatible(_type, _field, UCIMAP_STRING, \
	__bool_compatible(_type, _field, UCIMAP_BOOL, \
	-1))))

#ifndef likely
#define likely(x)   __builtin_expect(!!(x), 1)
#endif

#ifndef unlikely
#define unlikely(x) __builtin_expect(!!(x), 0)
#endif

#endif /* __GNUC__ */

#define UCIMAP_OPTION(_type, _field) \
	.name = #_field, \
	.offset = offsetof(_type, _field), \
	.detected_type = __optmap_gen_type(_type, _field), \
	.type_name = #_type


#define UCIMAP_SECTION(_name, _field) \
	.alloc_len = sizeof(_name), \
	.smap_offset = offsetof(_name, _field), \
	.type_name = #_name

struct uci_sectionmap;
struct uci_optmap;

struct ucimap_list;
struct ucimap_fixup;
struct ucimap_alloc;
struct ucimap_alloc_custom;
struct ucimap_section_data;

struct uci_map {
	struct uci_sectionmap **sections;
	unsigned int n_sections;
	bool parsed;
	void *priv;

	/* private */
	struct ucimap_fixup *fixup;
	struct ucimap_fixup **fixup_tail;
	struct ucimap_section_data *sdata;
	struct ucimap_section_data *pending;
	struct ucimap_section_data **sdata_tail;
};

enum ucimap_type {
	/* types */
	UCIMAP_SIMPLE   = 0x00,
	UCIMAP_LIST     = 0x10,
	UCIMAP_TYPE     = 0xf0, /* type mask */

	/* subtypes */
	UCIMAP_CUSTOM	= 0x0,
	UCIMAP_STRING   = 0x1,
	UCIMAP_BOOL     = 0x2,
	UCIMAP_INT      = 0x3,
	UCIMAP_SECTION  = 0x4,
	UCIMAP_SUBTYPE  = 0xf, /* subtype mask */

	/* automatically create lists from
	 * options with space-separated items */
	UCIMAP_LIST_AUTO = 0x0100,
	UCIMAP_FLAGS     = 0xff00, /* flags mask */
};

union ucimap_data {
	int i;
	bool b;
	char *s;
	void *ptr;
	void **data;
	struct ucimap_list *list;
};

struct ucimap_section_data {
	struct uci_map *map;
	struct uci_sectionmap *sm;
	const char *section_name;

	/* map for changed fields */
	unsigned char *cmap;
	bool done;

	/* internal */
	struct ucimap_section_data *next, **ref;
	struct ucimap_alloc *allocmap;
	struct ucimap_alloc_custom *alloc_custom;
	unsigned int allocmap_len;
	unsigned int alloc_custom_len;
};

struct uci_sectionmap {
	/* type string for the uci section */
	const char *type;

	/* length of the struct to map into, filled in by macro */
	unsigned int alloc_len;

	/* sectionmap offset, filled in by macro */
	unsigned int smap_offset;

	/* return a pointer to the section map data (allocate if necessary) */
	struct ucimap_section_data *(*alloc)(struct uci_map *map,
		struct uci_sectionmap *sm, struct uci_section *s);

	/* give the caller time to initialize the preallocated struct */
	int (*init)(struct uci_map *map, void *section, struct uci_section *s);

	/* pass the fully processed struct to the callback after the section end */
	int (*add)(struct uci_map *map, void *section);

	/* let the callback clean up its own stuff in the section */
	int (*free)(struct uci_map *map, void *section);

	/* list of option mappings for this section */
	struct uci_optmap *options;
	unsigned int n_options;
	unsigned int options_size;

	/* internal */
	const char *type_name;
};

struct uci_optmap {
	unsigned int offset;
	const char *name;
	enum ucimap_type type;
	int (*parse)(void *section, struct uci_optmap *om, union ucimap_data *data, const char *string);
	int (*format)(void *section, struct uci_optmap *om, union ucimap_data *data, char **string);
	void (*free)(void *section, struct uci_optmap *om, void *ptr);
	union {
		struct {
			int base;
			int min;
			int max;
		} i;
		struct {
			int maxlen;
		} s;
		struct uci_sectionmap *sm;
	} data;

	/* internal */
	int detected_type;
	const char *type_name;
};

struct ucimap_list {
	int n_items;
	int size;
	union ucimap_data item[];
};

/**
 * ucimap_init: initialize the ucimap data structure
 * @map: ucimap data structure
 *
 * you must call this function before doing any other ucimap operation
 * on the data structure
 */
extern int ucimap_init(struct uci_map *map);

/**
 * ucimap_cleanup: clean up all allocated data from ucimap
 * @map: ucimap data structure
 */
extern void ucimap_cleanup(struct uci_map *map);

/**
 * ucimap_parse: parse all sections in an uci package using ucimap
 * @map: ucimap data structure
 * @pkg: uci package
 */
extern void ucimap_parse(struct uci_map *map, struct uci_package *pkg);

/**
 * ucimap_set_changed: mark a field in a custom data structure as changed
 * @sd: pointer to the ucimap section data
 * @field: pointer to the field inside the custom data structure
 *
 * @sd must be set to the section data inside the data structure that contains @field
 */
extern void ucimap_set_changed(struct ucimap_section_data *sd, void *field);

/**
 * ucimap_store_section: copy all changed data from the converted data structure to uci
 * @map: ucimap data structure
 * @p: uci package to store the changes in
 * @sd: pointer to the ucimap section data
 *
 * changes are not saved or committed automatically
 */
extern int ucimap_store_section(struct uci_map *map, struct uci_package *p, struct ucimap_section_data *sd);

/**
 * ucimap_parse_section: parse a single section
 * @map: ucimap data structure
 * @sm: uci section map
 * @sd: pointer to the ucimap section data
 * @s: pointer to the uci section
 *
 * this function overwrites the ucimap section data, do not use on a section
 * that has been parsed already
 */
extern int ucimap_parse_section(struct uci_map *map, struct uci_sectionmap *sm, struct ucimap_section_data *sd, struct uci_section *s);

/**
 * ucimap_free_section: free a data structure for a converted section
 * @map: ucimap data structure
 * @sd: pointer to the ucimap section data
 *
 * this function will clean up all data that was allocated by ucimap for this section.
 * all references to the data structure become invalid
 */
extern void ucimap_free_section(struct uci_map *map, struct ucimap_section_data *sd);

/**
 * ucimap_resize_list: allocate or resize a uci list
 * @sd: pointer to the ucimap section data
 * @list: pointer to the list field
 * @items: new size
 *
 * @sd must point to the data structure that contains @list.
 * @list must point to the field containing a pointer to the list, not the list directly
 * the memory allocated for this list is tracked for the section and freed automatically
 */
extern int ucimap_resize_list(struct ucimap_section_data *sd, struct ucimap_list **list, int items);

/**
 * ucimap_free_item: free the allocated memory for a data structure member
 * @sd: pointer to the ucimap section data
 * @item: pointer to the field inside the data structure
 *
 * @sd must point to the data structure that contains @item.
 * @item must point to the field containing a pointer to the allocated item
 */
extern void ucimap_free_item(struct ucimap_section_data *sd, void *item);

#endif
