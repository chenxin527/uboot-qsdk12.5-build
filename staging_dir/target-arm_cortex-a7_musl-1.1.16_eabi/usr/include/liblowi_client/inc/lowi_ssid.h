#ifndef __LOWI_SSID_H__
#define __LOWI_SSID_H__

/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

        LOWI SSID Interface Header file

GENERAL DESCRIPTION
  This file contains the structure definitions and function prototypes for
  LOWI SSID

Copyright (c) 2012, 2016,2018 Qualcomm Technologies, Inc.
All Rights Reserved.
Confidential and Proprietary - Qualcomm Technologies, Inc.

(c) 2012 Qualcomm Atheros, Inc.
  All Rights Reserved.
  Qualcomm Atheros Confidential and Proprietary.

=============================================================================*/

#include <inc/lowi_defines.h>
#include <inc/lowi_const.h>


namespace qc_loc_fw
{

/**
 * Class for SSID
 */
class LOWISsid
{
public:
  LOWISsid ();
  /**
   * Checks if the SSID is valid
   * @return true for valid, false otherwise
   */
  bool isSSIDValid() const;

  /**
   * Sets SSID
   * @param unsigned char* SSID to be set
   * @param int   Length of the SSID
   * @return 0 for success, non zero for error
   */
  int setSSID(const unsigned char * const ssid, const int length);

  /**
   * Gets SSID
   * @param [out] unsigned char* SSID to be retrieved
   * @param [out] int*   Length of the SSID
   * @return 0 for success, non zero for error
   */
  int getSSID(unsigned char * const pSsid, int * const pLength) const;

  /**
   * Compares the ssid with the current
   * @param LOWISsid& LOWISsid to compare with
   * @return 0 for equal, non zero otherwise
   */
  int compareTo (const LOWISsid & ssid);

  /**
   * Prints SSID
   * @param uint8* SSID to be printed
   * @param int   Length of the SSID
   */
  static void print (const uint8* const ssid, const int length);

  /**
   * Returns the SSID is printable format
   * @param uint8* SSID to be printed
   * @param uint8  Length of the SSID
   * @param char[SSID_LEN+1] Array to return SSID in NULL terminated string format
   * @return char* SSID into string format
   */
  static const char* toString (const uint8* const ssid, const uint8 length,
                               char ssid_str[SSID_LEN+1]);

  /** Prints the SSID */
  void print ()
  {
    print (m_ssid, m_ssid_length);
  }

  /**
   * Returns the SSID in printable format
   * @param char[SSID_LEN+1] Array to return SSID in NULL terminated string format
   */
  const char* toString (char str[SSID_LEN+1])
  {
    str[0] = '\0'; // Set the result as empty string
    return (m_isSsidValid ? LOWISsid::toString (m_ssid, m_ssid_length, str) : str);
  }

  /**
   * Log Tag
   */
  static const char * const TAG;

private:
  unsigned char m_ssid[SSID_LEN];
  bool m_isSsidValid;
  bool m_isSsidSet;
  uint16 m_ssid_length;
};

} // namespace qc_loc_fw

#endif //#ifndef __LOWI_SSID_H__
