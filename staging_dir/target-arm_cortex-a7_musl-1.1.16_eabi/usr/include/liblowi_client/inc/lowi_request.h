#ifndef __LOWI_REQUEST_H__
#define __LOWI_REQUEST_H__

/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

        LOWI Request Interface Header file

GENERAL DESCRIPTION
  This file contains the structure definitions and function prototypes for
  LOWIRequest

  Copyright (c) 2012-2013,2015-2019 Qualcomm Technologies, Inc.
  All Rights Reserved.
  Confidential and Proprietary - Qualcomm Technologies, Inc.

  (c) 2012-2013 Qualcomm Atheros, Inc.
  All Rights Reserved.
  Qualcomm Atheros Confidential and Proprietary.

=============================================================================*/
#include <inc/lowi_const.h>
#include <inc/lowi_mac_address.h>
#include <inc/lowi_ssid.h>
#include <string>

namespace qc_loc_fw
{
class LOWIUtils;

/**
 * Status of driver(wifi/wigig) interface
 */
enum eWifiIntfState
{
  INTF_UNKNOWN = -1, // interface is not recognized
  INTF_DOWN    = 0,  // interface is OFF
  INTF_UP      = 1,  // interface is ON
  INTF_RUNNING = 2,  // interface is Associated or in SAP mode
};

/**
 * Base class for all requests LOWI can handle
 */
class LOWIRequest
{
private:
  /** Identity of request originator*/
  char* mRequestOriginator;
  uint32 mRequestId;
  std::string mInterface;
public:

  /**
   * Log Tag
   */
  static const char * const TAG;

  /** Type of Request */
  // NOTE:
  // When adding additional requests, update the following utility function:
  //  -- LOWIUtils::to_string(LOWIRequest::eRequestType a)
  //
  //  ADD NEW REQUESTS ONLY AT THE END OF THIS ENUM
  enum eRequestType
  {
    /** Request a passive or active scan from the wifi driver */
    DISCOVERY_SCAN = 0,
    /** Request to do RTT ranging with another wifi node */
    RANGING_SCAN,
    /** Retrieve LOWI capabilities for ranging, etc */
    CAPABILITY,
    /** Clear the WiFi node cached by LOWI */
    RESET_CACHE,
    /** Receive any scan results if and when available */
    ASYNC_DISCOVERY_SCAN_RESULTS,
    /** Do periodic RTT ranging measurements with LOWI managing the
     *  periodic requests to FW */
    PERIODIC_RANGING_SCAN,
    /** Cancel a PERIODIC_RANGING_SCAN request previously sent */
    CANCEL_RANGING_SCAN,
    /** Retrive specific background scan FW capabilities. Available on STA only */
    BGSCAN_CAPABILITIES,
    /** Retrieve a list of frequency channels supported by the WiFi driver. Available on STA only */
    BGSCAN_CHANNELS_SUPPORTED,
    /** Start a batching periodic background scan. Available on STA only */
    BGSCAN_START,
    /** Stop a batching periodic background scan previously requested. Available on STA only */
    BGSCAN_STOP,
    /** Retrieve the cached background scan results. Available on STA only */
    BGSCAN_CACHED_RESULTS,
    /** Start detection on a "hotlist" of APs provided in this request. Available on STA only */
    HOTLIST_SET,
    /** Stop a HOTLIST_SET request sent previously and clear the hotlist. Available on STA only */
    HOTLIST_CLEAR,
    /** Start significant change detection on a list of APs provided in
     *  this request. Available on STA only */
    SIGNIFINCANT_CHANGE_LIST_SET,
    /** Stop a SIGNIFINCANT_CHANGE_LIST_SET request sent previously and
     *  clear the list of APs. Available on STA only */
    SIGNIFINCANT_CHANGE_LIST_CLEAR,
    /** Start a batching periodic background scan request on the LP processor. Available on STA only */
    BATCHING_START,
    /** Stop a BATCHING_START request previously sent. Available on STA only */
    BATCHING_STOP,
    /** Retrieve the cached background scan results from the LP processor. Available on STA only */
    BATCHING_CACHED_RESULTS,
    /** Subscribe to receive dynamic capabilities. Available on STA only */
    CAPABILITY_SUBSCRIPTION,
    /** Set LCI location information */
    SET_LCI_INFORMATION,
    /** Set LCR location information */
    SET_LCR_INFORMATION,
    /** Request neighbor report from associated AP */
    NEIGHBOR_REPORT,
    /** Request LCI and/or Civic location via ANQP. Available on STA only */
    LOCATION_ANQP,
    /** lowi Internal Message */
    LOWI_INTERNAL_MESSAGE,
    /** Retrieve the channel supported for the STA ranging
     * by the WiFi driver. Available on STA only */
    LOWI_RTT_RM_CHANNEL_REQUEST,
    /** Send request to FW to enable responder. Available on STA only */
    LOWI_ENABLE_RESPONDER_REQUEST,
    /** Send request to FW to disable responder. Available on STA only */
    LOWI_DISABLE_RESPONDER_REQUEST,
    /** Request to query the current WLAN state*/
    LOWI_WLAN_STATE_QUERY_REQUEST,
    /** Request LCI of remote STA. Only available on Access point LOWI */
    SEND_LCI_REQUEST,
    /** Request FTMRanging to remote STA. Only available on Access point LOWI */
    FTM_RANGE_REQ,
    /** Request to configure LOWI, logging configuration is currently supported */
    LOWI_CONFIG_REQUEST,
    /** Send request to FW to start measurement req in responder mode */
    LOWI_START_RESPONDER_MEAS_REQUEST,
      /** Send request to FW to stop measurement req in responder mode */
    LOWI_STOP_RESPONDER_MEAS_REQUEST
  };

  /**
   * Constructor
   * @param uint32 Request Id generated by the client
   */
  LOWIRequest (uint32 requestId);
  /** Destructor*/
  virtual ~LOWIRequest () = 0;

  /** Copy Constructor */
  LOWIRequest( const LOWIRequest& rhs );
  /** Assignment operator */
  LOWIRequest& operator=( const LOWIRequest& rhs );

  /**
   * Returns the Request Originator
   * @return char* Request originator's id
   */
  const char* getRequestOriginator () const;

  /**
   * Sets the Request originator for the request.
   * Used internally by LOWI to identify the originator
   * of the request and send the responses back to the originator.
   *
   * Note: Clients of LOWI API do not need to set the originator as
   * there is no affect of doing so.
   */
  void setRequestOriginator (const char* const request_originator);

  /**
   * Returns the RequestId
   * @return RequestId generated by the user of the API
   */
  uint32 getRequestId () const;

  /* Set interface */
  std::string get_interface() const;
  /* Get interface */
  void set_interface(std::string iface);
  /**
   * Returns the request type
   * @return eRequestType type of request
   */
  virtual eRequestType getRequestType () const = 0;
};

///////////////////////////
// Capability Request
///////////////////////////

/**
 * Capability Request
 */
class LOWICapabilityRequest: public LOWIRequest
{
public:
  /**
   * Constructor
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   */
  LOWICapabilityRequest (uint32 requestId);
  /** Destructor*/
  virtual ~LOWICapabilityRequest ();

  /**
   * Returns the request type
   * @return eRequestType type of request
   */
  virtual eRequestType getRequestType () const;

};

///////////////////////////
// Cache Reset Request
///////////////////////////
/**
 * Cache Reset Request
 */
class LOWICacheResetRequest: public LOWIRequest
{
public:
  /**
   * Constructor
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   */
  LOWICacheResetRequest (uint32 requestId);
  /** Destructor*/
  virtual ~LOWICacheResetRequest ();

