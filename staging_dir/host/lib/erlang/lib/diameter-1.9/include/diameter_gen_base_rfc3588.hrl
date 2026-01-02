%% -------------------------------------------------------------------
%% This is a generated file.
%% -------------------------------------------------------------------

%%
%% Copyright (c) Ericsson AB. All rights reserved.
%%
%% The information in this document is the property of Ericsson.
%%
%% Except as specifically authorized in writing by Ericsson, the
%% receiver of this document shall keep the information contained
%% herein confidential and shall protect the same in whole or in
%% part from disclosure and dissemination to third parties.
%%
%% Disclosure and disseminations to the receivers employees shall
%% only be made on a strict need to know basis.
%%

-hrl_name('diameter_gen_base_rfc3588.hrl').


%%% -------------------------------------------------------
%%% Message records:
%%% -------------------------------------------------------

-record(diameter_base_CER,
	{'Origin-Host', 'Origin-Realm', 'Host-IP-Address' = [],
	 'Vendor-Id', 'Product-Name', 'Origin-State-Id' = [],
	 'Supported-Vendor-Id' = [], 'Auth-Application-Id' = [],
	 'Inband-Security-Id' = [], 'Acct-Application-Id' = [],
	 'Vendor-Specific-Application-Id' = [],
	 'Firmware-Revision' = [], 'AVP' = []}).

-record(diameter_base_CEA,
	{'Result-Code', 'Origin-Host', 'Origin-Realm',
	 'Host-IP-Address' = [], 'Vendor-Id', 'Product-Name',
	 'Origin-State-Id' = [], 'Error-Message' = [],
	 'Failed-AVP' = [], 'Supported-Vendor-Id' = [],
	 'Auth-Application-Id' = [], 'Inband-Security-Id' = [],
	 'Acct-Application-Id' = [],
	 'Vendor-Specific-Application-Id' = [],
	 'Firmware-Revision' = [], 'AVP' = []}).

-record(diameter_base_DPR,
	{'Origin-Host', 'Origin-Realm', 'Disconnect-Cause'}).

-record(diameter_base_DPA,
	{'Result-Code', 'Origin-Host', 'Origin-Realm',
	 'Error-Message' = [], 'Failed-AVP' = []}).

-record(diameter_base_DWR,
	{'Origin-Host', 'Origin-Realm',
	 'Origin-State-Id' = []}).

-record(diameter_base_DWA,
	{'Result-Code', 'Origin-Host', 'Origin-Realm',
	 'Error-Message' = [], 'Failed-AVP' = [],
	 'Origin-State-Id' = []}).

-record('diameter_base_answer-message',
	{'Session-Id' = [], 'Origin-Host', 'Origin-Realm',
	 'Result-Code', 'Origin-State-Id' = [],
	 'Error-Reporting-Host' = [], 'Proxy-Info' = [],
	 'AVP' = []}).

-record(diameter_base_RAR,
	{'Session-Id', 'Origin-Host', 'Origin-Realm',
	 'Destination-Realm', 'Destination-Host',
	 'Auth-Application-Id', 'Re-Auth-Request-Type',
	 'User-Name' = [], 'Origin-State-Id' = [],
	 'Proxy-Info' = [], 'Route-Record' = [], 'AVP' = []}).

-record(diameter_base_RAA,
	{'Session-Id', 'Result-Code', 'Origin-Host',
	 'Origin-Realm', 'User-Name' = [],
	 'Origin-State-Id' = [], 'Error-Message' = [],
	 'Error-Reporting-Host' = [], 'Failed-AVP' = [],
	 'Redirect-Host' = [], 'Redirect-Host-Usage' = [],
	 'Redirect-Max-Cache-Time' = [], 'Proxy-Info' = [],
	 'AVP' = []}).

-record(diameter_base_STR,
	{'Session-Id', 'Origin-Host', 'Origin-Realm',
	 'Destination-Realm', 'Auth-Application-Id',
	 'Termination-Cause', 'User-Name' = [],
	 'Destination-Host' = [], 'Class' = [],
	 'Origin-State-Id' = [], 'Proxy-Info' = [],
	 'Route-Record' = [], 'AVP' = []}).

-record(diameter_base_STA,
	{'Session-Id', 'Result-Code', 'Origin-Host',
	 'Origin-Realm', 'User-Name' = [], 'Class' = [],
	 'Error-Message' = [], 'Error-Reporting-Host' = [],
	 'Failed-AVP' = [], 'Origin-State-Id' = [],
	 'Redirect-Host' = [], 'Redirect-Host-Usage' = [],
	 'Redirect-Max-Cache-Time' = [], 'Proxy-Info' = [],
	 'AVP' = []}).

