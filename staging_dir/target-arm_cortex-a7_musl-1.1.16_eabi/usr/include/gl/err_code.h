/*
 * err_code.h
 * 
 * Created on: Mon 23 Apr 2018 06:01:50 PM CST
 *     Author: lancer
 *      Email: luoyejiang0701@qq.com
 */
#ifndef ERR_CODE_H
#define ERR_CODE_H

#define SUCCESS					 0		//handle success
#define ERR_INVALID_USER 		 -1     //Invalid user, permission denied or not logged in!
#define ERR_COOKIE_DISABLE 		 -2		//cookie disabled in broswer, you should enable it
#define ERR_PATH_NOT_FOUND		 -3     //can't find the API interface, maybe not installed  
#define ERR_PARAM_ERROR			 -4     //Invalid parameter, value or format!
#define ERR_PARAM_MISSING		 -5     //No parameter found!
#define ERR_TIMEOUT				 -6     //Time out!
#define ERR_FILE_MISSING		 -7     //file missing
#define ERR_NO_CABLE			 -8     //the cable not in wan interface
#define ERR_WRONG_PASSWORD		 -9		//wrong password
#define ERR_UPLOAD_FAILED		 -10    //the file upload failed
#define ERR_MALLOC_FAILED		 -11	//malloc memory failed
#define ERR_OPKG_UNAVAILABLE	 -12	//opkg temporarily unavailable
#define ERR_OPKG_OPERATE_FAILED	 -13	//opkg operator failed
#define ERR_COMMAND_MISSING		 -14	//can't find the command
#define ERR_PARAM_EXISTED		 -15	//param already exist
#define ERR_PROCESS_EXISTED		 -16	//Process is exist
#define ERR_UPSUPPORT_FEATURE	 -17	//Unsupported features.
#define ERR_DEVICE_NOT_INSERT	 -18	//No device found. Please insert. 
#define ERR_IP_INVALID			 -19	//IP conflict
/*Firmware*/
#define ERR_FW_SIZE				 -20    //the size of firmware error
#define ERR_FW_FORMAT			 -21	//the format of firmware error

#define ERR_LENGTH_INVALID		 -22	//Invalid string length
#define ERR_PORT_INVALID		 -23	//Invalid port number
#define ERR_NETWORK_UNREACHABLE	 -24	//Network unreachable
#define ERR_OPKG_UNINSTALL_UNSUPPORT	 -25	//The software uninstall unsupport
#define ERR_BRIDGE_ENABLE		  -26    //The bridge is enable
#define ERR_BRIDGE_FAILED		  -27    //The bridge is failed
#define ERR_DUPLICATE_NAME_EXISTS	-28 //A duplicate name exists

#define ERR_WAN2LAN_FAILED		-29   //Please remove internet cable
#define ERR_OPKG_UPDATE_FAILED  -30
#define ERR_OPKG_INSTALL_FAILED -31
#define ERR_UNKNOWN				 -99    //unknown error

/*WIFI*/
#define ERR_KEY					 -100   //wrong key
#define ERR_KEY_LENGTH			 -101   //The Key should be more than 8 and less than 63 characters in length
#define ERR_SSID_LENGTH			 -102   //The ssid's length cannot be greater than 32
#define ERR_WPA					 -103	//wpasupplicant error
#define ERR_AUTO_CHANNEL		 -104   //auto channel when connected by repeater
#define ERR_WIFI_NOT_IN_RANGE    -105   //wifi not in range
#define ERR_WRONG_ENCRYPTION	 -106   //wrong encryption
//#define ERR_WIFI_CONFIG_MISSING  -107   //no saved ssid
#define ERR_STA_NOT_CONFIGURE    -108   //sta not configed properly
#define ERR_GUEST_NETWORK_DISABLED	 -109   
#define ERR_CHANNEL_INVALID		-110   //channel invalid
#define ERR_FLASH_NO_SPACE		-111   //no flash space
#define ERR_NO_WIFI_MODULE      -112   //no wifi module
#define ERR_NO_5G_WIFI_MODULE      -113   //no 5g wifi module
#define ERR_AP_2G_BAND_MODULE   -114    //You cannot repeat 5G wifi now because your Wi-Fi module only support 2.4G.
#define ERR_DONGLE_5G_BAND_MODULE   -115    //You want to repeat a 2.4G Wi-Fi network. Please switch to 2.4G mode for your dongle first.
#define ERR_DONGLE_2G_BAND_MODULE   -116    //You want to repeat a 5G Wi-Fi network. Please switch to 5G mode for your dongle first.
#define ERR_AP_MODULE           -117    //The dongle have't exit.Please refresh the page.

