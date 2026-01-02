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

-module(diameter_gen_base_rfc6733).

-compile({parse_transform, diameter_exprecs}).

-compile(nowarn_unused_function).

-export_records([diameter_base_CER, diameter_base_CEA,
		 diameter_base_DPR, diameter_base_DPA, diameter_base_DWR,
		 diameter_base_DWA, 'diameter_base_answer-message',
		 diameter_base_RAR, diameter_base_RAA, diameter_base_STR,
		 diameter_base_STA, diameter_base_ASR, diameter_base_ASA,
		 diameter_base_ACR, diameter_base_ACA,
		 'diameter_base_Proxy-Info', 'diameter_base_Failed-AVP',
		 'diameter_base_Experimental-Result',
		 'diameter_base_Vendor-Specific-Application-Id']).

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
	{'Origin-Host', 'Origin-Realm', 'Disconnect-Cause',
	 'AVP' = []}).

-record(diameter_base_DPA,
	{'Result-Code', 'Origin-Host', 'Origin-Realm',
	 'Error-Message' = [], 'Failed-AVP' = [], 'AVP' = []}).

-record(diameter_base_DWR,
	{'Origin-Host', 'Origin-Realm', 'Origin-State-Id' = [],
	 'AVP' = []}).

-record(diameter_base_DWA,
	{'Result-Code', 'Origin-Host', 'Origin-Realm',
	 'Error-Message' = [], 'Failed-AVP' = [],
	 'Origin-State-Id' = [], 'AVP' = []}).

-record('diameter_base_answer-message',
	{'Session-Id' = [], 'Origin-Host', 'Origin-Realm',
	 'Result-Code', 'Origin-State-Id' = [],
	 'Error-Message' = [], 'Error-Reporting-Host' = [],
	 'Failed-AVP' = [], 'Experimental-Result' = [],
	 'Proxy-Info' = [], 'AVP' = []}).

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
	 'Destination-Host' = [],
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
	 'Error-Message' = [], 'Error-Reporting-Host' = [],
	 'Failed-AVP' = [], 'Acct-Interim-Interval' = [],
	 'Accounting-Realtime-Required' = [],
	 'Origin-State-Id' = [], 'Event-Timestamp' = [],
	 'Proxy-Info' = [], 'AVP' = []}).

-record('diameter_base_Proxy-Info',
	{'Proxy-Host', 'Proxy-State', 'AVP' = []}).

-record('diameter_base_Failed-AVP', {'AVP' = []}).

-record('diameter_base_Experimental-Result',
	{'Vendor-Id', 'Experimental-Result-Code'}).

-record('diameter_base_Vendor-Specific-Application-Id',
	{'Vendor-Id', 'Auth-Application-Id' = [],
	 'Acct-Application-Id' = []}).

-export([name/0, id/0, vendor_id/0, vendor_name/0,
	 decode_avps/2, encode_avps/2, msg_name/2, msg_header/1,
	 rec2msg/1, msg2rec/1, name2rec/1, avp_name/2,
	 avp_arity/2, avp_header/1, avp/3, grouped_avp/3,
	 enumerated_avp/3, empty_value/1, dict/0]).

-include_lib("diameter/include/diameter.hrl").

-include_lib("diameter/include/diameter_gen.hrl").

name() -> diameter_gen_base_rfc6733.

id() -> 0.

vendor_id() -> 0.

vendor_name() -> 'IETF'.

msg_name(258, true) -> 'RAR';
msg_name(258, false) -> 'RAA';
msg_name(280, true) -> 'DWR';
msg_name(280, false) -> 'DWA';
msg_name(274, true) -> 'ASR';
msg_name(274, false) -> 'ASA';
msg_name(282, true) -> 'DPR';
msg_name(282, false) -> 'DPA';
msg_name(275, true) -> 'STR';
msg_name(275, false) -> 'STA';
msg_name(271, true) -> 'ACR';
msg_name(271, false) -> 'ACA';
msg_name(257, true) -> 'CER';
msg_name(257, false) -> 'CEA';
msg_name(_, _) -> ''.

msg_header('CER') -> {257, 128, 0};
msg_header('CEA') -> {257, 0, 0};
msg_header('DPR') -> {282, 128, 0};
msg_header('DPA') -> {282, 0, 0};
msg_header('DWR') -> {280, 128, 0};
msg_header('DWA') -> {280, 0, 0};
msg_header('answer-message') -> {-1, 96, 0};
msg_header('RAR') -> {258, 192, 0};
msg_header('RAA') -> {258, 64, 0};
msg_header('STR') -> {275, 192, 0};
msg_header('STA') -> {275, 64, 0};
msg_header('ASR') -> {274, 192, 0};
msg_header('ASA') -> {274, 64, 0};
msg_header('ACR') -> {271, 192, 0};
msg_header('ACA') -> {271, 64, 0};
msg_header(_) -> erlang:error(badarg).

rec2msg(diameter_base_CER) -> 'CER';
rec2msg(diameter_base_CEA) -> 'CEA';
rec2msg(diameter_base_DPR) -> 'DPR';
rec2msg(diameter_base_DPA) -> 'DPA';
rec2msg(diameter_base_DWR) -> 'DWR';
rec2msg(diameter_base_DWA) -> 'DWA';
rec2msg('diameter_base_answer-message') ->
    'answer-message';
rec2msg(diameter_base_RAR) -> 'RAR';
rec2msg(diameter_base_RAA) -> 'RAA';
rec2msg(diameter_base_STR) -> 'STR';
rec2msg(diameter_base_STA) -> 'STA';
rec2msg(diameter_base_ASR) -> 'ASR';
rec2msg(diameter_base_ASA) -> 'ASA';
rec2msg(diameter_base_ACR) -> 'ACR';
rec2msg(diameter_base_ACA) -> 'ACA';
rec2msg(_) -> erlang:error(badarg).

msg2rec('CER') -> diameter_base_CER;
msg2rec('CEA') -> diameter_base_CEA;
msg2rec('DPR') -> diameter_base_DPR;
msg2rec('DPA') -> diameter_base_DPA;
msg2rec('DWR') -> diameter_base_DWR;
msg2rec('DWA') -> diameter_base_DWA;
msg2rec('answer-message') ->
    'diameter_base_answer-message';
msg2rec('RAR') -> diameter_base_RAR;
msg2rec('RAA') -> diameter_base_RAA;
msg2rec('STR') -> diameter_base_STR;
msg2rec('STA') -> diameter_base_STA;
msg2rec('ASR') -> diameter_base_ASR;
msg2rec('ASA') -> diameter_base_ASA;
msg2rec('ACR') -> diameter_base_ACR;
msg2rec('ACA') -> diameter_base_ACA;
msg2rec(_) -> erlang:error(badarg).

name2rec('Proxy-Info') -> 'diameter_base_Proxy-Info';
name2rec('Failed-AVP') -> 'diameter_base_Failed-AVP';
name2rec('Experimental-Result') ->
    'diameter_base_Experimental-Result';
