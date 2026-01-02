#ifndef __LOWI_SCAN_MEASUREMENT_H__
#define __LOWI_SCAN_MEASUREMENT_H__

/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

        LOWI Scan Measurement Interface Header file

GENERAL DESCRIPTION
  This file contains the structure definitions and function prototypes for
  LOWIScanMeasurement

  Copyright (c) 2012-2013,2016-2019 Qualcomm Technologies, Inc.
  All Rights Reserved.
  Confidential and Proprietary - Qualcomm Technologies, Inc.

  (c) 2012-2013 Qualcomm Atheros, Inc.
  All Rights Reserved.
  Qualcomm Atheros Confidential and Proprietary.

=============================================================================*/
#include <inc/lowi_request.h>
#include <inc/lowi_ssid.h>
#include <inc/lowi_mac_address.h>

namespace qc_loc_fw
{

/**
 * This struct defines the MSAP related data.
 */
struct LOWIMsapInfo
{
  uint8  protocolVersion;
  uint32 venueHash;
  uint8  serverIdx;
};

/** Beacon information element used to store LCI/LCR data */
struct LOWILocationIE
{
  uint8 id;       // element identifier
  uint8 len;      // number of bytes to follow
  uint8 *locData; // data blob
public:
  /** Constructor  & Copy constructor */
  LOWILocationIE();
  LOWILocationIE(const LOWILocationIE& rhs);
  /** Destructor */
  ~LOWILocationIE();

  /**
   * Prints Location IE
   */
  void printLocationIE ();
};

/** Contains the AoA result to be provided to clients */
class LOWIAoAResult
{
public:
  /** target's azimuth */
  double mAzimuth;
  /** target's elevation */
  double mElevation;

  /** Constructor */
  LOWIAoAResult()
  {
    mAzimuth   = LOWI_AZIMUTH_DEFAULT;
    mElevation = LOWI_ELEVATION_DEFAULT;
  }

  /** Copy constructor */
  LOWIAoAResult(LOWIAoAResult const &rhs)
  : mAzimuth(rhs.mAzimuth), mElevation(rhs.mElevation) { }

  /** Destructor */
  ~LOWIAoAResult() { }
};

/**
 * This struct defines Measurement Info per Wifi Node. It contains
 * measurement information for different types of scans. At any
 * given time only some values are valid for the scan type being
 * used.
 * For a DiscoveryScan only rssi and rssi_timestamp are valid fields
 * For a Ranging scan rtt, rtt_timestamp and rssi are valid fields.
 * 5/30/2014: for ranging scans that use RTT3 additional parameters
 * have been added: preamble, bw, mcsIdx and bitrate
 * 5/31/2015: for bgscans results coming from the LP, we're adding
 * two more parameters: scan id and flags.
 */
struct LOWICFRCIRInfo
{

 uint32 len;  // number of bytes to follow
 uint8 *data;
 public:
  /** Constructor  & Copy constructor */
  LOWICFRCIRInfo();
  LOWICFRCIRInfo(const LOWICFRCIRInfo& rhs);
  /** Destructor */
  ~LOWICFRCIRInfo();

};
struct LOWIMeasurementInfo
{
  /**
   * Measurement age msec
   * In units of 1 msec, -1 means info not available
   */
  int32         meas_age;
  /** RTT - value in nsec. 0 is considered to be invalid rtt
   * value. rtt will be deprecated soon rtt_ps should be used
   * instead globally by all */
  int32         rtt;
  /** RTT - value in pico sec. 0 is considered to be invalid rtt*/
  int32         rtt_ps;
  /* For RangingScanResponse
   * time stamp is an averaged time stamp, if there are multiple
   * measurements for a Wifi Node.
   */
  int64         rtt_timestamp;
  /** Measurement time stamp.
   * For DiscoveryScanResponse
   *  time stamp is corresponding to when the beacon was received.
   */
  int64         rssi_timestamp;
  /** Signal strength in 0.5dBm */
  int16         rssi;

  /** Adding reserved fields to make sure structure is 64-bit
   *  aligned, but do we really need align this structure? */
  uint16        reserved1;
  uint32        reserved2;

  /** BGScan parameters */
  /** Scan id */
  uint32 bgscan_scan_id;
  /** Flags */
  uint32 bgscan_flags;

