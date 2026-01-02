/*
 * gllibbase.h
 *
 * This is a base file for gl lib development. Interfaces
 * defined here will be called automatically to register your lib
 * to gl-arch framework. Do not modify this file unless you got
 * the permission from the architect.
 *
 *  Created on: Apr 25, 2017
 *      Author: Xiaoyong Wei
 *
 *  modify by lancer @ 2018.03.30
 */

#ifndef GLLIBBASE_H_
#define GLLIBBASE_H_


#include <stdio.h>
#include <json-c/json.h>


/** This defines a standard format for gl API functions. 
 */
typedef int (*api_call)(json_object*,json_object*);

/** CgiApiFuctionInfo defines a mapping from a string path (e.g., /router/stainfo) 
 *  to a specific function. This is to let the framework know which function to
 *  call when given the path.
 */
typedef struct _api_info{
	/* the string for the function */	
	const char* Path;
	/* the allowed operations of "get" or "post" */
	const char* AllowedOperations;
	/* the handle of the target function */
	api_call TargetFunctionHandler;
}api_info_t;

/** CgiApiFuctionInfoEntity defines an easy way to write a CgiApiFuctionInfo struct.
 *  It is convenient when used in an array. 
 */
#define map(path, opts, handler) {.Path=path,.AllowedOperations=opts,.TargetFunctionHandler=handler}

/** GetAPIFunctions returns an array in which all the info of the APIs in your lib
 *  are included. This function will be called automatically to righter those APIs
 *  to the gl-arch framework. A gl API function should follow the standard format
 *  of FunctionName(json_object* input,json_object* output) where the input and output
 *  will be initialized by the caller. Do not re-create or destory these two objects
 *  in your functions.
 */
extern api_info_t* get_api_entity(int* pLen);


#endif /* GLLIBBASE_H_ */