name2rec('Vendor-Specific-Application-Id') ->
    'diameter_base_Vendor-Specific-Application-Id';
name2rec(T) -> msg2rec(T).

avp_name(483, undefined) ->
    {'Accounting-Realtime-Required', 'Enumerated'};
avp_name(485, undefined) ->
    {'Accounting-Record-Number', 'Unsigned32'};
avp_name(480, undefined) ->
    {'Accounting-Record-Type', 'Enumerated'};
avp_name(287, undefined) ->
    {'Accounting-Sub-Session-Id', 'Unsigned64'};
avp_name(259, undefined) ->
    {'Acct-Application-Id', 'Unsigned32'};
avp_name(85, undefined) ->
    {'Acct-Interim-Interval', 'Unsigned32'};
avp_name(50, undefined) ->
    {'Acct-Multi-Session-Id', 'UTF8String'};
avp_name(44, undefined) ->
    {'Acct-Session-Id', 'OctetString'};
avp_name(258, undefined) ->
    {'Auth-Application-Id', 'Unsigned32'};
avp_name(276, undefined) ->
    {'Auth-Grace-Period', 'Unsigned32'};
avp_name(274, undefined) ->
    {'Auth-Request-Type', 'Enumerated'};
avp_name(277, undefined) ->
    {'Auth-Session-State', 'Enumerated'};
avp_name(291, undefined) ->
    {'Authorization-Lifetime', 'Unsigned32'};
avp_name(25, undefined) -> {'Class', 'OctetString'};
avp_name(293, undefined) ->
    {'Destination-Host', 'DiameterIdentity'};
avp_name(283, undefined) ->
    {'Destination-Realm', 'DiameterIdentity'};
avp_name(273, undefined) ->
    {'Disconnect-Cause', 'Enumerated'};
avp_name(281, undefined) ->
    {'Error-Message', 'UTF8String'};
avp_name(294, undefined) ->
    {'Error-Reporting-Host', 'DiameterIdentity'};
avp_name(55, undefined) -> {'Event-Timestamp', 'Time'};
avp_name(297, undefined) ->
    {'Experimental-Result', 'Grouped'};
avp_name(298, undefined) ->
    {'Experimental-Result-Code', 'Unsigned32'};
avp_name(279, undefined) -> {'Failed-AVP', 'Grouped'};
avp_name(267, undefined) ->
    {'Firmware-Revision', 'Unsigned32'};
avp_name(257, undefined) ->
    {'Host-IP-Address', 'Address'};
avp_name(299, undefined) ->
    {'Inband-Security-Id', 'Unsigned32'};
avp_name(272, undefined) ->
    {'Multi-Round-Time-Out', 'Unsigned32'};
avp_name(264, undefined) ->
    {'Origin-Host', 'DiameterIdentity'};
avp_name(296, undefined) ->
    {'Origin-Realm', 'DiameterIdentity'};
avp_name(278, undefined) ->
    {'Origin-State-Id', 'Unsigned32'};
avp_name(269, undefined) ->
    {'Product-Name', 'UTF8String'};
avp_name(280, undefined) ->
    {'Proxy-Host', 'DiameterIdentity'};
avp_name(284, undefined) -> {'Proxy-Info', 'Grouped'};
avp_name(33, undefined) ->
    {'Proxy-State', 'OctetString'};
avp_name(285, undefined) ->
    {'Re-Auth-Request-Type', 'Enumerated'};
avp_name(292, undefined) ->
    {'Redirect-Host', 'DiameterURI'};
avp_name(261, undefined) ->
    {'Redirect-Host-Usage', 'Enumerated'};
avp_name(262, undefined) ->
    {'Redirect-Max-Cache-Time', 'Unsigned32'};
avp_name(268, undefined) ->
    {'Result-Code', 'Unsigned32'};
avp_name(282, undefined) ->
    {'Route-Record', 'DiameterIdentity'};
avp_name(270, undefined) ->
    {'Session-Binding', 'Unsigned32'};
avp_name(263, undefined) ->
    {'Session-Id', 'UTF8String'};
avp_name(271, undefined) ->
    {'Session-Server-Failover', 'Enumerated'};
avp_name(27, undefined) ->
    {'Session-Timeout', 'Unsigned32'};
avp_name(265, undefined) ->
    {'Supported-Vendor-Id', 'Unsigned32'};
avp_name(295, undefined) ->
    {'Termination-Cause', 'Enumerated'};
avp_name(1, undefined) -> {'User-Name', 'UTF8String'};
avp_name(266, undefined) -> {'Vendor-Id', 'Unsigned32'};
avp_name(260, undefined) ->
    {'Vendor-Specific-Application-Id', 'Grouped'};
avp_name(_, _) -> 'AVP'.

avp_arity('CER', 'Origin-Host') -> 1;
avp_arity('CER', 'Origin-Realm') -> 1;
avp_arity('CER', 'Host-IP-Address') -> {1, '*'};
avp_arity('CER', 'Vendor-Id') -> 1;
avp_arity('CER', 'Product-Name') -> 1;
avp_arity('CER', 'Origin-State-Id') -> {0, 1};
avp_arity('CER', 'Supported-Vendor-Id') -> {0, '*'};
avp_arity('CER', 'Auth-Application-Id') -> {0, '*'};
avp_arity('CER', 'Inband-Security-Id') -> {0, '*'};
avp_arity('CER', 'Acct-Application-Id') -> {0, '*'};
avp_arity('CER', 'Vendor-Specific-Application-Id') ->
    {0, '*'};
avp_arity('CER', 'Firmware-Revision') -> {0, 1};
avp_arity('CER', 'AVP') -> {0, '*'};
avp_arity('CEA', 'Result-Code') -> 1;
avp_arity('CEA', 'Origin-Host') -> 1;
avp_arity('CEA', 'Origin-Realm') -> 1;
avp_arity('CEA', 'Host-IP-Address') -> {1, '*'};
avp_arity('CEA', 'Vendor-Id') -> 1;
avp_arity('CEA', 'Product-Name') -> 1;
avp_arity('CEA', 'Origin-State-Id') -> {0, 1};
avp_arity('CEA', 'Error-Message') -> {0, 1};
avp_arity('CEA', 'Failed-AVP') -> {0, 1};
avp_arity('CEA', 'Supported-Vendor-Id') -> {0, '*'};
avp_arity('CEA', 'Auth-Application-Id') -> {0, '*'};
avp_arity('CEA', 'Inband-Security-Id') -> {0, '*'};
avp_arity('CEA', 'Acct-Application-Id') -> {0, '*'};
avp_arity('CEA', 'Vendor-Specific-Application-Id') ->
    {0, '*'};