-record(diameter_base_ASR,
	{'Session-Id', 'Origin-Host', 'Origin-Realm',
	 'Destination-Realm', 'Destination-Host',
	 'Auth-Application-Id', 'User-Name' = [],
	 'Origin-State-Id' = [], 'Proxy-Info' = [],
	 'Route-Record' = [], 'AVP' = []}).

-record(diameter_base_ASA,
	{'Session-Id', 'Result-Code', 'Origin-Host',
	 'Origin-Realm', 'User-Name' = [],
	 'Origin-State-Id' = [], 'Error-Message' = [],
	 'Error-Reporting-Host' = [], 'Failed-AVP' = [],
	 'Redirect-Host' = [], 'Redirect-Host-Usage' = [],
	 'Redirect-Max-Cache-Time' = [], 'Proxy-Info' = [],
	 'AVP' = []}).

-record(diameter_base_ACR,
	{'Session-Id', 'Origin-Host', 'Origin-Realm',
	 'Destination-Realm', 'Accounting-Record-Type',
	 'Accounting-Record-Number', 'Acct-Application-Id' = [],
	 'Vendor-Specific-Application-Id' = [], 'User-Name' = [],
	 'Accounting-Sub-Session-Id' = [],
	 'Acct-Session-Id' = [], 'Acct-Multi-Session-Id' = [],
	 'Acct-Interim-Interval' = [],
	 'Accounting-Realtime-Required' = [],
	 'Origin-State-Id' = [], 'Event-Timestamp' = [],
	 'Proxy-Info' = [], 'Route-Record' = [], 'AVP' = []}).

-record(diameter_base_ACA,
	{'Session-Id', 'Result-Code', 'Origin-Host',
	 'Origin-Realm', 'Accounting-Record-Type',
	 'Accounting-Record-Number', 'Acct-Application-Id' = [],
	 'Vendor-Specific-Application-Id' = [], 'User-Name' = [],
	 'Accounting-Sub-Session-Id' = [],
	 'Acct-Session-Id' = [], 'Acct-Multi-Session-Id' = [],
	 'Error-Reporting-Host' = [],
	 'Acct-Interim-Interval' = [],
	 'Accounting-Realtime-Required' = [],
	 'Origin-State-Id' = [], 'Event-Timestamp' = [],
	 'Proxy-Info' = [], 'AVP' = []}).


%%% -------------------------------------------------------
%%% Grouped AVP records:
%%% -------------------------------------------------------

-record('diameter_base_Proxy-Info',
	{'Proxy-Host', 'Proxy-State', 'AVP' = []}).

-record('diameter_base_Failed-AVP', {'AVP' = []}).

-record('diameter_base_Experimental-Result',
	{'Vendor-Id', 'Experimental-Result-Code'}).

-record('diameter_base_Vendor-Specific-Application-Id',
	{'Vendor-Id' = [], 'Auth-Application-Id' = [],
	 'Acct-Application-Id' = []}).

-record('diameter_base_E2E-Sequence', {'AVP' = []}).


%%% -------------------------------------------------------
%%% ENUM Macros:
%%% -------------------------------------------------------

