/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 Vector template

 GENERAL DESCRIPTION
 This component implements a vector of any type

 Copyright (c) 2012 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 Copyright (c) 2016 Qualcomm Technologies, Inc.
 All Rights Reserved.
 Confidential and Proprietary - Qualcomm Technologies, Inc.
 =============================================================================*/
#ifndef __XTRAT_WIFI_VECTOR_H__
#define __XTRAT_WIFI_VECTOR_H__

#include <base_util/log.h>

namespace qc_loc_fw
{

template<typename T>
class vector
{
private:
  static const char *const TAG;
  static const int DEFAULT_CAPACITY = 64;
public:

  typedef T *Iterator;

  vector() :
    m_pArray(0), m_capacity(0), m_num_elements(0)
  {
  }

  vector(const vector<T>& rhs) :
    m_pArray(0), m_capacity(0), m_num_elements(0)
  {
    (void)operator = (rhs);
  }

  virtual ~vector()
  {
    flush();
  }

  void flush()
  {
    if (0 != m_pArray)
    {
      delete[] m_pArray;
      m_pArray = 0;
    }
    m_capacity = 0;
    m_num_elements = 0;
  }

  int push_back(const T& element)
  {
    int result = 0;

    // Check if the Array has been allocated already.
    if (0 == m_pArray)
    {
      // Inserting an element where as the Array is not yet allocated
      // Allocate the array to default size
      m_capacity = DEFAULT_CAPACITY;
      m_pArray = new(std::nothrow) T[m_capacity];
      if (0 == m_pArray)
      {
        result = -1;
      }
    }
    else
    {
      // Memory is already allocated. Check if the Array is running on boundary
      if (m_capacity == m_num_elements)
      {
        // We do not have space for more elements
        // Double the size and copy over the elements in new array
        unsigned int new_size = 2 * m_capacity;
        T *pNewArray = new(std::nothrow) T[new_size];
        if (0 != pNewArray)
        {
          for (unsigned int i = 0; i < m_capacity; ++i)
          {
            pNewArray[i] = m_pArray[i];
          }
          m_capacity = new_size;
          delete[] m_pArray;
          m_pArray = pNewArray;
        }
        else
        {
          result = -2;
        }
      }
    }

    if (0 == result)
    {
      // Store the new element
      m_pArray[m_num_elements] = element;
      ++m_num_elements;
    }
    else
    {
      log_error(TAG, "insertion failed %d", result);
    }
    return result;
  }

  int pop_back(T& element)
  {
    int result = 0;
    if (0 == m_num_elements)
    {
      result = -1;
    }
    else
    {
      --m_num_elements;
      element = m_pArray[m_num_elements];
    }
    return result;
  }

  T & operator [](const unsigned int index)
  {
    if(index < m_num_elements)
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
    if(index < m_num_elements)
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

  unsigned int getNumOfElements() const
  {
    return m_num_elements;
  }

  unsigned int getCapacity() const
  {
    return m_capacity;
  }

  const vector<T> & operator =(const vector<T> & rhs)
  {
    int result = 1;

    if(&rhs == this)
    {
      // do nothing for self-assignment
      return *this;
    }

    flush();
    int new_size = rhs.getCapacity();

    if(new_size > 0)
    {
      int elements = rhs.getNumOfElements();
      T * pNewArray = new (std::nothrow) T[new_size];
      if(0 != pNewArray)
      {
        for (int i = 0; i < elements; ++i)
        {
          pNewArray[i] = rhs.m_pArray[i];
        }
        m_capacity = new_size;
        m_num_elements = elements;

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

  Iterator begin()
  {
    return Iterator(m_pArray);
  }

  Iterator end()
  {
    return Iterator(m_pArray + m_num_elements);
  }

private:
  T * m_pArray;
  unsigned int m_capacity;
  unsigned int m_num_elements;
};

template<typename T>
const char * const vector<T>::TAG = "vector";

} // namespace qc_loc_fw

#endif //#ifndef __XTRAT_WIFI_VECTOR_H__
