/*
 * Copyright (c) 2017 Qualcomm Technologies, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Technologies, Inc.

*/

#ifndef wifison_event__h /*once only*/
#define wifison_event__h

/*====================================================================*"
 *   system header files;
 *--------------------------------------------------------------------*/
#include<sys/time.h>


#define SONE_EVENT_SOCKET_HYD       "/var/run/sonevent_socket_client_hyd"
#define SONE_EVENT_SOCKET_LBD       "/var/run/sonevent_socket_client_lbd"
#define SONE_EVENT_SOCKET_SERVER    "/var/run/sonevent_socket_server"

#define MESSAGE_FRAME_LEN_MAX    4096
#define VENDOR_DATA_LEN_MAX      1482

typedef enum {
    false = 0,
    true = 1,
} bool;

typedef enum sonEventClientID {
    SON_EVENT_CLIENT_HYD,
    SON_EVENT_CLIENT_LBD,
    SON_EVENT_MAX_CLIENTS,
} sonEventClientID;

enum sonEventSockMsgType
{
    SERVER_START,
    CLIENT_START,
    EVENT_REGISTER,
    EVENT_DEREGISTER,
    SERVER_STOP,
    VENDOR_DATA_SEND,
    EVENT_NOTIFICATION,
};

enum sonEventRegisterID
{
    SON_RE_JOIN_EVENT,
    SON_RE_LEAVE_EVENT,
    SON_DATA_EVENT,
    SON_CLIENT_RESTART_EVENT,
    SON_BSTM_QUERY_EVENT,
    SON_BLKLIST_STEER_CMD_EVENT,
    SON_BLKLIST_STEER_CMD_RESULT_EVENT,
    SON_BSTM_REQ_CMD_EVENT,
    SON_BSTM_RESPONSE_EVENT,
    SON_MAX_EVENT,
};

enum sonEventStatus
{
    EVENT_OK,
    EVENT_NO_DATA,
    EVENT_SOCKET_ERROR,
};

enum steerReportType
{
    BSTM_QUERY,
    BLKLIST_STEER_CMD,
    BLKLIST_STEER_CMD_RESULT,
    BSTM_REQ_CMD,
    BSTM_RESPONSE,
};

struct blkListCmd {
    unsigned int blkListType;
    unsigned int timeout;
};

struct steerReport {
    unsigned char mac[6];
    struct timeval timeStamp;
    unsigned int reportType;
    union {
        unsigned int bstmQueryReason;
        struct blkListCmd blkListCmd;
        unsigned int blkListCmdResult;
        unsigned int bstmResponseStatus;
    } reportData;
} __attribute__ ((packed));

struct sonEventClient {
    sonEventClientID clientID;
    char path[108];
};

struct service_message {
    unsigned int cmd;
    unsigned int len;
    unsigned char data[1];
} __attribute__ ((packed));

struct reInfo {
    unsigned char macaddress[6];
    unsigned char isDistantNeighbor;
} __attribute__ ((packed));

struct vendorData {
    unsigned char macaddress[6];
    unsigned char cus_data[VENDOR_DATA_LEN_MAX];
} __attribute__ ((packed));

struct sonEventInfo {
    int eventMsg;
    int length;
    union {
        int clientID;
        struct reInfo re;
        struct vendorData vdata;
        struct steerReport sReport;
    } data;
} __attribute__ ((packed));

int wifison_event_init(void);
void wifison_event_deinit(void);
void wifison_event_register(int);
void wifison_event_deregister(int);
int wifison_event_get(struct sonEventInfo *event);
void wifison_data_send(struct vendorData *vData, int vDataLen);
#endif
