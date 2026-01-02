#ifndef __LOWI_CLIENT_RECEIVER__
#define __LOWI_CLIENT_RECEIVER__

/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

        LOWI Client Receiver Interface Header file

GENERAL DESCRIPTION
  This file contains the structure definitions and function prototypes for
  LOWIClientReceiver

  Copyright (c) 2012, 2018 Qualcomm Technologies, Inc.
  All Rights Reserved.
  Confidential and Proprietary - Qualcomm Technologies, Inc.

  (c) 2012 Qualcomm Atheros, Inc.
  All Rights Reserved.
  Qualcomm Atheros Confidential and Proprietary.

=============================================================================*/

#include <base_util/postcard.h>
#include <mq_client/mq_client.h>
#include <base_util/sync.h>
#include <inc/lowi_const.h>
#include <inc/lowi_client_receiver.h>

namespace qc_loc_fw
{

/**
 * This class receives the messages from the IPC Hub.
 * Provides socket based IPC implementation. This class is run in a separate thread.
 * Provides the response to the Listener.
 */
class LOWIClientReceiver : public Runnable
{
private:
  const char * const mSocketName;
  BlockingQueue* const mMsgQueue;
  /** To be able to callback into LOWIClient*/
  MessageQueueClient*  const mMsgQueueClient;
  MessageQueueServiceCallback* const mCallback;
  const char* const mClientName;
  Thread* mReceiverThread;

  // private copy constructor and assignment operator so that the
  // the instance can not be copied.
  LOWIClientReceiver( const LOWIClientReceiver& rhs );
  LOWIClientReceiver& operator=( const LOWIClientReceiver& rhs );
public:
  /**
   * Log Tag
   */
  static const char * const TAG;

  /**
   * Constructor LOWIClientReceiver
   * @param char* Name of the server socket to connect to
   * @param BlockingQueue* IPC BlockingQueue to communicate with main thread
   * @param MessageQueueClient* Pointer to MessageQueueClient to communicate
   *         with IPC Hub
   * @param MessageQueueServiceCallback* Pointer for callback on receiving the
   *        msg from IPC hub
   * @param char* Name of this client. Ideal choice is the thread ID.
   */
  LOWIClientReceiver(const char * const socket_name,
      BlockingQueue * const pLocalMsgQueue,
      MessageQueueClient * const conn,
      MessageQueueServiceCallback* const callback,
      const char* const client_name);
  /** Destructor*/
  virtual ~LOWIClientReceiver();

  /**
   * Blocking call to initialize the LOWIClientReceiver
   * Starts the thread internally and does register with IPC hub
   * Calling thread blocks untill the registration is done.
   *
   * @return true if success, false otherwise
   */
  bool init ();

protected:
  /**
   * Runs the main loop of the thread.
   * This will internally run the blocking loop of the
   * MessageQueueClient to receive and messages from the IPC hub
   * and provide callback in this thread context to the
   * MessageQueueServiceCallback
   */
  virtual void run();
};

} // namespace qc_loc_fw
#endif //#ifndef __LOWI_CLIENT_RECEIVER__
