#ifndef __LOWI_CLIENT_H__
#define __LOWI_CLIENT_H__

/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

        LOWI Client Interface Header file

GENERAL DESCRIPTION
  This file contains the structure definitions and function prototypes for
  LOWIClient

  Copyright (c) 2012, 2018 Qualcomm Technologies, Inc.
  All Rights Reserved.
  Confidential and Proprietary - Qualcomm Technologies, Inc.

  (c) 2012 Qualcomm Atheros, Inc.
  All Rights Reserved.
  Qualcomm Atheros Confidential and Proprietary.

=============================================================================*/

#include <base_util/postcard.h>
#include <base_util/sync.h>
#include <inc/lowi_const.h>
#include <inc/lowi_request.h>
#include <inc/lowi_response.h>
#include <mq_client/mq_client.h>

namespace qc_loc_fw
{

// Forward declaration
class LOWIClientReceiver;

/**
 * This class should be sub classed by the client of LOWI to receive
 * responses to the requests made through LOWIClient.
 */
class LOWIClientListener
{
public:
  /**
   *  Notifies the listener whenever the Response is received
   *  for a Request sent by the client.
   *
   *  NOTE: The notification happens in a different thread as compared
   *  to the thread in which the request was made by the client.
   *
   *  @param LOWIResponse* Response received
   *
   *  @usage Client upon receiving this callback should inspect the type
   *          of response by response->getResponseType () and then type cast
   *          the response to retrieve the response data.
   *          i.e. Sample usage of a Capabilities response is
   *          if (response->getResponseType () == LOWIResponse.CAPABILITY)
   *          {
   *            LOWICapabilities* cap =
   *             ((LOWICapabilityResponse)response)->getCapabilities();
   *          }
   */
  virtual void responseReceived (LOWIResponse* response) = 0;

  /** Destructor */
  virtual ~LOWIClientListener () = 0;
};

/**
 * API for requesting scans using LOWIClient
 */
class LOWIClient : public MessageQueueServiceCallback
{
private:
  static const char  *const TAG;
  LOWIClientListener *const mLOWIClientListener;
  LOWIClientReceiver *mLOWIClientReceiver;
  MessageQueueClient *mConn;
  BlockingQueue      *mLocalMsgQueue;
  BlockingQueue      *mLocalMsgQueueBg;
  char               *mClientName;
  bool                mBlock;
  bool                mBlockBg;

  /**
   * Constructor
   * @param LOWIClientListener* Pointer to the LOWIClientListener
   *                              which will be notified when the
   *                              response is received.
   */
  LOWIClient(LOWIClientListener* const ptr);

  /**
   * Initializes the LOWIClient and triggers registration with IPC Hub
   * It is a blocking call until the initialization completes or fails.
   * Client must init the LOWIClient before issuing requests.
   *
   * @return bool true - success, false - failure
   */
  bool init ();

  // private copy constructor and assignment operator so that the
  // the instance can not be copied.
  LOWIClient( const LOWIClient& rhs );
  LOWIClient& operator=( const LOWIClient& rhs );

public:
  /**
   * Defines the status of the Request.
   */
  enum eRequestStatus
  {
    /** Request is successfully sent to LOWI*/
    STATUS_OK,
    /** Error due to bad parameters*/
    BAD_PARAMS,
    /** Failure to send request to LOWI*/
    SEND_FAILURE
  };

  /**
   * Defines the log level.
   */
  enum eLogLevel
  {
    /** No logging*/
    LL_LOG_OFF = 0,
    /** Error level*/
    LL_ERROR = 1,
    /** Warning level*/
    LL_WARNING = 2,
    /** Info level*/
    LL_INFO = 3,
    /** Debug level*/
    LL_DEBUG = 4,
    /** Verbose level*/
    LL_VERBOSE = 5,
    /** Log all*/
    LL_LOG_ALL = 100
  };