avp_arity('CEA', 'Firmware-Revision') -> {0, 1};
avp_arity('CEA', 'AVP') -> {0, '*'};
avp_arity('DPR', 'Origin-Host') -> 1;
avp_arity('DPR', 'Origin-Realm') -> 1;
avp_arity('DPR', 'Disconnect-Cause') -> 1;
avp_arity('DPR', 'AVP') -> {0, '*'};
avp_arity('DPA', 'Result-Code') -> 1;
avp_arity('DPA', 'Origin-Host') -> 1;
avp_arity('DPA', 'Origin-Realm') -> 1;
avp_arity('DPA', 'Error-Message') -> {0, 1};
avp_arity('DPA', 'Failed-AVP') -> {0, 1};
avp_arity('DPA', 'AVP') -> {0, '*'};
avp_arity('DWR', 'Origin-Host') -> 1;
avp_arity('DWR', 'Origin-Realm') -> 1;
avp_arity('DWR', 'Origin-State-Id') -> {0, 1};
avp_arity('DWR', 'AVP') -> {0, '*'};
avp_arity('DWA', 'Result-Code') -> 1;
avp_arity('DWA', 'Origin-Host') -> 1;
avp_arity('DWA', 'Origin-Realm') -> 1;
avp_arity('DWA', 'Error-Message') -> {0, 1};
avp_arity('DWA', 'Failed-AVP') -> {0, 1};
avp_arity('DWA', 'Origin-State-Id') -> {0, 1};
avp_arity('DWA', 'AVP') -> {0, '*'};
avp_arity('answer-message', 'Session-Id') -> {0, 1};
avp_arity('answer-message', 'Origin-Host') -> 1;
avp_arity('answer-message', 'Origin-Realm') -> 1;
avp_arity('answer-message', 'Result-Code') -> 1;
avp_arity('answer-message', 'Origin-State-Id') ->
    {0, 1};
avp_arity('answer-message', 'Error-Message') -> {0, 1};
avp_arity('answer-message', 'Error-Reporting-Host') ->
    {0, 1};
avp_arity('answer-message', 'Failed-AVP') -> {0, 1};
avp_arity('answer-message', 'Experimental-Result') ->
    {0, 1};