  /**
   * Returns the request type
   * @return eRequestType type of request
   */
  virtual eRequestType getRequestType () const;
};

///////////////////////////
// Discovery scan Request
///////////////////////////
// Forward declaration
class LOWIChannelInfo;

/**
 * Class to make a Discovery scan request
 */
class LOWIDiscoveryScanRequest: public LOWIRequest
{
public:
  /** Defines the available type of Discovery Scan*/
  enum eScanType
  {
    /**Passive Scan*/
    PASSIVE_SCAN,
    /**Active Scan*/
    ACTIVE_SCAN
  };

  /** Defines the available mode of Discovery Scan Request*/
  enum eRequestMode
  {
    /** Request to perform a Fresh scan. The request will trigger a Request
     * being sent to WifiDriver for fresh scan */
    FORCED_FRESH,
    /** Request to perform Fresh scan with throttling. If the last fresh
     * scan results are relatively fresh then this Request will be serviced
     * from Cache. Criteria to determine freshness is
     * current time < last scan time + threshold (defined in config file)
     */
    NORMAL,
    /** Request to return the result from Cache*/
    CACHE_ONLY,
    /** Request to provide the result from Cache but if results
     * are not found in cache then start the fresh scan*/
    CACHE_FALLBACK
  };

  /** Defines the bands for which the Discovery Scan Request can be made */
  enum eBand
  {
    /** 2.4 GHz only*/
    TWO_POINT_FOUR_GHZ = 0,
    /** 5 GHz only */
    FIVE_GHZ = 1,
    /** Both (2.4 & 5 GHz) */
    BAND_ALL
  };

  /**
   * Returns the scan type
   * @return Passive scan or Active scan
   */
  eScanType getScanType () const;
  /**
   * Returns the request mode
   * @return Mode of request
   */
  eRequestMode getRequestMode () const;
  /**
   * Returns Measurement age filter in seconds.
   * For Cache Request, at the time of generating the
   *  response for the request, all the measurements which
   *  are older than Current time - filter age,
   *  will be filtered out from the response.
   *  So '0' age filter could potentially
   *  return no measurements from the cache.
   *
   * For Fresh scan Request, at the time of generating the
   *  response for the request, all the measurements which
   *  are older than Request time to WLAN driver - filter age,
   *  will be filtered out from the response.
   * @return Measurement Age filter in seconds
   */
  uint32 getMeasAgeFilterSec () const;
  /**
   * Returns fallback tolerance in seconds.
   * Only valid when eRequestMode is CACHE_FALLBACK.
   * At the time of evaluating this request, all the
   * requested channels should have last measurement
   * timestamp equal to or greater than Current time -
   * Fallback tolerance. If not, then fallback to
   * trigger a fresh scan. Client can provide 0 if they
   * want to trigger a fresh scan as well.
   * @return Cache fallback tolerance
   */
  uint32 getFallbackToleranceSec () const;
  /**
   * Returns the band
   * @return RF band to scan.
   */
  eBand getBand () const;
  /**
   * Returns the dynamic array containing the ChannelInfo to be scanned.
   * Number of entries in the vector should not be more than
   * MAX_CHAN_INFO_SIZE as that's the max LOWI supports as of
   * now. Any ChannelInfo more than MAX_CHAN_INFO_SIZE will be
   * ignored.
   * @return Dynamic array containing channel specific information
   */
  vector <LOWIChannelInfo> & getChannels ();
  /**
   * Returns absolute timestamp on which the request will be dropped
   * if not processed already. Value should be -1 if the
   * timeoutTimestamp is not valid.
   * @return Request timeout timestamp
   */
  int64 getTimeoutTimestamp () const;
  /**
   * Returns cache request buffer preference.
   * This is set to true if the cache request has to be buffered until the
   * existing transaction is finished.
   * Will be ignored if there is no ongoing transaction.
   * Will be ignored for FRESH_ONLY requestMode
   * This can be used to get the latest results included in the cache request.
   */
  bool getBufferCacheRequest () const;

  bool getFullBeaconScanResponse () const
  {
    return fullBeaconScanResponse;
  }

  /** Destructor*/
  virtual ~LOWIDiscoveryScanRequest ();

  /**
   * Returns the request type
   * @return eRequestType type of the Request
   */
  virtual eRequestType getRequestType () const;

  /**
   * Helper function to create a DiscoveryScanRequest for CACHE_ONLY Request
   * mode. This API could be used to perform CACHE_ONLY discovery scan on any
   * band.
   *
   * @param uint32 Request ID generated by the client to track the response.
   *                Response for this Request will contain the same request Id.
   * @param eBand Band in which the scan is to be performed
   * @param uint32 Measurement age filter in seconds.
   *               For Cache Request, at the time of generating the
   *               response for the request, all the measurements which
   *               are older than Current time - filter age,
   *               will be filtered out from the response.
   *               So '0' age filter could potentially
   *               return no measurements from the cache.
   * @param int64 Timestamp at which this request should be dropped if not
   *              processed already. Should be 0 if this is to be ignored.
   * @param bool The request will be cached and processed after the current
   *             fresh scan completes if this flag is on. Will be honoured only
   *             if there is an ongoing fresh scan at the time of receiving this
   *             request
   */
  static LOWIDiscoveryScanRequest* createCacheOnlyRequest (uint32 requestId,
      eBand band, uint32 meas_age_filter_sec,
      int64 timeoutTimestamp, bool bufferCacheRequest);

  /**
   * Helper function to create a DiscoveryScanRequest for CACHE_FALLBACK
   * Request mode. This API could be used to perform CACHE_ONLY discovery
   * scan on any band.
   *
   * @param uint32 Request ID generated by the client to track the response.
   *                Response for this Request will contain the same request Id.
   * @param eBand Band in which the scan is to be performed
   * @param eScanType Type of discovery scan Active / Passive. Only
   *                  applicable if the request fallsback to trigger a
   *                  fresh scan.
   * @param uint32 Measurement age filter in seconds.
   *               For Cache Request, at the time of generating the
   *               response for the request, all the measurements which
   *               are older than Current time - filter age,
   *               will be filtered out from the response.
   *               So '0' age filter could potentially
   *               return no measurements from the cache.
   *
   *               For Fresh scan Request, at the time of generating the
   *               response for the request, all the measurements which
   *               are older than Request time to WLAN driver - filter age,
   *               will be filtered out from the response.
   * @param uint32 Fallback tolerance in seconds.
   *               At the time of evaluating this request, all the
   *               requested channels should have last measurement
   *               timestamp equal to or greater than Current time -
   *               Fallback tolerance. If not, then fallback to
   *               trigger a fresh scan. Client can provide 0 if they
   *               want to trigger a fresh scan as well.
   * @param int64 Timestamp at which this request should be dropped if not
   *              processed already. Should be 0 if this is to be ignored.
   * @param bool The request will be cached and processed after the current
   *             fresh scan completes if this flag is on. Will be honoured only
   *             if there is an ongoing fresh scan at the time of receiving
   *             this request
   * @param bool Set this to true if full beacon response is required
   *             LOWIDiscoveryScanResponse carries the vector of
   *             LOWIFullBeaconScanMeasurement*, if this flag is set to true.
   */
  static LOWIDiscoveryScanRequest* createCacheFallbackRequest (
      uint32 requestId,
      eBand band, eScanType type, uint32 meas_age_filter_sec,
      uint32 fallbackToleranceSec,
      int64 timeoutTimestamp, bool bufferCacheRequest,
      bool fullBeaconScanResponse = false);

