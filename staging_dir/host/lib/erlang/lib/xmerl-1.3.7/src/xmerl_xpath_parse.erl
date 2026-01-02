-module(xmerl_xpath_parse).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("xmerl_xpath_parse.yrl", 302).

% token({Token, _Line}) ->
% 	Token;
% token({Token, _Line, _Value}) ->
% 	Token.

value({Token, _Line}) ->
	Token;
value({_Token, _Line, Value}) ->
	Value.

-file("/net/isildur/ldisk/daily_build/17_prebuild_opu_o.2015-03-31_14/otp_src_17/bootstrap/lib/parsetools/include/yeccpre.hrl", 0).
%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 1996-2013. All Rights Reserved.
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The parser generator will insert appropriate declarations before this line.%

-type yecc_ret() :: {'error', _} | {'ok', _}.

-spec parse(Tokens :: list()) -> yecc_ret().
parse(Tokens) ->
    yeccpars0(Tokens, {no_func, no_line}, 0, [], []).

-spec parse_and_scan({function() | {atom(), atom()}, [_]}
                     | {atom(), atom(), [_]}) -> yecc_ret().
parse_and_scan({F, A}) ->
    yeccpars0([], {{F, A}, no_line}, 0, [], []);
parse_and_scan({M, F, A}) ->
    Arity = length(A),
    yeccpars0([], {{fun M:F/Arity, A}, no_line}, 0, [], []).

-spec format_error(any()) -> [char() | list()].
format_error(Message) ->
    case io_lib:deep_char_list(Message) of
        true ->
            Message;
        _ ->
            io_lib:write(Message)
    end.

%% To be used in grammar files to throw an error message to the parser
%% toplevel. Doesn't have to be exported!
-compile({nowarn_unused_function, return_error/2}).
-spec return_error(integer(), any()) -> no_return().
return_error(Line, Message) ->
    throw({error, {Line, ?MODULE, Message}}).

-define(CODE_VERSION, "1.4").

yeccpars0(Tokens, Tzr, State, States, Vstack) ->
    try yeccpars1(Tokens, Tzr, State, States, Vstack)
    catch 
        error: Error ->
            Stacktrace = erlang:get_stacktrace(),
            try yecc_error_type(Error, Stacktrace) of
                Desc ->
                    erlang:raise(error, {yecc_bug, ?CODE_VERSION, Desc},
                                 Stacktrace)
            catch _:_ -> erlang:raise(error, Error, Stacktrace)
            end;
        %% Probably thrown from return_error/2:
        throw: {error, {_Line, ?MODULE, _M}} = Error ->
            Error
    end.

yecc_error_type(function_clause, [{?MODULE,F,ArityOrArgs,_} | _]) ->
    case atom_to_list(F) of
        "yeccgoto_" ++ SymbolL ->
            {ok,[{atom,_,Symbol}],_} = erl_scan:string(SymbolL),
            State = case ArityOrArgs of
                        [S,_,_,_,_,_,_] -> S;
                        _ -> state_is_unknown
                    end,
            {Symbol, State, missing_in_goto_table}
    end.

yeccpars1([Token | Tokens], Tzr, State, States, Vstack) ->
    yeccpars2(State, element(1, Token), States, Vstack, Token, Tokens, Tzr);
yeccpars1([], {{F, A},_Line}, State, States, Vstack) ->
    case apply(F, A) of
        {ok, Tokens, Endline} ->
            yeccpars1(Tokens, {{F, A}, Endline}, State, States, Vstack);
        {eof, Endline} ->
            yeccpars1([], {no_func, Endline}, State, States, Vstack);
        {error, Descriptor, _Endline} ->
            {error, Descriptor}
    end;
yeccpars1([], {no_func, no_line}, State, States, Vstack) ->
    Line = 999999,
    yeccpars2(State, '$end', States, Vstack, yecc_end(Line), [],
              {no_func, Line});
yeccpars1([], {no_func, Endline}, State, States, Vstack) ->
    yeccpars2(State, '$end', States, Vstack, yecc_end(Endline), [],
              {no_func, Endline}).