  /**
   * Creates instance of LOWIClient and initializes it.
   * It is a blocking call until the Instance is created and registered
   * with the IPC hub
   * @param LOWIClientListener* Pointer to the LOWIClientListener
   *                              which will be notified when the
   *                              response is received.
   * @param bool     bool To enable / disable logging(optional).
   * @param eLogLevel Log level at which the library should be logging.
   *                  This will only take effect if the logging is
   *                  enabled in previous parameter(optional).
   */
  static LOWIClient* createInstance (LOWIClientListener* const ptr,
      bool enableLogging = false, eLogLevel log_level = LL_INFO);

  /** Destructor*/
  virtual ~LOWIClient();

  /**
   * Sends the Request created by the client.
   * @param   LOWIRequest* Request to be processed
   * @return  eReturnSatus  Return status of the request
   */
  eRequestStatus sendRequest (LOWIRequest* const request);

  /**
   *  Sends request for capabilities created by the client. Blocks until the
   *  capabilities are received or a timeout occurs if the capabilities do not
   *  come.
   *  The timeout is defined by CAPABILITIES_REQ_BLOCKING_TIMEOUT_SEC which is
   *  currently set to 5 secs.  This will be the maximum time the client will
   *  have to wait if no response is generated by lowi controller.
   *
   * @param request: request to be processed
   * @return LOWICapabilityResponse*: ptr to capabilities response
   */
  LOWICapabilityResponse* getCapabilities(LOWIRequest* const request);

  /**
   * Process a request created by the client. Checks the request type and blocks
   * on the following request types until a corresponding response is returned.
   * Blocking timeout is defined by STATUS_BLOCKING_TIMEOUT_SEC which is
   * currently set to 5 sec.
   * -- BGSCAN_CAPABILITIES
   * -- BGSCAN_CHANNELS_SUPPORTED
   * -- BGSCAN_CACHED_RESULTS
   * -- BGSCAN_START
   * -- BGSCAN_STOP
   * -- HOTLIST_SET
   * -- HOTLIST_CLEAR
   * -- SIGNIFINCANT_CHANGE_LIST_SET
   * -- SIGNIFINCANT_CHANGE_LIST_CLEAR
   *
   * @param LOWIRequest*: request to be processed
   * @return LOWIResponse*: pointer to LOWIResponse
   */
  LOWIResponse* processRequest(LOWIRequest* const request);

  /**
   * Composes an OutPostCard from the Request created by the client.
   *
   * This API is intended for the clients that have there own socket based IPC
   * implementation and are registered with the IPC hub. Such clients just need
   * to call this API to convert the Request to an OutPostCard which could then
   * be sent to the IPC Hub by the client. The recipient field of the Postcard
   * is populated by this API.
   *
   * Note: Memory should be deallocated by the client
   *
   * @param LOWIRequest* Request to be converted to an OutPostCard
   * @param char* ID of the originator which will be added to the OutPostCard
   * @return OutPostCard
   */
  static OutPostcard* composePostCard (LOWIRequest* const request,
      const char* const originatorId);

  /**
   * Parses an InPostCard and generates the Response needed by the client.
   *
   * This API is intended for the clients that have there own socket based IPC
   * implementation and are registered with the IPC hub. Such clients communicate
   * with the uWifiPsoAPI process through IPC hub to send and receive Postcards
   * on there own and need this API to parse the InPostCard into a Response.
   *
   * Note: Memory should be deallocated by the client
   *
   * @param InPostcard* InPostcard to be parsed
   * @return LOWIResponse
   */
  static LOWIResponse* parsePostCard (InPostcard* const postcard);

  /**
   * Sets logging level for LOWIClient library.
   * @param eLogLevel Log level at which the library should be logging.
   * @return true for success, false otherwise
   */
  static bool setLogLevel (eLogLevel log_level);

private:
  /**
   * Handles Response. Called by LOWIClientReceiver thread in it's own thread
   * context.
   * @param InMemoryStream*  Message received from the IPC hub
   */
  int newMsg(qc_loc_fw::InMemoryStream * new_buffer);
};

} // namespace qc_loc_fw

#endif //#ifndef __LOWI_CLIENT_H__
