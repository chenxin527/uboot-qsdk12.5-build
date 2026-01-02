-module(icparse).
-file("/net/isildur/ldisk/daily_build/17_prebuild_opu_o.2015-03-31_14/otp_src_17/lib/ic/src/icyeccpre.hrl", 0).
%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 1997-2009. All Rights Reserved.
%% 
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% %CopyrightEnd%
%%
%%


-export([parse/1, parse_and_scan/1, format_error/1]).

-import(lists, [reverse/1]).

-ifdef(JAM).
-compile([{parse_transform,jam_yecc_pj},pj]).
-endif.


-include("icforms.hrl").



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The parser generator will insert appropriate declarations before this line.%

parse(Tokens) ->
    case catch yeccpars1(Tokens, false, 0, [], []) of
	error ->
	    Errorline =
		if Tokens == [] -> 0; true -> element(2, hd(Tokens)) end,
	    {error,
	     {Errorline, ?MODULE, "syntax error at or after this line."}};
	Other ->
	    Other
    end.

parse_and_scan({Mod, Fun, Args}) ->
    case apply(Mod, Fun, Args) of
	{eof, _} ->
	    {ok, eof};
	{error, Descriptor, _} ->
	    {error, Descriptor};
	{ok, Tokens, _} ->
	    yeccpars1(Tokens, {Mod, Fun, Args}, 0, [], [])
    end.

format_error(Message) ->
    case io_lib:deep_char_list(Message) of
	true ->
	    Message;
	_ ->
	    io_lib:write(Message)
    end.

% To be used in grammar files to throw an error message to the parser toplevel.
% Doesn't have to be exported!
return_error(Line, Message) ->
    throw({error, {Line, ?MODULE, Message}}).


% Don't change yeccpars1/6 too much, it is called recursively by yeccpars2/8!
yeccpars1([Token | Tokens], Tokenizer, State, States, Vstack) ->
    yeccpars2(State, element(1, Token), States, Vstack, Token, Tokens,
	      Tokenizer);
yeccpars1([], {M, F, A}, State, States, Vstack) ->
    case catch apply(M, F, A) of
        {eof, Endline} ->
            {error, {Endline, ?MODULE, "end_of_file"}};
        {error, Descriptor, _Endline} ->
            {error, Descriptor};
        {'EXIT', Reason} ->
            {error, {0, ?MODULE, Reason}};
        {ok, Tokens, _Endline} ->
	    case catch yeccpars1(Tokens, {M, F, A}, State, States, Vstack) of
		error ->
		    Errorline = element(2, hd(Tokens)),
		    {error, {Errorline, ?MODULE,
			     "syntax error at or after this line."}};
		Other ->
		    Other
	    end
    end;
yeccpars1([], false, State, States, Vstack) ->
    yeccpars2(State, '$end', States, Vstack, {'$end', 999999}, [], false).

% For internal use only.
yeccerror(Token) ->
    {error,
     {element(2, Token), ?MODULE,
      ["syntax error before: ", yecctoken2string(Token)]}}.

yecctoken2string({atom, _, A}) -> io_lib:write(A);
yecctoken2string({integer,_,N}) -> io_lib:write(N);
yecctoken2string({float,_,F}) -> io_lib:write(F);
yecctoken2string({char,_,C}) -> io_lib:write_char(C);
yecctoken2string({var,_,V}) -> io_lib:format("~s", [V]);
yecctoken2string({string,_,S}) -> io_lib:write_string(S);
yecctoken2string({reserved_symbol, _, A}) -> io_lib:format("~w", [A]);
yecctoken2string({'dot', _}) -> "'.'";
yecctoken2string({'$end', _}) ->
    [];
yecctoken2string({Other, _}) when is_atom(Other) ->
    io_lib:format("~w", [Other]);
yecctoken2string({_, _, Other}) when is_list(Other) andalso is_number(hd(Other)) ->
    Other;
yecctoken2string({_, _, Other}) ->
    io_lib:format("~p", [Other]);
yecctoken2string(Other) ->
    io_lib:write(Other).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


-file("icparse.yrl", 867).
%%-----------------------------------------------------------




-file("./icparse.erl", 134).

