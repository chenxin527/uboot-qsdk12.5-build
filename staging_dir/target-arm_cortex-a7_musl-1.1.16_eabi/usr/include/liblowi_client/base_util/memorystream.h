/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 Memory stream

 GENERAL DESCRIPTION
 This header declares two memory streams, one for input and one for output

 Copyright (c) 2012 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 =============================================================================*/
#ifndef __XTRAT_WIFI_MEMORY_STREAM_H__
#define __XTRAT_WIFI_MEMORY_STREAM_H__

#include <stddef.h>

namespace qc_loc_fw
{

class MemoryStreamBase
{
public:
  virtual ~MemoryStreamBase() = 0;

  typedef unsigned char BYTE;
  virtual size_t getSize() const = 0;
  virtual const BYTE * getBuffer() const = 0;
};

class OutMemoryStream: public MemoryStreamBase
{
public:
  static OutMemoryStream * createInstance();
  virtual ~OutMemoryStream() = 0;

  // note: only OutMemoryStream supports the non-const version of getBuffer
  virtual BYTE * getBufferNonConst() = 0;

  virtual int append(const void * const pData, const size_t length) = 0;
  virtual size_t getPutCursor() const = 0;
};

class InMemoryStream: public MemoryStreamBase
{
public:
  static InMemoryStream * createInstance();

  // take ownership of the memory block from given OutMemoryStream 'os'
  // after this statement, 'os' is no longer usable, and won't delete the memory block at destruction
  // instead, this newly created InMemoryStream will have to delete that memory block
  static InMemoryStream * createInstance(OutMemoryStream * const os);

  virtual ~InMemoryStream() = 0;

  virtual int setBufferOwnership(const void ** const ppIn, const size_t length) = 0;
  virtual int setBufferNoDup(const void * const pIn, const size_t length) = 0;
  virtual int extract(void * const pData, const size_t length) = 0;
  virtual size_t getGetCursor() const = 0;
  virtual int setGetCursor(const size_t cursor) = 0;
  virtual size_t getCapacity() const = 0;
};

} // namespace qc_loc_fw

#endif //#ifndef __XTRAT_WIFI_MEMORY_STREAM_H__
