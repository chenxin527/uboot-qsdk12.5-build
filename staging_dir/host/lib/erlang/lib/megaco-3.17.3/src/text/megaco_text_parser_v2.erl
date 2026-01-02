-module(megaco_text_parser_v2).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("megaco_text_parser_v2.yrl", 1530).

%% The following directive is needed for (significantly) faster compilation
%% of the generated .erl file by the HiPE compiler.  Please do not remove.
-compile([{hipe,[{regalloc,linear_scan}]}]).

-include("megaco_text_parser_v2.hrl").



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



-file("./megaco_text_parser_v2.erl", 197).

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
 yeccpars2_113(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(114=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(115=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(116=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(117=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(118=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(119=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_119(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(120=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(121=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_121(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(122=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_122(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(123=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_123(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(124=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_124(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(125=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(126=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_126(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(127=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(128=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_128(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(129=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_129(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(130=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(131=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(132=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(133=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_133(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(134=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(135=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_135(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(136=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(137=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(138=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_138(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(139=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_139(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(140=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_140(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(141=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_141(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(142=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_142(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(143=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_143(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(144=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(145=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_145(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(146=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_146(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(147=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_147(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(148=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_148(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(149=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_149(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(150=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_150(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(151=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_151(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(152=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_152(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(153=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_153(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(154=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_154(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(155=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_155(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(156=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_156(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(157=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_157(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(158=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(159=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_159(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(160=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_160(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(161=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(162=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_162(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(163=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(164=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(165=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_165(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(166=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(172=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_172(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(173=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_173(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(174=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_174(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(181=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_181(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(182=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(183=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_183(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(184=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(185=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(186=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(187=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(188=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(189=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(190=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(191=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(192=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(193=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(194=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_194(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(195=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_195(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(196=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_196(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(197=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_197(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(198=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(199=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_199(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(200=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_200(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(201=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_201(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(202=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_202(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(203=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(204=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_204(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(205=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_205(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(206=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(207=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_207(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(208=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(209=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(210=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_210(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(211=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_211(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(212=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_212(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(213=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(214=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_214(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(215=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_215(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(216=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_216(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(217=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(218=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_218(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(219=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_219(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(220=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_220(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(221=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_221(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(222=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_222(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(223=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(224=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_224(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(225=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_225(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(226=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_226(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(227=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_227(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(228=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_228(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(229=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_229(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(230=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_230(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(231=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_231(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(232=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_232(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(233=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_233(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(234=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_234(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(235=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_235(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(236=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_236(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(237=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_237(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(238=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_238(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(239=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(240=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_240(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(241=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_241(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(242=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_242(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(243=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_243(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(244=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_244(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(245=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(246=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_246(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(247=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(248=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_248(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(249=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_249(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(250=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_250(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(251=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_251(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(252=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_252(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(258=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_258(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(259=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(260=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(261=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_261(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(262=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_262(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(263=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(264=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_264(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(265=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_265(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(266=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_266(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(267=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_267(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(268=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_268(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(269=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_269(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(276=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(277=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_277(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(278=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_278(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(279=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_279(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(280=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_280(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(281=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_281(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(282=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_282(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(283=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_283(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(284=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_284(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(285=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_285(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(286=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_286(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(287=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_287(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(288=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(289=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_289(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(290=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_290(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(291=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_284(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(292=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_292(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(293=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_293(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(294=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(295=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(296=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_296(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(297=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_297(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(298=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(299=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(300=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(301=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(302=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_302(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(303=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_303(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(304=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_304(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(305=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_305(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(306=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_306(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(307=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_307(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(308=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_308(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(309=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(310=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(311=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_311(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(312=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_312(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(313=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(314=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(315=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_315(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(316=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_316(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(317=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_317(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(318=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_318(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(319=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_319(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(320=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_320(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(321=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_321(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(322=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_322(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(323=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_323(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(324=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_268(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(325=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_325(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(326=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_326(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(327=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_327(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(328=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(329=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_329(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(330=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_330(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(331=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_331(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(332=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_332(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(333=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_333(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(334=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_334(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(335=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_335(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(336=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_336(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(337=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_337(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(338=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_338(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(339=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_339(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(340=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_340(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(341=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(342=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_342(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(343=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_343(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(344=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(345=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(346=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_346(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(347=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_347(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(348=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_348(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(349=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_349(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(350=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(351=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_351(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(352=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_352(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(353=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_353(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(354=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(355=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_355(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(356=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_356(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(357=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_357(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(358=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_358(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(359=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(360=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_360(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(361=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_361(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(362=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(363=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_363(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(364=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_364(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(365=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_365(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(366=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(367=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_367(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(368=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_368(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(369=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_369(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(370=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_370(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(371=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_371(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(372=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_372(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(373=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_373(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(374=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_374(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(375=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_375(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(376=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_376(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(377=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_377(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(378=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_378(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(379=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_379(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(380=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_380(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(381=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_381(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(382=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_382(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(383=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_383(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(384=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_384(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(392=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_392(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(393=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_393(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(394=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(395=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_395(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(396=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(397=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_397(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(398=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_398(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(399=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_399(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(400=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_400(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(401=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_401(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(402=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_402(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(403=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_403(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(404=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_404(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(405=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_405(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(406=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_406(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(407=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_407(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(408=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_408(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(409=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_409(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(410=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(411=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_411(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(412=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_412(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(413=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_413(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(414=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_414(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(415=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_415(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(416=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_416(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(417=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_417(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(418=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_418(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(419=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_419(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(420=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_420(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(421=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(422=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_422(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(423=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_423(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(424=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_424(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(425=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_425(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(426=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(427=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_427(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(428=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(429=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_429(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(430=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_430(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(431=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_431(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(432=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(433=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_433(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(434=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(435=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_435(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(436=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_436(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(437=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_437(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(438=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_399(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(439=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_439(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(440=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_440(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(441=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_441(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(442=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_442(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(443=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(444=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_444(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(445=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(446=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_446(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(447=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_447(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(448=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_448(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(449=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_449(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(450=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_450(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(451=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_451(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(452=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(453=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_453(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(454=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_454(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(455=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_455(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(456=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(457=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_457(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(458=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_458(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(459=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_459(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(460=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_460(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(461=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_461(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(462=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_462(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(463=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_463(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(464=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_464(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(465=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_465(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(466=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(467=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_467(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(468=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_468(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(469=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(470=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_470(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(471=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_471(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(472=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(473=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_473(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(474=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_474(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(475=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_475(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(476=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_476(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(477=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_477(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(478=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(479=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_479(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(480=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_480(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(481=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_481(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(482=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_482(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(483=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_483(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(484=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_484(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(485=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_485(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(486=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_486(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(487=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_487(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(488=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_482(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(489=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_489(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(490=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_490(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(491=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_491(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(492=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(493=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_493(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(494=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_494(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(495=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(496=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_496(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(497=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_497(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(498=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_498(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(499=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_167(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(500=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_500(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(501=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_501(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(502=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_502(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(503=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(504=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_504(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(505=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_505(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(506=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_506(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(507=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_507(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(508=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_508(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(509=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_509(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(510=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_510(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(511=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_511(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(512=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_512(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(513=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_513(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(514=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_514(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(515=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_515(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(516=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_516(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(517=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_517(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(518=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_518(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(519=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_519(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(520=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_520(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(521=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_521(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(522=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_522(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(523=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_523(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(524=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_524(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(525=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_525(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(526=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_526(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(527=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_527(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(528=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(529=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_529(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(530=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(531=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_531(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(532=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_532(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(533=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(534=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_534(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(535=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_535(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(536=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_536(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(537=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_537(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(538=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_523(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(539=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_539(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(540=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_540(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(541=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_541(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(542=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(543=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_543(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(544=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_544(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(545=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_545(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(546=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(547=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_547(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(548=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_548(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(549=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(550=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_550(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(551=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_551(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(552=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_552(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(553=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(554=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(555=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_555(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(556=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_556(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(557=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_557(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(558=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(559=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_559(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(560=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_560(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(561=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_561(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(562=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_562(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(563=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(564=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_564(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(565=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(566=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_566(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(567=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_567(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(568=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(569=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_569(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(570=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_570(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(571=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_571(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(572=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_572(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(573=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_573(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(574=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_574(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(575=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_575(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(576=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_576(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(577=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_577(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(578=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_578(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(579=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_579(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(580=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_580(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(581=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_581(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(582=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_582(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(583=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_583(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(584=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_584(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(585=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_585(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(586=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_586(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(587=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_587(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(588=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_588(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(589=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_589(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(590=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_590(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(591=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_591(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(592=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_592(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(593=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_593(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(594=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_594(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(595=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_595(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(596=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_596(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(597=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_597(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(598=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_598(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(599=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_599(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(600=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_600(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(601=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_601(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(602=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_585(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(603=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_603(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(604=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_604(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(605=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_605(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(606=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(607=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_607(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(608=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_608(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(609=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_609(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(610=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_610(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(611=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_608(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(612=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_612(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(613=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_613(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(614=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_614(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(615=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_615(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(616=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_616(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(617=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_617(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(618=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_618(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(619=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_619(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(620=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_620(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(621=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_621(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(622=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_622(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(623=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_623(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(624=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_624(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(625=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_621(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(626=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_626(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(627=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_627(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(628=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_628(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(629=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_629(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(630=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_630(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(631=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_631(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(632=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_632(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(633=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_633(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(634=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_634(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(635=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_615(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(636=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_636(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(637=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_637(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(638=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_638(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(639=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_639(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(640=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_574(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(641=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_641(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(642=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_642(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(643=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_643(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(644=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(645=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_645(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(646=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(647=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_647(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(648=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_648(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(649=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_649(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(650=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_650(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(651=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_651(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(652=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_652(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(653=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_653(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(654=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_654(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(655=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_655(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(656=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_656(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(657=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_657(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(658=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_658(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(659=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_659(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(660=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_660(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(661=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_661(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(662=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_662(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(663=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(664=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_664(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(665=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(666=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_666(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(667=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_667(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(668=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_668(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(669=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_669(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(670=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_670(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(671=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_671(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(672=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_672(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(673=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_673(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(674=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_674(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(675=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_675(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(676=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_676(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(677=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_677(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(678=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_678(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(679=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_679(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(680=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_669(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(681=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_681(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(682=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_682(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(683=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_683(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(684=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_684(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(685=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(686=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_686(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(687=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_687(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(688=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_688(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(689=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_689(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(690=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_690(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(691=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_691(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(692=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_692(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(693=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_693(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(694=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_694(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(695=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_650(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(696=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_696(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(697=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_697(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(698=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_698(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(699=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_699(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(700=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(701=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_701(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(702=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_702(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(703=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_703(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(704=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_704(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(705=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_705(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(706=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_706(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(707=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_707(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(708=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_708(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(709=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_709(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(710=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_710(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(711=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_711(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(712=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_712(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(713=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_506(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(714=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_714(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(715=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_715(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(716=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_716(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(717=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_717(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(718=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(719=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_719(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(720=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_720(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(721=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_721(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(722=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_722(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(723=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_723(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(724=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(725=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_725(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(726=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_726(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(727=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_727(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(728=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(729=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_729(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(730=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_730(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(731=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_731(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(732=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(733=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_733(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(734=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_734(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(735=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_735(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(736=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(737=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_737(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(738=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_738(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(739=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_739(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(740=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(741=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_741(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(742=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_742(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(743=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_743(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(744=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_744(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(745=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_745(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(746=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_746(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(747=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_747(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(748=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_748(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(749=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_749(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(750=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(751=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_751(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(752=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_752(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(753=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_753(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(754=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_754(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(755=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_755(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(756=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_756(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(757=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_757(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(758=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_758(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(759=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_759(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(760=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_760(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(761=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_761(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(762=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_762(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(763=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_763(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(764=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_764(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(765=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_765(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(766=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_766(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(767=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_767(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(768=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_768(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(769=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_769(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(770=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(771=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_771(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(772=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_772(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(773=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_773(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(774=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_774(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(775=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_775(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(776=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_776(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(784=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_784(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(785=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_785(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(786=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_786(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(787=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_787(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(788=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_788(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(789=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_777(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(790=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_790(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(791=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_791(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(800=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_800(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(801=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_801(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(802=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_802(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(803=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_803(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(804=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_804(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(805=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_805(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(806=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_806(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(807=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_807(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(808=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_808(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(809=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_809(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(810=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(811=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_811(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(812=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_812(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(813=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_813(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(814=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_814(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(815=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_815(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(816=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_816(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(817=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_817(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(818=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_818(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(819=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_819(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(820=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_820(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(821=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_821(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(822=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_822(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(823=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_823(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(824=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_824(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(825=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_825(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(826=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_826(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(827=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_827(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(828=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_828(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(829=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_829(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(830=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_830(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(831=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_831(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(832=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_832(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(833=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_833(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(834=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_834(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(835=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_835(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(836=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_836(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(837=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_837(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(838=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_838(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(839=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(840=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_840(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(841=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_841(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(842=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(843=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_843(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(844=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_844(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(845=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(846=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_846(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(847=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_847(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(848=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_848(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(849=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(850=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_850(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(851=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_851(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(852=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(853=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_853(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(854=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_854(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(855=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_855(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(856=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_856(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(857=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_818(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(858=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_858(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(859=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_859(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(860=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_860(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(861=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_861(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(862=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_862(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(863=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_863(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(864=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_864(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(865=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_865(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(866=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(867=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_867(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(868=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_868(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(869=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_818(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(870=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_870(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(871=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_871(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(872=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_872(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(873=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_752(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(874=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_874(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(875=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_875(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(876=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_876(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(877=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_877(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(878=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_878(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(879=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_879(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(880=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_880(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(881=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_881(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(882=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(883=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_883(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(884=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_884(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(885=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_885(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(886=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_886(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(887=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_887(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(888=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_888(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(889=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_889(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(890=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_890(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(891=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_891(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(892=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_892(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(893=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_893(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_4(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ServiceChangeIncompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 104, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 106, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 107, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 108, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 109, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 110, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 111, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 112, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 113, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 114, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 115, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
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
 yeccpars1(S, 118, Ss, Stack, T, Ts, Tzr);
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

yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_105(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_108(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_109(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_110(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_111(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_112(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_118: see yeccpars2_4

yeccpars2_119(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 120, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_120: see yeccpars2_4

yeccpars2_121(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_121(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_121_(Stack),
 yeccpars2_122(_S, Cat, [121 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_122(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_122_(Stack),
 yeccgoto_authenticationHeader(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_123(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 130, Ss, Stack, T, Ts, Tzr);
yeccpars2_123(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 131, Ss, Stack, T, Ts, Tzr);
yeccpars2_123(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_123_(Stack),
 yeccpars2_126(126, Cat, [123 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_124(S, endOfMessage, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 125, Ss, Stack, T, Ts, Tzr);
yeccpars2_124(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_125_(Stack),
 yeccgoto_megacoMessage(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_126(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'MtpAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 891, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_127(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 156, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 157, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 158, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 159, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mId(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_129(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mId(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_130: see yeccpars2_4

yeccpars2_131(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 134, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'InternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ServiceChangeIncompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 104, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 106, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 107, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 108, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 109, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 110, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 111, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 112, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 113, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 114, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 115, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_131_(Stack),
 yeccpars2_133(133, Cat, [131 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_132(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 134, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'InternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ServiceChangeIncompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 104, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 106, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 107, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 108, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 109, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 110, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 111, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 112, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 113, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 114, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 115, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_132_(Stack),
 yeccpars2_141(_S, Cat, [132 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_133(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 136, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_134(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 134, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'InternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ServiceChangeIncompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 104, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 106, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 107, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 108, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 109, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 110, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 111, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 112, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 113, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 114, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 115, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_134_(Stack),
 yeccpars2_135(_S, Cat, [134 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_135_(Stack),
 yeccgoto_daddr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_136(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 137, Ss, Stack, T, Ts, Tzr);
yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_136_(Stack),
 yeccgoto_domainAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_137: see yeccpars2_4

yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_138_(Stack),
 yeccgoto_portNumber(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_139(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_139_(Stack),
 yeccpars2_140(_S, Cat, [139 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_140_(Stack),
 yeccgoto_domainAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_141(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_141_(Stack),
 yeccgoto_daddr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_142(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 143, Ss, Stack, T, Ts, Tzr);
yeccpars2_142(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_143(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 144, Ss, Stack, T, Ts, Tzr);
yeccpars2_143(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_143_(Stack),
 yeccgoto_domainName(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_144: see yeccpars2_4

yeccpars2_145(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_145_(Stack),
 yeccpars2_146(_S, Cat, [145 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_146(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_146_(Stack),
 yeccgoto_domainName(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_147(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_147_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_148(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_148_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_149(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_149_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_150_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_151_(Stack),
 yeccgoto_messageBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_152(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 156, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 157, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 158, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 159, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_152_(Stack),
 yeccgoto_transactionList(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_153_(Stack),
 yeccgoto_message(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_154_(Stack),
 yeccgoto_messageBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_155(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 810, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_156(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 882, Ss, Stack, T, Ts, Tzr);
yeccpars2_156(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_157(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 740, Ss, Stack, T, Ts, Tzr);
yeccpars2_157(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_158(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 732, Ss, Stack, T, Ts, Tzr);
yeccpars2_158(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_159(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 160, Ss, Stack, T, Ts, Tzr);
yeccpars2_159(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 161, Ss, Stack, T, Ts, Tzr);
yeccpars2_159(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_160(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 724, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_161(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 163, Ss, Stack, T, Ts, Tzr);
yeccpars2_161(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_162(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 718, Ss, Stack, T, Ts, Tzr);
yeccpars2_162(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_162_(Stack),
 yeccpars2_717(717, Cat, [162 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_163(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 164, Ss, Stack, T, Ts, Tzr);
yeccpars2_163(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_164: see yeccpars2_4

yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_165_(Stack),
 yeccgoto_contextID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_166(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 167, Ss, Stack, T, Ts, Tzr);
yeccpars2_166(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_167(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 180, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 181, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 182, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 183, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 184, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 185, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 186, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 187, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 188, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 189, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 190, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 191, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 192, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_168_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_169(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_170(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_171_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_172(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_173(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_177(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 503, Ss, Stack, T, Ts, Tzr);
yeccpars2_177(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_179(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 499, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_179_(Stack),
 yeccpars2_498(498, Cat, [179 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_180(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_180_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_181(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 495, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_182(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 492, Ss, Stack, T, Ts, Tzr);
yeccpars2_182(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_183(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 482, Ss, Stack, T, Ts, Tzr);
yeccpars2_183(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_184_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_185_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_186_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_187_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_188(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 445, Ss, Stack, T, Ts, Tzr);
yeccpars2_188(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_189(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 443, Ss, Stack, T, Ts, Tzr);
yeccpars2_189(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_190(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 394, Ss, Stack, T, Ts, Tzr);
yeccpars2_190(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_191(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 217, Ss, Stack, T, Ts, Tzr);
yeccpars2_191(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_192(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 193, Ss, Stack, T, Ts, Tzr);
yeccpars2_192(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_193: see yeccpars2_4

yeccpars2_194(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 213, Ss, Stack, T, Ts, Tzr);
yeccpars2_194(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_194_(Stack),
 yeccpars2_212(212, Cat, [194 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_195(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_terminationA(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_196(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 198, Ss, Stack, T, Ts, Tzr);
yeccpars2_196(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_197_(Stack),
 yeccgoto_terminationID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_198: see yeccpars2_4

yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_terminationB(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_200(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 201, Ss, Stack, T, Ts, Tzr);
yeccpars2_200(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_201(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 203, Ss, Stack, T, Ts, Tzr);
yeccpars2_201(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 204, Ss, Stack, T, Ts, Tzr);
yeccpars2_201(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 205, Ss, Stack, T, Ts, Tzr);
yeccpars2_201(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_202(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 206, Ss, Stack, T, Ts, Tzr);
yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_202_(Stack),
 yeccgoto_topologyTriple(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_203_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_204(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_204_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_205(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_205_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_206(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 208, Ss, Stack, T, Ts, Tzr);
yeccpars2_206(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_207(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_207_(Stack),
 yeccgoto_topologyTriple(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_208(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 209, Ss, Stack, T, Ts, Tzr);
yeccpars2_208(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_209: see yeccpars2_4

yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_210_(Stack),
 yeccgoto_eventStream(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_211_(Stack),
 yeccgoto_streamID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_212(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 216, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_213: see yeccpars2_4

yeccpars2_214(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 213, Ss, Stack, T, Ts, Tzr);
yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_214_(Stack),
 yeccpars2_215(_S, Cat, [214 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_215_(Stack),
 yeccgoto_topologyTripleList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_216(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_216_(Stack),
 yeccgoto_topologyDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_217: see yeccpars2_4

yeccpars2_218(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_218(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_218_(Stack),
 yeccpars2_219(_S, Cat, [218 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_219(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_219_(Stack),
 yeccgoto_subtractRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_220(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 222, Ss, Stack, T, Ts, Tzr);
yeccpars2_220(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_221(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 393, Ss, Stack, T, Ts, Tzr);
yeccpars2_221(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_222(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 223, Ss, Stack, T, Ts, Tzr);
yeccpars2_222(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_223(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 236, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 237, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 238, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 239, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 240, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 241, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 242, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 243, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 244, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 245, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 246, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_223_(Stack),
 yeccpars2_235(235, Cat, [223 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_224_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_225(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_225_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_226_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_227_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_228_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_229_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_230_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_231(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_231_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_232(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 384, Ss, Stack, T, Ts, Tzr);
yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_232_(Stack),
 yeccpars2_383(_S, Cat, [232 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_233(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_auditItem(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_234(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 380, Ss, Stack, T, Ts, Tzr);
yeccpars2_234(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_234_(Stack),
 yeccpars2_379(_S, Cat, [234 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_235(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 378, Ss, Stack, T, Ts, Tzr);
yeccpars2_235(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_236(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_236_(Stack),
 yeccgoto_indAuddigitMapDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_237(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_237_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_238(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 366, Ss, Stack, T, Ts, Tzr);
yeccpars2_238(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_238_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_239(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 359, Ss, Stack, T, Ts, Tzr);
yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_239_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_240(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 332, Ss, Stack, T, Ts, Tzr);
yeccpars2_240(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_240_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_241(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_241_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_242(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_242_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_243(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_243_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_244(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 328, Ss, Stack, T, Ts, Tzr);
yeccpars2_244(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_244_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_245(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 252, Ss, Stack, T, Ts, Tzr);
yeccpars2_245(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_245_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_246(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 247, Ss, Stack, T, Ts, Tzr);
yeccpars2_246(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_246_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_247: see yeccpars2_4

yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_248_(Stack),
 yeccgoto_pkgdName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_249(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 250, Ss, Stack, T, Ts, Tzr);
yeccpars2_249(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_250(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_250_(Stack),
 yeccgoto_indAudstatisticsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_251(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_251_(Stack),
 yeccgoto_indAudsignalsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_252(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 258, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 259, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_253(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_253_(Stack),
 yeccgoto_indAudsignalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_254(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 268, Ss, Stack, T, Ts, Tzr);
yeccpars2_254(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_254_(Stack),
 yeccgoto_signalRequest(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_signalName(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_256(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 267, Ss, Stack, T, Ts, Tzr);
yeccpars2_256(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_257(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_257_(Stack),
 yeccgoto_indAudsignalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_258(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_258_(Stack),
 yeccgoto_optIndAudsignalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_259(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 260, Ss, Stack, T, Ts, Tzr);
yeccpars2_259(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_260: see yeccpars2_4

yeccpars2_261(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 263, Ss, Stack, T, Ts, Tzr);
yeccpars2_261(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_262_(Stack),
 yeccgoto_signalListId(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_263: see yeccpars2_4

yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_signalListParm(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_265(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 266, Ss, Stack, T, Ts, Tzr);
yeccpars2_265(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_266(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_266_(Stack),
 yeccgoto_indAudsignalList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_267(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_267_(Stack),
 yeccgoto_optIndAudsignalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_268(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 271, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 272, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 273, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 274, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 275, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_268(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_269(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 324, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_269_(Stack),
 yeccpars2_323(323, Cat, [269 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_270(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 298, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 299, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 300, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, 'NEQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 301, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_271(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 295, Ss, Stack, T, Ts, Tzr);
yeccpars2_271(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_272(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_272_COMMA(Stack),
 yeccgoto_sigParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_272(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_272_RBRKT(Stack),
 yeccgoto_sigParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_272(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_273(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 283, Ss, Stack, T, Ts, Tzr);
yeccpars2_273(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_274(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 278, Ss, Stack, T, Ts, Tzr);
yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_275(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 276, Ss, Stack, T, Ts, Tzr);
yeccpars2_275(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_276: see yeccpars2_4

yeccpars2_277(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_277_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_278(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 280, Ss, Stack, T, Ts, Tzr);
yeccpars2_278(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 281, Ss, Stack, T, Ts, Tzr);
yeccpars2_278(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 282, Ss, Stack, T, Ts, Tzr);
yeccpars2_278(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_279(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_279_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_280(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_280_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_281(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_281_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_282(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_282_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_283(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 284, Ss, Stack, T, Ts, Tzr);
yeccpars2_283(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_284(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 286, Ss, Stack, T, Ts, Tzr);
yeccpars2_284(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 287, Ss, Stack, T, Ts, Tzr);
yeccpars2_284(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 288, Ss, Stack, T, Ts, Tzr);
yeccpars2_284(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 289, Ss, Stack, T, Ts, Tzr);
yeccpars2_284(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_285(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 291, Ss, Stack, T, Ts, Tzr);
yeccpars2_285(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_285_(Stack),
 yeccpars2_290(290, Cat, [285 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_286(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_286_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_287(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_287_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_288(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_288_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_289(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_289_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_290(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 294, Ss, Stack, T, Ts, Tzr);
yeccpars2_290(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_291: see yeccpars2_284

yeccpars2_292(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 291, Ss, Stack, T, Ts, Tzr);
yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_292_(Stack),
 yeccpars2_293(_S, Cat, [292 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_293(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_293_(Stack),
 yeccgoto_notificationReasons(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_294(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_294_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_295: see yeccpars2_4

yeccpars2_296(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_296_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_297_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_298(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 309, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 310, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 304, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_299(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 304, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_300: see yeccpars2_299

%% yeccpars2_301: see yeccpars2_299

yeccpars2_302(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_302_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_303_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_304(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_304_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_305(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_305_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_306(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_306_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_307(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_307_(Stack),
 yeccgoto_alternativeValue(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_308(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_308_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_309: see yeccpars2_299

%% yeccpars2_310: see yeccpars2_299

yeccpars2_311(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 313, Ss, Stack, T, Ts, Tzr);
yeccpars2_311(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 314, Ss, Stack, T, Ts, Tzr);
yeccpars2_311(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_311_(Stack),
 yeccpars2_312(312, Cat, [311 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_312(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 319, Ss, Stack, T, Ts, Tzr);
yeccpars2_312(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_313: see yeccpars2_299

%% yeccpars2_314: see yeccpars2_299

yeccpars2_315(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 314, Ss, Stack, T, Ts, Tzr);
yeccpars2_315(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_315_(Stack),
 yeccpars2_316(_S, Cat, [315 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_316(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_316_(Stack),
 yeccgoto_valueList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_317(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 318, Ss, Stack, T, Ts, Tzr);
yeccpars2_317(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_318(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_318_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_319(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_319_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_320(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 314, Ss, Stack, T, Ts, Tzr);
yeccpars2_320(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_320_(Stack),
 yeccpars2_321(321, Cat, [320 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_321(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 322, Ss, Stack, T, Ts, Tzr);
yeccpars2_321(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_322(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_322_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_323(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 327, Ss, Stack, T, Ts, Tzr);
yeccpars2_323(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_324: see yeccpars2_268

yeccpars2_325(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 324, Ss, Stack, T, Ts, Tzr);
yeccpars2_325(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_325_(Stack),
 yeccpars2_326(_S, Cat, [325 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_326(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_326_(Stack),
 yeccgoto_sigParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_327(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_327_(Stack),
 yeccgoto_signalRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_328: see yeccpars2_4

yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_329_(Stack),
 yeccgoto_packagesItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_330(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 331, Ss, Stack, T, Ts, Tzr);
yeccpars2_330(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_331(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_331_(Stack),
 yeccgoto_indAudpackagesDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_332(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 338, Ss, Stack, T, Ts, Tzr);
yeccpars2_332(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 339, Ss, Stack, T, Ts, Tzr);
yeccpars2_332(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 340, Ss, Stack, T, Ts, Tzr);
yeccpars2_332(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_333(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_333_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_334(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_334_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_335(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_335_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_336(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 358, Ss, Stack, T, Ts, Tzr);
yeccpars2_336(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_337(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_337_(Stack),
 yeccgoto_indAudstreamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_338(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 350, Ss, Stack, T, Ts, Tzr);
yeccpars2_338(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_339(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 345, Ss, Stack, T, Ts, Tzr);
yeccpars2_339(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_340(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 341, Ss, Stack, T, Ts, Tzr);
yeccpars2_340(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_341: see yeccpars2_4

yeccpars2_342(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_342_(Stack),
 yeccgoto_indAudterminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_343(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 344, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_344_(Stack),
 yeccgoto_indAudterminationStateDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_345: see yeccpars2_4

yeccpars2_346(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 347, Ss, Stack, T, Ts, Tzr);
yeccpars2_346(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_347(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 338, Ss, Stack, T, Ts, Tzr);
yeccpars2_347(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_348(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 349, Ss, Stack, T, Ts, Tzr);
yeccpars2_348(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_349(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_349_(Stack),
 yeccgoto_indAudstreamDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_350: see yeccpars2_4

yeccpars2_351(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_351_(Stack),
 yeccgoto_indAudlocalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_352(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 354, Ss, Stack, T, Ts, Tzr);
yeccpars2_352(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_352_(Stack),
 yeccpars2_353(353, Cat, [352 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_353(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 357, Ss, Stack, T, Ts, Tzr);
yeccpars2_353(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_354: see yeccpars2_4

yeccpars2_355(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 354, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_355_(Stack),
 yeccpars2_356(_S, Cat, [355 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_356(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_356_(Stack),
 yeccgoto_indAudlocalParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_357(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_357_(Stack),
 yeccgoto_indAudlocalControlDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_358(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_358_(Stack),
 yeccgoto_indAudmediaDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_359: see yeccpars2_4

yeccpars2_360(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_360_(Stack),
 yeccgoto_requestID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_361(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 362, Ss, Stack, T, Ts, Tzr);
yeccpars2_361(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_362: see yeccpars2_4

yeccpars2_363(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_indAudrequestedEvent(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_364(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 365, Ss, Stack, T, Ts, Tzr);
yeccpars2_364(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_365(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_365_(Stack),
 yeccgoto_indAudeventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_366: see yeccpars2_4

yeccpars2_367(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 371, Ss, Stack, T, Ts, Tzr);
yeccpars2_367(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_367_(Stack),
 yeccpars2_370(_S, Cat, [367 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_368(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 369, Ss, Stack, T, Ts, Tzr);
yeccpars2_368(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_369(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_369_(Stack),
 yeccgoto_indAudeventBufferDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_370(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_370_(Stack),
 yeccgoto_indAudeventSpec(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_371(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 376, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_372_(Stack),
 yeccgoto_eventParameterName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_373(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 377, Ss, Stack, T, Ts, Tzr);
yeccpars2_373(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_374_(Stack),
 yeccgoto_indAudeventSpecParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_375(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_375_(Stack),
 yeccgoto_indAudeventSpecParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_376(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 209, Ss, Stack, T, Ts, Tzr);
yeccpars2_376(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_377(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_377_(Stack),
 yeccgoto_optIndAudeventSpecParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_378(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_378_(Stack),
 yeccgoto_auditDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_379(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_379_(Stack),
 yeccgoto_auditDescriptorBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_380(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 236, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 237, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 238, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 239, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 240, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 241, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 242, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 243, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 244, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 245, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 246, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_381(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 380, Ss, Stack, T, Ts, Tzr);
yeccpars2_381(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_381_(Stack),
 yeccpars2_382(_S, Cat, [381 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_382(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_382_(Stack),
 yeccgoto_auditItemList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_383(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_383_(Stack),
 yeccgoto_indAudterminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_384(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 236, Ss, Stack, T, Ts, Tzr);
yeccpars2_384(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 386, Ss, Stack, T, Ts, Tzr);
yeccpars2_384(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 387, Ss, Stack, T, Ts, Tzr);
yeccpars2_384(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 388, Ss, Stack, T, Ts, Tzr);
yeccpars2_384(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 389, Ss, Stack, T, Ts, Tzr);
yeccpars2_384(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 390, Ss, Stack, T, Ts, Tzr);
yeccpars2_384(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 391, Ss, Stack, T, Ts, Tzr);
yeccpars2_384(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_385(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 384, Ss, Stack, T, Ts, Tzr);
yeccpars2_385(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_385_(Stack),
 yeccpars2_392(_S, Cat, [385 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_386(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 366, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_387(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 359, Ss, Stack, T, Ts, Tzr);
yeccpars2_387(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_388(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 332, Ss, Stack, T, Ts, Tzr);
yeccpars2_388(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_389(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 328, Ss, Stack, T, Ts, Tzr);
yeccpars2_389(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_390(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 252, Ss, Stack, T, Ts, Tzr);
yeccpars2_390(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_391(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 247, Ss, Stack, T, Ts, Tzr);
yeccpars2_391(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_392(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_392_(Stack),
 yeccgoto_indAudterminationAuditList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_393(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_393_(Stack),
 yeccgoto_optAuditDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_394: see yeccpars2_4

yeccpars2_395(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 396, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_396(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 398, Ss, Stack, T, Ts, Tzr);
yeccpars2_396(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_397(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 442, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_398(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 399, Ss, Stack, T, Ts, Tzr);
yeccpars2_398(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_399(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 413, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 236, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 237, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 238, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 239, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 240, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 414, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 415, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 241, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 242, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 243, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 244, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 416, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 417, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 418, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 245, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 246, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 419, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 420, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_400(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_400_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_401_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_402_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_403_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_404(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 438, Ss, Stack, T, Ts, Tzr);
yeccpars2_404(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_404_(Stack),
 yeccpars2_437(437, Cat, [404 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_405(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_405_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_406(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_406_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_407(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_407_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_408(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_408_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_409(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_409_(Stack),
 yeccgoto_extensionParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_410: see yeccpars2_270

yeccpars2_411(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_411_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_412(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_412_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_413(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 434, Ss, Stack, T, Ts, Tzr);
yeccpars2_413(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_414(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 432, Ss, Stack, T, Ts, Tzr);
yeccpars2_414(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_415(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 430, Ss, Stack, T, Ts, Tzr);
yeccpars2_415(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_416(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 428, Ss, Stack, T, Ts, Tzr);
yeccpars2_416(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_417(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 426, Ss, Stack, T, Ts, Tzr);
yeccpars2_417(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_418(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 423, Ss, Stack, T, Ts, Tzr);
yeccpars2_418(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_419(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_419_COMMA(Stack),
 yeccgoto_timeStamp(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_419(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_419_RBRKT(Stack),
 yeccgoto_timeStamp(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_419(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_420(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_420(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_421: see yeccpars2_4

yeccpars2_422(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_422_(Stack),
 yeccgoto_serviceChangeVersion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_423(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'InternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 130, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 131, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'Nx64kToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ServiceChangeIncompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 104, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 106, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 107, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 108, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 109, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 110, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 111, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 112, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 113, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 114, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 115, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_423_(Stack),
 yeccpars2_126(126, Cat, [423 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_424(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_424_(Stack),
 yeccgoto_serviceChangeAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_425(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_425_(Stack),
 yeccgoto_serviceChangeAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_426: see yeccpars2_299

yeccpars2_427(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_427_(Stack),
 yeccgoto_serviceChangeReason(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_428: see yeccpars2_4

yeccpars2_429(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_429_(Stack),
 yeccgoto_serviceChangeProfile(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_430(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 130, Ss, Stack, T, Ts, Tzr);
yeccpars2_430(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 131, Ss, Stack, T, Ts, Tzr);
yeccpars2_430(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_430(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_430_(Stack),
 yeccpars2_126(126, Cat, [430 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_431(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_431_(Stack),
 yeccgoto_serviceChangeMgcId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_432: see yeccpars2_4

yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_433_(Stack),
 yeccgoto_serviceChangeMethod(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_434: see yeccpars2_4

yeccpars2_435(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_435_(Stack),
 yeccgoto_serviceChangeDelay(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_436(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_436_(Stack),
 yeccgoto_extension(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_437(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 441, Ss, Stack, T, Ts, Tzr);
yeccpars2_437(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_438: see yeccpars2_399

yeccpars2_439(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 438, Ss, Stack, T, Ts, Tzr);
yeccpars2_439(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_439_(Stack),
 yeccpars2_440(_S, Cat, [439 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_440(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_440_(Stack),
 yeccgoto_serviceChangeParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_441(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_441_(Stack),
 yeccgoto_serviceChangeDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_442(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_442_(Stack),
 yeccgoto_serviceChangeRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_443: see yeccpars2_4

yeccpars2_444(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_444_(Stack),
 yeccgoto_priority(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_445: see yeccpars2_4

yeccpars2_446(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 447, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_447(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_447(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 451, Ss, Stack, T, Ts, Tzr);
yeccpars2_447(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_448(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_448_(Stack),
 yeccgoto_notifyRequestBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_449(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 481, Ss, Stack, T, Ts, Tzr);
yeccpars2_449(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_450(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_450_(Stack),
 yeccgoto_notifyRequestBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_451(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 452, Ss, Stack, T, Ts, Tzr);
yeccpars2_451(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_452: see yeccpars2_4

yeccpars2_453(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 454, Ss, Stack, T, Ts, Tzr);
yeccpars2_453(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_454(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_454(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 458, Ss, Stack, T, Ts, Tzr);
yeccpars2_454(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_454_(Stack),
 yeccpars2_4(456, Cat, [454 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_455(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_455(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_455_(Stack),
 yeccpars2_476(476, Cat, [455 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_456: see yeccpars2_4

yeccpars2_457(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 460, Ss, Stack, T, Ts, Tzr);
yeccpars2_457(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_457_(Stack),
 yeccpars2_459(459, Cat, [457 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_458(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_458_(Stack),
 yeccgoto_timeStamp(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_459(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 463, Ss, Stack, T, Ts, Tzr);
yeccpars2_459(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_460(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_460(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 458, Ss, Stack, T, Ts, Tzr);
yeccpars2_460(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_460_(Stack),
 yeccpars2_4(456, Cat, [460 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_461(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 460, Ss, Stack, T, Ts, Tzr);
yeccpars2_461(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_461_(Stack),
 yeccpars2_462(_S, Cat, [461 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_462(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_462_(Stack),
 yeccgoto_observedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_463(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_463_(Stack),
 yeccgoto_observedEventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_464(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 466, Ss, Stack, T, Ts, Tzr);
yeccpars2_464(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_464_(Stack),
 yeccpars2_465(_S, Cat, [464 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_465(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_465_(Stack),
 yeccgoto_observedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_466: see yeccpars2_4

yeccpars2_467(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 472, Ss, Stack, T, Ts, Tzr);
yeccpars2_467(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_467_(Stack),
 yeccpars2_471(471, Cat, [467 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_468(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_observedEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_469: see yeccpars2_270

yeccpars2_470(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_470_(Stack),
 yeccgoto_eventStreamOrOther(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_471(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 475, Ss, Stack, T, Ts, Tzr);
yeccpars2_471(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_472: see yeccpars2_4

yeccpars2_473(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 472, Ss, Stack, T, Ts, Tzr);
yeccpars2_473(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_473_(Stack),
 yeccpars2_474(_S, Cat, [473 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_474(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_474_(Stack),
 yeccgoto_observedEventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_475(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_475_(Stack),
 yeccgoto_observedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_476(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 477, Ss, Stack, T, Ts, Tzr);
yeccpars2_476(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_477(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_477(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_477_(Stack),
 yeccpars2_4(478, Cat, [477 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_478: see yeccpars2_4

yeccpars2_479(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 466, Ss, Stack, T, Ts, Tzr);
yeccpars2_479(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_479_(Stack),
 yeccpars2_480(_S, Cat, [479 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_480(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_480_(Stack),
 yeccgoto_observedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_481(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_481_(Stack),
 yeccgoto_notifyRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_482(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 484, Ss, Stack, T, Ts, Tzr);
yeccpars2_482(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 485, Ss, Stack, T, Ts, Tzr);
yeccpars2_482(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 486, Ss, Stack, T, Ts, Tzr);
yeccpars2_482(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_483(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 488, Ss, Stack, T, Ts, Tzr);
yeccpars2_483(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_483_(Stack),
 yeccpars2_487(487, Cat, [483 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_484(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_484_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_485(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_485_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_486(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_486_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_487(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 491, Ss, Stack, T, Ts, Tzr);
yeccpars2_487(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_488: see yeccpars2_482

yeccpars2_489(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 488, Ss, Stack, T, Ts, Tzr);
yeccpars2_489(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_489_(Stack),
 yeccpars2_490(_S, Cat, [489 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_490(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_490_(Stack),
 yeccgoto_contextAuditProperties(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_491(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_491_(Stack),
 yeccgoto_contextAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_492: see yeccpars2_4

yeccpars2_493(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_493(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_493_(Stack),
 yeccpars2_494(_S, Cat, [493 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_494(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_494_(Stack),
 yeccgoto_auditRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_495: see yeccpars2_4

yeccpars2_496(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_496(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_496_(Stack),
 yeccpars2_497(_S, Cat, [496 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_497(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_497_(Stack),
 yeccgoto_auditRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_498(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 502, Ss, Stack, T, Ts, Tzr);
yeccpars2_498(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_499: see yeccpars2_167

yeccpars2_500(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 499, Ss, Stack, T, Ts, Tzr);
yeccpars2_500(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_500_(Stack),
 yeccpars2_501(_S, Cat, [500 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_501(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_501_(Stack),
 yeccgoto_actionRequestItems(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_502(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_502_(Stack),
 yeccgoto_actionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_503: see yeccpars2_4

yeccpars2_504(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 506, Ss, Stack, T, Ts, Tzr);
yeccpars2_504(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_504_(Stack),
 yeccpars2_505(_S, Cat, [504 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_505(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_505_(Stack),
 yeccgoto_ammRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_506(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 222, Ss, Stack, T, Ts, Tzr);
yeccpars2_506(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 516, Ss, Stack, T, Ts, Tzr);
yeccpars2_506(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 517, Ss, Stack, T, Ts, Tzr);
yeccpars2_506(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 518, Ss, Stack, T, Ts, Tzr);
yeccpars2_506(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 519, Ss, Stack, T, Ts, Tzr);
yeccpars2_506(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 520, Ss, Stack, T, Ts, Tzr);
yeccpars2_506(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 521, Ss, Stack, T, Ts, Tzr);
yeccpars2_506(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 522, Ss, Stack, T, Ts, Tzr);
yeccpars2_506(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_507(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_507_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_508(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_508_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_509(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_509_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_510(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_510_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_511(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_511_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_512(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_512_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_513(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_513_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_514(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_514_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_515(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 713, Ss, Stack, T, Ts, Tzr);
yeccpars2_515(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_515_(Stack),
 yeccpars2_712(712, Cat, [515 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_516(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_516_(Stack),
 yeccgoto_digitMapDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_517(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 704, Ss, Stack, T, Ts, Tzr);
yeccpars2_517(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_517_(Stack),
 yeccgoto_eventBufferDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_518(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 644, Ss, Stack, T, Ts, Tzr);
yeccpars2_518(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_518_(Stack),
 yeccgoto_eventsDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_519(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 574, Ss, Stack, T, Ts, Tzr);
yeccpars2_519(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_520(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 553, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 554, Ss, Stack, T, Ts, Tzr);
yeccpars2_520(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_521(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 542, Ss, Stack, T, Ts, Tzr);
yeccpars2_521(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_522(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 523, Ss, Stack, T, Ts, Tzr);
yeccpars2_522(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_522_(Stack),
 yeccgoto_signalsDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_523(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 527, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_523(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_524(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_524_(Stack),
 yeccgoto_signalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_525(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 538, Ss, Stack, T, Ts, Tzr);
yeccpars2_525(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_525_(Stack),
 yeccpars2_537(537, Cat, [525 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_526(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_526_(Stack),
 yeccgoto_signalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_527(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 528, Ss, Stack, T, Ts, Tzr);
yeccpars2_527(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_528: see yeccpars2_4

yeccpars2_529(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 530, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_530: see yeccpars2_4

yeccpars2_531(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 533, Ss, Stack, T, Ts, Tzr);
yeccpars2_531(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_531_(Stack),
 yeccpars2_532(532, Cat, [531 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_532(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 536, Ss, Stack, T, Ts, Tzr);
yeccpars2_532(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_533: see yeccpars2_4

yeccpars2_534(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 533, Ss, Stack, T, Ts, Tzr);
yeccpars2_534(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_534_(Stack),
 yeccpars2_535(_S, Cat, [534 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_535(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_535_(Stack),
 yeccgoto_signalListParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_536(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_536_(Stack),
 yeccgoto_signalList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_537(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 541, Ss, Stack, T, Ts, Tzr);
yeccpars2_537(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_538: see yeccpars2_523

yeccpars2_539(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 538, Ss, Stack, T, Ts, Tzr);
yeccpars2_539(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_539_(Stack),
 yeccpars2_540(_S, Cat, [539 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_540(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_540_(Stack),
 yeccgoto_signalParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_541(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_541_(Stack),
 yeccgoto_signalsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_542: see yeccpars2_4

yeccpars2_543(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_543_(Stack),
 yeccgoto_muxType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_544(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 546, Ss, Stack, T, Ts, Tzr);
yeccpars2_544(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_545(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_545_(Stack),
 yeccgoto_muxDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_546: see yeccpars2_4

yeccpars2_547(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 549, Ss, Stack, T, Ts, Tzr);
yeccpars2_547(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_547_(Stack),
 yeccpars2_548(548, Cat, [547 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_548(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 552, Ss, Stack, T, Ts, Tzr);
yeccpars2_548(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_549: see yeccpars2_4

yeccpars2_550(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 549, Ss, Stack, T, Ts, Tzr);
yeccpars2_550(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_550_(Stack),
 yeccpars2_551(_S, Cat, [550 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_551(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_551_(Stack),
 yeccgoto_terminationIDListRepeat(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_552(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_552_(Stack),
 yeccgoto_terminationIDList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_553: see yeccpars2_4

%% yeccpars2_554: see yeccpars2_4

yeccpars2_555(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_555_(Stack),
 yeccgoto_modemType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_556(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 558, Ss, Stack, T, Ts, Tzr);
yeccpars2_556(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_556_(Stack),
 yeccpars2_557(557, Cat, [556 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_557(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 561, Ss, Stack, T, Ts, Tzr);
yeccpars2_557(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_558: see yeccpars2_4

yeccpars2_559(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 558, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_559_(Stack),
 yeccpars2_560(_S, Cat, [559 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_560(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_560_(Stack),
 yeccgoto_modemTypeList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_561(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 563, Ss, Stack, T, Ts, Tzr);
yeccpars2_561(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_561_(Stack),
 yeccpars2_562(_S, Cat, [561 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_562(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_562_(Stack),
 yeccgoto_modemDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_563: see yeccpars2_4

yeccpars2_564(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 568, Ss, Stack, T, Ts, Tzr);
yeccpars2_564(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_564_(Stack),
 yeccpars2_567(567, Cat, [564 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_565: see yeccpars2_270

yeccpars2_566(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_566_(Stack),
 yeccgoto_propertyParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_567(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 571, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_568: see yeccpars2_4

yeccpars2_569(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 568, Ss, Stack, T, Ts, Tzr);
yeccpars2_569(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_569_(Stack),
 yeccpars2_570(_S, Cat, [569 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_570(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_570_(Stack),
 yeccgoto_propertyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_571(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_571_(Stack),
 yeccgoto_optPropertyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_572(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 563, Ss, Stack, T, Ts, Tzr);
yeccpars2_572(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_572_(Stack),
 yeccpars2_573(_S, Cat, [572 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_573(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_573_(Stack),
 yeccgoto_modemDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_574(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 583, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 584, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_608(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_575(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_575_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_576(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_576_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_577(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_577_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_578(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 640, Ss, Stack, T, Ts, Tzr);
yeccpars2_578(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_578_(Stack),
 yeccpars2_639(639, Cat, [578 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_579_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_580(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 615, Ss, Stack, T, Ts, Tzr);
yeccpars2_580(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_581(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_581_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_582(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_582_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_583(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 606, Ss, Stack, T, Ts, Tzr);
yeccpars2_583(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_584(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 585, Ss, Stack, T, Ts, Tzr);
yeccpars2_584(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_585(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 590, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 591, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_585(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_586(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 602, Ss, Stack, T, Ts, Tzr);
yeccpars2_586(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_586_(Stack),
 yeccpars2_601(601, Cat, [586 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_587(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_587_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_588(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_588_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_589(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_589_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_590(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 597, Ss, Stack, T, Ts, Tzr);
yeccpars2_590(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_591(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 592, Ss, Stack, T, Ts, Tzr);
yeccpars2_591(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_592(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 594, Ss, Stack, T, Ts, Tzr);
yeccpars2_592(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 595, Ss, Stack, T, Ts, Tzr);
yeccpars2_592(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 596, Ss, Stack, T, Ts, Tzr);
yeccpars2_592(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_593(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_593_(Stack),
 yeccgoto_serviceStates(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_594(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_594_(Stack),
 yeccgoto_serviceState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_595(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_595_(Stack),
 yeccgoto_serviceState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_596(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_596_(Stack),
 yeccgoto_serviceState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_597(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 599, Ss, Stack, T, Ts, Tzr);
yeccpars2_597(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 600, Ss, Stack, T, Ts, Tzr);
yeccpars2_597(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_598(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_598_(Stack),
 yeccgoto_eventBufferControl(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_599(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_599_(Stack),
 yeccgoto_eventBufferControlState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_600(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_600_(Stack),
 yeccgoto_eventBufferControlState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_601(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 605, Ss, Stack, T, Ts, Tzr);
yeccpars2_601(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_602: see yeccpars2_585

yeccpars2_603(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 602, Ss, Stack, T, Ts, Tzr);
yeccpars2_603(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_603_(Stack),
 yeccpars2_604(_S, Cat, [603 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_604_(Stack),
 yeccgoto_terminationStateParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_605(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_605_(Stack),
 yeccgoto_terminationStateDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_606: see yeccpars2_4

yeccpars2_607(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 608, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_608(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 580, Ss, Stack, T, Ts, Tzr);
yeccpars2_608(S, 'LocalDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 581, Ss, Stack, T, Ts, Tzr);
yeccpars2_608(S, 'RemoteDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 582, Ss, Stack, T, Ts, Tzr);
yeccpars2_608(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_609(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 611, Ss, Stack, T, Ts, Tzr);
yeccpars2_609(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_609_(Stack),
 yeccpars2_610(610, Cat, [609 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_610(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 614, Ss, Stack, T, Ts, Tzr);
yeccpars2_610(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_611: see yeccpars2_608

yeccpars2_612(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 611, Ss, Stack, T, Ts, Tzr);
yeccpars2_612(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_612_(Stack),
 yeccpars2_613(_S, Cat, [612 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_613(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_613_(Stack),
 yeccgoto_streamParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_614(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_614_(Stack),
 yeccgoto_streamDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_615(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 618, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 619, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 620, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_616(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_616_(Stack),
 yeccgoto_localParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_617(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 635, Ss, Stack, T, Ts, Tzr);
yeccpars2_617(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_617_(Stack),
 yeccpars2_634(634, Cat, [617 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_618(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 627, Ss, Stack, T, Ts, Tzr);
yeccpars2_618(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_619(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 625, Ss, Stack, T, Ts, Tzr);
yeccpars2_619(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_620(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 621, Ss, Stack, T, Ts, Tzr);
yeccpars2_620(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_621(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 623, Ss, Stack, T, Ts, Tzr);
yeccpars2_621(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 624, Ss, Stack, T, Ts, Tzr);
yeccpars2_621(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_622(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_622_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_623(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_623_(Stack),
 yeccgoto_onOrOff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_624(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_624_(Stack),
 yeccgoto_onOrOff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_625: see yeccpars2_621

yeccpars2_626(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_626_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_627(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 629, Ss, Stack, T, Ts, Tzr);
yeccpars2_627(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 630, Ss, Stack, T, Ts, Tzr);
yeccpars2_627(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 631, Ss, Stack, T, Ts, Tzr);
yeccpars2_627(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 632, Ss, Stack, T, Ts, Tzr);
yeccpars2_627(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 633, Ss, Stack, T, Ts, Tzr);
yeccpars2_627(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_628(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_628_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_629(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_629_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_630(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_630_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_631(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_631_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_632(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_632_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_633(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_633_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_634(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 638, Ss, Stack, T, Ts, Tzr);
yeccpars2_634(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_635: see yeccpars2_615

yeccpars2_636(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 635, Ss, Stack, T, Ts, Tzr);
yeccpars2_636(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_636_(Stack),
 yeccpars2_637(_S, Cat, [636 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_637(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_637_(Stack),
 yeccgoto_localParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_638(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_638_(Stack),
 yeccgoto_localControlDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_639(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 643, Ss, Stack, T, Ts, Tzr);
yeccpars2_639(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_640: see yeccpars2_574

yeccpars2_641(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 640, Ss, Stack, T, Ts, Tzr);
yeccpars2_641(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_641_(Stack),
 yeccpars2_642(_S, Cat, [641 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_642(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_642_(Stack),
 yeccgoto_mediaParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_643(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_643_(Stack),
 yeccgoto_mediaDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_644: see yeccpars2_4

yeccpars2_645(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 646, Ss, Stack, T, Ts, Tzr);
yeccpars2_645(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_646: see yeccpars2_4

yeccpars2_647(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 700, Ss, Stack, T, Ts, Tzr);
yeccpars2_647(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_647_(Stack),
 yeccpars2_699(699, Cat, [647 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_648(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 650, Ss, Stack, T, Ts, Tzr);
yeccpars2_648(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_648_(Stack),
 yeccpars2_649(_S, Cat, [648 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_649(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_649_(Stack),
 yeccgoto_requestedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_650(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 656, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 657, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 658, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_651(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_652(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 695, Ss, Stack, T, Ts, Tzr);
yeccpars2_652(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_652_(Stack),
 yeccpars2_694(694, Cat, [652 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_655(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_656_(Stack),
 yeccgoto_eventDM(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_657(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 659, Ss, Stack, T, Ts, Tzr);
yeccpars2_657(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_658(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_658_COMMA(Stack),
 yeccgoto_eventParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_658(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_658_RBRKT(Stack),
 yeccgoto_eventParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_658(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_659(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 662, Ss, Stack, T, Ts, Tzr);
yeccpars2_659(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 522, Ss, Stack, T, Ts, Tzr);
yeccpars2_659(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_660(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 690, Ss, Stack, T, Ts, Tzr);
yeccpars2_660(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 691, Ss, Stack, T, Ts, Tzr);
yeccpars2_660(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_661(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 689, Ss, Stack, T, Ts, Tzr);
yeccpars2_661(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_662(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 663, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_662_(Stack),
 yeccgoto_embedFirst(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_663: see yeccpars2_4

yeccpars2_664(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 665, Ss, Stack, T, Ts, Tzr);
yeccpars2_664(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_665: see yeccpars2_4

yeccpars2_666(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 685, Ss, Stack, T, Ts, Tzr);
yeccpars2_666(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_666_(Stack),
 yeccpars2_684(684, Cat, [666 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_667(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 669, Ss, Stack, T, Ts, Tzr);
yeccpars2_667(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_667_(Stack),
 yeccpars2_668(_S, Cat, [667 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_668(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_668_(Stack),
 yeccgoto_secondRequestedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_669(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 656, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 674, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 675, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_669(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_670(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 680, Ss, Stack, T, Ts, Tzr);
yeccpars2_670(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_670_(Stack),
 yeccpars2_679(679, Cat, [670 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_671(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_672(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_673(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_674(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 676, Ss, Stack, T, Ts, Tzr);
yeccpars2_674(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_675(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_675_COMMA(Stack),
 yeccgoto_secondEventParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_675(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_675_RBRKT(Stack),
 yeccgoto_secondEventParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_675(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_676(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 522, Ss, Stack, T, Ts, Tzr);
yeccpars2_676(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_677(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 678, Ss, Stack, T, Ts, Tzr);
yeccpars2_677(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_678(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_678_(Stack),
 yeccgoto_embedSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_679(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 683, Ss, Stack, T, Ts, Tzr);
yeccpars2_679(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_680: see yeccpars2_669

yeccpars2_681(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 680, Ss, Stack, T, Ts, Tzr);
yeccpars2_681(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_681_(Stack),
 yeccpars2_682(_S, Cat, [681 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_682(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_682_(Stack),
 yeccgoto_secondEventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_683(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_683_(Stack),
 yeccgoto_secondRequestedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_684(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 688, Ss, Stack, T, Ts, Tzr);
yeccpars2_684(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_685: see yeccpars2_4

yeccpars2_686(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 685, Ss, Stack, T, Ts, Tzr);
yeccpars2_686(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_686_(Stack),
 yeccpars2_687(_S, Cat, [686 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_687(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_687_(Stack),
 yeccgoto_secondRequestedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_688(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_688_(Stack),
 yeccgoto_embedFirst(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_689(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_689_(Stack),
 yeccgoto_embedNoSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_690(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 662, Ss, Stack, T, Ts, Tzr);
yeccpars2_690(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_691(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_691_(Stack),
 yeccgoto_embedWithSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_692(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 693, Ss, Stack, T, Ts, Tzr);
yeccpars2_692(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_693(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_693_(Stack),
 yeccgoto_embedWithSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_694(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 698, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_695: see yeccpars2_650

yeccpars2_696(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 695, Ss, Stack, T, Ts, Tzr);
yeccpars2_696(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_696_(Stack),
 yeccpars2_697(_S, Cat, [696 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_697(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_697_(Stack),
 yeccgoto_eventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_698(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_698_(Stack),
 yeccgoto_requestedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_699(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 703, Ss, Stack, T, Ts, Tzr);
yeccpars2_699(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_700: see yeccpars2_4

yeccpars2_701(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 700, Ss, Stack, T, Ts, Tzr);
yeccpars2_701(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_701_(Stack),
 yeccpars2_702(_S, Cat, [701 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_702(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_702_(Stack),
 yeccgoto_requestedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_703(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_703_(Stack),
 yeccgoto_eventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_704(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_704(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 458, Ss, Stack, T, Ts, Tzr);
yeccpars2_704(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_704_(Stack),
 yeccpars2_4(456, Cat, [704 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_705(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_705_(Stack),
 yeccgoto_eventSpec(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_706(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 708, Ss, Stack, T, Ts, Tzr);
yeccpars2_706(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_706_(Stack),
 yeccpars2_707(707, Cat, [706 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_707(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 711, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_708(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_708(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 458, Ss, Stack, T, Ts, Tzr);
yeccpars2_708(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_708_(Stack),
 yeccpars2_4(456, Cat, [708 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_709(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 708, Ss, Stack, T, Ts, Tzr);
yeccpars2_709(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_709_(Stack),
 yeccpars2_710(_S, Cat, [709 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_710(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_710_(Stack),
 yeccgoto_eventSpecList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_711(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_711_(Stack),
 yeccgoto_eventBufferDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_712(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 716, Ss, Stack, T, Ts, Tzr);
yeccpars2_712(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_713: see yeccpars2_506

yeccpars2_714(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 713, Ss, Stack, T, Ts, Tzr);
yeccpars2_714(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_714_(Stack),
 yeccpars2_715(_S, Cat, [714 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_715(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_715_(Stack),
 yeccgoto_ammParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_716(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_716_(Stack),
 yeccgoto_ammRequestBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_717(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 721, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_718: see yeccpars2_161

yeccpars2_719(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 718, Ss, Stack, T, Ts, Tzr);
yeccpars2_719(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_719_(Stack),
 yeccpars2_720(_S, Cat, [719 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_720(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_720_(Stack),
 yeccgoto_actionRequestList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_721(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_721_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_722(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 728, Ss, Stack, T, Ts, Tzr);
yeccpars2_722(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_723(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_723_(Stack),
 yeccgoto_transactionID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_724: see yeccpars2_161

yeccpars2_725(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 718, Ss, Stack, T, Ts, Tzr);
yeccpars2_725(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_725_(Stack),
 yeccpars2_726(726, Cat, [725 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_726(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 727, Ss, Stack, T, Ts, Tzr);
yeccpars2_726(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_727(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_727_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_728: see yeccpars2_161

yeccpars2_729(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 718, Ss, Stack, T, Ts, Tzr);
yeccpars2_729(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_729_(Stack),
 yeccpars2_730(730, Cat, [729 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_730(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 731, Ss, Stack, T, Ts, Tzr);
yeccpars2_730(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_731(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_731_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_732: see yeccpars2_4

yeccpars2_733(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 736, Ss, Stack, T, Ts, Tzr);
yeccpars2_733(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_733_(Stack),
 yeccpars2_735(735, Cat, [733 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_734(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_734_(Stack),
 yeccgoto_transactionAck(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_735(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 739, Ss, Stack, T, Ts, Tzr);
yeccpars2_735(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_736: see yeccpars2_4

yeccpars2_737(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 736, Ss, Stack, T, Ts, Tzr);
yeccpars2_737(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_737_(Stack),
 yeccpars2_738(_S, Cat, [737 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_738(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_738_(Stack),
 yeccgoto_transactionAckList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_739(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_739_(Stack),
 yeccgoto_transactionResponseAck(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_740: see yeccpars2_4

yeccpars2_741(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 742, Ss, Stack, T, Ts, Tzr);
yeccpars2_741(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_742(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 744, Ss, Stack, T, Ts, Tzr);
yeccpars2_742(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_742_(Stack),
 yeccpars2_743(743, Cat, [742 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_743(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 749, Ss, Stack, T, Ts, Tzr);
yeccpars2_743(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_743(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_744(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 745, Ss, Stack, T, Ts, Tzr);
yeccpars2_744(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_745(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_745_(Stack),
 yeccgoto_optImmAckRequired(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_746(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 881, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_747(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_747_(Stack),
 yeccgoto_transactionReplyBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_748(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 878, Ss, Stack, T, Ts, Tzr);
yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_748_(Stack),
 yeccpars2_877(_S, Cat, [748 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_749(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 750, Ss, Stack, T, Ts, Tzr);
yeccpars2_749(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_750: see yeccpars2_4

yeccpars2_751(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 752, Ss, Stack, T, Ts, Tzr);
yeccpars2_751(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_752(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 762, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 763, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 764, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 184, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 185, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 765, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 766, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 767, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 189, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 768, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 769, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 192, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_753(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_753_(Stack),
 yeccgoto_commandReply(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_754(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_754_(Stack),
 yeccgoto_commandReply(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_755(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_755_(Stack),
 yeccgoto_actionReplyBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_756(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_756_(Stack),
 yeccgoto_commandReply(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_757(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 873, Ss, Stack, T, Ts, Tzr);
yeccpars2_757(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_757_(Stack),
 yeccpars2_872(_S, Cat, [757 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_758(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_758_(Stack),
 yeccgoto_commandReply(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_759(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 866, Ss, Stack, T, Ts, Tzr);
yeccpars2_759(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_760(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_760_(Stack),
 yeccgoto_commandReply(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_761(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 865, Ss, Stack, T, Ts, Tzr);
yeccpars2_761(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_762(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_762_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_763(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 861, Ss, Stack, T, Ts, Tzr);
yeccpars2_763(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_764(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 801, Ss, Stack, T, Ts, Tzr);
yeccpars2_764(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_765(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_765_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_766(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_766_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_767(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 795, Ss, Stack, T, Ts, Tzr);
yeccpars2_767(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_768(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 770, Ss, Stack, T, Ts, Tzr);
yeccpars2_768(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_769(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_769_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_770: see yeccpars2_4

yeccpars2_771(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 773, Ss, Stack, T, Ts, Tzr);
yeccpars2_771(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_771_(Stack),
 yeccpars2_772(_S, Cat, [771 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_772(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_772_(Stack),
 yeccgoto_serviceChangeReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_773(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_773(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 776, Ss, Stack, T, Ts, Tzr);
yeccpars2_773(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_774(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 794, Ss, Stack, T, Ts, Tzr);
yeccpars2_774(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_775(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 793, Ss, Stack, T, Ts, Tzr);
yeccpars2_775(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_776(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 777, Ss, Stack, T, Ts, Tzr);
yeccpars2_776(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_777(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 784, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 785, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 786, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 458, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 787, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_778(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_778_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_779(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_779_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_780(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_780_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_781(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_781_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_782(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_782_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_783(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 789, Ss, Stack, T, Ts, Tzr);
yeccpars2_783(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_783_(Stack),
 yeccpars2_788(788, Cat, [783 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_784(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 430, Ss, Stack, T, Ts, Tzr);
yeccpars2_784(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_785(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 428, Ss, Stack, T, Ts, Tzr);
yeccpars2_785(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_786(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 423, Ss, Stack, T, Ts, Tzr);
yeccpars2_786(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_787(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_787(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_788(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 792, Ss, Stack, T, Ts, Tzr);
yeccpars2_788(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_789: see yeccpars2_777

yeccpars2_790(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 789, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_790_(Stack),
 yeccpars2_791(_S, Cat, [790 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_791(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_791_(Stack),
 yeccgoto_servChgReplyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_792(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_792_(Stack),
 yeccgoto_serviceChangeReplyDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_793(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_793_(Stack),
 yeccgoto_serviceChangeReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_794(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_794_(Stack),
 yeccgoto_serviceChangeReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_795: see yeccpars2_4

yeccpars2_796(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 798, Ss, Stack, T, Ts, Tzr);
yeccpars2_796(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_796_(Stack),
 yeccpars2_797(_S, Cat, [796 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_797(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_797_(Stack),
 yeccgoto_notifyReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_798(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_798(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_799(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 800, Ss, Stack, T, Ts, Tzr);
yeccpars2_799(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_800(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_800_(Stack),
 yeccgoto_notifyReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_801(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 804, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_802(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 818, Ss, Stack, T, Ts, Tzr);
yeccpars2_802(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_802_(Stack),
 yeccgoto_auditOther(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_803(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_803_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_804(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 807, Ss, Stack, T, Ts, Tzr);
yeccpars2_804(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_805(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_805_(Stack),
 yeccgoto_contextTerminationAudit(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_806(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_806_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_807(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 809, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_808(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 817, Ss, Stack, T, Ts, Tzr);
yeccpars2_808(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_809(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 810, Ss, Stack, T, Ts, Tzr);
yeccpars2_809(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_810: see yeccpars2_4

yeccpars2_811(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_811_(Stack),
 yeccgoto_errorCode(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_812(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 813, Ss, Stack, T, Ts, Tzr);
yeccpars2_812(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_813(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 815, Ss, Stack, T, Ts, Tzr);
yeccpars2_813(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_813_(Stack),
 yeccpars2_814(814, Cat, [813 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_814(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 816, Ss, Stack, T, Ts, Tzr);
yeccpars2_814(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_815(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_815_(Stack),
 yeccgoto_errorText(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_816(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_816_(Stack),
 yeccgoto_errorDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_817(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_817_(Stack),
 yeccgoto_contextTerminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_818(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 516, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 237, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 517, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 518, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 833, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 834, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 835, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 836, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 837, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 522, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 838, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_819(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 860, Ss, Stack, T, Ts, Tzr);
yeccpars2_819(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_820(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_820_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_821(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_821_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_822(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_822_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_823(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_823_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_824(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_824_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_825(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_825_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_826(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_826_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_827(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_827_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_828(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_828_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_829(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_829_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_830(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_830_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_831(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 857, Ss, Stack, T, Ts, Tzr);
yeccpars2_831(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_831_(Stack),
 yeccpars2_856(_S, Cat, [831 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_832(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_832_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_833(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 574, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_833_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_834(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 553, Ss, Stack, T, Ts, Tzr);
yeccpars2_834(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 554, Ss, Stack, T, Ts, Tzr);
yeccpars2_834(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_834_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_835(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 542, Ss, Stack, T, Ts, Tzr);
yeccpars2_835(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_835_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_836(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 452, Ss, Stack, T, Ts, Tzr);
yeccpars2_836(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_836_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_837(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 849, Ss, Stack, T, Ts, Tzr);
yeccpars2_837(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_837_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_838(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 839, Ss, Stack, T, Ts, Tzr);
yeccpars2_838(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_838_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_839: see yeccpars2_4

yeccpars2_840(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 845, Ss, Stack, T, Ts, Tzr);
yeccpars2_840(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_840_(Stack),
 yeccpars2_844(844, Cat, [840 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_841(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 842, Ss, Stack, T, Ts, Tzr);
yeccpars2_841(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_841_(Stack),
 yeccgoto_statisticsParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_842: see yeccpars2_299

yeccpars2_843(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_843_(Stack),
 yeccgoto_statisticsParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_844(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 848, Ss, Stack, T, Ts, Tzr);
yeccpars2_844(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_845: see yeccpars2_4

yeccpars2_846(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 845, Ss, Stack, T, Ts, Tzr);
yeccpars2_846(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_846_(Stack),
 yeccpars2_847(_S, Cat, [846 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_847(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_847_(Stack),
 yeccgoto_statisticsParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_848(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_848_(Stack),
 yeccgoto_statisticsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_849: see yeccpars2_4

yeccpars2_850(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 852, Ss, Stack, T, Ts, Tzr);
yeccpars2_850(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_850_(Stack),
 yeccpars2_851(851, Cat, [850 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_851(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 855, Ss, Stack, T, Ts, Tzr);
yeccpars2_851(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_852: see yeccpars2_4

yeccpars2_853(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 852, Ss, Stack, T, Ts, Tzr);
yeccpars2_853(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_853_(Stack),
 yeccpars2_854(_S, Cat, [853 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_854(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_854_(Stack),
 yeccgoto_packagesItems(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_855(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_855_(Stack),
 yeccgoto_packagesDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_856(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_856_(Stack),
 yeccgoto_terminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_857: see yeccpars2_818

yeccpars2_858(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 857, Ss, Stack, T, Ts, Tzr);
yeccpars2_858(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_858_(Stack),
 yeccpars2_859(_S, Cat, [858 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_859_(Stack),
 yeccgoto_auditReturnParameterList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_860(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_860_(Stack),
 yeccgoto_auditOther(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_861(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 863, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 117, Ss, Stack, T, Ts, Tzr);
yeccpars2_861(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_862_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_863(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 807, Ss, Stack, T, Ts, Tzr);
yeccpars2_863(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_864(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_864_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_865(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_865_(Stack),
 yeccgoto_actionReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_866: see yeccpars2_4

yeccpars2_867(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 869, Ss, Stack, T, Ts, Tzr);
yeccpars2_867(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_867_(Stack),
 yeccpars2_868(_S, Cat, [867 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_868(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_868_(Stack),
 yeccgoto_ammsReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_869: see yeccpars2_818

yeccpars2_870(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 871, Ss, Stack, T, Ts, Tzr);
yeccpars2_870(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_871(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_871_(Stack),
 yeccgoto_ammsReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_872(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_872_(Stack),
 yeccgoto_actionReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_873: see yeccpars2_752

yeccpars2_874(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_874_(Stack),
 yeccgoto_commandReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_875(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 873, Ss, Stack, T, Ts, Tzr);
yeccpars2_875(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_875_(Stack),
 yeccpars2_876(_S, Cat, [875 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_876(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_876_(Stack),
 yeccgoto_commandReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_877(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_877_(Stack),
 yeccgoto_transactionReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_878(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 749, Ss, Stack, T, Ts, Tzr);
yeccpars2_878(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_879(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 878, Ss, Stack, T, Ts, Tzr);
yeccpars2_879(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_879_(Stack),
 yeccpars2_880(_S, Cat, [879 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_880(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_880_(Stack),
 yeccgoto_actionReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_881(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_881_(Stack),
 yeccgoto_transactionReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_882: see yeccpars2_4

yeccpars2_883(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 884, Ss, Stack, T, Ts, Tzr);
yeccpars2_883(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_884(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 885, Ss, Stack, T, Ts, Tzr);
yeccpars2_884(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_885(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_885_(Stack),
 yeccgoto_transactionPending(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_886(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_886_(Stack),
 yeccgoto_transactionList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_887(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_887_(Stack),
 yeccgoto_pathName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_888(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_888_(Stack),
 yeccgoto_deviceName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_889(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_889_(Stack),
 yeccpars2_893(_S, Cat, [889 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_890(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_890(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_890_(Stack),
 yeccpars2_892(_S, Cat, [890 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_891(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_891_(Stack),
 yeccgoto_mtpAddress(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_892(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_892_(Stack),
 yeccgoto_mId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_893(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_893_(Stack),
 yeccgoto_mId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccgoto_actionReply(743, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_748(748, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionReply(878, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_879(879, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionReplyBody(752, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_761(761, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionReplyList(748=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_877(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionReplyList(879=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_880(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequest(161, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_162(162, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(718, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_719(719, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(724, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_725(725, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(728, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_729(729, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestItem(167, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(179, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestItem(499, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_500(500, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestItems(179, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_498(498, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestItems(500=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_501(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestList(162, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_717(717, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(719=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_720(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(725, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_726(726, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(729, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_730(730, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_alternativeValue(298=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_308(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammParameter(506, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_515(515, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammParameter(713, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_714(714, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammParameters(515, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_712(712, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammParameters(714=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_715(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammRequest(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammRequest(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammRequestBody(504=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_505(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammToken(167, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_177(177, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammToken(499, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_177(177, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsReply(752=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_760(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammsReply(873=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_760(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsReplyBody(867=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_868(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsToken(752, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_759(759, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammsToken(873, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_759(759, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditDescriptor(220, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_221(221, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditDescriptor(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_514(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditDescriptor(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_514(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditDescriptorBody(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_235(235, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditItem(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_234(234, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(380, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_381(381, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_412(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_412(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditItemList(234=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_379(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItemList(381=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_382(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditOther(801=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_803(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditOther(861=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReply(752=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_758(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReply(873=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_758(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditRequest(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditRequest(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnItem(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_233(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(380=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_233(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_233(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_233(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_832(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_832(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_832(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnParameter(818, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_831(831, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameter(857, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_858(858, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameter(869, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_831(831, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnParameterList(831=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_856(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameterList(858=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_authenticationHeader(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandReply(752, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_757(757, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandReply(873, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_875(875, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandReplyList(757=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_872(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandReplyList(875=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_876(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandRequest(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandRequest(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAudit(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAudit(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAuditProperties(483, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_487(487, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperties(489=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_490(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAuditProperty(482, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_483(483, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperty(488, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_489(489, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextID(164, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(166, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextID(750, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_751(751, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextProperty(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_173(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_173(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(752=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_756(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(873=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_756(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextTerminationAudit(804=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_806(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextTerminationAudit(863=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_864(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_daddr(131, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_133(133, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_daddr(132=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_141(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_daddr(134=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_deviceName(126, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_890(890, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_digitMapDescriptor(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_513(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_513(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_830(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_830(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_830(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_domainAddress(123=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainAddress(423=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainAddress(430=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_domainName(123=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainName(423=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainName(430=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedFirst(659, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_661(661, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedFirst(690, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_692(692, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedNoSig(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_655(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedNoSig(695=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_655(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedSig(669=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_673(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedSig(680=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_673(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedWithSig(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedWithSig(695=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorCode(810, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_812(812, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorDescriptor(127=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(447=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_450(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(743=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_747(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(752=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_755(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(773, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_775(775, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(798, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_799(799, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(807, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_808(808, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_829(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_829(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_829(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(873=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_874(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorText(813, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_814(814, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferControl(585=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_589(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferControl(602=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_589(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferControlState(597=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_598(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferDescriptor(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_512(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_512(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_828(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_828(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_828(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventDM(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(669=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_672(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(680=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_672(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(695=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameter(650, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_652(652, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameter(695, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_696(696, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameterName(371=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_375(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(466, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(469, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(472, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(469, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(650, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(469, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(669, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(469, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(680, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(469, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(695, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(469, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameters(652, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_694(694, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameters(696=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_697(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventSpec(704, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_706(706, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventSpec(708, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_709(709, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventSpecList(706, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_707(707, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventSpecList(709=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_710(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventStream(206=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_207(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStream(371=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventStreamOrOther(466=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_468(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(472=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_468(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_651(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(669=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_671(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(680=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_671(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(695=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_651(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventsDescriptor(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_511(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_511(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_827(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_827(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_827(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_extension(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_411(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_extension(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_411(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_extensionParameter(399, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(410, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_extensionParameter(438, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(410, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudauditReturnParameter(223, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(232, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(380, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(232, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(384, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_385(385, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(399, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(232, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(438, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(232, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAuddigitMapDescriptor(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_231(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(380=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_231(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(384=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_231(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_231(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_231(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventBufferDescriptor(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(380=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(384=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventSpec(366, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_368(368, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventSpecParameter(371, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_373(373, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventsDescriptor(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(380=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(384=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalControlDescriptor(332=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_337(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalControlDescriptor(347=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_337(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalParm(350, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_352(352, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalParm(354, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_355(355, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalParmList(352, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_353(353, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalParmList(355=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_356(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaDescriptor(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(380=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(384=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaParm(332, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_336(336, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudpackagesDescriptor(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(380=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(384=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudrequestedEvent(362, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_364(364, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalList(252=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_257(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalParm(252, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_256(256, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalsDescriptor(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(380=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(384=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstatisticsDescriptor(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_225(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(380=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_225(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(384=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_225(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_225(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_225(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstreamDescriptor(332=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_335(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstreamParm(332=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_334(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstreamParm(347, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_348(348, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationAudit(223=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(380=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationAuditList(232=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_383(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAuditList(385=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_392(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationStateDescriptor(332=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_333(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationStateParm(341, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_343(343, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localControlDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(608=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(611=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(640=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localParm(615, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_617(617, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localParm(635, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_636(636, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localParmList(617, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_634(634, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localParmList(636=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_637(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mId(123, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mId(423=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_425(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mId(430=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_431(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaDescriptor(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_510(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_510(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_826(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_826(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_826(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaParm(574, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_578(578, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaParm(640, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_641(641, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaParmList(578, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_639(639, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaParmList(641=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_642(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_megacoMessage(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_message(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(124, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_messageBody(127=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemDescriptor(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_509(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_509(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_825(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_825(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_825(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemType(553, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_572(572, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemType(554, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_556(556, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemType(558, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_559(559, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemTypeList(556, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_557(557, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemTypeList(559=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_560(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mtpAddress(126, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_889(889, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_muxDescriptor(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_508(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_508(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_824(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_824(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_824(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_muxType(542, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_544(544, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notificationReason(284, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_285(285, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notificationReason(291, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(292, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notificationReasons(285, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_290(290, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notificationReasons(292=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_293(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyReply(752=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_754(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyReply(873=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_754(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyReplyBody(796=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_797(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyRequest(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_172(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyRequest(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_172(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyRequestBody(447, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_449(449, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEvent(454, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_457(457, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(460, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_461(461, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(704=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_705(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(708=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_705(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventBody(464=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_465(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventBody(479=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_480(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventParameter(466, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_467(467, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventParameter(472, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_473(473, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventParameters(467, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_471(471, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventParameters(473=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_474(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEvents(457, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_459(459, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvents(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_462(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventsDescriptor(447=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_448(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_823(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_823(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_823(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_onOrOff(621=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_622(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_onOrOff(625=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_626(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optAuditDescriptor(218=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_219(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optAuditDescriptor(493=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_494(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optAuditDescriptor(496=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_497(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optImmAckRequired(742, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_743(743, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optIndAudeventSpecParameter(367=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_370(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optIndAudsignalParm(245=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_251(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optIndAudsignalParm(390=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_251(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optPropertyParms(561=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_562(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optPropertyParms(572=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_573(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optSep(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(121=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(123, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(139=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(145=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(423, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(430, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(126, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(454, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(456, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(455, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_476(476, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(460, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(456, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(477, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(478, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(704, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(456, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(708, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(456, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(889=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_893(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(890=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_892(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_822(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_822(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_822(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesItem(328, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_330(330, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItem(849, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_850(850, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItem(852, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_853(853, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesItems(850, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_851(851, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItems(853=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_854(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_parmValue(270=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(410=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_436(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(469=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_470(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(565=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_566(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_pathName(126=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_888(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_pkgdName(247, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_249(249, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(252=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(362=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_363(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(366, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_367(367, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(456, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_464(464, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(478, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_479(479, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(523=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(530=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(533=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(563, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(565, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(568, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(565, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(585, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(565, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(602, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(565, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(615, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(565, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(635, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(565, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(646, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_648(648, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(665, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_667(667, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(685, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_667(667, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(700, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_648(648, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(839, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_841(841, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(845, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_841(841, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_portNumber(137, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_139(139, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_portNumber(144, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_145(145, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_portNumber(423=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_424(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_priority(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(752=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(873=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParm(563, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_564(564, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(568, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_569(569, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(585=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_588(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(602=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_588(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(615=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_616(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(635=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_616(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParms(564, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_567(567, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParms(569=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_570(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestID(359, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_361(361, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(452, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_453(453, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(644, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_645(645, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(663, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_664(664, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEvent(646, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_647(647, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestedEvent(700, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_701(701, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEventBody(648=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_649(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEvents(647, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_699(699, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestedEvents(701=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_702(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_safeToken(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(123, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(6, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(118, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(119, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(120, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(121, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(126=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_887(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(130, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(142, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(131, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(132, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(132, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(132, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(134, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(132, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(137=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(144=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(160=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_723(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(164=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(193=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(209=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(213=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(217=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(247=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(252=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(260=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(268, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(270, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(295=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_296(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(298=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(299=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(300=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(301=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(309=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(310=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(313=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(314=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(324, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(270, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(328=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(341=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_342(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(345=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(350=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_351(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_351(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(359=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_360(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(362=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(366=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(371=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(394=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_409(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_422(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(423=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(426=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(428=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_429(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(432=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(434=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_435(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_409(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(443=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_444(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(445=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(452=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_360(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(456=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(466=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(472=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(478=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(492=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(495=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(503=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(523=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(528=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(530=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(533=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(542=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_543(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(546=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(549=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(553=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_555(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(554=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_555(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(558=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_555(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(563=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(585=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(602=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(606=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(615=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(635=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(644=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_360(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(646=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(663=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_360(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(665=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(669=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(680=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(685=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(695=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(700=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(732=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_734(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(736=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_734(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(740=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_723(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(750=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(770=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(795=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(801=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(807=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(810=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_811(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(839=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(842=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(845=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(849=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(852=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(861=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(866=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(882=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_723(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_safeToken2(4=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(6=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(120=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(126=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(130=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(131=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(132=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(134=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(137=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(144=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(160=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(164=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(193=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(209=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(213=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(217=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(247=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(252=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(260=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(268=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(295=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(298=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(299=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(300=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(301=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(309=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(310=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(313=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(314=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(324=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(328=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(341=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(345=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(350=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(354=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(359=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(362=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(366=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(371=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(394=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(423=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(426=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(428=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(432=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(434=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(443=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(445=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(452=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(456=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(466=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(472=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(478=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(492=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(495=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(503=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(523=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(528=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(530=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(533=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(542=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(546=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(549=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(553=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(554=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(558=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(563=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(585=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(602=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(606=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(615=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(635=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(644=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(646=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(663=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(665=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(669=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(680=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(685=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(695=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(700=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(732=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(736=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(740=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(750=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(770=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(795=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(801=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(807=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(810=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(839=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(842=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(845=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(849=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(852=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(861=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(866=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(882=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondEventParameter(669, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_670(670, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondEventParameter(680, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_681(681, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondEventParameters(670, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_679(679, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondEventParameters(681=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_682(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEvent(665, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_666(666, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondRequestedEvent(685, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_686(686, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEventBody(667=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_668(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEvents(666, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_684(684, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondRequestedEvents(686=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_687(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_servChgReplyParm(777, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_783(783, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_servChgReplyParm(789, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_790(790, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_servChgReplyParms(783, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_788(788, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_servChgReplyParms(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_791(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeAddress(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_408(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_408(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_782(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(789=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_782(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeDelay(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_407(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeDelay(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_407(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeDescriptor(396, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_397(397, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeMethod(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_406(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMethod(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_406(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeMgcId(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_405(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_405(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_781(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(789=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_781(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeParm(399, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_404(404, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeParm(438, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_439(439, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeParms(404, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_437(437, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeParms(439=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_440(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeProfile(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_780(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(789=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_780(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReason(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeReason(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReply(752=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_753(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeReply(873=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_753(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReplyBody(771=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_772(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReplyDescriptor(773, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_774(774, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeRequest(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_170(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeRequest(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_170(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeVersion(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_779(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(789=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_779(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceState(592=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_593(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceStates(585=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_587(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceStates(602=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_587(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_sigParameter(268, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_269(269, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sigParameter(324, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_325(325, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_sigParameters(269, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_323(323, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sigParameters(325=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_326(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalList(523=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_526(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalList(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_526(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListId(260, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_261(261, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListId(528, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_529(529, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListParm(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_265(265, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParm(530, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_531(531, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParm(533, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_534(534, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListParms(531, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_532(532, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParms(534=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_535(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalName(252, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(254, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(263, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(254, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(523, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(254, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(530, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(254, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(533, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(254, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(538, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(254, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalParm(523, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_525(525, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalParm(538, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_539(539, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalParms(525, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_537(537, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalParms(539=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_540(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalRequest(252=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_253(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(263=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(523=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_524(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(530=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(533=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_524(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalType(278=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_279(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalsDescriptor(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_507(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(659, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_660(660, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(676, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_677(677, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_507(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_821(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_821(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_821(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsDescriptor(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_820(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(857=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_820(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_820(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsParameter(839, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_840(840, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsParameter(845, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_846(846, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsParameters(840, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_844(844, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsParameters(846=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_847(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_577(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamDescriptor(640=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_577(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamID(209=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(276=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_277(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(345, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_346(346, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(606, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_607(607, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamModes(627=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_628(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamParm(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_576(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(608, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_609(609, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(611, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_612(612, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(640=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_576(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamParmList(609, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_610(610, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParmList(612=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_613(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_subtractRequest(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_169(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_subtractRequest(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_169(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationA(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_196(196, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationA(213, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_196(196, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationAudit(818, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_819(819, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationAudit(869, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_870(870, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationB(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(200, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationID(193=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_195(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(213=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_195(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(217, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_218(218, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(394, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_395(395, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(445, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_446(446, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(492, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_493(493, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(495, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_496(496, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(503, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_504(504, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(546, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_547(547, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(549, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_550(550, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(770, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_771(771, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(795, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_796(796, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(801, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_802(802, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(807, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_547(547, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(861, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_802(802, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(866, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_867(867, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationIDList(544=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_545(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDList(804=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_805(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDList(863=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_805(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationIDListRepeat(547, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_548(548, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDListRepeat(550=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_551(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_575(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateDescriptor(640=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_575(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateParm(585, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_586(586, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateParm(602, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_603(603, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateParms(586, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_601(601, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateParms(603=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_timeStamp(399=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_400(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(438=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_400(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(454, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_455(455, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(460, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_455(455, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(704, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_455(455, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(708, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_455(455, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_778(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(789=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_778(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDescriptor(167=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(752=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(873=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDirection(201, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(202, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyTriple(193, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_194(194, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyTriple(213, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(214, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyTripleList(194, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(212, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyTripleList(214=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionAck(732, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_733(733, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionAck(736, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_737(737, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionAckList(733, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_735(735, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionAckList(737=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_738(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionID(160, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_722(722, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionID(740, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_741(741, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionID(882, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_883(883, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionItem(127, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_152(152, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionItem(152, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_152(152, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionList(127=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_151(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionList(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_886(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionPending(127=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionPending(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionReply(127=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_149(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionReply(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_149(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionReplyBody(743, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_746(746, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionRequest(127=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_148(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionRequest(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_148(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionResponseAck(127=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_147(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionResponseAck(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_147(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_value(298=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_307(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(299=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_306(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(300=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_305(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(301=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_302(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(309, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_320(320, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(310, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_311(311, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(313, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_317(317, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(314, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_315(315, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(426=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_427(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(842=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_843(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_valueList(311, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_312(312, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_valueList(315=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_316(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_valueList(320, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_321(321, Cat, Ss, Stack, T, Ts, Tzr).

-compile({inline,yeccpars2_0_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_0_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_1_/1}).
-file("megaco_text_parser_v2.yrl", 457).
yeccpars2_1_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_3_/1}).
-file("megaco_text_parser_v2.yrl", 451).
yeccpars2_3_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sep
  end | __Stack].

-compile({inline,yeccpars2_7_/1}).
-file("megaco_text_parser_v2.yrl", 1391).
yeccpars2_7_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   make_safe_token ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_121_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_121_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_122_/1}).
-file("megaco_text_parser_v2.yrl", 456).
yeccpars2_122_(__Stack0) ->
 [__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_auth_header ( __3 , __5 , __7 )
  end | __Stack].

-compile({inline,yeccpars2_123_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_123_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_125_/1}).
-file("megaco_text_parser_v2.yrl", 449).
yeccpars2_125_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'MegacoMessage' { authHeader = __2 , mess = __3 }
  end | __Stack].

-compile({inline,yeccpars2_131_/1}).
-file("megaco_text_parser_v2.yrl", 912).
yeccpars2_131_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_132_/1}).
-file("megaco_text_parser_v2.yrl", 912).
yeccpars2_132_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_134_/1}).
-file("megaco_text_parser_v2.yrl", 912).
yeccpars2_134_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_135_/1}).
-file("megaco_text_parser_v2.yrl", 913).
yeccpars2_135_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ colon | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_136_/1}).
-file("megaco_text_parser_v2.yrl", 910).
yeccpars2_136_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainAddress ( __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_138_/1}).
-file("megaco_text_parser_v2.yrl", 917).
yeccpars2_138_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_139_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_139_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_140_/1}).
-file("megaco_text_parser_v2.yrl", 908).
yeccpars2_140_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainAddress ( __2 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_141_/1}).
-file("megaco_text_parser_v2.yrl", 914).
yeccpars2_141_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_143_/1}).
-file("megaco_text_parser_v2.yrl", 900).
yeccpars2_143_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainName ( __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_145_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_145_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_146_/1}).
-file("megaco_text_parser_v2.yrl", 898).
yeccpars2_146_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainName ( __2 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_147_/1}).
-file("megaco_text_parser_v2.yrl", 470).
yeccpars2_147_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionResponseAck , __1 }
  end | __Stack].

-compile({inline,yeccpars2_148_/1}).
-file("megaco_text_parser_v2.yrl", 467).
yeccpars2_148_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionRequest , __1 }
  end | __Stack].

-compile({inline,yeccpars2_149_/1}).
-file("megaco_text_parser_v2.yrl", 468).
yeccpars2_149_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionReply , __1 }
  end | __Stack].

-compile({inline,yeccpars2_150_/1}).
-file("megaco_text_parser_v2.yrl", 469).
yeccpars2_150_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionPending , __1 }
  end | __Stack].

-compile({inline,yeccpars2_151_/1}).
-file("megaco_text_parser_v2.yrl", 462).
yeccpars2_151_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactions , __1 }
  end | __Stack].

-compile({inline,yeccpars2_152_/1}).
-file("megaco_text_parser_v2.yrl", 464).
yeccpars2_152_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_153_/1}).
-file("megaco_text_parser_v2.yrl", 459).
yeccpars2_153_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_message ( __1 , __2 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_154_/1}).
-file("megaco_text_parser_v2.yrl", 461).
yeccpars2_154_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { messageError , __1 }
  end | __Stack].

-compile({inline,yeccpars2_162_/1}).
-file("megaco_text_parser_v2.yrl", 499).
yeccpars2_162_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_165_/1}).
-file("megaco_text_parser_v2.yrl", 905).
yeccpars2_165_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_contextID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_168_/1}).
-file("megaco_text_parser_v2.yrl", 513).
yeccpars2_168_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { topology , __1 }
  end | __Stack].

-compile({inline,yeccpars2_171_/1}).
-file("megaco_text_parser_v2.yrl", 514).
yeccpars2_171_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { priority , __1 }
  end | __Stack].

-compile({inline,yeccpars2_179_/1}).
-file("megaco_text_parser_v2.yrl", 506).
yeccpars2_179_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_180_/1}).
-file("megaco_text_parser_v2.yrl", 586).
yeccpars2_180_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { addReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_184_/1}).
-file("megaco_text_parser_v2.yrl", 516).
yeccpars2_184_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { emergency , false }
  end | __Stack].

-compile({inline,yeccpars2_185_/1}).
-file("megaco_text_parser_v2.yrl", 515).
yeccpars2_185_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { emergency , true }
  end | __Stack].

-compile({inline,yeccpars2_186_/1}).
-file("megaco_text_parser_v2.yrl", 588).
yeccpars2_186_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { modReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_187_/1}).
-file("megaco_text_parser_v2.yrl", 587).
yeccpars2_187_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { moveReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_194_/1}).
-file("megaco_text_parser_v2.yrl", 1374).
yeccpars2_194_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_197_/1}).
-file("megaco_text_parser_v2.yrl", 933).
yeccpars2_197_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_terminationID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_202_/1}).
-file("megaco_text_parser_v2.yrl", 1370).
yeccpars2_202_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TopologyRequest' { terminationFrom = __1 ,
    terminationTo = __3 ,
    topologyDirection = __5 }
  end | __Stack].

-compile({inline,yeccpars2_203_/1}).
-file("megaco_text_parser_v2.yrl", 1378).
yeccpars2_203_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   bothway
  end | __Stack].

-compile({inline,yeccpars2_204_/1}).
-file("megaco_text_parser_v2.yrl", 1379).
yeccpars2_204_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   isolate
  end | __Stack].

-compile({inline,yeccpars2_205_/1}).
-file("megaco_text_parser_v2.yrl", 1380).
yeccpars2_205_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   oneway
  end | __Stack].

-compile({inline,yeccpars2_207_/1}).
-file("megaco_text_parser_v2.yrl", 1364).
yeccpars2_207_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TopologyRequest' { terminationFrom = __1 ,
    terminationTo = __3 ,
    topologyDirection = __5 ,
    streamID = __7 }
  end | __Stack].

-compile({inline,yeccpars2_210_/1}).
-file("megaco_text_parser_v2.yrl", 840).
yeccpars2_210_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_211_/1}).
-file("megaco_text_parser_v2.yrl", 1069).
yeccpars2_211_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_streamID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_214_/1}).
-file("megaco_text_parser_v2.yrl", 1374).
yeccpars2_214_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_215_/1}).
-file("megaco_text_parser_v2.yrl", 1376).
yeccpars2_215_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_216_/1}).
-file("megaco_text_parser_v2.yrl", 1356).
yeccpars2_216_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_218_/1}).
-file("megaco_text_parser_v2.yrl", 625).
yeccpars2_218_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_219_/1}).
-file("megaco_text_parser_v2.yrl", 619).
yeccpars2_219_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { subtractReq , __1 } ,
    # 'SubtractRequest' { terminationID = [ __3 ] ,
    auditDescriptor = __4 } )
  end | __Stack].

-compile({inline,yeccpars2_223_/1}).
-file("megaco_text_parser_v2.yrl", 683).
yeccpars2_223_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_224_/1}).
-file("megaco_text_parser_v2.yrl", 704).
yeccpars2_224_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { terminationAudit , __1 }
  end | __Stack].

-compile({inline,yeccpars2_225_/1}).
-file("megaco_text_parser_v2.yrl", 737).
yeccpars2_225_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudStatisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_226_/1}).
-file("megaco_text_parser_v2.yrl", 731).
yeccpars2_226_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudSignalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_227_/1}).
-file("megaco_text_parser_v2.yrl", 739).
yeccpars2_227_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudPackagesDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_228_/1}).
-file("megaco_text_parser_v2.yrl", 727).
yeccpars2_228_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudMediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_229_/1}).
-file("megaco_text_parser_v2.yrl", 729).
yeccpars2_229_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudEventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_230_/1}).
-file("megaco_text_parser_v2.yrl", 735).
yeccpars2_230_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudEventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_231_/1}).
-file("megaco_text_parser_v2.yrl", 733).
yeccpars2_231_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudDigitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_232_/1}).
-file("megaco_text_parser_v2.yrl", 724).
yeccpars2_232_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_234_/1}).
-file("megaco_text_parser_v2.yrl", 686).
yeccpars2_234_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_236_/1}).
-file("megaco_text_parser_v2.yrl", 832).
yeccpars2_236_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_IADMD ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_237_/1}).
-file("megaco_text_parser_v2.yrl", 693).
yeccpars2_237_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   digitMapToken
  end | __Stack].

-compile({inline,yeccpars2_238_/1}).
-file("megaco_text_parser_v2.yrl", 702).
yeccpars2_238_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   eventBufferToken
  end | __Stack].

-compile({inline,yeccpars2_239_/1}).
-file("megaco_text_parser_v2.yrl", 703).
yeccpars2_239_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   eventsToken
  end | __Stack].

-compile({inline,yeccpars2_240_/1}).
-file("megaco_text_parser_v2.yrl", 692).
yeccpars2_240_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   mediaToken
  end | __Stack].

-compile({inline,yeccpars2_241_/1}).
-file("megaco_text_parser_v2.yrl", 691).
yeccpars2_241_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modemToken
  end | __Stack].

-compile({inline,yeccpars2_242_/1}).
-file("megaco_text_parser_v2.yrl", 690).
yeccpars2_242_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   muxToken
  end | __Stack].

-compile({inline,yeccpars2_243_/1}).
-file("megaco_text_parser_v2.yrl", 695).
yeccpars2_243_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   observedEventsToken
  end | __Stack].

-compile({inline,yeccpars2_244_/1}).
-file("megaco_text_parser_v2.yrl", 696).
yeccpars2_244_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   packagesToken
  end | __Stack].

-compile({inline,yeccpars2_245_/1}).
-file("megaco_text_parser_v2.yrl", 701).
yeccpars2_245_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   signalsToken
  end | __Stack].

-compile({inline,yeccpars2_246_/1}).
-file("megaco_text_parser_v2.yrl", 694).
yeccpars2_246_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statsToken
  end | __Stack].

-compile({inline,yeccpars2_248_/1}).
-file("megaco_text_parser_v2.yrl", 1071).
yeccpars2_248_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_pkgdName ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_250_/1}).
-file("megaco_text_parser_v2.yrl", 835).
yeccpars2_250_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStatisticsDescriptor' { statName = __3 }
  end | __Stack].

-compile({inline,yeccpars2_251_/1}).
-file("megaco_text_parser_v2.yrl", 814).
yeccpars2_251_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_253_/1}).
-file("megaco_text_parser_v2.yrl", 821).
yeccpars2_253_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signal , ensure_indAudSignal ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_254_/1}).
-file("megaco_text_parser_v2.yrl", 1164).
yeccpars2_254_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_signalRequest ( __1 , [ ] )
  end | __Stack].

-compile({inline,yeccpars2_257_/1}).
-file("megaco_text_parser_v2.yrl", 820).
yeccpars2_257_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { seqSigList , __1 }
  end | __Stack].

-compile({inline,yeccpars2_258_/1}).
-file("megaco_text_parser_v2.yrl", 817).
yeccpars2_258_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   asn1_NOVALUE
  end | __Stack].

-compile({inline,yeccpars2_262_/1}).
-file("megaco_text_parser_v2.yrl", 1214).
yeccpars2_262_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_266_/1}).
-file("megaco_text_parser_v2.yrl", 825).
yeccpars2_266_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudSeqSigList' { id = ensure_uint16 ( __3 ) ,
    signalList =
    ensure_indAudSignalListParm ( __5 ) }
  end | __Stack].

-compile({inline,yeccpars2_267_/1}).
-file("megaco_text_parser_v2.yrl", 818).
yeccpars2_267_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_269_/1}).
-file("megaco_text_parser_v2.yrl", 1167).
yeccpars2_269_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_272_COMMA/1}).
-file("megaco_text_parser_v2.yrl", 1191).
yeccpars2_272_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_272_RBRKT/1}).
-file("megaco_text_parser_v2.yrl", 1191).
yeccpars2_272_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_277_/1}).
-file("megaco_text_parser_v2.yrl", 1184).
yeccpars2_277_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { stream , __3 }
  end | __Stack].

-compile({inline,yeccpars2_279_/1}).
-file("megaco_text_parser_v2.yrl", 1185).
yeccpars2_279_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { signal_type , __3 }
  end | __Stack].

-compile({inline,yeccpars2_280_/1}).
-file("megaco_text_parser_v2.yrl", 1195).
yeccpars2_280_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   brief
  end | __Stack].

-compile({inline,yeccpars2_281_/1}).
-file("megaco_text_parser_v2.yrl", 1193).
yeccpars2_281_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onOff
  end | __Stack].

-compile({inline,yeccpars2_282_/1}).
-file("megaco_text_parser_v2.yrl", 1194).
yeccpars2_282_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   timeOut
  end | __Stack].

-compile({inline,yeccpars2_285_/1}).
-file("megaco_text_parser_v2.yrl", 1198).
yeccpars2_285_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_286_/1}).
-file("megaco_text_parser_v2.yrl", 1201).
yeccpars2_286_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onInterruptByEvent
  end | __Stack].

-compile({inline,yeccpars2_287_/1}).
-file("megaco_text_parser_v2.yrl", 1202).
yeccpars2_287_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onInterruptByNewSignalDescr
  end | __Stack].

-compile({inline,yeccpars2_288_/1}).
-file("megaco_text_parser_v2.yrl", 1203).
yeccpars2_288_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   otherReason
  end | __Stack].

-compile({inline,yeccpars2_289_/1}).
-file("megaco_text_parser_v2.yrl", 1200).
yeccpars2_289_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onTimeOut
  end | __Stack].

-compile({inline,yeccpars2_292_/1}).
-file("megaco_text_parser_v2.yrl", 1198).
yeccpars2_292_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_293_/1}).
-file("megaco_text_parser_v2.yrl", 1197).
yeccpars2_293_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_294_/1}).
-file("megaco_text_parser_v2.yrl", 1190).
yeccpars2_294_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { notify_completion , [ __4 | __5 ] }
  end | __Stack].

-compile({inline,yeccpars2_296_/1}).
-file("megaco_text_parser_v2.yrl", 1186).
yeccpars2_296_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { duration , ensure_uint16 ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_297_/1}).
-file("megaco_text_parser_v2.yrl", 1187).
yeccpars2_297_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { other , ensure_NAME ( __1 ) , __2 }
  end | __Stack].

-compile({inline,yeccpars2_302_/1}).
-file("megaco_text_parser_v2.yrl", 1005).
yeccpars2_302_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , unequalTo } }
  end | __Stack].

-compile({inline,yeccpars2_303_/1}).
-file("megaco_text_parser_v2.yrl", 1389).
yeccpars2_303_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_value ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_304_/1}).
-file("megaco_text_parser_v2.yrl", 1387).
yeccpars2_304_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_value ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_305_/1}).
-file("megaco_text_parser_v2.yrl", 1008).
yeccpars2_305_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , smallerThan } }
  end | __Stack].

-compile({inline,yeccpars2_306_/1}).
-file("megaco_text_parser_v2.yrl", 1011).
yeccpars2_306_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , greaterThan } }
  end | __Stack].

-compile({inline,yeccpars2_307_/1}).
-file("megaco_text_parser_v2.yrl", 1032).
yeccpars2_307_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __1 ] }
  end | __Stack].

-compile({inline,yeccpars2_308_/1}).
-file("megaco_text_parser_v2.yrl", 1002).
yeccpars2_308_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_311_/1}).
-file("megaco_text_parser_v2.yrl", 1035).
yeccpars2_311_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_315_/1}).
-file("megaco_text_parser_v2.yrl", 1035).
yeccpars2_315_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_316_/1}).
-file("megaco_text_parser_v2.yrl", 1034).
yeccpars2_316_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_318_/1}).
-file("megaco_text_parser_v2.yrl", 1024).
yeccpars2_318_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 , __4 ] ,
    extraInfo = { range , true } }
  end | __Stack].

-compile({inline,yeccpars2_319_/1}).
-file("megaco_text_parser_v2.yrl", 1028).
yeccpars2_319_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 | __3 ] ,
    extraInfo = { sublist , true } }
  end | __Stack].

-compile({inline,yeccpars2_320_/1}).
-file("megaco_text_parser_v2.yrl", 1035).
yeccpars2_320_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_322_/1}).
-file("megaco_text_parser_v2.yrl", 1020).
yeccpars2_322_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 | __3 ] ,
    extraInfo = { sublist , false } }
  end | __Stack].

-compile({inline,yeccpars2_325_/1}).
-file("megaco_text_parser_v2.yrl", 1167).
yeccpars2_325_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_326_/1}).
-file("megaco_text_parser_v2.yrl", 1166).
yeccpars2_326_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_327_/1}).
-file("megaco_text_parser_v2.yrl", 1163).
yeccpars2_327_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_signalRequest ( __1 , [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_329_/1}).
-file("megaco_text_parser_v2.yrl", 1336).
yeccpars2_329_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_packagesItem ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_331_/1}).
-file("megaco_text_parser_v2.yrl", 838).
yeccpars2_331_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudPackagesDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_333_/1}).
-file("megaco_text_parser_v2.yrl", 758).
yeccpars2_333_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { termStateDescr , __1 }
  end | __Stack].

-compile({inline,yeccpars2_334_/1}).
-file("megaco_text_parser_v2.yrl", 756).
yeccpars2_334_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_335_/1}).
-file("megaco_text_parser_v2.yrl", 757).
yeccpars2_335_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamDescr , __1 }
  end | __Stack].

-compile({inline,yeccpars2_337_/1}).
-file("megaco_text_parser_v2.yrl", 762).
yeccpars2_337_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamParms' { localControlDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_342_/1}).
-file("megaco_text_parser_v2.yrl", 790).
yeccpars2_342_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_indAudTerminationStateParm ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_344_/1}).
-file("megaco_text_parser_v2.yrl", 784).
yeccpars2_344_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudTerminationStateDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_349_/1}).
-file("megaco_text_parser_v2.yrl", 766).
yeccpars2_349_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamDescriptor' { streamID = __3 ,
    streamParms = __5 }
  end | __Stack].

-compile({inline,yeccpars2_351_/1}).
-file("megaco_text_parser_v2.yrl", 779).
yeccpars2_351_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_indAudLocalParm ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_352_/1}).
-file("megaco_text_parser_v2.yrl", 775).
yeccpars2_352_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_355_/1}).
-file("megaco_text_parser_v2.yrl", 775).
yeccpars2_355_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_356_/1}).
-file("megaco_text_parser_v2.yrl", 774).
yeccpars2_356_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_357_/1}).
-file("megaco_text_parser_v2.yrl", 772).
yeccpars2_357_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudLocalControlDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_358_/1}).
-file("megaco_text_parser_v2.yrl", 744).
yeccpars2_358_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudMediaDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_360_/1}).
-file("megaco_text_parser_v2.yrl", 1248).
yeccpars2_360_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_requestID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_365_/1}).
-file("megaco_text_parser_v2.yrl", 808).
yeccpars2_365_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudEventsDescriptor' { requestID = __3 ,
    pkgdName = __5 }
  end | __Stack].

-compile({inline,yeccpars2_367_/1}).
-file("megaco_text_parser_v2.yrl", 800).
yeccpars2_367_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_369_/1}).
-file("megaco_text_parser_v2.yrl", 793).
yeccpars2_369_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_370_/1}).
-file("megaco_text_parser_v2.yrl", 796).
yeccpars2_370_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudEventBufferDescriptor ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_372_/1}).
-file("megaco_text_parser_v2.yrl", 1145).
yeccpars2_372_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_NAME ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_374_/1}).
-file("megaco_text_parser_v2.yrl", 803).
yeccpars2_374_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamID , __1 }
  end | __Stack].

-compile({inline,yeccpars2_375_/1}).
-file("megaco_text_parser_v2.yrl", 804).
yeccpars2_375_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventParameterName , __1 }
  end | __Stack].

-compile({inline,yeccpars2_377_/1}).
-file("megaco_text_parser_v2.yrl", 799).
yeccpars2_377_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_378_/1}).
-file("megaco_text_parser_v2.yrl", 680).
yeccpars2_378_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_auditDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_379_/1}).
-file("megaco_text_parser_v2.yrl", 682).
yeccpars2_379_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_381_/1}).
-file("megaco_text_parser_v2.yrl", 686).
yeccpars2_381_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_382_/1}).
-file("megaco_text_parser_v2.yrl", 685).
yeccpars2_382_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_383_/1}).
-file("megaco_text_parser_v2.yrl", 713).
yeccpars2_383_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_385_/1}).
-file("megaco_text_parser_v2.yrl", 724).
yeccpars2_385_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_392_/1}).
-file("megaco_text_parser_v2.yrl", 723).
yeccpars2_392_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_393_/1}).
-file("megaco_text_parser_v2.yrl", 624).
yeccpars2_393_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_400_/1}).
-file("megaco_text_parser_v2.yrl", 1289).
yeccpars2_400_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { time_stamp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_401_/1}).
-file("megaco_text_parser_v2.yrl", 1291).
yeccpars2_401_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { version , __1 }
  end | __Stack].

-compile({inline,yeccpars2_402_/1}).
-file("megaco_text_parser_v2.yrl", 1284).
yeccpars2_402_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { reason , __1 }
  end | __Stack].

-compile({inline,yeccpars2_403_/1}).
-file("megaco_text_parser_v2.yrl", 1287).
yeccpars2_403_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { profile , __1 }
  end | __Stack].

-compile({inline,yeccpars2_404_/1}).
-file("megaco_text_parser_v2.yrl", 1281).
yeccpars2_404_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_405_/1}).
-file("megaco_text_parser_v2.yrl", 1290).
yeccpars2_405_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mgc_id , __1 }
  end | __Stack].

-compile({inline,yeccpars2_406_/1}).
-file("megaco_text_parser_v2.yrl", 1283).
yeccpars2_406_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { method , __1 }
  end | __Stack].

-compile({inline,yeccpars2_407_/1}).
-file("megaco_text_parser_v2.yrl", 1285).
yeccpars2_407_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { delay , __1 }
  end | __Stack].

-compile({inline,yeccpars2_408_/1}).
-file("megaco_text_parser_v2.yrl", 1286).
yeccpars2_408_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { address , __1 }
  end | __Stack].

-compile({inline,yeccpars2_409_/1}).
-file("megaco_text_parser_v2.yrl", 1384).
yeccpars2_409_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_extensionParameter ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_411_/1}).
-file("megaco_text_parser_v2.yrl", 1288).
yeccpars2_411_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { extension , __1 }
  end | __Stack].

-compile({inline,yeccpars2_412_/1}).
-file("megaco_text_parser_v2.yrl", 1292).
yeccpars2_412_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { audit_item , __1 }
  end | __Stack].

-compile({inline,yeccpars2_419_COMMA/1}).
-file("megaco_text_parser_v2.yrl", 1338).
yeccpars2_419_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_timeStamp ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_419_RBRKT/1}).
-file("megaco_text_parser_v2.yrl", 1338).
yeccpars2_419_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_timeStamp ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_422_/1}).
-file("megaco_text_parser_v2.yrl", 1308).
yeccpars2_422_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_version ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_423_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_423_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_424_/1}).
-file("megaco_text_parser_v2.yrl", 1302).
yeccpars2_424_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { portNumber , __3 }
  end | __Stack].

-compile({inline,yeccpars2_425_/1}).
-file("megaco_text_parser_v2.yrl", 1300).
yeccpars2_425_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_427_/1}).
-file("megaco_text_parser_v2.yrl", 1296).
yeccpars2_427_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 ]
  end | __Stack].

-compile({inline,yeccpars2_429_/1}).
-file("megaco_text_parser_v2.yrl", 1306).
yeccpars2_429_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_profile ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_430_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_430_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_431_/1}).
-file("megaco_text_parser_v2.yrl", 1304).
yeccpars2_431_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_433_/1}).
-file("megaco_text_parser_v2.yrl", 1294).
yeccpars2_433_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_serviceChangeMethod ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_435_/1}).
-file("megaco_text_parser_v2.yrl", 1298).
yeccpars2_435_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_uint32 ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_436_/1}).
-file("megaco_text_parser_v2.yrl", 1311).
yeccpars2_436_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'PropertyParm' .name , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_439_/1}).
-file("megaco_text_parser_v2.yrl", 1281).
yeccpars2_439_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_440_/1}).
-file("megaco_text_parser_v2.yrl", 1280).
yeccpars2_440_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_441_/1}).
-file("megaco_text_parser_v2.yrl", 1277).
yeccpars2_441_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_ServiceChangeParm ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_442_/1}).
-file("megaco_text_parser_v2.yrl", 866).
yeccpars2_442_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { serviceChangeReq , __1 } ,
    # 'ServiceChangeRequest' { terminationID = [ __3 ] ,
    serviceChangeParms = __5 } )
  end | __Stack].

-compile({inline,yeccpars2_444_/1}).
-file("megaco_text_parser_v2.yrl", 1382).
yeccpars2_444_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_448_/1}).
-file("megaco_text_parser_v2.yrl", 852).
yeccpars2_448_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'NotifyRequest' { observedEventsDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_450_/1}).
-file("megaco_text_parser_v2.yrl", 854).
yeccpars2_450_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'NotifyRequest' { errorDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_454_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_454_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_455_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_455_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_457_/1}).
-file("megaco_text_parser_v2.yrl", 1228).
yeccpars2_457_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_458_/1}).
-file("megaco_text_parser_v2.yrl", 1338).
yeccpars2_458_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_timeStamp ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_460_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_460_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_461_/1}).
-file("megaco_text_parser_v2.yrl", 1228).
yeccpars2_461_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_462_/1}).
-file("megaco_text_parser_v2.yrl", 1227).
yeccpars2_462_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_463_/1}).
-file("megaco_text_parser_v2.yrl", 1224).
yeccpars2_463_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'ObservedEventsDescriptor' { requestId = __3 ,
    observedEventLst = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_464_/1}).
-file("megaco_text_parser_v2.yrl", 1240).
yeccpars2_464_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_465_/1}).
-file("megaco_text_parser_v2.yrl", 1235).
yeccpars2_465_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_observed_event ( __3 , __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_467_/1}).
-file("megaco_text_parser_v2.yrl", 1243).
yeccpars2_467_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_470_/1}).
-file("megaco_text_parser_v2.yrl", 1143).
yeccpars2_470_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   select_stream_or_other ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_473_/1}).
-file("megaco_text_parser_v2.yrl", 1243).
yeccpars2_473_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_474_/1}).
-file("megaco_text_parser_v2.yrl", 1242).
yeccpars2_474_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_475_/1}).
-file("megaco_text_parser_v2.yrl", 1239).
yeccpars2_475_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_477_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_477_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_479_/1}).
-file("megaco_text_parser_v2.yrl", 1240).
yeccpars2_479_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_480_/1}).
-file("megaco_text_parser_v2.yrl", 1233).
yeccpars2_480_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_observed_event ( __6 , __5 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_481_/1}).
-file("megaco_text_parser_v2.yrl", 848).
yeccpars2_481_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { notifyReq , __1 } ,
    setelement ( # 'NotifyRequest' .terminationID , __5 , [ __3 ] ) )
  end | __Stack].

-compile({inline,yeccpars2_483_/1}).
-file("megaco_text_parser_v2.yrl", 524).
yeccpars2_483_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_484_/1}).
-file("megaco_text_parser_v2.yrl", 528).
yeccpars2_484_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   emergencyAudit
  end | __Stack].

-compile({inline,yeccpars2_485_/1}).
-file("megaco_text_parser_v2.yrl", 529).
yeccpars2_485_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   priorityAudit
  end | __Stack].

-compile({inline,yeccpars2_486_/1}).
-file("megaco_text_parser_v2.yrl", 527).
yeccpars2_486_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   topologyAudit
  end | __Stack].

-compile({inline,yeccpars2_489_/1}).
-file("megaco_text_parser_v2.yrl", 524).
yeccpars2_489_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_490_/1}).
-file("megaco_text_parser_v2.yrl", 523).
yeccpars2_490_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_491_/1}).
-file("megaco_text_parser_v2.yrl", 520).
yeccpars2_491_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { contextAudit , [ __3 | __4 ] }
  end | __Stack].

-compile({inline,yeccpars2_493_/1}).
-file("megaco_text_parser_v2.yrl", 625).
yeccpars2_493_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_494_/1}).
-file("megaco_text_parser_v2.yrl", 629).
yeccpars2_494_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { auditValueRequest , __1 } ,
    # 'AuditRequest' { terminationID = __3 ,
    auditDescriptor = __4 } )
  end | __Stack].

-compile({inline,yeccpars2_496_/1}).
-file("megaco_text_parser_v2.yrl", 625).
yeccpars2_496_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_497_/1}).
-file("megaco_text_parser_v2.yrl", 634).
yeccpars2_497_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { auditCapRequest , __1 } ,
    # 'AuditRequest' { terminationID = __3 ,
    auditDescriptor = __4 } )
  end | __Stack].

-compile({inline,yeccpars2_500_/1}).
-file("megaco_text_parser_v2.yrl", 506).
yeccpars2_500_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_501_/1}).
-file("megaco_text_parser_v2.yrl", 505).
yeccpars2_501_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_502_/1}).
-file("megaco_text_parser_v2.yrl", 503).
yeccpars2_502_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_action_requests ( __3 , [ __5 | __6 ] )
  end | __Stack].

-compile({inline,yeccpars2_504_/1}).
-file("megaco_text_parser_v2.yrl", 591).
yeccpars2_504_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_505_/1}).
-file("megaco_text_parser_v2.yrl", 581).
yeccpars2_505_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Descs = merge_AmmRequest_descriptors ( __4 , [ ] ) ,
    make_commandRequest ( __1 ,
    # 'AmmRequest' { terminationID = [ __3 ] ,
    descriptors = Descs } )
  end | __Stack].

-compile({inline,yeccpars2_507_/1}).
-file("megaco_text_parser_v2.yrl", 602).
yeccpars2_507_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_508_/1}).
-file("megaco_text_parser_v2.yrl", 599).
yeccpars2_508_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { muxDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_509_/1}).
-file("megaco_text_parser_v2.yrl", 598).
yeccpars2_509_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { modemDescriptor , deprecated }
  end | __Stack].

-compile({inline,yeccpars2_510_/1}).
-file("megaco_text_parser_v2.yrl", 597).
yeccpars2_510_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_511_/1}).
-file("megaco_text_parser_v2.yrl", 600).
yeccpars2_511_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_512_/1}).
-file("megaco_text_parser_v2.yrl", 601).
yeccpars2_512_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_513_/1}).
-file("megaco_text_parser_v2.yrl", 603).
yeccpars2_513_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { digitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_514_/1}).
-file("megaco_text_parser_v2.yrl", 604).
yeccpars2_514_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_515_/1}).
-file("megaco_text_parser_v2.yrl", 594).
yeccpars2_515_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_516_/1}).
-file("megaco_text_parser_v2.yrl", 1269).
yeccpars2_516_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_DMD ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_517_/1}).
-file("megaco_text_parser_v2.yrl", 1038).
yeccpars2_517_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_518_/1}).
-file("megaco_text_parser_v2.yrl", 1074).
yeccpars2_518_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'EventsDescriptor' { requestID = asn1_NOVALUE ,
    eventList = [ ] }
  end | __Stack].

-compile({inline,yeccpars2_522_/1}).
-file("megaco_text_parser_v2.yrl", 1154).
yeccpars2_522_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_524_/1}).
-file("megaco_text_parser_v2.yrl", 1160).
yeccpars2_524_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signal , __1 }
  end | __Stack].

-compile({inline,yeccpars2_525_/1}).
-file("megaco_text_parser_v2.yrl", 1157).
yeccpars2_525_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_526_/1}).
-file("megaco_text_parser_v2.yrl", 1159).
yeccpars2_526_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { seqSigList , __1 }
  end | __Stack].

-compile({inline,yeccpars2_531_/1}).
-file("megaco_text_parser_v2.yrl", 1212).
yeccpars2_531_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_534_/1}).
-file("megaco_text_parser_v2.yrl", 1212).
yeccpars2_534_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_535_/1}).
-file("megaco_text_parser_v2.yrl", 1211).
yeccpars2_535_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_536_/1}).
-file("megaco_text_parser_v2.yrl", 1207).
yeccpars2_536_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'SeqSigList' { id = ensure_uint16 ( __3 ) ,
    signalList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_539_/1}).
-file("megaco_text_parser_v2.yrl", 1157).
yeccpars2_539_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_540_/1}).
-file("megaco_text_parser_v2.yrl", 1156).
yeccpars2_540_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_541_/1}).
-file("megaco_text_parser_v2.yrl", 1153).
yeccpars2_541_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_543_/1}).
-file("megaco_text_parser_v2.yrl", 1067).
yeccpars2_543_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_muxType ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_545_/1}).
-file("megaco_text_parser_v2.yrl", 1064).
yeccpars2_545_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'MuxDescriptor' { muxType = __3 ,
    termList = __4 }
  end | __Stack].

-compile({inline,yeccpars2_547_/1}).
-file("megaco_text_parser_v2.yrl", 928).
yeccpars2_547_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_550_/1}).
-file("megaco_text_parser_v2.yrl", 928).
yeccpars2_550_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_551_/1}).
-file("megaco_text_parser_v2.yrl", 927).
yeccpars2_551_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_552_/1}).
-file("megaco_text_parser_v2.yrl", 924).
yeccpars2_552_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_555_/1}).
-file("megaco_text_parser_v2.yrl", 0).
yeccpars2_555_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_556_/1}).
-file("megaco_text_parser_v2.yrl", 0).
yeccpars2_556_(__Stack0) ->
 [begin
   '$undefined'
  end | __Stack0].

-compile({inline,yeccpars2_559_/1}).
-file("megaco_text_parser_v2.yrl", 0).
yeccpars2_559_(__Stack0) ->
 [begin
   '$undefined'
  end | __Stack0].

-compile({inline,yeccpars2_560_/1}).
-file("megaco_text_parser_v2.yrl", 0).
yeccpars2_560_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_561_/1}).
-file("megaco_text_parser_v2.yrl", 1260).
yeccpars2_561_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_562_/1}).
-file("megaco_text_parser_v2.yrl", 0).
yeccpars2_562_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_564_/1}).
-file("megaco_text_parser_v2.yrl", 1263).
yeccpars2_564_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_566_/1}).
-file("megaco_text_parser_v2.yrl", 999).
yeccpars2_566_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'PropertyParm' .name , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_569_/1}).
-file("megaco_text_parser_v2.yrl", 1263).
yeccpars2_569_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_570_/1}).
-file("megaco_text_parser_v2.yrl", 1262).
yeccpars2_570_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_571_/1}).
-file("megaco_text_parser_v2.yrl", 1259).
yeccpars2_571_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_572_/1}).
-file("megaco_text_parser_v2.yrl", 1260).
yeccpars2_572_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_573_/1}).
-file("megaco_text_parser_v2.yrl", 0).
yeccpars2_573_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_575_/1}).
-file("megaco_text_parser_v2.yrl", 949).
yeccpars2_575_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { termState , __1 }
  end | __Stack].

-compile({inline,yeccpars2_576_/1}).
-file("megaco_text_parser_v2.yrl", 945).
yeccpars2_576_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_577_/1}).
-file("megaco_text_parser_v2.yrl", 947).
yeccpars2_577_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_578_/1}).
-file("megaco_text_parser_v2.yrl", 939).
yeccpars2_578_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_579_/1}).
-file("megaco_text_parser_v2.yrl", 959).
yeccpars2_579_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { control , __1 }
  end | __Stack].

-compile({inline,yeccpars2_581_/1}).
-file("megaco_text_parser_v2.yrl", 954).
yeccpars2_581_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   PGs = ensure_prop_groups ( __1 ) ,
    { local , # 'LocalRemoteDescriptor' { propGrps = PGs } }
  end | __Stack].

-compile({inline,yeccpars2_582_/1}).
-file("megaco_text_parser_v2.yrl", 957).
yeccpars2_582_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   PGs = ensure_prop_groups ( __1 ) ,
    { remote , # 'LocalRemoteDescriptor' { propGrps = PGs } }
  end | __Stack].

-compile({inline,yeccpars2_586_/1}).
-file("megaco_text_parser_v2.yrl", 980).
yeccpars2_586_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_587_/1}).
-file("megaco_text_parser_v2.yrl", 1048).
yeccpars2_587_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { serviceState , __1 }
  end | __Stack].

-compile({inline,yeccpars2_588_/1}).
-file("megaco_text_parser_v2.yrl", 1050).
yeccpars2_588_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { propertyParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_589_/1}).
-file("megaco_text_parser_v2.yrl", 1049).
yeccpars2_589_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferControl , __1 }
  end | __Stack].

-compile({inline,yeccpars2_593_/1}).
-file("megaco_text_parser_v2.yrl", 1052).
yeccpars2_593_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_594_/1}).
-file("megaco_text_parser_v2.yrl", 1056).
yeccpars2_594_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   inSvc
  end | __Stack].

-compile({inline,yeccpars2_595_/1}).
-file("megaco_text_parser_v2.yrl", 1055).
yeccpars2_595_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   outOfSvc
  end | __Stack].

-compile({inline,yeccpars2_596_/1}).
-file("megaco_text_parser_v2.yrl", 1054).
yeccpars2_596_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   test
  end | __Stack].

-compile({inline,yeccpars2_598_/1}).
-file("megaco_text_parser_v2.yrl", 1058).
yeccpars2_598_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_599_/1}).
-file("megaco_text_parser_v2.yrl", 1061).
yeccpars2_599_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lockStep
  end | __Stack].

-compile({inline,yeccpars2_600_/1}).
-file("megaco_text_parser_v2.yrl", 1060).
yeccpars2_600_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   off
  end | __Stack].

-compile({inline,yeccpars2_603_/1}).
-file("megaco_text_parser_v2.yrl", 980).
yeccpars2_603_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_604_/1}).
-file("megaco_text_parser_v2.yrl", 979).
yeccpars2_604_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_605_/1}).
-file("megaco_text_parser_v2.yrl", 977).
yeccpars2_605_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_terminationStateDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_609_/1}).
-file("megaco_text_parser_v2.yrl", 967).
yeccpars2_609_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_612_/1}).
-file("megaco_text_parser_v2.yrl", 967).
yeccpars2_612_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_613_/1}).
-file("megaco_text_parser_v2.yrl", 966).
yeccpars2_613_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_614_/1}).
-file("megaco_text_parser_v2.yrl", 963).
yeccpars2_614_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'StreamDescriptor' { streamID = __3 ,
    streamParms = merge_streamParms ( [ __5 | __6 ] ) }
  end | __Stack].

-compile({inline,yeccpars2_616_/1}).
-file("megaco_text_parser_v2.yrl", 986).
yeccpars2_616_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_617_/1}).
-file("megaco_text_parser_v2.yrl", 973).
yeccpars2_617_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_622_/1}).
-file("megaco_text_parser_v2.yrl", 984).
yeccpars2_622_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { value , __3 }
  end | __Stack].

-compile({inline,yeccpars2_623_/1}).
-file("megaco_text_parser_v2.yrl", 989).
yeccpars2_623_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   false
  end | __Stack].

-compile({inline,yeccpars2_624_/1}).
-file("megaco_text_parser_v2.yrl", 988).
yeccpars2_624_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   true
  end | __Stack].

-compile({inline,yeccpars2_626_/1}).
-file("megaco_text_parser_v2.yrl", 983).
yeccpars2_626_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { group , __3 }
  end | __Stack].

-compile({inline,yeccpars2_628_/1}).
-file("megaco_text_parser_v2.yrl", 985).
yeccpars2_628_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { mode , __3 }
  end | __Stack].

-compile({inline,yeccpars2_629_/1}).
-file("megaco_text_parser_v2.yrl", 995).
yeccpars2_629_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   inactive
  end | __Stack].

-compile({inline,yeccpars2_630_/1}).
-file("megaco_text_parser_v2.yrl", 996).
yeccpars2_630_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   loopBack
  end | __Stack].

-compile({inline,yeccpars2_631_/1}).
-file("megaco_text_parser_v2.yrl", 993).
yeccpars2_631_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   recvOnly
  end | __Stack].

-compile({inline,yeccpars2_632_/1}).
-file("megaco_text_parser_v2.yrl", 992).
yeccpars2_632_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sendOnly
  end | __Stack].

-compile({inline,yeccpars2_633_/1}).
-file("megaco_text_parser_v2.yrl", 994).
yeccpars2_633_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sendRecv
  end | __Stack].

-compile({inline,yeccpars2_636_/1}).
-file("megaco_text_parser_v2.yrl", 973).
yeccpars2_636_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_637_/1}).
-file("megaco_text_parser_v2.yrl", 972).
yeccpars2_637_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_638_/1}).
-file("megaco_text_parser_v2.yrl", 970).
yeccpars2_638_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_641_/1}).
-file("megaco_text_parser_v2.yrl", 939).
yeccpars2_641_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_642_/1}).
-file("megaco_text_parser_v2.yrl", 938).
yeccpars2_642_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_643_/1}).
-file("megaco_text_parser_v2.yrl", 936).
yeccpars2_643_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_mediaDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_647_/1}).
-file("megaco_text_parser_v2.yrl", 1082).
yeccpars2_647_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_648_/1}).
-file("megaco_text_parser_v2.yrl", 1089).
yeccpars2_648_(__Stack0) ->
 [begin
   # 'RequestedEvent' { evParList = [ ] }
  end | __Stack0].

-compile({inline,yeccpars2_649_/1}).
-file("megaco_text_parser_v2.yrl", 1085).
yeccpars2_649_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'RequestedEvent' .pkgdName , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_652_/1}).
-file("megaco_text_parser_v2.yrl", 1093).
yeccpars2_652_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_656_/1}).
-file("megaco_text_parser_v2.yrl", 1149).
yeccpars2_656_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_eventDM ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_658_COMMA/1}).
-file("megaco_text_parser_v2.yrl", 1096).
yeccpars2_658_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_658_RBRKT/1}).
-file("megaco_text_parser_v2.yrl", 1096).
yeccpars2_658_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_662_/1}).
-file("megaco_text_parser_v2.yrl", 1112).
yeccpars2_662_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'SecondEventsDescriptor' { requestID = asn1_NOVALUE ,
    eventList = [ ] }
  end | __Stack].

-compile({inline,yeccpars2_666_/1}).
-file("megaco_text_parser_v2.yrl", 1120).
yeccpars2_666_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_667_/1}).
-file("megaco_text_parser_v2.yrl", 1128).
yeccpars2_667_(__Stack0) ->
 [begin
   # 'SecondRequestedEvent' { evParList = [ ] }
  end | __Stack0].

-compile({inline,yeccpars2_668_/1}).
-file("megaco_text_parser_v2.yrl", 1124).
yeccpars2_668_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'SecondRequestedEvent' .pkgdName , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_670_/1}).
-file("megaco_text_parser_v2.yrl", 1131).
yeccpars2_670_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_675_COMMA/1}).
-file("megaco_text_parser_v2.yrl", 1134).
yeccpars2_675_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_675_RBRKT/1}).
-file("megaco_text_parser_v2.yrl", 1134).
yeccpars2_675_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_678_/1}).
-file("megaco_text_parser_v2.yrl", 1140).
yeccpars2_678_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { second_embed , __3 }
  end | __Stack].

-compile({inline,yeccpars2_681_/1}).
-file("megaco_text_parser_v2.yrl", 1131).
yeccpars2_681_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_682_/1}).
-file("megaco_text_parser_v2.yrl", 1130).
yeccpars2_682_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_683_/1}).
-file("megaco_text_parser_v2.yrl", 1127).
yeccpars2_683_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_secondEventParameters ( [ __2 | __3 ] )
  end | __Stack].

-compile({inline,yeccpars2_686_/1}).
-file("megaco_text_parser_v2.yrl", 1120).
yeccpars2_686_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_687_/1}).
-file("megaco_text_parser_v2.yrl", 1119).
yeccpars2_687_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_688_/1}).
-file("megaco_text_parser_v2.yrl", 1116).
yeccpars2_688_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'SecondEventsDescriptor' { requestID = __3 ,
    eventList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_689_/1}).
-file("megaco_text_parser_v2.yrl", 1109).
yeccpars2_689_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , asn1_NOVALUE , __3 }
  end | __Stack].

-compile({inline,yeccpars2_691_/1}).
-file("megaco_text_parser_v2.yrl", 1106).
yeccpars2_691_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , __3 , asn1_NOVALUE }
  end | __Stack].

-compile({inline,yeccpars2_693_/1}).
-file("megaco_text_parser_v2.yrl", 1104).
yeccpars2_693_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , __3 , __5 }
  end | __Stack].

-compile({inline,yeccpars2_696_/1}).
-file("megaco_text_parser_v2.yrl", 1093).
yeccpars2_696_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_697_/1}).
-file("megaco_text_parser_v2.yrl", 1092).
yeccpars2_697_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_698_/1}).
-file("megaco_text_parser_v2.yrl", 1088).
yeccpars2_698_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_eventParameters ( [ __2 | __3 ] )
  end | __Stack].

-compile({inline,yeccpars2_701_/1}).
-file("megaco_text_parser_v2.yrl", 1082).
yeccpars2_701_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_702_/1}).
-file("megaco_text_parser_v2.yrl", 1081).
yeccpars2_702_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_703_/1}).
-file("megaco_text_parser_v2.yrl", 1078).
yeccpars2_703_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'EventsDescriptor' { requestID = __3 ,
    eventList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_704_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_704_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_705_/1}).
-file("megaco_text_parser_v2.yrl", 1045).
yeccpars2_705_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_eventSpec ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_706_/1}).
-file("megaco_text_parser_v2.yrl", 1043).
yeccpars2_706_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_708_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_708_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_709_/1}).
-file("megaco_text_parser_v2.yrl", 1043).
yeccpars2_709_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_710_/1}).
-file("megaco_text_parser_v2.yrl", 1042).
yeccpars2_710_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_711_/1}).
-file("megaco_text_parser_v2.yrl", 1040).
yeccpars2_711_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_714_/1}).
-file("megaco_text_parser_v2.yrl", 594).
yeccpars2_714_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_715_/1}).
-file("megaco_text_parser_v2.yrl", 593).
yeccpars2_715_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_716_/1}).
-file("megaco_text_parser_v2.yrl", 590).
yeccpars2_716_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_719_/1}).
-file("megaco_text_parser_v2.yrl", 499).
yeccpars2_719_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_720_/1}).
-file("megaco_text_parser_v2.yrl", 498).
yeccpars2_720_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_721_/1}).
-file("megaco_text_parser_v2.yrl", 487).
yeccpars2_721_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = asn1_NOVALUE ,
    actions = [ __3 | __4 ] }
  end | __Stack].

-compile({inline,yeccpars2_723_/1}).
-file("megaco_text_parser_v2.yrl", 890).
yeccpars2_723_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint32 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_725_/1}).
-file("megaco_text_parser_v2.yrl", 499).
yeccpars2_725_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_727_/1}).
-file("megaco_text_parser_v2.yrl", 491).
yeccpars2_727_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = asn1_NOVALUE ,
    actions = [ __4 | __5 ] }
  end | __Stack].

-compile({inline,yeccpars2_729_/1}).
-file("megaco_text_parser_v2.yrl", 499).
yeccpars2_729_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_731_/1}).
-file("megaco_text_parser_v2.yrl", 495).
yeccpars2_731_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = ensure_transactionID ( __3 ) ,
    actions = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_733_/1}).
-file("megaco_text_parser_v2.yrl", 476).
yeccpars2_733_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_734_/1}).
-file("megaco_text_parser_v2.yrl", 478).
yeccpars2_734_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_transactionAck ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_737_/1}).
-file("megaco_text_parser_v2.yrl", 476).
yeccpars2_737_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_738_/1}).
-file("megaco_text_parser_v2.yrl", 475).
yeccpars2_738_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_739_/1}).
-file("megaco_text_parser_v2.yrl", 473).
yeccpars2_739_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_742_/1}).
-file("megaco_text_parser_v2.yrl", 546).
yeccpars2_742_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_745_/1}).
-file("megaco_text_parser_v2.yrl", 545).
yeccpars2_745_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   'NULL'
  end | __Stack].

-compile({inline,yeccpars2_747_/1}).
-file("megaco_text_parser_v2.yrl", 548).
yeccpars2_747_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionError , __1 }
  end | __Stack].

-compile({inline,yeccpars2_748_/1}).
-file("megaco_text_parser_v2.yrl", 552).
yeccpars2_748_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_753_/1}).
-file("megaco_text_parser_v2.yrl", 563).
yeccpars2_753_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_754_/1}).
-file("megaco_text_parser_v2.yrl", 566).
yeccpars2_754_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_755_/1}).
-file("megaco_text_parser_v2.yrl", 559).
yeccpars2_755_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'ActionReply' { errorDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_756_/1}).
-file("megaco_text_parser_v2.yrl", 567).
yeccpars2_756_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { context , __1 }
  end | __Stack].

-compile({inline,yeccpars2_757_/1}).
-file("megaco_text_parser_v2.yrl", 577).
yeccpars2_757_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_758_/1}).
-file("megaco_text_parser_v2.yrl", 564).
yeccpars2_758_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_760_/1}).
-file("megaco_text_parser_v2.yrl", 565).
yeccpars2_760_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_762_/1}).
-file("megaco_text_parser_v2.yrl", 610).
yeccpars2_762_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   addReply
  end | __Stack].

-compile({inline,yeccpars2_765_/1}).
-file("megaco_text_parser_v2.yrl", 612).
yeccpars2_765_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modReply
  end | __Stack].

-compile({inline,yeccpars2_766_/1}).
-file("megaco_text_parser_v2.yrl", 611).
yeccpars2_766_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   moveReply
  end | __Stack].

-compile({inline,yeccpars2_769_/1}).
-file("megaco_text_parser_v2.yrl", 613).
yeccpars2_769_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   subtractReply
  end | __Stack].

-compile({inline,yeccpars2_771_/1}).
-file("megaco_text_parser_v2.yrl", 879).
yeccpars2_771_(__Stack0) ->
 [begin
   { serviceChangeResParms , # 'ServiceChangeResParm' { } }
  end | __Stack0].

-compile({inline,yeccpars2_772_/1}).
-file("megaco_text_parser_v2.yrl", 871).
yeccpars2_772_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceChangeReply ,
    # 'ServiceChangeReply' { terminationID = [ __3 ] ,
    serviceChangeResult = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_778_/1}).
-file("megaco_text_parser_v2.yrl", 1328).
yeccpars2_778_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { time_stamp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_779_/1}).
-file("megaco_text_parser_v2.yrl", 1327).
yeccpars2_779_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { version , __1 }
  end | __Stack].

-compile({inline,yeccpars2_780_/1}).
-file("megaco_text_parser_v2.yrl", 1326).
yeccpars2_780_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { profile , __1 }
  end | __Stack].

-compile({inline,yeccpars2_781_/1}).
-file("megaco_text_parser_v2.yrl", 1325).
yeccpars2_781_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mgc_id , __1 }
  end | __Stack].

-compile({inline,yeccpars2_782_/1}).
-file("megaco_text_parser_v2.yrl", 1324).
yeccpars2_782_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { address , __1 }
  end | __Stack].

-compile({inline,yeccpars2_783_/1}).
-file("megaco_text_parser_v2.yrl", 1322).
yeccpars2_783_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_790_/1}).
-file("megaco_text_parser_v2.yrl", 1322).
yeccpars2_790_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_791_/1}).
-file("megaco_text_parser_v2.yrl", 1321).
yeccpars2_791_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_792_/1}).
-file("megaco_text_parser_v2.yrl", 1318).
yeccpars2_792_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_ServiceChangeResParm ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_793_/1}).
-file("megaco_text_parser_v2.yrl", 876).
yeccpars2_793_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { errorDescriptor , __2 }
  end | __Stack].

-compile({inline,yeccpars2_794_/1}).
-file("megaco_text_parser_v2.yrl", 878).
yeccpars2_794_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceChangeResParms , __2 }
  end | __Stack].

-compile({inline,yeccpars2_796_/1}).
-file("megaco_text_parser_v2.yrl", 862).
yeccpars2_796_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_797_/1}).
-file("megaco_text_parser_v2.yrl", 857).
yeccpars2_797_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { notifyReply ,
    # 'NotifyReply' { terminationID = [ __3 ] ,
    errorDescriptor = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_800_/1}).
-file("megaco_text_parser_v2.yrl", 861).
yeccpars2_800_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_802_/1}).
-file("megaco_text_parser_v2.yrl", 651).
yeccpars2_802_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditResult ,
    # 'AuditResult' { terminationID = __1 ,
    terminationAuditResult = [ ] } }
  end | __Stack].

-compile({inline,yeccpars2_803_/1}).
-file("megaco_text_parser_v2.yrl", 643).
yeccpars2_803_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditValueReply , __3 }
  end | __Stack].

-compile({inline,yeccpars2_805_/1}).
-file("megaco_text_parser_v2.yrl", 647).
yeccpars2_805_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextAuditResult , __1 }
  end | __Stack].

-compile({inline,yeccpars2_806_/1}).
-file("megaco_text_parser_v2.yrl", 639).
yeccpars2_806_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditValueReply , __4 }
  end | __Stack].

-compile({inline,yeccpars2_811_/1}).
-file("megaco_text_parser_v2.yrl", 885).
yeccpars2_811_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint ( __1 , 0 , 999 )
  end | __Stack].

-compile({inline,yeccpars2_813_/1}).
-file("megaco_text_parser_v2.yrl", 888).
yeccpars2_813_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_815_/1}).
-file("megaco_text_parser_v2.yrl", 887).
yeccpars2_815_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   value_of ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_816_/1}).
-file("megaco_text_parser_v2.yrl", 882).
yeccpars2_816_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'ErrorDescriptor' { errorCode = __3 ,
    errorText = __5 }
  end | __Stack].

-compile({inline,yeccpars2_817_/1}).
-file("megaco_text_parser_v2.yrl", 648).
yeccpars2_817_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { contextAuditResult , __2 }
  end | __Stack].

-compile({inline,yeccpars2_820_/1}).
-file("megaco_text_parser_v2.yrl", 674).
yeccpars2_820_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_821_/1}).
-file("megaco_text_parser_v2.yrl", 670).
yeccpars2_821_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_822_/1}).
-file("megaco_text_parser_v2.yrl", 675).
yeccpars2_822_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { packagesDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_823_/1}).
-file("megaco_text_parser_v2.yrl", 672).
yeccpars2_823_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { observedEventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_824_/1}).
-file("megaco_text_parser_v2.yrl", 668).
yeccpars2_824_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { muxDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_825_/1}).
-file("megaco_text_parser_v2.yrl", 0).
yeccpars2_825_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_826_/1}).
-file("megaco_text_parser_v2.yrl", 666).
yeccpars2_826_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_827_/1}).
-file("megaco_text_parser_v2.yrl", 669).
yeccpars2_827_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_828_/1}).
-file("megaco_text_parser_v2.yrl", 673).
yeccpars2_828_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_829_/1}).
-file("megaco_text_parser_v2.yrl", 676).
yeccpars2_829_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { errorDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_830_/1}).
-file("megaco_text_parser_v2.yrl", 671).
yeccpars2_830_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { digitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_831_/1}).
-file("megaco_text_parser_v2.yrl", 664).
yeccpars2_831_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_832_/1}).
-file("megaco_text_parser_v2.yrl", 677).
yeccpars2_832_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditReturnItem , __1 }
  end | __Stack].

-compile({inline,yeccpars2_833_/1}).
-file("megaco_text_parser_v2.yrl", 692).
yeccpars2_833_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   mediaToken
  end | __Stack].

-compile({inline,yeccpars2_834_/1}).
-file("megaco_text_parser_v2.yrl", 691).
yeccpars2_834_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modemToken
  end | __Stack].

-compile({inline,yeccpars2_835_/1}).
-file("megaco_text_parser_v2.yrl", 690).
yeccpars2_835_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   muxToken
  end | __Stack].

-compile({inline,yeccpars2_836_/1}).
-file("megaco_text_parser_v2.yrl", 695).
yeccpars2_836_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   observedEventsToken
  end | __Stack].

-compile({inline,yeccpars2_837_/1}).
-file("megaco_text_parser_v2.yrl", 696).
yeccpars2_837_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   packagesToken
  end | __Stack].

-compile({inline,yeccpars2_838_/1}).
-file("megaco_text_parser_v2.yrl", 694).
yeccpars2_838_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statsToken
  end | __Stack].

-compile({inline,yeccpars2_840_/1}).
-file("megaco_text_parser_v2.yrl", 1345).
yeccpars2_840_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_841_/1}).
-file("megaco_text_parser_v2.yrl", 1349).
yeccpars2_841_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'StatisticsParameter' { statName = __1 ,
    statValue = asn1_NOVALUE }
  end | __Stack].

-compile({inline,yeccpars2_843_/1}).
-file("megaco_text_parser_v2.yrl", 1352).
yeccpars2_843_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'StatisticsParameter' { statName = __1 ,
    statValue = [ __3 ] }
  end | __Stack].

-compile({inline,yeccpars2_846_/1}).
-file("megaco_text_parser_v2.yrl", 1345).
yeccpars2_846_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_847_/1}).
-file("megaco_text_parser_v2.yrl", 1344).
yeccpars2_847_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_848_/1}).
-file("megaco_text_parser_v2.yrl", 1342).
yeccpars2_848_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_850_/1}).
-file("megaco_text_parser_v2.yrl", 1334).
yeccpars2_850_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_853_/1}).
-file("megaco_text_parser_v2.yrl", 1334).
yeccpars2_853_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_854_/1}).
-file("megaco_text_parser_v2.yrl", 1333).
yeccpars2_854_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_855_/1}).
-file("megaco_text_parser_v2.yrl", 1331).
yeccpars2_855_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_856_/1}).
-file("megaco_text_parser_v2.yrl", 661).
yeccpars2_856_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_terminationAudit ( [ __1 | __2 ] )
  end | __Stack].

-compile({inline,yeccpars2_858_/1}).
-file("megaco_text_parser_v2.yrl", 664).
yeccpars2_858_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_859_/1}).
-file("megaco_text_parser_v2.yrl", 663).
yeccpars2_859_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_860_/1}).
-file("megaco_text_parser_v2.yrl", 655).
yeccpars2_860_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditResult ,
    # 'AuditResult' { terminationID = __1 ,
    terminationAuditResult = __3 } }
  end | __Stack].

-compile({inline,yeccpars2_862_/1}).
-file("megaco_text_parser_v2.yrl", 645).
yeccpars2_862_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditCapReply , __3 }
  end | __Stack].

-compile({inline,yeccpars2_864_/1}).
-file("megaco_text_parser_v2.yrl", 641).
yeccpars2_864_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditCapReply , __4 }
  end | __Stack].

-compile({inline,yeccpars2_865_/1}).
-file("megaco_text_parser_v2.yrl", 556).
yeccpars2_865_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'ActionReply' .contextId , __5 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_867_/1}).
-file("megaco_text_parser_v2.yrl", 616).
yeccpars2_867_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_868_/1}).
-file("megaco_text_parser_v2.yrl", 607).
yeccpars2_868_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { __1 , # 'AmmsReply' { terminationID = [ __3 ] ,
    terminationAudit = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_871_/1}).
-file("megaco_text_parser_v2.yrl", 615).
yeccpars2_871_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_872_/1}).
-file("megaco_text_parser_v2.yrl", 561).
yeccpars2_872_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_action_reply ( [ __1 | __2 ] )
  end | __Stack].

-compile({inline,yeccpars2_874_/1}).
-file("megaco_text_parser_v2.yrl", 574).
yeccpars2_874_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 ]
  end | __Stack].

-compile({inline,yeccpars2_875_/1}).
-file("megaco_text_parser_v2.yrl", 577).
yeccpars2_875_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_876_/1}).
-file("megaco_text_parser_v2.yrl", 576).
yeccpars2_876_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_877_/1}).
-file("megaco_text_parser_v2.yrl", 549).
yeccpars2_877_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { actionReplies , [ __1 | __2 ] }
  end | __Stack].

-compile({inline,yeccpars2_879_/1}).
-file("megaco_text_parser_v2.yrl", 552).
yeccpars2_879_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_880_/1}).
-file("megaco_text_parser_v2.yrl", 551).
yeccpars2_880_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_881_/1}).
-file("megaco_text_parser_v2.yrl", 541).
yeccpars2_881_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionReply' { transactionId = __3 ,
    immAckRequired = __5 ,
    transactionResult = __6 }
  end | __Stack].

-compile({inline,yeccpars2_885_/1}).
-file("megaco_text_parser_v2.yrl", 481).
yeccpars2_885_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionPending' { transactionId = ensure_transactionID ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_886_/1}).
-file("megaco_text_parser_v2.yrl", 465).
yeccpars2_886_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_887_/1}).
-file("megaco_text_parser_v2.yrl", 931).
yeccpars2_887_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_pathName ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_888_/1}).
-file("megaco_text_parser_v2.yrl", 902).
yeccpars2_888_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { deviceName , __1 }
  end | __Stack].

-compile({inline,yeccpars2_889_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_889_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_890_/1}).
-file("megaco_text_parser_v2.yrl", 452).
yeccpars2_890_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_891_/1}).
-file("megaco_text_parser_v2.yrl", 919).
yeccpars2_891_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_mtpAddress ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_892_/1}).
-file("megaco_text_parser_v2.yrl", 895).
yeccpars2_892_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_893_/1}).
-file("megaco_text_parser_v2.yrl", 894).
yeccpars2_893_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].


-file("megaco_text_parser_v2.yrl", 1539).