yeccpars2(0=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(1=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_1(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(2=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_2(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(3=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_3(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(4=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(5=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_5(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(6=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(7=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_7(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(8=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_8(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(9=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_9(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(10=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_10(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(11=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_11(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(12=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_12(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(13=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(14=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(15=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_15(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(16=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_16(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(17=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_17(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(18=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(19=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(20=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(21=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(22=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(23=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_23(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(24=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_24(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(25=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_25(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(26=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_26(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(27=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_27(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(28=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_28(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(29=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(30=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_30(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(31=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_31(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(32=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_32(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(33=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_33(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(34=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_34(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(35=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_35(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(36=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_36(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(37=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_37(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(38=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_38(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(39=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_39(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(40=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_40(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(41=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_41(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(42=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_42(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(43=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_43(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(44=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_44(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(45=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_45(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(46=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_46(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(47=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_47(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(48=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_48(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(49=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_49(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(50=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_50(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(51=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_51(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(52=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_52(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(53=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(54=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_54(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(55=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(56=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(57=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(58=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(59=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_59(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(60=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_60(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(61=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_61(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(62=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_62(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(63=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(64=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_64(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(65=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_65(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(66=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(67=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_67(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(68=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(69=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(70=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(71=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(72=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(73=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(74=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(75=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_75(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(76=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(77=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_77(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(78=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_78(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(79=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_79(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(80=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_80(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(81=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(82=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_82(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(83=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_83(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(84=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_84(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(85=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_85(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(86=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_86(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(87=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_87(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(88=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(89=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_89(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(90=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_90(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(91=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_91(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(92=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_92(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(93=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_93(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(94=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_94(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(95=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_95(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(96=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_96(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(97=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_97(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(98=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_98(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(99=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_99(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(100=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_100(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(101=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_101(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(102=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(103=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_103(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(104=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(105=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_105(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(106=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_106(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(107=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_107(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(108=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_108(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(109=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_109(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(110=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_110(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(111=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_111(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(112=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_112(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(113=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(114=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_114(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(115=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_115(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(116=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_116(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(117=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_117(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(118=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_118(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(119=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_119(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(120=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_120(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(121=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_121(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(122=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_122(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(123=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_123(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(124=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_124(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(125=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_125(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(126=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_126(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(127=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(128=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(129=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(130=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(131=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(132=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(133=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_133(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(134=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(135=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(136=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(137=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(138=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(139=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_139(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(140=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_140(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(141=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_141(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(142=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(143=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(144=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(145=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_145(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(146=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(147=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(148=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(149=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_149(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(150=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_150(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(151=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_151(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(152=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_152(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(153=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(154=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_154(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(155=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(156=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(157=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_157(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(158=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_158(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(159=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(160=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_160(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(161=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(162=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_162(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(163=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(164=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_164(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(165=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(166=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(167=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_167(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(168=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_168(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(169=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_169(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(170=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_170(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(171=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_171(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(172=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_172(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(173=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_173(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(174=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(175=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_175(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(176=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_176(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(177=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_177(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(178=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_178(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(179=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_179(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(180=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_180(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(181=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_181(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(182=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(183=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(184=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(185=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(186=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_186(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(187=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_187(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(188=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(189=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_189(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(190=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_190(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(191=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(192=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_192(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(193=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(194=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_194(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(195=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_195(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(196=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_196(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(197=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_197(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(198=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(199=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_199(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(200=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_200(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(201=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_201(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(202=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(203=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_203(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(204=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(205=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_205(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(206=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(207=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_207(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(208=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_208(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(209=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_209(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(210=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_210(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(211=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_211(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(212=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(213=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_213(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(214=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_214(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(215=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_215(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(216=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_216(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(217=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(218=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_218(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(219=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_219(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(220=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_220(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(221=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_221(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(222=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(223=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_223(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(224=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_224(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(225=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_225(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(226=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(227=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_227(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(228=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_228(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(229=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(230=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_230(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(231=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_231(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(232=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(233=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_233(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(234=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_234(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(235=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_235(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(236=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_236(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(237=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_237(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(238=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_238(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(239=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(240=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_240(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(241=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_241(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(242=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_242(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(243=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_243(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(244=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_244(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(245=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_245(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(246=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_246(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(247=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_247(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(248=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(249=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_249(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(250=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_242(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(251=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_251(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(252=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_252(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(253=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_253(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(254=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_254(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(255=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_255(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(256=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_256(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(257=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_257(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(258=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_258(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(259=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(260=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_260(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(261=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_261(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(262=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(263=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(264=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_264(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(265=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_265(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(266=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_266(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(267=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_267(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(268=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_268(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(269=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_269(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(270=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(271=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_271(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(272=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_272(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(273=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_273(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(274=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(275=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_275(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(276=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_276(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(277=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_277(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(278=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_278(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(279=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_279(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(280=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_280(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(281=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_281(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(282=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_282(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(283=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_283(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(284=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_284(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(285=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_285(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(286=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_286(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(287=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_287(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(288=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(289=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_289(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(290=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_290(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(291=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_291(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(292=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(293=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_293(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(294=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(295=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_295(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(296=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_296(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(297=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_297(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(298=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_298(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(299=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(300=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_300(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(301=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_301(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(302=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_302(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(303=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(304=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_304(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(305=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_305(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(306=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_306(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(307=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_307(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(308=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_308(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(309=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_309(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(310=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_310(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(311=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_311(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(312=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_312(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(313=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_313(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(314=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_314(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(315=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_315(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(316=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_316(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(317=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_317(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(318=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_318(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(319=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_319(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(320=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_320(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(321=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_321(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(322=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_322(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(323=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_323(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(324=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_324(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(325=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_325(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(326=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_326(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(327=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(328=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_328(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(329=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_329(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(330=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_330(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(331=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_331(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(332=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_332(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(333=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_333(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(334=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_334(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(335=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_335(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(336=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_336(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(337=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_337(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(338=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_338(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(339=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_339(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(340=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_308(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(341=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_313(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(342=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_342(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(343=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_343(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(344=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_313(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(345=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_345(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(346=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_346(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(347=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_347(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(Other, _, _, _, _, _, _) ->
 erlang:error({yecc_bug,"1.4",{missing_state_in_action_table, Other}}).

yeccpars2_0(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 20, [S | Ss], [T | Stack]);
yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_0(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_0(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 18, [S | Ss], [T | Stack]);
yeccpars2_cont_0(S, const, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 19, [S | Ss], [T | Stack]);
yeccpars2_cont_0(S, exception, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 21, [S | Ss], [T | Stack]);
yeccpars2_cont_0(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 22, [S | Ss], [T | Stack]);
yeccpars2_cont_0(S, module, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 23, [S | Ss], [T | Stack]);
yeccpars2_cont_0(S, struct, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 24, [S | Ss], [T | Stack]);
yeccpars2_cont_0(S, typedef, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 25, [S | Ss], [T | Stack]);
yeccpars2_cont_0(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 26, [S | Ss], [T | Stack]);
yeccpars2_cont_0(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_1(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 18, [S | Ss], [T | Stack]);
yeccpars2_1(S, const, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 19, [S | Ss], [T | Stack]);
yeccpars2_1(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 20, [S | Ss], [T | Stack]);
yeccpars2_1(S, exception, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 21, [S | Ss], [T | Stack]);
yeccpars2_1(S, interface, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 22, [S | Ss], [T | Stack]);
yeccpars2_1(S, module, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 23, [S | Ss], [T | Stack]);
yeccpars2_1(S, struct, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 24, [S | Ss], [T | Stack]);
yeccpars2_1(S, typedef, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 25, [S | Ss], [T | Stack]);
yeccpars2_1(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 26, [S | Ss], [T | Stack]);
yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_1_(Stack),
 'yeccgoto_\'<specification>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<definition>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<definition>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<type_dcl>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_5(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 347, [S | Ss], [T | Stack]);
yeccpars2_5(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<type_dcl>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_7(_S, '$end', _Ss, Stack, _T, _Ts, _Tzr) ->
 {ok, hd(Stack)};
yeccpars2_7(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_8(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 346, [S | Ss], [T | Stack]);
yeccpars2_8(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_9(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 275, [S | Ss], [T | Stack]);
yeccpars2_9(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<interface>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_11(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 274, [S | Ss], [T | Stack]);
yeccpars2_11(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<interface>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_13(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 273, [S | Ss], [T | Stack]);
yeccpars2_13(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<type_dcl>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_15(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_15_(Stack),
 'yeccgoto_\'OorM_<definition>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<type_dcl>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_17(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 272, [S | Ss], [T | Stack]);
yeccpars2_17(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_18(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 265, [S | Ss], [T | Stack]);
yeccpars2_18(S, '<integer_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 266, [S | Ss], [T | Stack]);
yeccpars2_18(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_19(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_19(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_19(S, double, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 104, [S | Ss], [T | Stack]);
yeccpars2_19(S, fixed, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 261, [S | Ss], [T | Stack]);
yeccpars2_19(S, float, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 106, [S | Ss], [T | Stack]);
yeccpars2_19(S, octet, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 107, [S | Ss], [T | Stack]);
yeccpars2_19(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 109, [S | Ss], [T | Stack]);
yeccpars2_19(S, wstring, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 112, [S | Ss], [T | Stack]);
yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_19(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_19(S, boolean, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 44, [S | Ss], [T | Stack]);
yeccpars2_cont_19(S, char, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 45, [S | Ss], [T | Stack]);
yeccpars2_cont_19(S, long, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 46, [S | Ss], [T | Stack]);
yeccpars2_cont_19(S, short, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 47, [S | Ss], [T | Stack]);
yeccpars2_cont_19(S, unsigned, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 48, [S | Ss], [T | Stack]);
yeccpars2_cont_19(S, wchar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 49, [S | Ss], [T | Stack]);
yeccpars2_cont_19(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_20(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 240, [S | Ss], [T | Stack]);
yeccpars2_20(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_21(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 234, [S | Ss], [T | Stack]);
yeccpars2_21(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_22(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 226, [S | Ss], [T | Stack]);
yeccpars2_22(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_23(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 221, [S | Ss], [T | Stack]);
yeccpars2_23(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_24(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 220, [S | Ss], [T | Stack]);
yeccpars2_24(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_25(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_25(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_25(S, 'Object', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 100, [S | Ss], [T | Stack]);
yeccpars2_25(S, any, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 101, [S | Ss], [T | Stack]);
yeccpars2_25(S, double, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 104, [S | Ss], [T | Stack]);
yeccpars2_25(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 20, [S | Ss], [T | Stack]);
yeccpars2_25(S, fixed, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 105, [S | Ss], [T | Stack]);
yeccpars2_25(S, float, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 106, [S | Ss], [T | Stack]);
yeccpars2_25(S, octet, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 107, [S | Ss], [T | Stack]);
yeccpars2_25(S, sequence, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 108, [S | Ss], [T | Stack]);
yeccpars2_25(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 109, [S | Ss], [T | Stack]);
yeccpars2_25(S, struct, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 110, [S | Ss], [T | Stack]);
yeccpars2_25(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 111, [S | Ss], [T | Stack]);
yeccpars2_25(S, wstring, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 112, [S | Ss], [T | Stack]);
yeccpars2_25(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_19(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_26(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 27, [S | Ss], [T | Stack]);
yeccpars2_26(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_27(S, switch, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 28, [S | Ss], [T | Stack]);
yeccpars2_27(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_27_(Stack),
 'yeccgoto_\'<constr_forward_decl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_28(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 29, [S | Ss], [T | Stack]);
yeccpars2_28(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_29(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_29(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_29(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 20, [S | Ss], [T | Stack]);
yeccpars2_29(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_19(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<unsigned_int>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<unsigned_int>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_32_(Stack),
 'yeccgoto_\'<integer_type>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_33(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 57, [S | Ss], [T | Stack]);
yeccpars2_33(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<signed_int>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<signed_int>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<integer_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_37(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 55, [S | Ss], [T | Stack]);
yeccpars2_37(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<switch_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_38(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<switch_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_39(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<switch_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_40(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<switch_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_41(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<switch_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_42(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 54, [S | Ss], [T | Stack]);
yeccpars2_42(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_43(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_43_(Stack),
 'yeccgoto_\'<scoped_name>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_44(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<boolean_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_45(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<char_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_46(S, long, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 53, [S | Ss], [T | Stack]);
yeccpars2_46(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<signed_long_int>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<signed_short_int>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_48(S, long, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 50, [S | Ss], [T | Stack]);
yeccpars2_48(S, short, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 51, [S | Ss], [T | Stack]);
yeccpars2_48(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_49(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<char_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_50(S, long, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 52, [S | Ss], [T | Stack]);
yeccpars2_50(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_50_(Stack),
 'yeccgoto_\'<unsigned_long_int>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_51(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_51_(Stack),
 'yeccgoto_\'<unsigned_short_int>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_52(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_52_(Stack),
 'yeccgoto_\'<unsigned_long_int>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_53_(Stack),
 'yeccgoto_\'<signed_long_int>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_54_(Stack),
 'yeccgoto_\'<scoped_name>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_55(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 56, [S | Ss], [T | Stack]);
yeccpars2_55(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_56(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_56_(Stack),
 'yeccgoto_\'<scoped_name>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_57(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 58, [S | Ss], [T | Stack]);
yeccpars2_57(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_58_(Stack),
 yeccpars2_59(59, Cat, [58 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_59(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_59_(Stack),
 yeccpars2_65(65, Cat, [59 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_60(_S, '#', Ss, Stack, T, Ts, Tzr) ->
 NewStack = 'yeccpars2_60_#'(Stack),
 yeccpars2_59(59, '#', [60 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_60(_S, 'case', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_60_case(Stack),
 yeccpars2_59(59, 'case', [60 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_60(_S, default, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_60_default(Stack),
 yeccpars2_59(59, default, [60 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_60(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_60_(Stack),
 'yeccgoto_\'<switch_body>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_61(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 63, [S | Ss], [T | Stack]);
yeccpars2_61(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_62(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_62_(Stack),
 'yeccgoto_\'OorM_<case>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_63(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_63_(Stack),
 'yeccgoto_\'<union_type>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_64(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_64_(Stack),
 'yeccgoto_\'OorM_<case>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_65(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_65(S, 'case', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 102, [S | Ss], [T | Stack]);
yeccpars2_65(S, default, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 103, [S | Ss], [T | Stack]);
yeccpars2_65(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_66_(Stack),
 yeccpars2_79(79, Cat, [66 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_67_(Stack),
 'yeccgoto_\'Ugly_pragmas\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_68(S, '<integer_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 69, [S | Ss], [T | Stack]);
yeccpars2_68(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_69(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 70, [S | Ss], [T | Stack]);
yeccpars2_69(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_70(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 71, [S | Ss], [T | Stack]);
yeccpars2_70(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_71(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 72, [S | Ss], [T | Stack]);
yeccpars2_71(S, '<string_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 73, [S | Ss], [T | Stack]);
yeccpars2_71(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_72(S, '<floating_pt_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 75, [S | Ss], [T | Stack]);
yeccpars2_72(S, '<string_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 76, [S | Ss], [T | Stack]);
yeccpars2_72(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_73(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 74, [S | Ss], [T | Stack]);
yeccpars2_73(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_74_(Stack),
 'yeccgoto_\'OE_pragma\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_75(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 78, [S | Ss], [T | Stack]);
yeccpars2_75(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_76(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 77, [S | Ss], [T | Stack]);
yeccpars2_76(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_77(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_77_(Stack),
 'yeccgoto_\'OE_pragma\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_78(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_78_(Stack),
 'yeccgoto_\'OE_pragma\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_79(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_79(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_79(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_79(S, 'Object', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 100, [S | Ss], [T | Stack]);
yeccpars2_79(S, any, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 101, [S | Ss], [T | Stack]);
yeccpars2_79(S, 'case', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 102, [S | Ss], [T | Stack]);
yeccpars2_79(S, default, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 103, [S | Ss], [T | Stack]);
yeccpars2_79(S, double, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 104, [S | Ss], [T | Stack]);
yeccpars2_79(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 20, [S | Ss], [T | Stack]);
yeccpars2_79(S, fixed, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 105, [S | Ss], [T | Stack]);
yeccpars2_79(S, float, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 106, [S | Ss], [T | Stack]);
yeccpars2_79(S, octet, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 107, [S | Ss], [T | Stack]);
yeccpars2_79(S, sequence, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 108, [S | Ss], [T | Stack]);
yeccpars2_79(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 109, [S | Ss], [T | Stack]);
yeccpars2_79(S, struct, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 110, [S | Ss], [T | Stack]);
yeccpars2_79(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 111, [S | Ss], [T | Stack]);
yeccpars2_79(S, wstring, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 112, [S | Ss], [T | Stack]);
yeccpars2_79(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_19(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_80(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<constr_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_81(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 180, [S | Ss], [T | Stack]);
yeccpars2_81(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_82(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<simple_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<constr_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_84(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<template_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<template_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_87(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 55, [S | Ss], [T | Stack]);
yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<simple_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<base_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<base_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<base_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<template_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_92(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<constr_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_93(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_93_(Stack),
 yeccpars2_211(211, Cat, [93 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<base_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_96_(Stack),
 yeccpars2_210(210, Cat, [96 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<base_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<simple_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<base_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_100(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<base_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<any_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_102(S, '+', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 129, [S | Ss], [T | Stack]);
yeccpars2_102(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 130, [S | Ss], [T | Stack]);
yeccpars2_102(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_102(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_102(S, '~', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 140, [S | Ss], [T | Stack]);
yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_102(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_102(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 128, [S | Ss], [T | Stack]);
yeccpars2_cont_102(S, '<character_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 131, [S | Ss], [T | Stack]);
yeccpars2_cont_102(S, '<fixed_pt_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 132, [S | Ss], [T | Stack]);
yeccpars2_cont_102(S, '<floating_pt_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 133, [S | Ss], [T | Stack]);
yeccpars2_cont_102(S, '<integer_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 134, [S | Ss], [T | Stack]);
yeccpars2_cont_102(S, '<string_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 135, [S | Ss], [T | Stack]);
yeccpars2_cont_102(S, '<wcharacter_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 136, [S | Ss], [T | Stack]);
yeccpars2_cont_102(S, '<wstring_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 137, [S | Ss], [T | Stack]);
yeccpars2_cont_102(S, 'FALSE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 138, [S | Ss], [T | Stack]);
yeccpars2_cont_102(S, 'TRUE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 139, [S | Ss], [T | Stack]);
yeccpars2_cont_102(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_103(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 207, [S | Ss], [T | Stack]);
yeccpars2_103(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<floating_pt_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_105(S, '<', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 202, [S | Ss], [T | Stack]);
yeccpars2_105(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<floating_pt_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<octet_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_108(S, '<', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 196, [S | Ss], [T | Stack]);
yeccpars2_108(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_109(S, '<', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 193, [S | Ss], [T | Stack]);
yeccpars2_109(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_109_(Stack),
 'yeccgoto_\'<string_type>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_110(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 166, [S | Ss], [T | Stack]);
yeccpars2_110(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_111(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 165, [S | Ss], [T | Stack]);
yeccpars2_111(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_112(S, '<', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 113, [S | Ss], [T | Stack]);
yeccpars2_112(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_112_(Stack),
 'yeccgoto_\'<string_type>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_113: see yeccpars2_102

yeccpars2_114(S, '^', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 161, [S | Ss], [T | Stack]);
yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<or_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_115(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_115(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_115(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_102(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<mult_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_117(S, '<<', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 155, [S | Ss], [T | Stack]);
yeccpars2_117(S, '>>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 156, [S | Ss], [T | Stack]);
yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<and_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_118(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 55, [S | Ss], [T | Stack]);
yeccpars2_118(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<primary_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<unary_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_120(S, '>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 163, [S | Ss], [T | Stack]);
yeccpars2_120(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_121(S, '|', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 159, [S | Ss], [T | Stack]);
yeccpars2_121(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<const_exp>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_122(S, '%', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 146, [S | Ss], [T | Stack]);
yeccpars2_122(S, '*', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 147, [S | Ss], [T | Stack]);
yeccpars2_122(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 148, [S | Ss], [T | Stack]);
yeccpars2_122(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<add_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<primary_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<positive_int_const>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_126(S, '&', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 153, [S | Ss], [T | Stack]);
yeccpars2_126(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<xor_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_127(S, '+', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 143, [S | Ss], [T | Stack]);
yeccpars2_127(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 144, [S | Ss], [T | Stack]);
yeccpars2_127(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<shift_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_128: see yeccpars2_102

yeccpars2_129(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<unary_operator>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_130(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<unary_operator>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_133(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<boolean_literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<boolean_literal>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<unary_operator>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_141(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 142, [S | Ss], [T | Stack]);
yeccpars2_141(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_142(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_142_(Stack),
 'yeccgoto_\'<primary_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_143: see yeccpars2_102

%% yeccpars2_144: see yeccpars2_102

yeccpars2_145(S, '%', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 146, [S | Ss], [T | Stack]);
yeccpars2_145(S, '*', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 147, [S | Ss], [T | Stack]);
yeccpars2_145(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 148, [S | Ss], [T | Stack]);
yeccpars2_145(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_145_(Stack),
 'yeccgoto_\'<add_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_146: see yeccpars2_102

%% yeccpars2_147: see yeccpars2_102

%% yeccpars2_148: see yeccpars2_102

yeccpars2_149(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_149_(Stack),
 'yeccgoto_\'<mult_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_150_(Stack),
 'yeccgoto_\'<mult_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_151_(Stack),
 'yeccgoto_\'<mult_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_152(S, '%', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 146, [S | Ss], [T | Stack]);
yeccpars2_152(S, '*', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 147, [S | Ss], [T | Stack]);
yeccpars2_152(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 148, [S | Ss], [T | Stack]);
yeccpars2_152(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_152_(Stack),
 'yeccgoto_\'<add_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_153: see yeccpars2_102

yeccpars2_154(S, '<<', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 155, [S | Ss], [T | Stack]);
yeccpars2_154(S, '>>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 156, [S | Ss], [T | Stack]);
yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_154_(Stack),
 'yeccgoto_\'<and_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_155: see yeccpars2_102

%% yeccpars2_156: see yeccpars2_102

yeccpars2_157(S, '+', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 143, [S | Ss], [T | Stack]);
yeccpars2_157(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 144, [S | Ss], [T | Stack]);
yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_157_(Stack),
 'yeccgoto_\'<shift_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_158(S, '+', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 143, [S | Ss], [T | Stack]);
yeccpars2_158(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 144, [S | Ss], [T | Stack]);
yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_158_(Stack),
 'yeccgoto_\'<shift_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_159: see yeccpars2_102

yeccpars2_160(S, '^', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 161, [S | Ss], [T | Stack]);
yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_160_(Stack),
 'yeccgoto_\'<or_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_161: see yeccpars2_102

yeccpars2_162(S, '&', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 153, [S | Ss], [T | Stack]);
yeccpars2_162(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_162_(Stack),
 'yeccgoto_\'<xor_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_163(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_163_(Stack),
 'yeccgoto_\'<string_type>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_164(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_164_(Stack),
 'yeccgoto_\'<unary_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_165(S, switch, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 28, [S | Ss], [T | Stack]);
yeccpars2_165(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_166(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 167, [S | Ss], [T | Stack]);
yeccpars2_166(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_167(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_167_(Stack),
 yeccpars2_168(168, Cat, [167 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_168(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_168(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_168(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_168(S, 'Object', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 100, [S | Ss], [T | Stack]);
yeccpars2_168(S, any, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 101, [S | Ss], [T | Stack]);
yeccpars2_168(S, double, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 104, [S | Ss], [T | Stack]);
yeccpars2_168(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 20, [S | Ss], [T | Stack]);
yeccpars2_168(S, fixed, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 105, [S | Ss], [T | Stack]);
yeccpars2_168(S, float, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 106, [S | Ss], [T | Stack]);
yeccpars2_168(S, octet, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 107, [S | Ss], [T | Stack]);
yeccpars2_168(S, sequence, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 108, [S | Ss], [T | Stack]);
yeccpars2_168(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 109, [S | Ss], [T | Stack]);
yeccpars2_168(S, struct, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 110, [S | Ss], [T | Stack]);
yeccpars2_168(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 111, [S | Ss], [T | Stack]);
yeccpars2_168(S, wstring, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 112, [S | Ss], [T | Stack]);
yeccpars2_168(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_19(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_169(_S, '#', Ss, Stack, T, Ts, Tzr) ->
 NewStack = 'yeccpars2_169_#'(Stack),
 yeccpars2_168(168, '#', [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, '::', Ss, Stack, T, Ts, Tzr) ->
 NewStack = 'yeccpars2_169_::'(Stack),
 yeccpars2_168(168, '::', [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 NewStack = 'yeccpars2_169_<identifier>'(Stack),
 yeccpars2_168(168, '<identifier>', [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, 'Object', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_Object(Stack),
 yeccpars2_168(168, 'Object', [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, any, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_any(Stack),
 yeccpars2_168(168, any, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, boolean, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_boolean(Stack),
 yeccpars2_168(168, boolean, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, char, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_char(Stack),
 yeccpars2_168(168, char, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, double, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_double(Stack),
 yeccpars2_168(168, double, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, enum, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_enum(Stack),
 yeccpars2_168(168, enum, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, fixed, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_fixed(Stack),
 yeccpars2_168(168, fixed, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, float, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_float(Stack),
 yeccpars2_168(168, float, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, long, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_long(Stack),
 yeccpars2_168(168, long, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, octet, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_octet(Stack),
 yeccpars2_168(168, octet, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, sequence, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_sequence(Stack),
 yeccpars2_168(168, sequence, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, short, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_short(Stack),
 yeccpars2_168(168, short, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, string, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_string(Stack),
 yeccpars2_168(168, string, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, struct, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_struct(Stack),
 yeccpars2_168(168, struct, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, union, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_union(Stack),
 yeccpars2_168(168, union, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, unsigned, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_unsigned(Stack),
 yeccpars2_168(168, unsigned, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, wchar, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_wchar(Stack),
 yeccpars2_168(168, wchar, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, wstring, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_wstring(Stack),
 yeccpars2_168(168, wstring, [169 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_169(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_(Stack),
 'yeccgoto_\'<member_list>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_170(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 172, [S | Ss], [T | Stack]);
yeccpars2_170(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'OorM_<member>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_172(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_172_(Stack),
 'yeccgoto_\'<struct_type>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_173(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_173_(Stack),
 'yeccgoto_\'OorM_<member>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_174: see yeccpars2_81

yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<declarator>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_176_(Stack),
 yeccpars2_190(190, Cat, [176 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_177(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_177_(Stack),
 yeccpars2_187(187, Cat, [177 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<declarator>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<complex_declarator>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_180(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 183, [S | Ss], [T | Stack]);
yeccpars2_180(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<simple_declarator>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_181(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 183, [S | Ss], [T | Stack]);
yeccpars2_181(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_181_(Stack),
 'yeccgoto_\'<array_declarator>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_182(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_182_(Stack),
 'yeccgoto_\'OorM_<fixed_array_size>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_183: see yeccpars2_102

yeccpars2_184(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 185, [S | Ss], [T | Stack]);
yeccpars2_184(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_185_(Stack),
 'yeccgoto_\'<fixed_array_size>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_186_(Stack),
 'yeccgoto_\'OorM_<fixed_array_size>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_187(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 188, [S | Ss], [T | Stack]);
yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_187_(Stack),
 'yeccgoto_\'<declarators>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_188: see yeccpars2_81

yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_189_(Stack),
 'yeccgoto_\'ZorM_<declarator>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_190(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_190(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 191, [S | Ss], [T | Stack]);
yeccpars2_190(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_191(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_191_(Stack),
 yeccpars2_192(192, Cat, [191 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_192(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_192(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_192_(Stack),
 'yeccgoto_\'<member>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_193: see yeccpars2_102

yeccpars2_194(S, '>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 195, [S | Ss], [T | Stack]);
yeccpars2_194(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_195(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_195_(Stack),
 'yeccgoto_\'<string_type>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_196(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_196(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_196(S, 'Object', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 100, [S | Ss], [T | Stack]);
yeccpars2_196(S, any, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 101, [S | Ss], [T | Stack]);
yeccpars2_196(S, double, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 104, [S | Ss], [T | Stack]);
yeccpars2_196(S, fixed, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 105, [S | Ss], [T | Stack]);
yeccpars2_196(S, float, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 106, [S | Ss], [T | Stack]);
yeccpars2_196(S, octet, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 107, [S | Ss], [T | Stack]);
yeccpars2_196(S, sequence, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 108, [S | Ss], [T | Stack]);
yeccpars2_196(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 109, [S | Ss], [T | Stack]);
yeccpars2_196(S, wstring, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 112, [S | Ss], [T | Stack]);
yeccpars2_196(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_19(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_197(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 198, [S | Ss], [T | Stack]);
yeccpars2_197(S, '>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 199, [S | Ss], [T | Stack]);
yeccpars2_197(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_198: see yeccpars2_102

yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_199_(Stack),
 'yeccgoto_\'<sequence_type>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_200(S, '>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 201, [S | Ss], [T | Stack]);
yeccpars2_200(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_201(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_201_(Stack),
 'yeccgoto_\'<sequence_type>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_202: see yeccpars2_102

yeccpars2_203(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 204, [S | Ss], [T | Stack]);
yeccpars2_203(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_204: see yeccpars2_102

yeccpars2_205(S, '>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 206, [S | Ss], [T | Stack]);
yeccpars2_205(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_206(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_206_(Stack),
 'yeccgoto_\'<fixed_pt_type>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_207(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_207_(Stack),
 'yeccgoto_\'<case_label>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_208(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 209, [S | Ss], [T | Stack]);
yeccpars2_208(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_209_(Stack),
 'yeccgoto_\'<case_label>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_210(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_210_(Stack),
 'yeccgoto_\'OorM_<case_label>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_211(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_211(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 212, [S | Ss], [T | Stack]);
yeccpars2_211(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_212(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_212_(Stack),
 yeccpars2_213(213, Cat, [212 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_213(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_213_(Stack),
 'yeccgoto_\'<case>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_214_(Stack),
 'yeccgoto_\'<element_spec>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_215_(Stack),
 yeccpars2_216(216, Cat, [215 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_216(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_216(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_216_(Stack),
 'yeccgoto_\'OorM_<case_label>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_217: see yeccpars2_81

yeccpars2_218(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_218_(Stack),
 'yeccgoto_\'<type_dcl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_219(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_219_(Stack),
 'yeccgoto_\'<type_declarator>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_220(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 167, [S | Ss], [T | Stack]);
yeccpars2_220(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_220_(Stack),
 'yeccgoto_\'<constr_forward_decl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_221(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 222, [S | Ss], [T | Stack]);
yeccpars2_221(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_222: see yeccpars2_0

yeccpars2_223(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 20, [S | Ss], [T | Stack]);
yeccpars2_223(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 225, [S | Ss], [T | Stack]);
yeccpars2_223(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_0(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_224_(Stack),
 'yeccgoto_\'OorM_<definition>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_225(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_225_(Stack),
 'yeccgoto_\'<module>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_226(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 229, [S | Ss], [T | Stack]);
yeccpars2_226(_S, ';', Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = 'yeccpars2_226_;'(Stack),
 'yeccgoto_\'<forward_dcl>\''(hd(Nss), ';', Nss, NewStack, T, Ts, Tzr);
yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_226_(Stack),
 yeccpars2_227(_S, Cat, [226 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_227_(Stack),
 'yeccgoto_\'<interface_header>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Opt_<inheritance_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_229(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_229(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_229(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_230(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 55, [S | Ss], [T | Stack]);
yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_230_(Stack),
 yeccpars2_231(231, Cat, [230 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_231(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 232, [S | Ss], [T | Stack]);
yeccpars2_231(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_231_(Stack),
 'yeccgoto_\'<inheritance_spec>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_232: see yeccpars2_229

yeccpars2_233(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 55, [S | Ss], [T | Stack]);
yeccpars2_233(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_233_(Stack),
 'yeccgoto_\'ZorM_<scoped_name>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_234(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 235, [S | Ss], [T | Stack]);
yeccpars2_234(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_235(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_235_(Stack),
 yeccpars2_237(237, Cat, [235 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_236(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 239, [S | Ss], [T | Stack]);
yeccpars2_236(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_236_(Stack),
 yeccpars2_168(168, Cat, [236 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_237(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_237(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'ZorM_<member>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_238(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_238_(Stack),
 'yeccgoto_\'ZorM_<member>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_239_(Stack),
 'yeccgoto_\'<except_dcl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_240(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 241, [S | Ss], [T | Stack]);
yeccpars2_240(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_241(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_241_(Stack),
 yeccpars2_242(242, Cat, [241 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_242(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_242(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 244, [S | Ss], [T | Stack]);
yeccpars2_242(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_243(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_243_(Stack),
 yeccpars2_245(245, Cat, [243 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_244(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_244_(Stack),
 'yeccgoto_\'<enumerator>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_245(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_245(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_245_(Stack),
 yeccpars2_246(_S, Cat, [245 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_246(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_246_(Stack),
 yeccpars2_247(247, Cat, [246 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_247(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_247(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 248, [S | Ss], [T | Stack]);
yeccpars2_247(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 249, [S | Ss], [T | Stack]);
yeccpars2_247(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_248_(Stack),
 yeccpars2_242(250, Cat, [248 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_249(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_249_(Stack),
 'yeccgoto_\'<enum_type>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_250: see yeccpars2_242

yeccpars2_251(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_251_(Stack),
 'yeccgoto_\'ZorM_<enumerator>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_252(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<const_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_253(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 55, [S | Ss], [T | Stack]);
yeccpars2_253(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<const_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_254(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<const_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<const_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_256(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<const_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_257(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<const_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_258(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 262, [S | Ss], [T | Stack]);
yeccpars2_258(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_259(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<const_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_260(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<const_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_261(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<fixed_pt_const_type>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_262(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 263, [S | Ss], [T | Stack]);
yeccpars2_262(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_263: see yeccpars2_102

yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_264_(Stack),
 'yeccgoto_\'<const_dcl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_265(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_265_(Stack),
 'yeccgoto_\'OE_preproc\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_266(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 70, [S | Ss], [T | Stack]);
yeccpars2_266(S, '<string_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 267, [S | Ss], [T | Stack]);
yeccpars2_266(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_267(S, '<integer_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 269, [S | Ss], [T | Stack]);
yeccpars2_267(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_267_(Stack),
 yeccpars2_268(268, Cat, [267 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_268(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 271, [S | Ss], [T | Stack]);
yeccpars2_268(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_269(S, '<integer_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 269, [S | Ss], [T | Stack]);
yeccpars2_269(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_269_(Stack),
 yeccpars2_270(_S, Cat, [269 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_270(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_270_(Stack),
 'yeccgoto_\'ZorM_<integer_literal>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_271(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_271_(Stack),
 'yeccgoto_\'OE_preproc\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_272(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_272_(Stack),
 'yeccgoto_\'<definition>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_273(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_273_(Stack),
 'yeccgoto_\'<definition>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_274_(Stack),
 'yeccgoto_\'<definition>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_275(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_275_(Stack),
 yeccpars2_276(276, Cat, [275 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_276(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 18, [S | Ss], [T | Stack]);
yeccpars2_276(S, const, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 19, [S | Ss], [T | Stack]);
yeccpars2_276(S, enum, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 20, [S | Ss], [T | Stack]);
yeccpars2_276(S, exception, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 21, [S | Ss], [T | Stack]);
yeccpars2_276(S, oneway, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 290, [S | Ss], [T | Stack]);
yeccpars2_276(S, readonly, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 291, [S | Ss], [T | Stack]);
yeccpars2_276(S, struct, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 24, [S | Ss], [T | Stack]);
yeccpars2_276(S, typedef, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 25, [S | Ss], [T | Stack]);
yeccpars2_276(S, union, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 26, [S | Ss], [T | Stack]);
yeccpars2_276(_S, '::', Ss, Stack, T, Ts, Tzr) ->
 NewStack = 'yeccpars2_276_::'(Stack),
 yeccpars2_280(280, '::', [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 NewStack = 'yeccpars2_276_<identifier>'(Stack),
 yeccpars2_280(280, '<identifier>', [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, 'Object', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_Object(Stack),
 yeccpars2_280(280, 'Object', [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, any, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_any(Stack),
 yeccpars2_280(280, any, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, boolean, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_boolean(Stack),
 yeccpars2_280(280, boolean, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, char, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_char(Stack),
 yeccpars2_280(280, char, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, double, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_double(Stack),
 yeccpars2_280(280, double, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, float, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_float(Stack),
 yeccpars2_280(280, float, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, long, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_long(Stack),
 yeccpars2_280(280, long, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, octet, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_octet(Stack),
 yeccpars2_280(280, octet, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, short, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_short(Stack),
 yeccpars2_280(280, short, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, string, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_string(Stack),
 yeccpars2_280(280, string, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, unsigned, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_unsigned(Stack),
 yeccpars2_280(280, unsigned, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, void, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_void(Stack),
 yeccpars2_280(280, void, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, wchar, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_wchar(Stack),
 yeccpars2_280(280, wchar, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, wstring, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_wstring(Stack),
 yeccpars2_280(280, wstring, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, attribute, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_attribute(Stack),
 yeccpars2_279(279, attribute, [276 | Ss], NewStack, T, Ts, Tzr);
yeccpars2_276(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<interface_body>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_277(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 278, [S | Ss], [T | Stack]);
yeccpars2_277(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_278(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_278_(Stack),
 'yeccgoto_\'<interface_dcl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_279(S, attribute, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 340, [S | Ss], [T | Stack]);
yeccpars2_279(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_280(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_280(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_280(S, 'Object', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 100, [S | Ss], [T | Stack]);
yeccpars2_280(S, any, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 101, [S | Ss], [T | Stack]);
yeccpars2_280(S, double, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 104, [S | Ss], [T | Stack]);
yeccpars2_280(S, float, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 106, [S | Ss], [T | Stack]);
yeccpars2_280(S, octet, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 107, [S | Ss], [T | Stack]);
yeccpars2_280(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 109, [S | Ss], [T | Stack]);
yeccpars2_280(S, void, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 302, [S | Ss], [T | Stack]);
yeccpars2_280(S, wstring, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 112, [S | Ss], [T | Stack]);
yeccpars2_280(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_19(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_281(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<export>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_282(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<export>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_283(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 296, [S | Ss], [T | Stack]);
yeccpars2_283(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_284(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 295, [S | Ss], [T | Stack]);
yeccpars2_284(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_285(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Opt_<op_attribute>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_286(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_286_(Stack),
 'yeccgoto_\'ZorM_<export>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_287(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 294, [S | Ss], [T | Stack]);
yeccpars2_287(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_288(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 293, [S | Ss], [T | Stack]);
yeccpars2_288(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_289(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 292, [S | Ss], [T | Stack]);
yeccpars2_289(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_290(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<op_attribute>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_291(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Opt_readonly\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_292_(Stack),
 'yeccgoto_\'<export>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_293(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_293_(Stack),
 'yeccgoto_\'<export>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_294(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_294_(Stack),
 'yeccgoto_\'<export>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_295(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_295_(Stack),
 'yeccgoto_\'<export>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_296(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_296_(Stack),
 'yeccgoto_\'<export>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<param_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_298(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 55, [S | Ss], [T | Stack]);
yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<param_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_299(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<op_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_300(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 303, [S | Ss], [T | Stack]);
yeccpars2_300(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<param_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_302(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<op_type_spec>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_303(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 305, [S | Ss], [T | Stack]);
yeccpars2_303(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_304(S, raises, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 326, [S | Ss], [T | Stack]);
yeccpars2_304(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_304_(Stack),
 yeccpars2_324(324, Cat, [304 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_305(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_305_(Stack),
 yeccpars2_306(306, Cat, [305 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_306(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_306(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 309, [S | Ss], [T | Stack]);
yeccpars2_306(S, in, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 310, [S | Ss], [T | Stack]);
yeccpars2_306(S, inout, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 311, [S | Ss], [T | Stack]);
yeccpars2_306(S, out, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 312, [S | Ss], [T | Stack]);
yeccpars2_306(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_307(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_307_(Stack),
 yeccpars2_317(317, Cat, [307 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_308(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 42, [S | Ss], [T | Stack]);
yeccpars2_308(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 43, [S | Ss], [T | Stack]);
yeccpars2_308(S, 'Object', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 100, [S | Ss], [T | Stack]);
yeccpars2_308(S, any, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 101, [S | Ss], [T | Stack]);
yeccpars2_308(S, double, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 104, [S | Ss], [T | Stack]);
yeccpars2_308(S, float, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 106, [S | Ss], [T | Stack]);
yeccpars2_308(S, octet, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 107, [S | Ss], [T | Stack]);
yeccpars2_308(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 109, [S | Ss], [T | Stack]);
yeccpars2_308(S, wstring, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 112, [S | Ss], [T | Stack]);
yeccpars2_308(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_19(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_309(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_309_(Stack),
 'yeccgoto_\'<parameter_dcls>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_310(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<param_attribute>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_311(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<param_attribute>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_312(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<param_attribute>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_313(S, '<identifier>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 315, [S | Ss], [T | Stack]);
yeccpars2_313(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_314(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_314_(Stack),
 'yeccgoto_\'<param_dcl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_315(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<simple_declarator>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_316(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 319, [S | Ss], [T | Stack]);
yeccpars2_316(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_316_(Stack),
 yeccpars2_318(318, Cat, [316 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_317(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_317(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'ZorM_<param_dcl>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_318(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_318(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 320, [S | Ss], [T | Stack]);
yeccpars2_318(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_319(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_319_(Stack),
 'yeccgoto_\'<parameter_dcls>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_320(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_320_(Stack),
 yeccpars2_321(321, Cat, [320 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_321(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_321(S, in, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 310, [S | Ss], [T | Stack]);
yeccpars2_321(S, inout, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 311, [S | Ss], [T | Stack]);
yeccpars2_321(S, out, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 312, [S | Ss], [T | Stack]);
yeccpars2_321(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_322(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_322_(Stack),
 yeccpars2_323(323, Cat, [322 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_323(S, '#', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 68, [S | Ss], [T | Stack]);
yeccpars2_323(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_323_(Stack),
 'yeccgoto_\'ZorM_<param_dcl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_324(S, context, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 333, [S | Ss], [T | Stack]);
yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_324_(Stack),
 yeccpars2_331(_S, Cat, [324 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_325(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Opt_<raises_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_326(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 327, [S | Ss], [T | Stack]);
yeccpars2_326(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_327: see yeccpars2_229

yeccpars2_328(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 55, [S | Ss], [T | Stack]);
yeccpars2_328(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_328_(Stack),
 yeccpars2_329(329, Cat, [328 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_329(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 330, [S | Ss], [T | Stack]);
yeccpars2_329(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 232, [S | Ss], [T | Stack]);
yeccpars2_329(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_330(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_330_(Stack),
 'yeccgoto_\'<raises_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_331(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_331_(Stack),
 'yeccgoto_\'<op_dcl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_332(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Opt_<context_expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_333(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 334, [S | Ss], [T | Stack]);
yeccpars2_333(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_334(S, '<string_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 335, [S | Ss], [T | Stack]);
yeccpars2_334(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_335(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_335_(Stack),
 yeccpars2_336(336, Cat, [335 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_336(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 337, [S | Ss], [T | Stack]);
yeccpars2_336(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 338, [S | Ss], [T | Stack]);
yeccpars2_336(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_337(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_337_(Stack),
 'yeccgoto_\'<context_expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_338(S, '<string_literal>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 339, [S | Ss], [T | Stack]);
yeccpars2_338(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_339(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_339_(Stack),
 'yeccgoto_\'ZorM_<string_literal>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_340: see yeccpars2_308

%% yeccpars2_341: see yeccpars2_313

yeccpars2_342(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_342_(Stack),
 yeccpars2_343(343, Cat, [342 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_343(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(Ts, Tzr, 344, [S | Ss], [T | Stack]);
yeccpars2_343(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_343_(Stack),
 'yeccgoto_\'<attr_dcl>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_344: see yeccpars2_313

yeccpars2_345(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_345_(Stack),
 'yeccgoto_\'ZorM_<simple_declarator>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_346(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_346_(Stack),
 'yeccgoto_\'<definition>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_347(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_347_(Stack),
 'yeccgoto_\'<definition>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

'yeccgoto_\'<add_expr>\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(153, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(155, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(158, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(156, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_157(157, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(161, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(202, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<add_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<add_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'<and_expr>\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(161, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_162(162, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(202, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<and_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<and_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'<any_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<any_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<any_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<any_type>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<any_type>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<any_type>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<any_type>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<any_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<any_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<array_declarator>\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<array_declarator>\''(174=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<array_declarator>\''(188=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<array_declarator>\''(217=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<array_declarator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<array_declarator>', State, missing_in_goto_table}}).

'yeccgoto_\'<attr_dcl>\''(276, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_289(289, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<attr_dcl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<attr_dcl>', State, missing_in_goto_table}}).

'yeccgoto_\'<base_type_spec>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<base_type_spec>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<base_type_spec>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<base_type_spec>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<base_type_spec>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<base_type_spec>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<base_type_spec>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<base_type_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<base_type_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<boolean_literal>\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(115=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(128=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(143=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(144=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(146=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(147=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(148=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(155=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(156=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(159=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(161=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(193=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(202=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(204=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_literal>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<boolean_literal>', State, missing_in_goto_table}}).

'yeccgoto_\'<boolean_type>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_260(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_type>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_41(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_type>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_type>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_type>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_type>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<boolean_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<boolean_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<case>\''(58=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_62(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<case>\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_64(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<case>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<case>', State, missing_in_goto_table}}).

'yeccgoto_\'<case_label>\''(65=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<case_label>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<case_label>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<case_label>', State, missing_in_goto_table}}).

'yeccgoto_\'<char_type>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<char_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<char_type>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_40(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<char_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<char_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<char_type>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<char_type>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<char_type>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<char_type>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<char_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<char_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<complex_declarator>\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<complex_declarator>\''(174=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<complex_declarator>\''(188=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<complex_declarator>\''(217=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<complex_declarator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<complex_declarator>', State, missing_in_goto_table}}).

'yeccgoto_\'<const_dcl>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(17, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_dcl>\''(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(17, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_dcl>\''(222, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(17, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_dcl>\''(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(17, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_dcl>\''(276, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(288, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_dcl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<const_dcl>', State, missing_in_goto_table}}).

'yeccgoto_\'<const_exp>\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(208, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_exp>\''(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_exp>\''(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_141(141, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_exp>\''(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_exp>\''(193=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_exp>\''(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_exp>\''(202=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_exp>\''(204=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_exp>\''(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_exp>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<const_exp>', State, missing_in_goto_table}}).

'yeccgoto_\'<const_type>\''(19, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_258(258, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<const_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<const_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<constr_forward_decl>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<constr_forward_decl>\''(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<constr_forward_decl>\''(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<constr_forward_decl>\''(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<constr_forward_decl>\''(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<constr_forward_decl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<constr_forward_decl>', State, missing_in_goto_table}}).

'yeccgoto_\'<constr_type_spec>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<constr_type_spec>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<constr_type_spec>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<constr_type_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<constr_type_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<context_expr>\''(324=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_332(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<context_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<context_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'<declarator>\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<declarator>\''(174=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_177(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<declarator>\''(188=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<declarator>\''(217=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_177(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<declarator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<declarator>', State, missing_in_goto_table}}).

'yeccgoto_\'<declarators>\''(174=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<declarators>\''(217=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_219(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<declarators>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<declarators>', State, missing_in_goto_table}}).

'yeccgoto_\'<definition>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_15(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<definition>\''(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<definition>\''(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_15(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<definition>\''(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<definition>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<definition>', State, missing_in_goto_table}}).

'yeccgoto_\'<element_spec>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_93(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<element_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<element_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<enum_type>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enum_type>\''(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enum_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enum_type>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_39(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enum_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enum_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enum_type>\''(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enum_type>\''(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enum_type>\''(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enum_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<enum_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<enumerator>\''(242=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_243(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enumerator>\''(250=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_251(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<enumerator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<enumerator>', State, missing_in_goto_table}}).

'yeccgoto_\'<except_dcl>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(13, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<except_dcl>\''(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(13, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<except_dcl>\''(222, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(13, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<except_dcl>\''(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(13, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<except_dcl>\''(276, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_287(287, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<except_dcl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<except_dcl>', State, missing_in_goto_table}}).

'yeccgoto_\'<export>\''(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_286(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<export>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<export>', State, missing_in_goto_table}}).

'yeccgoto_\'<fixed_array_size>\''(180=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<fixed_array_size>\''(181=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<fixed_array_size>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<fixed_array_size>', State, missing_in_goto_table}}).

'yeccgoto_\'<fixed_pt_const_type>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_257(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<fixed_pt_const_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<fixed_pt_const_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<fixed_pt_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<fixed_pt_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<fixed_pt_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<fixed_pt_type>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<fixed_pt_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<fixed_pt_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<floating_pt_type>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_256(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<floating_pt_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<floating_pt_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<floating_pt_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<floating_pt_type>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<floating_pt_type>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<floating_pt_type>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<floating_pt_type>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<floating_pt_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<floating_pt_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<forward_dcl>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<forward_dcl>\''(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<forward_dcl>\''(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<forward_dcl>\''(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<forward_dcl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<forward_dcl>', State, missing_in_goto_table}}).

'yeccgoto_\'<inheritance_spec>\''(226=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<inheritance_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<inheritance_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<integer_type>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<integer_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<integer_type>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_38(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<integer_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<integer_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<integer_type>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<integer_type>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<integer_type>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<integer_type>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<integer_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<integer_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<interface>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface>\''(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface>\''(222, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface>\''(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<interface>', State, missing_in_goto_table}}).

'yeccgoto_\'<interface_body>\''(275, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_277(277, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface_body>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<interface_body>', State, missing_in_goto_table}}).

'yeccgoto_\'<interface_dcl>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface_dcl>\''(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface_dcl>\''(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface_dcl>\''(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface_dcl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<interface_dcl>', State, missing_in_goto_table}}).

'yeccgoto_\'<interface_header>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface_header>\''(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface_header>\''(222, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface_header>\''(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<interface_header>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<interface_header>', State, missing_in_goto_table}}).

'yeccgoto_\'<literal>\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(115=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(128=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(143=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(144=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(146=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(147=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(148=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(155=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(156=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(159=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(161=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(193=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(202=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(204=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<literal>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<literal>', State, missing_in_goto_table}}).

'yeccgoto_\'<member>\''(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<member>\''(169=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_173(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<member>\''(236=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_238(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<member>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<member>', State, missing_in_goto_table}}).

'yeccgoto_\'<member_list>\''(167, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_170(170, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<member_list>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<member_list>', State, missing_in_goto_table}}).

'yeccgoto_\'<module>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<module>\''(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<module>\''(222, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<module>\''(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<module>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<module>', State, missing_in_goto_table}}).

'yeccgoto_\'<mult_expr>\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(143, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_152(152, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(144, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_145(145, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(153, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(155, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(156, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(161, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(202, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(122, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<mult_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<mult_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'<octet_type>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<octet_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<octet_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<octet_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<octet_type>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<octet_type>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<octet_type>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<octet_type>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<octet_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<octet_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<op_attribute>\''(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_285(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<op_attribute>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<op_attribute>', State, missing_in_goto_table}}).

'yeccgoto_\'<op_dcl>\''(276, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_284(284, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<op_dcl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<op_dcl>', State, missing_in_goto_table}}).

'yeccgoto_\'<op_type_spec>\''(280, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_300(300, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<op_type_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<op_type_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<or_expr>\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<or_expr>\''(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<or_expr>\''(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<or_expr>\''(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<or_expr>\''(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<or_expr>\''(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<or_expr>\''(202, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<or_expr>\''(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<or_expr>\''(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<or_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<or_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'<param_attribute>\''(306, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_308(308, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<param_attribute>\''(321, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_308(308, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<param_attribute>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<param_attribute>', State, missing_in_goto_table}}).

'yeccgoto_\'<param_dcl>\''(306=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_307(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<param_dcl>\''(321=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_322(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<param_dcl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<param_dcl>', State, missing_in_goto_table}}).

'yeccgoto_\'<param_type_spec>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<param_type_spec>\''(308, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_313(313, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<param_type_spec>\''(340, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_313(341, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<param_type_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<param_type_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<parameter_dcls>\''(303, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_304(304, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<parameter_dcls>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<parameter_dcls>', State, missing_in_goto_table}}).

'yeccgoto_\'<positive_int_const>\''(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_120(120, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<positive_int_const>\''(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(184, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<positive_int_const>\''(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_194(194, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<positive_int_const>\''(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(200, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<positive_int_const>\''(202, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(203, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<positive_int_const>\''(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_205(205, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<positive_int_const>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<positive_int_const>', State, missing_in_goto_table}}).

'yeccgoto_\'<primary_expr>\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(115=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_164(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(128=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(143=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(144=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(146=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(147=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(148=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(155=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(156=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(159=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(161=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(193=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(202=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(204=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<primary_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<primary_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'<raises_expr>\''(304=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_325(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<raises_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<raises_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'<scoped_name>\''(19, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_253(253, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(25, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(87, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(29, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_37(37, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(87, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(115, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(143, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(144, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(146, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(147, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(148, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(153, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(155, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(156, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(161, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(168, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(87, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(196, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(87, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(202, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(229, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(230, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(232, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_233(233, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(280, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(298, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(308, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(298, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(327, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_328(328, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(340, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(298, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<scoped_name>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<scoped_name>', State, missing_in_goto_table}}).

'yeccgoto_\'<sequence_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<sequence_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<sequence_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<sequence_type>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<sequence_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<sequence_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<shift_expr>\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(153, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_154(154, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(161, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(202, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<shift_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<shift_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'<signed_int>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_int>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_int>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_int>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_int>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_int>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_int>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_int>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_int>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_int>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<signed_int>', State, missing_in_goto_table}}).

'yeccgoto_\'<signed_long_int>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_long_int>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_long_int>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_long_int>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_long_int>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_long_int>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_long_int>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_long_int>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_long_int>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_long_int>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<signed_long_int>', State, missing_in_goto_table}}).

'yeccgoto_\'<signed_short_int>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_short_int>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_short_int>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_short_int>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_short_int>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_short_int>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_short_int>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_short_int>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_short_int>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<signed_short_int>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<signed_short_int>', State, missing_in_goto_table}}).

'yeccgoto_\'<simple_declarator>\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_declarator>\''(174=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_declarator>\''(188=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_declarator>\''(217=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_declarator>\''(313=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_314(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_declarator>\''(341=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_342(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_declarator>\''(344=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_345(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_declarator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<simple_declarator>', State, missing_in_goto_table}}).

'yeccgoto_\'<simple_type_spec>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_type_spec>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_type_spec>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_type_spec>\''(196, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(197, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<simple_type_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<simple_type_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<specification>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(7, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<specification>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<specification>', State, missing_in_goto_table}}).

'yeccgoto_\'<string_type>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_252(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<string_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_84(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<string_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_84(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<string_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_84(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<string_type>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_84(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<string_type>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<string_type>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<string_type>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<string_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<string_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<struct_type>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<struct_type>\''(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<struct_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<struct_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<struct_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<struct_type>\''(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<struct_type>\''(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<struct_type>\''(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<struct_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<struct_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<switch_body>\''(58, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(61, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<switch_body>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<switch_body>', State, missing_in_goto_table}}).

'yeccgoto_\'<switch_type_spec>\''(29, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_33(33, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<switch_type_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<switch_type_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<template_type_spec>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<template_type_spec>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<template_type_spec>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<template_type_spec>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<template_type_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<template_type_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<type_dcl>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<type_dcl>\''(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<type_dcl>\''(222, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<type_dcl>\''(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<type_dcl>\''(276, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_283(283, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<type_dcl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<type_dcl>', State, missing_in_goto_table}}).

'yeccgoto_\'<type_declarator>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_218(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<type_declarator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<type_declarator>', State, missing_in_goto_table}}).

'yeccgoto_\'<type_spec>\''(25, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(217, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<type_spec>\''(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(81, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<type_spec>\''(168, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(174, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<type_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<type_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'<unary_expr>\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(128=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(143=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(144=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(146=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(147=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(148=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_149(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(155=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(156=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(159=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(161=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(193=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(202=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(204=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<unary_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'<unary_operator>\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(143, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(144, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(146, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(147, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(148, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(153, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(155, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(156, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(161, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(202, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(115, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unary_operator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<unary_operator>', State, missing_in_goto_table}}).

'yeccgoto_\'<union_type>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<union_type>\''(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<union_type>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_80(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<union_type>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_80(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<union_type>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_80(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<union_type>\''(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<union_type>\''(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<union_type>\''(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<union_type>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<union_type>', State, missing_in_goto_table}}).

'yeccgoto_\'<unsigned_int>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_int>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_int>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_int>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_int>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_int>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_int>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_int>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_int>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_int>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<unsigned_int>', State, missing_in_goto_table}}).

'yeccgoto_\'<unsigned_long_int>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_long_int>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_long_int>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_long_int>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_long_int>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_long_int>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_long_int>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_long_int>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_long_int>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_long_int>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<unsigned_long_int>', State, missing_in_goto_table}}).

'yeccgoto_\'<unsigned_short_int>\''(19=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_short_int>\''(25=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_short_int>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_short_int>\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_short_int>\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_short_int>\''(196=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_short_int>\''(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_short_int>\''(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_short_int>\''(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<unsigned_short_int>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<unsigned_short_int>', State, missing_in_goto_table}}).

'yeccgoto_\'<xor_expr>\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(159, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_160(160, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(202, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<xor_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'<xor_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'OE_pragma\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(59=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(65=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(168=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(190=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(192=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(210=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(211=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(213=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(216=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(237=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(242=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(245=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(247=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(250=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_282(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(306=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(317=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(318=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(321=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(323=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_pragma\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'OE_pragma', State, missing_in_goto_table}}).

'yeccgoto_\'OE_preproc\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_preproc\''(1=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_preproc\''(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_preproc\''(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_preproc\''(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_281(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OE_preproc\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'OE_preproc', State, missing_in_goto_table}}).

'yeccgoto_\'OorM_<case>\''(58=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_60(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OorM_<case>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'OorM_<case>', State, missing_in_goto_table}}).

'yeccgoto_\'OorM_<case_label>\''(59=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OorM_<case_label>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'OorM_<case_label>', State, missing_in_goto_table}}).

'yeccgoto_\'OorM_<definition>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OorM_<definition>\''(222, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(223, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OorM_<definition>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'OorM_<definition>', State, missing_in_goto_table}}).

'yeccgoto_\'OorM_<fixed_array_size>\''(180, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_181(181, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OorM_<fixed_array_size>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'OorM_<fixed_array_size>', State, missing_in_goto_table}}).

'yeccgoto_\'OorM_<member>\''(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_169(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OorM_<member>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'OorM_<member>', State, missing_in_goto_table}}).

'yeccgoto_\'Opt_<context_expr>\''(324=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_331(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Opt_<context_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'Opt_<context_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'Opt_<inheritance_spec>\''(226=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Opt_<inheritance_spec>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'Opt_<inheritance_spec>', State, missing_in_goto_table}}).

'yeccgoto_\'Opt_<op_attribute>\''(276, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_280(280, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Opt_<op_attribute>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'Opt_<op_attribute>', State, missing_in_goto_table}}).

'yeccgoto_\'Opt_<raises_expr>\''(304, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_324(324, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Opt_<raises_expr>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'Opt_<raises_expr>', State, missing_in_goto_table}}).

'yeccgoto_\'Opt_readonly\''(276, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_279(279, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Opt_readonly\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'Opt_readonly', State, missing_in_goto_table}}).

'yeccgoto_\'Ugly_pragmas\''(58, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_59(59, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(59, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(65, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_59(59, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(66, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_79(79, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(93, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(211, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(96, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(210, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(167, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(168, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(169, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(168, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(176, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(190, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(191, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(192, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(212, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_213(213, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(215, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_216(216, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(235, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_237(237, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(236, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(168, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(241, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_242(242, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(243, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(245, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(246, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_247(247, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(248, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_242(250, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(305, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_306(306, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(307, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_317(317, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(316, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_318(318, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(320, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_321(321, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(322, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_323(323, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Ugly_pragmas\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'Ugly_pragmas', State, missing_in_goto_table}}).

'yeccgoto_\'ZorM_<declarator>\''(177, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(187, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<declarator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'ZorM_<declarator>', State, missing_in_goto_table}}).

'yeccgoto_\'ZorM_<enumerator>\''(245=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_246(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<enumerator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'ZorM_<enumerator>', State, missing_in_goto_table}}).

'yeccgoto_\'ZorM_<export>\''(275, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_276(276, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<export>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'ZorM_<export>', State, missing_in_goto_table}}).

'yeccgoto_\'ZorM_<integer_literal>\''(267, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_268(268, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<integer_literal>\''(269=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<integer_literal>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'ZorM_<integer_literal>', State, missing_in_goto_table}}).

'yeccgoto_\'ZorM_<member>\''(235, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_236(236, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<member>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'ZorM_<member>', State, missing_in_goto_table}}).

'yeccgoto_\'ZorM_<param_dcl>\''(307, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_316(316, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<param_dcl>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'ZorM_<param_dcl>', State, missing_in_goto_table}}).

'yeccgoto_\'ZorM_<scoped_name>\''(230, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_231(231, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<scoped_name>\''(328, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_329(329, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<scoped_name>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'ZorM_<scoped_name>', State, missing_in_goto_table}}).

'yeccgoto_\'ZorM_<simple_declarator>\''(342, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_343(343, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<simple_declarator>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'ZorM_<simple_declarator>', State, missing_in_goto_table}}).

'yeccgoto_\'ZorM_<string_literal>\''(335, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_336(336, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'ZorM_<string_literal>\''(State, _Cat, _Ss, _Stack, _T, _Ts, _Tzr) ->
 erlang:error({yecc_bug,"1.4",{'ZorM_<string_literal>', State, missing_in_goto_table}}).

-compile({inline,yeccpars2_1_/1}).
-file("icparse.yrl", 290).
yeccpars2_1_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   reverse ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_15_/1}).
-file("icparse.yrl", 294).
yeccpars2_15_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_27_/1}).
-file("icparse.yrl", 837).
yeccpars2_27_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # constr_forward { id = __2 , tk = tk_union }
  end | __Stack].

-compile({inline,yeccpars2_32_/1}).
-file("icparse.yrl", 546).
yeccpars2_32_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { unsigned , __1 }
  end | __Stack].

-compile({inline,yeccpars2_43_/1}).
-file("icparse.yrl", 373).
yeccpars2_43_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ic_symtab : scoped_id_new ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_50_/1}).
-file("icparse.yrl", 569).
yeccpars2_50_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_51_/1}).
-file("icparse.yrl", 574).
yeccpars2_51_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_52_/1}).
-file("icparse.yrl", 570).
yeccpars2_52_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { 'long long' , element ( 2 , __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_53_/1}).
-file("icparse.yrl", 556).
yeccpars2_53_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { 'long long' , element ( 2 , __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_54_/1}).
-file("icparse.yrl", 374).
yeccpars2_54_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   ic_symtab : scoped_id_new_global ( __2 )
  end | __Stack].

-compile({inline,yeccpars2_56_/1}).
-file("icparse.yrl", 376).
yeccpars2_56_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ic_symtab : scoped_id_add ( __1 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_58_/1}).
-file("icparse.yrl", 261).
yeccpars2_58_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_59_/1}).
-file("icparse.yrl", 261).
yeccpars2_59_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,'yeccpars2_60_#'/1}).
-file("icparse.yrl", 261).
'yeccpars2_60_#'(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_60_case/1}).
-file("icparse.yrl", 261).
yeccpars2_60_case(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_60_default/1}).
-file("icparse.yrl", 261).
yeccpars2_60_default(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_60_/1}).
-file("icparse.yrl", 644).
yeccpars2_60_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   reverse ( lists : flatten ( __1 ) )
  end | __Stack].

-compile({inline,yeccpars2_62_/1}).
-file("icparse.yrl", 650).
yeccpars2_62_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_63_/1}).
-file("icparse.yrl", 632).
yeccpars2_63_(__Stack0) ->
 [__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # union { id = __2 , type = __5 , body = __8 }
  end | __Stack].

-compile({inline,yeccpars2_64_/1}).
-file("icparse.yrl", 651).
yeccpars2_64_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_66_/1}).
-file("icparse.yrl", 261).
yeccpars2_66_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_67_/1}).
-file("icparse.yrl", 262).
yeccpars2_67_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_74_/1}).
-file("icparse.yrl", 242).
yeccpars2_74_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # pragma { type = __4 , to = followed , apply = __5 }
  end | __Stack].

-compile({inline,yeccpars2_77_/1}).
-file("icparse.yrl", 247).
yeccpars2_77_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # pragma { type = __4 , to = __5 , apply = __6 }
  end | __Stack].

-compile({inline,yeccpars2_78_/1}).
-file("icparse.yrl", 252).
yeccpars2_78_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # pragma { type = __4 , to = __5 , apply = ic_options : float_to_version ( __6 ) }
  end | __Stack].

-compile({inline,yeccpars2_93_/1}).
-file("icparse.yrl", 261).
yeccpars2_93_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_96_/1}).
-file("icparse.yrl", 261).
yeccpars2_96_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_109_/1}).
-file("icparse.yrl", 719).
yeccpars2_109_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # string { }
  end | __Stack].

-compile({inline,yeccpars2_112_/1}).
-file("icparse.yrl", 723).
yeccpars2_112_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # wstring { }
  end | __Stack].

-compile({inline,yeccpars2_142_/1}).
-file("icparse.yrl", 447).
yeccpars2_142_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_145_/1}).
-file("icparse.yrl", 423).
yeccpars2_145_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { '-' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_149_/1}).
-file("icparse.yrl", 429).
yeccpars2_149_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { '/' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_150_/1}).
-file("icparse.yrl", 428).
yeccpars2_150_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { '*' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_151_/1}).
-file("icparse.yrl", 430).
yeccpars2_151_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { '%' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_152_/1}).
-file("icparse.yrl", 422).
yeccpars2_152_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { '+' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_154_/1}).
-file("icparse.yrl", 411).
yeccpars2_154_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { 'and' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_157_/1}).
-file("icparse.yrl", 416).
yeccpars2_157_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { rshift , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_158_/1}).
-file("icparse.yrl", 417).
yeccpars2_158_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { lshift , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_160_/1}).
-file("icparse.yrl", 401).
yeccpars2_160_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { 'or' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_162_/1}).
-file("icparse.yrl", 406).
yeccpars2_162_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { 'xor' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_163_/1}).
-file("icparse.yrl", 722).
yeccpars2_163_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # wstring { length = __3 }
  end | __Stack].

-compile({inline,yeccpars2_164_/1}).
-file("icparse.yrl", 434).
yeccpars2_164_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { __1 , __2 }
  end | __Stack].

-compile({inline,yeccpars2_167_/1}).
-file("icparse.yrl", 261).
yeccpars2_167_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,'yeccpars2_169_#'/1}).
-file("icparse.yrl", 261).
'yeccpars2_169_#'(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,'yeccpars2_169_::'/1}).
-file("icparse.yrl", 261).
'yeccpars2_169_::'(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,'yeccpars2_169_<identifier>'/1}).
-file("icparse.yrl", 261).
'yeccpars2_169_<identifier>'(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_Object/1}).
-file("icparse.yrl", 261).
yeccpars2_169_Object(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_any/1}).
-file("icparse.yrl", 261).
yeccpars2_169_any(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_boolean/1}).
-file("icparse.yrl", 261).
yeccpars2_169_boolean(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_char/1}).
-file("icparse.yrl", 261).
yeccpars2_169_char(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_double/1}).
-file("icparse.yrl", 261).
yeccpars2_169_double(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_enum/1}).
-file("icparse.yrl", 261).
yeccpars2_169_enum(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_fixed/1}).
-file("icparse.yrl", 261).
yeccpars2_169_fixed(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_float/1}).
-file("icparse.yrl", 261).
yeccpars2_169_float(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_long/1}).
-file("icparse.yrl", 261).
yeccpars2_169_long(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_octet/1}).
-file("icparse.yrl", 261).
yeccpars2_169_octet(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_sequence/1}).
-file("icparse.yrl", 261).
yeccpars2_169_sequence(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_short/1}).
-file("icparse.yrl", 261).
yeccpars2_169_short(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_string/1}).
-file("icparse.yrl", 261).
yeccpars2_169_string(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_struct/1}).
-file("icparse.yrl", 261).
yeccpars2_169_struct(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_union/1}).
-file("icparse.yrl", 261).
yeccpars2_169_union(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_unsigned/1}).
-file("icparse.yrl", 261).
yeccpars2_169_unsigned(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_wchar/1}).
-file("icparse.yrl", 261).
yeccpars2_169_wchar(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_wstring/1}).
-file("icparse.yrl", 261).
yeccpars2_169_wstring(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_169_/1}).
-file("icparse.yrl", 604).
yeccpars2_169_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   reverse ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_172_/1}).
-file("icparse.yrl", 600).
yeccpars2_172_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # struct { id = __2 , body = __4 }
  end | __Stack].

-compile({inline,yeccpars2_173_/1}).
-file("icparse.yrl", 614).
yeccpars2_173_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2 ++ __1
  end | __Stack].

-compile({inline,yeccpars2_176_/1}).
-file("icparse.yrl", 261).
yeccpars2_176_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_177_/1}).
-file("icparse.yrl", 521).
yeccpars2_177_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_181_/1}).
-file("icparse.yrl", 728).
yeccpars2_181_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # array { id = __1 , size = reverse ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_182_/1}).
-file("icparse.yrl", 732).
yeccpars2_182_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_185_/1}).
-file("icparse.yrl", 738).
yeccpars2_185_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_186_/1}).
-file("icparse.yrl", 734).
yeccpars2_186_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_187_/1}).
-file("icparse.yrl", 518).
yeccpars2_187_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | reverse ( __2 ) ]
  end | __Stack].

-compile({inline,yeccpars2_189_/1}).
-file("icparse.yrl", 523).
yeccpars2_189_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_191_/1}).
-file("icparse.yrl", 261).
yeccpars2_191_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_192_/1}).
-file("icparse.yrl", 623).
yeccpars2_192_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __1 ++ __4 ++ __6 ++ [ # member { type = __2 , id = __3 } ]
  end | __Stack].

-compile({inline,yeccpars2_195_/1}).
-file("icparse.yrl", 718).
yeccpars2_195_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # string { length = __3 }
  end | __Stack].

-compile({inline,yeccpars2_199_/1}).
-file("icparse.yrl", 713).
yeccpars2_199_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # sequence { type = __3 }
  end | __Stack].

-compile({inline,yeccpars2_201_/1}).
-file("icparse.yrl", 711).
yeccpars2_201_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # sequence { type = __3 , length = __5 }
  end | __Stack].

-compile({inline,yeccpars2_206_/1}).
-file("icparse.yrl", 833).
yeccpars2_206_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # fixed { digits = __3 , scale = __5 }
  end | __Stack].

-compile({inline,yeccpars2_207_/1}).
-file("icparse.yrl", 677).
yeccpars2_207_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_209_/1}).
-file("icparse.yrl", 676).
yeccpars2_209_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_210_/1}).
-file("icparse.yrl", 672).
yeccpars2_210_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2 ++ [ __3 | __1 ] ++ __4
  end | __Stack].

-compile({inline,yeccpars2_212_/1}).
-file("icparse.yrl", 261).
yeccpars2_212_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_213_/1}).
-file("icparse.yrl", 662).
yeccpars2_213_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __1 ++ __3 ++ __5 ++ __7 ++ [ __4 # case_dcl { label = reverse ( __2 ) } ]
  end | __Stack].

-compile({inline,yeccpars2_214_/1}).
-file("icparse.yrl", 682).
yeccpars2_214_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # case_dcl { type = __1 , id = __2 }
  end | __Stack].

-compile({inline,yeccpars2_215_/1}).
-file("icparse.yrl", 261).
yeccpars2_215_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_216_/1}).
-file("icparse.yrl", 670).
yeccpars2_216_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __1 ++ [ __2 ] ++ __3
  end | __Stack].

-compile({inline,yeccpars2_218_/1}).
-file("icparse.yrl", 471).
yeccpars2_218_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_219_/1}).
-file("icparse.yrl", 479).
yeccpars2_219_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # typedef { type = __1 , id = __2 }
  end | __Stack].

-compile({inline,yeccpars2_220_/1}).
-file("icparse.yrl", 836).
yeccpars2_220_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # constr_forward { id = __2 , tk = tk_struct }
  end | __Stack].

-compile({inline,yeccpars2_224_/1}).
-file("icparse.yrl", 296).
yeccpars2_224_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_225_/1}).
-file("icparse.yrl", 311).
yeccpars2_225_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # module { id = __2 , body = reverse ( __4 ) }
  end | __Stack].

-compile({inline,'yeccpars2_226_;'/1}).
-file("icparse.yrl", 327).
'yeccpars2_226_;'(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # forward { id = __2 }
  end | __Stack].

-compile({inline,yeccpars2_226_/1}).
-file("icparse.yrl", 358).
yeccpars2_226_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_227_/1}).
-file("icparse.yrl", 332).
yeccpars2_227_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { __2 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_230_/1}).
-file("icparse.yrl", 367).
yeccpars2_230_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_231_/1}).
-file("icparse.yrl", 363).
yeccpars2_231_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | reverse ( __3 ) ]
  end | __Stack].

-compile({inline,yeccpars2_233_/1}).
-file("icparse.yrl", 369).
yeccpars2_233_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_235_/1}).
-file("icparse.yrl", 261).
yeccpars2_235_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_236_/1}).
-file("icparse.yrl", 261).
yeccpars2_236_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_238_/1}).
-file("icparse.yrl", 854).
yeccpars2_238_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2 ++ __1
  end | __Stack].

-compile({inline,yeccpars2_239_/1}).
-file("icparse.yrl", 754).
yeccpars2_239_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # except { id = __2 , body = reverse ( __4 ) }
  end | __Stack].

-compile({inline,yeccpars2_241_/1}).
-file("icparse.yrl", 261).
yeccpars2_241_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_243_/1}).
-file("icparse.yrl", 261).
yeccpars2_243_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_244_/1}).
-file("icparse.yrl", 705).
yeccpars2_244_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # enumerator { id = __1 }
  end | __Stack].

-compile({inline,yeccpars2_245_/1}).
-file("icparse.yrl", 700).
yeccpars2_245_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_246_/1}).
-file("icparse.yrl", 261).
yeccpars2_246_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_248_/1}).
-file("icparse.yrl", 261).
yeccpars2_248_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_249_/1}).
-file("icparse.yrl", 692).
yeccpars2_249_(__Stack0) ->
 [__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # enum { id = __2 , body = __4 ++ __6 ++ __8 ++ [ __5 | reverse ( __7 ) ] }
  end | __Stack].

-compile({inline,yeccpars2_251_/1}).
-file("icparse.yrl", 702).
yeccpars2_251_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2 ++ __4 ++ [ __5 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_264_/1}).
-file("icparse.yrl", 381).
yeccpars2_264_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # const { type = __2 , id = __3 , val = __5 }
  end | __Stack].

-compile({inline,yeccpars2_265_/1}).
-file("icparse.yrl", 0).
yeccpars2_265_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_267_/1}).
-file("icparse.yrl", 285).
yeccpars2_267_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_269_/1}).
-file("icparse.yrl", 285).
yeccpars2_269_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_270_/1}).
-file("icparse.yrl", 287).
yeccpars2_270_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_271_/1}).
-file("icparse.yrl", 272).
yeccpars2_271_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   case __4 of
    [ ] ->
    case __2 of
    { _ , _ , "1" } ->
    # preproc { cat = line_nr , id = __3 , aux = __4 } ;
    _ ->
    [ ]
    end ;
    _ ->
    # preproc { cat = line_nr , id = __3 , aux = __4 }
    end
  end | __Stack].

-compile({inline,yeccpars2_272_/1}).
-file("icparse.yrl", 301).
yeccpars2_272_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_273_/1}).
-file("icparse.yrl", 302).
yeccpars2_273_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_274_/1}).
-file("icparse.yrl", 303).
yeccpars2_274_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_275_/1}).
-file("icparse.yrl", 340).
yeccpars2_275_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,'yeccpars2_276_::'/1}).
-file("icparse.yrl", 761).
'yeccpars2_276_::'(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,'yeccpars2_276_<identifier>'/1}).
-file("icparse.yrl", 761).
'yeccpars2_276_<identifier>'(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_Object/1}).
-file("icparse.yrl", 761).
yeccpars2_276_Object(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_any/1}).
-file("icparse.yrl", 761).
yeccpars2_276_any(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_boolean/1}).
-file("icparse.yrl", 761).
yeccpars2_276_boolean(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_char/1}).
-file("icparse.yrl", 761).
yeccpars2_276_char(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_double/1}).
-file("icparse.yrl", 761).
yeccpars2_276_double(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_float/1}).
-file("icparse.yrl", 761).
yeccpars2_276_float(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_long/1}).
-file("icparse.yrl", 761).
yeccpars2_276_long(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_octet/1}).
-file("icparse.yrl", 761).
yeccpars2_276_octet(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_short/1}).
-file("icparse.yrl", 761).
yeccpars2_276_short(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_string/1}).
-file("icparse.yrl", 761).
yeccpars2_276_string(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_unsigned/1}).
-file("icparse.yrl", 761).
yeccpars2_276_unsigned(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_void/1}).
-file("icparse.yrl", 761).
yeccpars2_276_void(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_wchar/1}).
-file("icparse.yrl", 761).
yeccpars2_276_wchar(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_wstring/1}).
-file("icparse.yrl", 761).
yeccpars2_276_wstring(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_276_attribute/1}).
-file("icparse.yrl", 858).
yeccpars2_276_attribute(__Stack0) ->
 [begin
   nil
  end | __Stack0].

-compile({inline,yeccpars2_278_/1}).
-file("icparse.yrl", 321).
yeccpars2_278_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # interface { id = element ( 1 , __1 ) , inherit = element ( 2 , __1 ) ,
    body = lists : reverse ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_286_/1}).
-file("icparse.yrl", 343).
yeccpars2_286_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   if is_list ( __2 ) -> __2 ++ __1 ;
    true -> [ __2 | __1 ]
    end
  end | __Stack].

-compile({inline,yeccpars2_292_/1}).
-file("icparse.yrl", 352).
yeccpars2_292_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_293_/1}).
-file("icparse.yrl", 350).
yeccpars2_293_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_294_/1}).
-file("icparse.yrl", 351).
yeccpars2_294_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_295_/1}).
-file("icparse.yrl", 353).
yeccpars2_295_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_296_/1}).
-file("icparse.yrl", 349).
yeccpars2_296_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_304_/1}).
-file("icparse.yrl", 807).
yeccpars2_304_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_305_/1}).
-file("icparse.yrl", 261).
yeccpars2_305_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_307_/1}).
-file("icparse.yrl", 261).
yeccpars2_307_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_309_/1}).
-file("icparse.yrl", 780).
yeccpars2_309_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_314_/1}).
-file("icparse.yrl", 797).
yeccpars2_314_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # param { inout = __1 , type = __2 , id = __3 }
  end | __Stack].

-compile({inline,yeccpars2_316_/1}).
-file("icparse.yrl", 261).
yeccpars2_316_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_319_/1}).
-file("icparse.yrl", 779).
yeccpars2_319_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2 ++ [ __3 | reverse ( __4 ) ]
  end | __Stack].

-compile({inline,yeccpars2_320_/1}).
-file("icparse.yrl", 261).
yeccpars2_320_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_322_/1}).
-file("icparse.yrl", 261).
yeccpars2_322_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_323_/1}).
-file("icparse.yrl", 790).
yeccpars2_323_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2 ++ __4 ++ __6 ++ [ __5 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_324_/1}).
-file("icparse.yrl", 816).
yeccpars2_324_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_328_/1}).
-file("icparse.yrl", 367).
yeccpars2_328_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_330_/1}).
-file("icparse.yrl", 812).
yeccpars2_330_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | reverse ( __4 ) ]
  end | __Stack].

-compile({inline,yeccpars2_331_/1}).
-file("icparse.yrl", 758).
yeccpars2_331_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # op { oneway = __1 , type = __2 , id = __3 , params = __4 , raises = __5 , ctx = __6 }
  end | __Stack].

-compile({inline,yeccpars2_335_/1}).
-file("icparse.yrl", 840).
yeccpars2_335_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_337_/1}).
-file("icparse.yrl", 821).
yeccpars2_337_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | reverse ( __4 ) ]
  end | __Stack].

-compile({inline,yeccpars2_339_/1}).
-file("icparse.yrl", 842).
yeccpars2_339_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_342_/1}).
-file("icparse.yrl", 845).
yeccpars2_342_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_343_/1}).
-file("icparse.yrl", 744).
yeccpars2_343_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # attr { readonly = __1 , type = __3 , id = [ __4 | reverse ( __5 ) ] }
  end | __Stack].

-compile({inline,yeccpars2_345_/1}).
-file("icparse.yrl", 847).
yeccpars2_345_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_346_/1}).
-file("icparse.yrl", 304).
yeccpars2_346_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].

-compile({inline,yeccpars2_347_/1}).
-file("icparse.yrl", 300).
yeccpars2_347_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __1
  end | __Stack].


-file("icparse.yrl", 872).