avp_arity('answer-message', 'Proxy-Info') -> {0, '*'};
avp_arity('answer-message', 'AVP') -> {0, '*'};
avp_arity('RAR', 'Session-Id') -> 1;
avp_arity('RAR', 'Origin-Host') -> 1;
avp_arity('RAR', 'Origin-Realm') -> 1;
avp_arity('RAR', 'Destination-Realm') -> 1;
avp_arity('RAR', 'Destination-Host') -> 1;
avp_arity('RAR', 'Auth-Application-Id') -> 1;
avp_arity('RAR', 'Re-Auth-Request-Type') -> 1;
avp_arity('RAR', 'User-Name') -> {0, 1};
avp_arity('RAR', 'Origin-State-Id') -> {0, 1};
avp_arity('RAR', 'Proxy-Info') -> {0, '*'};
avp_arity('RAR', 'Route-Record') -> {0, '*'};
avp_arity('RAR', 'AVP') -> {0, '*'};
avp_arity('RAA', 'Session-Id') -> 1;
avp_arity('RAA', 'Result-Code') -> 1;
avp_arity('RAA', 'Origin-Host') -> 1;
avp_arity('RAA', 'Origin-Realm') -> 1;
avp_arity('RAA', 'User-Name') -> {0, 1};
avp_arity('RAA', 'Origin-State-Id') -> {0, 1};
avp_arity('RAA', 'Error-Message') -> {0, 1};
avp_arity('RAA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('RAA', 'Failed-AVP') -> {0, 1};
avp_arity('RAA', 'Redirect-Host') -> {0, '*'};
avp_arity('RAA', 'Redirect-Host-Usage') -> {0, 1};
avp_arity('RAA', 'Redirect-Max-Cache-Time') -> {0, 1};
avp_arity('RAA', 'Proxy-Info') -> {0, '*'};
avp_arity('RAA', 'AVP') -> {0, '*'};
avp_arity('STR', 'Session-Id') -> 1;
avp_arity('STR', 'Origin-Host') -> 1;
avp_arity('STR', 'Origin-Realm') -> 1;
avp_arity('STR', 'Destination-Realm') -> 1;
avp_arity('STR', 'Auth-Application-Id') -> 1;
avp_arity('STR', 'Termination-Cause') -> 1;
avp_arity('STR', 'User-Name') -> {0, 1};
avp_arity('STR', 'Destination-Host') -> {0, 1};
avp_arity('STR', 'Class') -> {0, '*'};
avp_arity('STR', 'Origin-State-Id') -> {0, 1};
avp_arity('STR', 'Proxy-Info') -> {0, '*'};
avp_arity('STR', 'Route-Record') -> {0, '*'};
avp_arity('STR', 'AVP') -> {0, '*'};
avp_arity('STA', 'Session-Id') -> 1;
avp_arity('STA', 'Result-Code') -> 1;
avp_arity('STA', 'Origin-Host') -> 1;
avp_arity('STA', 'Origin-Realm') -> 1;
avp_arity('STA', 'User-Name') -> {0, 1};
avp_arity('STA', 'Class') -> {0, '*'};
avp_arity('STA', 'Error-Message') -> {0, 1};
avp_arity('STA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('STA', 'Failed-AVP') -> {0, 1};
avp_arity('STA', 'Origin-State-Id') -> {0, 1};
avp_arity('STA', 'Redirect-Host') -> {0, '*'};
avp_arity('STA', 'Redirect-Host-Usage') -> {0, 1};
avp_arity('STA', 'Redirect-Max-Cache-Time') -> {0, 1};
avp_arity('STA', 'Proxy-Info') -> {0, '*'};
avp_arity('STA', 'AVP') -> {0, '*'};
avp_arity('ASR', 'Session-Id') -> 1;
avp_arity('ASR', 'Origin-Host') -> 1;
avp_arity('ASR', 'Origin-Realm') -> 1;
avp_arity('ASR', 'Destination-Realm') -> 1;
avp_arity('ASR', 'Destination-Host') -> 1;
avp_arity('ASR', 'Auth-Application-Id') -> 1;
avp_arity('ASR', 'User-Name') -> {0, 1};
avp_arity('ASR', 'Origin-State-Id') -> {0, 1};
avp_arity('ASR', 'Proxy-Info') -> {0, '*'};
avp_arity('ASR', 'Route-Record') -> {0, '*'};
avp_arity('ASR', 'AVP') -> {0, '*'};
avp_arity('ASA', 'Session-Id') -> 1;
avp_arity('ASA', 'Result-Code') -> 1;
avp_arity('ASA', 'Origin-Host') -> 1;
avp_arity('ASA', 'Origin-Realm') -> 1;
avp_arity('ASA', 'User-Name') -> {0, 1};
avp_arity('ASA', 'Origin-State-Id') -> {0, 1};
avp_arity('ASA', 'Error-Message') -> {0, 1};
avp_arity('ASA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('ASA', 'Failed-AVP') -> {0, 1};
avp_arity('ASA', 'Redirect-Host') -> {0, '*'};
avp_arity('ASA', 'Redirect-Host-Usage') -> {0, 1};
avp_arity('ASA', 'Redirect-Max-Cache-Time') -> {0, 1};
avp_arity('ASA', 'Proxy-Info') -> {0, '*'};
avp_arity('ASA', 'AVP') -> {0, '*'};
avp_arity('ACR', 'Session-Id') -> 1;
avp_arity('ACR', 'Origin-Host') -> 1;
avp_arity('ACR', 'Origin-Realm') -> 1;
avp_arity('ACR', 'Destination-Realm') -> 1;
avp_arity('ACR', 'Accounting-Record-Type') -> 1;
avp_arity('ACR', 'Accounting-Record-Number') -> 1;
avp_arity('ACR', 'Acct-Application-Id') -> {0, 1};
avp_arity('ACR', 'Vendor-Specific-Application-Id') ->
    {0, 1};
avp_arity('ACR', 'User-Name') -> {0, 1};
avp_arity('ACR', 'Destination-Host') -> {0, 1};
avp_arity('ACR', 'Accounting-Sub-Session-Id') -> {0, 1};
avp_arity('ACR', 'Acct-Session-Id') -> {0, 1};
avp_arity('ACR', 'Acct-Multi-Session-Id') -> {0, 1};
avp_arity('ACR', 'Acct-Interim-Interval') -> {0, 1};
avp_arity('ACR', 'Accounting-Realtime-Required') ->
    {0, 1};
avp_arity('ACR', 'Origin-State-Id') -> {0, 1};
avp_arity('ACR', 'Event-Timestamp') -> {0, 1};
avp_arity('ACR', 'Proxy-Info') -> {0, '*'};
avp_arity('ACR', 'Route-Record') -> {0, '*'};
avp_arity('ACR', 'AVP') -> {0, '*'};
avp_arity('ACA', 'Session-Id') -> 1;
avp_arity('ACA', 'Result-Code') -> 1;
avp_arity('ACA', 'Origin-Host') -> 1;
avp_arity('ACA', 'Origin-Realm') -> 1;
avp_arity('ACA', 'Accounting-Record-Type') -> 1;
avp_arity('ACA', 'Accounting-Record-Number') -> 1;
avp_arity('ACA', 'Acct-Application-Id') -> {0, 1};
avp_arity('ACA', 'Vendor-Specific-Application-Id') ->
    {0, 1};
avp_arity('ACA', 'User-Name') -> {0, 1};
avp_arity('ACA', 'Accounting-Sub-Session-Id') -> {0, 1};
avp_arity('ACA', 'Acct-Session-Id') -> {0, 1};
avp_arity('ACA', 'Acct-Multi-Session-Id') -> {0, 1};
avp_arity('ACA', 'Error-Message') -> {0, 1};
avp_arity('ACA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('ACA', 'Failed-AVP') -> {0, 1};
avp_arity('ACA', 'Acct-Interim-Interval') -> {0, 1};
avp_arity('ACA', 'Accounting-Realtime-Required') ->
    {0, 1};
avp_arity('ACA', 'Origin-State-Id') -> {0, 1};
avp_arity('ACA', 'Event-Timestamp') -> {0, 1};
avp_arity('ACA', 'Proxy-Info') -> {0, '*'};
avp_arity('ACA', 'AVP') -> {0, '*'};
avp_arity('Proxy-Info', 'Proxy-Host') -> 1;
avp_arity('Proxy-Info', 'Proxy-State') -> 1;
avp_arity('Proxy-Info', 'AVP') -> {0, '*'};
avp_arity('Failed-AVP', 'AVP') -> {1, '*'};
avp_arity('Experimental-Result', 'Vendor-Id') -> 1;
avp_arity('Experimental-Result',
	  'Experimental-Result-Code') ->
    1;
avp_arity('Vendor-Specific-Application-Id',
	  'Vendor-Id') ->
    1;
avp_arity('Vendor-Specific-Application-Id',
	  'Auth-Application-Id') ->
    {0, 1};
avp_arity('Vendor-Specific-Application-Id',
	  'Acct-Application-Id') ->
    {0, 1};
avp_arity(_, _) -> 0.

avp_header('Accounting-Realtime-Required') ->
    {483, 64, undefined};
avp_header('Accounting-Record-Number') ->
    {485, 64, undefined};
avp_header('Accounting-Record-Type') ->
    {480, 64, undefined};
avp_header('Accounting-Sub-Session-Id') ->
    {287, 64, undefined};
avp_header('Acct-Application-Id') ->
    {259, 64, undefined};
avp_header('Acct-Interim-Interval') ->
    {85, 64, undefined};
avp_header('Acct-Multi-Session-Id') ->
    {50, 64, undefined};
avp_header('Acct-Session-Id') -> {44, 64, undefined};
avp_header('Auth-Application-Id') ->
    {258, 64, undefined};
avp_header('Auth-Grace-Period') -> {276, 64, undefined};
avp_header('Auth-Request-Type') -> {274, 64, undefined};
avp_header('Auth-Session-State') ->
    {277, 64, undefined};
avp_header('Authorization-Lifetime') ->
    {291, 64, undefined};
avp_header('Class') -> {25, 64, undefined};
avp_header('Destination-Host') -> {293, 64, undefined};
avp_header('Destination-Realm') -> {283, 64, undefined};
avp_header('Disconnect-Cause') -> {273, 64, undefined};
avp_header('Error-Message') -> {281, 0, undefined};
avp_header('Error-Reporting-Host') ->
    {294, 0, undefined};
avp_header('Event-Timestamp') -> {55, 64, undefined};
avp_header('Experimental-Result') ->
    {297, 64, undefined};
avp_header('Experimental-Result-Code') ->
    {298, 64, undefined};
avp_header('Failed-AVP') -> {279, 64, undefined};
avp_header('Firmware-Revision') -> {267, 0, undefined};
avp_header('Host-IP-Address') -> {257, 64, undefined};
avp_header('Inband-Security-Id') ->
    {299, 64, undefined};
avp_header('Multi-Round-Time-Out') ->
    {272, 64, undefined};
avp_header('Origin-Host') -> {264, 64, undefined};
avp_header('Origin-Realm') -> {296, 64, undefined};
avp_header('Origin-State-Id') -> {278, 64, undefined};
avp_header('Product-Name') -> {269, 0, undefined};
avp_header('Proxy-Host') -> {280, 64, undefined};
avp_header('Proxy-Info') -> {284, 64, undefined};
avp_header('Proxy-State') -> {33, 64, undefined};
avp_header('Re-Auth-Request-Type') ->
    {285, 64, undefined};
avp_header('Redirect-Host') -> {292, 64, undefined};
avp_header('Redirect-Host-Usage') ->
    {261, 64, undefined};
avp_header('Redirect-Max-Cache-Time') ->
    {262, 64, undefined};
avp_header('Result-Code') -> {268, 64, undefined};
avp_header('Route-Record') -> {282, 64, undefined};
avp_header('Session-Binding') -> {270, 64, undefined};
avp_header('Session-Id') -> {263, 64, undefined};
avp_header('Session-Server-Failover') ->
    {271, 64, undefined};
avp_header('Session-Timeout') -> {27, 64, undefined};
avp_header('Supported-Vendor-Id') ->
    {265, 64, undefined};
avp_header('Termination-Cause') -> {295, 64, undefined};
avp_header('User-Name') -> {1, 64, undefined};
avp_header('Vendor-Id') -> {266, 64, undefined};
avp_header('Vendor-Specific-Application-Id') ->
    {260, 64, undefined};
avp_header(_) -> erlang:error(badarg).

avp(T, Data, 'Accounting-Realtime-Required') ->
    enumerated_avp(T, 'Accounting-Realtime-Required', Data);
avp(T, Data, 'Accounting-Record-Number') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Accounting-Record-Type') ->
    enumerated_avp(T, 'Accounting-Record-Type', Data);
avp(T, Data, 'Accounting-Sub-Session-Id') ->
    diameter_types:'Unsigned64'(T, Data);
avp(T, Data, 'Acct-Application-Id') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Acct-Interim-Interval') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Acct-Multi-Session-Id') ->
    diameter_types:'UTF8String'(T, Data);
avp(T, Data, 'Acct-Session-Id') ->
    diameter_types:'OctetString'(T, Data);
avp(T, Data, 'Auth-Application-Id') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Auth-Grace-Period') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Auth-Request-Type') ->
    enumerated_avp(T, 'Auth-Request-Type', Data);
avp(T, Data, 'Auth-Session-State') ->
    enumerated_avp(T, 'Auth-Session-State', Data);
avp(T, Data, 'Authorization-Lifetime') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Class') ->
    diameter_types:'OctetString'(T, Data);
avp(T, Data, 'Destination-Host') ->
    diameter_types:'DiameterIdentity'(T, Data);
avp(T, Data, 'Destination-Realm') ->
    diameter_types:'DiameterIdentity'(T, Data);
avp(T, Data, 'Disconnect-Cause') ->
    enumerated_avp(T, 'Disconnect-Cause', Data);
avp(T, Data, 'Error-Message') ->
    diameter_types:'UTF8String'(T, Data);
avp(T, Data, 'Error-Reporting-Host') ->
    diameter_types:'DiameterIdentity'(T, Data);
avp(T, Data, 'Event-Timestamp') ->
    diameter_types:'Time'(T, Data);
avp(T, Data, 'Experimental-Result') ->
    grouped_avp(T, 'Experimental-Result', Data);
avp(T, Data, 'Experimental-Result-Code') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Failed-AVP') ->
    grouped_avp(T, 'Failed-AVP', Data);
avp(T, Data, 'Firmware-Revision') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Host-IP-Address') ->
    diameter_types:'Address'(T, Data);
avp(T, Data, 'Inband-Security-Id') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Multi-Round-Time-Out') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Origin-Host') ->
    diameter_types:'DiameterIdentity'(T, Data);
avp(T, Data, 'Origin-Realm') ->
    diameter_types:'DiameterIdentity'(T, Data);
avp(T, Data, 'Origin-State-Id') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Product-Name') ->
    diameter_types:'UTF8String'(T, Data);
avp(T, Data, 'Proxy-Host') ->
    diameter_types:'DiameterIdentity'(T, Data);
avp(T, Data, 'Proxy-Info') ->
    grouped_avp(T, 'Proxy-Info', Data);
avp(T, Data, 'Proxy-State') ->
    diameter_types:'OctetString'(T, Data);
avp(T, Data, 'Re-Auth-Request-Type') ->
    enumerated_avp(T, 'Re-Auth-Request-Type', Data);
avp(T, Data, 'Redirect-Host') ->
    diameter_types:'DiameterURI'(T, Data);
avp(T, Data, 'Redirect-Host-Usage') ->
    enumerated_avp(T, 'Redirect-Host-Usage', Data);
avp(T, Data, 'Redirect-Max-Cache-Time') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Result-Code') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Route-Record') ->
    diameter_types:'DiameterIdentity'(T, Data);
