/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 List template

 GENERAL DESCRIPTION
 This component implements a list of any type

 Copyright (c) 2012-2014 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 Copyright (c) 2015 Qualcomm Technologies, Inc.
 All Rights Reserved.
 Confidential and Proprietary - Qualcomm Technologies, Inc.
 =============================================================================*/
#ifndef __XTRAT_WIFI_LIST_H__
#define __XTRAT_WIFI_LIST_H__

#include <new>

// for size_t, qsort
#include <stdlib.h>

#include <base_util/log.h>

namespace qc_loc_fw
{

// the reason we do not use STL/STLport is for portability.
// the availability of STL on other linux targets are not clear to
// me at this time
// also STL may or may not work well with JNI/NDK code for C++ exception

template<typename T>
class SingleListNode
{
public:
  SingleListNode(const T & rhs) :
      m_pNext(0), m_value(rhs)
  {
  }

  inline const SingleListNode<T> * getNext() const
  {
    return m_pNext;
  }

  inline SingleListNode<T> * getNext()
  {
    return m_pNext;
  }

  inline void setNext(SingleListNode<T> * const pNext)
  {
    m_pNext = pNext;
  }

  inline T & getValue()
  {
    return m_value;
  }

  inline const T & getValue() const
  {
    return m_value;
  }

  inline T * getPointer()
  {
    return &m_value;
  }

  inline const T * getPointer() const
  {
    return &m_value;
  }

private:
  SingleListNode<T> * m_pNext;
  T m_value;
};

template<typename T>
class List;

template<typename T>
class ConstListIterator
{
protected:
  static const char * const TAG;
  ConstListIterator(SingleListNode<T> * const pNode) :
      m_pNode(pNode)
  {
  }
  friend class List<T> ;
public:

  typedef T ValueType;

  inline bool operator==(const ConstListIterator & rhs) const
  {
    return (m_pNode == rhs.m_pNode);
  }

  inline bool operator!=(const ConstListIterator & rhs) const
  {
    return (m_pNode != rhs.m_pNode);
  }

  void operator++()
  {
    if(0 != m_pNode)
    {
      m_pNode = m_pNode->getNext();
    }
    else
    {
      log_error(TAG, "operator ++ with null iterator");
    }
  }

  const T& operator*() const
  {
    if(0 == m_pNode)
    {
      log_error(TAG, "operator * with null iterator");
      // we cannot return here, as Klockwork would complain explicitly
      // returning a NULL pointer (so it cannot be used without checking...)
      // directly calling this->m_pNode->getValue() confuses Klockwork so we wouldn't be seeing
      // the warning
    }

    return this->m_pNode->getValue();
  }

  const T* ptr() const
  {
    if(0 == m_pNode)
    {
      log_error(TAG, "ptr with null iterator");
      return 0;
    }
    else
    {
      return m_pNode->getPointer();
    }
  }

  inline const T* operator->() const
  {
    // we cannot call ptr() here, as Klockwork would complain about ptr() explicitly
    // returning a NULL pointer (so it cannot be used without checking...)
    // directly calling this->m_pNode->getPointer() confuses Klockwork so we wouldn't be seeing
    // the warning
    //return ptr();
    return this->m_pNode->getPointer();
  }

protected:
  SingleListNode<T> * m_pNode;
};

// note: to access any inherited member in a templated base class
// we need to either address full class name ::, or add this->
// this is new in C++ to avoid parser conflicts
template<typename T>
class ListIterator : public ConstListIterator<T>
{
private:
  ListIterator(SingleListNode<T> * const pNode) :
    ConstListIterator<T>(pNode)
  {
  }
  friend class List<T> ;
public:

  T& operator*() const
  {
    if(0 == this->m_pNode)
    {
      log_error(this->TAG, "operator * with null iterator");
      // we cannot return value of null pointer here, as Klockwork would complain,
      // returning a NULL pointer (so it cannot be used without checking...)
      // directly calling this->m_pNode->getValue() confuses Klockwork so we wouldn't be seeing
      // the warning
    }

    return this->m_pNode->getValue();
  }

  T* ptr() const
  {
    if(0 == this->m_pNode)
    {
      log_error(this->TAG, "ptr with null iterator");
      return 0;
    }
    else
    {
      return this->m_pNode->getPointer();
    }
  }

  inline T* operator->() const
  {
    // we cannot call ptr() here, as Klockwork would complain about ptr() explicitly
    // returning a NULL pointer (so it cannot be used without checking...)
    // directly calling this->m_pNode->getPointer() confuses Klockwork so we wouldn't be seeing
    // the warning
    //return ptr();
    return this->m_pNode->getPointer();
  }
};

template<typename T>
class List
{
private:
  static const char * const TAG;
public:

  typedef T ValueType;
  typedef ListIterator<T> Iterator;
  typedef ConstListIterator<T> ConstIterator;

  List() :
      m_pHead(0), m_size(0)
  {
  }

  int append(const List<T> & rhs)
  {
    int result = 0;
    for (List<T>::ConstIterator it = rhs.begin(); it != rhs.end(); ++it)
    {
      if(0 != add_head(*it))
      {
        result = 2;
        break;
      }
    }
    return result;
  }

  inline int append_reverse(const List<T> & rhs)
  {
    return append(rhs);
  }

  virtual ~List()
  {
    flush();
  }

  void flush()
  {
    SingleListNode<T> * pNode = m_pHead;
    while (0 != pNode)
    {
      SingleListNode<T> * pNextNode = pNode->getNext();
      delete pNode;
      pNode = pNextNode;
    }
    m_size = 0;
    m_pHead = 0;
  }

