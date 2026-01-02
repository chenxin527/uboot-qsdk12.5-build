/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 Sync utilities

 GENERAL DESCRIPTION
 This header declares utilities used for thread synchronization

 Copyright (c) 2012 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 =============================================================================*/
#ifndef __XTRAT_WIFI_SYNC_H__
#define __XTRAT_WIFI_SYNC_H__

#include <time.h>
#include <base_util/time_routines.h>

namespace qc_loc_fw
{

class Mutex
{
public:
  virtual ~Mutex() = 0;
  // name is only shallow copied (only the pointer is copied), so use constant string as the name!
  static Mutex * createInstance(const char * const tag = 0, const bool verboseLog = false);
  virtual int lock() = 0;
  virtual int unlock() = 0;
};

class AutoLock
{
private:
  Mutex * m_pMutex;
  const char * m_tag;
  bool m_locked;
public:
  AutoLock(Mutex * const pMutex, const char * log_tag = 0);
  ~AutoLock();
  int ZeroIfLocked();
};

class BlockingQueue
{
public:
  virtual ~BlockingQueue() = 0;

  static BlockingQueue * createInstance(const char * tag, const bool verboseLog = false);

  virtual int push(void * const ptr) = 0;
  virtual int close() = 0;

  // deprecated, as realtime/wall clock is not a good design choice
  // note the change in signature, that you have to explicitly specify timeout pointer to use this version
  // if you don't, you'll be using the new version with TimeDiff(false)
  virtual int pop(void ** const pptr, const timespec * const timeout_abs_realtime, bool * const p_is_queue_closed = 0) = 0;

  // pass in TimeDiff(true) if you do not want to wait, which is valid time difference of 0
  // pass in TimeDiff(false) if you want to wait forever, which is invalid time difference
  // pass in some valid TimeDiff and we are going to wait for it
  virtual int pop(void ** const pptr, const TimeDiff & timeout = TimeDiff(false), bool * const p_is_queue_closed = 0) = 0;
};

class Runnable
{
public:
  // expect Runnable to be deleted within Thread, and other places
  virtual ~Runnable() = 0;
  virtual void run() = 0;
};

class Thread
{
public:
  virtual ~Thread() = 0;

  static Thread * createInstance(const char * tag, Runnable * const pRunnable, const bool delete_runnable_at_destruction = true);

  // call 'launch' to start execution of this thread
  virtual int launch() = 0;

  // wait for it to complete
  virtual int join() = 0;
};

} // namespace qc_loc_fw

#endif //#ifndef __XTRAT_WIFI_SYNC_H__