avp(T, Data, 'Session-Binding') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Session-Id') ->
    diameter_types:'UTF8String'(T, Data);
avp(T, Data, 'Session-Server-Failover') ->
    enumerated_avp(T, 'Session-Server-Failover', Data);
avp(T, Data, 'Session-Timeout') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Supported-Vendor-Id') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Termination-Cause') ->
    enumerated_avp(T, 'Termination-Cause', Data);
avp(T, Data, 'User-Name') ->
    diameter_types:'UTF8String'(T, Data);
avp(T, Data, 'Vendor-Id') ->
    diameter_types:'Unsigned32'(T, Data);
avp(T, Data, 'Vendor-Specific-Application-Id') ->
    grouped_avp(T, 'Vendor-Specific-Application-Id', Data);
avp(_, _, _) -> erlang:error(badarg).

enumerated_avp(decode, 'Disconnect-Cause',
	       <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'Disconnect-Cause', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'Disconnect-Cause',
	       <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Disconnect-Cause', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Disconnect-Cause',
	       <<0, 0, 0, 2>>) ->
    2;
enumerated_avp(encode, 'Disconnect-Cause', 2) ->
    <<0, 0, 0, 2>>;
enumerated_avp(decode, 'Redirect-Host-Usage',
	       <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'Redirect-Host-Usage', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'Redirect-Host-Usage',
	       <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Redirect-Host-Usage', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Redirect-Host-Usage',
	       <<0, 0, 0, 2>>) ->
    2;
enumerated_avp(encode, 'Redirect-Host-Usage', 2) ->
    <<0, 0, 0, 2>>;
enumerated_avp(decode, 'Redirect-Host-Usage',
	       <<0, 0, 0, 3>>) ->
    3;
enumerated_avp(encode, 'Redirect-Host-Usage', 3) ->
    <<0, 0, 0, 3>>;
enumerated_avp(decode, 'Redirect-Host-Usage',
	       <<0, 0, 0, 4>>) ->
    4;
enumerated_avp(encode, 'Redirect-Host-Usage', 4) ->
    <<0, 0, 0, 4>>;
enumerated_avp(decode, 'Redirect-Host-Usage',
	       <<0, 0, 0, 5>>) ->
    5;
enumerated_avp(encode, 'Redirect-Host-Usage', 5) ->
    <<0, 0, 0, 5>>;
enumerated_avp(decode, 'Redirect-Host-Usage',
	       <<0, 0, 0, 6>>) ->
    6;
enumerated_avp(encode, 'Redirect-Host-Usage', 6) ->
    <<0, 0, 0, 6>>;
enumerated_avp(decode, 'Auth-Request-Type',
	       <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Auth-Request-Type', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Auth-Request-Type',
	       <<0, 0, 0, 2>>) ->
    2;
enumerated_avp(encode, 'Auth-Request-Type', 2) ->
    <<0, 0, 0, 2>>;
enumerated_avp(decode, 'Auth-Request-Type',
	       <<0, 0, 0, 3>>) ->
    3;
enumerated_avp(encode, 'Auth-Request-Type', 3) ->
    <<0, 0, 0, 3>>;
