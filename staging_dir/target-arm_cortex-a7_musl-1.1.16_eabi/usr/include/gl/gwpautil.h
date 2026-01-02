/*
 * gwpautil.h
 *
 *  Created on: Aug 12, 2016
 *      Author: Lookwei
 */

#ifndef SRC_WPA_GWPAUTIL_H_
#define SRC_WPA_GWPAUTIL_H_

#ifndef LIBGWPA_DUAL
#define LIBGWPA_DUAL
#endif

extern int gcli_init();
extern void gcli_free();
extern int gcli_init_n_attach();
//extern int gcli_init_n_attach(void (*event_msg_handler)(char *msg, int len));
//extern int gcli_init_n_attach2(void (*event_msg_handler)(char *msg, int len));
/**
 * Send request to wpa_supplicant server
 * @iNumParamters Number of request parameters
 * @caParameters Parameter array
 * @buf4cmdReturn Buffer to accept the results of the request
 * @sizeBufLen The length of the buffer
 * Returns: -1=wpa_supplicant not connected, -2=time out, <0= failed, 0=succeed
 * */
extern int gcli_send_requst(int iNumParamters, const char *caParameters[], char *buf4cmdReturn, int sizeBufLen);

extern int gcli_send_direct_requst(int iNumParamters,char *caParameters[], char *buf4cmdReturn, int sizeBufLen);

extern int gcli_receive_envent_msg(char *buf4envent, int sizeBufLen);
/**
 * check if there are expected events in pending messages
 * Returns: -1=nothing found or errors, 0=conneted sucessfully, 1=wrong key
 */
extern int gcli_check_pending_events();

extern int main_bak(int argc, char *argv[]);

//extern int gcli_check_pending_events2(const char* evenTokens[], int iNumEvents);
#endif /* SRC_WPA_GWPAUTIL_H_ */