  /** TX Parameters */
  /** bitrate */
  uint32         tx_bitrate; /* in units of 100Kbps */
  /** preamble */
  uint8          tx_preamble;
  /** Number of spatial streams */
  uint8          tx_nss;
  /** Bandwidth of the transmitted ack from the device to Wifi Node
   *  Note: LOWIUtils::to_eRangingBandwidth can be used to do
   *  the conversion */
    uint8          tx_bw;
  /** Modulation Coding Scheme (MCS) index defines the
   *  following:
   *  1) The Number of Streams used for TX & RX
   *  2) the Type of mudulation used
   *  3) the Coding Rate
   *
   *  Note: Does not apply to legacy frames (frames using schemes
   *  prior to 802.11n)
   *   */
  uint8          tx_mcsIdx; /* does not apply to OFDM preambles */
  /* used tx chain number, if fwr do not fill it then set it -1 */
  int8           tx_chain_no;

  /** RX Parameters */
  /** bitrate */
  uint32         rx_bitrate; /* in units of 100Kbps */
  /* used rx chain number, if fwr do not fill it then set it -1 */
  int8           rx_chain_no;
  /** preamble */
  uint8          rx_preamble;
  /** Number of spatial streams */
  uint8          rx_nss;
  /** Bandwidth of the received frame from the Wifi Node
   *  Note: LOWIUtils::to_eRangingBandwidth can be used to do the
   *  conversion */
  uint8          rx_bw;
  /** Modulation Coding Scheme (MCS) index defines the
   *  following:
   *  1) The Number of Streams used for TX & RX
   *  2) the Type of mudulation used
   *  3) the Coding Rate
   *
   *  Note: Does not apply to legacy frames (frames using schemes
   *  prior to 802.11n)
   *   */
  uint8          rx_mcsIdx; /* does not apply to OFDM preambles */
  LOWICFRCIRInfo* cfrcirInfo;
public:
  /** constructor */
  LOWIMeasurementInfo();
};

/**
 * This class defines the measurement taken for every scan request.
 * This contains the measurements corresponding the discovery / ranging
 * and background scan requests. However, the fields are valid /
 * invalid based on type of scan as documented below.
 *
 * NOTE: IF YOU ADD ANY NEW FIELDS TO THIS CLASS PLEASE ADD IT
 * TO THE CONSTRUCTOR AND COPY CONSTRUCTOR, OTHERWISE YOU WILL
 * GET UNPREDICTABLE BEHAVIOR WHEN DATA IS PASSED FROM ONE LOWI
 * LAYER TO ANOTHER.
 *
 */
class LOWIScanMeasurement
{
public:
  /** Log Tag */
  static const char * const TAG;

  /** Encryption type supported by the Wifi Node
   * NOTE: Expect changes to this interface. Not yet finalized
   */
  enum eEncryptionType
  {
    LOWI_ENCRYPTION_TYPE_UNKNOWN  = 0,
    LOWI_ENCRYPTION_TYPE_OPEN     = 1,
    LOWI_ENCRYPTION_TYPE_WEP      = 2,
    LOWI_ENCRYPTION_TYPE_WPA_PSK  = 3,
    LOWI_ENCRYPTION_TYPE_WPA_EAP  = 4
  };

  /**
   * Provides the PEER OEM information
   * This info is going to be available through Ranging scans
   * on Lithium and through Discovery scans in future chip sets.
   */
  enum ePeerOEM
  {
    LOWI_PEER_OEM_UNKNOWN = 0,
    LOWI_PEER_OEM_QTI     = 1
  };

  /** BSSID of the wifi node*/
  LOWIMacAddress  bssid;

  /** Operating Channel Information */
  uint32          frequency;         /* Primary Channel Frequency */

  /************* INTERNAL FIELDS *******************
   *  The following fields are used internaly within LOWI and
   *  will not be provided to Clients. Clients shall not rely
   *  on the values of these fields.
   */
  /** Operating Channel Information... Contd */
  uint32          band_center_freq1[BW_MAX]; /* Channel Center Frequency for whole BW */
  uint32          band_center_freq2; /* Channel Center frequency of second 80 MHz lobe for 80 + 80 BW */
  /** The following info field is a bitfield that contains PHY
    * mode and flags for this bssid.
    * Bits 0-6 contain the PHY mode
    * Bits 7-13 contain the flags
    */
  uint32          info;
  uint32          tsfDelta;  /* Delta between local TSF and Target's TSF*/
  /* Indicates if the BSSID supports 11mc - dual sided RTT
   */
  uint32          ranging_features_supported;
  /** Timestamp of when RTT measurement was taken - applies
   *  only to RTT measurements at this time */
  uint64          rttMeasTimeStamp;         /* 0.1 ns units */
  /************* END INTERNAL FIELDS ***************/

  /** Flag indicating if we are associated with this AP
   * Note: This is cached information from LOWI-AP in passive listening mode
   *       Does not come from LOWI-LP. To guarantee up to date information on
   *       this, clients can use Full beacon scan request.
   */
  bool            associatedToAp;