  int add(const T& rhs)
  {
    int result = 1;
    SingleListNode<T> * pNewNode = new SingleListNode<T>(rhs);
    if(0 != pNewNode)
    {
      pNewNode->setNext(m_pHead);
      m_pHead = pNewNode;
      ++m_size;
      result = 0;
    }
    else
    {
      // we're dead
      result = 2;
    }

    if(0 != result)
    {
      log_error(TAG, "add : failed %d", result);
    }

    return result;
  }

  int add_tail (const T& rhs)
  {
    int result = 1;
    SingleListNode<T> * pPrevNode = 0;
    SingleListNode<T> * pNode = m_pHead;

    SingleListNode<T> * pNewNode = new SingleListNode<T>(rhs);
    if (0 == pNewNode)
    {
      result = 2;
    }
    else
    {
      while (0 != pNode)
      {
        pPrevNode = pNode;
        pNode = pNode->getNext();
      }

      if (pPrevNode == 0)
      {
        m_pHead = pNewNode;
      }
      else
      {
        pPrevNode->setNext (pNewNode);
      }

      ++m_size;
      result = 0;
    }

    return result;
  }

  inline int add_head(const T& rhs)
  {
    return add(rhs);
  }

  int sort(bool reverse = false)
  {
    SingleListNode<T> ** nodes = 0;
    int result = 1;
    do
    {
      if(0 >= m_size)
      {
        // empty list
        result = 0;
        break;
      }

      nodes = new (std::nothrow) SingleListNode<T> *[m_size];
      if(0 == nodes)
      {
        result = 3;
        break;
      }
      // fill the array with null pointers
      for (size_t i = 0; i < m_size; ++i)
      {
        nodes[i] = 0;
      }

      // create an array of node pointers
      size_t index = 0;
      for (SingleListNode<T> * pNode = m_pHead; (pNode != 0) && (index < m_size); pNode = pNode->getNext())
      {
        nodes[index] = pNode;
        ++index;
      }

      if(index != m_size)
      {
        // inconsistent size and actual list content
        result = 4;
        break;
      }

      if(!reverse)
      {
        qsort(nodes, m_size, sizeof(SingleListNode<T> *), _comparator);
      }
      else
      {
        qsort(nodes, m_size, sizeof(SingleListNode<T> *), _reverse_comparator);
      }

      // note we have checked that the list cannot be empty, so node[0] is always defined
      m_pHead = nodes[0];
      // note we have checked that the list cannot be empty, so m_size is at least 1
      for (size_t i = 0; i < (m_size - 1); ++i)
      {
        nodes[i]->setNext(nodes[i + 1]);
      }
      // note we have checked that the list cannot be empty, so m_size is at least 1
      nodes[m_size - 1]->setNext(0);

      delete[] nodes;
      nodes = 0;

      result = 0;
    } while (0);

    if(0 != nodes)
    {
      delete[] nodes;
      nodes = 0;
    }

    if(0 != result)
    {
      log_error(TAG, "sort : failed %d", result);
    }
    return result;
  }

  int remove(const T& rhs, const bool ok_if_not_found = false)
  {
    int result = 1;
    SingleListNode<T> * pPrevNode = 0;
    SingleListNode<T> * pNode = m_pHead;

    while (0 != pNode)
    {
      if(rhs == pNode->getValue())
      {
        if(0 != pPrevNode)
        {
          pPrevNode->setNext(pNode->getNext());
        }
        else
        {
          // we're the head
          m_pHead = pNode->getNext();
        }
        --m_size;
        delete pNode;
        pNode = 0;
        result = 0;
        break;
      }
      pPrevNode = pNode;
      pNode = pNode->getNext();
    }

    if(0 != result)
    {
      if((1 == result) && ok_if_not_found)
      {
        // we couldn't find it, but caller said it's okay
        result = 0;
      }
      else
      {
        log_error(TAG, "remove: failed %d", result);
      }
    }

    return result;
  }

  Iterator erase(const Iterator & target)
  {
    int result = 1;
    SingleListNode<T> * pPrevNode = 0;
    SingleListNode<T> * pNode = m_pHead;
    SingleListNode<T> * pNextNode = 0;

    while (0 != pNode)
    {
      if(target == Iterator(pNode))
      {
        pNextNode = pNode->getNext();
        if(0 != pPrevNode)
        {
          pPrevNode->setNext(pNextNode);
        }
        else
        {
          // we're the head
          m_pHead = pNextNode;
        }
        --m_size;
        delete pNode;
        pNode = 0;
        result = 0;
        break;
      }
      pPrevNode = pNode;
      pNode = pNode->getNext();
    }

    if(0 != result)
    {
      log_error(TAG, "erase: failed %d", result);
    }

    return Iterator(pNextNode);
  }

  inline Iterator begin()
  {
    return Iterator(m_pHead);
  }

  inline Iterator end()
  {
    return Iterator(0);
  }

  inline ConstIterator begin() const
  {
    return ConstIterator(m_pHead);
  }

  inline ConstIterator end() const
  {
    return ConstIterator(0);
  }

  inline size_t getSize() const
  {
    return m_size;
  }

protected:
  SingleListNode<T> * m_pHead;
  size_t m_size;

  static int _comparator(const void * lhs, const void * rhs)
  {
    const SingleListNode<T> * const left_node = *reinterpret_cast<SingleListNode<T> * const *>(lhs);
    const SingleListNode<T> * const right_node = *reinterpret_cast<SingleListNode<T> * const *>(rhs);
    return list_comparator(left_node->getValue(), right_node->getValue());
  }

  static int _reverse_comparator(const void * lhs, const void * rhs)
  {
    return _comparator(rhs, lhs);
  }
};

template<typename T>
const char * const List<T>::TAG = "List";

template<typename T>
const char * const ConstListIterator<T>::TAG = "List";

} // namespace qc_loc_fw

#endif //#ifndef __XTRAT_WIFI_LIST_H__
