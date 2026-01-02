/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 IPC message

 GENERAL DESCRIPTION
 This header declares two IPC messages, one for input and one for output

 Copyright (c) 2012, 2014 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

Copyright (c) 2014 Qualcomm Technologies, Inc.
 All Rights Reserved.
 Confidential and Proprietary - Qualcomm Technologies, Inc.
 =============================================================================*/
#ifndef __XTRAT_WIFI_POSTCARD_H__
#define __XTRAT_WIFI_POSTCARD_H__

#include <stdint.h>
#include <base_util/memorystream.h>

namespace qc_loc_fw
{

class PostcardBase
{
public:
  virtual ~PostcardBase() = 0;

  typedef double DOUBLE;
  typedef float FLOAT;
  typedef long long INT64;
  typedef unsigned long long UINT64;
  typedef int32_t INT32;
  typedef uint32_t UINT32;
  typedef int16_t INT16;
  typedef uint16_t UINT16;
  typedef char INT8;
  typedef unsigned char UINT8;
  typedef bool BOOL;
  typedef void* PTR;
};

class OutPostcard: public PostcardBase
{
public:
  // we only use 2 bytes to hold the name
  static const size_t MAX_ENCODE_NAME_LENGTH = 256;

  virtual ~OutPostcard() = 0;
  static OutPostcard * createInstance();

  virtual int init() = 0;
  virtual int finalize() = 0;
  virtual const MemoryStreamBase * getEncodedBuffer() const = 0;
  virtual OutMemoryStream * getInternalBuffer() = 0;

  virtual int addDouble(const char * const name, const DOUBLE & value) = 0;
  virtual int addFloat(const char * const name, const FLOAT & value) = 0;
  virtual int addInt64(const char * const name, const INT64 & value) = 0;
  virtual int addUInt64(const char * const name, const UINT64 & value) = 0;
  virtual int addInt32(const char * const name, const INT32 & value) = 0;
  virtual int addUInt32(const char * const name, const UINT32 & value) = 0;
  virtual int addInt16(const char * const name, const INT16 & value) = 0;
  virtual int addUInt16(const char * const name, const UINT16 & value) = 0;
  virtual int addInt8(const char * const name, const INT8 & value) = 0;
  virtual int addUInt8(const char * const name, const UINT8 & value) = 0;
  virtual int addBool(const char * const name, const BOOL & value) = 0;
  virtual int addString(const char * const name, const char * const str) = 0;
  virtual int addPtr(const char * const name, const PTR & value) = 0;
  virtual int addBlob(const char * const name, const void * const blob, const size_t length) = 0;
  virtual int addCard(const char * const name, const OutPostcard * const pCard) = 0;

  virtual int addArrayDouble(const char * const name, const int num_element, const DOUBLE array[]) = 0;
  virtual int addArrayFloat(const char * const name, const int num_element, const FLOAT array[]) = 0;
  virtual int addArrayInt64(const char * const name, const int num_element, const INT64 array[]) = 0;
  virtual int addArrayUInt64(const char * const name, const int num_element, const UINT64 array[]) = 0;
  virtual int addArrayInt32(const char * const name, const int num_element, const INT32 array[]) = 0;
  virtual int addArrayUInt32(const char * const name, const int num_element, const UINT32 array[]) = 0;
  virtual int addArrayInt16(const char * const name, const int num_element, const INT16 array[]) = 0;
  virtual int addArrayUInt16(const char * const name, const int num_element, const UINT16 array[]) = 0;
  virtual int addArrayInt8(const char * const name, const int num_element, const INT8 array[]) = 0;
  virtual int addArrayUInt8(const char * const name, const int num_element, const UINT8 array[]) = 0;
  virtual int addArrayBool(const char * const name, const int num_element, const BOOL array[]) = 0;
  virtual int addArrayPtr (const char * const name, const int num_element, const PTR array[]) = 0;
};

class InPostcard: public PostcardBase
{
public:
  virtual ~InPostcard() = 0;
  static InPostcard * createInstance();

  // assume ownership of the memory stream pointed by pInMem
  // the memory stream object will be deleted in our destructor
  // whether the actual memory block will be deleted with the destructor of
  // that InMemoryStream depends on the ownership setting of that InMemoryStream
  static InPostcard * createInstance(InMemoryStream * const pInMem);