  /** Secure access point or not. Only valid for DiscoveryScanResponse*/
  bool            isSecure;
  /** Type of the Wifi Node. Only valid for DiscoveryScanResponse*/
  eNodeType       type;
  /** Type of RTT measurement performed, if applicable */
  eRttType        rttType;
  /** SSID. Only valid for DiscoveryScanResponse*/
  LOWISsid        ssid;
  /** MsapInfo - valid if not NULL. Only valid for DiscoveryScanResponse*/
  LOWIMsapInfo*   msapInfo;
  /** Cell power limit in dBm. Only valid for discovery scan results,
   *  if available. For ranging scan results will be always 0.
   */
  int8            cellPowerLimitdBm;

  /**
   * Indicates if AP is indoor or outdoor
   * ' ' indicates - Do not care
   * 'I' indicates - Indoor
   * 'O' indicates - Outdoor
   */
  uint8         indoor_outdoor;

  /**
   * Dynamic array containing measurement info per Wifi node.
   * DiscoveryScan and background scans will only have one measurement
   * where as the the vector can contain multiple MeasurementInfo for a
   * Ranging scan.
   */
  vector <LOWIMeasurementInfo*> measurementsInfo;

  /**
   * This is an enumation of the list of error codes the Wi-fi
   * Driver will send to LOWI controller with the scan
   * measurements on a per Target basis.
   */
  enum eTargetStatus
  {
    LOWI_TARGET_STATUS_SUCCESS                             = 0,
    LOWI_TARGET_STATUS_FAILURE                             = 1,
    LOWI_TARGET_STATUS_RTT_FAIL_NO_RSP                     = 2, /* Target Doesn't respond to RTT request */
    LOWI_TARGET_STATUS_RTT_FAIL_REJECTED                   = 3, /* Target rejected RTT3 request - Applies to RTT3 only */
    LOWI_TARGET_STATUS_RTT_FAIL_FTM_TIMEOUT                = 4, /* Timing measurement Timesout */
    LOWI_TARGET_STATUS_RTT_TARGET_ON_DIFF_CHANNEL          = 5, /* Target on different Channel - failure to Range */
    LOWI_TARGET_STATUS_RTT_FAIL_TARGET_NOT_CAPABLE         = 6, /* Target not capable of Rtt3 ranging */
    LOWI_TARGET_STATUS_RTT_FAIL_INVALID_TS                 = 7, /* Invalid Time stamps when ranging with Target */
    LOWI_TARGET_STATUS_RTT_FAIL_TARGET_BUSY_TRY_LATER      = 8, /* Target is busy, please try RTT3 at a later time */
    LOWI_TARGET_STATUS_RTT_NAN_RANGING_PROTOCOL_FAILURE          = 9, /* NAN Ranging negotiation failure */
    LOWI_TARGET_STATUS_RTT_NAN_RANGING_CONCURRENCY_NOT_SUPPORTED = 10,/* NAN Ranging Concurreny not supported */
    LOWI_TARGET_STATUS_MAX
  };

  /**
   * Status for the measurements associated with this Target.
   */
  eTargetStatus targetStatus;

  /** Contains the Country Code
   * i.e. 'U' 'S'
   * if there is no country code found, then the array will contain 0 0
   */
  uint8         country_code [LOWI_COUNTRY_CODE_LEN];

  /**
   * Measurement number. In case of periodic ranging scan measurements, this
   * will provide a counter that the client can use to track the number of
   * measurements at any given point during the ranging request. It does not
   * apply to single-shot ranging requests. For single-shot requests this will
   * always be zero.
   */
  uint32 measurementNum;

  /** The following four params
   *  -- beaconPeriod
   *  -- beaconCaps
   *  -- ieLen
   *  -- ieData
   *  are part of the results for background scans
   */

  /** Period advertised in the beacon */
  uint16 beaconPeriod;

  /** Capabilities advertised in the beacon */
  uint16 beaconCaps;

  /** Status advertised in the beacon */
  uint32 beaconStatus;

  /** Blob of all the information elements found in the beacon */
  vector<int8> ieData;

  /** Total RTT measurement Frames attempted   */
  uint16 num_frames_attempted;

  /** Actual time taken by FW to finish one burst of
   *  measurements (unit: ms) */
  uint16 actual_burst_duration;

  /** Number of "FTM frames per burst" negotiated with
   *  peer/target. */
  uint8 negotiated_num_frames_per_burst;

  /** If Target/peer fails to accept an FTM session. Peer will
   *  provide when it to retry FTM session. this field has the
   *  time after which FTM session can be retried.
   *  uint: seconds */
  uint8 retry_after_duration;