-define('DIAMETER_BASE_DISCONNECT-CAUSE_REBOOTING', 0).
-define('DIAMETER_BASE_DISCONNECT-CAUSE_BUSY', 1).
-define('DIAMETER_BASE_DISCONNECT-CAUSE_DO_NOT_WANT_TO_TALK_TO_YOU', 2).
-define('DIAMETER_BASE_REDIRECT-HOST-USAGE_DONT_CACHE', 0).
-define('DIAMETER_BASE_REDIRECT-HOST-USAGE_ALL_SESSION', 1).
-define('DIAMETER_BASE_REDIRECT-HOST-USAGE_ALL_REALM', 2).
-define('DIAMETER_BASE_REDIRECT-HOST-USAGE_REALM_AND_APPLICATION', 3).
-define('DIAMETER_BASE_REDIRECT-HOST-USAGE_ALL_APPLICATION', 4).
-define('DIAMETER_BASE_REDIRECT-HOST-USAGE_ALL_HOST', 5).
-define('DIAMETER_BASE_REDIRECT-HOST-USAGE_ALL_USER', 6).
-define('DIAMETER_BASE_AUTH-REQUEST-TYPE_AUTHENTICATE_ONLY', 1).
-define('DIAMETER_BASE_AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 2).
-define('DIAMETER_BASE_AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 3).
-define('DIAMETER_BASE_AUTH-SESSION-STATE_STATE_MAINTAINED', 0).
-define('DIAMETER_BASE_AUTH-SESSION-STATE_NO_STATE_MAINTAINED', 1).
-define('DIAMETER_BASE_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 0).
-define('DIAMETER_BASE_RE-AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 1).
-define('DIAMETER_BASE_TERMINATION-CAUSE_LOGOUT', 1).
-define('DIAMETER_BASE_TERMINATION-CAUSE_SERVICE_NOT_PROVIDED', 2).
-define('DIAMETER_BASE_TERMINATION-CAUSE_BAD_ANSWER', 3).
-define('DIAMETER_BASE_TERMINATION-CAUSE_ADMINISTRATIVE', 4).
-define('DIAMETER_BASE_TERMINATION-CAUSE_LINK_BROKEN', 5).
-define('DIAMETER_BASE_TERMINATION-CAUSE_AUTH_EXPIRED', 6).
-define('DIAMETER_BASE_TERMINATION-CAUSE_USER_MOVED', 7).
-define('DIAMETER_BASE_TERMINATION-CAUSE_SESSION_TIMEOUT', 8).
-define('DIAMETER_BASE_SESSION-SERVER-FAILOVER_REFUSE_SERVICE', 0).
-define('DIAMETER_BASE_SESSION-SERVER-FAILOVER_TRY_AGAIN', 1).
-define('DIAMETER_BASE_SESSION-SERVER-FAILOVER_ALLOW_SERVICE', 2).
-define('DIAMETER_BASE_SESSION-SERVER-FAILOVER_TRY_AGAIN_ALLOW_SERVICE', 3).
-define('DIAMETER_BASE_ACCOUNTING-RECORD-TYPE_EVENT_RECORD', 1).
-define('DIAMETER_BASE_ACCOUNTING-RECORD-TYPE_START_RECORD', 2).
-define('DIAMETER_BASE_ACCOUNTING-RECORD-TYPE_INTERIM_RECORD', 3).
-define('DIAMETER_BASE_ACCOUNTING-RECORD-TYPE_STOP_RECORD', 4).
-define('DIAMETER_BASE_ACCOUNTING-REALTIME-REQUIRED_DELIVER_AND_GRANT', 1).
-define('DIAMETER_BASE_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_STORE', 2).
-define('DIAMETER_BASE_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_LOSE', 3).



%%% -------------------------------------------------------
%%% DEFINE Macros:
%%% -------------------------------------------------------

-define('DIAMETER_BASE_RESULT-CODE_MULTI_ROUND_AUTH', 1001).
-define('DIAMETER_BASE_RESULT-CODE_SUCCESS', 2001).
-define('DIAMETER_BASE_RESULT-CODE_LIMITED_SUCCESS', 2002).
-define('DIAMETER_BASE_RESULT-CODE_COMMAND_UNSUPPORTED', 3001).
-define('DIAMETER_BASE_RESULT-CODE_UNABLE_TO_DELIVER', 3002).
-define('DIAMETER_BASE_RESULT-CODE_REALM_NOT_SERVED', 3003).
-define('DIAMETER_BASE_RESULT-CODE_TOO_BUSY', 3004).
-define('DIAMETER_BASE_RESULT-CODE_LOOP_DETECTED', 3005).
-define('DIAMETER_BASE_RESULT-CODE_REDIRECT_INDICATION', 3006).
-define('DIAMETER_BASE_RESULT-CODE_APPLICATION_UNSUPPORTED', 3007).
-define('DIAMETER_BASE_RESULT-CODE_INVALID_HDR_BITS', 3008).
-define('DIAMETER_BASE_RESULT-CODE_INVALID_AVP_BITS', 3009).
-define('DIAMETER_BASE_RESULT-CODE_UNKNOWN_PEER', 3010).
-define('DIAMETER_BASE_RESULT-CODE_AUTHENTICATION_REJECTED', 4001).
-define('DIAMETER_BASE_RESULT-CODE_OUT_OF_SPACE', 4002).
-define('DIAMETER_BASE_RESULT-CODE_ELECTION_LOST', 4003).
-define('DIAMETER_BASE_RESULT-CODE_AVP_UNSUPPORTED', 5001).
-define('DIAMETER_BASE_RESULT-CODE_UNKNOWN_SESSION_ID', 5002).
-define('DIAMETER_BASE_RESULT-CODE_AUTHORIZATION_REJECTED', 5003).
-define('DIAMETER_BASE_RESULT-CODE_INVALID_AVP_VALUE', 5004).
-define('DIAMETER_BASE_RESULT-CODE_MISSING_AVP', 5005).
-define('DIAMETER_BASE_RESULT-CODE_RESOURCES_EXCEEDED', 5006).
-define('DIAMETER_BASE_RESULT-CODE_CONTRADICTING_AVPS', 5007).
-define('DIAMETER_BASE_RESULT-CODE_AVP_NOT_ALLOWED', 5008).
-define('DIAMETER_BASE_RESULT-CODE_AVP_OCCURS_TOO_MANY_TIMES', 5009).
-define('DIAMETER_BASE_RESULT-CODE_NO_COMMON_APPLICATION', 5010).
-define('DIAMETER_BASE_RESULT-CODE_UNSUPPORTED_VERSION', 5011).
-define('DIAMETER_BASE_RESULT-CODE_UNABLE_TO_COMPLY', 5012).
-define('DIAMETER_BASE_RESULT-CODE_INVALID_BIT_IN_HEADER', 5013).
-define('DIAMETER_BASE_RESULT-CODE_INVALID_AVP_LENGTH', 5014).
-define('DIAMETER_BASE_RESULT-CODE_INVALID_MESSAGE_LENGTH', 5015).
-define('DIAMETER_BASE_RESULT-CODE_INVALID_AVP_BIT_COMBO', 5016).
-define('DIAMETER_BASE_RESULT-CODE_NO_COMMON_SECURITY', 5017).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_MULTI_ROUND_AUTH', 1001).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_SUCCESS', 2001).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_LIMITED_SUCCESS', 2002).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_COMMAND_UNSUPPORTED', 3001).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_UNABLE_TO_DELIVER', 3002).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_REALM_NOT_SERVED', 3003).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_TOO_BUSY', 3004).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_LOOP_DETECTED', 3005).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_REDIRECT_INDICATION', 3006).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_APPLICATION_UNSUPPORTED', 3007).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_INVALID_HDR_BITS', 3008).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_INVALID_AVP_BITS', 3009).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_UNKNOWN_PEER', 3010).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_AUTHENTICATION_REJECTED', 4001).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_OUT_OF_SPACE', 4002).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_ELECTION_LOST', 4003).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_AVP_UNSUPPORTED', 5001).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_UNKNOWN_SESSION_ID', 5002).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_AUTHORIZATION_REJECTED', 5003).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_INVALID_AVP_VALUE', 5004).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_MISSING_AVP', 5005).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_RESOURCES_EXCEEDED', 5006).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_CONTRADICTING_AVPS', 5007).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_AVP_NOT_ALLOWED', 5008).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_AVP_OCCURS_TOO_MANY_TIMES', 5009).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_NO_COMMON_APPLICATION', 5010).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_UNSUPPORTED_VERSION', 5011).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_UNABLE_TO_COMPLY', 5012).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_INVALID_BIT_IN_HEADER', 5013).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_INVALID_AVP_LENGTH', 5014).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_INVALID_MESSAGE_LENGTH', 5015).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_INVALID_AVP_BIT_COMBO', 5016).
-define('DIAMETER_BASE_RESULT-CODE_DIAMETER_NO_COMMON_SECURITY', 5017).
-define('DIAMETER_BASE_TERMINATION-CAUSE_DIAMETER_LOGOUT', 1).
-define('DIAMETER_BASE_TERMINATION-CAUSE_DIAMETER_SERVICE_NOT_PROVIDED', 2).
-define('DIAMETER_BASE_TERMINATION-CAUSE_DIAMETER_BAD_ANSWER', 3).
-define('DIAMETER_BASE_TERMINATION-CAUSE_DIAMETER_ADMINISTRATIVE', 4).
-define('DIAMETER_BASE_TERMINATION-CAUSE_DIAMETER_LINK_BROKEN', 5).
-define('DIAMETER_BASE_TERMINATION-CAUSE_DIAMETER_AUTH_EXPIRED', 6).
-define('DIAMETER_BASE_TERMINATION-CAUSE_DIAMETER_USER_MOVED', 7).
-define('DIAMETER_BASE_TERMINATION-CAUSE_DIAMETER_SESSION_TIMEOUT', 8).