  /**
   * Helper function to create a DiscoveryScanRequest for NORMAL / FORCED_FRESH
   * Request mode. This API could be used to perform a NORMAL / FORCED_FRESH
   * discovery scan on any band.
   *
   * @param uint32 Request ID generated by the client to track the response.
   *                Response for this Request will contain the same request Id.
   * @param eBand Band in which the scan is to be performed
   * @param eScanType Type of discovery scan Active / Passive.
   * @param uint32 Measurement age filter in seconds.
   *               For Fresh scan Request, at the time of generating the
   *               response for the request, all the measurements which
   *               are older than Request time to WLAN driver - filter age,
   *               will be filtered out from the response.
   * @param int64 Timestamp at which this request should be dropped if not
   *              processed already. Should be 0 if this is to be ignored.
   * @param eRequestMode Mode of request NORMAL / FORCED_FRESH
   * @param bool Set this to true if full beacon response is required
   *             LOWIDiscoveryScanResponse carries the vector of
   *             LOWIFullBeaconScanMeasurement*, if this flag is set to true.
   *
   */
  static LOWIDiscoveryScanRequest* createFreshScanRequest (uint32 requestId,
      eBand band, eScanType type, uint32 meas_age_filter_sec,
      int64 timeoutTimestamp, eRequestMode mode, bool fullBeaconScanResponse = false);

  /**
   * Helper function to create a DiscoveryScanRequest for CACHE_ONLY Request
   * mode. This API could be used to perform CACHE_ONLY discovery scan on
   * specific channels.
   *
   * @param uint32 Request ID generated by the client to track the response.
   *                Response for this Request will contain the same request Id.
   * @param vector <LOWIChannelInfo> Vector should contain the ChannelInfo
   *               of the Channels that need to be scanned.
   *               Maximum channels supported by LOWI right now are 16 and
   *               any thing more than that is ignored.
   * @param uint32 Measurement age filter in seconds.
   *               For Cache Request, at the time of generating the
   *               response for the request, all the measurements which
   *               are older than Current time - filter age,
   *               will be filtered out from the response.
   *               So '0' age filter could potentially
   *               return no measurements from the cache.
   * @param int64 Timestamp at which this request should be dropped if not
   *              processed already. Should be 0 if this is to be ignored.
   * @param bool The request will be cached and processed after the current
   *             fresh scan completes if this flag is on. Will be honoured only
   *             if there is an ongoing fresh scan at the time of receiving this
   *             request
   */
  static LOWIDiscoveryScanRequest* createCacheOnlyRequest (uint32 requestId,
      vector <LOWIChannelInfo>& chanInfo,
      uint32 meas_age_filter_sec, int64 timeoutTimestamp,
      bool bufferCacheRequest);

  /**
   * Helper function to create a DiscoveryScanRequest for CACHE_FALLBACK
   * Request mode. This API could be used to perform CACHE_ONLY discovery
   * scan on specific channels.
   *
   * @param uint32 Request ID generated by the client to track the response.
   *                Response for this Request will contain the same request Id.
   * @param vector <LOWIChannelInfo> Vector should contain the ChannelInfo
   *               of the Channels that need to be scanned.
   *               Maximum channels supported by LOWI right now are 16 and
   *               any thing more than that is ignored.
   * @param eScanType Type of discovery scan Active / Passive. Only
   *                  applicable if the request falls back to trigger a
   *                  fresh scan.
   * @param uint32 Measurement age filter in seconds.
   *               For Cache Request, at the time of generating the
   *               response for the request, all the measurements which
   *               are older than Current time - filter age,
   *               will be filtered out from the response.
   *               So '0' age filter could potentially
   *               return no measurements from the cache.
   *
   *               For Fresh scan Request, at the time of generating the
   *               response for the request, all the measurements which
   *               are older than Request time to WLAN driver - filter age,
   *               will be filtered out from the response.
   * @param uint32 Fallback tolerance in seconds.
   *               At the time of evaluating this request, all the
   *               requested channels should have last measurement
   *               timestamp equal to or greater than Current time -
   *               Fallback tolerance. If not, then fallback to
   *               trigger a fresh scan. Client can provide 0 if they
   *               want to trigger a fresh scan as well.
   * @param int64 Timestamp at which this request should be dropped if not
   *              processed already. Should be 0 if this is to be ignored.
   * @param bool The request will be cached and processed after the current
   *             fresh scan completes if this flag is on. Will be honoured only
   *             if there is an ongoing fresh scan at the time of receiving
   *             this request
   * @param bool Set this to true, if full beacon response is required
   *             LOWIDiscoveryScanResponse carries the vector of
   *             LOWIFullBeaconScanMeasurement*, if this flag is set to true.
   *
   */
  static LOWIDiscoveryScanRequest* createCacheFallbackRequest (
      uint32 requestId,
      vector <LOWIChannelInfo>& chanInfo,
      eScanType type, uint32 meas_age_filter_sec,
      uint32 fallbackToleranceSec,
      int64 timeoutTimestamp, bool bufferCacheRequest,
      bool fullBeaconScanResponse = false);

  /**
   * Helper function to create a DiscoveryScanRequest for NORMAL / FORCED_FRESH
   * Request mode. This API could be used to perform a NORMAL / FORCED_FRESH
   * discovery scan on specific channels.
   *
   * @param uint32 Request ID generated by the client to track the response.
   *                Response for this Request will contain the same request Id.
   * @param vector <LOWIChannelInfo> Vector should contain the ChannelInfo
   *               of the Channels that need to be scanned.
   *               Maximum channels supported by LOWI right now are 16 and
   *               any thing more than that is ignored.
   * @param eScanType Type of discovery scan Active / Passive.
   * @param uint32 Measurement age filter in seconds.
   *               For Fresh scan Request, at the time of generating the
   *               response for the request, all the measurements which
   *               are older than Request time to WLAN driver - filter age,
   *               will be filtered out from the response.
   * @param int64 Timestamp at which this request should be dropped if not
   *              processed already. Should be 0 if this is to be ignored.
   * @param eRequestMode Mode of request NORMAL / FORCED_FRESH
   * @param bool Set this to true if full beacon response is required
   *             LOWIDiscoveryScanResponse carries the vector of
   *             LOWIFullBeaconScanMeasurement*, if this flag is set to true.
   *
   */
  static LOWIDiscoveryScanRequest* createFreshScanRequest (uint32 requestId,
      vector <LOWIChannelInfo>& chanInfo,
      eScanType type, uint32 meas_age_filter_sec,
      int64 timeoutTimestamp, eRequestMode mode, bool fullBeaconScanResponse = false);

  /**
   * Sets the SSIDs for Scan.
   * These SSIDs are sent out in the probe request and helps getting probe response
   * from the hidden SSIDs.
   * Note: Hidden SSIDs do not respond to broadcast probe request but they do when
   * their SSIDs are included in the probe request.
   * @param vector<LOWISsid>& Vector of LOWISsids
   */
  inline void setScanSsids (vector <LOWISsid>& ssids)
  {
    scanSsids = ssids;
  }

  /**
   * Sets the BSSIDs for Scan.
   * This triggers a unicast probe request to the specified BSSIDs.
   * Note: Although the API supports multiple BSSIDs, underlying driver may not support
   * it yet and may just support one BSSID. In that case expect the response from only the
   * first BSSID included in the vector.
   * @param vector<LOWIMacAddress>& Vector of LOWIMacAddress
   */
  inline void setScanMacAddress (vector <LOWIMacAddress>& bssids)
  {
    scanBssids = bssids;
  }