enumerated_avp(decode, 'Auth-Session-State',
	       <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'Auth-Session-State', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'Auth-Session-State',
	       <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Auth-Session-State', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Re-Auth-Request-Type',
	       <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'Re-Auth-Request-Type', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'Re-Auth-Request-Type',
	       <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Re-Auth-Request-Type', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Termination-Cause',
	       <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Termination-Cause', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Termination-Cause',
	       <<0, 0, 0, 2>>) ->
    2;
enumerated_avp(encode, 'Termination-Cause', 2) ->
    <<0, 0, 0, 2>>;
enumerated_avp(decode, 'Termination-Cause',
	       <<0, 0, 0, 3>>) ->
    3;
enumerated_avp(encode, 'Termination-Cause', 3) ->
    <<0, 0, 0, 3>>;
enumerated_avp(decode, 'Termination-Cause',
	       <<0, 0, 0, 4>>) ->
    4;
enumerated_avp(encode, 'Termination-Cause', 4) ->
    <<0, 0, 0, 4>>;
enumerated_avp(decode, 'Termination-Cause',
	       <<0, 0, 0, 5>>) ->
    5;
enumerated_avp(encode, 'Termination-Cause', 5) ->
    <<0, 0, 0, 5>>;
enumerated_avp(decode, 'Termination-Cause',
	       <<0, 0, 0, 6>>) ->
    6;
enumerated_avp(encode, 'Termination-Cause', 6) ->
    <<0, 0, 0, 6>>;
enumerated_avp(decode, 'Termination-Cause',
	       <<0, 0, 0, 7>>) ->
    7;
enumerated_avp(encode, 'Termination-Cause', 7) ->
    <<0, 0, 0, 7>>;
enumerated_avp(decode, 'Termination-Cause',
	       <<0, 0, 0, 8>>) ->
    8;
enumerated_avp(encode, 'Termination-Cause', 8) ->
    <<0, 0, 0, 8>>;
enumerated_avp(decode, 'Session-Server-Failover',
	       <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'Session-Server-Failover', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'Session-Server-Failover',
	       <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Session-Server-Failover', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Session-Server-Failover',
	       <<0, 0, 0, 2>>) ->
    2;
enumerated_avp(encode, 'Session-Server-Failover', 2) ->
    <<0, 0, 0, 2>>;
enumerated_avp(decode, 'Session-Server-Failover',
	       <<0, 0, 0, 3>>) ->
    3;
enumerated_avp(encode, 'Session-Server-Failover', 3) ->
    <<0, 0, 0, 3>>;
enumerated_avp(decode, 'Accounting-Record-Type',
	       <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Accounting-Record-Type', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Accounting-Record-Type',
	       <<0, 0, 0, 2>>) ->
    2;
enumerated_avp(encode, 'Accounting-Record-Type', 2) ->
    <<0, 0, 0, 2>>;
enumerated_avp(decode, 'Accounting-Record-Type',
	       <<0, 0, 0, 3>>) ->
    3;
enumerated_avp(encode, 'Accounting-Record-Type', 3) ->
    <<0, 0, 0, 3>>;
enumerated_avp(decode, 'Accounting-Record-Type',
	       <<0, 0, 0, 4>>) ->
    4;
enumerated_avp(encode, 'Accounting-Record-Type', 4) ->
    <<0, 0, 0, 4>>;
enumerated_avp(decode, 'Accounting-Realtime-Required',
	       <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Accounting-Realtime-Required',
	       1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Accounting-Realtime-Required',
	       <<0, 0, 0, 2>>) ->
    2;
enumerated_avp(encode, 'Accounting-Realtime-Required',
	       2) ->
    <<0, 0, 0, 2>>;
enumerated_avp(decode, 'Accounting-Realtime-Required',
	       <<0, 0, 0, 3>>) ->
    3;
enumerated_avp(encode, 'Accounting-Realtime-Required',
	       3) ->
    <<0, 0, 0, 3>>;
enumerated_avp(_, _, _) -> erlang:error(badarg).

empty_value('Proxy-Info') -> empty_group('Proxy-Info');
empty_value('Failed-AVP') -> empty_group('Failed-AVP');
empty_value('Experimental-Result') ->
    empty_group('Experimental-Result');
empty_value('Vendor-Specific-Application-Id') ->
    empty_group('Vendor-Specific-Application-Id');
empty_value('Disconnect-Cause') -> <<0, 0, 0, 0>>;
empty_value('Redirect-Host-Usage') -> <<0, 0, 0, 0>>;
empty_value('Auth-Request-Type') -> <<0, 0, 0, 0>>;
empty_value('Auth-Session-State') -> <<0, 0, 0, 0>>;
empty_value('Re-Auth-Request-Type') -> <<0, 0, 0, 0>>;
empty_value('Termination-Cause') -> <<0, 0, 0, 0>>;
empty_value('Session-Server-Failover') ->
    <<0, 0, 0, 0>>;
empty_value('Accounting-Record-Type') -> <<0, 0, 0, 0>>;
empty_value('Accounting-Realtime-Required') ->
    <<0, 0, 0, 0>>;
empty_value(Name) -> empty(Name).

