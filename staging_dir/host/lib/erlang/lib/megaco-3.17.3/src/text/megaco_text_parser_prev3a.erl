-module(megaco_text_parser_prev3a).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("megaco_text_parser_prev3a.yrl", 1583).

%% The following directive is needed for (significantly) faster compilation
%% of the generated .erl file by the HiPE compiler.  Please do not remove.
-compile([{hipe,[{regalloc,linear_scan}]}]).

-include("megaco_text_parser_prev3a.hrl").



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



-file("./megaco_text_parser_prev3a.erl", 197).

yeccpars2(0=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(1=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_1(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(2=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_2(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(3=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(4=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(5=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(6=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(7=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_7(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(8=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_8(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(9=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(10=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(11=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(12=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(13=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(59=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_59(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(60=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_60(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(61=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(62=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_62(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(63=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(64=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_64(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(65=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(66=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(67=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(79=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_79(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(80=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_80(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(81=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(82=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(83=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(84=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_84(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(85=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(86=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_86(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(87=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(88=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(89=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(90=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(91=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(92=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(93=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_93(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(94=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(95=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(96=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_96(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(97=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(98=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(99=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(100=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_100(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(101=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_101(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(102=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(103=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_103(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(104=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(105=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_105(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(106=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(107=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_107(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(108=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_108(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(109=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_109(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(110=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_110(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(111=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_111(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(112=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_112(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(113=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_113(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(114=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_114(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(115=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_115(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(116=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(117=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(118=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_118(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(119=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_119(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(120=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_120(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(121=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_121(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(122=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(123=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(124=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_124(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(125=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_125(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(126=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_126(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(127=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(128=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_128(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(129=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(130=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(131=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_131(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(132=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(133=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_133(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(134=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(135=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_135(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(136=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_136(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(137=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_137(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(138=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_138(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(139=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_139(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(140=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_140(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(141=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_141(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(142=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(143=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_143(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(144=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_144(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(145=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_145(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(146=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(147=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_147(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(148=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_148(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(149=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_149(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(150=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(151=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_151(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(152=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_152(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(153=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(154=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_154(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(155=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_155(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(156=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_156(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(157=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_157(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(158=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_158(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(159=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_159(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(160=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_160(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(161=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_161(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(162=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_162(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(163=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_163(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(164=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_164(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(165=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_165(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(166=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(167=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_167(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(168=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(169=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_169(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(170=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_170(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(171=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_171(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(172=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_172(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(173=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_173(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(174=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_174(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(175=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(176=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(182=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(183=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_183(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(184=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(185=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_185(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(186=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_186(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(187=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_187(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(188=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_188(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(189=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_189(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(190=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_190(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(191=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_191(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(192=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_192(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(193=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_193(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(194=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_194(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(195=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_195(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(196=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_196(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(197=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(198=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_198(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(199=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_199(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(200=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(201=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_201(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(202=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(203=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(204=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_204(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(205=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_205(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(206=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(207=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(208=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_208(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(209=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_209(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(210=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%%  yeccpars2_217(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(218=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_218(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(219=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_219(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(220=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(221=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_221(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(222=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_222(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(223=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(224=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_224(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(225=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_225(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(226=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(227=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(228=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(229=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_229(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(230=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_230(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(231=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_231(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(232=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(233=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_233(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(234=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_234(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(235=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_235(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(236=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_236(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(237=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_237(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(238=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(239=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_239(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(240=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_240(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(241=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_241(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(242=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_242(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(243=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_243(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(244=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_244(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(245=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(246=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(247=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_247(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(248=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_248(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(249=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_249(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(250=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_250(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(251=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_251(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(252=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_252(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(253=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_253(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(254=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(255=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(256=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_256(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(257=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_250(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(258=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_258(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(259=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(260=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_260(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(261=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(262=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_262(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(263=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_263(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(270=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(271=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(272=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(273=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_273(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(274=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_274(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(275=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_275(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(276=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_276(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(277=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_277(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(278=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_278(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(279=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_279(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(280=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(281=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(282=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_282(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(283=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_283(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(284=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(285=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(286=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_286(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(287=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_287(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(288=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(289=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_289(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(290=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_290(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(291=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_291(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(292=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_292(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(293=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_293(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(294=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(295=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(296=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_296(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(297=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_297(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(298=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(299=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(305=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_305(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(306=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_306(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(307=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_307(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(308=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_308(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(309=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_309(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(310=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_310(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(311=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_311(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(312=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_312(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(313=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_313(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(314=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(315=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_315(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(316=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_316(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(317=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_317(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(318=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(319=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_319(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(320=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_320(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(321=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_321(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(322=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_322(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(323=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(324=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_324(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(325=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_325(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(326=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_326(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(327=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(328=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_328(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(329=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_329(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(330=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_330(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(331=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_331(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(332=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(333=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_333(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(334=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(335=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_335(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(336=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_336(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(337=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_337(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(338=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(339=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_339(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(340=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_340(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(341=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_341(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(342=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_342(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(343=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_343(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(344=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_344(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(345=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_345(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(346=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_346(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(347=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_347(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(348=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_348(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(349=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(350=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_350(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(351=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_351(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(352=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_352(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(353=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_353(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(354=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_354(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(355=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_355(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(356=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_356(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(357=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_357(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(358=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_358(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(359=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_359(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(360=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_360(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(361=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_361(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(362=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_362(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(363=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_363(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(364=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_364(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(365=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_365(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(366=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_366(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(367=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(368=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_368(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(369=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_369(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(370=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_370(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(371=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_371(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(372=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(373=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_373(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(374=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_374(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(375=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_375(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(376=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_376(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(377=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_377(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(378=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_378(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(379=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_379(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(380=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_380(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(381=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_381(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(382=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_382(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(383=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_230(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(384=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_384(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(385=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_385(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(386=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_386(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(387=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_387(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(388=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_388(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(389=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_389(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(390=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_390(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(391=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_391(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(392=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_392(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(393=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_393(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(394=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_394(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(395=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(396=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_396(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(397=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_397(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(398=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_398(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(399=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_399(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(400=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(401=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_401(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(402=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(403=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_403(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(404=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_404(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(405=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_405(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(406=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(407=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_407(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(408=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(409=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_409(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(410=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_410(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(411=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_411(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(412=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(413=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_413(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(414=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_414(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(415=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_415(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(416=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_416(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(417=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(418=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_418(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(419=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_419(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(420=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_420(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(421=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_421(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(422=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_422(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(423=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_423(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(424=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(425=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_425(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(426=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_426(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(427=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_427(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(428=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(429=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_429(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(430=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_430(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(431=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_431(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(432=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_432(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(433=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_433(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(434=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_434(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(435=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_435(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(436=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_436(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(437=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(438=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_438(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(439=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_439(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(440=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_230(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(441=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_441(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(442=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_442(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(443=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(444=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_444(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(445=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_445(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(446=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_446(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(447=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_447(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(448=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_448(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(449=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(450=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_450(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(451=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_451(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(452=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_452(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(453=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_453(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(454=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_454(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(455=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_455(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(456=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_456(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(457=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_457(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(458=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_458(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(459=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_459(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(460=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_460(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(461=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_461(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(462=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_462(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(463=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_463(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(464=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_456(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(465=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_465(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(466=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_466(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(467=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_467(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(468=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_468(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(469=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_469(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(470=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_470(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(471=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_471(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(472=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_472(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(473=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_230(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(474=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_474(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(475=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_475(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(476=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_476(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(477=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_477(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(478=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_478(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(479=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_479(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(480=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_480(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(481=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(482=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_482(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(483=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_483(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(484=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_484(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(485=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(486=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_486(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(487=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_487(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(488=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_488(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(489=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_489(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(490=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_490(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(491=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_491(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(492=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_492(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(493=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_493(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(494=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(495=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_495(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(496=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_496(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(497=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_497(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(498=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(499=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_499(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(500=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_500(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(501=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_469(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(502=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_502(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(503=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_503(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(504=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_504(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(505=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_505(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(506=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(507=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_507(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(508=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_508(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(509=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(510=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_510(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(511=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_511(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(512=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_512(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(513=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_513(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(514=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(515=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_515(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(516=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_516(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(517=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(518=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_518(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(519=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_519(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(520=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_520(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(521=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_521(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(522=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_522(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(523=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_523(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(524=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_524(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(525=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_525(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(526=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_526(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(527=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_527(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(528=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_528(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(529=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_529(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(530=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_530(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(531=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_531(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(532=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_532(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(533=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_533(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(534=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_534(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(535=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_535(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(536=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_536(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(537=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_537(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(538=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_538(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(539=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(540=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_540(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(541=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_541(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(542=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(543=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_543(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(544=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_544(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(545=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(546=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_546(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(547=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_547(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(548=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_548(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(549=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_549(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(550=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_550(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(551=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_551(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(552=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_552(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(553=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_553(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(554=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(555=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_555(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(556=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(557=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_557(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(558=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_558(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(559=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(560=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_560(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(561=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_561(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(562=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_562(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(563=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_563(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(564=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_549(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(565=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_565(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(566=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_566(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(567=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_567(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(568=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(569=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_569(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(570=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_570(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(571=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_571(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(572=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(573=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_573(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(574=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_574(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(575=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(576=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_576(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(577=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_577(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(578=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_578(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(579=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(580=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(581=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_581(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(582=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_582(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(583=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_583(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(584=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(585=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_585(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(586=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_586(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(587=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_587(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(588=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_588(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(589=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(590=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_590(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(591=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_591(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(592=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(593=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_593(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(594=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_594(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(595=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_595(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(596=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_596(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(597=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_597(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(598=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_598(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(599=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_599(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(600=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_600(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(601=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_601(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(602=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_602(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(603=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_603(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(604=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_604(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(605=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_605(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(606=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_606(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(607=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_607(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(608=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_608(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(609=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_609(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(610=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_610(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(611=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_611(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(612=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_612(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(613=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_613(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(614=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_614(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(615=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_615(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(616=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_616(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(617=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_617(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(618=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_618(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(619=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_619(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(620=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_620(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(621=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_621(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(622=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_622(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(623=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_623(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(624=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_624(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(625=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_625(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(626=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_626(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(627=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_610(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(628=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_628(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(629=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_629(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(630=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_630(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(631=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(632=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_632(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(633=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_633(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(634=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_634(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(635=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_635(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(636=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_633(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(637=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_637(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(638=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_638(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(639=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_639(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(640=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_640(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(641=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_641(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(642=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_642(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(643=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_643(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(644=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_644(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(645=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_645(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(646=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_646(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(647=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_647(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(648=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_648(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(649=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_649(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(650=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_646(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(651=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_651(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(652=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_652(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(653=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_653(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(654=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_654(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(655=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_655(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(656=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_656(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(657=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_657(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(658=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_658(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(659=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_659(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(660=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_640(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(661=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_661(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(662=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_662(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(663=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_663(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(664=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_664(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(665=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_598(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(666=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_666(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(667=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_667(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(668=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_668(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(669=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(670=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_670(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(671=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(672=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_672(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(673=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_673(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(674=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_674(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(675=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_675(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(676=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_676(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(677=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_677(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(678=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_678(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(679=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_679(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(680=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_680(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(681=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_681(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(682=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_682(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(683=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_683(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(684=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_684(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(685=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_685(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(686=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_686(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(687=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_687(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(688=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(689=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_689(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(690=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(691=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_691(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(692=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_692(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(693=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_693(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(694=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_694(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(695=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_695(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(696=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_696(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(697=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_697(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(698=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_698(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(699=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_699(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(700=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_700(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(701=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_701(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(702=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_702(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(703=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_703(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(704=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_704(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(705=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_694(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(706=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_706(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(707=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_707(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(708=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_708(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(709=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_709(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(710=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(711=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_711(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(712=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_712(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(713=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_713(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(714=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_714(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(715=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_715(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(716=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_716(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(717=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_717(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(718=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_718(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(719=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_719(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(720=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_675(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(721=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_721(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(722=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_722(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(723=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_723(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(724=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_724(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(725=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(726=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_726(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(727=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_727(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(728=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_728(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(729=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_729(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(730=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_730(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(731=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_731(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(732=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_732(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(733=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_733(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(734=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_734(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(735=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_735(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(736=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_736(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(737=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_737(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(738=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_520(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(739=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_739(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(740=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_740(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(741=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_741(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(742=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_742(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(743=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_147(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(744=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_744(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(745=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_745(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(746=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_746(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(747=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_747(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(748=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_748(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(749=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_147(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(750=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_750(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(751=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_751(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(752=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_752(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(753=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_147(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(754=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_754(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(755=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_755(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(756=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_756(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(757=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(758=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_758(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(759=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_759(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(760=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_760(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(761=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(762=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_762(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(763=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_763(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(764=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_764(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(765=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(766=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_766(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(767=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_767(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(768=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_768(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(769=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_769(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(770=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_770(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(771=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_771(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(772=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_772(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(773=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_773(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(774=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_774(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(775=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(776=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_776(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(777=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_777(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(778=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_778(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(779=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_779(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(780=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_780(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(781=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_781(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(782=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_782(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(783=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_783(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(784=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_784(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(785=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_785(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(786=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_786(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(787=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_787(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(788=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_788(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(789=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_789(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(790=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_790(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(791=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_791(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(792=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_792(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(793=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_793(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(794=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_794(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(795=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(796=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_796(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(797=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_797(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(798=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_798(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(799=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_799(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(800=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_800(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(801=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_801(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(802=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_802(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(803=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_803(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(804=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_804(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(805=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_805(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(806=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_806(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(807=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_807(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(808=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_808(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(809=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_809(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(810=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_810(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(811=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_811(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(812=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_812(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(813=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_813(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(814=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_802(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(815=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_815(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(816=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_816(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(817=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_817(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(818=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_818(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(819=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_819(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(820=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(821=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_821(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(822=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_822(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(823=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_823(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(824=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_824(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(825=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_825(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(826=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_826(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(827=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_827(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(828=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_828(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(829=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_829(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(830=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_830(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(831=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_831(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(832=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_832(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(833=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_833(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(834=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_834(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(835=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(836=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_836(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(837=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_837(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(838=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_838(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(839=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_839(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(840=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_840(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(841=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_841(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(842=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_842(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(843=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_843(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(844=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_844(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(845=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_845(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(846=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_846(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(847=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_847(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(848=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_848(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(849=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_849(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(850=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_850(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(851=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_851(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(852=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_852(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(853=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_853(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(854=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_854(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(855=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_855(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(856=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_856(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(857=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_857(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(858=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_858(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(859=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_859(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(860=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_860(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(861=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_861(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(862=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_862(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(863=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_863(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(864=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(865=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_865(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(866=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_866(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(867=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(868=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_868(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(869=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_869(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(870=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_870(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(871=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_871(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(872=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_843(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(873=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_873(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(874=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_874(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(875=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_875(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(876=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_876(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(877=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_877(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(878=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_878(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(879=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_879(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(880=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_880(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(881=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(882=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_882(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(883=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_883(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(884=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_843(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(885=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_885(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(886=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_886(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(887=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_887(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(888=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_777(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(889=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_889(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(890=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_890(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(891=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_891(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(892=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_892(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(893=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_893(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(894=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_894(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(895=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_895(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(896=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_896(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(897=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(898=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_898(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(899=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_899(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(900=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_900(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(901=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_901(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(902=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_902(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(903=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_903(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(904=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_904(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(905=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_905(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(906=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_906(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(907=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_907(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(908=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_908(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(Other, _, _, _, _, _, _) ->
 erlang:error({yecc_bug,"1.4",{missing_state_in_action_table, Other}}).

yeccpars2_0(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_0_(Stack),
 yeccpars2_1(1, Cat, [0 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_1(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 5, Ss, Stack, T, Ts, Tzr);
yeccpars2_1(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_1_(Stack),
 yeccpars2_4(4, Cat, [1 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_2(_S, '$end', _Ss, Stack, _T, _Ts, _Tzr) ->
 {ok, hd(Stack)};
yeccpars2_2(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_3_(Stack),
 yeccgoto_optSep(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_4(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_4(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_5(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 6, Ss, Stack, T, Ts, Tzr);
yeccpars2_5(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_6: see yeccpars2_4

yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_7_(Stack),
 yeccgoto_safeToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_8(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 104, Ss, Stack, T, Ts, Tzr);
yeccpars2_8(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_11(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_12(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_13(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_15(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_17(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_18(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_24(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_25(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_26(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_27(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_28(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_33(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_37(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_38(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_39(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_40(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_41(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_42(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_43(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_44(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_45(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_46(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_49(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_50(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_51(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_52(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_54(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_55(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_56(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_58(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_60(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_61(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_62(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_63(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_64(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_65(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_67(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_68(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_74(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_75(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_76(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_77(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_78(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_79(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_80(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_81(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_82(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_84(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_90(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_92(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_93(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_99(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_100(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_102(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_103(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_104: see yeccpars2_4

yeccpars2_105(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 106, Ss, Stack, T, Ts, Tzr);
yeccpars2_105(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_106: see yeccpars2_4

yeccpars2_107(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_107_(Stack),
 yeccpars2_108(_S, Cat, [107 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_108(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_108_(Stack),
 yeccgoto_authenticationHeader(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_109(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_109_(Stack),
 yeccpars2_112(112, Cat, [109 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_110(S, endOfMessage, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 111, Ss, Stack, T, Ts, Tzr);
yeccpars2_110(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_111(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_111_(Stack),
 yeccgoto_megacoMessage(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_112(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'MtpAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 906, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_113(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_113(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 142, Ss, Stack, T, Ts, Tzr);
yeccpars2_113(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 143, Ss, Stack, T, Ts, Tzr);
yeccpars2_113(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 144, Ss, Stack, T, Ts, Tzr);
yeccpars2_113(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 145, Ss, Stack, T, Ts, Tzr);
yeccpars2_113(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mId(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mId(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_116: see yeccpars2_4

yeccpars2_117(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 120, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_117_(Stack),
 yeccpars2_119(119, Cat, [117 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_118(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 120, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_118_(Stack),
 yeccpars2_127(_S, Cat, [118 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_119(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 122, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_120(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 120, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_120_(Stack),
 yeccpars2_121(_S, Cat, [120 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_121(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_121_(Stack),
 yeccgoto_daddr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_122(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 123, Ss, Stack, T, Ts, Tzr);
yeccpars2_122(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_122_(Stack),
 yeccgoto_domainAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_123: see yeccpars2_4

yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_124_(Stack),
 yeccgoto_portNumber(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_125(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_125_(Stack),
 yeccpars2_126(_S, Cat, [125 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_126(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_126_(Stack),
 yeccgoto_domainAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_127(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_127_(Stack),
 yeccgoto_daddr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_128(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 129, Ss, Stack, T, Ts, Tzr);
yeccpars2_128(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_129(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 130, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_129_(Stack),
 yeccgoto_domainName(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_130: see yeccpars2_4

yeccpars2_131(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_131_(Stack),
 yeccpars2_132(_S, Cat, [131 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_132_(Stack),
 yeccgoto_domainName(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_133(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_133_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_134_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_135_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_136_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_137_(Stack),
 yeccgoto_messageBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_138(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 142, Ss, Stack, T, Ts, Tzr);
yeccpars2_138(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 143, Ss, Stack, T, Ts, Tzr);
yeccpars2_138(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 144, Ss, Stack, T, Ts, Tzr);
yeccpars2_138(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 145, Ss, Stack, T, Ts, Tzr);
yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_138_(Stack),
 yeccgoto_transactionList(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_139_(Stack),
 yeccgoto_message(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_140_(Stack),
 yeccgoto_messageBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_141(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 835, Ss, Stack, T, Ts, Tzr);
yeccpars2_141(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_142(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 897, Ss, Stack, T, Ts, Tzr);
yeccpars2_142(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_143(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 765, Ss, Stack, T, Ts, Tzr);
yeccpars2_143(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_144(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 757, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_145(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 146, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 147, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_146(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 749, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_147(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 149, Ss, Stack, T, Ts, Tzr);
yeccpars2_147(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_148(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 743, Ss, Stack, T, Ts, Tzr);
yeccpars2_148(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_148_(Stack),
 yeccpars2_742(742, Cat, [148 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_149(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 150, Ss, Stack, T, Ts, Tzr);
yeccpars2_149(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_150: see yeccpars2_4

yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_151_(Stack),
 yeccgoto_contextID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_152(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 153, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_153(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 166, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 167, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 168, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 169, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 171, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 172, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 174, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 175, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_157_(Stack),
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_158_(Stack),
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_159_(Stack),
 yeccgoto_contextProperties(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_160_(Stack),
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_162(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 517, Ss, Stack, T, Ts, Tzr);
yeccpars2_162(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_163(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_164(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 514, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_164_(Stack),
 yeccpars2_513(_S, Cat, [164 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_165(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 512, Ss, Stack, T, Ts, Tzr);
yeccpars2_165(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_166(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_166_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_167(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 509, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_168(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 506, Ss, Stack, T, Ts, Tzr);
yeccpars2_168(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_169(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 469, Ss, Stack, T, Ts, Tzr);
yeccpars2_169(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_170(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 453, Ss, Stack, T, Ts, Tzr);
yeccpars2_170(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_171_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_172(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_172_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_173(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 417, Ss, Stack, T, Ts, Tzr);
yeccpars2_173(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_174(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 367, Ss, Stack, T, Ts, Tzr);
yeccpars2_174(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_175(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 176, Ss, Stack, T, Ts, Tzr);
yeccpars2_175(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_176: see yeccpars2_4

yeccpars2_177(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 180, Ss, Stack, T, Ts, Tzr);
yeccpars2_177(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_177_(Stack),
 yeccpars2_179(_S, Cat, [177 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_178_(Stack),
 yeccgoto_terminationID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_179_(Stack),
 yeccgoto_subtractRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_180(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 182, Ss, Stack, T, Ts, Tzr);
yeccpars2_180(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_181(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 366, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_182(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 183, Ss, Stack, T, Ts, Tzr);
yeccpars2_182(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_183(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 196, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 197, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 198, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 199, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 200, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 201, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 202, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 203, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 204, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 205, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 206, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_183_(Stack),
 yeccpars2_195(195, Cat, [183 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_184_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_185_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_186_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_187_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_188(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_188_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_189_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_190(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_190_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_191(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_191_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_192(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 358, Ss, Stack, T, Ts, Tzr);
yeccpars2_192(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_192_(Stack),
 yeccpars2_357(_S, Cat, [192 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_193(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_auditItem(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_194(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 354, Ss, Stack, T, Ts, Tzr);
yeccpars2_194(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_194_(Stack),
 yeccpars2_353(_S, Cat, [194 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_195(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 352, Ss, Stack, T, Ts, Tzr);
yeccpars2_195(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_196(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_196_(Stack),
 yeccgoto_indAuddigitMapDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_197_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_198(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 338, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_198_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_199(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 332, Ss, Stack, T, Ts, Tzr);
yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_199_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_200(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 303, Ss, Stack, T, Ts, Tzr);
yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_200_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_201(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_201_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_202_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_203_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_204(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 299, Ss, Stack, T, Ts, Tzr);
yeccpars2_204(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_204_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_205(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 212, Ss, Stack, T, Ts, Tzr);
yeccpars2_205(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_205_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_206(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 207, Ss, Stack, T, Ts, Tzr);
yeccpars2_206(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_206_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_207: see yeccpars2_4

yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_208_(Stack),
 yeccgoto_pkgdName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_209(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 210, Ss, Stack, T, Ts, Tzr);
yeccpars2_209(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_210_(Stack),
 yeccgoto_indAudstatisticsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_211_(Stack),
 yeccgoto_indAudsignalsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_212(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 218, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 219, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_213_(Stack),
 yeccgoto_indAudsignalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_214(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 228, Ss, Stack, T, Ts, Tzr);
yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_214_(Stack),
 yeccgoto_signalRequest(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_signalName(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_216(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 227, Ss, Stack, T, Ts, Tzr);
yeccpars2_216(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_217(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_217_(Stack),
 yeccgoto_indAudsignalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_218(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_218_(Stack),
 yeccgoto_optIndAudsignalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_219(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_219(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_220: see yeccpars2_4

yeccpars2_221(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 223, Ss, Stack, T, Ts, Tzr);
yeccpars2_221(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_222(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_222_(Stack),
 yeccgoto_signalListId(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_223: see yeccpars2_4

yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_signalListParm(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_225(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 226, Ss, Stack, T, Ts, Tzr);
yeccpars2_225(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_226_(Stack),
 yeccgoto_indAudsignalList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_227_(Stack),
 yeccgoto_optIndAudsignalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_228(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 231, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 232, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 233, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 234, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 235, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 236, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 237, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_229(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 295, Ss, Stack, T, Ts, Tzr);
yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_229_(Stack),
 yeccpars2_294(294, Cat, [229 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_230(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 269, Ss, Stack, T, Ts, Tzr);
yeccpars2_230(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 270, Ss, Stack, T, Ts, Tzr);
yeccpars2_230(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 271, Ss, Stack, T, Ts, Tzr);
yeccpars2_230(S, 'NEQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 272, Ss, Stack, T, Ts, Tzr);
yeccpars2_230(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_231(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 263, Ss, Stack, T, Ts, Tzr);
yeccpars2_231(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_232(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 261, Ss, Stack, T, Ts, Tzr);
yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_233(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_233_COMMA(Stack),
 yeccgoto_sigParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_233(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_233_RBRKT(Stack),
 yeccgoto_sigParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_233(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_234(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 249, Ss, Stack, T, Ts, Tzr);
yeccpars2_234(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_235(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 246, Ss, Stack, T, Ts, Tzr);
yeccpars2_235(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_236(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 241, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_237(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 238, Ss, Stack, T, Ts, Tzr);
yeccpars2_237(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_238: see yeccpars2_4

yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_239_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_240(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_240_(Stack),
 yeccgoto_streamID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_241(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 243, Ss, Stack, T, Ts, Tzr);
yeccpars2_241(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 244, Ss, Stack, T, Ts, Tzr);
yeccpars2_241(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 245, Ss, Stack, T, Ts, Tzr);
yeccpars2_241(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_242(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_242_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_243(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_243_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_244(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_244_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_245(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_245_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_246: see yeccpars2_4

yeccpars2_247(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_247_(Stack),
 yeccgoto_requestID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_248_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_249(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 250, Ss, Stack, T, Ts, Tzr);
yeccpars2_249(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_250(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 252, Ss, Stack, T, Ts, Tzr);
yeccpars2_250(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 253, Ss, Stack, T, Ts, Tzr);
yeccpars2_250(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 254, Ss, Stack, T, Ts, Tzr);
yeccpars2_250(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 255, Ss, Stack, T, Ts, Tzr);
yeccpars2_250(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_251(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 257, Ss, Stack, T, Ts, Tzr);
yeccpars2_251(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_251_(Stack),
 yeccpars2_256(256, Cat, [251 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_252(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_252_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_253(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_253_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_254(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_254_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_255_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_256(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 260, Ss, Stack, T, Ts, Tzr);
yeccpars2_256(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_257: see yeccpars2_250

yeccpars2_258(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 257, Ss, Stack, T, Ts, Tzr);
yeccpars2_258(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_258_(Stack),
 yeccpars2_259(_S, Cat, [258 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_259(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_259_(Stack),
 yeccgoto_notificationReasons(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_260(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_260_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_261: see yeccpars2_4

yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_262_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_263(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 265, Ss, Stack, T, Ts, Tzr);
yeccpars2_263(S, 'ExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 266, Ss, Stack, T, Ts, Tzr);
yeccpars2_263(S, 'InternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 267, Ss, Stack, T, Ts, Tzr);
yeccpars2_263(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_264_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_265(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_265_(Stack),
 yeccgoto_direction(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_266(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_266_(Stack),
 yeccgoto_direction(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_267(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_267_(Stack),
 yeccgoto_direction(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_268(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_268_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_269(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 280, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 281, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 275, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_270(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 275, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_271: see yeccpars2_270

%% yeccpars2_272: see yeccpars2_270

yeccpars2_273(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_273_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_274_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_275(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_275_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_276(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_276_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_277(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_277_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_278(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_278_(Stack),
 yeccgoto_alternativeValue(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_279(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_279_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_280: see yeccpars2_270

%% yeccpars2_281: see yeccpars2_270

yeccpars2_282(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 284, Ss, Stack, T, Ts, Tzr);
yeccpars2_282(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 285, Ss, Stack, T, Ts, Tzr);
yeccpars2_282(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_282_(Stack),
 yeccpars2_283(283, Cat, [282 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_283(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 290, Ss, Stack, T, Ts, Tzr);
yeccpars2_283(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_284: see yeccpars2_270

%% yeccpars2_285: see yeccpars2_270

yeccpars2_286(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 285, Ss, Stack, T, Ts, Tzr);
yeccpars2_286(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_286_(Stack),
 yeccpars2_287(_S, Cat, [286 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_287(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_287_(Stack),
 yeccgoto_valueList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_288(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 289, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_289(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_289_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_290(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_290_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_291(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 285, Ss, Stack, T, Ts, Tzr);
yeccpars2_291(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_291_(Stack),
 yeccpars2_292(292, Cat, [291 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_292(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 293, Ss, Stack, T, Ts, Tzr);
yeccpars2_292(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_293(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_293_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_294(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 298, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_295: see yeccpars2_228

yeccpars2_296(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 295, Ss, Stack, T, Ts, Tzr);
yeccpars2_296(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_296_(Stack),
 yeccpars2_297(_S, Cat, [296 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_297_(Stack),
 yeccgoto_sigParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_298_(Stack),
 yeccgoto_signalRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_299: see yeccpars2_4

yeccpars2_300(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_300_(Stack),
 yeccgoto_packagesItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_301(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 302, Ss, Stack, T, Ts, Tzr);
yeccpars2_301(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_302(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_302_(Stack),
 yeccgoto_indAudpackagesDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_303(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 310, Ss, Stack, T, Ts, Tzr);
yeccpars2_303(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 311, Ss, Stack, T, Ts, Tzr);
yeccpars2_303(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 312, Ss, Stack, T, Ts, Tzr);
yeccpars2_303(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 313, Ss, Stack, T, Ts, Tzr);
yeccpars2_303(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_304(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_304_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_305(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_305_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_306(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_306_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_307(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_307_(Stack),
 yeccgoto_indAudstreamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_308(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 331, Ss, Stack, T, Ts, Tzr);
yeccpars2_308(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_309(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_309_(Stack),
 yeccgoto_indAudstreamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_310(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 323, Ss, Stack, T, Ts, Tzr);
yeccpars2_310(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_311(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 207, Ss, Stack, T, Ts, Tzr);
yeccpars2_311(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_312(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 318, Ss, Stack, T, Ts, Tzr);
yeccpars2_312(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_313(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 314, Ss, Stack, T, Ts, Tzr);
yeccpars2_313(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_314: see yeccpars2_4

yeccpars2_315(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_315_(Stack),
 yeccgoto_indAudterminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_316(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 317, Ss, Stack, T, Ts, Tzr);
yeccpars2_316(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_317(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_317_(Stack),
 yeccgoto_indAudterminationStateDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_318: see yeccpars2_4

yeccpars2_319(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 320, Ss, Stack, T, Ts, Tzr);
yeccpars2_319(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_320(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 310, Ss, Stack, T, Ts, Tzr);
yeccpars2_320(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 311, Ss, Stack, T, Ts, Tzr);
yeccpars2_320(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_321(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 322, Ss, Stack, T, Ts, Tzr);
yeccpars2_321(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_322(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_322_(Stack),
 yeccgoto_indAudstreamDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_323: see yeccpars2_4

yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_324_(Stack),
 yeccgoto_indAudlocalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_325(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 327, Ss, Stack, T, Ts, Tzr);
yeccpars2_325(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_325_(Stack),
 yeccpars2_326(326, Cat, [325 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_326(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 330, Ss, Stack, T, Ts, Tzr);
yeccpars2_326(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_327: see yeccpars2_4

yeccpars2_328(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 327, Ss, Stack, T, Ts, Tzr);
yeccpars2_328(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_328_(Stack),
 yeccpars2_329(_S, Cat, [328 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_329_(Stack),
 yeccgoto_indAudlocalParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_330(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_330_(Stack),
 yeccgoto_indAudlocalControlDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_331(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_331_(Stack),
 yeccgoto_indAudmediaDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_332: see yeccpars2_4

yeccpars2_333(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 334, Ss, Stack, T, Ts, Tzr);
yeccpars2_333(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_334: see yeccpars2_4

yeccpars2_335(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_indAudrequestedEvent(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_336(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 337, Ss, Stack, T, Ts, Tzr);
yeccpars2_336(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_337(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_337_(Stack),
 yeccgoto_indAudeventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_338: see yeccpars2_4

yeccpars2_339(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 343, Ss, Stack, T, Ts, Tzr);
yeccpars2_339(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_339_(Stack),
 yeccpars2_342(_S, Cat, [339 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_340(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 341, Ss, Stack, T, Ts, Tzr);
yeccpars2_340(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_341(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_341_(Stack),
 yeccgoto_indAudeventBufferDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_342(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_342_(Stack),
 yeccgoto_indAudeventSpec(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_343(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 348, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_344_(Stack),
 yeccgoto_eventParameterName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_345(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 351, Ss, Stack, T, Ts, Tzr);
yeccpars2_345(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_346(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_346_(Stack),
 yeccgoto_indAudeventSpecParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_347(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_347_(Stack),
 yeccgoto_indAudeventSpecParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_348(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 349, Ss, Stack, T, Ts, Tzr);
yeccpars2_348(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_349: see yeccpars2_4

yeccpars2_350(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_350_(Stack),
 yeccgoto_eventStream(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_351(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_351_(Stack),
 yeccgoto_optIndAudeventSpecParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_352(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_352_(Stack),
 yeccgoto_auditDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_353(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_353_(Stack),
 yeccgoto_auditDescriptorBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_354(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 196, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 197, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 198, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 199, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 200, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 201, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 202, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 203, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 204, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 205, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 206, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_355(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 354, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_355_(Stack),
 yeccpars2_356(_S, Cat, [355 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_356(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_356_(Stack),
 yeccgoto_auditItemList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_357(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_357_(Stack),
 yeccgoto_indAudterminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_358(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 196, Ss, Stack, T, Ts, Tzr);
yeccpars2_358(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 360, Ss, Stack, T, Ts, Tzr);
yeccpars2_358(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 361, Ss, Stack, T, Ts, Tzr);
yeccpars2_358(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 362, Ss, Stack, T, Ts, Tzr);
yeccpars2_358(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 363, Ss, Stack, T, Ts, Tzr);
yeccpars2_358(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 364, Ss, Stack, T, Ts, Tzr);
yeccpars2_358(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 311, Ss, Stack, T, Ts, Tzr);
yeccpars2_358(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_359(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 358, Ss, Stack, T, Ts, Tzr);
yeccpars2_359(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_359_(Stack),
 yeccpars2_365(_S, Cat, [359 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_360(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 338, Ss, Stack, T, Ts, Tzr);
yeccpars2_360(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_361(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 332, Ss, Stack, T, Ts, Tzr);
yeccpars2_361(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_362(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 303, Ss, Stack, T, Ts, Tzr);
yeccpars2_362(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_363(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 299, Ss, Stack, T, Ts, Tzr);
yeccpars2_363(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_364(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 212, Ss, Stack, T, Ts, Tzr);
yeccpars2_364(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_365(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_365_(Stack),
 yeccgoto_indAudterminationAuditList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_366(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_366_(Stack),
 yeccgoto_optAuditDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_367: see yeccpars2_4

yeccpars2_368(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 369, Ss, Stack, T, Ts, Tzr);
yeccpars2_368(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_369(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 371, Ss, Stack, T, Ts, Tzr);
yeccpars2_369(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_370(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 416, Ss, Stack, T, Ts, Tzr);
yeccpars2_370(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_371(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 372, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_372(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 386, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 196, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 197, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 198, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 199, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 200, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 387, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 388, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 201, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 202, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 203, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 204, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 389, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 390, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 391, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ServiceChangeIncompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 392, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 205, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 206, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 393, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 394, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_373(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_373_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_374_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_375(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_375_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_376(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_376_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_377(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 412, Ss, Stack, T, Ts, Tzr);
yeccpars2_377(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_377_(Stack),
 yeccpars2_411(411, Cat, [377 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_378(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_378_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_379(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_379_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_380(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_380_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_381(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_381_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_382(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_382_(Stack),
 yeccgoto_extensionParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_383: see yeccpars2_230

yeccpars2_384(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_384_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_385(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_385_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_386(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 408, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_387(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 406, Ss, Stack, T, Ts, Tzr);
yeccpars2_387(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_388(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 404, Ss, Stack, T, Ts, Tzr);
yeccpars2_388(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_389(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 402, Ss, Stack, T, Ts, Tzr);
yeccpars2_389(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_390(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 400, Ss, Stack, T, Ts, Tzr);
yeccpars2_390(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_391(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 397, Ss, Stack, T, Ts, Tzr);
yeccpars2_391(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_392(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_392_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_393(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_393_(Stack),
 yeccgoto_timeStamp(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_394(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 395, Ss, Stack, T, Ts, Tzr);
yeccpars2_394(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_395: see yeccpars2_4

yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_396_(Stack),
 yeccgoto_serviceChangeVersion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_397(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_397_(Stack),
 yeccpars2_112(112, Cat, [397 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_398(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_398_(Stack),
 yeccgoto_serviceChangeAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_399(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_399_(Stack),
 yeccgoto_serviceChangeAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_400: see yeccpars2_270

yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_401_(Stack),
 yeccgoto_serviceChangeReason(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_402: see yeccpars2_4

yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_403_(Stack),
 yeccgoto_serviceChangeProfile(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_404(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_404(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_404(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_404(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_404_(Stack),
 yeccpars2_112(112, Cat, [404 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_405(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_405_(Stack),
 yeccgoto_serviceChangeMgcId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_406: see yeccpars2_4

yeccpars2_407(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_407_(Stack),
 yeccgoto_serviceChangeMethod(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_408: see yeccpars2_4

yeccpars2_409(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_409_(Stack),
 yeccgoto_serviceChangeDelay(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_410(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_410_(Stack),
 yeccgoto_extension(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_411(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 415, Ss, Stack, T, Ts, Tzr);
yeccpars2_411(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_412: see yeccpars2_372

yeccpars2_413(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 412, Ss, Stack, T, Ts, Tzr);
yeccpars2_413(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_413_(Stack),
 yeccpars2_414(_S, Cat, [413 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_414(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_414_(Stack),
 yeccgoto_serviceChangeParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_415(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_415_(Stack),
 yeccgoto_serviceChangeDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_416(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_416_(Stack),
 yeccgoto_serviceChangeRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_417: see yeccpars2_4

yeccpars2_418(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 419, Ss, Stack, T, Ts, Tzr);
yeccpars2_418(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_419(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_419(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 423, Ss, Stack, T, Ts, Tzr);
yeccpars2_419(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_420(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_420_(Stack),
 yeccgoto_notifyRequestBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_421(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 452, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_422(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_422_(Stack),
 yeccgoto_notifyRequestBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_423(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 424, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_424: see yeccpars2_4

yeccpars2_425(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 426, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_426(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_426(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 393, Ss, Stack, T, Ts, Tzr);
yeccpars2_426(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_426_(Stack),
 yeccpars2_4(428, Cat, [426 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_427(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_427(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_427_(Stack),
 yeccpars2_447(447, Cat, [427 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_428: see yeccpars2_4

yeccpars2_429(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 431, Ss, Stack, T, Ts, Tzr);
yeccpars2_429(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_429_(Stack),
 yeccpars2_430(430, Cat, [429 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_430(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 434, Ss, Stack, T, Ts, Tzr);
yeccpars2_430(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_431(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_431(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 393, Ss, Stack, T, Ts, Tzr);
yeccpars2_431(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_431_(Stack),
 yeccpars2_4(428, Cat, [431 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_432(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 431, Ss, Stack, T, Ts, Tzr);
yeccpars2_432(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_432_(Stack),
 yeccpars2_433(_S, Cat, [432 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_433_(Stack),
 yeccgoto_observedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_434(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_434_(Stack),
 yeccgoto_observedEventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_435(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 437, Ss, Stack, T, Ts, Tzr);
yeccpars2_435(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_435_(Stack),
 yeccpars2_436(_S, Cat, [435 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_436(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_436_(Stack),
 yeccgoto_observedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_437: see yeccpars2_4

yeccpars2_438(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 443, Ss, Stack, T, Ts, Tzr);
yeccpars2_438(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_438_(Stack),
 yeccpars2_442(442, Cat, [438 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_439(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_observedEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_440: see yeccpars2_230

yeccpars2_441(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_441_(Stack),
 yeccgoto_eventStreamOrOther(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_442(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 446, Ss, Stack, T, Ts, Tzr);
yeccpars2_442(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_443: see yeccpars2_4

yeccpars2_444(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 443, Ss, Stack, T, Ts, Tzr);
yeccpars2_444(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_444_(Stack),
 yeccpars2_445(_S, Cat, [444 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_445(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_445_(Stack),
 yeccgoto_observedEventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_446(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_446_(Stack),
 yeccgoto_observedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_447(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 448, Ss, Stack, T, Ts, Tzr);
yeccpars2_447(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_448(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_448(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_448_(Stack),
 yeccpars2_4(449, Cat, [448 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_449: see yeccpars2_4

yeccpars2_450(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 437, Ss, Stack, T, Ts, Tzr);
yeccpars2_450(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_450_(Stack),
 yeccpars2_451(_S, Cat, [450 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_451(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_451_(Stack),
 yeccgoto_observedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_452(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_452_(Stack),
 yeccgoto_notifyRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_453(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 455, Ss, Stack, T, Ts, Tzr);
yeccpars2_453(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_454(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 468, Ss, Stack, T, Ts, Tzr);
yeccpars2_454(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_455(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 456, Ss, Stack, T, Ts, Tzr);
yeccpars2_455(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_456(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 459, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 460, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 461, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 462, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_457(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_457_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_458(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 464, Ss, Stack, T, Ts, Tzr);
yeccpars2_458(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_458_(Stack),
 yeccpars2_463(463, Cat, [458 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_459(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_459_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_460(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_460_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_461(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_461_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_462(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_462_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_463(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 467, Ss, Stack, T, Ts, Tzr);
yeccpars2_463(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_464: see yeccpars2_456

yeccpars2_465(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 464, Ss, Stack, T, Ts, Tzr);
yeccpars2_465(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_465_(Stack),
 yeccpars2_466(_S, Cat, [465 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_466(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_466_(Stack),
 yeccgoto_contextAuditProperties(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_467(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_467_(Stack),
 yeccgoto_indAudcontextAttrDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_468(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_468_(Stack),
 yeccgoto_contextAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_469(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 476, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 477, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 478, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 479, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 480, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_470(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_470_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_471(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_471_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_472(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_472_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_473: see yeccpars2_230

yeccpars2_474(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_contextAttrDescProp(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_475(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 501, Ss, Stack, T, Ts, Tzr);
yeccpars2_475(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_475_(Stack),
 yeccpars2_500(500, Cat, [475 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_476(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_476_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_477(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_477_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_478(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_478_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_479(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 498, Ss, Stack, T, Ts, Tzr);
yeccpars2_479(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_480(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 481, Ss, Stack, T, Ts, Tzr);
yeccpars2_480(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_481: see yeccpars2_4

yeccpars2_482(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 494, Ss, Stack, T, Ts, Tzr);
yeccpars2_482(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_482_(Stack),
 yeccpars2_493(493, Cat, [482 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_483(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_terminationA(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_484(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 485, Ss, Stack, T, Ts, Tzr);
yeccpars2_484(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_485: see yeccpars2_4

yeccpars2_486(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_terminationB(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_487(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 488, Ss, Stack, T, Ts, Tzr);
yeccpars2_487(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_488(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 490, Ss, Stack, T, Ts, Tzr);
yeccpars2_488(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 491, Ss, Stack, T, Ts, Tzr);
yeccpars2_488(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 492, Ss, Stack, T, Ts, Tzr);
yeccpars2_488(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_489(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_489_(Stack),
 yeccgoto_topologyTriple(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_490(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_490_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_491(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_491_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_492(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_492_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_493(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 497, Ss, Stack, T, Ts, Tzr);
yeccpars2_493(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_494: see yeccpars2_4

yeccpars2_495(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 494, Ss, Stack, T, Ts, Tzr);
yeccpars2_495(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_495_(Stack),
 yeccpars2_496(_S, Cat, [495 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_496(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_496_(Stack),
 yeccgoto_topologyTripleList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_497(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_497_(Stack),
 yeccgoto_topologyDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_498: see yeccpars2_4

yeccpars2_499(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_499_(Stack),
 yeccgoto_priority(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_500(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 504, Ss, Stack, T, Ts, Tzr);
yeccpars2_500(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_501: see yeccpars2_469

yeccpars2_502(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 501, Ss, Stack, T, Ts, Tzr);
yeccpars2_502(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_502_(Stack),
 yeccpars2_503(_S, Cat, [502 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_503(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_503_(Stack),
 yeccgoto_contextAttrDescProps(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_504(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_504_(Stack),
 yeccgoto_contextAttrDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_505(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_505_(Stack),
 yeccgoto_propertyParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_506: see yeccpars2_4

yeccpars2_507(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 180, Ss, Stack, T, Ts, Tzr);
yeccpars2_507(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_507_(Stack),
 yeccpars2_508(_S, Cat, [507 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_508(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_508_(Stack),
 yeccgoto_auditRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_509: see yeccpars2_4

yeccpars2_510(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 180, Ss, Stack, T, Ts, Tzr);
yeccpars2_510(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_510_(Stack),
 yeccpars2_511(_S, Cat, [510 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_511(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_511_(Stack),
 yeccgoto_auditRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_512(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_512_(Stack),
 yeccgoto_actionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_513(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_513_(Stack),
 yeccgoto_actionRequestBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_514: see yeccpars2_153

yeccpars2_515(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 514, Ss, Stack, T, Ts, Tzr);
yeccpars2_515(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_515_(Stack),
 yeccpars2_516(_S, Cat, [515 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_516(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_516_(Stack),
 yeccgoto_actionRequestItems(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_517: see yeccpars2_4

yeccpars2_518(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 520, Ss, Stack, T, Ts, Tzr);
yeccpars2_518(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_518_(Stack),
 yeccpars2_519(_S, Cat, [518 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_519(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_519_(Stack),
 yeccgoto_ammRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_520(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 182, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 531, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 532, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 533, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 534, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 535, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 536, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 537, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 538, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_521(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_521_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_522(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_522_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_523(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_523_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_524(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_524_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_525(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_525_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_526(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_526_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_527(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_527_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_528(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_528_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_529(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_529_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_530(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 738, Ss, Stack, T, Ts, Tzr);
yeccpars2_530(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_530_(Stack),
 yeccpars2_737(737, Cat, [530 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_531(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_531_(Stack),
 yeccgoto_digitMapDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_532(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 729, Ss, Stack, T, Ts, Tzr);
yeccpars2_532(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_532_(Stack),
 yeccgoto_eventBufferDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_533(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 669, Ss, Stack, T, Ts, Tzr);
yeccpars2_533(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_533_(Stack),
 yeccgoto_eventsDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_534(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 598, Ss, Stack, T, Ts, Tzr);
yeccpars2_534(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_535(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 579, Ss, Stack, T, Ts, Tzr);
yeccpars2_535(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 580, Ss, Stack, T, Ts, Tzr);
yeccpars2_535(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_536(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 568, Ss, Stack, T, Ts, Tzr);
yeccpars2_536(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_537(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 549, Ss, Stack, T, Ts, Tzr);
yeccpars2_537(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_537_(Stack),
 yeccgoto_signalsDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_538(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 539, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_539: see yeccpars2_4

yeccpars2_540(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 545, Ss, Stack, T, Ts, Tzr);
yeccpars2_540(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_540_(Stack),
 yeccpars2_544(544, Cat, [540 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_541(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 542, Ss, Stack, T, Ts, Tzr);
yeccpars2_541(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_541_(Stack),
 yeccgoto_statisticsParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_542: see yeccpars2_270

yeccpars2_543(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_543_(Stack),
 yeccgoto_statisticsParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_544(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 548, Ss, Stack, T, Ts, Tzr);
yeccpars2_544(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_545: see yeccpars2_4

yeccpars2_546(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 545, Ss, Stack, T, Ts, Tzr);
yeccpars2_546(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_546_(Stack),
 yeccpars2_547(_S, Cat, [546 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_547(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_547_(Stack),
 yeccgoto_statisticsParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_548(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_548_(Stack),
 yeccgoto_statisticsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_549(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 553, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_549(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_550(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_550_(Stack),
 yeccgoto_signalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_551(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 564, Ss, Stack, T, Ts, Tzr);
yeccpars2_551(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_551_(Stack),
 yeccpars2_563(563, Cat, [551 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_552(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_552_(Stack),
 yeccgoto_signalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_553(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 554, Ss, Stack, T, Ts, Tzr);
yeccpars2_553(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_554: see yeccpars2_4

yeccpars2_555(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 556, Ss, Stack, T, Ts, Tzr);
yeccpars2_555(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_556: see yeccpars2_4

yeccpars2_557(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 559, Ss, Stack, T, Ts, Tzr);
yeccpars2_557(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_557_(Stack),
 yeccpars2_558(558, Cat, [557 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_558(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 562, Ss, Stack, T, Ts, Tzr);
yeccpars2_558(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_559: see yeccpars2_4

yeccpars2_560(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 559, Ss, Stack, T, Ts, Tzr);
yeccpars2_560(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_560_(Stack),
 yeccpars2_561(_S, Cat, [560 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_561(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_561_(Stack),
 yeccgoto_signalListParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_562(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_562_(Stack),
 yeccgoto_signalList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_563(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 567, Ss, Stack, T, Ts, Tzr);
yeccpars2_563(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_564: see yeccpars2_549

yeccpars2_565(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 564, Ss, Stack, T, Ts, Tzr);
yeccpars2_565(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_565_(Stack),
 yeccpars2_566(_S, Cat, [565 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_566(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_566_(Stack),
 yeccgoto_signalParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_567(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_567_(Stack),
 yeccgoto_signalsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_568: see yeccpars2_4

yeccpars2_569(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_569_(Stack),
 yeccgoto_muxType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_570(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 572, Ss, Stack, T, Ts, Tzr);
yeccpars2_570(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_571(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_571_(Stack),
 yeccgoto_muxDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_572: see yeccpars2_4

yeccpars2_573(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 575, Ss, Stack, T, Ts, Tzr);
yeccpars2_573(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_573_(Stack),
 yeccpars2_574(574, Cat, [573 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_574(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 578, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_575: see yeccpars2_4

yeccpars2_576(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 575, Ss, Stack, T, Ts, Tzr);
yeccpars2_576(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_576_(Stack),
 yeccpars2_577(_S, Cat, [576 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_577(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_577_(Stack),
 yeccgoto_terminationIDListRepeat(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_578(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_578_(Stack),
 yeccgoto_terminationIDList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_579: see yeccpars2_4

%% yeccpars2_580: see yeccpars2_4

yeccpars2_581(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_581_(Stack),
 yeccgoto_modemType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_582(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 584, Ss, Stack, T, Ts, Tzr);
yeccpars2_582(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_582_(Stack),
 yeccpars2_583(583, Cat, [582 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_583(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 587, Ss, Stack, T, Ts, Tzr);
yeccpars2_583(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_584: see yeccpars2_4

yeccpars2_585(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 584, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_585_(Stack),
 yeccpars2_586(_S, Cat, [585 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_586(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_586_(Stack),
 yeccgoto_modemTypeList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_587(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 589, Ss, Stack, T, Ts, Tzr);
yeccpars2_587(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_587_(Stack),
 yeccpars2_588(_S, Cat, [587 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_588(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_588_(Stack),
 yeccgoto_modemDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_589: see yeccpars2_4

yeccpars2_590(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 592, Ss, Stack, T, Ts, Tzr);
yeccpars2_590(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_590_(Stack),
 yeccpars2_591(591, Cat, [590 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_591(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 595, Ss, Stack, T, Ts, Tzr);
yeccpars2_591(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_592: see yeccpars2_4

yeccpars2_593(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 592, Ss, Stack, T, Ts, Tzr);
yeccpars2_593(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_593_(Stack),
 yeccpars2_594(_S, Cat, [593 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_594(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_594_(Stack),
 yeccgoto_propertyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_595(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_595_(Stack),
 yeccgoto_optPropertyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_596(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 589, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_596_(Stack),
 yeccpars2_597(_S, Cat, [596 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_597(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_597_(Stack),
 yeccgoto_modemDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_598(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 538, Ss, Stack, T, Ts, Tzr);
yeccpars2_598(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 608, Ss, Stack, T, Ts, Tzr);
yeccpars2_598(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 609, Ss, Stack, T, Ts, Tzr);
yeccpars2_598(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_598(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_598(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 605, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_598(S, 'LocalDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 606, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_598(S, 'RemoteDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 607, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_598(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_599(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_599_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_600(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_600_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_601(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_601_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_602(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_602_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_603(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 665, Ss, Stack, T, Ts, Tzr);
yeccpars2_603(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_603_(Stack),
 yeccpars2_664(664, Cat, [603 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_604_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_605(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 640, Ss, Stack, T, Ts, Tzr);
yeccpars2_605(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_606(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_606_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_607(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_607_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_608(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 631, Ss, Stack, T, Ts, Tzr);
yeccpars2_608(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_609(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 610, Ss, Stack, T, Ts, Tzr);
yeccpars2_609(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_610(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 615, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 616, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_611(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 627, Ss, Stack, T, Ts, Tzr);
yeccpars2_611(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_611_(Stack),
 yeccpars2_626(626, Cat, [611 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_612(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_612_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_613(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_613_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_614(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_614_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_615(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 622, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_616(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 617, Ss, Stack, T, Ts, Tzr);
yeccpars2_616(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_617(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 619, Ss, Stack, T, Ts, Tzr);
yeccpars2_617(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 620, Ss, Stack, T, Ts, Tzr);
yeccpars2_617(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 621, Ss, Stack, T, Ts, Tzr);
yeccpars2_617(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_618(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_618_(Stack),
 yeccgoto_serviceStates(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_619(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_619_(Stack),
 yeccgoto_serviceState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_620(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_620_(Stack),
 yeccgoto_serviceState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_621(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_621_(Stack),
 yeccgoto_serviceState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_622(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 624, Ss, Stack, T, Ts, Tzr);
yeccpars2_622(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 625, Ss, Stack, T, Ts, Tzr);
yeccpars2_622(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_623(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_623_(Stack),
 yeccgoto_eventBufferControl(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_624(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_624_(Stack),
 yeccgoto_eventBufferControlState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_625(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_625_(Stack),
 yeccgoto_eventBufferControlState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_626(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 630, Ss, Stack, T, Ts, Tzr);
yeccpars2_626(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_627: see yeccpars2_610

yeccpars2_628(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 627, Ss, Stack, T, Ts, Tzr);
yeccpars2_628(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_628_(Stack),
 yeccpars2_629(_S, Cat, [628 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_629(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_629_(Stack),
 yeccgoto_terminationStateParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_630(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_630_(Stack),
 yeccgoto_terminationStateDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_631: see yeccpars2_4

yeccpars2_632(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 633, Ss, Stack, T, Ts, Tzr);
yeccpars2_632(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_633(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 538, Ss, Stack, T, Ts, Tzr);
yeccpars2_633(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_598(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_634(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 636, Ss, Stack, T, Ts, Tzr);
yeccpars2_634(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_634_(Stack),
 yeccpars2_635(635, Cat, [634 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_635(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 639, Ss, Stack, T, Ts, Tzr);
yeccpars2_635(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_636: see yeccpars2_633

yeccpars2_637(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 636, Ss, Stack, T, Ts, Tzr);
yeccpars2_637(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_637_(Stack),
 yeccpars2_638(_S, Cat, [637 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_638(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_638_(Stack),
 yeccgoto_streamParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_639(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_639_(Stack),
 yeccgoto_streamDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_640(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 643, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 644, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 645, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_641(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_641_(Stack),
 yeccgoto_localParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_642(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 660, Ss, Stack, T, Ts, Tzr);
yeccpars2_642(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_642_(Stack),
 yeccpars2_659(659, Cat, [642 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_643(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 652, Ss, Stack, T, Ts, Tzr);
yeccpars2_643(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_644(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 650, Ss, Stack, T, Ts, Tzr);
yeccpars2_644(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_645(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 646, Ss, Stack, T, Ts, Tzr);
yeccpars2_645(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_646(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 648, Ss, Stack, T, Ts, Tzr);
yeccpars2_646(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 649, Ss, Stack, T, Ts, Tzr);
yeccpars2_646(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_647(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_647_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_648(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_648_(Stack),
 yeccgoto_onOrOff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_649(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_649_(Stack),
 yeccgoto_onOrOff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_650: see yeccpars2_646

yeccpars2_651(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_651_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_652(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 654, Ss, Stack, T, Ts, Tzr);
yeccpars2_652(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 655, Ss, Stack, T, Ts, Tzr);
yeccpars2_652(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 656, Ss, Stack, T, Ts, Tzr);
yeccpars2_652(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 657, Ss, Stack, T, Ts, Tzr);
yeccpars2_652(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 658, Ss, Stack, T, Ts, Tzr);
yeccpars2_652(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_653_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_654_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_655(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_655_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_656_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_657(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_657_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_658(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_658_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_659(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 663, Ss, Stack, T, Ts, Tzr);
yeccpars2_659(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_660: see yeccpars2_640

yeccpars2_661(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 660, Ss, Stack, T, Ts, Tzr);
yeccpars2_661(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_661_(Stack),
 yeccpars2_662(_S, Cat, [661 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_662(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_662_(Stack),
 yeccgoto_localParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_663(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_663_(Stack),
 yeccgoto_localControlDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_664(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 668, Ss, Stack, T, Ts, Tzr);
yeccpars2_664(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_665: see yeccpars2_598

yeccpars2_666(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 665, Ss, Stack, T, Ts, Tzr);
yeccpars2_666(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_666_(Stack),
 yeccpars2_667(_S, Cat, [666 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_667(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_667_(Stack),
 yeccgoto_mediaParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_668(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_668_(Stack),
 yeccgoto_mediaDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_669: see yeccpars2_4

yeccpars2_670(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 671, Ss, Stack, T, Ts, Tzr);
yeccpars2_670(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_671: see yeccpars2_4

yeccpars2_672(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 725, Ss, Stack, T, Ts, Tzr);
yeccpars2_672(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_672_(Stack),
 yeccpars2_724(724, Cat, [672 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_673(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 675, Ss, Stack, T, Ts, Tzr);
yeccpars2_673(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_673_(Stack),
 yeccpars2_674(_S, Cat, [673 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_674(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_674_(Stack),
 yeccgoto_requestedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_675(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 681, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 682, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 683, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_676(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_677(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 720, Ss, Stack, T, Ts, Tzr);
yeccpars2_677(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_677_(Stack),
 yeccpars2_719(719, Cat, [677 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_678(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_679(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_680(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_681(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_681_(Stack),
 yeccgoto_eventDM(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_682(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 684, Ss, Stack, T, Ts, Tzr);
yeccpars2_682(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_683(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_683_COMMA(Stack),
 yeccgoto_eventParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_683(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_683_RBRKT(Stack),
 yeccgoto_eventParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_683(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_684(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 687, Ss, Stack, T, Ts, Tzr);
yeccpars2_684(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 537, Ss, Stack, T, Ts, Tzr);
yeccpars2_684(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_685(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 715, Ss, Stack, T, Ts, Tzr);
yeccpars2_685(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 716, Ss, Stack, T, Ts, Tzr);
yeccpars2_685(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_686(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 714, Ss, Stack, T, Ts, Tzr);
yeccpars2_686(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_687(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 688, Ss, Stack, T, Ts, Tzr);
yeccpars2_687(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_687_(Stack),
 yeccgoto_embedFirst(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_688: see yeccpars2_4

yeccpars2_689(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 690, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_690: see yeccpars2_4

yeccpars2_691(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 710, Ss, Stack, T, Ts, Tzr);
yeccpars2_691(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_691_(Stack),
 yeccpars2_709(709, Cat, [691 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_692(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 694, Ss, Stack, T, Ts, Tzr);
yeccpars2_692(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_692_(Stack),
 yeccpars2_693(_S, Cat, [692 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_693(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_693_(Stack),
 yeccgoto_secondRequestedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_694(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 681, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 699, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 700, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_695(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 705, Ss, Stack, T, Ts, Tzr);
yeccpars2_695(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_695_(Stack),
 yeccpars2_704(704, Cat, [695 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_696(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_697(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_698(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_699(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 701, Ss, Stack, T, Ts, Tzr);
yeccpars2_699(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_700(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_700_COMMA(Stack),
 yeccgoto_secondEventParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_700(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_700_RBRKT(Stack),
 yeccgoto_secondEventParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_700(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_701(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 537, Ss, Stack, T, Ts, Tzr);
yeccpars2_701(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_702(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 703, Ss, Stack, T, Ts, Tzr);
yeccpars2_702(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_703(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_703_(Stack),
 yeccgoto_embedSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_704(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 708, Ss, Stack, T, Ts, Tzr);
yeccpars2_704(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_705: see yeccpars2_694

yeccpars2_706(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 705, Ss, Stack, T, Ts, Tzr);
yeccpars2_706(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_706_(Stack),
 yeccpars2_707(_S, Cat, [706 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_707(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_707_(Stack),
 yeccgoto_secondEventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_708(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_708_(Stack),
 yeccgoto_secondRequestedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_709(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 713, Ss, Stack, T, Ts, Tzr);
yeccpars2_709(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_710: see yeccpars2_4

yeccpars2_711(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 710, Ss, Stack, T, Ts, Tzr);
yeccpars2_711(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_711_(Stack),
 yeccpars2_712(_S, Cat, [711 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_712(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_712_(Stack),
 yeccgoto_secondRequestedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_713(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_713_(Stack),
 yeccgoto_embedFirst(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_714(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_714_(Stack),
 yeccgoto_embedNoSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_715(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 687, Ss, Stack, T, Ts, Tzr);
yeccpars2_715(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_716(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_716_(Stack),
 yeccgoto_embedWithSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_717(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 718, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_718(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_718_(Stack),
 yeccgoto_embedWithSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_719(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 723, Ss, Stack, T, Ts, Tzr);
yeccpars2_719(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_720: see yeccpars2_675

yeccpars2_721(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 720, Ss, Stack, T, Ts, Tzr);
yeccpars2_721(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_721_(Stack),
 yeccpars2_722(_S, Cat, [721 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_722(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_722_(Stack),
 yeccgoto_eventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_723(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_723_(Stack),
 yeccgoto_requestedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_724(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 728, Ss, Stack, T, Ts, Tzr);
yeccpars2_724(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_725: see yeccpars2_4

yeccpars2_726(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 725, Ss, Stack, T, Ts, Tzr);
yeccpars2_726(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_726_(Stack),
 yeccpars2_727(_S, Cat, [726 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_727(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_727_(Stack),
 yeccgoto_requestedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_728(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_728_(Stack),
 yeccgoto_eventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_729(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_729(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 393, Ss, Stack, T, Ts, Tzr);
yeccpars2_729(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_729_(Stack),
 yeccpars2_4(428, Cat, [729 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_730(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_730_(Stack),
 yeccgoto_eventSpec(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_731(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 733, Ss, Stack, T, Ts, Tzr);
yeccpars2_731(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_731_(Stack),
 yeccpars2_732(732, Cat, [731 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_732(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 736, Ss, Stack, T, Ts, Tzr);
yeccpars2_732(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_733(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_733(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 393, Ss, Stack, T, Ts, Tzr);
yeccpars2_733(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_733_(Stack),
 yeccpars2_4(428, Cat, [733 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_734(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 733, Ss, Stack, T, Ts, Tzr);
yeccpars2_734(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_734_(Stack),
 yeccpars2_735(_S, Cat, [734 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_735(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_735_(Stack),
 yeccgoto_eventSpecList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_736(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_736_(Stack),
 yeccgoto_eventBufferDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_737(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 741, Ss, Stack, T, Ts, Tzr);
yeccpars2_737(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_738: see yeccpars2_520

yeccpars2_739(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 738, Ss, Stack, T, Ts, Tzr);
yeccpars2_739(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_739_(Stack),
 yeccpars2_740(_S, Cat, [739 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_740(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_740_(Stack),
 yeccgoto_ammParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_741(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_741_(Stack),
 yeccgoto_ammRequestBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_742(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 746, Ss, Stack, T, Ts, Tzr);
yeccpars2_742(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_743: see yeccpars2_147

yeccpars2_744(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 743, Ss, Stack, T, Ts, Tzr);
yeccpars2_744(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_744_(Stack),
 yeccpars2_745(_S, Cat, [744 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_745(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_745_(Stack),
 yeccgoto_actionRequestList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_746(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_746_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_747(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 753, Ss, Stack, T, Ts, Tzr);
yeccpars2_747(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_748_(Stack),
 yeccgoto_transactionID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_749: see yeccpars2_147

yeccpars2_750(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 743, Ss, Stack, T, Ts, Tzr);
yeccpars2_750(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_750_(Stack),
 yeccpars2_751(751, Cat, [750 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_751(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 752, Ss, Stack, T, Ts, Tzr);
yeccpars2_751(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_752(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_752_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_753: see yeccpars2_147

yeccpars2_754(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 743, Ss, Stack, T, Ts, Tzr);
yeccpars2_754(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_754_(Stack),
 yeccpars2_755(755, Cat, [754 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_755(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 756, Ss, Stack, T, Ts, Tzr);
yeccpars2_755(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_756(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_756_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_757: see yeccpars2_4

yeccpars2_758(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 761, Ss, Stack, T, Ts, Tzr);
yeccpars2_758(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_758_(Stack),
 yeccpars2_760(760, Cat, [758 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_759(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_759_(Stack),
 yeccgoto_transactionAck(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_760(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 764, Ss, Stack, T, Ts, Tzr);
yeccpars2_760(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_761: see yeccpars2_4

yeccpars2_762(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 761, Ss, Stack, T, Ts, Tzr);
yeccpars2_762(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_762_(Stack),
 yeccpars2_763(_S, Cat, [762 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_763(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_763_(Stack),
 yeccgoto_transactionAckList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_764(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_764_(Stack),
 yeccgoto_transactionResponseAck(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_765: see yeccpars2_4

yeccpars2_766(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 767, Ss, Stack, T, Ts, Tzr);
yeccpars2_766(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_767(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 769, Ss, Stack, T, Ts, Tzr);
yeccpars2_767(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_767_(Stack),
 yeccpars2_768(768, Cat, [767 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_768(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 774, Ss, Stack, T, Ts, Tzr);
yeccpars2_768(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_768(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_769(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 770, Ss, Stack, T, Ts, Tzr);
yeccpars2_769(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_770(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_770_(Stack),
 yeccgoto_optImmAckRequired(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_771(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 896, Ss, Stack, T, Ts, Tzr);
yeccpars2_771(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_772(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_772_(Stack),
 yeccgoto_transactionReplyBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_773(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 893, Ss, Stack, T, Ts, Tzr);
yeccpars2_773(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_773_(Stack),
 yeccpars2_892(_S, Cat, [773 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_774(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 775, Ss, Stack, T, Ts, Tzr);
yeccpars2_774(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_775: see yeccpars2_4

yeccpars2_776(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 777, Ss, Stack, T, Ts, Tzr);
yeccpars2_776(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_777(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 787, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 788, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 789, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 169, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 790, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 791, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 792, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 793, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 794, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_778(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_778_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_779(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_779_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_780(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_780_(Stack),
 yeccgoto_actionReplyBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_781(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_781_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_782(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 888, Ss, Stack, T, Ts, Tzr);
yeccpars2_782(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_782_(Stack),
 yeccpars2_887(_S, Cat, [782 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_783(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_783_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_784(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 881, Ss, Stack, T, Ts, Tzr);
yeccpars2_784(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_785(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_785_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_786(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 880, Ss, Stack, T, Ts, Tzr);
yeccpars2_786(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_787(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_787_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_788(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 876, Ss, Stack, T, Ts, Tzr);
yeccpars2_788(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_789(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 826, Ss, Stack, T, Ts, Tzr);
yeccpars2_789(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_790(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_790_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_791(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_791_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_792(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 820, Ss, Stack, T, Ts, Tzr);
yeccpars2_792(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_793(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 795, Ss, Stack, T, Ts, Tzr);
yeccpars2_793(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_794(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_794_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_795: see yeccpars2_4

yeccpars2_796(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 798, Ss, Stack, T, Ts, Tzr);
yeccpars2_796(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_796_(Stack),
 yeccpars2_797(_S, Cat, [796 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_797(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_797_(Stack),
 yeccgoto_serviceChangeReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_798(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_798(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 801, Ss, Stack, T, Ts, Tzr);
yeccpars2_798(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_799(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 819, Ss, Stack, T, Ts, Tzr);
yeccpars2_799(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_800(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 818, Ss, Stack, T, Ts, Tzr);
yeccpars2_800(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_801(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 802, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_802(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 809, Ss, Stack, T, Ts, Tzr);
yeccpars2_802(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 810, Ss, Stack, T, Ts, Tzr);
yeccpars2_802(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 811, Ss, Stack, T, Ts, Tzr);
yeccpars2_802(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 393, Ss, Stack, T, Ts, Tzr);
yeccpars2_802(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 812, Ss, Stack, T, Ts, Tzr);
yeccpars2_802(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_803(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_803_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_804(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_804_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_805(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_805_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_806(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_806_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_807(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_807_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_808(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 814, Ss, Stack, T, Ts, Tzr);
yeccpars2_808(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_808_(Stack),
 yeccpars2_813(813, Cat, [808 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_809(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 404, Ss, Stack, T, Ts, Tzr);
yeccpars2_809(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_810(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 402, Ss, Stack, T, Ts, Tzr);
yeccpars2_810(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_811(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 397, Ss, Stack, T, Ts, Tzr);
yeccpars2_811(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_812(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 395, Ss, Stack, T, Ts, Tzr);
yeccpars2_812(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_813(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 817, Ss, Stack, T, Ts, Tzr);
yeccpars2_813(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_814: see yeccpars2_802

yeccpars2_815(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 814, Ss, Stack, T, Ts, Tzr);
yeccpars2_815(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_815_(Stack),
 yeccpars2_816(_S, Cat, [815 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_816(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_816_(Stack),
 yeccgoto_servChgReplyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_817(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_817_(Stack),
 yeccgoto_serviceChangeReplyDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_818(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_818_(Stack),
 yeccgoto_serviceChangeReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_819(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_819_(Stack),
 yeccgoto_serviceChangeReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_820: see yeccpars2_4

yeccpars2_821(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 823, Ss, Stack, T, Ts, Tzr);
yeccpars2_821(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_821_(Stack),
 yeccpars2_822(_S, Cat, [821 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_822(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_822_(Stack),
 yeccgoto_notifyReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_823(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_823(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_824(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 825, Ss, Stack, T, Ts, Tzr);
yeccpars2_824(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_825(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_825_(Stack),
 yeccgoto_notifyReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_826(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 829, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_827(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 843, Ss, Stack, T, Ts, Tzr);
yeccpars2_827(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_827_(Stack),
 yeccgoto_auditOther(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_828(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_828_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_829(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 832, Ss, Stack, T, Ts, Tzr);
yeccpars2_829(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_830(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_830_(Stack),
 yeccgoto_contextTerminationAudit(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_831(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_831_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_832(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 834, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_833(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 842, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_834(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 835, Ss, Stack, T, Ts, Tzr);
yeccpars2_834(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_835: see yeccpars2_4

yeccpars2_836(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_836_(Stack),
 yeccgoto_errorCode(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_837(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 838, Ss, Stack, T, Ts, Tzr);
yeccpars2_837(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_838(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 840, Ss, Stack, T, Ts, Tzr);
yeccpars2_838(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_838_(Stack),
 yeccpars2_839(839, Cat, [838 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_839(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 841, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_840(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_840_(Stack),
 yeccgoto_errorText(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_841(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_841_(Stack),
 yeccgoto_errorDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_842(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_842_(Stack),
 yeccgoto_contextTerminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_843(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 531, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 197, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 532, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 533, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 858, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 859, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 860, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 861, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 862, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 537, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 863, Ss, Stack, T, Ts, Tzr);
yeccpars2_843(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_844(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 875, Ss, Stack, T, Ts, Tzr);
yeccpars2_844(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_845(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_845_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_846(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_846_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_847(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_847_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_848(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_848_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_849(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_849_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_850(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_850_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_851(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_851_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_852(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_852_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_853(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_853_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_854(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_854_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_855(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_855_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_856(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 872, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_856_(Stack),
 yeccpars2_871(_S, Cat, [856 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_857(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_857_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_858(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 598, Ss, Stack, T, Ts, Tzr);
yeccpars2_858(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_858_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_859(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 579, Ss, Stack, T, Ts, Tzr);
yeccpars2_859(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 580, Ss, Stack, T, Ts, Tzr);
yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_859_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_860(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 568, Ss, Stack, T, Ts, Tzr);
yeccpars2_860(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_860_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_861(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 424, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_861_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_862(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 864, Ss, Stack, T, Ts, Tzr);
yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_862_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_863(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 539, Ss, Stack, T, Ts, Tzr);
yeccpars2_863(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_863_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_864: see yeccpars2_4

yeccpars2_865(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 867, Ss, Stack, T, Ts, Tzr);
yeccpars2_865(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_865_(Stack),
 yeccpars2_866(866, Cat, [865 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_866(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 870, Ss, Stack, T, Ts, Tzr);
yeccpars2_866(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_867: see yeccpars2_4

yeccpars2_868(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 867, Ss, Stack, T, Ts, Tzr);
yeccpars2_868(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_868_(Stack),
 yeccpars2_869(_S, Cat, [868 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_869(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_869_(Stack),
 yeccgoto_packagesItems(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_870(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_870_(Stack),
 yeccgoto_packagesDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_871(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_871_(Stack),
 yeccgoto_terminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_872: see yeccpars2_843

yeccpars2_873(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 872, Ss, Stack, T, Ts, Tzr);
yeccpars2_873(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_873_(Stack),
 yeccpars2_874(_S, Cat, [873 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_874(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_874_(Stack),
 yeccgoto_auditReturnParameterList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_875(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_875_(Stack),
 yeccgoto_auditOther(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_876(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 878, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_877(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_877_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_878(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 832, Ss, Stack, T, Ts, Tzr);
yeccpars2_878(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_879(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_879_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_880(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_880_(Stack),
 yeccgoto_actionReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_881: see yeccpars2_4

yeccpars2_882(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 884, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_882_(Stack),
 yeccpars2_883(_S, Cat, [882 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_883(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_883_(Stack),
 yeccgoto_ammsReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_884: see yeccpars2_843

yeccpars2_885(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 886, Ss, Stack, T, Ts, Tzr);
yeccpars2_885(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_886(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_886_(Stack),
 yeccgoto_ammsReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_887(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_887_(Stack),
 yeccgoto_actionReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_888: see yeccpars2_777

yeccpars2_889(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_889_(Stack),
 yeccgoto_commandReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_890(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 888, Ss, Stack, T, Ts, Tzr);
yeccpars2_890(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_890_(Stack),
 yeccpars2_891(_S, Cat, [890 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_891(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_891_(Stack),
 yeccgoto_commandReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_892(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_892_(Stack),
 yeccgoto_transactionReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_893(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 774, Ss, Stack, T, Ts, Tzr);
yeccpars2_893(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_894(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 893, Ss, Stack, T, Ts, Tzr);
yeccpars2_894(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_894_(Stack),
 yeccpars2_895(_S, Cat, [894 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_895(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_895_(Stack),
 yeccgoto_actionReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_896(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_896_(Stack),
 yeccgoto_transactionReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_897: see yeccpars2_4

yeccpars2_898(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 899, Ss, Stack, T, Ts, Tzr);
yeccpars2_898(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_899(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 900, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_900(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_900_(Stack),
 yeccgoto_transactionPending(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_901(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_901_(Stack),
 yeccgoto_transactionList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_902(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_902_(Stack),
 yeccgoto_pathName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_903(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_903_(Stack),
 yeccgoto_deviceName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_904(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_904(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_904_(Stack),
 yeccpars2_908(_S, Cat, [904 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_905(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_905(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_905_(Stack),
 yeccpars2_907(_S, Cat, [905 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_906(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_906_(Stack),
 yeccgoto_mtpAddress(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_907(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_907_(Stack),
 yeccgoto_mId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_908(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_908_(Stack),
 yeccgoto_mId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccgoto_actionReply(768, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_773(773, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionReply(893, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_894(894, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionReplyBody(777, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_786(786, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionReplyList(773=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_892(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionReplyList(894=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_895(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequest(147, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_148(148, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(743, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_744(744, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(749, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_750(750, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(753, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_754(754, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestBody(153, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(165, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestItem(153, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_164(164, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestItem(514, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_515(515, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestItems(164=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_513(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestItems(515=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_516(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestList(148, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_742(742, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(744=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_745(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(750, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_751(751, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(754, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_755(755, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_alternativeValue(269=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_279(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammParameter(520, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_530(530, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammParameter(738, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_739(739, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammParameters(530, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_737(737, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammParameters(739=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_740(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammRequest(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammRequest(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammRequestBody(518=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_519(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammToken(153, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_162(162, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammToken(514, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_162(162, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsReply(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_785(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammsReply(888=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_785(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsReplyBody(882=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_883(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsToken(777, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_784(784, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammsToken(888, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_784(784, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditDescriptor(180, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_181(181, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditDescriptor(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_529(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditDescriptor(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_529(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditDescriptorBody(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_195(195, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditItem(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_194(194, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(354, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_355(355, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_385(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_385(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditItemList(194=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_353(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItemList(355=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_356(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditOther(826=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_828(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditOther(876=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_877(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReply(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_783(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReply(888=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_783(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditRequest(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditRequest(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnItem(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_857(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_857(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_857(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnParameter(843, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_856(856, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameter(872, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_873(873, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameter(884, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_856(856, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnParameterList(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_871(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameterList(873=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_874(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_authenticationHeader(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandReplyList(782=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_887(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandReplyList(890=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_891(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandReplys(777, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_782(782, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandReplys(888, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_890(890, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandRequest(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandRequest(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAttrDescProp(469, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_475(475, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescProp(501, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_502(502, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAttrDescProps(475, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_500(500, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescProps(502=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_503(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAttrDescriptor(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(888=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAudit(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAudit(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAuditProperties(458, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_463(463, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperties(465=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_466(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAuditProperty(456, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_458(458, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperty(464, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_465(465, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextID(150, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_152(152, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextID(775, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_776(776, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextProperties(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperties(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperties(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_781(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperties(888=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_781(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextProperty(469=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_474(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(501=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_474(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextTerminationAudit(829=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_831(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextTerminationAudit(878=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_879(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_daddr(117, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(119, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_daddr(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_daddr(120=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_deviceName(112, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_905(905, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_digitMapDescriptor(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_528(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_528(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_855(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_855(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_855(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_direction(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_domainAddress(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainAddress(397=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainAddress(404=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_domainName(109=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainName(397=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainName(404=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedFirst(684, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_686(686, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedFirst(715, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_717(717, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedNoSig(675=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_680(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedNoSig(720=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_680(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedSig(694=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_698(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedSig(705=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_698(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedWithSig(675=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_679(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedWithSig(720=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_679(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorCode(835, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_837(837, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorDescriptor(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(419=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_422(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(768=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_772(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_780(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(798, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_800(800, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(823, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_824(824, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(832, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_833(833, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_854(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_854(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_854(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(888=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_889(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorText(838, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_839(839, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferControl(610=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_614(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferControl(627=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_614(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferControlState(622=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_623(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferDescriptor(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_527(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_527(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_853(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_853(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_853(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventDM(675=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_678(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(694=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_697(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(705=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_697(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(720=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_678(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameter(675, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_677(677, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameter(720, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_721(721, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameterName(343=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_347(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(437, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(440, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(443, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(440, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(675, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(440, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(694, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(440, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(705, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(440, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(720, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(440, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameters(677, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_719(719, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameters(721=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_722(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventSpec(729, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_731(731, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventSpec(733, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_734(734, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventSpecList(731, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_732(732, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventSpecList(734=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_735(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventStream(343=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_346(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventStreamOrOther(437=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_439(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(443=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_439(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(675=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_676(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(694=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_696(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(705=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_696(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(720=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_676(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventsDescriptor(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_526(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_526(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_852(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_852(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_852(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_extension(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_384(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_extension(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_384(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_extensionParameter(372, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(383, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_extensionParameter(412, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(383, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudauditReturnParameter(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(192, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(354, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(192, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(358, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_359(359, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(372, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(192, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(412, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(192, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudcontextAttrDescriptor(453, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_454(454, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAuddigitMapDescriptor(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(358=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventBufferDescriptor(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(358=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventSpec(338, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_340(340, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventSpecParameter(343, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_345(345, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventsDescriptor(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(358=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalControlDescriptor(303=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_309(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalControlDescriptor(320=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_309(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalParm(323, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_325(325, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalParm(327, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_328(328, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalParmList(325, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_326(326, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalParmList(328=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaDescriptor(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(358=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaParm(303, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_308(308, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudpackagesDescriptor(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(358=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudrequestedEvent(334, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_336(336, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalList(212=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_217(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalParm(212, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_216(216, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalsDescriptor(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(358=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstatisticsDescriptor(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(303=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_307(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(320=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_307(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(358=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstreamDescriptor(303=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_306(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstreamParm(303=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_305(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstreamParm(320, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_321(321, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationAudit(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationAuditList(192=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_357(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAuditList(359=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_365(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationStateDescriptor(303=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_304(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationStateParm(314, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_316(316, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localControlDescriptor(598=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(633=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(636=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(665=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localParm(640, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_642(642, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localParm(660, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_661(661, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localParmList(642, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_659(659, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localParmList(661=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_662(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mId(109, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_113(113, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mId(397=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_399(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mId(404=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_405(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaDescriptor(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_525(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_525(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_851(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_851(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_851(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaParm(598, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_603(603, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaParm(665, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_666(666, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaParmList(603, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_664(664, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaParmList(666=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_667(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_megacoMessage(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_message(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_110(110, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_messageBody(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemDescriptor(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_524(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_524(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_850(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_850(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_850(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemType(579, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_596(596, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemType(580, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_582(582, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemType(584, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_585(585, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemTypeList(582, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_583(583, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemTypeList(585=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_586(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mtpAddress(112, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_904(904, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_muxDescriptor(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_523(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_523(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_849(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_849(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_849(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_muxType(568, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_570(570, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notificationReason(250, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_251(251, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notificationReason(257, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_258(258, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notificationReasons(251, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_256(256, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notificationReasons(258=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyReply(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_779(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyReply(888=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_779(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyReplyBody(821=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_822(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyRequest(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyRequest(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyRequestBody(419, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_421(421, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEvent(426, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_429(429, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(431, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_432(432, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(729=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_730(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(733=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_730(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventBody(435=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_436(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventBody(450=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_451(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventParameter(437, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_438(438, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventParameter(443, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_444(444, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventParameters(438, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_442(442, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventParameters(444=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_445(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEvents(429, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_430(430, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvents(432=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventsDescriptor(419=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_420(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_848(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_848(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_848(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_onOrOff(646=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_647(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_onOrOff(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_651(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optAuditDescriptor(177=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optAuditDescriptor(507=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_508(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optAuditDescriptor(510=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_511(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optImmAckRequired(767, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_768(768, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optIndAudeventSpecParameter(339=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_342(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optIndAudsignalParm(205=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optIndAudsignalParm(364=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optPropertyParms(587=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_588(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optPropertyParms(596=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_597(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optSep(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(107=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_108(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(109, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_112(112, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(125=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(131=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(397, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_112(112, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(404, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_112(112, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(426, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(428, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(427, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_447(447, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(431, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(428, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(448, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(449, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(729, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(428, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(733, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(428, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(904=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_908(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(905=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_907(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_847(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_847(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_847(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesItem(299, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(301, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItem(864, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_865(865, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItem(867, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_868(868, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesItems(865, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_866(866, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItems(868=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_869(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_parmValue(230=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_268(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(383=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_410(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_441(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(473=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_505(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_pathName(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_903(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_pkgdName(207, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_209(209, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(212=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(334=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_335(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(338, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_339(339, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(428, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_435(435, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(449, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_450(450, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(456=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_457(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(464=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_457(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(469, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(473, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(501, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(473, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(539, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_541(541, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(545, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_541(541, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(549=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(556=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(559=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(564=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(589, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(473, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(592, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(473, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(610, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(473, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(627, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(473, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(640, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(473, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(660, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(473, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(671, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_673(673, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(690, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_692(692, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(710, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_692(692, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(725, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_673(673, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_portNumber(123, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(125, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_portNumber(130, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_portNumber(397=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_398(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_priority(469=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_472(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(501=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_472(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParm(469=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_471(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(501=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_471(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(589, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_590(590, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(592, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_593(593, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(610=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_613(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(627=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_613(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(640=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_641(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(660=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_641(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParms(590, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_591(591, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParms(593=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_594(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestID(246=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(332, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_333(333, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(424, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_425(425, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(669, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_670(670, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(688, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_689(689, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEvent(671, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_672(672, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestedEvent(725, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_726(726, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEventBody(673=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_674(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEvents(672, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_724(724, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestedEvents(726=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_727(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_safeToken(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_109(109, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(6, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(104, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_105(105, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(106, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_107(107, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_902(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(116, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_128(128, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(117, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(118, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(120, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(123=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(130=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(146=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(150=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(176=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(212=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(220=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_222(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(228, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(230, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(238=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_240(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(246=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_247(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(261=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(269=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(270=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(271=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(272=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(281=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(284=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(285=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(295, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(230, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(299=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_300(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(314=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_315(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(318=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_240(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(323=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(327=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(332=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_247(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(334=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(338=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(343=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(349=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_240(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(367=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_382(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(395=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(397=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(402=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(406=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_407(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(408=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_409(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_382(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(417=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(424=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_247(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(428=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(437=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(443=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(449=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(456=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(464=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(469=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(481=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(485=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(494=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(498=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_499(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(501=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(509=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(517=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(539=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(542=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(549=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(554=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_222(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(556=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(559=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(564=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_569(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(572=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(575=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(579=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_581(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(580=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_581(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(584=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_581(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(589=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(592=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(610=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(627=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(631=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_240(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(640=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(660=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(669=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_247(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(671=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(675=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(688=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_247(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(690=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(694=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(705=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(710=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(720=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(725=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(757=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_759(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(761=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_759(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(765=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(775=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(795=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(820=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(826=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(832=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(835=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_836(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(864=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_300(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(867=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_300(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(876=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(881=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_safeToken2(4=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(6=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(104=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(106=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(116=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(117=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(120=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(123=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(130=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(146=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(150=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(176=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(212=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(220=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(228=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(238=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(246=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(261=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(269=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(270=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(271=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(272=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(280=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(281=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(284=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(285=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(295=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(299=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(314=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(318=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(323=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(327=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(332=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(334=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(338=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(343=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(349=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(367=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(395=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(397=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(402=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(406=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(408=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(417=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(424=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(428=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(437=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(443=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(449=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(456=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(464=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(469=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(481=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(485=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(494=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(498=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(501=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(509=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(517=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(539=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(542=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(549=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(554=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(556=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(559=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(564=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(572=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(575=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(579=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(580=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(584=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(589=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(592=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(610=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(627=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(631=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(640=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(660=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(669=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(671=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(675=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(688=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(690=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(694=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(705=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(710=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(720=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(725=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(757=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(761=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(765=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(775=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(795=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(820=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(826=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(832=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(835=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(864=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(867=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(876=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(881=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondEventParameter(694, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_695(695, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondEventParameter(705, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_706(706, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondEventParameters(695, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_704(704, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondEventParameters(706=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_707(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEvent(690, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_691(691, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondRequestedEvent(710, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_711(711, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEventBody(692=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_693(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEvents(691, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_709(709, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondRequestedEvents(711=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_712(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_servChgReplyParm(802, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_808(808, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_servChgReplyParm(814, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_815(815, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_servChgReplyParms(808, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_813(813, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_servChgReplyParms(815=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_816(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeAddress(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_381(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_381(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(802=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_807(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(814=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_807(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeDelay(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_380(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeDelay(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_380(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeDescriptor(369, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_370(370, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeMethod(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_379(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMethod(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_379(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeMgcId(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_378(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_378(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(802=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_806(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(814=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_806(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeParm(372, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_377(377, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeParm(412, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_413(413, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeParms(377, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_411(411, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeParms(413=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_414(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeProfile(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_376(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_376(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(802=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_805(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(814=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_805(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReason(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_375(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeReason(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_375(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReply(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_778(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeReply(888=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_778(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReplyBody(796=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_797(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReplyDescriptor(798, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_799(799, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeRequest(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeRequest(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeVersion(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(802=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_804(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(814=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_804(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceState(617=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_618(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceStates(610=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_612(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceStates(627=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_612(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_sigParameter(228, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(229, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sigParameter(295, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_296(296, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_sigParameters(229, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(294, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sigParameters(296=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalList(549=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_552(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalList(564=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_552(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListId(220, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_221(221, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListId(554, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_555(555, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListParm(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_225(225, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParm(556, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_557(557, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParm(559, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_560(560, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListParms(557, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_558(558, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParms(560=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_561(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalName(212, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(214, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(214, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(549, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(214, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(556, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(214, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(559, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(214, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(564, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(214, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalParm(549, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_551(551, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalParm(564, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_565(565, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalParms(551, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_563(563, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalParms(565=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_566(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalRequest(212=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(549=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_550(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(556=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(559=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(564=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_550(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalType(241=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_242(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalsDescriptor(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_522(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(684, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_685(685, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(701, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_702(702, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_522(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_846(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_846(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_846(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsDescriptor(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_521(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(598=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_602(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(633=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_602(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(636=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_602(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(665=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_602(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_521(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(843=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_845(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(872=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_845(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(884=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_845(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsParameter(539, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_540(540, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsParameter(545, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_546(546, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsParameters(540, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_544(544, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsParameters(546=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_547(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamDescriptor(598=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_601(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamDescriptor(665=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_601(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamID(238=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(318, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_319(319, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(349=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_350(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(631, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_632(632, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamModes(652=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamParm(598=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_600(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(633, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_634(634, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(636, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_637(637, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(665=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_600(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamParmList(634, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_635(635, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParmList(637=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_638(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_subtractRequest(153=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_subtractRequest(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationA(481, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_484(484, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationA(494, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_484(484, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationAudit(843, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_844(844, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationAudit(884, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_885(885, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationB(485, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_487(487, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationID(176, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_177(177, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(367, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_368(368, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(417, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_418(418, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(481=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_483(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(485=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_486(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(494=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_483(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(506, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_507(507, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(509, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_510(510, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(517, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_518(518, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(572, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_573(573, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(575, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_576(576, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(795, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_796(796, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(820, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_821(821, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(826, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_827(827, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(832, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_573(573, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(876, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_827(827, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(881, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_882(882, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationIDList(570=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_571(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDList(829=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_830(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDList(878=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_830(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationIDListRepeat(573, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_574(574, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDListRepeat(576=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_577(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateDescriptor(598=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_599(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateDescriptor(665=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_599(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateParm(610, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_611(611, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateParm(627, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_628(628, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateParms(611, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_626(626, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateParms(628=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_629(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_timeStamp(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_373(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_373(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(426, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_427(427, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(431, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_427(427, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(729, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_427(427, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(733, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_427(427, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(802=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_803(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(814=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_803(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDescriptor(469=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_470(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(501=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_470(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDirection(488=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_489(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyTriple(481, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_482(482, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyTriple(494, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_495(495, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyTripleList(482, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_493(493, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyTripleList(495=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_496(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionAck(757, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_758(758, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionAck(761, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_762(762, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionAckList(758, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_760(760, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionAckList(762=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_763(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionID(146, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_747(747, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionID(765, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_766(766, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionID(897, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_898(898, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionItem(113, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(138, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionItem(138, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(138, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionList(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionList(138=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_901(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionPending(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionPending(138=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionReply(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionReply(138=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionReplyBody(768, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_771(771, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionRequest(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionRequest(138=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionResponseAck(113=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_133(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionResponseAck(138=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_133(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_value(269=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_278(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(270=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_277(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(271=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_276(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(272=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_273(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(280, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_291(291, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(281, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_282(282, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(284, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(288, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(285, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_286(286, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(542=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_543(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_valueList(282, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_283(283, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_valueList(286=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_287(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_valueList(291, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(292, Cat, Ss, Stack, T, Ts, Tzr).

-compile({inline,yeccpars2_0_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_0_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_1_/1}).
-file("megaco_text_parser_prev3a.yrl", 476).
yeccpars2_1_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_3_/1}).
-file("megaco_text_parser_prev3a.yrl", 470).
yeccpars2_3_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sep
  end | __Stack].

-compile({inline,yeccpars2_7_/1}).
-file("megaco_text_parser_prev3a.yrl", 1445).
yeccpars2_7_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   make_safe_token ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_107_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_107_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_108_/1}).
-file("megaco_text_parser_prev3a.yrl", 475).
yeccpars2_108_(__Stack0) ->
 [__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_auth_header ( __3 , __5 , __7 )
  end | __Stack].

-compile({inline,yeccpars2_109_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_109_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_111_/1}).
-file("megaco_text_parser_prev3a.yrl", 468).
yeccpars2_111_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'MegacoMessage' { authHeader = __2 , mess = __3 }
  end | __Stack].

-compile({inline,yeccpars2_117_/1}).
-file("megaco_text_parser_prev3a.yrl", 953).
yeccpars2_117_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_118_/1}).
-file("megaco_text_parser_prev3a.yrl", 953).
yeccpars2_118_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_120_/1}).
-file("megaco_text_parser_prev3a.yrl", 953).
yeccpars2_120_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_121_/1}).
-file("megaco_text_parser_prev3a.yrl", 954).
yeccpars2_121_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ colon | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_122_/1}).
-file("megaco_text_parser_prev3a.yrl", 951).
yeccpars2_122_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainAddress ( __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_124_/1}).
-file("megaco_text_parser_prev3a.yrl", 958).
yeccpars2_124_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_125_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_125_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_126_/1}).
-file("megaco_text_parser_prev3a.yrl", 949).
yeccpars2_126_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainAddress ( __2 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_127_/1}).
-file("megaco_text_parser_prev3a.yrl", 955).
yeccpars2_127_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_129_/1}).
-file("megaco_text_parser_prev3a.yrl", 941).
yeccpars2_129_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainName ( __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_131_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_131_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_132_/1}).
-file("megaco_text_parser_prev3a.yrl", 939).
yeccpars2_132_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainName ( __2 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_133_/1}).
-file("megaco_text_parser_prev3a.yrl", 489).
yeccpars2_133_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionResponseAck , __1 }
  end | __Stack].

-compile({inline,yeccpars2_134_/1}).
-file("megaco_text_parser_prev3a.yrl", 486).
yeccpars2_134_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionRequest , __1 }
  end | __Stack].

-compile({inline,yeccpars2_135_/1}).
-file("megaco_text_parser_prev3a.yrl", 487).
yeccpars2_135_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionReply , __1 }
  end | __Stack].

-compile({inline,yeccpars2_136_/1}).
-file("megaco_text_parser_prev3a.yrl", 488).
yeccpars2_136_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionPending , __1 }
  end | __Stack].

-compile({inline,yeccpars2_137_/1}).
-file("megaco_text_parser_prev3a.yrl", 481).
yeccpars2_137_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactions , __1 }
  end | __Stack].

-compile({inline,yeccpars2_138_/1}).
-file("megaco_text_parser_prev3a.yrl", 483).
yeccpars2_138_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_139_/1}).
-file("megaco_text_parser_prev3a.yrl", 478).
yeccpars2_139_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_message ( __1 , __2 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_140_/1}).
-file("megaco_text_parser_prev3a.yrl", 480).
yeccpars2_140_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { messageError , __1 }
  end | __Stack].

-compile({inline,yeccpars2_148_/1}).
-file("megaco_text_parser_prev3a.yrl", 516).
yeccpars2_148_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_151_/1}).
-file("megaco_text_parser_prev3a.yrl", 946).
yeccpars2_151_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_contextID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_157_/1}).
-file("megaco_text_parser_prev3a.yrl", 528).
yeccpars2_157_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextProps , __1 }
  end | __Stack].

-compile({inline,yeccpars2_158_/1}).
-file("megaco_text_parser_prev3a.yrl", 529).
yeccpars2_158_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextAudit , __1 }
  end | __Stack].

-compile({inline,yeccpars2_159_/1}).
-file("megaco_text_parser_prev3a.yrl", 533).
yeccpars2_159_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_context_request ( # 'ContextRequest' { } , __1 )
  end | __Stack].

-compile({inline,yeccpars2_160_/1}).
-file("megaco_text_parser_prev3a.yrl", 530).
yeccpars2_160_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { commandRequest , __1 }
  end | __Stack].

-compile({inline,yeccpars2_164_/1}).
-file("megaco_text_parser_prev3a.yrl", 526).
yeccpars2_164_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_166_/1}).
-file("megaco_text_parser_prev3a.yrl", 629).
yeccpars2_166_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { addReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_171_/1}).
-file("megaco_text_parser_prev3a.yrl", 631).
yeccpars2_171_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { modReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_172_/1}).
-file("megaco_text_parser_prev3a.yrl", 630).
yeccpars2_172_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { moveReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_177_/1}).
-file("megaco_text_parser_prev3a.yrl", 670).
yeccpars2_177_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_178_/1}).
-file("megaco_text_parser_prev3a.yrl", 974).
yeccpars2_178_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_terminationID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_179_/1}).
-file("megaco_text_parser_prev3a.yrl", 664).
yeccpars2_179_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { subtractReq , __1 } ,
    # 'SubtractRequest' { terminationID = [ __3 ] ,
    auditDescriptor = __4 } )
  end | __Stack].

-compile({inline,yeccpars2_183_/1}).
-file("megaco_text_parser_prev3a.yrl", 728).
yeccpars2_183_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_184_/1}).
-file("megaco_text_parser_prev3a.yrl", 749).
yeccpars2_184_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { terminationAudit , __1 }
  end | __Stack].

-compile({inline,yeccpars2_185_/1}).
-file("megaco_text_parser_prev3a.yrl", 776).
yeccpars2_185_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudStatisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_186_/1}).
-file("megaco_text_parser_prev3a.yrl", 770).
yeccpars2_186_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudSignalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_187_/1}).
-file("megaco_text_parser_prev3a.yrl", 778).
yeccpars2_187_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudPackagesDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_188_/1}).
-file("megaco_text_parser_prev3a.yrl", 766).
yeccpars2_188_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudMediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_189_/1}).
-file("megaco_text_parser_prev3a.yrl", 768).
yeccpars2_189_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudEventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_190_/1}).
-file("megaco_text_parser_prev3a.yrl", 774).
yeccpars2_190_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudEventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_191_/1}).
-file("megaco_text_parser_prev3a.yrl", 772).
yeccpars2_191_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudDigitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_192_/1}).
-file("megaco_text_parser_prev3a.yrl", 763).
yeccpars2_192_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_194_/1}).
-file("megaco_text_parser_prev3a.yrl", 731).
yeccpars2_194_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_196_/1}).
-file("megaco_text_parser_prev3a.yrl", 873).
yeccpars2_196_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_IADMD ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_197_/1}).
-file("megaco_text_parser_prev3a.yrl", 738).
yeccpars2_197_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   digitMapToken
  end | __Stack].

-compile({inline,yeccpars2_198_/1}).
-file("megaco_text_parser_prev3a.yrl", 747).
yeccpars2_198_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   eventBufferToken
  end | __Stack].

-compile({inline,yeccpars2_199_/1}).
-file("megaco_text_parser_prev3a.yrl", 748).
yeccpars2_199_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   eventsToken
  end | __Stack].

-compile({inline,yeccpars2_200_/1}).
-file("megaco_text_parser_prev3a.yrl", 737).
yeccpars2_200_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   mediaToken
  end | __Stack].

-compile({inline,yeccpars2_201_/1}).
-file("megaco_text_parser_prev3a.yrl", 736).
yeccpars2_201_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modemToken
  end | __Stack].

-compile({inline,yeccpars2_202_/1}).
-file("megaco_text_parser_prev3a.yrl", 735).
yeccpars2_202_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   muxToken
  end | __Stack].

-compile({inline,yeccpars2_203_/1}).
-file("megaco_text_parser_prev3a.yrl", 740).
yeccpars2_203_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   observedEventsToken
  end | __Stack].

-compile({inline,yeccpars2_204_/1}).
-file("megaco_text_parser_prev3a.yrl", 741).
yeccpars2_204_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   packagesToken
  end | __Stack].

-compile({inline,yeccpars2_205_/1}).
-file("megaco_text_parser_prev3a.yrl", 746).
yeccpars2_205_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   signalsToken
  end | __Stack].

-compile({inline,yeccpars2_206_/1}).
-file("megaco_text_parser_prev3a.yrl", 739).
yeccpars2_206_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statsToken
  end | __Stack].

-compile({inline,yeccpars2_208_/1}).
-file("megaco_text_parser_prev3a.yrl", 1114).
yeccpars2_208_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_pkgdName ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_210_/1}).
-file("megaco_text_parser_prev3a.yrl", 876).
yeccpars2_210_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStatisticsDescriptor' { statName = __3 }
  end | __Stack].

-compile({inline,yeccpars2_211_/1}).
-file("megaco_text_parser_prev3a.yrl", 855).
yeccpars2_211_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_213_/1}).
-file("megaco_text_parser_prev3a.yrl", 862).
yeccpars2_213_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signal , ensure_indAudSignal ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_214_/1}).
-file("megaco_text_parser_prev3a.yrl", 1207).
yeccpars2_214_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_signalRequest ( __1 , [ ] )
  end | __Stack].

-compile({inline,yeccpars2_217_/1}).
-file("megaco_text_parser_prev3a.yrl", 861).
yeccpars2_217_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { seqSigList , __1 }
  end | __Stack].

-compile({inline,yeccpars2_218_/1}).
-file("megaco_text_parser_prev3a.yrl", 858).
yeccpars2_218_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   asn1_NOVALUE
  end | __Stack].

-compile({inline,yeccpars2_222_/1}).
-file("megaco_text_parser_prev3a.yrl", 1271).
yeccpars2_222_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_226_/1}).
-file("megaco_text_parser_prev3a.yrl", 866).
yeccpars2_226_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudSeqSigList' { id = ensure_uint16 ( __3 ) ,
    signalList =
    ensure_indAudSignalListParm ( __5 ) }
  end | __Stack].

-compile({inline,yeccpars2_227_/1}).
-file("megaco_text_parser_prev3a.yrl", 859).
yeccpars2_227_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_229_/1}).
-file("megaco_text_parser_prev3a.yrl", 1210).
yeccpars2_229_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_233_COMMA/1}).
-file("megaco_text_parser_prev3a.yrl", 1240).
yeccpars2_233_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_233_RBRKT/1}).
-file("megaco_text_parser_prev3a.yrl", 1240).
yeccpars2_233_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_239_/1}).
-file("megaco_text_parser_prev3a.yrl", 1232).
yeccpars2_239_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { stream , __3 }
  end | __Stack].

-compile({inline,yeccpars2_240_/1}).
-file("megaco_text_parser_prev3a.yrl", 1112).
yeccpars2_240_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_streamID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_242_/1}).
-file("megaco_text_parser_prev3a.yrl", 1234).
yeccpars2_242_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { signal_type , __3 }
  end | __Stack].

-compile({inline,yeccpars2_243_/1}).
-file("megaco_text_parser_prev3a.yrl", 1248).
yeccpars2_243_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   brief
  end | __Stack].

-compile({inline,yeccpars2_244_/1}).
-file("megaco_text_parser_prev3a.yrl", 1246).
yeccpars2_244_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onOff
  end | __Stack].

-compile({inline,yeccpars2_245_/1}).
-file("megaco_text_parser_prev3a.yrl", 1247).
yeccpars2_245_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   timeOut
  end | __Stack].

-compile({inline,yeccpars2_247_/1}).
-file("megaco_text_parser_prev3a.yrl", 1305).
yeccpars2_247_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_requestID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_248_/1}).
-file("megaco_text_parser_prev3a.yrl", 1242).
yeccpars2_248_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { requestId , __3 }
  end | __Stack].

-compile({inline,yeccpars2_251_/1}).
-file("megaco_text_parser_prev3a.yrl", 1255).
yeccpars2_251_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_252_/1}).
-file("megaco_text_parser_prev3a.yrl", 1258).
yeccpars2_252_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onInterruptByEvent
  end | __Stack].

-compile({inline,yeccpars2_253_/1}).
-file("megaco_text_parser_prev3a.yrl", 1259).
yeccpars2_253_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onInterruptByNewSignalDescr
  end | __Stack].

-compile({inline,yeccpars2_254_/1}).
-file("megaco_text_parser_prev3a.yrl", 1260).
yeccpars2_254_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   otherReason
  end | __Stack].

-compile({inline,yeccpars2_255_/1}).
-file("megaco_text_parser_prev3a.yrl", 1257).
yeccpars2_255_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onTimeOut
  end | __Stack].

-compile({inline,yeccpars2_258_/1}).
-file("megaco_text_parser_prev3a.yrl", 1255).
yeccpars2_258_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_259_/1}).
-file("megaco_text_parser_prev3a.yrl", 1254).
yeccpars2_259_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_260_/1}).
-file("megaco_text_parser_prev3a.yrl", 1239).
yeccpars2_260_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { notify_completion , [ __4 | __5 ] }
  end | __Stack].

-compile({inline,yeccpars2_262_/1}).
-file("megaco_text_parser_prev3a.yrl", 1236).
yeccpars2_262_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { duration , ensure_uint16 ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_264_/1}).
-file("megaco_text_parser_prev3a.yrl", 1241).
yeccpars2_264_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { direction , __3 }
  end | __Stack].

-compile({inline,yeccpars2_265_/1}).
-file("megaco_text_parser_prev3a.yrl", 1252).
yeccpars2_265_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   both
  end | __Stack].

-compile({inline,yeccpars2_266_/1}).
-file("megaco_text_parser_prev3a.yrl", 1250).
yeccpars2_266_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   external
  end | __Stack].

-compile({inline,yeccpars2_267_/1}).
-file("megaco_text_parser_prev3a.yrl", 1251).
yeccpars2_267_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   internal
  end | __Stack].

-compile({inline,yeccpars2_268_/1}).
-file("megaco_text_parser_prev3a.yrl", 1244).
yeccpars2_268_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { other , ensure_NAME ( __1 ) , __2 }
  end | __Stack].

-compile({inline,yeccpars2_273_/1}).
-file("megaco_text_parser_prev3a.yrl", 1048).
yeccpars2_273_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , unequalTo } }
  end | __Stack].

-compile({inline,yeccpars2_274_/1}).
-file("megaco_text_parser_prev3a.yrl", 1443).
yeccpars2_274_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_value ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_275_/1}).
-file("megaco_text_parser_prev3a.yrl", 1442).
yeccpars2_275_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_value ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_276_/1}).
-file("megaco_text_parser_prev3a.yrl", 1051).
yeccpars2_276_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , smallerThan } }
  end | __Stack].

-compile({inline,yeccpars2_277_/1}).
-file("megaco_text_parser_prev3a.yrl", 1054).
yeccpars2_277_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , greaterThan } }
  end | __Stack].

-compile({inline,yeccpars2_278_/1}).
-file("megaco_text_parser_prev3a.yrl", 1075).
yeccpars2_278_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __1 ] }
  end | __Stack].

-compile({inline,yeccpars2_279_/1}).
-file("megaco_text_parser_prev3a.yrl", 1045).
yeccpars2_279_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_282_/1}).
-file("megaco_text_parser_prev3a.yrl", 1078).
yeccpars2_282_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_286_/1}).
-file("megaco_text_parser_prev3a.yrl", 1078).
yeccpars2_286_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_287_/1}).
-file("megaco_text_parser_prev3a.yrl", 1077).
yeccpars2_287_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_289_/1}).
-file("megaco_text_parser_prev3a.yrl", 1067).
yeccpars2_289_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 , __4 ] ,
    extraInfo = { range , true } }
  end | __Stack].

-compile({inline,yeccpars2_290_/1}).
-file("megaco_text_parser_prev3a.yrl", 1071).
yeccpars2_290_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 | __3 ] ,
    extraInfo = { sublist , true } }
  end | __Stack].

-compile({inline,yeccpars2_291_/1}).
-file("megaco_text_parser_prev3a.yrl", 1078).
yeccpars2_291_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_293_/1}).
-file("megaco_text_parser_prev3a.yrl", 1063).
yeccpars2_293_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 | __3 ] ,
    extraInfo = { sublist , false } }
  end | __Stack].

-compile({inline,yeccpars2_296_/1}).
-file("megaco_text_parser_prev3a.yrl", 1210).
yeccpars2_296_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_297_/1}).
-file("megaco_text_parser_prev3a.yrl", 1209).
yeccpars2_297_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_298_/1}).
-file("megaco_text_parser_prev3a.yrl", 1206).
yeccpars2_298_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_signalRequest ( __1 , [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_300_/1}).
-file("megaco_text_parser_prev3a.yrl", 1396).
yeccpars2_300_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_packagesItem ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_302_/1}).
-file("megaco_text_parser_prev3a.yrl", 879).
yeccpars2_302_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudPackagesDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_304_/1}).
-file("megaco_text_parser_prev3a.yrl", 797).
yeccpars2_304_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { termStateDescr , __1 }
  end | __Stack].

-compile({inline,yeccpars2_305_/1}).
-file("megaco_text_parser_prev3a.yrl", 795).
yeccpars2_305_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_306_/1}).
-file("megaco_text_parser_prev3a.yrl", 796).
yeccpars2_306_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamDescr , __1 }
  end | __Stack].

-compile({inline,yeccpars2_307_/1}).
-file("megaco_text_parser_prev3a.yrl", 803).
yeccpars2_307_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamParms' { statisticsDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_309_/1}).
-file("megaco_text_parser_prev3a.yrl", 801).
yeccpars2_309_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamParms' { localControlDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_315_/1}).
-file("megaco_text_parser_prev3a.yrl", 831).
yeccpars2_315_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_indAudTerminationStateParm ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_317_/1}).
-file("megaco_text_parser_prev3a.yrl", 825).
yeccpars2_317_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudTerminationStateDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_322_/1}).
-file("megaco_text_parser_prev3a.yrl", 807).
yeccpars2_322_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamDescriptor' { streamID = __3 ,
    streamParms = __5 }
  end | __Stack].

-compile({inline,yeccpars2_324_/1}).
-file("megaco_text_parser_prev3a.yrl", 820).
yeccpars2_324_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_indAudLocalParm ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_325_/1}).
-file("megaco_text_parser_prev3a.yrl", 816).
yeccpars2_325_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_328_/1}).
-file("megaco_text_parser_prev3a.yrl", 816).
yeccpars2_328_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_329_/1}).
-file("megaco_text_parser_prev3a.yrl", 815).
yeccpars2_329_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_330_/1}).
-file("megaco_text_parser_prev3a.yrl", 813).
yeccpars2_330_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudLocalControlDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_331_/1}).
-file("megaco_text_parser_prev3a.yrl", 783).
yeccpars2_331_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudMediaDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_337_/1}).
-file("megaco_text_parser_prev3a.yrl", 849).
yeccpars2_337_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudEventsDescriptor' { requestID = __3 ,
    pkgdName = __5 }
  end | __Stack].

-compile({inline,yeccpars2_339_/1}).
-file("megaco_text_parser_prev3a.yrl", 841).
yeccpars2_339_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_341_/1}).
-file("megaco_text_parser_prev3a.yrl", 834).
yeccpars2_341_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_342_/1}).
-file("megaco_text_parser_prev3a.yrl", 837).
yeccpars2_342_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudEventBufferDescriptor ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_344_/1}).
-file("megaco_text_parser_prev3a.yrl", 1188).
yeccpars2_344_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_NAME ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_346_/1}).
-file("megaco_text_parser_prev3a.yrl", 844).
yeccpars2_346_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamID , __1 }
  end | __Stack].

-compile({inline,yeccpars2_347_/1}).
-file("megaco_text_parser_prev3a.yrl", 845).
yeccpars2_347_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventParameterName , __1 }
  end | __Stack].

-compile({inline,yeccpars2_350_/1}).
-file("megaco_text_parser_prev3a.yrl", 881).
yeccpars2_350_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_351_/1}).
-file("megaco_text_parser_prev3a.yrl", 840).
yeccpars2_351_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_352_/1}).
-file("megaco_text_parser_prev3a.yrl", 725).
yeccpars2_352_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_auditDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_353_/1}).
-file("megaco_text_parser_prev3a.yrl", 727).
yeccpars2_353_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_355_/1}).
-file("megaco_text_parser_prev3a.yrl", 731).
yeccpars2_355_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_356_/1}).
-file("megaco_text_parser_prev3a.yrl", 730).
yeccpars2_356_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_357_/1}).
-file("megaco_text_parser_prev3a.yrl", 758).
yeccpars2_357_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_359_/1}).
-file("megaco_text_parser_prev3a.yrl", 763).
yeccpars2_359_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_365_/1}).
-file("megaco_text_parser_prev3a.yrl", 762).
yeccpars2_365_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_366_/1}).
-file("megaco_text_parser_prev3a.yrl", 669).
yeccpars2_366_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_373_/1}).
-file("megaco_text_parser_prev3a.yrl", 1346).
yeccpars2_373_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { time_stamp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_374_/1}).
-file("megaco_text_parser_prev3a.yrl", 1348).
yeccpars2_374_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { version , __1 }
  end | __Stack].

-compile({inline,yeccpars2_375_/1}).
-file("megaco_text_parser_prev3a.yrl", 1341).
yeccpars2_375_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { reason , __1 }
  end | __Stack].

-compile({inline,yeccpars2_376_/1}).
-file("megaco_text_parser_prev3a.yrl", 1344).
yeccpars2_376_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { profile , __1 }
  end | __Stack].

-compile({inline,yeccpars2_377_/1}).
-file("megaco_text_parser_prev3a.yrl", 1338).
yeccpars2_377_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_378_/1}).
-file("megaco_text_parser_prev3a.yrl", 1347).
yeccpars2_378_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mgc_id , __1 }
  end | __Stack].

-compile({inline,yeccpars2_379_/1}).
-file("megaco_text_parser_prev3a.yrl", 1340).
yeccpars2_379_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { method , __1 }
  end | __Stack].

-compile({inline,yeccpars2_380_/1}).
-file("megaco_text_parser_prev3a.yrl", 1342).
yeccpars2_380_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { delay , __1 }
  end | __Stack].

-compile({inline,yeccpars2_381_/1}).
-file("megaco_text_parser_prev3a.yrl", 1343).
yeccpars2_381_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { address , __1 }
  end | __Stack].

-compile({inline,yeccpars2_382_/1}).
-file("megaco_text_parser_prev3a.yrl", 1440).
yeccpars2_382_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_extensionParameter ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_384_/1}).
-file("megaco_text_parser_prev3a.yrl", 1345).
yeccpars2_384_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { extension , __1 }
  end | __Stack].

-compile({inline,yeccpars2_385_/1}).
-file("megaco_text_parser_prev3a.yrl", 1350).
yeccpars2_385_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { audit_item , __1 }
  end | __Stack].

-compile({inline,yeccpars2_392_/1}).
-file("megaco_text_parser_prev3a.yrl", 1349).
yeccpars2_392_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   incomplete
  end | __Stack].

-compile({inline,yeccpars2_393_/1}).
-file("megaco_text_parser_prev3a.yrl", 1398).
yeccpars2_393_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_timeStamp ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_396_/1}).
-file("megaco_text_parser_prev3a.yrl", 1367).
yeccpars2_396_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_version ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_397_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_397_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_398_/1}).
-file("megaco_text_parser_prev3a.yrl", 1361).
yeccpars2_398_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { portNumber , __3 }
  end | __Stack].

-compile({inline,yeccpars2_399_/1}).
-file("megaco_text_parser_prev3a.yrl", 1359).
yeccpars2_399_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_401_/1}).
-file("megaco_text_parser_prev3a.yrl", 1355).
yeccpars2_401_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 ]
  end | __Stack].

-compile({inline,yeccpars2_403_/1}).
-file("megaco_text_parser_prev3a.yrl", 1365).
yeccpars2_403_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_profile ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_404_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_404_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_405_/1}).
-file("megaco_text_parser_prev3a.yrl", 1363).
yeccpars2_405_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_407_/1}).
-file("megaco_text_parser_prev3a.yrl", 1353).
yeccpars2_407_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_serviceChangeMethod ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_409_/1}).
-file("megaco_text_parser_prev3a.yrl", 1357).
yeccpars2_409_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_uint32 ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_410_/1}).
-file("megaco_text_parser_prev3a.yrl", 1370).
yeccpars2_410_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'PropertyParm' .name , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_413_/1}).
-file("megaco_text_parser_prev3a.yrl", 1338).
yeccpars2_413_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_414_/1}).
-file("megaco_text_parser_prev3a.yrl", 1337).
yeccpars2_414_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_415_/1}).
-file("megaco_text_parser_prev3a.yrl", 1334).
yeccpars2_415_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_ServiceChangeParm ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_416_/1}).
-file("megaco_text_parser_prev3a.yrl", 907).
yeccpars2_416_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { serviceChangeReq , __1 } ,
    # 'ServiceChangeRequest' { terminationID = [ __3 ] ,
    serviceChangeParms = __5 } )
  end | __Stack].

-compile({inline,yeccpars2_420_/1}).
-file("megaco_text_parser_prev3a.yrl", 893).
yeccpars2_420_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'NotifyRequest' { observedEventsDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_422_/1}).
-file("megaco_text_parser_prev3a.yrl", 895).
yeccpars2_422_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'NotifyRequest' { errorDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_426_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_426_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_427_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_427_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_429_/1}).
-file("megaco_text_parser_prev3a.yrl", 1285).
yeccpars2_429_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_431_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_431_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_432_/1}).
-file("megaco_text_parser_prev3a.yrl", 1285).
yeccpars2_432_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_433_/1}).
-file("megaco_text_parser_prev3a.yrl", 1284).
yeccpars2_433_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_434_/1}).
-file("megaco_text_parser_prev3a.yrl", 1281).
yeccpars2_434_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'ObservedEventsDescriptor' { requestId = __3 ,
    observedEventLst = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_435_/1}).
-file("megaco_text_parser_prev3a.yrl", 1297).
yeccpars2_435_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_436_/1}).
-file("megaco_text_parser_prev3a.yrl", 1292).
yeccpars2_436_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_observed_event ( __3 , __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_438_/1}).
-file("megaco_text_parser_prev3a.yrl", 1300).
yeccpars2_438_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_441_/1}).
-file("megaco_text_parser_prev3a.yrl", 1186).
yeccpars2_441_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   select_stream_or_other ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_444_/1}).
-file("megaco_text_parser_prev3a.yrl", 1300).
yeccpars2_444_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_445_/1}).
-file("megaco_text_parser_prev3a.yrl", 1299).
yeccpars2_445_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_446_/1}).
-file("megaco_text_parser_prev3a.yrl", 1296).
yeccpars2_446_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_448_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_448_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_450_/1}).
-file("megaco_text_parser_prev3a.yrl", 1297).
yeccpars2_450_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_451_/1}).
-file("megaco_text_parser_prev3a.yrl", 1290).
yeccpars2_451_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_observed_event ( __6 , __5 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_452_/1}).
-file("megaco_text_parser_prev3a.yrl", 889).
yeccpars2_452_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { notifyReq , __1 } ,
    setelement ( # 'NotifyRequest' .terminationID , __5 , [ __3 ] ) )
  end | __Stack].

-compile({inline,yeccpars2_457_/1}).
-file("megaco_text_parser_prev3a.yrl", 572).
yeccpars2_457_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_458_/1}).
-file("megaco_text_parser_prev3a.yrl", 565).
yeccpars2_458_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_459_/1}).
-file("megaco_text_parser_prev3a.yrl", 569).
yeccpars2_459_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   emergencyAudit
  end | __Stack].

-compile({inline,yeccpars2_460_/1}).
-file("megaco_text_parser_prev3a.yrl", 571).
yeccpars2_460_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   iepsCallind
  end | __Stack].

-compile({inline,yeccpars2_461_/1}).
-file("megaco_text_parser_prev3a.yrl", 570).
yeccpars2_461_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   priorityAudit
  end | __Stack].

-compile({inline,yeccpars2_462_/1}).
-file("megaco_text_parser_prev3a.yrl", 568).
yeccpars2_462_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   topologyAudit
  end | __Stack].

-compile({inline,yeccpars2_465_/1}).
-file("megaco_text_parser_prev3a.yrl", 565).
yeccpars2_465_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_466_/1}).
-file("megaco_text_parser_prev3a.yrl", 564).
yeccpars2_466_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_467_/1}).
-file("megaco_text_parser_prev3a.yrl", 561).
yeccpars2_467_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_468_/1}).
-file("megaco_text_parser_prev3a.yrl", 555).
yeccpars2_468_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_context_attr_audit_request (
    # 'ContextAttrAuditRequest' { } , __3 )
  end | __Stack].

-compile({inline,yeccpars2_470_/1}).
-file("megaco_text_parser_prev3a.yrl", 547).
yeccpars2_470_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { topology , __1 }
  end | __Stack].

-compile({inline,yeccpars2_471_/1}).
-file("megaco_text_parser_prev3a.yrl", 552).
yeccpars2_471_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_472_/1}).
-file("megaco_text_parser_prev3a.yrl", 548).
yeccpars2_472_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { priority , __1 }
  end | __Stack].

-compile({inline,yeccpars2_475_/1}).
-file("megaco_text_parser_prev3a.yrl", 544).
yeccpars2_475_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_476_/1}).
-file("megaco_text_parser_prev3a.yrl", 550).
yeccpars2_476_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { emergency , false }
  end | __Stack].

-compile({inline,yeccpars2_477_/1}).
-file("megaco_text_parser_prev3a.yrl", 549).
yeccpars2_477_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { emergency , true }
  end | __Stack].

-compile({inline,yeccpars2_478_/1}).
-file("megaco_text_parser_prev3a.yrl", 551).
yeccpars2_478_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { iepsCallind , true }
  end | __Stack].

-compile({inline,yeccpars2_482_/1}).
-file("megaco_text_parser_prev3a.yrl", 1430).
yeccpars2_482_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_489_/1}).
-file("megaco_text_parser_prev3a.yrl", 1426).
yeccpars2_489_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TopologyRequest' { terminationFrom = __1 ,
    terminationTo = __3 ,
    topologyDirection = __5 }
  end | __Stack].

-compile({inline,yeccpars2_490_/1}).
-file("megaco_text_parser_prev3a.yrl", 1434).
yeccpars2_490_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   bothway
  end | __Stack].

-compile({inline,yeccpars2_491_/1}).
-file("megaco_text_parser_prev3a.yrl", 1435).
yeccpars2_491_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   isolate
  end | __Stack].

-compile({inline,yeccpars2_492_/1}).
-file("megaco_text_parser_prev3a.yrl", 1436).
yeccpars2_492_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   oneway
  end | __Stack].

-compile({inline,yeccpars2_495_/1}).
-file("megaco_text_parser_prev3a.yrl", 1430).
yeccpars2_495_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_496_/1}).
-file("megaco_text_parser_prev3a.yrl", 1432).
yeccpars2_496_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_497_/1}).
-file("megaco_text_parser_prev3a.yrl", 1417).
yeccpars2_497_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_499_/1}).
-file("megaco_text_parser_prev3a.yrl", 1438).
yeccpars2_499_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_502_/1}).
-file("megaco_text_parser_prev3a.yrl", 544).
yeccpars2_502_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_503_/1}).
-file("megaco_text_parser_prev3a.yrl", 543).
yeccpars2_503_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_504_/1}).
-file("megaco_text_parser_prev3a.yrl", 538).
yeccpars2_504_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_505_/1}).
-file("megaco_text_parser_prev3a.yrl", 1042).
yeccpars2_505_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'PropertyParm' .name , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_507_/1}).
-file("megaco_text_parser_prev3a.yrl", 670).
yeccpars2_507_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_508_/1}).
-file("megaco_text_parser_prev3a.yrl", 674).
yeccpars2_508_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { auditValueRequest , __1 } ,
    # 'AuditRequest' { terminationID = __3 ,
    auditDescriptor = __4 } )
  end | __Stack].

-compile({inline,yeccpars2_510_/1}).
-file("megaco_text_parser_prev3a.yrl", 670).
yeccpars2_510_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_511_/1}).
-file("megaco_text_parser_prev3a.yrl", 679).
yeccpars2_511_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { auditCapRequest , __1 } ,
    # 'AuditRequest' { terminationID = __3 ,
    auditDescriptor = __4 } )
  end | __Stack].

-compile({inline,yeccpars2_512_/1}).
-file("megaco_text_parser_prev3a.yrl", 520).
yeccpars2_512_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_action_request ( __3 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_513_/1}).
-file("megaco_text_parser_prev3a.yrl", 522).
yeccpars2_513_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_515_/1}).
-file("megaco_text_parser_prev3a.yrl", 526).
yeccpars2_515_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_516_/1}).
-file("megaco_text_parser_prev3a.yrl", 525).
yeccpars2_516_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_518_/1}).
-file("megaco_text_parser_prev3a.yrl", 634).
yeccpars2_518_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_519_/1}).
-file("megaco_text_parser_prev3a.yrl", 624).
yeccpars2_519_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Descs = merge_AmmRequest_descriptors ( __4 , [ ] ) ,
    make_commandRequest ( __1 ,
    # 'AmmRequest' { terminationID = [ __3 ] ,
    descriptors = Descs } )
  end | __Stack].

-compile({inline,yeccpars2_521_/1}).
-file("megaco_text_parser_prev3a.yrl", 648).
yeccpars2_521_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_522_/1}).
-file("megaco_text_parser_prev3a.yrl", 645).
yeccpars2_522_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_523_/1}).
-file("megaco_text_parser_prev3a.yrl", 642).
yeccpars2_523_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { muxDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_524_/1}).
-file("megaco_text_parser_prev3a.yrl", 641).
yeccpars2_524_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { modemDescriptor , deprecated }
  end | __Stack].

-compile({inline,yeccpars2_525_/1}).
-file("megaco_text_parser_prev3a.yrl", 640).
yeccpars2_525_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_526_/1}).
-file("megaco_text_parser_prev3a.yrl", 643).
yeccpars2_526_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_527_/1}).
-file("megaco_text_parser_prev3a.yrl", 644).
yeccpars2_527_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_528_/1}).
-file("megaco_text_parser_prev3a.yrl", 646).
yeccpars2_528_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { digitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_529_/1}).
-file("megaco_text_parser_prev3a.yrl", 647).
yeccpars2_529_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_530_/1}).
-file("megaco_text_parser_prev3a.yrl", 637).
yeccpars2_530_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_531_/1}).
-file("megaco_text_parser_prev3a.yrl", 1326).
yeccpars2_531_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_DMD ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_532_/1}).
-file("megaco_text_parser_prev3a.yrl", 1081).
yeccpars2_532_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_533_/1}).
-file("megaco_text_parser_prev3a.yrl", 1117).
yeccpars2_533_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'EventsDescriptor' { requestID = asn1_NOVALUE ,
    eventList = [ ] }
  end | __Stack].

-compile({inline,yeccpars2_537_/1}).
-file("megaco_text_parser_prev3a.yrl", 1197).
yeccpars2_537_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_540_/1}).
-file("megaco_text_parser_prev3a.yrl", 1406).
yeccpars2_540_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_541_/1}).
-file("megaco_text_parser_prev3a.yrl", 1410).
yeccpars2_541_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'StatisticsParameter' { statName = __1 ,
    statValue = asn1_NOVALUE }
  end | __Stack].

-compile({inline,yeccpars2_543_/1}).
-file("megaco_text_parser_prev3a.yrl", 1413).
yeccpars2_543_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'StatisticsParameter' { statName = __1 ,
    statValue = [ __3 ] }
  end | __Stack].

-compile({inline,yeccpars2_546_/1}).
-file("megaco_text_parser_prev3a.yrl", 1406).
yeccpars2_546_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_547_/1}).
-file("megaco_text_parser_prev3a.yrl", 1405).
yeccpars2_547_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_548_/1}).
-file("megaco_text_parser_prev3a.yrl", 1403).
yeccpars2_548_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_550_/1}).
-file("megaco_text_parser_prev3a.yrl", 1203).
yeccpars2_550_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signal , __1 }
  end | __Stack].

-compile({inline,yeccpars2_551_/1}).
-file("megaco_text_parser_prev3a.yrl", 1200).
yeccpars2_551_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_552_/1}).
-file("megaco_text_parser_prev3a.yrl", 1202).
yeccpars2_552_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { seqSigList , __1 }
  end | __Stack].

-compile({inline,yeccpars2_557_/1}).
-file("megaco_text_parser_prev3a.yrl", 1269).
yeccpars2_557_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_560_/1}).
-file("megaco_text_parser_prev3a.yrl", 1269).
yeccpars2_560_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_561_/1}).
-file("megaco_text_parser_prev3a.yrl", 1268).
yeccpars2_561_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_562_/1}).
-file("megaco_text_parser_prev3a.yrl", 1264).
yeccpars2_562_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'SeqSigList' { id = ensure_uint16 ( __3 ) ,
    signalList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_565_/1}).
-file("megaco_text_parser_prev3a.yrl", 1200).
yeccpars2_565_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_566_/1}).
-file("megaco_text_parser_prev3a.yrl", 1199).
yeccpars2_566_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_567_/1}).
-file("megaco_text_parser_prev3a.yrl", 1196).
yeccpars2_567_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_569_/1}).
-file("megaco_text_parser_prev3a.yrl", 1110).
yeccpars2_569_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_muxType ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_571_/1}).
-file("megaco_text_parser_prev3a.yrl", 1107).
yeccpars2_571_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'MuxDescriptor' { muxType = __3 ,
    termList = __4 }
  end | __Stack].

-compile({inline,yeccpars2_573_/1}).
-file("megaco_text_parser_prev3a.yrl", 969).
yeccpars2_573_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_576_/1}).
-file("megaco_text_parser_prev3a.yrl", 969).
yeccpars2_576_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_577_/1}).
-file("megaco_text_parser_prev3a.yrl", 968).
yeccpars2_577_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_578_/1}).
-file("megaco_text_parser_prev3a.yrl", 965).
yeccpars2_578_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_581_/1}).
-file("megaco_text_parser_prev3a.yrl", 0).
yeccpars2_581_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_582_/1}).
-file("megaco_text_parser_prev3a.yrl", 0).
yeccpars2_582_(__Stack0) ->
 [begin
   '$undefined'
  end | __Stack0].

-compile({inline,yeccpars2_585_/1}).
-file("megaco_text_parser_prev3a.yrl", 0).
yeccpars2_585_(__Stack0) ->
 [begin
   '$undefined'
  end | __Stack0].

-compile({inline,yeccpars2_586_/1}).
-file("megaco_text_parser_prev3a.yrl", 0).
yeccpars2_586_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_587_/1}).
-file("megaco_text_parser_prev3a.yrl", 1317).
yeccpars2_587_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_588_/1}).
-file("megaco_text_parser_prev3a.yrl", 0).
yeccpars2_588_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_590_/1}).
-file("megaco_text_parser_prev3a.yrl", 1320).
yeccpars2_590_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_593_/1}).
-file("megaco_text_parser_prev3a.yrl", 1320).
yeccpars2_593_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_594_/1}).
-file("megaco_text_parser_prev3a.yrl", 1319).
yeccpars2_594_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_595_/1}).
-file("megaco_text_parser_prev3a.yrl", 1316).
yeccpars2_595_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_596_/1}).
-file("megaco_text_parser_prev3a.yrl", 1317).
yeccpars2_596_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_597_/1}).
-file("megaco_text_parser_prev3a.yrl", 0).
yeccpars2_597_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_599_/1}).
-file("megaco_text_parser_prev3a.yrl", 990).
yeccpars2_599_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { termState , __1 }
  end | __Stack].

-compile({inline,yeccpars2_600_/1}).
-file("megaco_text_parser_prev3a.yrl", 986).
yeccpars2_600_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_601_/1}).
-file("megaco_text_parser_prev3a.yrl", 988).
yeccpars2_601_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_602_/1}).
-file("megaco_text_parser_prev3a.yrl", 1001).
yeccpars2_602_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statistics , __1 }
  end | __Stack].

-compile({inline,yeccpars2_603_/1}).
-file("megaco_text_parser_prev3a.yrl", 980).
yeccpars2_603_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_604_/1}).
-file("megaco_text_parser_prev3a.yrl", 1000).
yeccpars2_604_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { control , __1 }
  end | __Stack].

-compile({inline,yeccpars2_606_/1}).
-file("megaco_text_parser_prev3a.yrl", 995).
yeccpars2_606_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   PGs = ensure_prop_groups ( __1 ) ,
    { local , # 'LocalRemoteDescriptor' { propGrps = PGs } }
  end | __Stack].

-compile({inline,yeccpars2_607_/1}).
-file("megaco_text_parser_prev3a.yrl", 998).
yeccpars2_607_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   PGs = ensure_prop_groups ( __1 ) ,
    { remote , # 'LocalRemoteDescriptor' { propGrps = PGs } }
  end | __Stack].

-compile({inline,yeccpars2_611_/1}).
-file("megaco_text_parser_prev3a.yrl", 1023).
yeccpars2_611_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_612_/1}).
-file("megaco_text_parser_prev3a.yrl", 1091).
yeccpars2_612_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { serviceState , __1 }
  end | __Stack].

-compile({inline,yeccpars2_613_/1}).
-file("megaco_text_parser_prev3a.yrl", 1093).
yeccpars2_613_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { propertyParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_614_/1}).
-file("megaco_text_parser_prev3a.yrl", 1092).
yeccpars2_614_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferControl , __1 }
  end | __Stack].

-compile({inline,yeccpars2_618_/1}).
-file("megaco_text_parser_prev3a.yrl", 1095).
yeccpars2_618_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_619_/1}).
-file("megaco_text_parser_prev3a.yrl", 1099).
yeccpars2_619_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   inSvc
  end | __Stack].

-compile({inline,yeccpars2_620_/1}).
-file("megaco_text_parser_prev3a.yrl", 1098).
yeccpars2_620_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   outOfSvc
  end | __Stack].

-compile({inline,yeccpars2_621_/1}).
-file("megaco_text_parser_prev3a.yrl", 1097).
yeccpars2_621_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   test
  end | __Stack].

-compile({inline,yeccpars2_623_/1}).
-file("megaco_text_parser_prev3a.yrl", 1101).
yeccpars2_623_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_624_/1}).
-file("megaco_text_parser_prev3a.yrl", 1104).
yeccpars2_624_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lockStep
  end | __Stack].

-compile({inline,yeccpars2_625_/1}).
-file("megaco_text_parser_prev3a.yrl", 1103).
yeccpars2_625_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   off
  end | __Stack].

-compile({inline,yeccpars2_628_/1}).
-file("megaco_text_parser_prev3a.yrl", 1023).
yeccpars2_628_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_629_/1}).
-file("megaco_text_parser_prev3a.yrl", 1022).
yeccpars2_629_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_630_/1}).
-file("megaco_text_parser_prev3a.yrl", 1020).
yeccpars2_630_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_terminationStateDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_634_/1}).
-file("megaco_text_parser_prev3a.yrl", 1009).
yeccpars2_634_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_637_/1}).
-file("megaco_text_parser_prev3a.yrl", 1009).
yeccpars2_637_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_638_/1}).
-file("megaco_text_parser_prev3a.yrl", 1008).
yeccpars2_638_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_639_/1}).
-file("megaco_text_parser_prev3a.yrl", 1005).
yeccpars2_639_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'StreamDescriptor' { streamID = __3 ,
    streamParms = merge_streamParms ( [ __5 | __6 ] ) }
  end | __Stack].

-compile({inline,yeccpars2_641_/1}).
-file("megaco_text_parser_prev3a.yrl", 1029).
yeccpars2_641_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_642_/1}).
-file("megaco_text_parser_prev3a.yrl", 1015).
yeccpars2_642_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_647_/1}).
-file("megaco_text_parser_prev3a.yrl", 1027).
yeccpars2_647_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { value , __3 }
  end | __Stack].

-compile({inline,yeccpars2_648_/1}).
-file("megaco_text_parser_prev3a.yrl", 1032).
yeccpars2_648_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   false
  end | __Stack].

-compile({inline,yeccpars2_649_/1}).
-file("megaco_text_parser_prev3a.yrl", 1031).
yeccpars2_649_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   true
  end | __Stack].

-compile({inline,yeccpars2_651_/1}).
-file("megaco_text_parser_prev3a.yrl", 1026).
yeccpars2_651_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { group , __3 }
  end | __Stack].

-compile({inline,yeccpars2_653_/1}).
-file("megaco_text_parser_prev3a.yrl", 1028).
yeccpars2_653_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { mode , __3 }
  end | __Stack].

-compile({inline,yeccpars2_654_/1}).
-file("megaco_text_parser_prev3a.yrl", 1038).
yeccpars2_654_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   inactive
  end | __Stack].

-compile({inline,yeccpars2_655_/1}).
-file("megaco_text_parser_prev3a.yrl", 1039).
yeccpars2_655_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   loopBack
  end | __Stack].

-compile({inline,yeccpars2_656_/1}).
-file("megaco_text_parser_prev3a.yrl", 1036).
yeccpars2_656_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   recvOnly
  end | __Stack].

-compile({inline,yeccpars2_657_/1}).
-file("megaco_text_parser_prev3a.yrl", 1035).
yeccpars2_657_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sendOnly
  end | __Stack].

-compile({inline,yeccpars2_658_/1}).
-file("megaco_text_parser_prev3a.yrl", 1037).
yeccpars2_658_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sendRecv
  end | __Stack].

-compile({inline,yeccpars2_661_/1}).
-file("megaco_text_parser_prev3a.yrl", 1015).
yeccpars2_661_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_662_/1}).
-file("megaco_text_parser_prev3a.yrl", 1014).
yeccpars2_662_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_663_/1}).
-file("megaco_text_parser_prev3a.yrl", 1012).
yeccpars2_663_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_666_/1}).
-file("megaco_text_parser_prev3a.yrl", 980).
yeccpars2_666_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_667_/1}).
-file("megaco_text_parser_prev3a.yrl", 979).
yeccpars2_667_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_668_/1}).
-file("megaco_text_parser_prev3a.yrl", 977).
yeccpars2_668_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_mediaDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_672_/1}).
-file("megaco_text_parser_prev3a.yrl", 1125).
yeccpars2_672_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_673_/1}).
-file("megaco_text_parser_prev3a.yrl", 1132).
yeccpars2_673_(__Stack0) ->
 [begin
   # 'RequestedEvent' { evParList = [ ] }
  end | __Stack0].

-compile({inline,yeccpars2_674_/1}).
-file("megaco_text_parser_prev3a.yrl", 1128).
yeccpars2_674_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'RequestedEvent' .pkgdName , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_677_/1}).
-file("megaco_text_parser_prev3a.yrl", 1136).
yeccpars2_677_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_681_/1}).
-file("megaco_text_parser_prev3a.yrl", 1192).
yeccpars2_681_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_eventDM ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_683_COMMA/1}).
-file("megaco_text_parser_prev3a.yrl", 1139).
yeccpars2_683_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_683_RBRKT/1}).
-file("megaco_text_parser_prev3a.yrl", 1139).
yeccpars2_683_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_687_/1}).
-file("megaco_text_parser_prev3a.yrl", 1155).
yeccpars2_687_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'SecondEventsDescriptor' { requestID = asn1_NOVALUE ,
    eventList = [ ] }
  end | __Stack].

-compile({inline,yeccpars2_691_/1}).
-file("megaco_text_parser_prev3a.yrl", 1163).
yeccpars2_691_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_692_/1}).
-file("megaco_text_parser_prev3a.yrl", 1171).
yeccpars2_692_(__Stack0) ->
 [begin
   # 'SecondRequestedEvent' { evParList = [ ] }
  end | __Stack0].

-compile({inline,yeccpars2_693_/1}).
-file("megaco_text_parser_prev3a.yrl", 1167).
yeccpars2_693_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'SecondRequestedEvent' .pkgdName , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_695_/1}).
-file("megaco_text_parser_prev3a.yrl", 1174).
yeccpars2_695_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_700_COMMA/1}).
-file("megaco_text_parser_prev3a.yrl", 1177).
yeccpars2_700_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_700_RBRKT/1}).
-file("megaco_text_parser_prev3a.yrl", 1177).
yeccpars2_700_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_703_/1}).
-file("megaco_text_parser_prev3a.yrl", 1183).
yeccpars2_703_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { second_embed , __3 }
  end | __Stack].

-compile({inline,yeccpars2_706_/1}).
-file("megaco_text_parser_prev3a.yrl", 1174).
yeccpars2_706_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_707_/1}).
-file("megaco_text_parser_prev3a.yrl", 1173).
yeccpars2_707_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_708_/1}).
-file("megaco_text_parser_prev3a.yrl", 1170).
yeccpars2_708_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_secondEventParameters ( [ __2 | __3 ] )
  end | __Stack].

-compile({inline,yeccpars2_711_/1}).
-file("megaco_text_parser_prev3a.yrl", 1163).
yeccpars2_711_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_712_/1}).
-file("megaco_text_parser_prev3a.yrl", 1162).
yeccpars2_712_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_713_/1}).
-file("megaco_text_parser_prev3a.yrl", 1159).
yeccpars2_713_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'SecondEventsDescriptor' { requestID = __3 ,
    eventList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_714_/1}).
-file("megaco_text_parser_prev3a.yrl", 1152).
yeccpars2_714_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , asn1_NOVALUE , __3 }
  end | __Stack].

-compile({inline,yeccpars2_716_/1}).
-file("megaco_text_parser_prev3a.yrl", 1149).
yeccpars2_716_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , __3 , asn1_NOVALUE }
  end | __Stack].

-compile({inline,yeccpars2_718_/1}).
-file("megaco_text_parser_prev3a.yrl", 1147).
yeccpars2_718_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , __3 , __5 }
  end | __Stack].

-compile({inline,yeccpars2_721_/1}).
-file("megaco_text_parser_prev3a.yrl", 1136).
yeccpars2_721_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_722_/1}).
-file("megaco_text_parser_prev3a.yrl", 1135).
yeccpars2_722_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_723_/1}).
-file("megaco_text_parser_prev3a.yrl", 1131).
yeccpars2_723_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_eventParameters ( [ __2 | __3 ] )
  end | __Stack].

-compile({inline,yeccpars2_726_/1}).
-file("megaco_text_parser_prev3a.yrl", 1125).
yeccpars2_726_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_727_/1}).
-file("megaco_text_parser_prev3a.yrl", 1124).
yeccpars2_727_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_728_/1}).
-file("megaco_text_parser_prev3a.yrl", 1121).
yeccpars2_728_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'EventsDescriptor' { requestID = __3 ,
    eventList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_729_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_729_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_730_/1}).
-file("megaco_text_parser_prev3a.yrl", 1088).
yeccpars2_730_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_eventSpec ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_731_/1}).
-file("megaco_text_parser_prev3a.yrl", 1086).
yeccpars2_731_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_733_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_733_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_734_/1}).
-file("megaco_text_parser_prev3a.yrl", 1086).
yeccpars2_734_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_735_/1}).
-file("megaco_text_parser_prev3a.yrl", 1085).
yeccpars2_735_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_736_/1}).
-file("megaco_text_parser_prev3a.yrl", 1083).
yeccpars2_736_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_739_/1}).
-file("megaco_text_parser_prev3a.yrl", 637).
yeccpars2_739_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_740_/1}).
-file("megaco_text_parser_prev3a.yrl", 636).
yeccpars2_740_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_741_/1}).
-file("megaco_text_parser_prev3a.yrl", 633).
yeccpars2_741_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_744_/1}).
-file("megaco_text_parser_prev3a.yrl", 516).
yeccpars2_744_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_745_/1}).
-file("megaco_text_parser_prev3a.yrl", 515).
yeccpars2_745_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_746_/1}).
-file("megaco_text_parser_prev3a.yrl", 504).
yeccpars2_746_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = asn1_NOVALUE ,
    actions = [ __3 | __4 ] }
  end | __Stack].

-compile({inline,yeccpars2_748_/1}).
-file("megaco_text_parser_prev3a.yrl", 931).
yeccpars2_748_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint32 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_750_/1}).
-file("megaco_text_parser_prev3a.yrl", 516).
yeccpars2_750_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_752_/1}).
-file("megaco_text_parser_prev3a.yrl", 508).
yeccpars2_752_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = asn1_NOVALUE ,
    actions = [ __4 | __5 ] }
  end | __Stack].

-compile({inline,yeccpars2_754_/1}).
-file("megaco_text_parser_prev3a.yrl", 516).
yeccpars2_754_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_756_/1}).
-file("megaco_text_parser_prev3a.yrl", 512).
yeccpars2_756_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = ensure_transactionID ( __3 ) ,
    actions = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_758_/1}).
-file("megaco_text_parser_prev3a.yrl", 495).
yeccpars2_758_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_759_/1}).
-file("megaco_text_parser_prev3a.yrl", 497).
yeccpars2_759_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_transactionAck ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_762_/1}).
-file("megaco_text_parser_prev3a.yrl", 495).
yeccpars2_762_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_763_/1}).
-file("megaco_text_parser_prev3a.yrl", 494).
yeccpars2_763_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_764_/1}).
-file("megaco_text_parser_prev3a.yrl", 492).
yeccpars2_764_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_767_/1}).
-file("megaco_text_parser_prev3a.yrl", 589).
yeccpars2_767_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_770_/1}).
-file("megaco_text_parser_prev3a.yrl", 588).
yeccpars2_770_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   'NULL'
  end | __Stack].

-compile({inline,yeccpars2_772_/1}).
-file("megaco_text_parser_prev3a.yrl", 591).
yeccpars2_772_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionError , __1 }
  end | __Stack].

-compile({inline,yeccpars2_773_/1}).
-file("megaco_text_parser_prev3a.yrl", 595).
yeccpars2_773_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_778_/1}).
-file("megaco_text_parser_prev3a.yrl", 616).
yeccpars2_778_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_779_/1}).
-file("megaco_text_parser_prev3a.yrl", 619).
yeccpars2_779_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_780_/1}).
-file("megaco_text_parser_prev3a.yrl", 602).
yeccpars2_780_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'ActionReply' { errorDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_781_/1}).
-file("megaco_text_parser_prev3a.yrl", 620).
yeccpars2_781_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { context , __1 }
  end | __Stack].

-compile({inline,yeccpars2_782_/1}).
-file("megaco_text_parser_prev3a.yrl", 614).
yeccpars2_782_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_783_/1}).
-file("megaco_text_parser_prev3a.yrl", 617).
yeccpars2_783_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_785_/1}).
-file("megaco_text_parser_prev3a.yrl", 618).
yeccpars2_785_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_787_/1}).
-file("megaco_text_parser_prev3a.yrl", 654).
yeccpars2_787_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   addReply
  end | __Stack].

-compile({inline,yeccpars2_790_/1}).
-file("megaco_text_parser_prev3a.yrl", 656).
yeccpars2_790_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modReply
  end | __Stack].

-compile({inline,yeccpars2_791_/1}).
-file("megaco_text_parser_prev3a.yrl", 655).
yeccpars2_791_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   moveReply
  end | __Stack].

-compile({inline,yeccpars2_794_/1}).
-file("megaco_text_parser_prev3a.yrl", 657).
yeccpars2_794_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   subtractReply
  end | __Stack].

-compile({inline,yeccpars2_796_/1}).
-file("megaco_text_parser_prev3a.yrl", 920).
yeccpars2_796_(__Stack0) ->
 [begin
   { serviceChangeResParms , # 'ServiceChangeResParm' { } }
  end | __Stack0].

-compile({inline,yeccpars2_797_/1}).
-file("megaco_text_parser_prev3a.yrl", 912).
yeccpars2_797_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceChangeReply ,
    # 'ServiceChangeReply' { terminationID = [ __3 ] ,
    serviceChangeResult = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_803_/1}).
-file("megaco_text_parser_prev3a.yrl", 1387).
yeccpars2_803_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { time_stamp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_804_/1}).
-file("megaco_text_parser_prev3a.yrl", 1386).
yeccpars2_804_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { version , __1 }
  end | __Stack].

-compile({inline,yeccpars2_805_/1}).
-file("megaco_text_parser_prev3a.yrl", 1385).
yeccpars2_805_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { profile , __1 }
  end | __Stack].

-compile({inline,yeccpars2_806_/1}).
-file("megaco_text_parser_prev3a.yrl", 1384).
yeccpars2_806_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mgc_id , __1 }
  end | __Stack].

-compile({inline,yeccpars2_807_/1}).
-file("megaco_text_parser_prev3a.yrl", 1383).
yeccpars2_807_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { address , __1 }
  end | __Stack].

-compile({inline,yeccpars2_808_/1}).
-file("megaco_text_parser_prev3a.yrl", 1381).
yeccpars2_808_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_815_/1}).
-file("megaco_text_parser_prev3a.yrl", 1381).
yeccpars2_815_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_816_/1}).
-file("megaco_text_parser_prev3a.yrl", 1380).
yeccpars2_816_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_817_/1}).
-file("megaco_text_parser_prev3a.yrl", 1377).
yeccpars2_817_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_ServiceChangeResParm ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_818_/1}).
-file("megaco_text_parser_prev3a.yrl", 917).
yeccpars2_818_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { errorDescriptor , __2 }
  end | __Stack].

-compile({inline,yeccpars2_819_/1}).
-file("megaco_text_parser_prev3a.yrl", 919).
yeccpars2_819_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceChangeResParms , __2 }
  end | __Stack].

-compile({inline,yeccpars2_821_/1}).
-file("megaco_text_parser_prev3a.yrl", 903).
yeccpars2_821_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_822_/1}).
-file("megaco_text_parser_prev3a.yrl", 898).
yeccpars2_822_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { notifyReply ,
    # 'NotifyReply' { terminationID = [ __3 ] ,
    errorDescriptor = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_825_/1}).
-file("megaco_text_parser_prev3a.yrl", 902).
yeccpars2_825_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_827_/1}).
-file("megaco_text_parser_prev3a.yrl", 696).
yeccpars2_827_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditResult ,
    # 'AuditResult' { terminationID = __1 ,
    terminationAuditResult = [ ] } }
  end | __Stack].

-compile({inline,yeccpars2_828_/1}).
-file("megaco_text_parser_prev3a.yrl", 688).
yeccpars2_828_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditValueReply , __3 }
  end | __Stack].

-compile({inline,yeccpars2_830_/1}).
-file("megaco_text_parser_prev3a.yrl", 692).
yeccpars2_830_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextAuditResult , __1 }
  end | __Stack].

-compile({inline,yeccpars2_831_/1}).
-file("megaco_text_parser_prev3a.yrl", 684).
yeccpars2_831_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditValueReply , __4 }
  end | __Stack].

-compile({inline,yeccpars2_836_/1}).
-file("megaco_text_parser_prev3a.yrl", 926).
yeccpars2_836_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint ( __1 , 0 , 999 )
  end | __Stack].

-compile({inline,yeccpars2_838_/1}).
-file("megaco_text_parser_prev3a.yrl", 929).
yeccpars2_838_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_840_/1}).
-file("megaco_text_parser_prev3a.yrl", 928).
yeccpars2_840_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   value_of ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_841_/1}).
-file("megaco_text_parser_prev3a.yrl", 923).
yeccpars2_841_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'ErrorDescriptor' { errorCode = __3 ,
    errorText = __5 }
  end | __Stack].

-compile({inline,yeccpars2_842_/1}).
-file("megaco_text_parser_prev3a.yrl", 693).
yeccpars2_842_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { contextAuditResult , __2 }
  end | __Stack].

-compile({inline,yeccpars2_845_/1}).
-file("megaco_text_parser_prev3a.yrl", 719).
yeccpars2_845_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_846_/1}).
-file("megaco_text_parser_prev3a.yrl", 715).
yeccpars2_846_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_847_/1}).
-file("megaco_text_parser_prev3a.yrl", 720).
yeccpars2_847_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { packagesDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_848_/1}).
-file("megaco_text_parser_prev3a.yrl", 717).
yeccpars2_848_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { observedEventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_849_/1}).
-file("megaco_text_parser_prev3a.yrl", 713).
yeccpars2_849_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { muxDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_850_/1}).
-file("megaco_text_parser_prev3a.yrl", 0).
yeccpars2_850_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_851_/1}).
-file("megaco_text_parser_prev3a.yrl", 711).
yeccpars2_851_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_852_/1}).
-file("megaco_text_parser_prev3a.yrl", 714).
yeccpars2_852_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_853_/1}).
-file("megaco_text_parser_prev3a.yrl", 718).
yeccpars2_853_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_854_/1}).
-file("megaco_text_parser_prev3a.yrl", 721).
yeccpars2_854_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { errorDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_855_/1}).
-file("megaco_text_parser_prev3a.yrl", 716).
yeccpars2_855_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { digitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_856_/1}).
-file("megaco_text_parser_prev3a.yrl", 709).
yeccpars2_856_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_857_/1}).
-file("megaco_text_parser_prev3a.yrl", 722).
yeccpars2_857_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditReturnItem , __1 }
  end | __Stack].

-compile({inline,yeccpars2_858_/1}).
-file("megaco_text_parser_prev3a.yrl", 737).
yeccpars2_858_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   mediaToken
  end | __Stack].

-compile({inline,yeccpars2_859_/1}).
-file("megaco_text_parser_prev3a.yrl", 736).
yeccpars2_859_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modemToken
  end | __Stack].

-compile({inline,yeccpars2_860_/1}).
-file("megaco_text_parser_prev3a.yrl", 735).
yeccpars2_860_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   muxToken
  end | __Stack].

-compile({inline,yeccpars2_861_/1}).
-file("megaco_text_parser_prev3a.yrl", 740).
yeccpars2_861_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   observedEventsToken
  end | __Stack].

-compile({inline,yeccpars2_862_/1}).
-file("megaco_text_parser_prev3a.yrl", 741).
yeccpars2_862_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   packagesToken
  end | __Stack].

-compile({inline,yeccpars2_863_/1}).
-file("megaco_text_parser_prev3a.yrl", 739).
yeccpars2_863_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statsToken
  end | __Stack].

-compile({inline,yeccpars2_865_/1}).
-file("megaco_text_parser_prev3a.yrl", 1394).
yeccpars2_865_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_868_/1}).
-file("megaco_text_parser_prev3a.yrl", 1394).
yeccpars2_868_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_869_/1}).
-file("megaco_text_parser_prev3a.yrl", 1393).
yeccpars2_869_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_870_/1}).
-file("megaco_text_parser_prev3a.yrl", 1391).
yeccpars2_870_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_871_/1}).
-file("megaco_text_parser_prev3a.yrl", 706).
yeccpars2_871_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_terminationAudit ( [ __1 | __2 ] )
  end | __Stack].

-compile({inline,yeccpars2_873_/1}).
-file("megaco_text_parser_prev3a.yrl", 709).
yeccpars2_873_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_874_/1}).
-file("megaco_text_parser_prev3a.yrl", 708).
yeccpars2_874_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_875_/1}).
-file("megaco_text_parser_prev3a.yrl", 700).
yeccpars2_875_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditResult ,
    # 'AuditResult' { terminationID = __1 ,
    terminationAuditResult = __3 } }
  end | __Stack].

-compile({inline,yeccpars2_877_/1}).
-file("megaco_text_parser_prev3a.yrl", 690).
yeccpars2_877_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditCapReply , __3 }
  end | __Stack].

-compile({inline,yeccpars2_879_/1}).
-file("megaco_text_parser_prev3a.yrl", 686).
yeccpars2_879_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditCapReply , __4 }
  end | __Stack].

-compile({inline,yeccpars2_880_/1}).
-file("megaco_text_parser_prev3a.yrl", 599).
yeccpars2_880_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'ActionReply' .contextId , __5 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_882_/1}).
-file("megaco_text_parser_prev3a.yrl", 660).
yeccpars2_882_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_883_/1}).
-file("megaco_text_parser_prev3a.yrl", 651).
yeccpars2_883_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { __1 , # 'AmmsReply' { terminationID = [ __3 ] ,
    terminationAudit = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_886_/1}).
-file("megaco_text_parser_prev3a.yrl", 659).
yeccpars2_886_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_887_/1}).
-file("megaco_text_parser_prev3a.yrl", 604).
yeccpars2_887_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_action_reply ( [ __1 | __2 ] )
  end | __Stack].

-compile({inline,yeccpars2_889_/1}).
-file("megaco_text_parser_prev3a.yrl", 611).
yeccpars2_889_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ { error , __2 } ]
  end | __Stack].

-compile({inline,yeccpars2_890_/1}).
-file("megaco_text_parser_prev3a.yrl", 614).
yeccpars2_890_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_891_/1}).
-file("megaco_text_parser_prev3a.yrl", 613).
yeccpars2_891_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_892_/1}).
-file("megaco_text_parser_prev3a.yrl", 592).
yeccpars2_892_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { actionReplies , [ __1 | __2 ] }
  end | __Stack].

-compile({inline,yeccpars2_894_/1}).
-file("megaco_text_parser_prev3a.yrl", 595).
yeccpars2_894_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_895_/1}).
-file("megaco_text_parser_prev3a.yrl", 594).
yeccpars2_895_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_896_/1}).
-file("megaco_text_parser_prev3a.yrl", 584).
yeccpars2_896_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionReply' { transactionId = __3 ,
    immAckRequired = __5 ,
    transactionResult = __6 }
  end | __Stack].

-compile({inline,yeccpars2_900_/1}).
-file("megaco_text_parser_prev3a.yrl", 500).
yeccpars2_900_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionPending' { transactionId = ensure_transactionID ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_901_/1}).
-file("megaco_text_parser_prev3a.yrl", 484).
yeccpars2_901_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_902_/1}).
-file("megaco_text_parser_prev3a.yrl", 972).
yeccpars2_902_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_pathName ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_903_/1}).
-file("megaco_text_parser_prev3a.yrl", 943).
yeccpars2_903_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { deviceName , __1 }
  end | __Stack].

-compile({inline,yeccpars2_904_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_904_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_905_/1}).
-file("megaco_text_parser_prev3a.yrl", 471).
yeccpars2_905_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_906_/1}).
-file("megaco_text_parser_prev3a.yrl", 960).
yeccpars2_906_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_mtpAddress ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_907_/1}).
-file("megaco_text_parser_prev3a.yrl", 936).
yeccpars2_907_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_908_/1}).
-file("megaco_text_parser_prev3a.yrl", 935).
yeccpars2_908_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].


-file("megaco_text_parser_prev3a.yrl", 1592).