  /**
   * Returns the vector to Scan mac addresses
   */
  inline const vector<LOWIMacAddress>& getScanMacAddress () const
  {
    return scanBssids;
  }

  /**
   * Returns the vector to SSIDs
   */
  inline const vector<LOWISsid>& getScanSsids () const
  {
    return scanSsids;
  }


private:
  /**
   * Constructor
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   */
  LOWIDiscoveryScanRequest (uint32 requestId);

  /** Passive scan or Active scan*/
  eScanType         scanType;
  /** Mode of request*/
  eRequestMode      requestMode;

  /**
   * Measurement age filter in seconds.
   * For Cache Request, at the time of generating the
   *  response for the request, all the measurements which
   *  are older than Current time - filter age,
   *  will be filtered out from the response.
   *  So '0' age filter could potentially
   *  return no measurements from the cache.
   *
   * For Fresh scan Request, at the time of generating the
   *  response for the request, all the measurements which
   *  are older than Request time to WLAN driver - filter age,
   *  will be filtered out from the response.
   */
  uint32             measAgeFilterSec;
  /**
   * Fallback tolerance in seconds.
   * Only valid when eRequestMode is CACHE_FALLBACK.
   * At the time of evaluating this request, all the
   * requested channels should have last measurement
   * timestamp equal to or greater than Current time -
   * Fallback tolerance. If not, then fallback to
   * trigger a fresh scan. Client can provide 0 if they
   * want to trigger a fresh scan as well.
   */
  uint32             fallbackToleranceSec;
  /** RF band to scan.*/
  eBand             band;
  /**
   * Dynamic array containing the ChannelInfo to be scanned.
   * Number of entries in the vector should not be more than
   * MAX_CHAN_INFO_SIZE as that's the max LOWI supports as of
   * now. Any ChannelInfo more than MAX_CHAN_INFO_SIZE will be
   * ignored.
   */
  vector <LOWIChannelInfo> chanInfo;
  /** Absolute timestamp on which the request will be dropped if not processed
   * value should be 0 if the timeoutTimestamp is not valid.
   */
  int64             timeoutTimestamp;
  /** Set this to true if the cache request has to be buffered until the
   * existing transaction is finished.
   * Will be ignored if there is no ongoing transaction.
   * Will be ignored for FRESH_ONLY requestMode
   * This can be used to get the latest results included in the cache request.
   */
  bool           bufferCacheRequest;

  /** Set this to true if full beacon response is expected
   * LOWIDiscoveryScanResponse carries the vector of LOWIFullScanMeasurement*
   * if this flag is set to true.
   */
  bool           fullBeaconScanResponse;

  vector <LOWISsid> scanSsids;
  vector <LOWIMacAddress> scanBssids;
  friend class LOWIUtils;
};

/**
 * Defines the info for a Channel
 */
class LOWIChannelInfo
{
private:
  /** Frequency in Mhz*/
  uint32 frequency;
public:
  LOWIChannelInfo ();
  /**
   * Constructor
   * @param uint32 frequency of the channel
   */
  LOWIChannelInfo (uint32 freq);

  /**
   * Constructor
   * @param uint32 Channel number
   * @param LOWIDiscoveryScanRequest::eBand Band of the channel
   */
  LOWIChannelInfo (uint32 channel, LOWIDiscoveryScanRequest::eBand band);

  ~LOWIChannelInfo ();
  /**
   * Returns the band associated with the channel.
   * @return Band for the channel.
   */
  LOWIDiscoveryScanRequest::eBand getBand () const;
  /**
   * Returns the Frequency associated with the channel.
   * @return Frequency of the channel
   */
  uint32 getFrequency () const;
  /**
   * Returns the Channel number for the Channel Info.
   * Channel number corresponds to the Band
   *
   * @return Channel Number
   */
  uint32 getChannel () const;
};


///////////////////////////
// Ranging scan Request
///////////////////////////

/** Defines available type of Wifi Nodes*/
enum eNodeType
{
  NODE_TYPE_UNKNOWN = 0,
  ACCESS_POINT, // access point
  PEER_DEVICE,  // device which is part of a p2p group
  NAN_DEVICE,   // device which is part of a NAN
  STA_DEVICE,   // stand alone station (as in ad-hoc BSS)
  SOFT_AP       // Node in Hotspot mode
};
/** Defines supported RTT types for Ranging scan request */
enum eRttType
{
  RTT1_RANGING = 0,    /* Ranging with no Multipath correction */
  RTT2_RANGING,        /* Ranging with Multipath correction */
  RTT3_RANGING,        /* Two-sided Ranging as defined in 802.11mc spec */
  BEST_EFFORT_RANGING  /* One of the above, which ever the peer supports */
};

/** Defines RTT report types for Ranging scan */
enum eRttReportType
{
  RTT_REPORT_1_FRAME_CFR = 0,  /* Responses sent on a per frame basis with CFR capture */
  RTT_REPORT_1_FRAME_NO_CFR,   /* Responses sent on a per frame basis without CFR captiure */
  RTT_REPORT_AGGREGATE,        /* Single responses containing results for all requested APs and frames*/
  RTT_REPORT_BSSID,             /* Responses sent on a per BSSID destination basis */
  RTT_REPORT_1_FRAME_CFR_CIR    /* Responses sent on a per frame basis with CFR capture */
};

/** Defines the Bandwidth for Ranging scan */
//! Note : update eRangingBandwidth enums in all defined include files
//! FYI - Present in lowi_tlv.h and lowi_request.h
enum eRangingBandwidth
{
  BW_20MHZ = 0,
  BW_40MHZ,
  BW_80MHZ,
  BW_160MHZ,
  BW_MAX
};

/** Defines the Preamble for Ranging scan */
enum eRangingPreamble
{
  RTT_PREAMBLE_LEGACY = 0,
  RTT_PREAMBLE_HT,
  RTT_PREAMBLE_VHT,
  RTT_PREAMBLE_MAX
};

/** This enum defines the Phy mode */
enum eLOWIPhyMode
{
  LOWI_PHY_MODE_UNKNOWN       = -1,
  LOWI_PHY_MODE_11A           = 0,  /* 11a Mode */
  LOWI_PHY_MODE_11G           = 1,  /* 11b/g Mode */
  LOWI_PHY_MODE_11B           = 2,  /* 11b Mode */
  LOWI_PHY_MODE_11GONLY       = 3,  /* 11g only Mode */
  LOWI_PHY_MODE_11NA_HT20     = 4,  /* 11na HT20 mode */
  LOWI_PHY_MODE_11NG_HT20     = 5,  /* 11ng HT20 mode */
  LOWI_PHY_MODE_11NA_HT40     = 6,  /* 11na HT40 mode */
  LOWI_PHY_MODE_11NG_HT40     = 7,  /* 11ng HT40 mode */
  LOWI_PHY_MODE_11AC_VHT20    = 8,  /* 5G 11ac VHT20 mode */
  LOWI_PHY_MODE_11AC_VHT40    = 9,  /* 5G 11ac VHT40 mode */
  LOWI_PHY_MODE_11AC_VHT80    = 10, /* 5G 11ac VHT80 mode */
  LOWI_PHY_MODE_11AC_VHT20_2G = 11, /* 2G 11ac VHT20 mode */
  LOWI_PHY_MODE_11AC_VHT40_2G = 12, /* 2G 11ac VHT40 mode */
  LOWI_PHY_MODE_11AC_VHT80_2G = 13, /* 2G 11ac VHT80 mode */
  LOWI_PHY_MODE_11AC_VHT80_80 = 14, /* 5G 11ac VHT80_80 mode */
  LOWI_PHY_MODE_11AC_VHT160   = 15, /* 5G 11ac VHT160 mode */
  LOWI_PHY_MODE_11AX_HE20     = 16, /* 5G 11ax HE20 mode */
  LOWI_PHY_MODE_11AX_HE40     = 17, /* 5G 11ax HE40 mode */
  LOWI_PHY_MODE_11AX_HE80     = 18, /* 5G 11ax HE80 mode */
  LOWI_PHY_MODE_11AX_HE80_80  = 19, /* 5G 11ax HE80_80 mode */
  LOWI_PHY_MODE_11AX_HE160    = 20, /* 5G 11ax HE160 mode */
  LOWI_PHY_MODE_11AX_HE20_2G  = 21, /* 2G 11ax HE20 mode */
  LOWI_PHY_MODE_11AX_HE40_2G  = 22, /* 2G 11ax HE40 mode */
  LOWI_PHY_MODE_11AX_HE80_2G  = 23, /* 2G 11ax HE80 mode */

