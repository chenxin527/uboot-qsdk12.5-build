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

-hrl_name('diameter_gen_base_accounting.hrl').


%%% -------------------------------------------------------
%%% Message records:
%%% -------------------------------------------------------

-record(diameter_base_accounting_ACR,
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

-record(diameter_base_accounting_ACA,
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
%%% Grouped AVP records from diameter_gen_base_rfc3588:
%%% -------------------------------------------------------

-record('diameter_base_accounting_Proxy-Info',
	{'Proxy-Host', 'Proxy-State', 'AVP' = []}).

-record('diameter_base_accounting_Failed-AVP',
	{'AVP' = []}).

-record('diameter_base_accounting_Experimental-Result',
	{'Vendor-Id', 'Experimental-Result-Code'}).

-record('diameter_base_accounting_Vendor-Specific-Application-Id',
	{'Vendor-Id' = [], 'Auth-Application-Id' = [],
	 'Acct-Application-Id' = []}).

-record('diameter_base_accounting_E2E-Sequence',
	{'AVP' = []}).


%%% -------------------------------------------------------
%%% ENUM Macros from diameter_gen_base_rfc3588:
%%% -------------------------------------------------------

-ifndef('DIAMETER_BASE_ACCOUNTING_DISCONNECT-CAUSE_REBOOTING').
-define('DIAMETER_BASE_ACCOUNTING_DISCONNECT-CAUSE_REBOOTING', 0).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_DISCONNECT-CAUSE_BUSY').
-define('DIAMETER_BASE_ACCOUNTING_DISCONNECT-CAUSE_BUSY', 1).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_DISCONNECT-CAUSE_DO_NOT_WANT_TO_TALK_TO_YOU').
-define('DIAMETER_BASE_ACCOUNTING_DISCONNECT-CAUSE_DO_NOT_WANT_TO_TALK_TO_YOU', 2).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_DONT_CACHE').
-define('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_DONT_CACHE', 0).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_SESSION').
-define('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_SESSION', 1).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_REALM').
-define('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_REALM', 2).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_REALM_AND_APPLICATION').
-define('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_REALM_AND_APPLICATION', 3).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_APPLICATION').
-define('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_APPLICATION', 4).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_HOST').
-define('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_HOST', 5).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_USER').
-define('DIAMETER_BASE_ACCOUNTING_REDIRECT-HOST-USAGE_ALL_USER', 6).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_AUTH-REQUEST-TYPE_AUTHENTICATE_ONLY').
-define('DIAMETER_BASE_ACCOUNTING_AUTH-REQUEST-TYPE_AUTHENTICATE_ONLY', 1).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_AUTH-REQUEST-TYPE_AUTHORIZE_ONLY').
-define('DIAMETER_BASE_ACCOUNTING_AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 2).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE').
-define('DIAMETER_BASE_ACCOUNTING_AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 3).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_AUTH-SESSION-STATE_STATE_MAINTAINED').
-define('DIAMETER_BASE_ACCOUNTING_AUTH-SESSION-STATE_STATE_MAINTAINED', 0).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_AUTH-SESSION-STATE_NO_STATE_MAINTAINED').
-define('DIAMETER_BASE_ACCOUNTING_AUTH-SESSION-STATE_NO_STATE_MAINTAINED', 1).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY').
-define('DIAMETER_BASE_ACCOUNTING_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 0).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_RE-AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE').
-define('DIAMETER_BASE_ACCOUNTING_RE-AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 1).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_LOGOUT').
-define('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_LOGOUT', 1).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_SERVICE_NOT_PROVIDED').
-define('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_SERVICE_NOT_PROVIDED', 2).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_BAD_ANSWER').
-define('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_BAD_ANSWER', 3).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_ADMINISTRATIVE').
-define('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_ADMINISTRATIVE', 4).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_LINK_BROKEN').
-define('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_LINK_BROKEN', 5).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_AUTH_EXPIRED').
-define('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_AUTH_EXPIRED', 6).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_USER_MOVED').
-define('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_USER_MOVED', 7).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_SESSION_TIMEOUT').
-define('DIAMETER_BASE_ACCOUNTING_TERMINATION-CAUSE_SESSION_TIMEOUT', 8).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_SESSION-SERVER-FAILOVER_REFUSE_SERVICE').
-define('DIAMETER_BASE_ACCOUNTING_SESSION-SERVER-FAILOVER_REFUSE_SERVICE', 0).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_SESSION-SERVER-FAILOVER_TRY_AGAIN').
-define('DIAMETER_BASE_ACCOUNTING_SESSION-SERVER-FAILOVER_TRY_AGAIN', 1).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_SESSION-SERVER-FAILOVER_ALLOW_SERVICE').
-define('DIAMETER_BASE_ACCOUNTING_SESSION-SERVER-FAILOVER_ALLOW_SERVICE', 2).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_SESSION-SERVER-FAILOVER_TRY_AGAIN_ALLOW_SERVICE').
-define('DIAMETER_BASE_ACCOUNTING_SESSION-SERVER-FAILOVER_TRY_AGAIN_ALLOW_SERVICE', 3).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-RECORD-TYPE_EVENT_RECORD').
-define('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-RECORD-TYPE_EVENT_RECORD', 1).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-RECORD-TYPE_START_RECORD').
-define('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-RECORD-TYPE_START_RECORD', 2).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-RECORD-TYPE_INTERIM_RECORD').
-define('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-RECORD-TYPE_INTERIM_RECORD', 3).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-RECORD-TYPE_STOP_RECORD').
-define('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-RECORD-TYPE_STOP_RECORD', 4).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-REALTIME-REQUIRED_DELIVER_AND_GRANT').
-define('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-REALTIME-REQUIRED_DELIVER_AND_GRANT', 1).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_STORE').
-define('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_STORE', 2).
-endif.
-ifndef('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_LOSE').
-define('DIAMETER_BASE_ACCOUNTING_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_LOSE', 3).
-endif.