  /** Number of "FTM bursts" negotiated with peer/target.
   *  This is indicated in the form of an exponent.
   *  The number of bursts = 2^negotiated_burst_exp */
  uint8 negotiated_burst_exp;

  /** LCI information element */
  LOWILocationIE *lciInfo;

  /** LCR information element */
  LOWILocationIE *lcrInfo;

  /** AoA measurement result */
  LOWIAoAResult *aoaMeasurement;

  /** definitions used in location_features_supported  */
  #define LCI_SUPPORTED_MASK           0x00000001
  #define LOC_CIVIC_SUPPORTED_MASK     0x00000002
  #define ANQP_SUPPORTED_MASK          0x00000004
  /** bit mask used to store which location features are supported by the AP */
  uint32 location_features_supported;

  /** Constructor*/
  LOWIScanMeasurement ();
  /** Destructor*/
  virtual ~LOWIScanMeasurement ();

  /** Copy constructor **/
  LOWIScanMeasurement( const LOWIScanMeasurement& rhs );
  /** Assignment operator **/
  LOWIScanMeasurement& operator=( const LOWIScanMeasurement& rhs );

  /** Type of the Scan Measurement */
  enum eScanMeasurementType
  {
    LOWI_SCAN_MEASUREMENT = 0,
    LOWI_FULL_BEACON_SCAN_MEASUREMENT = 1,
    LOWI_RANGING_SCAN_MEASUREMENT = 2
  };

  /**
   * Returns the ScanMeasurement type
   * @return eScanMeasurementType Type of ScanMeasurement
   */
  virtual eScanMeasurementType getScanMeasurementType ()
  {
    return LOWI_SCAN_MEASUREMENT;
  }

  /** Phy Mode. */
  eLOWIPhyMode phyMode;

  /** Max Tx rate in Kbps supported by the Wifi Node */
  uint32 maxTxRate;

  /** Encryption Type supported by WiFi Node */
  eEncryptionType encryptionType;

  /** Target TSF
  * Wifi Node's time stamp embedded in the last beacon.
  * Note: 0 value for this field indicates "NOT VALID"
  * Note: This is only available if the scan is performed
  *       over APSS (Full beacon)
  */
  uint64 targetTSF;

  /**
   * Provides the scan measurement addition info.
   * if bit 0 is set, then the results are from
   * beacon IE or it is a probe response
   */
  #define LOWI_BEACON_IE_MASK           0x0000000000000001
  uint64 measAdditionalInfoMask;

  /**
   * Provides the OEM information.
   * Only provided as part of 2 sided ranging with the peer (RTT3)
   */
  ePeerOEM peerOEM;
};

/**
 * Class to provide the full beacon Scan measurement details from a
 * beacon / probe response.
 */
class LOWIFullBeaconScanMeasurement : public LOWIScanMeasurement
{
private:
  static const char* const TAG;

public:

  /** Vector containing all the IEs */
  vector <LOWILocationIE*> mLOWIIE;

  /**
   * Returns the ScanMeasurement type
   * @return eScanMeasurementType Type of ScanMeasurement
   */
  virtual eScanMeasurementType getScanMeasurementType ()
  {
    return LOWI_FULL_BEACON_SCAN_MEASUREMENT;
  }

  /**
   * Destructor
   */
  virtual ~LOWIFullBeaconScanMeasurement ();
};

/**
 * Class to provide the extended Ranging Scan measurements.
 */
class LOWIRangingScanMeasurement : public LOWIScanMeasurement
{
private:
  static const char* const TAG;

public:
  /**
   * Indicates maximum possible number of BSSs, including the reference BSS
   * sharing the same antenna connector.
   * If this field is not configured (value 0), then look at the colocatedBssids field
   */
  uint8 maxBssidsIndicator;


  /**
   * Contains the explicit list of the Virtual mac addresses
   * which share the same antenna connector.
   * This field contains explicit Bssids only if the maxBssidsIndicator field is 0
   */
  vector <LOWIMacAddress> colocatedBssids;

  /**
   * Returns the ScanMeasurement type
   * @return eScanMeasurementType Type of ScanMeasurement
   */
  virtual eScanMeasurementType getScanMeasurementType ()
  {
    return LOWI_RANGING_SCAN_MEASUREMENT;
  }

  // Constructor
  LOWIRangingScanMeasurement ()
  : maxBssidsIndicator (0)
  {
  }

  // Destructor
  virtual ~LOWIRangingScanMeasurement ()
  {
  }

};
} // namespace qc_loc_fw

#endif //#ifndef __LOWI_SCAN_MEASUREMENT_H__
