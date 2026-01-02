#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "event_core_static" for configuration "Release"
set_property(TARGET event_core_static APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_core_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent_core.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_core_static )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_core_static "${_IMPORT_PREFIX}/lib/libevent_core.a" )

# Import target "event_core_shared" for configuration "Release"
set_property(TARGET event_core_shared APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_core_shared PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent_core-2.1.so.7.0.0"
  IMPORTED_SONAME_RELEASE "libevent_core-2.1.so.7"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_core_shared )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_core_shared "${_IMPORT_PREFIX}/lib/libevent_core-2.1.so.7.0.0" )

# Import target "event_extra_static" for configuration "Release"
set_property(TARGET event_extra_static APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_extra_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent_extra.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_extra_static )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_extra_static "${_IMPORT_PREFIX}/lib/libevent_extra.a" )

# Import target "event_extra_shared" for configuration "Release"
set_property(TARGET event_extra_shared APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_extra_shared PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent_extra-2.1.so.7.0.0"
  IMPORTED_SONAME_RELEASE "libevent_extra-2.1.so.7"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_extra_shared )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_extra_shared "${_IMPORT_PREFIX}/lib/libevent_extra-2.1.so.7.0.0" )

# Import target "event_openssl_static" for configuration "Release"
set_property(TARGET event_openssl_static APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_openssl_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent_openssl.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_openssl_static )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_openssl_static "${_IMPORT_PREFIX}/lib/libevent_openssl.a" )

# Import target "event_openssl_shared" for configuration "Release"
set_property(TARGET event_openssl_shared APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_openssl_shared PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent_openssl-2.1.so.7.0.0"
  IMPORTED_SONAME_RELEASE "libevent_openssl-2.1.so.7"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_openssl_shared )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_openssl_shared "${_IMPORT_PREFIX}/lib/libevent_openssl-2.1.so.7.0.0" )

# Import target "event_pthreads_static" for configuration "Release"
set_property(TARGET event_pthreads_static APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_pthreads_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent_pthreads.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_pthreads_static )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_pthreads_static "${_IMPORT_PREFIX}/lib/libevent_pthreads.a" )

# Import target "event_pthreads_shared" for configuration "Release"
set_property(TARGET event_pthreads_shared APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_pthreads_shared PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent_pthreads-2.1.so.7.0.0"
  IMPORTED_SONAME_RELEASE "libevent_pthreads-2.1.so.7"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_pthreads_shared )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_pthreads_shared "${_IMPORT_PREFIX}/lib/libevent_pthreads-2.1.so.7.0.0" )

# Import target "event_static" for configuration "Release"
set_property(TARGET event_static APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_static PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent.a"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_static )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_static "${_IMPORT_PREFIX}/lib/libevent.a" )

# Import target "event_shared" for configuration "Release"
set_property(TARGET event_shared APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(event_shared PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libevent-2.1.so.7.0.0"
  IMPORTED_SONAME_RELEASE "libevent-2.1.so.7"
  )

list(APPEND _IMPORT_CHECK_TARGETS event_shared )
list(APPEND _IMPORT_CHECK_FILES_FOR_event_shared "${_IMPORT_PREFIX}/lib/libevent-2.1.so.7.0.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