  LOWI_PHY_MODE_MAX           = LOWI_PHY_MODE_11AX_HE80_2G
};

/**
 * Defines the information for a Wifi Node
 */
struct LOWINodeInfo
{
  /** MacId of the Node*/
  LOWIMacAddress bssid;
  /** Frequency in Mhz, which the node is transmitting*/
  uint32 frequency;
  /** Frequency of the center of total BW */
  uint32 band_center_freq1;
  /** Frequency of the center of the second 80MHZ Lobe if BW is
   *  80MHz + 80MHz */
  uint32 band_center_freq2;

  /** Either PEER_DEVICE or ACCESS_POINT*/
  eNodeType nodeType;
  /* Spoof MacId needed for peer device ranging.
   * Only valid if nodeType is PEER_DEVICE*/
  LOWIMacAddress spoofMacId;

  /** The Type Of RTT to be performed */
  eRttType rttType;

  /** Bandwidth to be used*/
  eRangingBandwidth bandwidth;

  /**********************************************************************************
   * FTMR Related fields
   * Bit 0: ASAP = 0/1 - This field indicates whether to start FTM session
   *                     immediately or not. ASAP = 1 means immediate FTM session
   * Bit 1: LCI Req = True/False   - Request Location Configuration Information report
   * Bit 2: Location Civic Req = True/False
   * Bit 3: PTSF no preference -- Used in iFTMR to indicate validity of PTSF
   *        timer field in the frame
   * Bit 4: AoA measurement: 1: perform AoA measurement, 0: do not perform AoA measurement
   * Bit 5: whether to use legacy acks or high speed acks in FTM transactions
   *        0: default, use high speed acks with QTI peers
   *        1: use only legacy acks regardless of peer
   * Bits 6-7: Reserved
   * Bits 8-11: Number of Bursts Exponent - This field indicates the number of
   *            bursts of FTM bursts to perform. The numbe rof bursts is indidcated
   *            as Num of Bursts = 2^ Burst exponent. This format is used to be
   *            consistent with the format in the 802.11mc spec.
   * Bits 12-15: Burst Duration - Duration of each FTM burst, defined by the
   *             following table:
   *                                   Value               Burst Duration
   *                                    0-1                   Reserved
   *                                     2                      250us
   *                                     3                      500us
   *                                     4                        1ms
   *                                     5                        2ms
   *                                     6                        4ms
   *                                     7                        8ms
   *                                     8                       16ms
   *                                     9                       32ms
   *                                     10                      64ms
   *                                     11                     128ms
   *                                   12-14                  Reserved
   *                                     15                 No Preference
   *
   * Bits 16-31: Burst Period (time between Bursts) Units: 100ms (0 - no preference)
   *********************************************************************************/
  #define FTM_ASAP_BIT               0
  #define FTM_LCI_BIT                1
  #define FTM_LOC_CIVIC_BIT          2
  #define FTM_PTSF_TIMER_NO_PREF     3
  #define FTM_AOA_MEASUREMENT        4
  #define FTM_LEG_ACK_ONLY           5
  #define FTM_QCA_PEER               6
  #define FTM_BURSTS_EXP_START_BIT   8
  #define FTM_BURSTS_EXP_MASK        0xF
  #define FTM_BURST_DUR_START_BIT    12
  #define FTM_BURST_DUR_MASK         0xF
  #define FTM_BURST_PERIOD_START_BIT 16
  #define FTM_BURST_PERIOD_MASK      0xFFFF

  #define FTM_SET_ASAP(x) (x = (x | (1 << FTM_ASAP_BIT)))
  #define FTM_CLEAR_ASAP(x) (x = (x & ~(1 << FTM_ASAP_BIT)))
  #define FTM_GET_ASAP(x) ((x & (1 << FTM_ASAP_BIT)) >> FTM_ASAP_BIT)

  #define FTM_SET_LCI_REQ(x) (x = (x | (1 << FTM_LCI_BIT)))
  #define FTM_CLEAR_LCI_REQ(x) (x = (x & ~(1 << FTM_LCI_BIT)))
  #define FTM_GET_LCI_REQ(x) ((x & (1 << FTM_LCI_BIT)) >> FTM_LCI_BIT)

  #define FTM_SET_LOC_CIVIC_REQ(x) (x = (x | (1 << FTM_LOC_CIVIC_BIT)))
  #define FTM_CLEAR_LOC_CIVIC_REQ(x) (x = (x & ~(1 << FTM_LOC_CIVIC_BIT)))
  #define FTM_GET_LOC_CIVIC_REQ(x) ((x & (1 << FTM_LOC_CIVIC_BIT)) >> FTM_LOC_CIVIC_BIT)

  #define FTM_SET_PTSF_TIMER_NO_PREF(x) (x = (x | (1 << FTM_PTSF_TIMER_NO_PREF)))
  #define FTM_CLEAR_PTSF_TIMER_NO_PREF(x) (x = (x & ~(1 << FTM_PTSF_TIMER_NO_PREF)))
  #define FTM_GET_PTSF_TIMER_NO_PREF(x) ((x & (1 << FTM_PTSF_TIMER_NO_PREF)) >> FTM_PTSF_TIMER_NO_PREF)

  #define FTM_SET_AOA_MEASUREMENT(x) (x = (x | (1 << FTM_AOA_MEASUREMENT)))
  #define FTM_CLEAR_AOA_MEASUREMENT(x) (x = (x & ~(1 << FTM_AOA_MEASUREMENT)))
  #define FTM_GET_AOA_MEASUREMENT(x) ((x & (1 << FTM_AOA_MEASUREMENT)) >> FTM_AOA_MEASUREMENT)

  #define FTM_SET_BURSTS_EXP(x,y) (x = ((x & ~(FTM_BURSTS_EXP_MASK << FTM_BURSTS_EXP_START_BIT)) | (y << FTM_BURSTS_EXP_START_BIT)))
  #define FTM_GET_BURSTS_EXP(x)   ((x & (FTM_BURSTS_EXP_MASK << FTM_BURSTS_EXP_START_BIT)) >> FTM_BURSTS_EXP_START_BIT)