  // assume ownership of the memory stream pointed by pCard->getEncodedBuffer
  // the memory stream object will be deleted in our destructor
  // pCard becomes useless can can only be deleted after this operation
  static InPostcard * createInstance(OutPostcard * const pCard);

  // doesn't assume ownership of the memory pointed by pIn
  // the memory block won't be deleted in our destructor
  virtual int init(const void * const pIn, const size_t length, bool assume_ownership = false) = 0;
  virtual const MemoryStreamBase * getBuffer() const = 0;

  static const int FIELD_NOT_FOUND = -1;
  virtual int getDouble(const char * const name, DOUBLE & value) = 0;
  virtual int getFloat(const char * const name, FLOAT & value) = 0;
  virtual int getInt64(const char * const name, INT64 & value) = 0;
  virtual int getUInt64(const char * const name, UINT64 & value) = 0;
  virtual int getInt32(const char * const name, INT32 & value) = 0;
  virtual int getUInt32(const char * const name, UINT32 & value) = 0;
  virtual int getInt16(const char * const name, INT16 & value) = 0;
  virtual int getUInt16(const char * const name, UINT16 & value) = 0;
  virtual int getInt8(const char * const name, INT8 & value) = 0;
  virtual int getUInt8(const char * const name, UINT8 & value) = 0;
  //virtual int getArrayUInt8(const char * const name, UINT8 array[]) = 0;
  virtual int getBool(const char * const name, BOOL & value) = 0;
  virtual int getString(const char * const name, const char ** pStr) = 0;
  virtual int getStringDup(const char * const name, const char ** pStr) = 0;

  virtual int getDoubleDefault(const char * const name, DOUBLE & value) = 0;
  virtual int getFloatDefault(const char * const name, FLOAT & value) = 0;
  virtual int getInt64Default(const char * const name, INT64 & value) = 0;
  virtual int getUInt64Default(const char * const name, UINT64 & value) = 0;
  virtual int getInt32Default(const char * const name, INT32 & value) = 0;
  virtual int getUInt32Default(const char * const name, UINT32 & value) = 0;
  virtual int getInt16Default(const char * const name, INT16 & value) = 0;
  virtual int getUInt16Default(const char * const name, UINT16 & value) = 0;
  virtual int getInt8Default(const char * const name, INT8 & value) = 0;
  virtual int getUInt8Default(const char * const name, UINT8 & value) = 0;
  virtual int getBoolDefault(const char * const name, BOOL & value) = 0;
  virtual int getStringOptional(const char * const name, const char ** pStr) = 0;
  virtual int getPtr(const char * const name, PTR & value) = 0;

  virtual int getBlob(const char * const name, const void ** const pBlob, size_t * const pLength) = 0;
  virtual int getCard(const char * const name, InPostcard ** const ppCard, const int index = 0) = 0;

  // Note for alignment issue, we cannot directly return a pointer pointing to internal buffer
  // so we have to explicitly allocate and de-allocate a memory block according to alignment rule
  // call these functions twice. first set array to 0 and get the number of elements
  virtual int getArrayDouble(const char * const name, int * const pNumElem, DOUBLE * const array = 0) = 0;
  virtual int getArrayFloat(const char * const name, int * const pNumElem, FLOAT * const array = 0) = 0;
  virtual int getArrayInt64(const char * const name, int * const pNumElem, INT64 * const array = 0) = 0;
  virtual int getArrayUInt64(const char * const name, int * const pNumElem, UINT64 * const array = 0) = 0;
  virtual int getArrayInt32(const char * const name, int * const pNumElem, INT32 * const array = 0) = 0;
  virtual int getArrayUInt32(const char * const name, int * const pNumElem, UINT32 * const array = 0) = 0;
  virtual int getArrayInt16(const char * const name, int * const pNumElem, INT16 * const array = 0) = 0;
  virtual int getArrayUInt16(const char * const name, int * const pNumElem, UINT16 * const array = 0) = 0;
  virtual int getArrayInt8(const char * const name, int * const pNumElem, INT8 * const array = 0) = 0;
  virtual int getArrayUInt8(const char * const name, int * const pNumElem, UINT8 * const array = 0) = 0;
  virtual int getArrayBool(const char * const name, int * const pNumElem, BOOL * const array = 0) = 0;
  virtual int getArrayPtr (const char * const name, int * const pNumElem, PTR * const array = 0) = 0;

};

} // namespace qc_loc_fw

#endif // #ifndef __XTRAT_WIFI_POSTCARD_H__
