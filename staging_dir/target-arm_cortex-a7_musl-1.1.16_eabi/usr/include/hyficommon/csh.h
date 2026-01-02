/*
 * Copyright (c) 2010 Qualcomm Atheros, Inc.
 *
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#ifndef csh__h
#define csh__h
                    /*-,- From csh.c */
                    extern
/*-F- cshInit -- set up command shell server.
 * If Port is passed by zero, it is drawn from env. variable
 * or else a default.
 * Note however, if Port is passed nonzero, then the CSH_FIND_PORT
 * feature is disabled regardless of environmental variable etc.
 */
void cshInit(
        int Port)       /* pass 0 for default, else port to listen on */
;
#endif /* csh__h */
