/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 MQ client controller base

 GENERAL DESCRIPTION
 This header declares the public interface of main controller for client core

 Copyright (c) 2012 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 =============================================================================*/
#ifndef __MQ_CLIENT_CORE_CONTROLLER_BASE_H__
#define __MQ_CLIENT_CORE_CONTROLLER_BASE_H__

#include <base_util/list.h>
#include <base_util/sync.h>
#include <base_util/config_file.h>
#include <mq_client/mq_client.h>
#include <base_util/postcard.h>
#include <base_util/time_routines.h>

namespace qc_loc_fw
{

class TimerDataInterface
{
public:
  virtual ~TimerDataInterface() = 0;

  // this is used at timer de-registration
  virtual bool operator ==(const TimerDataInterface & rhs) const = 0;
};

class MqClientFunctionalModuleBase
{
public:
  virtual ~MqClientFunctionalModuleBase() = 0;
  virtual int init() = 0;
  virtual int deinit() = 0;

  // if this component needs timer service, it must implement this function
  virtual void timerCallback(const TimerDataInterface * const)
  {
  }
};

class TimerCallbackEntry
{
public:
  bool operator ==(const TimerCallbackEntry & rhs) const;

  Timestamp absolute_timeout;
  MqClientFunctionalModuleBase * module;
  const TimerDataInterface * data;
};

// You might actually inherit from this class, so you can send specialized messages internally
// to your own blocking queue, with or without a postcard
class MqMsgWrapper
{
protected:
  // the purpose of this class is to be allocated from heap and then
  // used as a carrier in the local blocking message queue
  // putting it into private prevents us from creating this on stack by mistake
  MqMsgWrapper (InPostcard * const in_card);
public:
  virtual ~MqMsgWrapper();

  static MqMsgWrapper * createInstance(InPostcard * const in_card);

  // note: the postcard is going to be deleted at destruction of this wrapper
  InPostcard * m_in_card;
  Timestamp m_timestamp;
};

class MqClientControllerBase: public Runnable
{
public:
  virtual ~MqClientControllerBase();

  virtual int sendIpcMessage(const MemoryStreamBase * const buffer);

  static const int MIN_TX_ID;
  static const int INVALID_TX_ID;
  virtual int getNextTxId();

  virtual int setLocalTimer(const unsigned int timeout_in_sec, MqClientFunctionalModuleBase * const module,
      const TimerDataInterface * const data);
  virtual int setLocalTimer(const TimeDiff & timeout_diff, MqClientFunctionalModuleBase * const module,
      const TimerDataInterface * const data);

  virtual int removeLocalTimer(const MqClientFunctionalModuleBase * const module, TimerDataInterface * const data);

  // used by main thread to initialize members
  virtual int init();
  // used by main thread to register for death recipients. only safe to add after all are successfully 'init'
  virtual int addPeer(MqClientControllerBase * const peer);
  // used by main thread to kick start this IPC client
  virtual int launch();
  // kill this IPC client by inserting a KILL message into the queue. concurrent access, but only safe after a successful 'init'
  virtual int kill();
  // used by main thread to wait for completion of this IPC client
  virtual int join();

  virtual const char * getSelfIpcName() const;

  // note after this call, ownership of the encoded buffer inside this msg would be transferred out
  // which means you cannot use this postcard again and should destroy it
  virtual int sendLocalMessage(qc_loc_fw::OutPostcard * const msg);

protected:
  friend class Thread;

  const char * TAG;
  const char * const m_name;
  const char * const m_server_socket_name;
  const char * const m_config_name;
  int m_last_tx_id;

  enum CTRL_STATE
  {
    CS_NOT_READY_YET = 0, CS_READY, CS_DESTROYED,
  };
  CTRL_STATE m_state;

  List<MqClientControllerBase *> m_peers;
  List<TimerCallbackEntry> m_timers;
  Thread * m_ipc_receiver_thread;
  Thread * m_ipc_handler_thread;
  BlockingQueue * m_local_msg_queue;
  MessageQueueClient * m_conn;
  ConfigFile * m_config;

  MqClientControllerBase(const char * const tag, const char * const name, const char * const server_socket_name,
      const char * const config_name);

  int getNearestDeadline(bool & fgDeadlineSet, Timestamp & timeout);

  // be called at the last stage of 'init'
  virtual int _init() = 0;
  virtual void run();

  // inherit this one if you do not need the local timestamp when we received the message
  virtual void _process(InPostcard * const in_msg);

  // inherit this one if you want the local timestamp when we received the message
  virtual void _process(MqMsgWrapper * const msg_wrapper);

  // be called at the last stage of 'run'
  // the decendent shall consider calling this in its own destructor, to make sure this function
  // is called without first 'run'
  // this cannot be automated for destrctor for base class canned call virtual function of
  // the decendent class (for it has been destructed)
  // the implementation of this function shall guard itself by checking if m_state is already CS_DESTROYED,
  // which shall be set at the end of this function
  virtual void _shutdown() = 0;
};

} // namespace xtrat_wifi

#endif // #ifndef __MQ_CLIENT_CORE_CONTROLLER_BASE_H__