dict() ->
    [1,
     {avp_types,
      [{"Accounting-Realtime-Required", 483, "Enumerated",
	"M"},
       {"Accounting-Record-Number", 485, "Unsigned32", "M"},
       {"Accounting-Record-Type", 480, "Enumerated", "M"},
       {"Accounting-Sub-Session-Id", 287, "Unsigned64", "M"},
       {"Acct-Application-Id", 259, "Unsigned32", "M"},
       {"Acct-Interim-Interval", 85, "Unsigned32", "M"},
       {"Acct-Multi-Session-Id", 50, "UTF8String", "M"},
       {"Acct-Session-Id", 44, "OctetString", "M"},
       {"Auth-Application-Id", 258, "Unsigned32", "M"},
       {"Auth-Grace-Period", 276, "Unsigned32", "M"},
       {"Auth-Request-Type", 274, "Enumerated", "M"},
       {"Auth-Session-State", 277, "Enumerated", "M"},
       {"Authorization-Lifetime", 291, "Unsigned32", "M"},
       {"Class", 25, "OctetString", "M"},
       {"Destination-Host", 293, "DiameterIdentity", "M"},
       {"Destination-Realm", 283, "DiameterIdentity", "M"},
       {"Disconnect-Cause", 273, "Enumerated", "M"},
       {"Error-Message", 281, "UTF8String", []},
       {"Error-Reporting-Host", 294, "DiameterIdentity", []},
       {"Event-Timestamp", 55, "Time", "M"},
       {"Experimental-Result", 297, "Grouped", "M"},
       {"Experimental-Result-Code", 298, "Unsigned32", "M"},
       {"Failed-AVP", 279, "Grouped", "M"},
       {"Firmware-Revision", 267, "Unsigned32", []},
       {"Host-IP-Address", 257, "Address", "M"},
       {"Inband-Security-Id", 299, "Unsigned32", "M"},
       {"Multi-Round-Time-Out", 272, "Unsigned32", "M"},
       {"Origin-Host", 264, "DiameterIdentity", "M"},
       {"Origin-Realm", 296, "DiameterIdentity", "M"},
       {"Origin-State-Id", 278, "Unsigned32", "M"},
       {"Product-Name", 269, "UTF8String", []},
       {"Proxy-Host", 280, "DiameterIdentity", "M"},
       {"Proxy-Info", 284, "Grouped", "M"},
       {"Proxy-State", 33, "OctetString", "M"},
       {"Re-Auth-Request-Type", 285, "Enumerated", "M"},
       {"Redirect-Host", 292, "DiameterURI", "M"},
       {"Redirect-Host-Usage", 261, "Enumerated", "M"},
       {"Redirect-Max-Cache-Time", 262, "Unsigned32", "M"},
       {"Result-Code", 268, "Unsigned32", "M"},
       {"Route-Record", 282, "DiameterIdentity", "M"},
       {"Session-Binding", 270, "Unsigned32", "M"},
       {"Session-Id", 263, "UTF8String", "M"},
       {"Session-Server-Failover", 271, "Enumerated", "M"},
       {"Session-Timeout", 27, "Unsigned32", "M"},
       {"Supported-Vendor-Id", 265, "Unsigned32", "M"},
       {"Termination-Cause", 295, "Enumerated", "M"},
       {"User-Name", 1, "UTF8String", "M"},
       {"Vendor-Id", 266, "Unsigned32", "M"},
       {"Vendor-Specific-Application-Id", 260, "Grouped",
	"M"}]},
     {avp_vendor_id, []}, {codecs, []},
     {command_codes,
      [{258, "RAR", "RAA"}, {280, "DWR", "DWA"},
       {274, "ASR", "ASA"}, {282, "DPR", "DPA"},
       {275, "STR", "STA"}, {271, "ACR", "ACA"},
       {257, "CER", "CEA"}]},
     {custom_types, []},
     {define,
      [{"Result-Code",
	[{"MULTI_ROUND_AUTH", 1001}, {"SUCCESS", 2001},
	 {"LIMITED_SUCCESS", 2002},
	 {"COMMAND_UNSUPPORTED", 3001},
	 {"UNABLE_TO_DELIVER", 3002}, {"REALM_NOT_SERVED", 3003},
	 {"TOO_BUSY", 3004}, {"LOOP_DETECTED", 3005},
	 {"REDIRECT_INDICATION", 3006},
	 {"APPLICATION_UNSUPPORTED", 3007},
	 {"INVALID_HDR_BITS", 3008}, {"INVALID_AVP_BITS", 3009},
	 {"UNKNOWN_PEER", 3010},
	 {"AUTHENTICATION_REJECTED", 4001},
	 {"OUT_OF_SPACE", 4002}, {"ELECTION_LOST", 4003},
	 {"AVP_UNSUPPORTED", 5001}, {"UNKNOWN_SESSION_ID", 5002},
	 {"AUTHORIZATION_REJECTED", 5003},
	 {"INVALID_AVP_VALUE", 5004}, {"MISSING_AVP", 5005},
	 {"RESOURCES_EXCEEDED", 5006},
	 {"CONTRADICTING_AVPS", 5007}, {"AVP_NOT_ALLOWED", 5008},
	 {"AVP_OCCURS_TOO_MANY_TIMES", 5009},
	 {"NO_COMMON_APPLICATION", 5010},
	 {"UNSUPPORTED_VERSION", 5011},
	 {"UNABLE_TO_COMPLY", 5012},
	 {"INVALID_BIT_IN_HEADER", 5013},
	 {"INVALID_AVP_LENGTH", 5014},
	 {"INVALID_MESSAGE_LENGTH", 5015},
	 {"INVALID_AVP_BIT_COMBO", 5016},
	 {"NO_COMMON_SECURITY", 5017}]}]},
     {enum,
      [{"Disconnect-Cause",
	[{"REBOOTING", 0}, {"BUSY", 1},
	 {"DO_NOT_WANT_TO_TALK_TO_YOU", 2}]},
       {"Redirect-Host-Usage",
	[{"DONT_CACHE", 0}, {"ALL_SESSION", 1},
	 {"ALL_REALM", 2}, {"REALM_AND_APPLICATION", 3},
	 {"ALL_APPLICATION", 4}, {"ALL_HOST", 5},
	 {"ALL_USER", 6}]},
       {"Auth-Request-Type",
	[{"AUTHENTICATE_ONLY", 1}, {"AUTHORIZE_ONLY", 2},
	 {"AUTHORIZE_AUTHENTICATE", 3}]},
       {"Auth-Session-State",
	[{"STATE_MAINTAINED", 0}, {"NO_STATE_MAINTAINED", 1}]},
       {"Re-Auth-Request-Type",
	[{"AUTHORIZE_ONLY", 0}, {"AUTHORIZE_AUTHENTICATE", 1}]},
       {"Termination-Cause",
	[{"LOGOUT", 1}, {"SERVICE_NOT_PROVIDED", 2},
	 {"BAD_ANSWER", 3}, {"ADMINISTRATIVE", 4},
	 {"LINK_BROKEN", 5}, {"AUTH_EXPIRED", 6},
	 {"USER_MOVED", 7}, {"SESSION_TIMEOUT", 8}]},
       {"Session-Server-Failover",
	[{"REFUSE_SERVICE", 0}, {"TRY_AGAIN", 1},
	 {"ALLOW_SERVICE", 2}, {"TRY_AGAIN_ALLOW_SERVICE", 3}]},
       {"Accounting-Record-Type",
	[{"EVENT_RECORD", 1}, {"START_RECORD", 2},
	 {"INTERIM_RECORD", 3}, {"STOP_RECORD", 4}]},
       {"Accounting-Realtime-Required",
	[{"DELIVER_AND_GRANT", 1}, {"GRANT_AND_STORE", 2},
	 {"GRANT_AND_LOSE", 3}]}]},
     {grouped,
      [{"Proxy-Info", 284, [],
	[{"Proxy-Host"}, {"Proxy-State"}, {'*', ["AVP"]}]},
       {"Failed-AVP", 279, [], [{'*', {"AVP"}}]},
       {"Experimental-Result", 297, [],
	[{"Vendor-Id"}, {"Experimental-Result-Code"}]},
       {"Vendor-Specific-Application-Id", 260, [],
	[{"Vendor-Id"}, ["Auth-Application-Id"],
	 ["Acct-Application-Id"]]}]},
     {id, 0}, {import_avps, []}, {import_enums, []},
     {import_groups, []}, {inherits, []},
     {messages,
      [{"CER", 257, ['REQ'], [],
	[{"Origin-Host"}, {"Origin-Realm"},
	 {'*', {"Host-IP-Address"}}, {"Vendor-Id"},
	 {"Product-Name"}, ["Origin-State-Id"],
	 {'*', ["Supported-Vendor-Id"]},
	 {'*', ["Auth-Application-Id"]},
	 {'*', ["Inband-Security-Id"]},
	 {'*', ["Acct-Application-Id"]},
	 {'*', ["Vendor-Specific-Application-Id"]},
	 ["Firmware-Revision"], {'*', ["AVP"]}]},
       {"CEA", 257, [], [],
	[{"Result-Code"}, {"Origin-Host"}, {"Origin-Realm"},
	 {'*', {"Host-IP-Address"}}, {"Vendor-Id"},
	 {"Product-Name"}, ["Origin-State-Id"],
	 ["Error-Message"], ["Failed-AVP"],
	 {'*', ["Supported-Vendor-Id"]},
	 {'*', ["Auth-Application-Id"]},
	 {'*', ["Inband-Security-Id"]},
	 {'*', ["Acct-Application-Id"]},
	 {'*', ["Vendor-Specific-Application-Id"]},
	 ["Firmware-Revision"], {'*', ["AVP"]}]},
       {"DPR", 282, ['REQ'], [],
	[{"Origin-Host"}, {"Origin-Realm"},
	 {"Disconnect-Cause"}, {'*', ["AVP"]}]},
       {"DPA", 282, [], [],
	[{"Result-Code"}, {"Origin-Host"}, {"Origin-Realm"},
	 ["Error-Message"], ["Failed-AVP"], {'*', ["AVP"]}]},
       {"DWR", 280, ['REQ'], [],
	[{"Origin-Host"}, {"Origin-Realm"}, ["Origin-State-Id"],
	 {'*', ["AVP"]}]},
       {"DWA", 280, [], [],
	[{"Result-Code"}, {"Origin-Host"}, {"Origin-Realm"},
	 ["Error-Message"], ["Failed-AVP"], ["Origin-State-Id"],
	 {'*', ["AVP"]}]},
       {"answer-message", -1, ['ERR', 'PXY'], [],
	[{{0, 1}, {{"Session-Id"}}}, {"Origin-Host"},
	 {"Origin-Realm"}, {"Result-Code"}, ["Origin-State-Id"],
	 ["Error-Message"], ["Error-Reporting-Host"],
	 ["Failed-AVP"], ["Experimental-Result"],
	 {'*', ["Proxy-Info"]}, {'*', ["AVP"]}]},
       {"RAR", 258, ['REQ', 'PXY'], [],
	[{{"Session-Id"}}, {"Origin-Host"}, {"Origin-Realm"},
	 {"Destination-Realm"}, {"Destination-Host"},
	 {"Auth-Application-Id"}, {"Re-Auth-Request-Type"},
	 ["User-Name"], ["Origin-State-Id"],
	 {'*', ["Proxy-Info"]}, {'*', ["Route-Record"]},
	 {'*', ["AVP"]}]},
       {"RAA", 258, ['PXY'], [],
	[{{"Session-Id"}}, {"Result-Code"}, {"Origin-Host"},
	 {"Origin-Realm"}, ["User-Name"], ["Origin-State-Id"],
	 ["Error-Message"], ["Error-Reporting-Host"],
	 ["Failed-AVP"], {'*', ["Redirect-Host"]},
	 ["Redirect-Host-Usage"], ["Redirect-Max-Cache-Time"],
	 {'*', ["Proxy-Info"]}, {'*', ["AVP"]}]},
       {"STR", 275, ['REQ', 'PXY'], [],
	[{{"Session-Id"}}, {"Origin-Host"}, {"Origin-Realm"},
	 {"Destination-Realm"}, {"Auth-Application-Id"},
	 {"Termination-Cause"}, ["User-Name"],
	 ["Destination-Host"], {'*', ["Class"]},
	 ["Origin-State-Id"], {'*', ["Proxy-Info"]},
	 {'*', ["Route-Record"]}, {'*', ["AVP"]}]},
       {"STA", 275, ['PXY'], [],
	[{{"Session-Id"}}, {"Result-Code"}, {"Origin-Host"},
	 {"Origin-Realm"}, ["User-Name"], {'*', ["Class"]},
	 ["Error-Message"], ["Error-Reporting-Host"],
	 ["Failed-AVP"], ["Origin-State-Id"],
	 {'*', ["Redirect-Host"]}, ["Redirect-Host-Usage"],
	 ["Redirect-Max-Cache-Time"], {'*', ["Proxy-Info"]},
	 {'*', ["AVP"]}]},
       {"ASR", 274, ['REQ', 'PXY'], [],
	[{{"Session-Id"}}, {"Origin-Host"}, {"Origin-Realm"},
	 {"Destination-Realm"}, {"Destination-Host"},
	 {"Auth-Application-Id"}, ["User-Name"],
	 ["Origin-State-Id"], {'*', ["Proxy-Info"]},
	 {'*', ["Route-Record"]}, {'*', ["AVP"]}]},
       {"ASA", 274, ['PXY'], [],
	[{{"Session-Id"}}, {"Result-Code"}, {"Origin-Host"},
	 {"Origin-Realm"}, ["User-Name"], ["Origin-State-Id"],
	 ["Error-Message"], ["Error-Reporting-Host"],
	 ["Failed-AVP"], {'*', ["Redirect-Host"]},
	 ["Redirect-Host-Usage"], ["Redirect-Max-Cache-Time"],
	 {'*', ["Proxy-Info"]}, {'*', ["AVP"]}]},
       {"ACR", 271, ['REQ', 'PXY'], [],
	[{{"Session-Id"}}, {"Origin-Host"}, {"Origin-Realm"},
	 {"Destination-Realm"}, {"Accounting-Record-Type"},
	 {"Accounting-Record-Number"}, ["Acct-Application-Id"],
	 ["Vendor-Specific-Application-Id"], ["User-Name"],
	 ["Destination-Host"], ["Accounting-Sub-Session-Id"],
	 ["Acct-Session-Id"], ["Acct-Multi-Session-Id"],
	 ["Acct-Interim-Interval"],
	 ["Accounting-Realtime-Required"], ["Origin-State-Id"],
	 ["Event-Timestamp"], {'*', ["Proxy-Info"]},
	 {'*', ["Route-Record"]}, {'*', ["AVP"]}]},
       {"ACA", 271, ['PXY'], [],
	[{{"Session-Id"}}, {"Result-Code"}, {"Origin-Host"},
	 {"Origin-Realm"}, {"Accounting-Record-Type"},
	 {"Accounting-Record-Number"}, ["Acct-Application-Id"],
	 ["Vendor-Specific-Application-Id"], ["User-Name"],
	 ["Accounting-Sub-Session-Id"], ["Acct-Session-Id"],
	 ["Acct-Multi-Session-Id"], ["Error-Message"],
	 ["Error-Reporting-Host"], ["Failed-AVP"],
	 ["Acct-Interim-Interval"],
	 ["Accounting-Realtime-Required"], ["Origin-State-Id"],
	 ["Event-Timestamp"], {'*', ["Proxy-Info"]},
	 {'*', ["AVP"]}]}]},
     {name, "diameter_gen_base_rfc6733"},
     {prefix, "diameter_base"}, {vendor, {0, "IETF"}}].