/*VPN*/
#define ERR_MAX_KEYS_LIMIT	     -199   //You have reached the maximum number of WireGuard keys. Go to https://mullvad.net/account/#port-management to revoke one of your keys.
#define ERR_CLIENT_CONFLICT		 -200	//Must be stopped server before starting client
#define ERR_SERVER_CONFLICT		 -201	//Must be stopped client before starting server
#define ERR_STOPPED				 -202	//stopped
#define ERR_CONNECTING		 	 -203	//connecting
#define ERR_DISCONNECTED		 -204	//disconnected
#define ERR_STOP_FAILURE		 -205	//stop failure
#define ERR_START_FAILURE		 -206	//start failure
#define ERR_CREATEKEY_FAILURE	 -207	//createkey failure
#define ERR_NO_KEY				 -208	//no key existed
#define ERR_NOT_INSTALLED		 -209	//not installed
#define ERR_NO_INTERNET			 -210	//The router no internet
#define ERR_INVALID_USER_OR_PSW	 -211	//Invalid username or password
#define ERR_INVALID_ACCOUNT		 -212	//Invalid Account
#define ERR_GET_CONFIG			 -213	//Get Config Fail
#define ERR_INVALID_IP			 -214	//Invalid IP Address
#define ERR_INVALID_NETMASK		 -215	//Invalid subnet mask
#define ERR_INVALID_PORT		 -216	//Invalid port
#define ERR_INVALID_PAIR		 -217	//Invalid pair 
#define ERR_INVALID_DNS			 -218	//Invalid DNS
#define ERR_INVALID_ALLOWEDIPS   -219   //Invalid AllowedIPs
#define ERR_PORT_CONFLICT        -222   //Port is occupied
#define ERR_INVALID_IPV6         -223   //IPV6 Address must start with fd00

/*#Modem*/
#define ERR_DEVICE_NO_FOUND		 -250	//device not found, please insert it
#define ERR_MODEM_ID_MISSING	 -251	//modem id missing
#define ERR_DATABASE_ERR		 -252	//database missing or errors
#define ERR_CONNECT_LONG_TIME	 -253	//modem connecting is long time
#define ERR_CONFIG_MISSING		 -254	//modem config file missing
#define ERR_COMMAND_FAILED		 -255	//command excute failed
#define ERR_PORT_NOT_FOUND		 -256	//port not found, please check it
#define ERR_DEVICE_NOT_SUPPORT	 -257	//device not support
#define ERR_MSG_ID_MISSING		 -258	//message id missing
#define ERR_MSG_DEL_FAILED		 -259	//message delete failed
#define ERR_PHONE_NUMBER_MISSING -260	//phone number missing
#define ERR_MSG_CONTENT_MISSING	 -261	//phone conetnt missing
#define ERR_MSG_SEND_FAILED		 -262	//message send failed
#define ERR_CHECK_SIM_CARD		 -263	//please check SIM card
#define ERR_MSG_STATUS_SET_FAIL	 -264	//message status set fail
#define ERR_DEVICE_BUSY	 		 -265	//device busy
#define ERR_NO_FORWARD_FILE      -266   //no forward file
#define ERR_NO_SSMTP             -267   //no ssmtp package

