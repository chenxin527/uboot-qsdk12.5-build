/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 Queue template

 GENERAL DESCRIPTION
 This component implements a queue of any type

 Copyright (c) 2012-2014 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 =============================================================================*/
#ifndef __XTRAT_WIFI_QUEUE_H__
#define __XTRAT_WIFI_QUEUE_H__

#include <base_util/list.h>
#include <base_util/log.h>

namespace qc_loc_fw
{

template<typename T>
class Queue: public List<T>
{
private:
  static const char * const TAG;
public:
  Queue()
  {
  }

  virtual ~Queue()
  {
  }

  int push(const T& rhs)
  {
    // our specific requirement says pushing, or enqueuing, should be as fast as possible
    // this is exactly what list does for us: always O(1) for insertion at the head
    return this->add(rhs);
  }

  int top(T * const pValue)
  {
    int result = 1;
    do
    {
      if(0 == pValue)
      {
        result = 2;
        break;
      }

      SingleListNode<T> * pLastNode = 0;
      //SingleListNode<T> * pSecondLastNode = 0;
      SingleListNode<T> * pNode = List<T>::m_pHead;
      while (0 != pNode)
      {
        //pSecondLastNode = pLastNode;
        pLastNode = pNode;
        pNode = pNode->getNext();
      }

      if(0 != pLastNode)
      {
        *pValue = pLastNode->getValue();
      }
      else
      {
        // we started with an empty queue
        result = 3;
        break;
      }
      result = 0;
    } while (false);

    if(0 != result)
    {
      log_error(TAG, "top: failed %d", result);
    }
    return result;
  }

  int pop(T * const pValue)
  {
    int result = 1;
    do
    {
      if(0 == pValue)
      {
        result = 2;
        break;
      }

      SingleListNode<T> * pLastNode = 0;
      SingleListNode<T> * pSecondLastNode = 0;
      SingleListNode<T> * pNode = List<T>::m_pHead;
      while (0 != pNode)
      {
        pSecondLastNode = pLastNode;
        pLastNode = pNode;
        pNode = pNode->getNext();
      }

      if(0 != pSecondLastNode)
      {
        pSecondLastNode->setNext(0);
        List<T>::m_size = List<T>::m_size - 1;
      }
      else
      {
        // nothing, we only had 1 element and we just removed it
        List<T>::m_pHead = 0;
        List<T>::m_size = 0;
      }

      if(0 != pLastNode)
      {
        *pValue = pLastNode->getValue();
        delete pLastNode;
        pLastNode = 0;
      }
      else
      {
        // we started with an empty queue
        result = 3;
        break;
      }
      result = 0;
    } while (false);

    if(0 != result)
    {
      log_error(TAG, "pop: failed %d", result);
    }
    return result;
  }
};

template<typename T>
const char * const Queue<T>::TAG = "Queue";

} // namespace qc_loc_fw

#endif //#ifndef __XTRAT_WIFI_QUEUE_H__
