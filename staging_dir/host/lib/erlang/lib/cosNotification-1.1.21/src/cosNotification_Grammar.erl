-module(cosNotification_Grammar).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("cosNotification_Grammar.yrl", 131).
%%--------------------------------------------------------------------
%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 1999-2009. All Rights Reserved.
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
%%----------------------------------------------------------------------
%% File    : cosNotification_Grammar.erl
%% Purpose : THIS FILE HAS BEEN GENERATED. DO NOT EDIT!!!!
%%----------------------------------------------------------------------

-include("CosNotification_Definitions.hrl").

create_unary('+', Val) when is_number(Val) -> Val;
create_unary('-', Val) when is_number(Val) -> -Val;
create_unary(_, _) -> return_error(0, "syntax error").

examin_comp({T, []}) ->
	{T, '$empty'};
examin_comp(V) ->
	V.


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



-file("./cosNotification_Grammar.erl", 224).

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
yeccpars2(14=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(15=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_15(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(16=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(17=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_17(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(27=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_27(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(28=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_28(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(29=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_29(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(30=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_30(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(36=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_36(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(37=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(38=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_32(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(39=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_39(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(40=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_40(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(41=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_41(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(42=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_42(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(43=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_43(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(44=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_44(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(51=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_51(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(52=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_52(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(58=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_58(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(59=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_59(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(60=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_60(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(61=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(62=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_62(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(63=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_63(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(64=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_64(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(65=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(66=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(67=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_67(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(68=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(69=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(70=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_70(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(71=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(72=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(73=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(74=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_74(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(75=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_75(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(76=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(77=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_77(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(78=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(79=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_79(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(80=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(81=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(82=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_82(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(83=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_83(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(84=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(85=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_85(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(86=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(87=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_87(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(88=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(89=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_89(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(90=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(91=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_91(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(Other, _, _, _, _, _, _) ->
 erlang:error({yecc_bug,"1.4",{missing_state_in_action_table, Other}}).

yeccpars2_0(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, 'ADDOP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, 'FALSE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, 'TRUE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, bslsh, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, default, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, dollar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, exist, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, ident, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, int, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, 'not', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, num, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_0_(Stack),
 yeccpars2_1(1, Cat, [0 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_1(_S, '$end', _Ss, Stack, _T, _Ts, _Tzr) ->
 {ok, hd(Stack)};
yeccpars2_1(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_2(S, 'MULOP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_2(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<expr>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<term>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<factor_not>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_5(S, in, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_5(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<expr_in>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_6(S, 'RELOP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<bool_compare>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_7(S, 'ADDOP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_7(S, '~', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<expr_twiddle>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<toplevel>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_9(S, 'or', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<bool>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<bool_and>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_11(S, 'and', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<bool_or>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 'yeccgoto_\'<constraint>\''(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_13_(Stack),
 'yeccgoto_\'<factor>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_14(S, bslsh, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, ident, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'not', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_14(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_14(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(S, 'ADDOP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(S, 'FALSE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(S, 'TRUE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(S, default, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(S, dollar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(S, exist, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(S, int, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(S, num, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_14(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_15(S, int, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(S, num, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_16_(Stack),
 'yeccgoto_\'<factor>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_17(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_17_(Stack),
 'yeccgoto_\'<factor>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_18(S, ident, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_18(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_19(S, dollar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_19(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_20(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_20(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_20(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_20(S, bslsh, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_20(S, ident, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_20_(Stack),
 yeccpars2_68(_S, Cat, [20 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_21(S, dollar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_21(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_22_(Stack),
 'yeccgoto_\'<Ident>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_23_(Stack),
 'yeccgoto_\'<factor>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_24(S, bslsh, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_24(S, ident, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_24(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_14(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_25(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_25_(Stack),
 'yeccgoto_\'<factor>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_26(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_26_(Stack),
 'yeccgoto_\'<factor>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_27(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_27_(Stack),
 'yeccgoto_\'<factor_not>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_28(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, bslsh, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(S, ident, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_28(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_28_(Stack),
 yeccpars2_30(_S, Cat, [28 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_29(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_29(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_29(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_29_(Stack),
 yeccpars2_67(_S, Cat, [29 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_30_(Stack),
 'yeccgoto_\'<factor>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_31(S, bslsh, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_31(S, ident, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_31(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_32(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_32(S, '_d', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_32(S, '_length', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_32(S, '_repos_id', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_32(S, '_type_id', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_32(S, int, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_32(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_33(S, int, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_33(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_34(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_34(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_35(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_35(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_35(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_35_(Stack),
 yeccpars2_36(_S, Cat, [35 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_36_(Stack),
 'yeccgoto_\'<Component>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_37: see yeccpars2_31

%% yeccpars2_38: see yeccpars2_32

yeccpars2_39(S, int, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_39(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_40(S, ']', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_40(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_41(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_41(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_41(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_41(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_41_(Stack),
 yeccpars2_42(_S, Cat, [41 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_42(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_42_(Stack),
 'yeccgoto_\'<CompExt>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_43(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_43(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_43(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_43(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_43_(Stack),
 yeccpars2_59(_S, Cat, [43 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_44(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_44_(Stack),
 'yeccgoto_\'<CompExt>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_45(S, 'ADDOP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_45(S, int, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_45(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_45(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_45_(Stack),
 yeccpars2_52(52, Cat, [45 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_46(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_46_(Stack),
 'yeccgoto_\'<CompDot>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_47_(Stack),
 'yeccgoto_\'<CompDot>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_48_(Stack),
 'yeccgoto_\'<CompDot>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_49(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_49_(Stack),
 'yeccgoto_\'<CompDot>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_50(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_50(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_50(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_50(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_50_(Stack),
 yeccpars2_51(_S, Cat, [50 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_51(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_51_(Stack),
 'yeccgoto_\'<CompDot>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_52(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_52(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_53(S, int, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_53(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_54_(Stack),
 'yeccgoto_\'<UnionVal>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_55_(Stack),
 'yeccgoto_\'<UnionVal>\''(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_56(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_56_(Stack),
 'yeccgoto_\'<UnionVal>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_57(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_57(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_57(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_57_(Stack),
 yeccpars2_58(_S, Cat, [57 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_58_(Stack),
 'yeccgoto_\'<CompDot>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_59_(Stack),
 'yeccgoto_\'<CompDot>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_60(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_60(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_61(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_61(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_61(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_61(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_61_(Stack),
 yeccpars2_62(_S, Cat, [61 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_62(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_62_(Stack),
 'yeccgoto_\'<CompExt>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_63(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_63_(Stack),
 'yeccgoto_\'<Component>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_64(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_64(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_65(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_65(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_65_(Stack),
 yeccpars2_66(_S, Cat, [65 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_66_(Stack),
 'yeccgoto_\'<Component>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_67_(Stack),
 'yeccgoto_\'<Component>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_68(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_68_(Stack),
 'yeccgoto_\'<factor>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_69(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_69(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_69(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_69(S, bslsh, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_69(S, ident, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_69_(Stack),
 yeccpars2_70(_S, Cat, [69 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_70_(Stack),
 'yeccgoto_\'<factor>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_71_(Stack),
 'yeccgoto_\'<Ident>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_72_(Stack),
 'yeccgoto_\'<factor>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_73_(Stack),
 'yeccgoto_\'<factor>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_74(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(S, 'or', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_75(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_75_(Stack),
 'yeccgoto_\'<factor>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_76: see yeccpars2_14

yeccpars2_77(S, 'and', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_77(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_77_(Stack),
 'yeccgoto_\'<bool_or>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_78: see yeccpars2_14

yeccpars2_79(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_79_(Stack),
 'yeccgoto_\'<bool_and>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_80: see yeccpars2_14

%% yeccpars2_81: see yeccpars2_14

yeccpars2_82(S, 'ADDOP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_82(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_82_(Stack),
 'yeccgoto_\'<expr_twiddle>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_83(S, 'MULOP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_83_(Stack),
 'yeccgoto_\'<expr>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_84: see yeccpars2_14

yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_85_(Stack),
 'yeccgoto_\'<term>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_86: see yeccpars2_14

yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_87_(Stack),
 'yeccgoto_\'<bool_compare>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_88(S, dollar, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_31(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_89_(Stack),
 'yeccgoto_\'<expr_in>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_90(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(S, '[', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(S, bslsh, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(S, ident, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_90_(Stack),
 yeccpars2_91(_S, Cat, [90 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_91_(Stack),
 'yeccgoto_\'<expr_in>\''(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

'yeccgoto_\'<CompDot>\''(32=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<CompDot>\''(38=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_44(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<CompExt>\''(29=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<CompExt>\''(35=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<CompExt>\''(41=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_42(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<CompExt>\''(43=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<CompExt>\''(50=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_51(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<CompExt>\''(57=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<CompExt>\''(61=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_62(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<CompExt>\''(65=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<Component>\''(20=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_68(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Component>\''(28=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Component>\''(69=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Component>\''(90=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<Ident>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(14=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(20, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(29, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(28, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(29, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(31, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_64(64, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(32, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_43(43, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(37, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_60(60, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(38, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_43(43, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(69, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(29, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(78=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(80=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(88=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<Ident>\''(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_29(29, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<UnionVal>\''(45, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_52(52, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<bool>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<bool_and>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<bool_and>\''(14, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<bool_and>\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_77(77, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<bool_compare>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<bool_compare>\''(14=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<bool_compare>\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<bool_compare>\''(78=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_79(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<bool_or>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(9, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<bool_or>\''(14, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(74, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<constraint>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<expr>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(7, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr>\''(14, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(7, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr>\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(7, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr>\''(78, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(7, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr>\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(82, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr>\''(86, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(7, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<expr_in>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(6, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr_in>\''(14, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(6, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr_in>\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(6, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr_in>\''(78, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(6, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr_in>\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<expr_twiddle>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr_twiddle>\''(14, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr_twiddle>\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr_twiddle>\''(78, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<expr_twiddle>\''(86, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<factor>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor>\''(14=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor>\''(24=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_27(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor>\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor>\''(78=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor>\''(80=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor>\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor>\''(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor>\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<factor_not>\''(0=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor_not>\''(14=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor_not>\''(76=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor_not>\''(78=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor_not>\''(80=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor_not>\''(81=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor_not>\''(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<factor_not>\''(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<term>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<term>\''(14, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<term>\''(76, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<term>\''(78, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<term>\''(80, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(83, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<term>\''(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr);
'yeccgoto_\'<term>\''(86, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr).

'yeccgoto_\'<toplevel>\''(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr).

-compile({inline,yeccpars2_0_/1}).
-file("cosNotification_Grammar.yrl", 53).
yeccpars2_0_(__Stack0) ->
 [begin
   '$empty'
  end | __Stack0].

-compile({inline,yeccpars2_13_/1}).
-file("cosNotification_Grammar.yrl", 93).
yeccpars2_13_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   list_to_atom ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_16_/1}).
-file("cosNotification_Grammar.yrl", 90).
yeccpars2_16_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   false
  end | __Stack].

-compile({inline,yeccpars2_17_/1}).
-file("cosNotification_Grammar.yrl", 89).
yeccpars2_17_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   true
  end | __Stack].

-compile({inline,yeccpars2_20_/1}).
-file("cosNotification_Grammar.yrl", 104).
yeccpars2_20_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_22_/1}).
-file("cosNotification_Grammar.yrl", 119).
yeccpars2_22_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   element ( 2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_23_/1}).
-file("cosNotification_Grammar.yrl", 87).
yeccpars2_23_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   element ( 2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_25_/1}).
-file("cosNotification_Grammar.yrl", 86).
yeccpars2_25_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   element ( 2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_26_/1}).
-file("cosNotification_Grammar.yrl", 88).
yeccpars2_26_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   element ( 2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_27_/1}).
-file("cosNotification_Grammar.yrl", 83).
yeccpars2_27_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { 'not' , __2 }
  end | __Stack].

-compile({inline,yeccpars2_28_/1}).
-file("cosNotification_Grammar.yrl", 104).
yeccpars2_28_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_29_/1}).
-file("cosNotification_Grammar.yrl", 109).
yeccpars2_29_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_30_/1}).
-file("cosNotification_Grammar.yrl", 96).
yeccpars2_30_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   examin_comp ( { exist_component , __3 } )
  end | __Stack].

-compile({inline,yeccpars2_35_/1}).
-file("cosNotification_Grammar.yrl", 109).
yeccpars2_35_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_36_/1}).
-file("cosNotification_Grammar.yrl", 101).
yeccpars2_36_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ { arrindex , element ( 2 , __2 ) } | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_41_/1}).
-file("cosNotification_Grammar.yrl", 109).
yeccpars2_41_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_42_/1}).
-file("cosNotification_Grammar.yrl", 107).
yeccpars2_42_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ { arrindex , element ( 2 , __2 ) } | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_43_/1}).
-file("cosNotification_Grammar.yrl", 109).
yeccpars2_43_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_44_/1}).
-file("cosNotification_Grammar.yrl", 106).
yeccpars2_44_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_45_/1}).
-file("cosNotification_Grammar.yrl", 125).
yeccpars2_45_(__Stack0) ->
 [begin
   default
  end | __Stack0].

-compile({inline,yeccpars2_46_/1}).
-file("cosNotification_Grammar.yrl", 115).
yeccpars2_46_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ '_d' ]
  end | __Stack].

-compile({inline,yeccpars2_47_/1}).
-file("cosNotification_Grammar.yrl", 114).
yeccpars2_47_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ '_length' ]
  end | __Stack].

-compile({inline,yeccpars2_48_/1}).
-file("cosNotification_Grammar.yrl", 117).
yeccpars2_48_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ '_repos_id' ]
  end | __Stack].

-compile({inline,yeccpars2_49_/1}).
-file("cosNotification_Grammar.yrl", 116).
yeccpars2_49_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ '_type_id' ]
  end | __Stack].

-compile({inline,yeccpars2_50_/1}).
-file("cosNotification_Grammar.yrl", 109).
yeccpars2_50_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_51_/1}).
-file("cosNotification_Grammar.yrl", 112).
yeccpars2_51_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ { dotint , element ( 2 , __1 ) } | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_54_/1}).
-file("cosNotification_Grammar.yrl", 122).
yeccpars2_54_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { uint , element ( 2 , __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_55_/1}).
-file("cosNotification_Grammar.yrl", 124).
yeccpars2_55_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { ustr , element ( 2 , __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_56_/1}).
-file("cosNotification_Grammar.yrl", 123).
yeccpars2_56_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { uint , create_unary ( element ( 2 , __1 ) , element ( 2 , __2 ) ) }
  end | __Stack].

-compile({inline,yeccpars2_57_/1}).
-file("cosNotification_Grammar.yrl", 109).
yeccpars2_57_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_58_/1}).
-file("cosNotification_Grammar.yrl", 113).
yeccpars2_58_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_59_/1}).
-file("cosNotification_Grammar.yrl", 111).
yeccpars2_59_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ { dotid , __1 } | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_61_/1}).
-file("cosNotification_Grammar.yrl", 109).
yeccpars2_61_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_62_/1}).
-file("cosNotification_Grammar.yrl", 108).
yeccpars2_62_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ { associd , __2 } | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_63_/1}).
-file("cosNotification_Grammar.yrl", 100).
yeccpars2_63_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_65_/1}).
-file("cosNotification_Grammar.yrl", 109).
yeccpars2_65_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_66_/1}).
-file("cosNotification_Grammar.yrl", 102).
yeccpars2_66_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ { associd , __2 } | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_67_/1}).
-file("cosNotification_Grammar.yrl", 103).
yeccpars2_67_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ { varid , __1 } | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_68_/1}).
-file("cosNotification_Grammar.yrl", 94).
yeccpars2_68_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   examin_comp ( { component , __2 } )
  end | __Stack].

-compile({inline,yeccpars2_69_/1}).
-file("cosNotification_Grammar.yrl", 104).
yeccpars2_69_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_70_/1}).
-file("cosNotification_Grammar.yrl", 95).
yeccpars2_70_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   examin_comp ( { default_component , __3 } )
  end | __Stack].

-compile({inline,yeccpars2_71_/1}).
-file("cosNotification_Grammar.yrl", 120).
yeccpars2_71_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   element ( 2 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_72_/1}).
-file("cosNotification_Grammar.yrl", 92).
yeccpars2_72_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   create_unary ( element ( 2 , __1 ) , element ( 2 , __2 ) )
  end | __Stack].

-compile({inline,yeccpars2_73_/1}).
-file("cosNotification_Grammar.yrl", 91).
yeccpars2_73_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   create_unary ( element ( 2 , __1 ) , element ( 2 , __2 ) )
  end | __Stack].

-compile({inline,yeccpars2_75_/1}).
-file("cosNotification_Grammar.yrl", 85).
yeccpars2_75_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_77_/1}).
-file("cosNotification_Grammar.yrl", 60).
yeccpars2_77_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { 'or' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_79_/1}).
-file("cosNotification_Grammar.yrl", 63).
yeccpars2_79_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { 'and' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_82_/1}).
-file("cosNotification_Grammar.yrl", 74).
yeccpars2_82_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { '~' , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_83_/1}).
-file("cosNotification_Grammar.yrl", 77).
yeccpars2_83_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { element ( 2 , __2 ) , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_85_/1}).
-file("cosNotification_Grammar.yrl", 80).
yeccpars2_85_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { element ( 2 , __2 ) , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_87_/1}).
-file("cosNotification_Grammar.yrl", 66).
yeccpars2_87_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { element ( 2 , __2 ) , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_89_/1}).
-file("cosNotification_Grammar.yrl", 70).
yeccpars2_89_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { in , __1 , __3 }
  end | __Stack].

-compile({inline,yeccpars2_90_/1}).
-file("cosNotification_Grammar.yrl", 104).
yeccpars2_90_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_91_/1}).
-file("cosNotification_Grammar.yrl", 71).
yeccpars2_91_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { in , __1 , examin_comp ( { component , __4 } ) }
  end | __Stack].


-file("cosNotification_Grammar.yrl", 167).