/* Switch */
#define ERR_WISP_DISCONNECTED	-300    //Wisp disconnected
#define ERR_VPN_NOFOUND			-301    //Vpn not found
#define ERR_VPN_INVALID			-302    //Vpn function invalid

/*BLE ERROR CODE*/
#define ERR_BLE_NO_RESPONSE 		 	-400    //Remote device has no response
#define ERR_BLE_CONNECT_SPECIFIED_FAILED	-401	//Connect specified device failed
#define ERR_BLE_GET_LIST_FAILED			-402	//Get scan list or device list from host failed
//ble stack error
#define	ERR_BLE_INVALID_CONN_HANDLE         -450  	//Invalid GATT connection handle.
#define ERR_BLE_WAITING_RESPONSE            -451    //Waiting response from GATT server to previous procedure.
#define ERR_BLE_GATT_CONNECTION_TIMEOUT     -452    //GATT connection is closed due procedure timeout.
#define ERR_BLE_INVALID_PARAM               -453    //Command contained invalid parameter
#define ERR_BLE_WRONG_STATE                 -454    //Device is in wrong state to receive command
#define ERR_BLE_OUT_OF_MEMORY               -455    //Device has run out of memory
#define ERR_BLE_NOT_IMPLEMENTED             -456    //Feature is not implemented
#define ERR_BLE_INVALID_COMMAND             -457    //Command was not recognized
#define ERR_BLE_TIMEOUT                     -458    //Command or Procedure failed due to timeout
#define ERR_BLE_NOT_CONNECTED               -459    //Connection handle passed is to command is not a valid handle
#define ERR_BLE_FLOW                        -460    //Command would cause either underflow or overflow error
#define ERR_BLE_USER_ATTRIBUTE              -461    //User attribute was accessed through API which is not supported
#define ERR_BLE_INVALID_LICENSE_KEY         -462    //No valid license key found
#define ERR_BLE_COMMAND_TOO_LONG            -463    //Command maximum length exceeded
#define ERR_BLE_OUT_OF_BONDS                -464    //Bonding procedure can't be started because device has no space left for bond.
#define ERR_BLE_UNSPECIFIED                 -465   	//Unspecified error
#define ERR_BLE_HARDWARE                    -466    //Hardware failure
#define ERR_BLE_BUFFERS_FULL                -467    //Command not accepted, because internal buffers are full
#define ERR_BLE_DISCONNECTED                -468    //Command or Procedure failed due to disconnection
#define ERR_BLE_TOO_MANY_REQUESTS           -469    //Too many Simultaneous Requests
#define ERR_BLE_NOT_SUPPORTED               -470   	//Feature is not supported in this firmware build
#define ERR_BLE_NO_BONDING                  -471    //The bonding does not exist.
#define ERR_BLE_CRYPTO                      -472    //Error using crypto functions
#define ERR_BLE_DATA_CORRUPTED              -473    //Data was corrupted.
#define ERR_BLE_COMMAND_INCOMPLETE          -474    //Data received does not form a complete command

/* nas */
#define ERR_FILE_EXISTED    -500    //file already exists
#define ERR_FS_MISSING      -501    //filesystem missing
#define ERR_FS_UMOUNT       -502    //filesystem can't umount safely
/*wifi coverage*/
#define ERR_FUNCTION_CONFLICT -600 //wifi coverage conflict

/*AdGuardHome*/
#define ERR_DNS_BUSY -700 //wifi coverage conflict

/*MESH*/
#define ERR_TOPO_DATA -800 //no mesh data
#define ERR_MESHSUB_OFFLINE -801 //sub device offline
#define ERR_MESH_UPGRADE -802 //sub upgrde faile
#define ERR_MESH_SUPPORT -803 //no support on mesh mode

/*MAC CLONE*/
#define ERR_MAC_CONFLICT -900 //mac conflict for clone

#endif /* ERR_CODE_H */


