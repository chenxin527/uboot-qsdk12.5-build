/*
 * parser.h
 *
 *  Created on: Jan 8, 2018
 *      Author: lancer
 */


#ifndef PARSER_H
#define PARSER_H

#include <libubox/list.h>
#include <json-c/json.h>


typedef struct _api_dispatcher {
	char path[64];
	char opts[16];
    int (*func)(json_object*, json_object*);
} api_dispatcher_t;


typedef struct _api_dispatcher_list {
	api_dispatcher_t api_dispatcher;
	struct list_head node;
} api_dispatcher_list_t;


bool parser_check_if_need_token(char *caPath);
int custom_api_dispatcher(char *api, json_object* input, json_object* output);

#endif /* PARSER_H */