  #define FTM_SET_BURST_DUR(x,y) (x = ((x & ~(FTM_BURST_DUR_MASK << FTM_BURST_DUR_START_BIT)) | (y << FTM_BURST_DUR_START_BIT)))
  #define FTM_GET_BURST_DUR(x) ((x & (FTM_BURST_DUR_MASK << FTM_BURST_DUR_START_BIT)) >> FTM_BURST_DUR_START_BIT)

  #define FTM_SET_BURST_PERIOD(x,y) (x = ((x & ~(FTM_BURST_PERIOD_MASK << FTM_BURST_PERIOD_START_BIT)) | (y << FTM_BURST_PERIOD_START_BIT)))
  #define FTM_GET_BURST_PERIOD(x) ((x & (FTM_BURST_PERIOD_MASK << FTM_BURST_PERIOD_START_BIT)) >> FTM_BURST_PERIOD_START_BIT)

  #define FTM_SET_LEG_ACK_ONLY(x) (x = (x | (1 << FTM_LEG_ACK_ONLY)))
  #define FTM_CLEAR_LEG_ACK_ONLY(x) (x = (x & ~(1 << FTM_LEG_ACK_ONLY)))
  #define FTM_GET_LEG_ACK_ONLY(x) ((x & (1 << FTM_LEG_ACK_ONLY)) >> FTM_LEG_ACK_ONLY)

  #define FTM_SET_QCA_PEER(x) (x = (x | (1 << FTM_QCA_PEER)))
  #define FTM_CLEAR_QCA_PEER(x) (x = (x & ~(1 << FTM_QCA_PEER)))
  #define FTM_GET_QCA_PEER(x) ((x & (1 << FTM_QCA_PEER)) >> FTM_QCA_PEER)
  uint32 ftmRangingParameters;

  /** Preamable to be used*/
  eRangingPreamble preamble;

  /**
   * number of packets for each RTT measurement
   * NOTE: maximum of 5 per RTT measurement
   */
  uint8 num_pkts_per_meas;

  /**
   * maximum number of times a measurement should be retried if the measurement
   * fails (i.e. it yields no results)
   */
  uint8 num_retries_per_meas;

  /**
   * The following defines are used to indicate whether
   * LOWI will use parameters from the LOWI Cache or not.
   */
  #define LOWI_NO_PARAMS_FROM_CACHE     0xFFFFFFFF
  #define LOWI_USE_PARAMS_FROM_CACHE    0

  /**
   * Defines what parameters in the request will be read
   * from Cache by LOWI
   */
  uint32 paramControl;

  /** phymode to be used */
  eLOWIPhyMode phyMode;
  /* RTT functional defines start here */
#define RTT_REPORT_PER_FRAME_WITH_CFR 0
#define RTT_REPORT_PER_FRAME_NO_CFR   1
#define RTT_AGGREGATE_REPORT_NON_CFR  2
#define RTT_REPORT_PER_BURST_NON_CFR  3
#define RTT_REPORT_PER_FRAME_WITH_CFR_CIR 4


  /** report Type */
  uint32 reportType;

  /** interface */
  std::string interface;
public:
  /**
   * Constructor
   */
  LOWINodeInfo ();

  /**
   * Validates the NodeInfo
   */
  void validate ();
};

/**
 * Defines the information for a Wifi Node and allows for periodic measurements
 */
struct LOWIPeriodicNodeInfo : public LOWINodeInfo
{
  /**
   * indicates whether request for this WiFi node is periodic or one-shot
   * 0: one-shot, non-zero: periodic
   */
  uint8 periodic;

  /** for periodic requests, this indicates the periodicity of the
   *  measurements (i.e. every 500ms, or every 800ms, etc
   */
  uint32 meas_period;

  /**
   *  for periodic requests, this indicates the number of measurements to be
   *  carried out at the "period" given above
   */
  uint32 num_measurements;

public:

  /**
   * Constructor
   */
  LOWIPeriodicNodeInfo();

  /**
   * This function checks the parameters for every wifi node in the request and
   * ensures that they are correct. If not, it assigns a valid default parameter
   * so the request can be serviced.
   */
  void validateParams();
};

/**
 * Class to make a Ranging scan request.
 */
class LOWIRangingScanRequest: public LOWIRequest
{
private:
  /**
   * Dynamic array containing the wifi Node Info to be scanned.
   * Currently LOWI only supports 16 wifi nodes to be scanned
   * with Ranging scan. Any thing more than 16 will be ignored.
   */
  vector <LOWINodeInfo> nodeInfo;

  /** Absolute timestamp on which the request will be dropped if not processed
   * value should be 0 if the timeoutTimestamp is not valid.
   */
  int64             timeoutTimestamp;

  /** The Type Of RTT Report the FW should provide */
  eRttReportType rttReportType;

public:

  /**
   * Returns the Dynamic array containing the LOWINodeInfo
   * @return Dynamic array containing the LOWINodeInfo
   */
  vector <LOWINodeInfo> & getNodes ();

  /**
   * Sets the time-out timestamp for the request
   * @return void
   */
  void setTimeoutTimestamp(int64 timestamp);

  /**
   * Returns the timestamp at which the request expires
   * @return timestamp at which the request expires
   */
  int64 getTimeoutTimestamp () const;

  /**
   * Sets the RTT report type for the request
   * @return void
   */
  void setReportType(eRttReportType report_type);

  /**
   * Returns the RTT Report Type for this Request
   * @return eRttReportType RTT Report type
   */
  eRttReportType getReportType() const;

  /**
   * Constructor
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   * @param vector<LOWINodeInfo> Dynamic array containing wifi nodes
   *                           that need to be scanned.
   * @param int64 Timestamp at which the request will be dropped if not
   *              processed already. Should be 0 if this is to be ignored.
   */
  LOWIRangingScanRequest (uint32 requestId, vector <LOWINodeInfo>& node_info,
      int64 timestamp);
  /** Destructor*/
  virtual ~LOWIRangingScanRequest ();

  /**
   * Returns the request type
   * @return eRequestType type of the Request
   */
  virtual eRequestType getRequestType () const;
};

/**
 * Class to make a Request for Async discovery scan results.
*/
class LOWIAsyncDiscoveryScanResultRequest : public LOWIRequest
{
private:
  /**
   * Number of seconds for which the request should be active.
   * Request will be dropped after this time.
   * requestExpirySec can not be more than
   * ASYNC_DISCOVERY_REQ_VALIDITY_PERIOD_SEC
   */
  uint32             requestExpirySec;

  /**
   * Internally calculated based on the time the request
   * was received and the requested expiry
   */
  int64              timeoutTimestamp;

public:
  /**
   * Constructor
   * A client registers this request to receive the discovery
   * scan results as and when they are available.
   * LOWI provides the async results to the client for as long
   * as the request is valid or for a max period
   * (ASYNC_DISCOVERY_REQ_VALIDITY_PERIOD_SEC), after which it
   * drops the request assuming that the client is no longer
   * interested in the scan results. There is no indication to
   * the client when this happens. If the client is interested
   * in listening for the async scan results, it should keep
   * refreshing it's registration by issung the same request
   * before the expiry of previous request.
   * Issuing the same request again even when it's not yet expired,
   * just refreshes the request and LOWI resets the expiry timer
   * for the request.
   * If the client is no longer interested in listening for the
   * async results, it can refresh this request with 0 timeout value.
   *
   * Client will not get the results / response to this request
   * if there was a discovery scan result available but was
   * triggered by a discovery scan request from the same client.
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   * @param uint32 Number of seconds for which the request should
   *               be active. requestExpirySec can not be more than
   *               ASYNC_DISCOVERY_REQ_VALIDITY_PERIOD_SEC
   */
  LOWIAsyncDiscoveryScanResultRequest (uint32 requestId,
      uint32 request_timer_sec);

