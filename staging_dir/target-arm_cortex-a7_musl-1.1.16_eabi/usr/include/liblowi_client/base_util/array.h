/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 Array template

 GENERAL DESCRIPTION
 This component implements an array of any type

 Copyright (c) 2012 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 =============================================================================*/
#ifndef __XTRAT_WIFI_ARRAY_H__
#define __XTRAT_WIFI_ARRAY_H__

#include <base_util/log.h>
#include <base_util/list.h>

namespace qc_loc_fw
{

template<typename T>
class Array
{
private:
  static const char * const TAG;
public:

  typedef T * Iterator;

  Array() :
      m_pArray(0), m_size(0)
  {
  }

  Array(const Array<T> & rhs) :
      m_pArray(0), m_size(0)
  {
    (void) operator =(rhs);
  }

  virtual ~Array()
  {
    flush();
  }

  int setSize(const unsigned int size)
  {
    int result = 1;
    flush();
    if(size > 0)
    {
      m_pArray = new T[size];
      if(0 != m_pArray)
      {
        m_size = size;
        result = 0;
      }
      else
      {
        m_size = 0;
        result = 2;
      }
    }
    else
    {
      // invalid size
      result = 3;
    }

    if(0 != result)
    {
      log_error(TAG, "set size failed %d", result);
    }
    return result;
  }

  void flush()
  {
    if(0 != m_pArray)
    {
      delete[] m_pArray;
      m_pArray = 0;
    }
    m_size = 0;
  }

  int insert(const List<T> & list)
  {
    int result = 1;
    if(list.getSize() > 0)
    {
      unsigned int new_size = m_size + list.getSize();
      T * pNewArray = new T[new_size];
      if(0 != pNewArray)
      {
        for (unsigned int i = 0; i < m_size; ++i)
        {
          pNewArray[i] = m_pArray[i];
        }

        const SingleListNode<T> * pNode = list.getHead();
        for (unsigned int j = m_size; j < new_size; ++j)
        {
          pNewArray[j] = pNode->getValue();
          pNode = pNode->getNext();
        }
        m_size = new_size;

        if(0 != m_pArray)
        {
          delete[] m_pArray;
        }
        m_pArray = pNewArray;
        result = 0;
      }
      else
      {
        result = 2;
      }
    }
    else
    {
      // do nothing. it's okay to insert empty list into an array
      result = 0;
    }

    if(0 != result)
    {
      log_error(TAG, "insertion failed %d", result);
    }
    return result;
  }

  T & operator [](const unsigned int index)
  {
    if(index < m_size)
    {
      return m_pArray[index];
    }
    else
    {
      log_error(TAG, "index out of range\n");
      // could be null reference, but we're doomed anyway
      return m_pArray[0];
    }
  }

  const T & operator [](const unsigned int index) const
  {
    if(index < m_size)
    {
      return m_pArray[index];
    }
    else
    {
      log_error(TAG, "index out of range\n");
      // could be null reference, but we're doomed anyway
      return m_pArray[0];
    }
  }

  unsigned int getSize() const
  {
    return m_size;
  }

  const Array<T> & operator =(const Array<T> & rhs)
  {
    int result = 1;

    if(&rhs == this)
    {
      // do nothing for self-assignment
      return *this;
    }

    flush();
    int new_size = rhs.getSize();

    if(new_size > 0)
    {

      T * pNewArray = new T[new_size];
      if(0 != pNewArray)
      {
        for (int i = 0; i < new_size; ++i)
        {
          pNewArray[i] = rhs.m_pArray[i];
        }
        m_size = new_size;

        if(0 != m_pArray)
        {
          delete[] m_pArray;
        }
        m_pArray = pNewArray;
        result = 0;
      }
      else
      {
        result = 2;
      }
    }
    else
    {
      // do nothing. it's okay to insert empty array into an array
      result = 0;
    }

    if(0 != result)
    {
      log_error(TAG, "assignment failed %d", result);
    }
    return *this;
  }

  // used in searching or sorting
  const T * getRawArray() const
  {
    return m_pArray;
  }
  T * getRawArray()
  {
    return m_pArray;
  }

  Iterator begin()
  {
    return Iterator(m_pArray);
  }

  Iterator end()
  {
    return Iterator(m_pArray + m_size);
  }

private:
  T * m_pArray;
  unsigned int m_size;
};

template<typename T>
const char * const Array<T>::TAG = "Array";

} // namespace qc_loc_fw

#endif //#ifndef __XTRAT_WIFI_ARRAY_H__
