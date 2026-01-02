/*
 *  Copyright (c) 2012 Qualcomm Atheros Inc.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#ifndef _STORAGE_H_
#define _STORAGE_H_

#define CONFIG_RADIO  "RADIO."
#define CONFIG_WLAN   "WLAN." 
#define CONFIG_PLC    "PLC."
#define CONFIG_WSPLC  "WSPLC."
#define CONFIG_HYFI   "HYFI."

//semaphore id to serialize wifi restart
int wifi_semid;

/* boolean */
typedef enum strgBool_e {
    STRG_FALSE = 0,
    STRG_TRUE = !STRG_FALSE
} strgBool_e;

typedef void(*storageCallback_f)( void *handle, void *cookie, int err );

/**storage_getHandle
 * init configuration context
 * @param  : none
 * @return handle of configuration
 */
void *storage_getHandle();


/**storage_setParam
 * write one parameter to configuration
 * @param handle : handle of configuration
 * @param name   : parameter name, containing path information
 *                 for radio  parameters: RADIO.*.ParameterName
 *                 for AP/STA parameters: WLAN.*.ParameterName
 *                 for PLC    parameters: PLC.ParameterName
 *                 "*" stands for a number(index) which begins from 1
 * @param value  : value in string
 * @return 0 on success and negative value on failure
 */
int storage_setParam(void *handle, const char *name, const char *value);


/**storage_apply
 * apply all parameters to configuration
 * @param handle : handle of configuration
 * @return         0 on success and negative value on failure,
 *                 parameter "handle" will be freed in this function
 */
int storage_apply(void *handle);


/**storage_applyWithCallback
 * apply all parameters to configuration. Callback must call storage_callbackDone
 * once finished processing.
 * @param handle : handle of configuration
 * @callback     : callback to be called when apply process is done
 * @cookie       : user cookie
 * @return         0 on success and negative value on failure,
 *                 parameter "handle" will be freed in this function
 */
int storage_applyWithCallback(void *handle, storageCallback_f callback, void *cookie );


/**storage_callbackDone
 * Must be called when callback function has finished processing.
 * @param handle : handle of configuration
 * @return         0 on success and negative value on failure,
 *                 parameter "handle" will be freed in this function
 */
int storage_callbackDone( void *handle );

/**storage_addVAP
 * add a virtual AP(AP or STA)
 * @param name : none
 * @return   AP index(which could be used to generate path of this AP) on success 
 *           negative value on failure
 */
int storage_addVAP();


/**storage_delVAP
 * delete a virtual AP
 * @param index : VAP index
 * @return   0 on success and negative value on failure
 */
int storage_delVAP(int index);

/**storage_restartWireless
 * None
 * return None
 */
void storage_restartWireless(void);

/**storage_AddVap
 * Add a virtual AP
 * @param index : VAP index
 * @return  +ve on success and negative value on failure.
 */

int storage_AddVap(void *handle, const char *name, const char *value);

/**
 * @brief Release lock
 * @return STRG_TRUE on successful unlock; otherwise STRG_FALSE
 */

strgBool_e storage_wifiUnlock();

/**
 * @brief Get lock
 * @return STRG_TRUE on successful lock; otherwise STRG_FALSE
 */

strgBool_e storage_wifiLock();

/**
 * @brief Get sem set id if exists else create a new one.
 * @return STRG_TRUE on successful get; otherwise STRG_FALSE
 */

strgBool_e storage_wifiLockInit();

#endif