  /**
   * Returns the expiry time of the Request.
   * @return uint32 Request expiry time
   */
  uint32 getRequestExpiryTime ();

  /**
   * Returns the request type
   * @return eRequestType type of the Request
   */
  virtual eRequestType getRequestType () const;

  /**
   * Returns the Timeout timestamp
   * @return int64 Timeout timestamp
   */
  int64 getTimeoutTimestamp () const;

  /**
   * Sets the timeout timestamp
   * Client does not have to call this API.
   * Calling this API from client side does not affect
   * the internal usage.
   * This is internally calculated based on the
   * request timer in the constructor.
   * @param int64 Timeout timestamp
   */
  void setTimeoutTimestamp (int64 timeout);

  /** Destructor*/
  virtual ~LOWIAsyncDiscoveryScanResultRequest ()
  {
    log_verbose(TAG, "~LOWIAsyncDiscoveryScanResultRequest");
  }
};


/**
 * Class to make a periodic ranging scan request.
 */
  class LOWIPeriodicRangingScanRequest: public LOWIRangingScanRequest
{
private:
  /**
   * Dynamic array containing the wifi Node Info to be scanned.
   * Currently LOWI only supports 16 wifi nodes to be scanned
   * with Ranging scan. Any thing more than 16 will be ignored.
   */
  vector <LOWIPeriodicNodeInfo> nodeInfo;

protected:
  /**
   * Use the empty vector "nodes" to pass to the LOWIRangingScanRequest
   * constructor when creating a LOWIPeriodicRangingScanRequest type. That way,
   * LOWIPeriodicRangingScanRequest types can be created using the
   * already existing constructors.
   */
  static vector<LOWINodeInfo> emptyNodeInfo;


public:
  /**
   * Returns the Dynamic array containing the LOWINodeInfo
   * @return Dynamic array containing the LOWINodeInfo
   */
  vector <LOWIPeriodicNodeInfo> & getNodes ();

  /**
   * Constructor
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   * @param vector<LOWIPeriodicNodeInfo> Dynamic array containing wifi nodes
   *                           that need to be scanned.
   * @param int64 Timestamp at which the request will be dropped if not
   *              processed already. Should be 0 if this is to be ignored.
   */
  LOWIPeriodicRangingScanRequest (uint32 requestId,
                                  vector <LOWIPeriodicNodeInfo>& node_info,
                                  int64 timestamp);
  /** Destructor*/
  virtual ~LOWIPeriodicRangingScanRequest ();

  /**
   * Returns the request type
   * @return eRequestType type of the Request
   */
  virtual eRequestType getRequestType () const;
};

/**
 * This class cancels RTT measurements
 */
class LOWICancelRangingScanRequest: public LOWIRequest
{
private:
  /**
   * Dynamic array containing the wifi node bssids to be
   * cancelled
   */
  vector <LOWIMacAddress> bssidInfo;

public:
  /**
   * Constructor
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   * @param vector<LOWIMacAddress> Dynamic array containing wifi nodes
   *                           that need to be cancelled.
   */
  LOWICancelRangingScanRequest (uint32 requestId,
                                vector<LOWIMacAddress> & bssid_info);

  /** Destructor*/
  virtual ~LOWICancelRangingScanRequest();

  /**
   * Returns the Dynamic array containing the BSSIDs of the wifi nodes to cancel
   * @return Dynamic array containing the BSSIDs
   */
  vector <LOWIMacAddress> & getBssids();

  /**
   * Returns the request type
   * @return eRequestType type of the Request
   */
  virtual eRequestType getRequestType() const;
};

enum eLowiMotionPattern
{
  LOWI_MOTION_NOT_EXPECTED = 0, // Not expected to change location
  LOWI_MOTION_EXPECTED     = 1, // Expected to change location
  LOWI_MOTION_UNKNOWN      = 2  // Movement pattern unknown
};

/** LCI Information to be injected into reponder's FW */
struct LOWILciInformation
{
  int64 latitude;              // latitude in degrees * 2^25 , 2's complement
  int64 longitude;             // latitude in degrees * 2^25 , 2's complement
  int32 altitude;              // Altitude in units of 1/256 m
  uint8 latitude_unc;          // As defined in Section 2.3.2 of IETF RFC 6225
  uint8 longitude_unc;         // As defined in Section 2.3.2 of IETF RFC 6225
  uint8 altitude_unc;          // As defined in Section 2.4.5 from IETF RFC 6225:

  //Following element for configuring the Z subelement
  eLowiMotionPattern motion_pattern;
  int32 floor;                 // floor # if known. 80000000 if unknown.
  int32 height_above_floor;    // in units of 1/64 m
  int32 height_unc;            // in units of 1/64 m

  /** Constructor */
  LOWILciInformation();
};

/** Set LCI location information */
class LOWISetLCILocationInformation : public LOWIRequest
{
private:
  LOWILciInformation mLciInfo;
  uint32 mUsageRules;
public:

  /**
   * Constructor
   * lciInfo: lciInformation to set
   */
  LOWISetLCILocationInformation(uint32 requestID, LOWILciInformation &lciInfo, uint32 &usageRules);

  /** Destructor */
  ~LOWISetLCILocationInformation();

  /** Returns LCI information injected into device */
  const LOWILciInformation& getLciParams() const;

  /** Returns the usage rules variable */
  uint32 getUsageRules() const;

  /**
   * Returns the request type
   * @return eRequestType type of the Request
   */
  virtual eRequestType getRequestType() const;
};


/** LCR Information to be injected into reponder's FW */
struct LOWILcrInformation
{
  uint8  country_code[LOWI_COUNTRY_CODE_LEN]; // country code
  uint32 length;                              // length of the info field
  int8   civic_info[CIVIC_INFO_LEN];          // Civic info to be copied in FTM frame

  /** Constructor */
  LOWILcrInformation();
};

/** Set LCR location information */
class LOWISetLCRLocationInformation : public LOWIRequest
{
private:
  LOWILcrInformation mLcrInfo;
public:

  /**
   * Constructor
   * lcrInfo: lcrInformation to set
   */
  LOWISetLCRLocationInformation(uint32 requestID, LOWILcrInformation &lcrInfo);

  /** Destructor */
  ~LOWISetLCRLocationInformation();

  /** Returns LCR information injected into device */
  const LOWILcrInformation& getLcrParams() const;

  /**
   * Returns the request type
   * @return eRequestType type of the Request
   */
  virtual eRequestType getRequestType() const;
};


///////////////////////////
// Neighbor Report Request
///////////////////////////
/**
 * Neighbor Report Request
 *  Used by STA to request a neighbor report from AP that STA is associated with
 */
class LOWINeighborReportRequest : public LOWIRequest
{
public:
  /**
   * Constructor
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   */
  LOWINeighborReportRequest (uint32 requestId);
  /** Destructor*/
  virtual ~LOWINeighborReportRequest ();