%% yeccpars1/7 is called from generated code.
%%
%% When using the {includefile, Includefile} option, make sure that
%% yeccpars1/7 can be found by parsing the file without following
%% include directives. yecc will otherwise assume that an old
%% yeccpre.hrl is included (one which defines yeccpars1/5).
yeccpars1(State1, State, States, Vstack, Token0, [Token | Tokens], Tzr) ->
    yeccpars2(State, element(1, Token), [State1 | States],
              [Token0 | Vstack], Token, Tokens, Tzr);
yeccpars1(State1, State, States, Vstack, Token0, [], {{_F,_A}, _Line}=Tzr) ->
    yeccpars1([], Tzr, State, [State1 | States], [Token0 | Vstack]);
yeccpars1(State1, State, States, Vstack, Token0, [], {no_func, no_line}) ->
    Line = yecctoken_end_location(Token0),
    yeccpars2(State, '$end', [State1 | States], [Token0 | Vstack],
              yecc_end(Line), [], {no_func, Line});
yeccpars1(State1, State, States, Vstack, Token0, [], {no_func, Line}) ->
    yeccpars2(State, '$end', [State1 | States], [Token0 | Vstack],
              yecc_end(Line), [], {no_func, Line}).

%% For internal use only.
yecc_end({Line,_Column}) ->
    {'$end', Line};
yecc_end(Line) ->
    {'$end', Line}.

yecctoken_end_location(Token) ->
    try
        {text, Str} = erl_scan:token_info(Token, text),
        {line, Line} = erl_scan:token_info(Token, line),
        Parts = re:split(Str, "\n"),
        Dline = length(Parts) - 1,
        Yline = Line + Dline,
        case erl_scan:token_info(Token, column) of
            {column, Column} ->
                Col = byte_size(lists:last(Parts)),
                {Yline, Col + if Dline =:= 0 -> Column; true -> 1 end};
            undefined ->
                Yline
        end
    catch _:_ ->
        yecctoken_location(Token)
    end.

-compile({nowarn_unused_function, yeccerror/1}).
yeccerror(Token) ->
    Text = yecctoken_to_string(Token),
    Location = yecctoken_location(Token),
    {error, {Location, ?MODULE, ["syntax error before: ", Text]}}.

-compile({nowarn_unused_function, yecctoken_to_string/1}).
yecctoken_to_string(Token) ->
    case catch erl_scan:token_info(Token, text) of
        {text, Txt} -> Txt;
        _ -> yecctoken2string(Token)
    end.

yecctoken_location(Token) ->
    case catch erl_scan:token_info(Token, location) of
        {location, Loc} -> Loc;
        _ -> element(2, Token)
    end.

-compile({nowarn_unused_function, yecctoken2string/1}).
yecctoken2string({atom, _, A}) -> io_lib:write(A);
yecctoken2string({integer,_,N}) -> io_lib:write(N);
yecctoken2string({float,_,F}) -> io_lib:write(F);
yecctoken2string({char,_,C}) -> io_lib:write_char(C);
yecctoken2string({var,_,V}) -> io_lib:format("~s", [V]);
yecctoken2string({string,_,S}) -> io_lib:write_string(S);
yecctoken2string({reserved_symbol, _, A}) -> io_lib:write(A);
yecctoken2string({_Cat, _, Val}) -> io_lib:format("~p",[Val]);
yecctoken2string({dot, _}) -> "'.'";
yecctoken2string({'$end', _}) ->
    [];
yecctoken2string({Other, _}) when is_atom(Other) ->
    io_lib:write(Other);
yecctoken2string(Other) ->
    io_lib:write(Other).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



