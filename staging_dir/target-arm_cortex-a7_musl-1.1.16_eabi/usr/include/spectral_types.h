#ifndef _SPECTRAL_TYPES_H_
#define _SPECTRAL_TYPES_H_

/*
 * =====================================================================================
 * spectral common data types (windows/linux)           
 * =====================================================================================
 */


#ifdef WIN32

typedef unsigned __int64    u_int64_t;
typedef __int64             int64_t;
typedef unsigned long       u_int32_t;
typedef long                int32_t;
typedef unsigned short      u_int16_t;
typedef short               int16_t;
typedef unsigned char       u_int8_t;
typedef char                int8_t;

#define INT_MAX         (int)(~0U>>1) 
#define INT_MIN         (-INT_MAX - 1)  

#else // non Win32 data type definitions

#endif


#endif  /* _SPECTRALTYPES_H_ */

