/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 Config file

 GENERAL DESCRIPTION
 This header declares a config file parser

 Copyright (c) 2012-2013 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 =============================================================================*/
#ifndef __XTRAT_WIFI_CONFIG_FILE_H__
#define __XTRAT_WIFI_CONFIG_FILE_H__

namespace qc_loc_fw
{

class ConfigFile
{
public:
  static ConfigFile * createInstance(const char * const filename, const size_t max_line_length = 1023,
      const bool verbose = false);

  virtual ~ConfigFile() = 0;

  virtual bool loaded() const = 0;

  enum RETURN_CODE
  {
    NO_ERROR_RESULT_SET = 0, NOT_FOUND = 1000
  };

  virtual int getString(const char * const name, const char ** pStr) = 0;
  virtual int getStringDup(const char * const name, const char ** pStr, const char * const strDefault = 0) = 0;
  virtual int getInt32(const char * const name, int & value) = 0;
  virtual int getInt32Default(const char * const name, int & value, const int & Default) = 0;
  virtual int get_PZ_Int32Default(const char * const name, int & value, const int & Default) = 0;
  virtual int get_PNZ_Int32Default(const char * const name, int & value, const int & Default) = 0;
  virtual int getDouble(const char * const name, double & value) = 0;
  virtual int getDoubleDefault(const char * const name, double & value, const double & Default) = 0;
};

} // namespace qc_loc_fw

#endif //#ifndef __XTRAT_WIFI_CONFIG_FILE_H__