-file("./xmerl_xpath_parse.erl", 199).

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
%% yeccpars2(18=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_18(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(19=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_19(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(20=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_20(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(21=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_21(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(22=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_22(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(23=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(24=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(30=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(31=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(32=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(33=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_33(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(34=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_34(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(35=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_35(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(36=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(37=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_37(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(38=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_38(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(39=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_39(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(40=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_40(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(41=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_41(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(47=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_47(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(48=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_48(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(49=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_49(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(50=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_50(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(51=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_51(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(52=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_52(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(53=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(54=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_54(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(55=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(56=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_56(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(57=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_57(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(58=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_58(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(59=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_59(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(60=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(61=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_61(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(62=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_62(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(63=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(64=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_64(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(65=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(66=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(67=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_67(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(68=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(69=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(70=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_70(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(71=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_71(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(72=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_72(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(73=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(74=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_74(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(75=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_75(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(76=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(77=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(78=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_78(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(79=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(80=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_80(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(81=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(82=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(83=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_83(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(84=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_84(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(85=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_85(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(86=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_86(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(87=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(88=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(89=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(90=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(91=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_91(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(92=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(93=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(94=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(95=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(96=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_96(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(97=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_97(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(98=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_98(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(99=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_99(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(100=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_100(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(101=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_101(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(102=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_28(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(103=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_28(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(104=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_104(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(105=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_105(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(106=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_106(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(107=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(108=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_108(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(109=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_109(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(110=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_110(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(Other, _, _, _, _, _, _) ->
 erlang:error({yecc_bug,"1.4",{missing_state_in_action_table, Other}}).

yeccpars2_0(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, '..', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, axis, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, function_name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, literal, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, number, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, var_reference, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_1(S, '|', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 109, Ss, Stack, T, Ts, Tzr);
yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'UnaryExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'MultiplicativeExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'RelativeLocationPath\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_4(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_4_(Stack),
 'yeccgoto_\'LocationPath\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_5(S, '<', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_5(S, '<=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_5(S, '>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_5(S, '>=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_5(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'EqualityExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'FilterExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'UnionExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_8(S, 'or', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 107, Ss, Stack, T, Ts, Tzr);
yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Expr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_9(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_9_(Stack),
 'yeccgoto_\'Step\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'NodeTest\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_11(S, '*', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_11(S, 'div', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_11(S, mod, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'AdditiveExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'PathExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'PrimaryExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_14(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'PathExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_15(_S, '$end', _Ss, Stack, _T, _Ts, _Tzr) ->
 {ok, hd(Stack)};
yeccpars2_15(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_16(S, '!=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_16(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'AndExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_17(S, 'and', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_17(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'OrExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_18(S, '+', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'RelationalExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_19_(Stack),
 'yeccgoto_\'LocationPath\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_20_(Stack),
 'yeccgoto_\'Step\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'RelativeLocationPath\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'RelativeLocationPath\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_23: see yeccpars2_0

%% yeccpars2_24: see yeccpars2_0

yeccpars2_25(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'AbbreviatedStep\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_26(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'AbbreviatedStep\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_27(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(S, '..', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(S, axis, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(S, node_type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(S, prefix_test, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(S, 'processing-instruction', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(S, wildcard, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_27(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_27_(Stack),
 'yeccgoto_\'AbsoluteLocationPath\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_28(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, '..', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, axis, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_29(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_29(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_30(S, '::', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_30(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_31(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_31(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_32_(Stack),
 'yeccgoto_\'PrimaryExpr\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_33(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_33_(Stack),
 'yeccgoto_\'NameTest\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_34(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_34(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_35_(Stack),
 'yeccgoto_\'PrimaryExpr\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_36_(Stack),
 'yeccgoto_\'NameTest\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_37(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_37(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_38(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_38_(Stack),
 'yeccgoto_\'PrimaryExpr\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_39(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_39_(Stack),
 'yeccgoto_\'NameTest\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_40(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_40(S, literal, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_40(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_41(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_41_(Stack),
 'yeccgoto_\'NodeTest\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_42(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_42(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_43(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_43_(Stack),
 'yeccgoto_\'NodeTest\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_44(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_44(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_45(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_45_(Stack),
 'yeccgoto_\'NodeTest\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_46(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, '..', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, axis, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, function_name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, literal, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, number, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, var_reference, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_46(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'Argument\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_48_(Stack),
 'yeccgoto_\'<ArgumentMember>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_49(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_49(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_49_(Stack),
 'yeccgoto_\'<ArgumentList>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_50(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_50(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_51(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_51_(Stack),
 'yeccgoto_\'FunctionCall\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_52(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_52_(Stack),
 'yeccgoto_\'FunctionCall\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_53: see yeccpars2_0

yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_54_(Stack),
 'yeccgoto_\'<ArgumentMember>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_55(S, name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_55(S, node_type, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_55(S, prefix_test, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_55(S, 'processing-instruction', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_55(S, wildcard, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_55(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_56(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_56(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_56_(Stack),
 'yeccgoto_\'Step\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_57_(Stack),
 'yeccgoto_\'<PredicateMember>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_58(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_58_(Stack),
 'yeccgoto_\'<PredicateList>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_59_(Stack),
 'yeccgoto_\'Step\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_60: see yeccpars2_0

yeccpars2_61(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_61(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_62(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'PredicateExpr\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_63(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_63_(Stack),
 'yeccgoto_\'Predicate\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_64(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_64_(Stack),
 'yeccgoto_\'<PredicateMember>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_65(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_65_(Stack),
 'yeccgoto_\'Step\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_66_(Stack),
 'yeccgoto_\'Step\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_67(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_67(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_67_(Stack),
 'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_68(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, '..', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, axis, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_69: see yeccpars2_68

yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_70_(Stack),
 'yeccgoto_\'AbbreviatedRelativeLocationPath\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_71_(Stack),
 'yeccgoto_\'RelativeLocationPath\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_72(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_72(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_72_(Stack),
 'yeccgoto_\'AbsoluteLocationPath\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_73_(Stack),
 'yeccgoto_\'UnaryExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_74(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_75(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_75_(Stack),
 'yeccgoto_\'PrimaryExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_76: see yeccpars2_0

%% yeccpars2_77: see yeccpars2_0

yeccpars2_78(S, '*', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_78(S, 'div', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_78(S, mod, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_78(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_78_(Stack),
 'yeccgoto_\'AdditiveExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_79: see yeccpars2_0

yeccpars2_80(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_80_(Stack),
 'yeccgoto_\'MultiplyOperator\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_81: see yeccpars2_0

%% yeccpars2_82: see yeccpars2_0

yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_83_(Stack),
 'yeccgoto_\'MultiplicativeExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_84(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_84_(Stack),
 'yeccgoto_\'MultiplicativeExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_85_(Stack),
 'yeccgoto_\'MultiplicativeExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_86(S, '*', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_86(S, 'div', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_86(S, mod, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_86_(Stack),
 'yeccgoto_\'AdditiveExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_87: see yeccpars2_0

yeccpars2_88(S, '!=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_88(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_88_(Stack),
 'yeccgoto_\'AndExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_89: see yeccpars2_0

%% yeccpars2_90: see yeccpars2_0

yeccpars2_91(S, '<', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, '<=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, '>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(S, '>=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_91_(Stack),
 'yeccgoto_\'EqualityExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_92: see yeccpars2_0

%% yeccpars2_93: see yeccpars2_0

%% yeccpars2_94: see yeccpars2_0

%% yeccpars2_95: see yeccpars2_0

yeccpars2_96(S, '+', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_96(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_96_(Stack),
 'yeccgoto_\'RelationalExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_97(S, '+', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_97_(Stack),
 'yeccgoto_\'RelationalExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_98(S, '+', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_98_(Stack),
 'yeccgoto_\'RelationalExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_99(S, '+', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_99(S, '-', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_99_(Stack),
 'yeccgoto_\'RelationalExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_100(S, '<', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, '<=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, '>', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, '>=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_100_(Stack),
 'yeccgoto_\'EqualityExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_101_(Stack),
 'yeccgoto_\'FilterExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_102: see yeccpars2_28

%% yeccpars2_103: see yeccpars2_28

yeccpars2_104(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_104(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_104_(Stack),
 'yeccgoto_\'PathExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_105(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_105(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_105(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_105_(Stack),
 'yeccgoto_\'PathExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_106_(Stack),
 'yeccgoto_\'Step\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_107: see yeccpars2_0

yeccpars2_108(S, 'and', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_108(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_108_(Stack),
 'yeccgoto_\'OrExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_109(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, '..', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, '/', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, '//', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, '@', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, axis, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, function_name, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, literal, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, number, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, var_reference, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_110(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_110_(Stack),
 'yeccgoto_\'UnionExpr\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

'yeccgoto_\'<ArgumentList>\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_50(50, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<ArgumentMember>\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_49(49, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<PredicateList>\''(9=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<PredicateList>\''(56=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<PredicateList>\''(65=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<PredicateMember>\''(9, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<PredicateMember>\''(56, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<PredicateMember>\''(65, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(27=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedAbsoluteLocationPath\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'AbbreviatedRelativeLocationPath\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(27=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedRelativeLocationPath\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'AbbreviatedStep\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(27=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(69=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbbreviatedStep\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'AbsoluteLocationPath\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AbsoluteLocationPath\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'AdditiveExpr\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(18, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(18, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(18, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(18, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(18, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(87, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(18, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(18, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(18, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(92, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(99, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(93, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(98, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(94, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(95, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_96(96, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AdditiveExpr\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_18(18, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'AndExpr\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(17, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AndExpr\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(17, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AndExpr\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(17, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AndExpr\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(17, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AndExpr\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(17, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'AndExpr\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_108(108, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Argument\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Argument\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'EqualityExpr\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(16, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EqualityExpr\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(16, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EqualityExpr\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(16, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EqualityExpr\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(16, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EqualityExpr\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(16, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EqualityExpr\''(87, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(88, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'EqualityExpr\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(16, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Expr\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_15(15, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Expr\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(74, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Expr\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Expr\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Expr\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_62(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FilterExpr\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(24, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(77, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(82, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(87, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(92, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(93, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(94, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(95, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FilterExpr\''(109, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'FunctionCall\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'FunctionCall\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'LocationPath\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'LocationPath\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'MultiplicativeExpr\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_86(86, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(77, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_78(78, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(87, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(92, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(93, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(94, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(95, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplicativeExpr\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'MultiplyOperator\''(11, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(79, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplyOperator\''(78, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(79, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'MultiplyOperator\''(86, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(79, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'NameTest\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(27=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(55=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(69=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NameTest\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'NodeTest\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(24, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(27, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(55, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(56, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(68, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(69, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(77, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(82, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(87, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(92, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(93, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(94, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(95, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(103, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'NodeTest\''(109, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'OrExpr\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OrExpr\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OrExpr\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OrExpr\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'OrExpr\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'PathExpr\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PathExpr\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_110(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Predicate\''(9=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Predicate\''(14=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Predicate\''(56=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Predicate\''(58=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_64(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Predicate\''(65=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'PredicateExpr\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(61, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'PrimaryExpr\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'PrimaryExpr\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'RelationalExpr\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelationalExpr\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelationalExpr\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelationalExpr\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelationalExpr\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelationalExpr\''(87, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelationalExpr\''(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_100(100, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelationalExpr\''(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(91, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelationalExpr\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'RelativeLocationPath\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(24, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(27, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(72, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(67, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(77, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(82, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(87, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(92, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(93, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(94, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(95, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(102, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_105(105, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(103, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(104, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'RelativeLocationPath\''(109, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'Step\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(27=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(69=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(102=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'Step\''(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'UnaryExpr\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(23=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(46=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(53=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(60=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(77=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(79=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_84(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(82=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(94=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(95=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnaryExpr\''(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'UnionExpr\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(23, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(24, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(46, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(53, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(60, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(77, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(79, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(82, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(87, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(92, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(93, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(94, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(95, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'UnionExpr\''(107, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr).

-compile({inline,yeccpars2_4_/1}).
-file("xmerl_xpath_parse.yrl", 96).
yeccpars2_4_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { path , rel , __1 }
  end | __Stack].

-compile({inline,yeccpars2_9_/1}).
-file("xmerl_xpath_parse.yrl", 122).
yeccpars2_9_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { step , { child , __1 , [ ] } }
  end | __Stack].

-compile({inline,yeccpars2_19_/1}).
-file("xmerl_xpath_parse.yrl", 97).
yeccpars2_19_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { path , abs , __1 }
  end | __Stack].

-compile({inline,yeccpars2_20_/1}).
-file("xmerl_xpath_parse.yrl", 124).
yeccpars2_20_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { abbrev_step , __1 }
  end | __Stack].

-compile({inline,yeccpars2_27_/1}).
-file("xmerl_xpath_parse.yrl", 101).
yeccpars2_27_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '/'
  end | __Stack].

-compile({inline,yeccpars2_32_/1}).
-file("xmerl_xpath_parse.yrl", 176).
yeccpars2_32_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { literal , value ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_33_/1}).
-file("xmerl_xpath_parse.yrl", 294).
yeccpars2_33_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { name , value ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_35_/1}).
-file("xmerl_xpath_parse.yrl", 177).
yeccpars2_35_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { number , value ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_36_/1}).
-file("xmerl_xpath_parse.yrl", 293).
yeccpars2_36_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prefix_test , value ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_38_/1}).
-file("xmerl_xpath_parse.yrl", 174).
yeccpars2_38_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { variable_reference , value ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_39_/1}).
-file("xmerl_xpath_parse.yrl", 292).
yeccpars2_39_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { wildcard , value ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_41_/1}).
-file("xmerl_xpath_parse.yrl", 143).
yeccpars2_41_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { node_type , value ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_43_/1}).
-file("xmerl_xpath_parse.yrl", 145).
yeccpars2_43_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { processing_instruction , value ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_45_/1}).
-file("xmerl_xpath_parse.yrl", 142).
yeccpars2_45_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { node_type , value ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_48_/1}).
-file("xmerl_xpath_parse.yrl", 190).
yeccpars2_48_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_49_/1}).
-file("xmerl_xpath_parse.yrl", 186).
yeccpars2_49_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lists : reverse ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_51_/1}).
-file("xmerl_xpath_parse.yrl", 182).
yeccpars2_51_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { function_call , value ( __1 ) , [ ] }
  end | __Stack].

-compile({inline,yeccpars2_52_/1}).
-file("xmerl_xpath_parse.yrl", 184).
yeccpars2_52_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { function_call , value ( __1 ) , __3 }
  end | __Stack].

-compile({inline,yeccpars2_54_/1}).
-file("xmerl_xpath_parse.yrl", 189).
yeccpars2_54_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_56_/1}).
-file("xmerl_xpath_parse.yrl", 114).
yeccpars2_56_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { step , { value ( __1 ) , __3 , [ ] } }
  end | __Stack].

-compile({inline,yeccpars2_57_/1}).
-file("xmerl_xpath_parse.yrl", 132).
yeccpars2_57_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_58_/1}).
-file("xmerl_xpath_parse.yrl", 127).
yeccpars2_58_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lists : reverse ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_59_/1}).
-file("xmerl_xpath_parse.yrl", 112).
yeccpars2_59_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { step , { value ( __1 ) , __3 , __4 } }
  end | __Stack].

-compile({inline,yeccpars2_63_/1}).
-file("xmerl_xpath_parse.yrl", 149).
yeccpars2_63_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { pred , __2 }
  end | __Stack].

-compile({inline,yeccpars2_64_/1}).
-file("xmerl_xpath_parse.yrl", 131).
yeccpars2_64_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_65_/1}).
-file("xmerl_xpath_parse.yrl", 118).
yeccpars2_65_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { step , { attribute , __2 , [ ] } }
  end | __Stack].

-compile({inline,yeccpars2_66_/1}).
-file("xmerl_xpath_parse.yrl", 116).
yeccpars2_66_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { step , { value ( __1 ) , __2 , __3 } }
  end | __Stack].

-compile({inline,yeccpars2_67_/1}).
-file("xmerl_xpath_parse.yrl", 156).
yeccpars2_67_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { '//' , __2 }
  end | __Stack].

-compile({inline,yeccpars2_70_/1}).
-file("xmerl_xpath_parse.yrl", 160).
yeccpars2_70_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { __1 , '//' , __3 }
  end | __Stack].

-compile({inline,yeccpars2_71_/1}).
-file("xmerl_xpath_parse.yrl", 107).
yeccpars2_71_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { refine , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_72_/1}).
-file("xmerl_xpath_parse.yrl", 100).
yeccpars2_72_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_73_/1}).
-file("xmerl_xpath_parse.yrl", 263).
yeccpars2_73_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { negative , __2 }
  end | __Stack].

-compile({inline,yeccpars2_75_/1}).
-file("xmerl_xpath_parse.yrl", 175).
yeccpars2_75_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_78_/1}).
-file("xmerl_xpath_parse.yrl", 248).
yeccpars2_78_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { arith , '-' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_80_/1}).
-file("xmerl_xpath_parse.yrl", 288).
yeccpars2_80_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '*'
  end | __Stack].

-compile({inline,yeccpars2_83_/1}).
-file("xmerl_xpath_parse.yrl", 258).
yeccpars2_83_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { arith , mod , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_84_/1}).
-file("xmerl_xpath_parse.yrl", 256).
yeccpars2_84_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { arith , 'div' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_85_/1}).
-file("xmerl_xpath_parse.yrl", 254).
yeccpars2_85_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { arith , __2 , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_86_/1}).
-file("xmerl_xpath_parse.yrl", 246).
yeccpars2_86_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { arith , '+' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_88_/1}).
-file("xmerl_xpath_parse.yrl", 222).
yeccpars2_88_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { bool , 'and' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_91_/1}).
-file("xmerl_xpath_parse.yrl", 227).
yeccpars2_91_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { comp , '=' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_96_/1}).
-file("xmerl_xpath_parse.yrl", 240).
yeccpars2_96_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { comp , '>=' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_97_/1}).
-file("xmerl_xpath_parse.yrl", 236).
yeccpars2_97_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { comp , '>' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_98_/1}).
-file("xmerl_xpath_parse.yrl", 238).
yeccpars2_98_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { comp , '<=' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_99_/1}).
-file("xmerl_xpath_parse.yrl", 234).
yeccpars2_99_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { comp , '<' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_100_/1}).
-file("xmerl_xpath_parse.yrl", 229).
yeccpars2_100_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { comp , '!=' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_101_/1}).
-file("xmerl_xpath_parse.yrl", 210).
yeccpars2_101_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { path , filter , { __1 , __2 } }
  end | __Stack].

-compile({inline,yeccpars2_104_/1}).
-file("xmerl_xpath_parse.yrl", 206).
yeccpars2_104_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { __1 , '//' , __3 }
  end | __Stack].

-compile({inline,yeccpars2_105_/1}).
-file("xmerl_xpath_parse.yrl", 205).
yeccpars2_105_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { refine , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_106_/1}).
-file("xmerl_xpath_parse.yrl", 120).
yeccpars2_106_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { step , { child , __1 , __2 } }
  end | __Stack].

-compile({inline,yeccpars2_108_/1}).
-file("xmerl_xpath_parse.yrl", 216).
yeccpars2_108_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { bool , 'or' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_110_/1}).
-file("xmerl_xpath_parse.yrl", 199).
yeccpars2_110_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { path , union , { __1 , __3 } }
  end | __Stack].


-file("xmerl_xpath_parse.yrl", 313).
