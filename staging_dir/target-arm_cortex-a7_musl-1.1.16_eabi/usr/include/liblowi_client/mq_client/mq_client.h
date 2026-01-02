/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 mq-client

 GENERAL DESCRIPTION
 This header declares the public interface to mq client library.

 Copyright (c) 2012, 2018 Qualcomm Technologies, Inc.
 All Rights Reserved.
 Confidential and Proprietary - Qualcomm Technologies, Inc.

 (c) 2012 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 =============================================================================*/
#ifndef __XTRAT_WIFI_MESSAGE_QUEUE_CLIENT_H__
#define __XTRAT_WIFI_MESSAGE_QUEUE_CLIENT_H__

#include <base_util/queue.h>
#include <base_util/memorystream.h>

#ifndef IZAT_OFFLINE
#define MQ_SERVER_SOCKET_NAME mq_server_name
extern const char* const mq_server_name;
#else
#ifndef ROOT_DIR
#define ROOT_DIR ""
#endif
#define MQ_SERVER_SOCKET_NAME ROOT_DIR "location-mq-s"
#endif

namespace qc_loc_fw
{

class MessageQueueServiceCallback
{
public:
  static const int RC_NO_ERROR_CONTINUE = 0;
  static const int RC_NO_ERROR_STOP_LOOP = 10000;
  static const int RC_ERROR_STOP_LOOP_START = RC_NO_ERROR_STOP_LOOP + 1;

  virtual ~MessageQueueServiceCallback() = 0;
  virtual int newMsg(qc_loc_fw::InMemoryStream * new_buffer) = 0;
};

class MessageQueueClient
{
public:
  static MessageQueueClient * createInstance();
  virtual ~MessageQueueClient() = 0;

  virtual int setServerNameDup(const char * const name) = 0;
  virtual int connect(const bool name_in_file_system = true) = 0;
  virtual int send(const qc_loc_fw::MemoryStreamBase * const buffer) = 0;
  virtual int run_block(MessageQueueServiceCallback * const callback) = 0;

  // multiple access. called by any thread which wishes to shutdown communication
  virtual int shutdown() = 0;
};

} // namespace qc_loc_fw

#endif //#ifndef __XTRAT_WIFI_MESSAGE_QUEUE_CLIENT_H__