  /**
   * Returns the request type
   * @return eRequestType type of request
   */
  virtual eRequestType getRequestType () const;
};

///////////////////////////
// WLAN State Query Request
///////////////////////////

/**
 * Valid interfaces for which the client wants to get events notifications
 */
enum eLowiWlanInterface
{
  LOWI_DEV_STA = 0, /**<  WLAN device is in Station mode  */
  LOWI_DEV_P2P_CLI = 1, /**<  WLAN device is in P2P Client mode  */
  LOWI_WLAN_DEV_ANY = 2 /**<  WLAN device is in any mode */
};

/**
 * Request to query current WLAN state.
 */
class LOWIWLANStateQueryRequest : public LOWIRequest
{
private:
  eLowiWlanInterface interface;
public:
  /**
   * Client uses this request to query the wlan state
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   * @param eLowiWlanInterface interface for which the client wants
   *                     to get the events (wlan0 / p2p0)
   *                     Default interface is wlan0 (STA)
   */
  LOWIWLANStateQueryRequest (uint32 requestId,
      eLowiWlanInterface iface = LOWI_DEV_STA)
  : LOWIRequest (requestId), interface (iface)
  {
  }

  /**
   * Returns the request type
   * @return eRequestType type of the Request
   */
  virtual eRequestType getRequestType () const
  {
    return LOWI_WLAN_STATE_QUERY_REQUEST;
  }

  /**
   * Returns the interface
   * @return eLowiWlanInterface Interface
   */
  virtual eLowiWlanInterface getInterface () const
  {
    return interface;
  }

};

///////////////////////////
//LCI Request
///////////////////////////
/**
 * LCI Request
 * Used by STA to request LCI from remote STA
 */
class LOWISendLCIRequest : public LOWIRequest
{
private:
  LOWIMacAddress mBssid;
public:
  /**
   * Constructor
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   * @param LOWIMacAddress bssid of target STA
   */
  LOWISendLCIRequest(uint32 requestId, LOWIMacAddress bssid);
  /** Destructor*/
  virtual ~LOWISendLCIRequest()
  {
    log_verbose(TAG, "~LOWISendLCIRequest");
  }

  /**
   * Returns the bssid for this request
   * @return LOWIMacAddress &
   */
  const LOWIMacAddress& getBssid() const
  {
    return mBssid;
  }

  /**
   * Returns the request type
   * @return eRequestType type of request
   */
  virtual eRequestType getRequestType() const
  {
    return SEND_LCI_REQUEST;
  }
};

///////////////////////////
// FTM Ranging Request
///////////////////////////
struct LOWIFTMRRNodeInfo
{
  LOWIMacAddress bssid;
  uint32 bssidInfo;           // used to help determine neighbor service set transition candidates
  uint8 operatingClass;       // Indicates the channel set of the AP indicated by this BSSID
  uint8 phyType;              // PHY type of the AP indicated by this BSSID
  uint8 ch;
  uint8 center_Ch1;
  uint8 center_Ch2;
  eRangingBandwidth bandwidth;

  LOWIFTMRRNodeInfo(LOWIMacAddress bssid = LOWIMacAddress(), uint32 bssidInfo = 0, uint8 operatingClass = 0,
                    uint8 phyType = 0, uint8 ch = 0,  uint8 center_Ch1 = 0, uint8 center_Ch2 = 0,
                    eRangingBandwidth bandwidth = BW_20MHZ);

};
/**
 * FTM Ranging Request
 *  Used by STA to request FTM ranging from remote STA
 */
class LOWIFTMRangingRequest : public LOWIRequest
{
private:
  LOWIMacAddress mDestBssid;
  uint16 mRandInterval;
  vector<LOWIFTMRRNodeInfo> mNodes;

public:
  /**
   * Constructor
   * @param uint32 Request id generated by the client
   *        This will be echoed back in the corresponding response.
   */
  LOWIFTMRangingRequest(uint32 requestId, LOWIMacAddress bssid,
                        uint16 randInterval, vector<LOWIFTMRRNodeInfo>& nodes);

  /** Destructor*/
  virtual ~LOWIFTMRangingRequest()
  {
    log_verbose(TAG, "~LOWIFTMRangingRequest");
  }

  /**
   * Returns the bssid for this request
   * @return LOWIMacAddress &
   */
  const LOWIMacAddress& getBSSID() const
  {
    return mDestBssid;
  }

  /**
   * Returns the vector of nodes for this request
   * @return vector<LOWIFTMRRNodeInfo> &
   */
  const vector<LOWIFTMRRNodeInfo>& getNodes() const
  {
    return mNodes;
  }

  /**
   * Returns randamization interval for this request
   * @return uint16
   */
  uint16 getRandInter() const
  {
    return mRandInterval;
  }

  /**
   * Returns the request type
   * @return eRequestType type of request
   */
  virtual eRequestType getRequestType() const
  {
    return FTM_RANGE_REQ;
  }
};

///////////////////////////
// LOWI config Request
///////////////////////////

/**
 * Different LOWI Variants for which logging
 * could be configured.
 */
enum eLOWIVariant
{
  LOWI_AP = 0,
  LOWI_LP,
  LOWI_AP_LP_BOTH
};


/**
 * Structure to hold the tag name and the corresponding
 * log level.
 */
struct LOWILogInfo
{
  const char* tag;
  uint8 log_level;
  LOWILogInfo (){};
  LOWILogInfo (const char* tagString, uint8 loglevel)
  {
    tag = tagString;
    log_level = loglevel;
  }
};

/**
 * Config Request
 */
class LOWIConfigRequest: public LOWIRequest
{
public:
  /** Defines the mode of config Request*/
  enum eConfigRequestMode
  {
    UNKNOWN_MODE,
    /** Request to perform a log config. The request will trigger a Request
     * to configure the log level for different modules (tags). */
    LOG_CONFIG,
    /** Request to LOWI server to exit */
    LOWI_EXIT
  };

  /**
   * Returns the request mode
   * @return eConfigRequestMode mode of request
   */
  eConfigRequestMode getConfigRequestMode () const
  {
    return mConfigRequestMode;
  }

  /**
   * Returns the request type
   * @return eRequestType type of request
   */

  eRequestType getRequestType () const
  {
    return LOWI_CONFIG_REQUEST;
  }

  /**
   * Returns the vector of log info for this request
   * @return vector<LOWILogInfo> &
   */
  vector<LOWILogInfo>& getLogInfo()
  {
    return mLogInfo;
  }

  /**
   * Returns LOWI Processor to be configured for this request
   * @return eLOWIVariant
   */
  eLOWIVariant getLowiVariant() const
  {
    return mLowiVariant;
  }

  /**
   * Returns global log level to be configured for this request
   * @return uint8
   */
  uint8 getGlobalLogLevel() const
  {
    return mLowiGlobalLogLevel;
  }

  /**
   * Returns global log level flag
   * if true, consider the global log level other wise
   * ignore it.
   * @return bool
   */
  bool getGlobalLogFlag() const
  {
    return mLowiGlobalLogFlag;
  }

  /** Destructor*/
  virtual ~LOWIConfigRequest ()
  {
    log_verbose (TAG, "~LOWIConfigRequest");
  }

  /**
   * Constructor
   * @param uint32 Request id generated by the client
   * @param eConfigRequestMode Request mode for this request
   */
  LOWIConfigRequest (uint32 requestId, eConfigRequestMode reqMode);
  /** vector to hold tag and log level */
  vector<LOWILogInfo> mLogInfo;
  /** Processor for which log level need to be set */
  eLOWIVariant mLowiVariant;
  /** Global log level */
  uint8 mLowiGlobalLogLevel;
  /** Global log flag, if disabled global log level will be ignored */
  bool mLowiGlobalLogFlag;
  /** Mode of request*/
  eConfigRequestMode      mConfigRequestMode;
};
}// namespace qc_loc_fw

#endif //#ifndef __LOWI_REQUEST_H__
