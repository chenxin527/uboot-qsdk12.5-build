-module(megaco_text_parser_prev3b).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("megaco_text_parser_prev3b.yrl", 1593).

%% The following directive is needed for (significantly) faster compilation
%% of the generated .erl file by the HiPE compiler.  Please do not remove.
-compile([{hipe,[{regalloc,linear_scan}]}]).

-include("megaco_text_parser_prev3b.hrl").



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



-file("./megaco_text_parser_prev3b.erl", 197).

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
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(104=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_104(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(105=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(106=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_106(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(107=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_107(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(108=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_108(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(109=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_109(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(110=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_110(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(111=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_111(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(112=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_112(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(113=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_113(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(114=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_114(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(115=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(116=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(117=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_117(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(118=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_118(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(119=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(120=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_120(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(121=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(122=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_128(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(129=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(130=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_130(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(140=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_140(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(147=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_147(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(148=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_148(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(149=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(150=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_150(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(151=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_151(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(152=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_152(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(153=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_153(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(166=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(167=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_167(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_176(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(177=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_177(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(178=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(179=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(180=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_180(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(181=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_181(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(182=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(183=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(184=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(185=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_185(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(186=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_186(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(187=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_187(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(188=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(189=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_189(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(190=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_190(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(191=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(192=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_192(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(193=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(194=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_194(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(195=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_195(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(196=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_196(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(197=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(198=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_198(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(199=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_199(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(200=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(201=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(202=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_202(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(203=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_203(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(204=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_204(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(205=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_205(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(206=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(207=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_207(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(208=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_208(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(209=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_209(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(210=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_210(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(211=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_211(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(212=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_212(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(218=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_218(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(219=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_219(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(220=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_220(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(221=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_221(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(222=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_222(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(223=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(224=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(225=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_225(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(226=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(227=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(228=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(229=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(230=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(231=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(232=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_232(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(233=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_233(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(234=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_234(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(235=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_235(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(236=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_236(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(237=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_237(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(238=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_238(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(239=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_239(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(240=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_240(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(241=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_241(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(242=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_242(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(243=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_243(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(244=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(245=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_245(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(246=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_246(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(247=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(248=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_248(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(249=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_249(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(250=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_250(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(251=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_251(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(252=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_252(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(253=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_253(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(254=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_254(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(255=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(256=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_256(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(257=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_257(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(258=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_258(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(259=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(260=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_260(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(261=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_261(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(262=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(263=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_263(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(264=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_264(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(265=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_265(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(266=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_266(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(267=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_267(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(268=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_268(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(269=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_269(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(270=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(271=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_271(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(272=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_272(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(273=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_273(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(274=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(275=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_275(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(276=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_276(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(277=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_277(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(278=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_278(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(279=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_279(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(280=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_280(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(281=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(282=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_282(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(283=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_283(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(284=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_284(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(285=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(286=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_286(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(287=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_287(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(288=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(289=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_289(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(290=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_290(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(291=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_291(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(292=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_292(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(293=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_293(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(294=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(295=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(296=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(297=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_297(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(298=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_298(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(299=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_299(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(300=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_300(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(301=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_301(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(302=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_302(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(303=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_303(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(304=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(305=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(306=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_306(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(307=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_307(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(308=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(309=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(310=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_310(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(311=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_311(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(312=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_312(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(313=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_313(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(314=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_314(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(315=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_315(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(316=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_316(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(317=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_317(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(318=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_318(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(319=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_252(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(320=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_320(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(326=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_326(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(327=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_327(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(328=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_328(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(329=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_329(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(330=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_330(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(331=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_331(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(332=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_332(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(333=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_333(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(334=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_334(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(335=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_335(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(336=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_336(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(342=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(343=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_343(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(344=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(345=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_345(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(346=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_346(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(347=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(348=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_348(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(349=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_349(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(350=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_350(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(351=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(352=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_352(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(353=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_353(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(354=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_354(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(355=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_355(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(356=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_327(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(357=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_357(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(358=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_358(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(359=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_359(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(360=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(378=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_378(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(379=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_379(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(380=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_380(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(381=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_381(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(382=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_382(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(383=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_383(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(384=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_384(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(385=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_385(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(386=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_386(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(387=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_387(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(393=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_393(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(399=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_399(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(400=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_400(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%%  yeccpars2_410(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(411=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_254(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(412=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_412(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(413=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_413(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_421(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(422=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_422(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(423=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(424=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_424(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(425=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_425(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(426=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_426(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(427=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_427(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(428=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(429=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_429(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(430=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(431=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_431(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(432=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_432(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(433=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_433(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(434=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(435=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_435(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(436=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(437=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_437(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(438=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_438(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(439=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_439(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(440=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_400(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(441=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_441(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(442=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_442(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(443=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_443(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(444=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_444(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(445=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(446=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_446(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(447=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(448=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_448(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(449=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_449(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(450=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_450(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(451=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_451(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(452=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_452(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(453=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_453(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(454=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(455=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_455(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(456=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_456(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(457=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_457(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(458=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(459=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_459(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(460=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_460(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(461=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_461(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(462=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_462(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(463=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_463(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(464=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_464(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(465=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_465(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(466=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_466(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(467=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(468=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_468(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(469=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_469(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(470=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_254(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(471=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_471(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(472=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_472(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(473=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(474=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_474(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(475=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_475(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(476=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_476(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(477=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_477(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(478=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_478(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(479=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(480=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_480(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(481=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_481(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(482=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_482(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(483=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_483(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(484=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_484(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(485=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_485(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(486=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_486(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(487=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_487(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(488=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_488(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(489=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_489(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(490=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_490(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(491=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_491(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(492=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_492(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(493=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_493(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(494=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_494(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(495=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_495(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(496=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_496(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(497=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_497(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(498=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_490(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(499=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_499(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(500=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_500(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(501=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_501(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(502=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_502(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(503=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_503(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(504=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_504(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(505=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_505(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(506=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_254(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(507=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_507(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(508=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_508(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(509=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_509(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(510=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(511=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_511(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(512=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_512(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(513=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(514=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_514(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(515=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_515(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(516=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_516(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(517=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_517(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(518=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_518(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(519=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_519(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(520=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(521=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_521(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(522=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_522(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(523=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_523(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(524=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(525=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_525(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(526=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_526(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(527=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(528=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_528(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(529=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_529(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(530=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_530(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(531=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_531(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(532=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_152(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(533=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_533(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(534=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_534(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(535=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(536=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_536(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(537=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_537(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(538=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_538(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(539=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_539(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(540=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_540(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(541=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_541(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(542=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_542(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(543=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_543(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(544=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_544(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(545=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_545(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(546=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_546(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(547=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_547(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(548=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_548(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(549=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_549(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(550=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_550(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(551=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_551(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(552=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_552(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(553=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_553(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(554=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_554(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(555=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_555(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(556=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_556(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(557=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(558=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_558(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(559=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_559(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(560=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(561=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_561(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(562=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_562(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(563=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(564=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_564(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(565=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_565(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(566=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_566(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(567=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_567(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(568=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_568(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(569=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_569(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(570=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_570(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(571=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_571(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(572=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(573=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_573(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(574=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(575=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_575(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(576=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_576(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(577=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(578=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_578(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(579=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_579(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(580=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_580(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(581=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_581(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(582=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_567(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(583=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_583(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(584=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_584(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(585=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_585(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(586=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(587=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_587(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(588=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_588(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(589=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_589(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(590=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(591=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_591(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(592=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_592(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(593=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(594=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_594(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(595=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_595(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(596=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_596(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(597=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(598=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(599=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_599(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(600=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_600(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(601=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_601(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(602=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(603=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_603(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(604=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_604(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(605=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_605(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(606=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_606(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(607=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(608=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_608(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(609=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_609(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(610=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_610(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(611=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_611(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(612=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_612(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(613=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_613(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(614=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_614(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(615=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_615(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(616=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_616(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(617=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_617(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(618=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_618(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(619=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_619(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(620=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_620(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(621=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_621(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(622=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_622(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(623=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_623(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(624=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_624(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(625=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_625(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(626=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_626(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(627=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_627(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(628=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_628(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(629=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_629(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(630=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_630(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(631=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_631(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(632=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_632(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(633=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_633(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(634=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_634(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(635=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_635(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(636=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_636(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(637=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_637(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(638=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_638(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(639=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_639(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(640=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_640(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(641=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_641(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(642=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_625(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(643=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_643(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(644=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_644(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(645=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_645(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(646=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(647=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_647(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(648=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_648(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(649=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_649(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(650=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_650(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(651=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_648(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(652=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_652(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(653=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_653(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(654=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_654(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(655=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_655(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(656=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_656(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(657=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_657(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(658=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_658(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(659=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_659(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(660=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_660(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(661=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_483(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(662=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_662(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(663=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_483(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(664=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_664(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(665=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_665(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(666=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_666(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(667=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_667(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(668=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_668(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(669=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_669(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(670=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_670(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(671=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_671(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(672=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_672(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(673=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_655(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(674=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_674(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(675=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_675(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(676=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_676(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(677=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_677(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(678=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_613(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(679=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_679(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(680=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_680(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(681=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_681(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(682=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(683=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_683(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(684=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(685=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_685(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(686=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_686(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(687=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_687(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(688=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_688(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(689=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_689(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(690=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_690(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(691=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_691(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(692=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_692(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(693=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_693(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(694=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_694(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(695=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_695(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(696=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_696(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(697=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_697(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(698=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_698(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(699=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_699(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(700=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_700(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(701=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(702=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_702(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(703=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(704=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_704(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(705=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_705(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(706=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_706(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(707=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_707(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(708=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_708(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(709=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_709(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(710=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_710(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(711=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_711(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(712=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_712(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(713=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_713(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(714=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_714(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(715=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_715(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(716=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_716(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(717=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_717(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(718=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_707(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(719=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_719(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(720=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_720(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(721=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_721(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(722=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_722(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(723=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(724=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_724(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(725=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_725(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(726=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_726(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(727=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_727(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(728=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_728(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(729=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_729(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(730=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_730(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(731=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_731(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(732=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_732(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(733=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_688(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(734=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_734(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(735=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_735(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(736=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_736(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(737=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_737(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(738=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(739=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_739(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(740=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_740(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(741=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_741(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(742=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_742(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(743=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_743(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_749(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(750=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_750(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(751=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_538(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(752=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_752(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(753=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_753(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(754=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_754(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(755=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_755(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(756=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(757=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_757(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(758=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_758(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(759=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_759(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(760=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_760(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(761=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_761(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(762=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(763=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_763(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(764=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_764(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(765=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_765(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(766=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(767=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_767(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(768=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_768(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(769=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_769(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(770=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(771=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_771(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(772=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_772(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(773=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_773(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(774=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(775=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_775(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(776=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_776(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(777=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_777(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(778=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(779=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_779(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(780=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_780(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(781=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_781(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(782=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_782(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(783=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_783(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(784=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_784(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(785=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_785(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(786=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_786(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(787=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_787(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(788=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(789=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_789(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(790=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_790(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(791=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_791(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(792=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_792(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(793=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_793(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(794=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_794(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(795=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_795(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(796=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_796(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(797=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_797(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(798=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_798(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(799=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_799(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(800=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_800(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(801=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_801(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(802=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_802(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(803=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_803(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(804=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_804(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(805=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_805(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(806=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_806(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(807=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_807(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(808=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(809=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_809(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(810=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_810(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(811=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_811(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(812=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_812(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(813=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_813(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(814=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_814(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(815=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_815(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(816=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_816(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(817=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_817(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(818=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_818(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(819=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_819(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(820=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_820(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(821=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_821(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(822=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_822(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(823=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_823(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(824=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_824(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(825=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_825(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(826=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_826(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(827=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_815(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(828=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_828(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(829=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_829(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(830=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_830(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(831=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_831(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(832=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_832(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(833=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(834=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_834(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(835=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_835(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(836=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_836(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(837=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_837(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(838=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_838(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(839=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_839(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(840=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_840(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(841=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_841(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(842=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_842(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(843=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_843(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(844=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_844(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(845=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_845(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(846=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_846(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(847=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_847(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(848=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(849=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_849(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(850=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_850(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(851=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_851(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(852=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_852(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(853=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_853(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(854=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_854(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(855=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_855(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(856=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_856(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(857=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_857(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(858=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_858(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(859=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_859(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(860=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_860(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(861=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_861(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(862=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_862(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(863=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_863(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(864=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_864(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(865=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_865(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(866=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_866(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(867=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_867(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(868=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_868(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(869=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_869(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(870=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_870(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(871=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_871(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(872=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_872(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(873=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_873(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(874=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_874(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(875=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_875(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(876=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_876(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(877=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(878=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_878(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(879=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_879(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(880=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(881=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_881(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(882=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_882(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(883=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_883(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(884=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_884(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(885=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_856(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(886=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_886(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(887=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_887(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(888=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_888(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(889=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_889(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(890=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_890(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(891=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_891(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(892=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_892(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(893=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_893(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(894=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(895=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_895(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(896=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_896(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(897=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_856(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(898=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_898(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(899=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_899(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(900=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_900(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(901=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_790(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(909=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_909(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(910=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(911=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_911(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(912=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_912(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(913=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_913(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(914=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_914(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(915=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_915(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(916=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_916(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(917=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_917(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(918=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_918(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(919=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_919(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(920=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_920(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(921=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_921(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
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
yeccpars2_cont_4(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
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
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
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

%% yeccpars2_103: see yeccpars2_4

yeccpars2_104(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_104(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_105: see yeccpars2_4

yeccpars2_106(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_106_(Stack),
 yeccpars2_107(_S, Cat, [106 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_107_(Stack),
 yeccgoto_authenticationHeader(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_108(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 115, Ss, Stack, T, Ts, Tzr);
yeccpars2_108(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_108(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_108(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_108_(Stack),
 yeccpars2_111(111, Cat, [108 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_109(S, endOfMessage, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 110, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_110(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_110_(Stack),
 yeccgoto_megacoMessage(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_111(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'MtpAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 919, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_112(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 140, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 142, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 143, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 144, Ss, Stack, T, Ts, Tzr);
yeccpars2_112(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mId(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mId(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_115: see yeccpars2_4

yeccpars2_116(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 119, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_116_(Stack),
 yeccpars2_118(118, Cat, [116 | Ss], NewStack, T, Ts, Tzr).

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
 yeccpars1(S, 119, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_117_(Stack),
 yeccpars2_126(_S, Cat, [117 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_118(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 121, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_119(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 119, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_119_(Stack),
 yeccpars2_120(_S, Cat, [119 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_120_(Stack),
 yeccgoto_daddr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_121(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 122, Ss, Stack, T, Ts, Tzr);
yeccpars2_121(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_121_(Stack),
 yeccgoto_domainAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_122: see yeccpars2_4

yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_123_(Stack),
 yeccgoto_portNumber(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_124(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_124(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_124_(Stack),
 yeccpars2_125(_S, Cat, [124 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_125_(Stack),
 yeccgoto_domainAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_126(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_126_(Stack),
 yeccgoto_daddr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_127(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 128, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_128(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 129, Ss, Stack, T, Ts, Tzr);
yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_128_(Stack),
 yeccgoto_domainName(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_129: see yeccpars2_4

yeccpars2_130(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_130(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_130_(Stack),
 yeccpars2_131(_S, Cat, [130 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_131_(Stack),
 yeccgoto_domainName(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_132_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

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
 yeccgoto_messageBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_137(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_137(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 142, Ss, Stack, T, Ts, Tzr);
yeccpars2_137(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 143, Ss, Stack, T, Ts, Tzr);
yeccpars2_137(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 144, Ss, Stack, T, Ts, Tzr);
yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_137_(Stack),
 yeccgoto_transactionList(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_138_(Stack),
 yeccgoto_message(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_139_(Stack),
 yeccgoto_messageBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_140(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 848, Ss, Stack, T, Ts, Tzr);
yeccpars2_140(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_141(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 910, Ss, Stack, T, Ts, Tzr);
yeccpars2_141(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_142(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 778, Ss, Stack, T, Ts, Tzr);
yeccpars2_142(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_143(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 770, Ss, Stack, T, Ts, Tzr);
yeccpars2_143(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_144(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 145, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 146, Ss, Stack, T, Ts, Tzr);
yeccpars2_144(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_145(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 762, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_146(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 148, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_147(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 756, Ss, Stack, T, Ts, Tzr);
yeccpars2_147(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_147_(Stack),
 yeccpars2_755(755, Cat, [147 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_148(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 149, Ss, Stack, T, Ts, Tzr);
yeccpars2_148(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_149: see yeccpars2_4

yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_150_(Stack),
 yeccgoto_contextID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_151(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 152, Ss, Stack, T, Ts, Tzr);
yeccpars2_151(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_152(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 168, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 169, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 171, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 172, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 174, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 175, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 176, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 177, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 178, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 179, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 180, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 181, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 182, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_153_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_156_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_158_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_159_(Stack),
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_160_(Stack),
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_162(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_162_(Stack),
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_163(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_164(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 535, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_166(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 532, Ss, Stack, T, Ts, Tzr);
yeccpars2_166(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_166_(Stack),
 yeccpars2_531(_S, Cat, [166 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_167(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 530, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_168_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_169(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 527, Ss, Stack, T, Ts, Tzr);
yeccpars2_169(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_170(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 524, Ss, Stack, T, Ts, Tzr);
yeccpars2_170(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_171(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 503, Ss, Stack, T, Ts, Tzr);
yeccpars2_171(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_172(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 487, Ss, Stack, T, Ts, Tzr);
yeccpars2_172(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_173(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_173_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_174_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_175(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 483, Ss, Stack, T, Ts, Tzr);
yeccpars2_175(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_176_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_177(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_177_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_178(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 447, Ss, Stack, T, Ts, Tzr);
yeccpars2_178(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_179(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 445, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_180(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 395, Ss, Stack, T, Ts, Tzr);
yeccpars2_180(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_181(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 201, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_182(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 183, Ss, Stack, T, Ts, Tzr);
yeccpars2_182(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_183: see yeccpars2_4

yeccpars2_184(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 197, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_184_(Stack),
 yeccpars2_196(196, Cat, [184 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_terminationA(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_186(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 188, Ss, Stack, T, Ts, Tzr);
yeccpars2_186(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_187_(Stack),
 yeccgoto_terminationID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_188: see yeccpars2_4

yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_terminationB(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_190(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 191, Ss, Stack, T, Ts, Tzr);
yeccpars2_190(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_191(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 193, Ss, Stack, T, Ts, Tzr);
yeccpars2_191(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 194, Ss, Stack, T, Ts, Tzr);
yeccpars2_191(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 195, Ss, Stack, T, Ts, Tzr);
yeccpars2_191(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_192(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_192_(Stack),
 yeccgoto_topologyTriple(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_193(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_193_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_194(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_194_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_195(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_195_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_196(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 200, Ss, Stack, T, Ts, Tzr);
yeccpars2_196(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_197: see yeccpars2_4

yeccpars2_198(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 197, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_198_(Stack),
 yeccpars2_199(_S, Cat, [198 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_199_(Stack),
 yeccgoto_topologyTripleList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_200_(Stack),
 yeccgoto_topologyDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_201: see yeccpars2_4

yeccpars2_202(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 204, Ss, Stack, T, Ts, Tzr);
yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_202_(Stack),
 yeccpars2_203(_S, Cat, [202 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_203_(Stack),
 yeccgoto_subtractRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_204(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 206, Ss, Stack, T, Ts, Tzr);
yeccpars2_204(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_205(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 394, Ss, Stack, T, Ts, Tzr);
yeccpars2_205(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_206(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 207, Ss, Stack, T, Ts, Tzr);
yeccpars2_206(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_207(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 222, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 223, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 224, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 225, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 226, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 227, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 228, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 229, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 230, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_207_(Stack),
 yeccpars2_219(219, Cat, [207 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_208_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_209_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_210_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_211_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_212(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_212_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_213_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_214_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_215_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_216(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 386, Ss, Stack, T, Ts, Tzr);
yeccpars2_216(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_216_(Stack),
 yeccpars2_385(_S, Cat, [216 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_217(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_auditItem(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_218(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 382, Ss, Stack, T, Ts, Tzr);
yeccpars2_218(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_218_(Stack),
 yeccpars2_381(_S, Cat, [218 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_219(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 380, Ss, Stack, T, Ts, Tzr);
yeccpars2_219(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_220(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_220_(Stack),
 yeccgoto_indAuddigitMapDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_221(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_221_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_222(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 366, Ss, Stack, T, Ts, Tzr);
yeccpars2_222(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_222_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_223(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 360, Ss, Stack, T, Ts, Tzr);
yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_223_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_224(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 327, Ss, Stack, T, Ts, Tzr);
yeccpars2_224(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_224_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_225(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_225_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_226_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_227_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_228(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 323, Ss, Stack, T, Ts, Tzr);
yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_228_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_229(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 236, Ss, Stack, T, Ts, Tzr);
yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_229_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_230(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 231, Ss, Stack, T, Ts, Tzr);
yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_230_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_231: see yeccpars2_4

yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_232_(Stack),
 yeccgoto_pkgdName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_233(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 234, Ss, Stack, T, Ts, Tzr);
yeccpars2_233(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_234(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_234_(Stack),
 yeccgoto_indAudstatisticsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_235(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_235_(Stack),
 yeccgoto_indAudsignalsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_236(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 242, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 243, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_237(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_237_(Stack),
 yeccgoto_indAudsignalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_238(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 252, Ss, Stack, T, Ts, Tzr);
yeccpars2_238(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_238_(Stack),
 yeccgoto_signalRequest(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_signalName(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_240(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 251, Ss, Stack, T, Ts, Tzr);
yeccpars2_240(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_241(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_241_(Stack),
 yeccgoto_indAudsignalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_242(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_242_(Stack),
 yeccgoto_optIndAudsignalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_243(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 244, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_244: see yeccpars2_4

yeccpars2_245(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 247, Ss, Stack, T, Ts, Tzr);
yeccpars2_245(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_246(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_246_(Stack),
 yeccgoto_signalListId(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_247: see yeccpars2_4

yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_signalListParm(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_249(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 250, Ss, Stack, T, Ts, Tzr);
yeccpars2_249(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_250(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_250_(Stack),
 yeccgoto_indAudsignalList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_251(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_251_(Stack),
 yeccgoto_optIndAudsignalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_252(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 255, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 256, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 257, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 258, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 259, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 260, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 261, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_253(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 319, Ss, Stack, T, Ts, Tzr);
yeccpars2_253(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_253_(Stack),
 yeccpars2_318(318, Cat, [253 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_254(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 293, Ss, Stack, T, Ts, Tzr);
yeccpars2_254(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 294, Ss, Stack, T, Ts, Tzr);
yeccpars2_254(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 295, Ss, Stack, T, Ts, Tzr);
yeccpars2_254(S, 'NEQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 296, Ss, Stack, T, Ts, Tzr);
yeccpars2_254(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_255(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 287, Ss, Stack, T, Ts, Tzr);
yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_256(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 285, Ss, Stack, T, Ts, Tzr);
yeccpars2_256(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_257(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_257_COMMA(Stack),
 yeccgoto_sigParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_257(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_257_RBRKT(Stack),
 yeccgoto_sigParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_257(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_258(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 273, Ss, Stack, T, Ts, Tzr);
yeccpars2_258(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_259(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 270, Ss, Stack, T, Ts, Tzr);
yeccpars2_259(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_260(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 265, Ss, Stack, T, Ts, Tzr);
yeccpars2_260(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_261(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 262, Ss, Stack, T, Ts, Tzr);
yeccpars2_261(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_262: see yeccpars2_4

yeccpars2_263(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_263_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_264_(Stack),
 yeccgoto_streamID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_265(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 267, Ss, Stack, T, Ts, Tzr);
yeccpars2_265(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 268, Ss, Stack, T, Ts, Tzr);
yeccpars2_265(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 269, Ss, Stack, T, Ts, Tzr);
yeccpars2_265(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_266(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_266_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_267(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_267_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_268(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_268_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_269(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_269_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_270: see yeccpars2_4

yeccpars2_271(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_271_(Stack),
 yeccgoto_requestID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_272(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_272_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_273(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 274, Ss, Stack, T, Ts, Tzr);
yeccpars2_273(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_274(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 276, Ss, Stack, T, Ts, Tzr);
yeccpars2_274(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 277, Ss, Stack, T, Ts, Tzr);
yeccpars2_274(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 278, Ss, Stack, T, Ts, Tzr);
yeccpars2_274(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 279, Ss, Stack, T, Ts, Tzr);
yeccpars2_274(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_275(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 281, Ss, Stack, T, Ts, Tzr);
yeccpars2_275(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_275_(Stack),
 yeccpars2_280(280, Cat, [275 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_276(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_276_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_277(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_277_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_278(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_278_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_279(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_279_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_280(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 284, Ss, Stack, T, Ts, Tzr);
yeccpars2_280(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_281: see yeccpars2_274

yeccpars2_282(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 281, Ss, Stack, T, Ts, Tzr);
yeccpars2_282(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_282_(Stack),
 yeccpars2_283(_S, Cat, [282 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_283(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_283_(Stack),
 yeccgoto_notificationReasons(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_284(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_284_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_285: see yeccpars2_4

yeccpars2_286(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_286_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_287(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 289, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'ExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 290, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'InternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 291, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_288(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_288_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_289(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_289_(Stack),
 yeccgoto_direction(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_290(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_290_(Stack),
 yeccgoto_direction(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_291(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_291_(Stack),
 yeccgoto_direction(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_292_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_293(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 304, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 305, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 299, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_294(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 299, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_295: see yeccpars2_294

%% yeccpars2_296: see yeccpars2_294

yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_297_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_298_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_299(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_299_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_300(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_300_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_301_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_302(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_302_(Stack),
 yeccgoto_alternativeValue(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_303_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_304: see yeccpars2_294

%% yeccpars2_305: see yeccpars2_294

yeccpars2_306(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 308, Ss, Stack, T, Ts, Tzr);
yeccpars2_306(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 309, Ss, Stack, T, Ts, Tzr);
yeccpars2_306(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_306_(Stack),
 yeccpars2_307(307, Cat, [306 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_307(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 314, Ss, Stack, T, Ts, Tzr);
yeccpars2_307(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_308: see yeccpars2_294

%% yeccpars2_309: see yeccpars2_294

yeccpars2_310(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 309, Ss, Stack, T, Ts, Tzr);
yeccpars2_310(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_310_(Stack),
 yeccpars2_311(_S, Cat, [310 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_311(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_311_(Stack),
 yeccgoto_valueList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_312(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 313, Ss, Stack, T, Ts, Tzr);
yeccpars2_312(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_313(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_313_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_314(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_314_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_315(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 309, Ss, Stack, T, Ts, Tzr);
yeccpars2_315(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_315_(Stack),
 yeccpars2_316(316, Cat, [315 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_316(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 317, Ss, Stack, T, Ts, Tzr);
yeccpars2_316(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_317(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_317_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_318(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 322, Ss, Stack, T, Ts, Tzr);
yeccpars2_318(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_319: see yeccpars2_252

yeccpars2_320(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 319, Ss, Stack, T, Ts, Tzr);
yeccpars2_320(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_320_(Stack),
 yeccpars2_321(_S, Cat, [320 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_321(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_321_(Stack),
 yeccgoto_sigParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_322(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_322_(Stack),
 yeccgoto_signalRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_323: see yeccpars2_4

yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_324_(Stack),
 yeccgoto_packagesItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_325(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 326, Ss, Stack, T, Ts, Tzr);
yeccpars2_325(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_326(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_326_(Stack),
 yeccgoto_indAudpackagesDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_327(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 334, Ss, Stack, T, Ts, Tzr);
yeccpars2_327(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 335, Ss, Stack, T, Ts, Tzr);
yeccpars2_327(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 336, Ss, Stack, T, Ts, Tzr);
yeccpars2_327(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 337, Ss, Stack, T, Ts, Tzr);
yeccpars2_327(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_328(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_328_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_329_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_330(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_330_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_331(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_331_(Stack),
 yeccgoto_indAudstreamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_332(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 356, Ss, Stack, T, Ts, Tzr);
yeccpars2_332(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_332_(Stack),
 yeccpars2_355(355, Cat, [332 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_333(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_333_(Stack),
 yeccgoto_indAudstreamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_334(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 347, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_335(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 231, Ss, Stack, T, Ts, Tzr);
yeccpars2_335(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_336(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 342, Ss, Stack, T, Ts, Tzr);
yeccpars2_336(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_337(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 338, Ss, Stack, T, Ts, Tzr);
yeccpars2_337(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_338: see yeccpars2_4

yeccpars2_339(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_339_(Stack),
 yeccgoto_indAudterminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_340(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 341, Ss, Stack, T, Ts, Tzr);
yeccpars2_340(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_341(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_341_(Stack),
 yeccgoto_indAudterminationStateDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_342: see yeccpars2_4

yeccpars2_343(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 344, Ss, Stack, T, Ts, Tzr);
yeccpars2_343(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_344(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 334, Ss, Stack, T, Ts, Tzr);
yeccpars2_344(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 335, Ss, Stack, T, Ts, Tzr);
yeccpars2_344(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_345(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 346, Ss, Stack, T, Ts, Tzr);
yeccpars2_345(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_346(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_346_(Stack),
 yeccgoto_indAudstreamDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_347: see yeccpars2_4

yeccpars2_348(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_348_(Stack),
 yeccgoto_indAudlocalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_349(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 351, Ss, Stack, T, Ts, Tzr);
yeccpars2_349(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_349_(Stack),
 yeccpars2_350(350, Cat, [349 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_350(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 354, Ss, Stack, T, Ts, Tzr);
yeccpars2_350(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_351: see yeccpars2_4

yeccpars2_352(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 351, Ss, Stack, T, Ts, Tzr);
yeccpars2_352(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_352_(Stack),
 yeccpars2_353(_S, Cat, [352 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_353(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_353_(Stack),
 yeccgoto_indAudlocalParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_354(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_354_(Stack),
 yeccgoto_indAudlocalControlDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_355(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 359, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_356: see yeccpars2_327

yeccpars2_357(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 356, Ss, Stack, T, Ts, Tzr);
yeccpars2_357(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_357_(Stack),
 yeccpars2_358(_S, Cat, [357 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_358(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_358_(Stack),
 yeccgoto_indAudmediaParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_359(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_359_(Stack),
 yeccgoto_indAudmediaDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_360: see yeccpars2_4

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
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 376, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_372_(Stack),
 yeccgoto_eventParameterName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_373(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 379, Ss, Stack, T, Ts, Tzr);
yeccpars2_373(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_374_(Stack),
 yeccgoto_indAudeventSpecParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_375(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_375_(Stack),
 yeccgoto_indAudeventSpecParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_376(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 377, Ss, Stack, T, Ts, Tzr);
yeccpars2_376(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_377: see yeccpars2_4

yeccpars2_378(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_378_(Stack),
 yeccgoto_eventStream(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_379(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_379_(Stack),
 yeccgoto_optIndAudeventSpecParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_380(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_380_(Stack),
 yeccgoto_auditDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_381(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_381_(Stack),
 yeccgoto_auditDescriptorBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_382(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 222, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 223, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 224, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 225, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 226, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 227, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 228, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 229, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 230, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_383(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 382, Ss, Stack, T, Ts, Tzr);
yeccpars2_383(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_383_(Stack),
 yeccpars2_384(_S, Cat, [383 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_384(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_384_(Stack),
 yeccgoto_auditItemList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_385(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_385_(Stack),
 yeccgoto_indAudterminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_386(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 388, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 389, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 390, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 391, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 392, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 335, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_387(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 386, Ss, Stack, T, Ts, Tzr);
yeccpars2_387(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_387_(Stack),
 yeccpars2_393(_S, Cat, [387 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_388(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 366, Ss, Stack, T, Ts, Tzr);
yeccpars2_388(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_389(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 360, Ss, Stack, T, Ts, Tzr);
yeccpars2_389(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_390(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 327, Ss, Stack, T, Ts, Tzr);
yeccpars2_390(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_391(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 323, Ss, Stack, T, Ts, Tzr);
yeccpars2_391(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_392(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 236, Ss, Stack, T, Ts, Tzr);
yeccpars2_392(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_393(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_393_(Stack),
 yeccgoto_indAudterminationAuditList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_394(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_394_(Stack),
 yeccgoto_optAuditDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_395: see yeccpars2_4

yeccpars2_396(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 397, Ss, Stack, T, Ts, Tzr);
yeccpars2_396(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_397(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 399, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_398(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 444, Ss, Stack, T, Ts, Tzr);
yeccpars2_398(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_399(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 400, Ss, Stack, T, Ts, Tzr);
yeccpars2_399(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_400(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 414, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 222, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 223, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 224, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 415, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 416, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 225, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 226, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 227, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 228, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 417, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 418, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 419, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ServiceChangeIncompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 420, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 229, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 230, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 422, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_401_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_402_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_403_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_404(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_404_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_405(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 440, Ss, Stack, T, Ts, Tzr);
yeccpars2_405(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_405_(Stack),
 yeccpars2_439(439, Cat, [405 | Ss], NewStack, T, Ts, Tzr).

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
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_410(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_410_(Stack),
 yeccgoto_extensionParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_411: see yeccpars2_254

yeccpars2_412(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_412_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_413(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_413_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_414(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 436, Ss, Stack, T, Ts, Tzr);
yeccpars2_414(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_415(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 434, Ss, Stack, T, Ts, Tzr);
yeccpars2_415(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_416(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 432, Ss, Stack, T, Ts, Tzr);
yeccpars2_416(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_417(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 430, Ss, Stack, T, Ts, Tzr);
yeccpars2_417(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_418(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 428, Ss, Stack, T, Ts, Tzr);
yeccpars2_418(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_419(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 425, Ss, Stack, T, Ts, Tzr);
yeccpars2_419(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_420(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_420_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_421(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_421_(Stack),
 yeccgoto_timeStamp(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_422(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 423, Ss, Stack, T, Ts, Tzr);
yeccpars2_422(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_423: see yeccpars2_4

yeccpars2_424(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_424_(Stack),
 yeccgoto_serviceChangeVersion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_425(S, 'AndAUDITSelectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 115, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 88, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 89, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 94, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 99, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 101, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_425_(Stack),
 yeccpars2_111(111, Cat, [425 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_426(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_426_(Stack),
 yeccgoto_serviceChangeAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_427(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_427_(Stack),
 yeccgoto_serviceChangeAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_428: see yeccpars2_294

yeccpars2_429(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_429_(Stack),
 yeccgoto_serviceChangeReason(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_430: see yeccpars2_4

yeccpars2_431(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_431_(Stack),
 yeccgoto_serviceChangeProfile(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_432(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 115, Ss, Stack, T, Ts, Tzr);
yeccpars2_432(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 116, Ss, Stack, T, Ts, Tzr);
yeccpars2_432(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_432(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_432_(Stack),
 yeccpars2_111(111, Cat, [432 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_433_(Stack),
 yeccgoto_serviceChangeMgcId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_434: see yeccpars2_4

yeccpars2_435(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_435_(Stack),
 yeccgoto_serviceChangeMethod(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_436: see yeccpars2_4

yeccpars2_437(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_437_(Stack),
 yeccgoto_serviceChangeDelay(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_438(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_438_(Stack),
 yeccgoto_extension(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_439(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 443, Ss, Stack, T, Ts, Tzr);
yeccpars2_439(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_440: see yeccpars2_400

yeccpars2_441(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 440, Ss, Stack, T, Ts, Tzr);
yeccpars2_441(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_441_(Stack),
 yeccpars2_442(_S, Cat, [441 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_442(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_442_(Stack),
 yeccgoto_serviceChangeParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_443(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_443_(Stack),
 yeccgoto_serviceChangeDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_444(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_444_(Stack),
 yeccgoto_serviceChangeRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_445: see yeccpars2_4

yeccpars2_446(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_446_(Stack),
 yeccgoto_priority(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_447: see yeccpars2_4

yeccpars2_448(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 449, Ss, Stack, T, Ts, Tzr);
yeccpars2_448(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_449(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 140, Ss, Stack, T, Ts, Tzr);
yeccpars2_449(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 453, Ss, Stack, T, Ts, Tzr);
yeccpars2_449(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_450(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_450_(Stack),
 yeccgoto_notifyRequestBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_451(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 482, Ss, Stack, T, Ts, Tzr);
yeccpars2_451(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_452(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_452_(Stack),
 yeccgoto_notifyRequestBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_453(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 454, Ss, Stack, T, Ts, Tzr);
yeccpars2_453(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_454: see yeccpars2_4

yeccpars2_455(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 456, Ss, Stack, T, Ts, Tzr);
yeccpars2_455(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_456(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_456(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_456_(Stack),
 yeccpars2_4(458, Cat, [456 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_457(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_457(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_457_(Stack),
 yeccpars2_477(477, Cat, [457 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_458: see yeccpars2_4

yeccpars2_459(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 461, Ss, Stack, T, Ts, Tzr);
yeccpars2_459(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_459_(Stack),
 yeccpars2_460(460, Cat, [459 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_460(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 464, Ss, Stack, T, Ts, Tzr);
yeccpars2_460(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_461(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_461(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_461(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_461_(Stack),
 yeccpars2_4(458, Cat, [461 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_462(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 461, Ss, Stack, T, Ts, Tzr);
yeccpars2_462(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_462_(Stack),
 yeccpars2_463(_S, Cat, [462 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_463(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_463_(Stack),
 yeccgoto_observedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_464(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_464_(Stack),
 yeccgoto_observedEventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_465(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 467, Ss, Stack, T, Ts, Tzr);
yeccpars2_465(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_465_(Stack),
 yeccpars2_466(_S, Cat, [465 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_466(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_466_(Stack),
 yeccgoto_observedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_467: see yeccpars2_4

yeccpars2_468(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 473, Ss, Stack, T, Ts, Tzr);
yeccpars2_468(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_468_(Stack),
 yeccpars2_472(472, Cat, [468 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_469(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_observedEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_470: see yeccpars2_254

yeccpars2_471(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_471_(Stack),
 yeccgoto_eventStreamOrOther(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_472(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 476, Ss, Stack, T, Ts, Tzr);
yeccpars2_472(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_473: see yeccpars2_4

yeccpars2_474(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 473, Ss, Stack, T, Ts, Tzr);
yeccpars2_474(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_474_(Stack),
 yeccpars2_475(_S, Cat, [474 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_475(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_475_(Stack),
 yeccgoto_observedEventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_476(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_476_(Stack),
 yeccgoto_observedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_477(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 478, Ss, Stack, T, Ts, Tzr);
yeccpars2_477(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_478(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_478(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_478_(Stack),
 yeccpars2_4(479, Cat, [478 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_479: see yeccpars2_4

yeccpars2_480(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 467, Ss, Stack, T, Ts, Tzr);
yeccpars2_480(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_480_(Stack),
 yeccpars2_481(_S, Cat, [480 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_481(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_481_(Stack),
 yeccgoto_observedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_482(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_482_(Stack),
 yeccgoto_notifyRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_483(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 485, Ss, Stack, T, Ts, Tzr);
yeccpars2_483(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 486, Ss, Stack, T, Ts, Tzr);
yeccpars2_483(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_484(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_484_(Stack),
 yeccgoto_iepsValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_485(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_485_(Stack),
 yeccgoto_onOrOff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_486(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_486_(Stack),
 yeccgoto_onOrOff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_487(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 489, Ss, Stack, T, Ts, Tzr);
yeccpars2_487(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_488(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 502, Ss, Stack, T, Ts, Tzr);
yeccpars2_488(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_489(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 490, Ss, Stack, T, Ts, Tzr);
yeccpars2_489(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_490(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 493, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 494, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 495, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 496, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_490(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_491(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_491_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_492(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 498, Ss, Stack, T, Ts, Tzr);
yeccpars2_492(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_492_(Stack),
 yeccpars2_497(497, Cat, [492 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_493(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_493_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_494(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_494_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_495(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_495_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_496(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_496_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_497(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 501, Ss, Stack, T, Ts, Tzr);
yeccpars2_497(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_498: see yeccpars2_490

yeccpars2_499(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 498, Ss, Stack, T, Ts, Tzr);
yeccpars2_499(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_499_(Stack),
 yeccpars2_500(_S, Cat, [499 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_500(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_500_(Stack),
 yeccgoto_contextAuditProperties(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_501(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_501_(Stack),
 yeccgoto_indAudcontextAttrDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_502(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_502_(Stack),
 yeccgoto_contextAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_503(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 508, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_503(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_504(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 523, Ss, Stack, T, Ts, Tzr);
yeccpars2_504(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_505(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 520, Ss, Stack, T, Ts, Tzr);
yeccpars2_505(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_505_(Stack),
 yeccpars2_519(_S, Cat, [505 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_506: see yeccpars2_254

yeccpars2_507(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 517, Ss, Stack, T, Ts, Tzr);
yeccpars2_507(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_508(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 509, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_509(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 510, Ss, Stack, T, Ts, Tzr);
yeccpars2_509(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_510: see yeccpars2_4

yeccpars2_511(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 513, Ss, Stack, T, Ts, Tzr);
yeccpars2_511(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_511_(Stack),
 yeccpars2_512(512, Cat, [511 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_512(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 516, Ss, Stack, T, Ts, Tzr);
yeccpars2_512(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_513: see yeccpars2_4

yeccpars2_514(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 513, Ss, Stack, T, Ts, Tzr);
yeccpars2_514(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_514_(Stack),
 yeccpars2_515(_S, Cat, [514 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_515(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_515_(Stack),
 yeccgoto_contextIDs(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_516(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_516_(Stack),
 yeccgoto_contextIdList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_517(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_517_(Stack),
 yeccgoto_contextAttrDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_518(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_518_(Stack),
 yeccgoto_propertyParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_519(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_519_(Stack),
 yeccgoto_propertyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_520: see yeccpars2_4

yeccpars2_521(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 520, Ss, Stack, T, Ts, Tzr);
yeccpars2_521(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_521_(Stack),
 yeccpars2_522(_S, Cat, [521 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_522(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_522_(Stack),
 yeccgoto_propertyParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_523(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_523_(Stack),
 yeccgoto_contextAttrDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_524: see yeccpars2_4

yeccpars2_525(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 204, Ss, Stack, T, Ts, Tzr);
yeccpars2_525(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_525_(Stack),
 yeccpars2_526(_S, Cat, [525 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_526(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_526_(Stack),
 yeccgoto_auditRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_527: see yeccpars2_4

yeccpars2_528(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 204, Ss, Stack, T, Ts, Tzr);
yeccpars2_528(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_528_(Stack),
 yeccpars2_529(_S, Cat, [528 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_529(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_529_(Stack),
 yeccgoto_auditRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_530(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_530_(Stack),
 yeccgoto_actionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_531(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_531_(Stack),
 yeccgoto_actionRequestBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_532: see yeccpars2_152

yeccpars2_533(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 532, Ss, Stack, T, Ts, Tzr);
yeccpars2_533(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_533_(Stack),
 yeccpars2_534(_S, Cat, [533 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_534(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_534_(Stack),
 yeccgoto_actionRequestItems(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_535: see yeccpars2_4

yeccpars2_536(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 538, Ss, Stack, T, Ts, Tzr);
yeccpars2_536(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_536_(Stack),
 yeccpars2_537(_S, Cat, [536 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_537(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_537_(Stack),
 yeccgoto_ammRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_538(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 206, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 549, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 550, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 551, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 552, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 553, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 554, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 555, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 556, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_539(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_539_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_540(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_540_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_541(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_541_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_542(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_542_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_543(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_543_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_544(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_544_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_545(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_545_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_546(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_546_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_547(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_547_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_548(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 751, Ss, Stack, T, Ts, Tzr);
yeccpars2_548(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_548_(Stack),
 yeccpars2_750(750, Cat, [548 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_549(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_549_(Stack),
 yeccgoto_digitMapDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_550(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 742, Ss, Stack, T, Ts, Tzr);
yeccpars2_550(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_550_(Stack),
 yeccgoto_eventBufferDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_551(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 682, Ss, Stack, T, Ts, Tzr);
yeccpars2_551(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_551_(Stack),
 yeccgoto_eventsDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_552(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 613, Ss, Stack, T, Ts, Tzr);
yeccpars2_552(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_553(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 597, Ss, Stack, T, Ts, Tzr);
yeccpars2_553(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 598, Ss, Stack, T, Ts, Tzr);
yeccpars2_553(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_554(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 586, Ss, Stack, T, Ts, Tzr);
yeccpars2_554(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_555(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 567, Ss, Stack, T, Ts, Tzr);
yeccpars2_555(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_555_(Stack),
 yeccgoto_signalsDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_556(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 557, Ss, Stack, T, Ts, Tzr);
yeccpars2_556(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_557: see yeccpars2_4

yeccpars2_558(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 563, Ss, Stack, T, Ts, Tzr);
yeccpars2_558(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_558_(Stack),
 yeccpars2_562(562, Cat, [558 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_559(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 560, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_559_(Stack),
 yeccgoto_statisticsParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_560: see yeccpars2_294

yeccpars2_561(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_561_(Stack),
 yeccgoto_statisticsParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_562(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 566, Ss, Stack, T, Ts, Tzr);
yeccpars2_562(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_563: see yeccpars2_4

yeccpars2_564(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 563, Ss, Stack, T, Ts, Tzr);
yeccpars2_564(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_564_(Stack),
 yeccpars2_565(_S, Cat, [564 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_565(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_565_(Stack),
 yeccgoto_statisticsParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_566(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_566_(Stack),
 yeccgoto_statisticsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_567(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 571, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_567(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_568(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_568_(Stack),
 yeccgoto_signalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_569(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 582, Ss, Stack, T, Ts, Tzr);
yeccpars2_569(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_569_(Stack),
 yeccpars2_581(581, Cat, [569 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_570(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_570_(Stack),
 yeccgoto_signalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_571(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 572, Ss, Stack, T, Ts, Tzr);
yeccpars2_571(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_572: see yeccpars2_4

yeccpars2_573(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 574, Ss, Stack, T, Ts, Tzr);
yeccpars2_573(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_574: see yeccpars2_4

yeccpars2_575(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 577, Ss, Stack, T, Ts, Tzr);
yeccpars2_575(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_575_(Stack),
 yeccpars2_576(576, Cat, [575 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_576(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 580, Ss, Stack, T, Ts, Tzr);
yeccpars2_576(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_577: see yeccpars2_4

yeccpars2_578(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 577, Ss, Stack, T, Ts, Tzr);
yeccpars2_578(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_578_(Stack),
 yeccpars2_579(_S, Cat, [578 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_579_(Stack),
 yeccgoto_signalListParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_580(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_580_(Stack),
 yeccgoto_signalList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_581(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 585, Ss, Stack, T, Ts, Tzr);
yeccpars2_581(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_582: see yeccpars2_567

yeccpars2_583(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 582, Ss, Stack, T, Ts, Tzr);
yeccpars2_583(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_583_(Stack),
 yeccpars2_584(_S, Cat, [583 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_584(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_584_(Stack),
 yeccgoto_signalParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_585(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_585_(Stack),
 yeccgoto_signalsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_586: see yeccpars2_4

yeccpars2_587(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_587_(Stack),
 yeccgoto_muxType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_588(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 590, Ss, Stack, T, Ts, Tzr);
yeccpars2_588(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_589(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_589_(Stack),
 yeccgoto_muxDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_590: see yeccpars2_4

yeccpars2_591(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 593, Ss, Stack, T, Ts, Tzr);
yeccpars2_591(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_591_(Stack),
 yeccpars2_592(592, Cat, [591 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_592(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 596, Ss, Stack, T, Ts, Tzr);
yeccpars2_592(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_593: see yeccpars2_4

yeccpars2_594(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 593, Ss, Stack, T, Ts, Tzr);
yeccpars2_594(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_594_(Stack),
 yeccpars2_595(_S, Cat, [594 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_595(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_595_(Stack),
 yeccgoto_terminationIDListRepeat(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_596(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_596_(Stack),
 yeccgoto_terminationIDList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_597: see yeccpars2_4

%% yeccpars2_598: see yeccpars2_4

yeccpars2_599(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_599_(Stack),
 yeccgoto_modemType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_600(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 602, Ss, Stack, T, Ts, Tzr);
yeccpars2_600(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_600_(Stack),
 yeccpars2_601(601, Cat, [600 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_601(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 605, Ss, Stack, T, Ts, Tzr);
yeccpars2_601(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_602: see yeccpars2_4

yeccpars2_603(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 602, Ss, Stack, T, Ts, Tzr);
yeccpars2_603(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_603_(Stack),
 yeccpars2_604(_S, Cat, [603 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_604_(Stack),
 yeccgoto_modemTypeList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_605(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 607, Ss, Stack, T, Ts, Tzr);
yeccpars2_605(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_605_(Stack),
 yeccpars2_606(_S, Cat, [605 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_606(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_606_(Stack),
 yeccgoto_modemDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_607: see yeccpars2_4

yeccpars2_608(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 520, Ss, Stack, T, Ts, Tzr);
yeccpars2_608(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_608_(Stack),
 yeccpars2_609(609, Cat, [608 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_609(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 610, Ss, Stack, T, Ts, Tzr);
yeccpars2_609(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_610(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_610_(Stack),
 yeccgoto_optPropertyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_611(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 607, Ss, Stack, T, Ts, Tzr);
yeccpars2_611(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_611_(Stack),
 yeccpars2_612(_S, Cat, [611 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_612(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_612_(Stack),
 yeccgoto_modemDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_613(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 556, Ss, Stack, T, Ts, Tzr);
yeccpars2_613(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 623, Ss, Stack, T, Ts, Tzr);
yeccpars2_613(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 624, Ss, Stack, T, Ts, Tzr);
yeccpars2_613(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_613(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_613(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 620, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_613(S, 'LocalDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 621, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_613(S, 'RemoteDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 622, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_613(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_614(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_614_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_615(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_615_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_616(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_616_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_617(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_617_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_618(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 678, Ss, Stack, T, Ts, Tzr);
yeccpars2_618(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_618_(Stack),
 yeccpars2_677(677, Cat, [618 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_619(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_619_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_620(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 655, Ss, Stack, T, Ts, Tzr);
yeccpars2_620(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_621(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_621_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_622(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_622_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_623(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 646, Ss, Stack, T, Ts, Tzr);
yeccpars2_623(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_624(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 625, Ss, Stack, T, Ts, Tzr);
yeccpars2_624(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_625(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 630, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 631, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_625(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_626(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 642, Ss, Stack, T, Ts, Tzr);
yeccpars2_626(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_626_(Stack),
 yeccpars2_641(641, Cat, [626 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_627(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_627_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_628(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_628_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_629(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_629_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_630(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 637, Ss, Stack, T, Ts, Tzr);
yeccpars2_630(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_631(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 632, Ss, Stack, T, Ts, Tzr);
yeccpars2_631(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_632(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 634, Ss, Stack, T, Ts, Tzr);
yeccpars2_632(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 635, Ss, Stack, T, Ts, Tzr);
yeccpars2_632(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 636, Ss, Stack, T, Ts, Tzr);
yeccpars2_632(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_633(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_633_(Stack),
 yeccgoto_serviceStates(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_634(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_634_(Stack),
 yeccgoto_serviceState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_635(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_635_(Stack),
 yeccgoto_serviceState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_636(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_636_(Stack),
 yeccgoto_serviceState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_637(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 639, Ss, Stack, T, Ts, Tzr);
yeccpars2_637(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 640, Ss, Stack, T, Ts, Tzr);
yeccpars2_637(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_638(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_638_(Stack),
 yeccgoto_eventBufferControl(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_639(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_639_(Stack),
 yeccgoto_eventBufferControlState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_640(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_640_(Stack),
 yeccgoto_eventBufferControlState(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_641(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 645, Ss, Stack, T, Ts, Tzr);
yeccpars2_641(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_642: see yeccpars2_625

yeccpars2_643(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 642, Ss, Stack, T, Ts, Tzr);
yeccpars2_643(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_643_(Stack),
 yeccpars2_644(_S, Cat, [643 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_644(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_644_(Stack),
 yeccgoto_terminationStateParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_645(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_645_(Stack),
 yeccgoto_terminationStateDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_646: see yeccpars2_4

yeccpars2_647(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 648, Ss, Stack, T, Ts, Tzr);
yeccpars2_647(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_648(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 556, Ss, Stack, T, Ts, Tzr);
yeccpars2_648(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_613(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_649(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 651, Ss, Stack, T, Ts, Tzr);
yeccpars2_649(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_649_(Stack),
 yeccpars2_650(650, Cat, [649 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_650(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 654, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_651: see yeccpars2_648

yeccpars2_652(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 651, Ss, Stack, T, Ts, Tzr);
yeccpars2_652(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_652_(Stack),
 yeccpars2_653(_S, Cat, [652 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_653_(Stack),
 yeccgoto_streamParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_654_(Stack),
 yeccgoto_streamDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_655(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 658, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 659, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 660, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_656_(Stack),
 yeccgoto_localParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_657(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 673, Ss, Stack, T, Ts, Tzr);
yeccpars2_657(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_657_(Stack),
 yeccpars2_672(672, Cat, [657 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_658(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 665, Ss, Stack, T, Ts, Tzr);
yeccpars2_658(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_659(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 663, Ss, Stack, T, Ts, Tzr);
yeccpars2_659(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_660(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 661, Ss, Stack, T, Ts, Tzr);
yeccpars2_660(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_661: see yeccpars2_483

yeccpars2_662(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_662_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_663: see yeccpars2_483

yeccpars2_664(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_664_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_665(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 667, Ss, Stack, T, Ts, Tzr);
yeccpars2_665(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 668, Ss, Stack, T, Ts, Tzr);
yeccpars2_665(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 669, Ss, Stack, T, Ts, Tzr);
yeccpars2_665(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 670, Ss, Stack, T, Ts, Tzr);
yeccpars2_665(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 671, Ss, Stack, T, Ts, Tzr);
yeccpars2_665(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_666(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_666_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_667(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_667_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_668(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_668_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_669(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_669_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_670(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_670_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_671(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_671_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_672(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 676, Ss, Stack, T, Ts, Tzr);
yeccpars2_672(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_673: see yeccpars2_655

yeccpars2_674(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 673, Ss, Stack, T, Ts, Tzr);
yeccpars2_674(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_674_(Stack),
 yeccpars2_675(_S, Cat, [674 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_675(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_675_(Stack),
 yeccgoto_localParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_676(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_676_(Stack),
 yeccgoto_localControlDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_677(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 681, Ss, Stack, T, Ts, Tzr);
yeccpars2_677(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_678: see yeccpars2_613

yeccpars2_679(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 678, Ss, Stack, T, Ts, Tzr);
yeccpars2_679(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_679_(Stack),
 yeccpars2_680(_S, Cat, [679 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_680(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_680_(Stack),
 yeccgoto_mediaParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_681(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_681_(Stack),
 yeccgoto_mediaDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_682: see yeccpars2_4

yeccpars2_683(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 684, Ss, Stack, T, Ts, Tzr);
yeccpars2_683(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_684: see yeccpars2_4

yeccpars2_685(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 738, Ss, Stack, T, Ts, Tzr);
yeccpars2_685(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_685_(Stack),
 yeccpars2_737(737, Cat, [685 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_686(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 688, Ss, Stack, T, Ts, Tzr);
yeccpars2_686(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_686_(Stack),
 yeccpars2_687(_S, Cat, [686 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_687(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_687_(Stack),
 yeccgoto_requestedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_688(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 694, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 695, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 696, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_688(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_689(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_690(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 733, Ss, Stack, T, Ts, Tzr);
yeccpars2_690(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_690_(Stack),
 yeccpars2_732(732, Cat, [690 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_691(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_692(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_693(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_694(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_694_(Stack),
 yeccgoto_eventDM(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_695(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 697, Ss, Stack, T, Ts, Tzr);
yeccpars2_695(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_696(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_696_COMMA(Stack),
 yeccgoto_eventParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_696(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_696_RBRKT(Stack),
 yeccgoto_eventParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_696(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_697(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 700, Ss, Stack, T, Ts, Tzr);
yeccpars2_697(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 555, Ss, Stack, T, Ts, Tzr);
yeccpars2_697(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_698(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 728, Ss, Stack, T, Ts, Tzr);
yeccpars2_698(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 729, Ss, Stack, T, Ts, Tzr);
yeccpars2_698(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_699(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 727, Ss, Stack, T, Ts, Tzr);
yeccpars2_699(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_700(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 701, Ss, Stack, T, Ts, Tzr);
yeccpars2_700(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_700_(Stack),
 yeccgoto_embedFirst(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_701: see yeccpars2_4

yeccpars2_702(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 703, Ss, Stack, T, Ts, Tzr);
yeccpars2_702(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_703: see yeccpars2_4

yeccpars2_704(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 723, Ss, Stack, T, Ts, Tzr);
yeccpars2_704(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_704_(Stack),
 yeccpars2_722(722, Cat, [704 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_705(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 707, Ss, Stack, T, Ts, Tzr);
yeccpars2_705(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_705_(Stack),
 yeccpars2_706(_S, Cat, [705 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_706(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_706_(Stack),
 yeccgoto_secondRequestedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_707(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 694, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 712, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 713, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_707(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_708(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 718, Ss, Stack, T, Ts, Tzr);
yeccpars2_708(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_708_(Stack),
 yeccpars2_717(717, Cat, [708 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_709(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_710(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_711(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_712(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 714, Ss, Stack, T, Ts, Tzr);
yeccpars2_712(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_713(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_713_COMMA(Stack),
 yeccgoto_secondEventParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_713(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_713_RBRKT(Stack),
 yeccgoto_secondEventParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_713(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_714(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 555, Ss, Stack, T, Ts, Tzr);
yeccpars2_714(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_715(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 716, Ss, Stack, T, Ts, Tzr);
yeccpars2_715(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_716(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_716_(Stack),
 yeccgoto_embedSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_717(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 721, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_718: see yeccpars2_707

yeccpars2_719(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 718, Ss, Stack, T, Ts, Tzr);
yeccpars2_719(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_719_(Stack),
 yeccpars2_720(_S, Cat, [719 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_720(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_720_(Stack),
 yeccgoto_secondEventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_721(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_721_(Stack),
 yeccgoto_secondRequestedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_722(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 726, Ss, Stack, T, Ts, Tzr);
yeccpars2_722(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_723: see yeccpars2_4

yeccpars2_724(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 723, Ss, Stack, T, Ts, Tzr);
yeccpars2_724(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_724_(Stack),
 yeccpars2_725(_S, Cat, [724 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_725(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_725_(Stack),
 yeccgoto_secondRequestedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_726(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_726_(Stack),
 yeccgoto_embedFirst(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_727(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_727_(Stack),
 yeccgoto_embedNoSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_728(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 700, Ss, Stack, T, Ts, Tzr);
yeccpars2_728(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_729(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_729_(Stack),
 yeccgoto_embedWithSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_730(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 731, Ss, Stack, T, Ts, Tzr);
yeccpars2_730(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_731(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_731_(Stack),
 yeccgoto_embedWithSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_732(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 736, Ss, Stack, T, Ts, Tzr);
yeccpars2_732(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_733: see yeccpars2_688

yeccpars2_734(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 733, Ss, Stack, T, Ts, Tzr);
yeccpars2_734(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_734_(Stack),
 yeccpars2_735(_S, Cat, [734 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_735(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_735_(Stack),
 yeccgoto_eventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_736(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_736_(Stack),
 yeccgoto_requestedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_737(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 741, Ss, Stack, T, Ts, Tzr);
yeccpars2_737(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_738: see yeccpars2_4

yeccpars2_739(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 738, Ss, Stack, T, Ts, Tzr);
yeccpars2_739(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_739_(Stack),
 yeccpars2_740(_S, Cat, [739 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_740(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_740_(Stack),
 yeccgoto_requestedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_741(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_741_(Stack),
 yeccgoto_eventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_742(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_742(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_742(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_742_(Stack),
 yeccpars2_4(458, Cat, [742 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_743(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_743_(Stack),
 yeccgoto_eventSpec(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_744(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 746, Ss, Stack, T, Ts, Tzr);
yeccpars2_744(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_744_(Stack),
 yeccpars2_745(745, Cat, [744 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_745(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 749, Ss, Stack, T, Ts, Tzr);
yeccpars2_745(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_746(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_746_(Stack),
 yeccpars2_4(458, Cat, [746 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_747(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 746, Ss, Stack, T, Ts, Tzr);
yeccpars2_747(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_747_(Stack),
 yeccpars2_748(_S, Cat, [747 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_748_(Stack),
 yeccgoto_eventSpecList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_749(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_749_(Stack),
 yeccgoto_eventBufferDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_750(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 754, Ss, Stack, T, Ts, Tzr);
yeccpars2_750(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_751: see yeccpars2_538

yeccpars2_752(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 751, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_752_(Stack),
 yeccpars2_753(_S, Cat, [752 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_753(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_753_(Stack),
 yeccgoto_ammParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_754(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_754_(Stack),
 yeccgoto_ammRequestBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_755(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 759, Ss, Stack, T, Ts, Tzr);
yeccpars2_755(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_756: see yeccpars2_146

yeccpars2_757(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 756, Ss, Stack, T, Ts, Tzr);
yeccpars2_757(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_757_(Stack),
 yeccpars2_758(_S, Cat, [757 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_758(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_758_(Stack),
 yeccgoto_actionRequestList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_759(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_759_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_760(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 766, Ss, Stack, T, Ts, Tzr);
yeccpars2_760(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_761(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_761_(Stack),
 yeccgoto_transactionID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_762: see yeccpars2_146

yeccpars2_763(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 756, Ss, Stack, T, Ts, Tzr);
yeccpars2_763(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_763_(Stack),
 yeccpars2_764(764, Cat, [763 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_764(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 765, Ss, Stack, T, Ts, Tzr);
yeccpars2_764(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_765(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_765_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_766: see yeccpars2_146

yeccpars2_767(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 756, Ss, Stack, T, Ts, Tzr);
yeccpars2_767(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_767_(Stack),
 yeccpars2_768(768, Cat, [767 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_768(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 769, Ss, Stack, T, Ts, Tzr);
yeccpars2_768(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_769(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_769_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_770: see yeccpars2_4

yeccpars2_771(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 774, Ss, Stack, T, Ts, Tzr);
yeccpars2_771(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_771_(Stack),
 yeccpars2_773(773, Cat, [771 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_772(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_772_(Stack),
 yeccgoto_transactionAck(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_773(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 777, Ss, Stack, T, Ts, Tzr);
yeccpars2_773(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_774: see yeccpars2_4

yeccpars2_775(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 774, Ss, Stack, T, Ts, Tzr);
yeccpars2_775(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_775_(Stack),
 yeccpars2_776(_S, Cat, [775 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_776(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_776_(Stack),
 yeccgoto_transactionAckList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_777(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_777_(Stack),
 yeccgoto_transactionResponseAck(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_778: see yeccpars2_4

yeccpars2_779(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 780, Ss, Stack, T, Ts, Tzr);
yeccpars2_779(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_780(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 782, Ss, Stack, T, Ts, Tzr);
yeccpars2_780(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_780_(Stack),
 yeccpars2_781(781, Cat, [780 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_781(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 787, Ss, Stack, T, Ts, Tzr);
yeccpars2_781(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 140, Ss, Stack, T, Ts, Tzr);
yeccpars2_781(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_782(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 783, Ss, Stack, T, Ts, Tzr);
yeccpars2_782(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_783(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_783_(Stack),
 yeccgoto_optImmAckRequired(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_784(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 909, Ss, Stack, T, Ts, Tzr);
yeccpars2_784(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_785(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_785_(Stack),
 yeccgoto_transactionReplyBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_786(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 906, Ss, Stack, T, Ts, Tzr);
yeccpars2_786(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_786_(Stack),
 yeccpars2_905(_S, Cat, [786 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_787(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 788, Ss, Stack, T, Ts, Tzr);
yeccpars2_787(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_788: see yeccpars2_4

yeccpars2_789(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 790, Ss, Stack, T, Ts, Tzr);
yeccpars2_789(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_790(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 800, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 801, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 802, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 171, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 174, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 140, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 175, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 803, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 804, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 805, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 179, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 806, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 807, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 182, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_791(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_791_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_792(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_792_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_793(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_793_(Stack),
 yeccgoto_actionReplyBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_794(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_794_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_795(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 901, Ss, Stack, T, Ts, Tzr);
yeccpars2_795(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_795_(Stack),
 yeccpars2_900(_S, Cat, [795 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_796(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_796_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_797(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 894, Ss, Stack, T, Ts, Tzr);
yeccpars2_797(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_798(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_798_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_799(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 893, Ss, Stack, T, Ts, Tzr);
yeccpars2_799(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_800(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_800_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_801(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 889, Ss, Stack, T, Ts, Tzr);
yeccpars2_801(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_802(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 839, Ss, Stack, T, Ts, Tzr);
yeccpars2_802(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_803(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_803_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_804(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_804_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_805(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 833, Ss, Stack, T, Ts, Tzr);
yeccpars2_805(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_806(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 808, Ss, Stack, T, Ts, Tzr);
yeccpars2_806(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_807(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_807_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_808: see yeccpars2_4

yeccpars2_809(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 811, Ss, Stack, T, Ts, Tzr);
yeccpars2_809(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_809_(Stack),
 yeccpars2_810(_S, Cat, [809 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_810(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_810_(Stack),
 yeccgoto_serviceChangeReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_811(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 140, Ss, Stack, T, Ts, Tzr);
yeccpars2_811(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 814, Ss, Stack, T, Ts, Tzr);
yeccpars2_811(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_812(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 832, Ss, Stack, T, Ts, Tzr);
yeccpars2_812(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_813(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 831, Ss, Stack, T, Ts, Tzr);
yeccpars2_813(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_814(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 815, Ss, Stack, T, Ts, Tzr);
yeccpars2_814(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_815(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 822, Ss, Stack, T, Ts, Tzr);
yeccpars2_815(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 823, Ss, Stack, T, Ts, Tzr);
yeccpars2_815(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 824, Ss, Stack, T, Ts, Tzr);
yeccpars2_815(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_815(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 825, Ss, Stack, T, Ts, Tzr);
yeccpars2_815(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_816(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_816_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_817(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_817_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_818(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_818_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_819(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_819_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_820(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_820_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_821(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 827, Ss, Stack, T, Ts, Tzr);
yeccpars2_821(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_821_(Stack),
 yeccpars2_826(826, Cat, [821 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_822(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 432, Ss, Stack, T, Ts, Tzr);
yeccpars2_822(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_823(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 430, Ss, Stack, T, Ts, Tzr);
yeccpars2_823(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_824(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 425, Ss, Stack, T, Ts, Tzr);
yeccpars2_824(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_825(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 423, Ss, Stack, T, Ts, Tzr);
yeccpars2_825(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_826(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 830, Ss, Stack, T, Ts, Tzr);
yeccpars2_826(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_827: see yeccpars2_815

yeccpars2_828(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 827, Ss, Stack, T, Ts, Tzr);
yeccpars2_828(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_828_(Stack),
 yeccpars2_829(_S, Cat, [828 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_829(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_829_(Stack),
 yeccgoto_servChgReplyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_830(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_830_(Stack),
 yeccgoto_serviceChangeReplyDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_831(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_831_(Stack),
 yeccgoto_serviceChangeReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_832(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_832_(Stack),
 yeccgoto_serviceChangeReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_833: see yeccpars2_4

yeccpars2_834(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 836, Ss, Stack, T, Ts, Tzr);
yeccpars2_834(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_834_(Stack),
 yeccpars2_835(_S, Cat, [834 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_835(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_835_(Stack),
 yeccgoto_notifyReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_836(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 140, Ss, Stack, T, Ts, Tzr);
yeccpars2_836(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_837(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 838, Ss, Stack, T, Ts, Tzr);
yeccpars2_837(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_838(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_838_(Stack),
 yeccgoto_notifyReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_839(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 842, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_839(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_840(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 856, Ss, Stack, T, Ts, Tzr);
yeccpars2_840(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_840_(Stack),
 yeccgoto_auditOther(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_841(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_841_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_842(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 845, Ss, Stack, T, Ts, Tzr);
yeccpars2_842(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_843(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_843_(Stack),
 yeccgoto_contextTerminationAudit(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_844(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_844_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_845(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 847, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_846(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 855, Ss, Stack, T, Ts, Tzr);
yeccpars2_846(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_847(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 848, Ss, Stack, T, Ts, Tzr);
yeccpars2_847(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_848: see yeccpars2_4

yeccpars2_849(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_849_(Stack),
 yeccgoto_errorCode(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_850(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 851, Ss, Stack, T, Ts, Tzr);
yeccpars2_850(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_851(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 853, Ss, Stack, T, Ts, Tzr);
yeccpars2_851(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_851_(Stack),
 yeccpars2_852(852, Cat, [851 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_852(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 854, Ss, Stack, T, Ts, Tzr);
yeccpars2_852(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_853(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_853_(Stack),
 yeccgoto_errorText(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_854(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_854_(Stack),
 yeccgoto_errorDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_855(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_855_(Stack),
 yeccgoto_contextTerminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_856(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 549, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 140, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 550, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 551, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 871, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 872, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 873, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 874, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 875, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 555, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 876, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_857(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 888, Ss, Stack, T, Ts, Tzr);
yeccpars2_857(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_858(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_858_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_859_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_860(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_860_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_861(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_861_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_862_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_863(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_863_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_864(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_864_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_865(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_865_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_866(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_866_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_867(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_867_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_868(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_868_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_869(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 885, Ss, Stack, T, Ts, Tzr);
yeccpars2_869(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_869_(Stack),
 yeccpars2_884(_S, Cat, [869 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_870(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_870_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_871(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 613, Ss, Stack, T, Ts, Tzr);
yeccpars2_871(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_871_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_872(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 597, Ss, Stack, T, Ts, Tzr);
yeccpars2_872(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 598, Ss, Stack, T, Ts, Tzr);
yeccpars2_872(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_872_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_873(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 586, Ss, Stack, T, Ts, Tzr);
yeccpars2_873(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_873_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_874(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 454, Ss, Stack, T, Ts, Tzr);
yeccpars2_874(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_874_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_875(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 877, Ss, Stack, T, Ts, Tzr);
yeccpars2_875(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_875_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_876(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 557, Ss, Stack, T, Ts, Tzr);
yeccpars2_876(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_876_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_877: see yeccpars2_4

yeccpars2_878(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 880, Ss, Stack, T, Ts, Tzr);
yeccpars2_878(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_878_(Stack),
 yeccpars2_879(879, Cat, [878 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_879(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 883, Ss, Stack, T, Ts, Tzr);
yeccpars2_879(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_880: see yeccpars2_4

yeccpars2_881(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 880, Ss, Stack, T, Ts, Tzr);
yeccpars2_881(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_881_(Stack),
 yeccpars2_882(_S, Cat, [881 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_882(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_882_(Stack),
 yeccgoto_packagesItems(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_883(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_883_(Stack),
 yeccgoto_packagesDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_884(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_884_(Stack),
 yeccgoto_terminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_885: see yeccpars2_856

yeccpars2_886(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 885, Ss, Stack, T, Ts, Tzr);
yeccpars2_886(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_886_(Stack),
 yeccpars2_887(_S, Cat, [886 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_887(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_887_(Stack),
 yeccgoto_auditReturnParameterList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_888(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_888_(Stack),
 yeccgoto_auditOther(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_889(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 891, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 85, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 87, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_890(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_890_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_891(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 845, Ss, Stack, T, Ts, Tzr);
yeccpars2_891(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_892(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_892_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_893(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_893_(Stack),
 yeccgoto_actionReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_894: see yeccpars2_4

yeccpars2_895(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 897, Ss, Stack, T, Ts, Tzr);
yeccpars2_895(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_895_(Stack),
 yeccpars2_896(_S, Cat, [895 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_896(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_896_(Stack),
 yeccgoto_ammsReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_897: see yeccpars2_856

yeccpars2_898(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 899, Ss, Stack, T, Ts, Tzr);
yeccpars2_898(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_899(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_899_(Stack),
 yeccgoto_ammsReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_900(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_900_(Stack),
 yeccgoto_actionReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_901: see yeccpars2_790

yeccpars2_902(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_902_(Stack),
 yeccgoto_commandReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_903(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 901, Ss, Stack, T, Ts, Tzr);
yeccpars2_903(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_903_(Stack),
 yeccpars2_904(_S, Cat, [903 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_904(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_904_(Stack),
 yeccgoto_commandReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_905(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_905_(Stack),
 yeccgoto_transactionReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_906(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 787, Ss, Stack, T, Ts, Tzr);
yeccpars2_906(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_907(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 906, Ss, Stack, T, Ts, Tzr);
yeccpars2_907(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_907_(Stack),
 yeccpars2_908(_S, Cat, [907 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_908(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_908_(Stack),
 yeccgoto_actionReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_909(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_909_(Stack),
 yeccgoto_transactionReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_910: see yeccpars2_4

yeccpars2_911(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 912, Ss, Stack, T, Ts, Tzr);
yeccpars2_911(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_912(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 913, Ss, Stack, T, Ts, Tzr);
yeccpars2_912(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_913(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_913_(Stack),
 yeccgoto_transactionPending(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_914(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_914_(Stack),
 yeccgoto_transactionList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_915(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_915_(Stack),
 yeccgoto_pathName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_916(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_916_(Stack),
 yeccgoto_deviceName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_917(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_917(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_917_(Stack),
 yeccpars2_921(_S, Cat, [917 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_918(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_918(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_918_(Stack),
 yeccpars2_920(_S, Cat, [918 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_919(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_919_(Stack),
 yeccgoto_mtpAddress(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_920(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_920_(Stack),
 yeccgoto_mId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_921(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_921_(Stack),
 yeccgoto_mId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccgoto_actionReply(781, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_786(786, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionReply(906, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_907(907, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionReplyBody(790, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_799(799, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionReplyList(786=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_905(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionReplyList(907=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_908(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequest(146, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_147(147, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(756, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_757(757, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(762, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_763(763, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(766, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_767(767, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestBody(152, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_167(167, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestItem(152, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(166, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestItem(532, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_533(533, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestItems(166=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_531(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestItems(533=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_534(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestList(147, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_755(755, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(757=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_758(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(763, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_764(764, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(767, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_768(768, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_alternativeValue(293=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammParameter(538, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_548(548, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammParameter(751, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_752(752, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammParameters(548, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_750(750, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammParameters(752=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_753(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammRequest(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammRequest(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammRequestBody(536=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_537(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammToken(152, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_164(164, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammToken(532, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_164(164, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsReply(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_798(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammsReply(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_798(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsReplyBody(895=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_896(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsToken(790, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_797(797, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammsToken(901, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_797(797, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditDescriptor(204, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_205(205, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditDescriptor(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_547(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditDescriptor(751=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_547(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditDescriptorBody(207, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_219(219, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditItem(207, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_218(218, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(382, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_383(383, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_413(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_413(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditItemList(218=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_381(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItemList(383=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_384(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditOther(839=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_841(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditOther(889=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_890(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReply(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_796(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReply(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_796(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditRequest(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditRequest(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnItem(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_217(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_217(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_217(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_217(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_870(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_870(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_870(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnParameter(856, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_869(869, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameter(885, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_886(886, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameter(897, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_869(869, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnParameterList(869=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_884(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameterList(886=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_887(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_authenticationHeader(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandReplyList(795=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_900(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandReplyList(903=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_904(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandReplys(790, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_795(795, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandReplys(901, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_903(903, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandRequest(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_162(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandRequest(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_162(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAttrDescriptor(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAudit(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAudit(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAuditProperties(492, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_497(497, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperties(499=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_500(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAuditProperty(490, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_492(492, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperty(498, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_499(499, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextID(149, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_151(151, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextID(510, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_511(511, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextID(513, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_514(514, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextID(788, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_789(789, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextIDs(511, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_512(512, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextIDs(514=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_515(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextIdList(503, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_507(507, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextProperty(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_794(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_794(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextTerminationAudit(842=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_844(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextTerminationAudit(891=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_892(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_daddr(116, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_daddr(117=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_daddr(119=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_deviceName(111, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_918(918, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_digitMapDescriptor(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_546(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(751=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_546(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_868(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_868(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_868(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_direction(287=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_domainAddress(108=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainAddress(425=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainAddress(432=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_domainName(108=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainName(425=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainName(432=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedFirst(697, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_699(699, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedFirst(728, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_730(730, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedNoSig(688=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_693(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedNoSig(733=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_693(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedSig(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_711(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedSig(718=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_711(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedWithSig(688=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_692(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedWithSig(733=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_692(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorCode(848, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_850(850, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorDescriptor(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(449=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_452(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(781=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_785(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_793(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(811, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_813(813, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(836, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_837(837, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(845, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_846(846, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_867(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_867(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_867(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_902(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorText(851, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_852(852, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferControl(625=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_629(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferControl(642=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_629(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferControlState(637=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_638(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferDescriptor(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_545(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(751=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_545(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_866(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_866(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_866(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventDM(688=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_691(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_710(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(718=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_710(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(733=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_691(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameter(688, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_690(690, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameter(733, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_734(734, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameterName(371=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_375(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(467, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(470, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(473, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(470, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(688, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(470, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(707, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(470, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(718, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(470, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(733, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(470, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameters(690, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_732(732, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameters(734=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_735(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventSpec(742, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_744(744, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventSpec(746, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_747(747, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventSpecList(744, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_745(745, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventSpecList(747=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventStream(371=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventStreamOrOther(467=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_469(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(473=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_469(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(688=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_689(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_709(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(718=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_709(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(733=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_689(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventsDescriptor(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_544(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(751=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_544(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_865(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_865(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_865(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_extension(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_412(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_extension(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_412(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_extensionParameter(400, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(411, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_extensionParameter(440, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(411, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_iepsValue(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_iepsValue(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_iepsValue(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_iepsValue(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudauditReturnParameter(207, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_216(216, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(382, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_216(216, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(386, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_387(387, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(400, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_216(216, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(440, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_216(216, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudcontextAttrDescriptor(487, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_488(488, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAuddigitMapDescriptor(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(386=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventBufferDescriptor(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(386=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventSpec(366, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_368(368, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventSpecParameter(371, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_373(373, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventsDescriptor(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(386=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalControlDescriptor(327=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_333(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalControlDescriptor(344=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_333(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalControlDescriptor(356=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_333(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalParm(347, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_349(349, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalParm(351, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_352(352, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalParmList(349, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_350(350, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalParmList(352=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_353(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaDescriptor(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(386=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaParm(327, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_332(332, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaParm(356, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_357(357, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaParms(332, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_355(355, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaParms(357=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_358(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudpackagesDescriptor(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(386=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudrequestedEvent(362, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_364(364, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalList(236=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_241(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalParm(236, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_240(240, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalsDescriptor(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(386=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstatisticsDescriptor(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(327=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_331(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(344=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_331(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(356=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_331(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(386=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstreamDescriptor(327=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_330(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstreamDescriptor(356=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_330(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstreamParm(327=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstreamParm(344, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_345(345, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstreamParm(356=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationAudit(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationAuditList(216=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_385(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAuditList(387=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_393(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationStateDescriptor(327=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_328(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationStateDescriptor(356=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_328(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationStateParm(338, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_340(340, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localControlDescriptor(613=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_619(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(648=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_619(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(651=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_619(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(678=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_619(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localParm(655, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_657(657, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localParm(673, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_674(674, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localParmList(657, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_672(672, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localParmList(674=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_675(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mId(108, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_112(112, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mId(425=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_427(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mId(432=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaDescriptor(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_543(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(751=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_543(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_864(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_864(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_864(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaParm(613, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_618(618, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaParm(678, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_679(679, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaParmList(618, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_677(677, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaParmList(679=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_680(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_megacoMessage(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_message(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_109(109, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_messageBody(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemDescriptor(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_542(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(751=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_542(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_863(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_863(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_863(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemType(597, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_611(611, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemType(598, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_600(600, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemType(602, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_603(603, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemTypeList(600, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_601(601, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemTypeList(603=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mtpAddress(111, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_917(917, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_muxDescriptor(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_541(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(751=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_541(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_muxType(586, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_588(588, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notificationReason(274, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_275(275, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notificationReason(281, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_282(282, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notificationReasons(275, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_280(280, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notificationReasons(282=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_283(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyReply(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_792(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyReply(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_792(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyReplyBody(834=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_835(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyRequest(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyRequest(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyRequestBody(449, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_451(451, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEvent(456, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_459(459, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(461, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_462(462, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(742=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_743(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(746=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_743(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventBody(465=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_466(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventBody(480=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_481(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventParameter(467, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_468(468, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventParameter(473, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_474(474, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventParameters(468, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_472(472, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventParameters(474=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_475(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEvents(459, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_460(460, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvents(462=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_463(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventsDescriptor(449=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_450(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_861(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_861(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_861(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_onOrOff(483=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_484(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_onOrOff(661=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_662(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_onOrOff(663=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_664(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optAuditDescriptor(202=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optAuditDescriptor(525=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_526(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optAuditDescriptor(528=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_529(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optImmAckRequired(780, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_781(781, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optIndAudeventSpecParameter(367=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_370(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optIndAudsignalParm(229=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_235(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optIndAudsignalParm(392=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_235(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optPropertyParms(605=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_606(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optPropertyParms(611=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_612(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optSep(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(106=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(108, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_111(111, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(124=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(130=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(425, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_111(111, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(432, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_111(111, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(456, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(458, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(457, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_477(477, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(461, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(458, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(478, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(479, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(742, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(458, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(746, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(458, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(917=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_921(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(918=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_920(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_860(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_860(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_860(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesItem(323, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_325(325, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItem(877, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_878(878, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItem(880, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_881(881, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesItems(878, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_879(879, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItems(881=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_882(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_parmValue(254=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(411=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_438(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(470=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_471(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(506=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_518(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_pathName(111=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_916(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_pkgdName(231, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_233(233, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(236=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(247=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(362=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_363(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(366, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_367(367, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(458, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_465(465, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(479, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_480(480, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(490=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_491(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(498=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_491(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(503, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(506, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(520, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(506, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(557, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_559(559, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(563, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_559(559, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(567=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(577=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(582=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(607, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(506, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(625, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(506, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(642, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(506, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(655, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(506, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(673, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(506, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(684, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_686(686, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(703, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_705(705, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(723, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_705(705, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(738, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_686(686, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_portNumber(122, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(124, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_portNumber(129, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_portNumber(425=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_426(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_priority(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParm(503, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_505(505, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(520, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_521(521, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(607, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_608(608, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(625=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_628(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(642=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_628(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(655=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(673=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParmList(505=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_519(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParmList(521=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_522(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParmList(608, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_609(609, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParms(503, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_504(504, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestID(270=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_272(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(360, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_361(361, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(454, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_455(455, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(682, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_683(683, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(701, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_702(702, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEvent(684, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_685(685, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestedEvent(738, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_739(739, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEventBody(686=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_687(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEvents(685, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_737(737, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestedEvents(739=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_740(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_safeToken(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_108(108, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(6, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(103, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(104, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(105, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_106(106, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(111=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_915(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(115, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(127, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(116, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(117, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(119, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(117, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(122=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(129=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(145=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_761(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(149=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(188=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(197=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(201=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(231=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(236=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(244=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_246(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(247=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(252, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(254, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(262=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(270=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_271(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(285=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_286(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(293=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(294=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(295=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(296=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(304=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(305=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(309=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(319, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(254, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(323=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(338=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_339(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(342=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(347=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_348(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(351=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_348(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(360=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_271(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(362=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(366=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(371=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(377=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(395=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_410(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(423=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_424(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(425=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(428=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(430=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_431(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(434=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_435(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(436=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_437(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_410(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(445=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_446(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(447=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(454=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_271(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(458=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(467=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(473=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(479=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(490=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(498=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(503=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(510=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(513=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(524=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(527=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(535=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(557=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(560=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(563=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(567=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(572=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_246(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(577=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(582=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(586=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_587(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(590=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(593=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(597=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_599(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(598=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_599(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(602=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_599(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(607=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(625=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(642=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(646=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(655=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(673=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(682=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_271(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(684=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(688=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(701=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_271(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(703=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(718=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(723=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(733=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(770=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_772(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(774=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_772(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(778=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_761(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(788=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(808=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(839=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(845=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(848=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_849(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(877=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(880=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(889=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(894=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(910=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_761(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_safeToken2(4=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(6=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(105=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(111=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(115=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(116=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(117=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(119=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(122=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(129=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(145=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(149=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(188=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(197=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(201=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(231=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(236=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(244=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(247=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(252=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(262=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(270=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(285=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(293=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(294=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(295=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(296=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(304=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(305=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(309=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(319=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(323=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(338=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(342=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(347=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(351=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(360=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(362=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(366=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(371=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(377=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(395=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(423=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(425=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(428=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(430=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(434=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(436=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(445=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(447=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(454=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(458=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(467=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(473=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(479=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(490=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(498=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(503=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(510=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(513=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(520=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(524=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(527=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(535=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(557=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(560=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(563=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(567=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(572=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(577=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(582=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(586=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(590=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(593=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(597=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(598=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(602=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(607=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(625=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(642=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(646=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(655=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(673=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(682=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(684=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(688=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(701=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(703=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(718=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(723=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(733=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(738=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(770=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(774=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(778=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(788=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(808=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(839=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(845=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(848=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(877=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(880=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(889=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(894=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(910=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondEventParameter(707, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_708(708, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondEventParameter(718, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_719(719, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondEventParameters(708, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_717(717, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondEventParameters(719=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_720(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEvent(703, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_704(704, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondRequestedEvent(723, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_724(724, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEventBody(705=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_706(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEvents(704, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_722(722, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondRequestedEvents(724=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_725(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_servChgReplyParm(815, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_821(821, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_servChgReplyParm(827, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_828(828, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_servChgReplyParms(821, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_826(826, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_servChgReplyParms(828=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_829(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeAddress(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_409(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_409(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(815=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_820(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(827=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_820(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeDelay(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_408(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeDelay(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_408(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeDescriptor(397, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_398(398, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeMethod(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_407(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMethod(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_407(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeMgcId(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_406(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_406(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(815=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_819(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(827=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_819(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeParm(400, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_405(405, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeParm(440, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_441(441, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeParms(405, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_439(439, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeParms(441=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_442(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeProfile(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_404(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_404(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(815=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_818(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(827=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_818(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReason(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeReason(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReply(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_791(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeReply(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_791(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReplyBody(809=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_810(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReplyDescriptor(811, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_812(812, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeRequest(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeRequest(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeVersion(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(815=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_817(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(827=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_817(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceState(632=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_633(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceStates(625=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_627(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceStates(642=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_627(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_sigParameter(252, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_253(253, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sigParameter(319, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_320(320, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_sigParameters(253, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_318(318, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sigParameters(320=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_321(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalList(567=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_570(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalList(582=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_570(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListId(244, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(245, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListId(572, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_573(573, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListParm(247, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_249(249, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParm(574, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_575(575, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParm(577, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_578(578, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListParms(575, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_576(576, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParms(578=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalName(236, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_238(238, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(247, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_238(238, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(567, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_238(238, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(574, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_238(238, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(577, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_238(238, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(582, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_238(238, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalParm(567, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_569(569, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalParm(582, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_583(583, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalParms(569, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_581(581, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalParms(583=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_584(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalRequest(236=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_237(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(247=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(567=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_568(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(577=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(582=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_568(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalType(265=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_266(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalsDescriptor(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_540(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(697, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_698(698, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(714, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_715(715, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(751=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_540(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsDescriptor(538=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_539(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(613=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_617(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(648=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_617(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(651=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_617(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(678=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_617(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(751=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_539(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(856=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_858(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_858(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(897=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_858(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsParameter(557, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_558(558, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsParameter(563, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_564(564, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsParameters(558, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_562(562, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsParameters(564=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_565(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamDescriptor(613=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_616(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamDescriptor(678=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_616(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamID(262=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_263(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(342, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_343(343, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(377=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_378(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(646, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_647(647, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamModes(665=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_666(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamParm(613=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_615(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(648, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_649(649, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(651, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_652(652, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(678=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_615(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamParmList(649, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_650(650, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParmList(652=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_subtractRequest(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_subtractRequest(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationA(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(186, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationA(197, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(186, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationAudit(856, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_857(857, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationAudit(897, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_898(898, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationB(188, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(190, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationID(183=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(188=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(197=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(201, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(202, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(395, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(396, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(447, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_448(448, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(524, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_525(525, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(527, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_528(528, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(535, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_536(536, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(590, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_591(591, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(593, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_594(594, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(808, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_809(809, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(833, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_834(834, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(839, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_840(840, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(845, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_591(591, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(889, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_840(840, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(894, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_895(895, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationIDList(588=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_589(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDList(842=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_843(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDList(891=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_843(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationIDListRepeat(591, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_592(592, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDListRepeat(594=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_595(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateDescriptor(613=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_614(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateDescriptor(678=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_614(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateParm(625, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_626(626, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateParm(642, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_643(643, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateParms(626, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_641(641, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateParms(643=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_644(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_timeStamp(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(440=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(456, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_457(457, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(461, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_457(457, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(742, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_457(457, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(746, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_457(457, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(815=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_816(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(827=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_816(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDescriptor(152=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(901=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDirection(191=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyTriple(183, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(184, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyTriple(197, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_198(198, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyTripleList(184, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_196(196, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyTripleList(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionAck(770, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_771(771, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionAck(774, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_775(775, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionAckList(771, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_773(773, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionAckList(775=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_776(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionID(145, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_760(760, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionID(778, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_779(779, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionID(910, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_911(911, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionItem(112, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(137, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionItem(137, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(137, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionList(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionList(137=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_914(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionPending(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionPending(137=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionReply(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionReply(137=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionReplyBody(781, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_784(784, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionRequest(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_133(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionRequest(137=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_133(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionResponseAck(112=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionResponseAck(137=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_value(293=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_302(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(294=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(295=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_300(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(296=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(304, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_315(315, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(305, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_306(306, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(308, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_312(312, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(309, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_310(310, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(428=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_429(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(560=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_561(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_valueList(306, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_307(307, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_valueList(310=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_311(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_valueList(315, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_316(316, Cat, Ss, Stack, T, Ts, Tzr).

-compile({inline,yeccpars2_0_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_0_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_1_/1}).
-file("megaco_text_parser_prev3b.yrl", 481).
yeccpars2_1_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_3_/1}).
-file("megaco_text_parser_prev3b.yrl", 475).
yeccpars2_3_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sep
  end | __Stack].

-compile({inline,yeccpars2_7_/1}).
-file("megaco_text_parser_prev3b.yrl", 1456).
yeccpars2_7_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   make_safe_token ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_106_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_106_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_107_/1}).
-file("megaco_text_parser_prev3b.yrl", 480).
yeccpars2_107_(__Stack0) ->
 [__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_auth_header ( __3 , __5 , __7 )
  end | __Stack].

-compile({inline,yeccpars2_108_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_108_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_110_/1}).
-file("megaco_text_parser_prev3b.yrl", 473).
yeccpars2_110_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'MegacoMessage' { authHeader = __2 , mess = __3 }
  end | __Stack].

-compile({inline,yeccpars2_116_/1}).
-file("megaco_text_parser_prev3b.yrl", 961).
yeccpars2_116_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_117_/1}).
-file("megaco_text_parser_prev3b.yrl", 961).
yeccpars2_117_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_119_/1}).
-file("megaco_text_parser_prev3b.yrl", 961).
yeccpars2_119_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_120_/1}).
-file("megaco_text_parser_prev3b.yrl", 962).
yeccpars2_120_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ colon | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_121_/1}).
-file("megaco_text_parser_prev3b.yrl", 959).
yeccpars2_121_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainAddress ( __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_123_/1}).
-file("megaco_text_parser_prev3b.yrl", 966).
yeccpars2_123_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_124_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_124_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_125_/1}).
-file("megaco_text_parser_prev3b.yrl", 957).
yeccpars2_125_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainAddress ( __2 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_126_/1}).
-file("megaco_text_parser_prev3b.yrl", 963).
yeccpars2_126_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_128_/1}).
-file("megaco_text_parser_prev3b.yrl", 949).
yeccpars2_128_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainName ( __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_130_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_130_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_131_/1}).
-file("megaco_text_parser_prev3b.yrl", 947).
yeccpars2_131_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainName ( __2 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_132_/1}).
-file("megaco_text_parser_prev3b.yrl", 494).
yeccpars2_132_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionResponseAck , __1 }
  end | __Stack].

-compile({inline,yeccpars2_133_/1}).
-file("megaco_text_parser_prev3b.yrl", 491).
yeccpars2_133_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionRequest , __1 }
  end | __Stack].

-compile({inline,yeccpars2_134_/1}).
-file("megaco_text_parser_prev3b.yrl", 492).
yeccpars2_134_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionReply , __1 }
  end | __Stack].

-compile({inline,yeccpars2_135_/1}).
-file("megaco_text_parser_prev3b.yrl", 493).
yeccpars2_135_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionPending , __1 }
  end | __Stack].

-compile({inline,yeccpars2_136_/1}).
-file("megaco_text_parser_prev3b.yrl", 486).
yeccpars2_136_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactions , __1 }
  end | __Stack].

-compile({inline,yeccpars2_137_/1}).
-file("megaco_text_parser_prev3b.yrl", 488).
yeccpars2_137_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_138_/1}).
-file("megaco_text_parser_prev3b.yrl", 483).
yeccpars2_138_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_message ( __1 , __2 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_139_/1}).
-file("megaco_text_parser_prev3b.yrl", 485).
yeccpars2_139_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { messageError , __1 }
  end | __Stack].

-compile({inline,yeccpars2_147_/1}).
-file("megaco_text_parser_prev3b.yrl", 521).
yeccpars2_147_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_150_/1}).
-file("megaco_text_parser_prev3b.yrl", 954).
yeccpars2_150_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_contextID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_153_/1}).
-file("megaco_text_parser_prev3b.yrl", 545).
yeccpars2_153_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { topology , __1 }
  end | __Stack].

-compile({inline,yeccpars2_156_/1}).
-file("megaco_text_parser_prev3b.yrl", 546).
yeccpars2_156_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { priority , __1 }
  end | __Stack].

-compile({inline,yeccpars2_158_/1}).
-file("megaco_text_parser_prev3b.yrl", 549).
yeccpars2_158_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { iepsCallind , __1 }
  end | __Stack].

-compile({inline,yeccpars2_159_/1}).
-file("megaco_text_parser_prev3b.yrl", 534).
yeccpars2_159_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextProp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_160_/1}).
-file("megaco_text_parser_prev3b.yrl", 535).
yeccpars2_160_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextAudit , __1 }
  end | __Stack].

-compile({inline,yeccpars2_162_/1}).
-file("megaco_text_parser_prev3b.yrl", 536).
yeccpars2_162_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { commandRequest , __1 }
  end | __Stack].

-compile({inline,yeccpars2_166_/1}).
-file("megaco_text_parser_prev3b.yrl", 531).
yeccpars2_166_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_168_/1}).
-file("megaco_text_parser_prev3b.yrl", 638).
yeccpars2_168_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { addReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_173_/1}).
-file("megaco_text_parser_prev3b.yrl", 548).
yeccpars2_173_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { emergency , false }
  end | __Stack].

-compile({inline,yeccpars2_174_/1}).
-file("megaco_text_parser_prev3b.yrl", 547).
yeccpars2_174_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { emergency , true }
  end | __Stack].

-compile({inline,yeccpars2_176_/1}).
-file("megaco_text_parser_prev3b.yrl", 640).
yeccpars2_176_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { modReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_177_/1}).
-file("megaco_text_parser_prev3b.yrl", 639).
yeccpars2_177_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { moveReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_184_/1}).
-file("megaco_text_parser_prev3b.yrl", 1439).
yeccpars2_184_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_187_/1}).
-file("megaco_text_parser_prev3b.yrl", 982).
yeccpars2_187_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_terminationID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_192_/1}).
-file("megaco_text_parser_prev3b.yrl", 1435).
yeccpars2_192_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TopologyRequest' { terminationFrom = __1 ,
    terminationTo = __3 ,
    topologyDirection = __5 }
  end | __Stack].

-compile({inline,yeccpars2_193_/1}).
-file("megaco_text_parser_prev3b.yrl", 1443).
yeccpars2_193_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   bothway
  end | __Stack].

-compile({inline,yeccpars2_194_/1}).
-file("megaco_text_parser_prev3b.yrl", 1444).
yeccpars2_194_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   isolate
  end | __Stack].

-compile({inline,yeccpars2_195_/1}).
-file("megaco_text_parser_prev3b.yrl", 1445).
yeccpars2_195_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   oneway
  end | __Stack].

-compile({inline,yeccpars2_198_/1}).
-file("megaco_text_parser_prev3b.yrl", 1439).
yeccpars2_198_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_199_/1}).
-file("megaco_text_parser_prev3b.yrl", 1441).
yeccpars2_199_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_200_/1}).
-file("megaco_text_parser_prev3b.yrl", 1426).
yeccpars2_200_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_202_/1}).
-file("megaco_text_parser_prev3b.yrl", 679).
yeccpars2_202_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_203_/1}).
-file("megaco_text_parser_prev3b.yrl", 673).
yeccpars2_203_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { subtractReq , __1 } ,
    # 'SubtractRequest' { terminationID = [ __3 ] ,
    auditDescriptor = __4 } )
  end | __Stack].

-compile({inline,yeccpars2_207_/1}).
-file("megaco_text_parser_prev3b.yrl", 739).
yeccpars2_207_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_208_/1}).
-file("megaco_text_parser_prev3b.yrl", 760).
yeccpars2_208_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { terminationAudit , __1 }
  end | __Stack].

-compile({inline,yeccpars2_209_/1}).
-file("megaco_text_parser_prev3b.yrl", 787).
yeccpars2_209_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudStatisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_210_/1}).
-file("megaco_text_parser_prev3b.yrl", 781).
yeccpars2_210_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudSignalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_211_/1}).
-file("megaco_text_parser_prev3b.yrl", 789).
yeccpars2_211_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudPackagesDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_212_/1}).
-file("megaco_text_parser_prev3b.yrl", 777).
yeccpars2_212_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudMediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_213_/1}).
-file("megaco_text_parser_prev3b.yrl", 779).
yeccpars2_213_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudEventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_214_/1}).
-file("megaco_text_parser_prev3b.yrl", 785).
yeccpars2_214_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudEventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_215_/1}).
-file("megaco_text_parser_prev3b.yrl", 783).
yeccpars2_215_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudDigitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_216_/1}).
-file("megaco_text_parser_prev3b.yrl", 774).
yeccpars2_216_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_218_/1}).
-file("megaco_text_parser_prev3b.yrl", 742).
yeccpars2_218_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_220_/1}).
-file("megaco_text_parser_prev3b.yrl", 881).
yeccpars2_220_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_IADMD ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_221_/1}).
-file("megaco_text_parser_prev3b.yrl", 749).
yeccpars2_221_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   digitMapToken
  end | __Stack].

-compile({inline,yeccpars2_222_/1}).
-file("megaco_text_parser_prev3b.yrl", 758).
yeccpars2_222_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   eventBufferToken
  end | __Stack].

-compile({inline,yeccpars2_223_/1}).
-file("megaco_text_parser_prev3b.yrl", 759).
yeccpars2_223_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   eventsToken
  end | __Stack].

-compile({inline,yeccpars2_224_/1}).
-file("megaco_text_parser_prev3b.yrl", 748).
yeccpars2_224_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   mediaToken
  end | __Stack].

-compile({inline,yeccpars2_225_/1}).
-file("megaco_text_parser_prev3b.yrl", 747).
yeccpars2_225_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modemToken
  end | __Stack].

-compile({inline,yeccpars2_226_/1}).
-file("megaco_text_parser_prev3b.yrl", 746).
yeccpars2_226_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   muxToken
  end | __Stack].

-compile({inline,yeccpars2_227_/1}).
-file("megaco_text_parser_prev3b.yrl", 751).
yeccpars2_227_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   observedEventsToken
  end | __Stack].

-compile({inline,yeccpars2_228_/1}).
-file("megaco_text_parser_prev3b.yrl", 752).
yeccpars2_228_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   packagesToken
  end | __Stack].

-compile({inline,yeccpars2_229_/1}).
-file("megaco_text_parser_prev3b.yrl", 757).
yeccpars2_229_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   signalsToken
  end | __Stack].

-compile({inline,yeccpars2_230_/1}).
-file("megaco_text_parser_prev3b.yrl", 750).
yeccpars2_230_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statsToken
  end | __Stack].

-compile({inline,yeccpars2_232_/1}).
-file("megaco_text_parser_prev3b.yrl", 1122).
yeccpars2_232_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_pkgdName ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_234_/1}).
-file("megaco_text_parser_prev3b.yrl", 884).
yeccpars2_234_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStatisticsDescriptor' { statName = __3 }
  end | __Stack].

-compile({inline,yeccpars2_235_/1}).
-file("megaco_text_parser_prev3b.yrl", 863).
yeccpars2_235_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_237_/1}).
-file("megaco_text_parser_prev3b.yrl", 870).
yeccpars2_237_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signal , ensure_indAudSignal ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_238_/1}).
-file("megaco_text_parser_prev3b.yrl", 1215).
yeccpars2_238_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_signalRequest ( __1 , [ ] )
  end | __Stack].

-compile({inline,yeccpars2_241_/1}).
-file("megaco_text_parser_prev3b.yrl", 869).
yeccpars2_241_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { seqSigList , __1 }
  end | __Stack].

-compile({inline,yeccpars2_242_/1}).
-file("megaco_text_parser_prev3b.yrl", 866).
yeccpars2_242_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   asn1_NOVALUE
  end | __Stack].

-compile({inline,yeccpars2_246_/1}).
-file("megaco_text_parser_prev3b.yrl", 1279).
yeccpars2_246_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_250_/1}).
-file("megaco_text_parser_prev3b.yrl", 874).
yeccpars2_250_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudSeqSigList' { id = ensure_uint16 ( __3 ) ,
    signalList =
    ensure_indAudSignalListParm ( __5 ) }
  end | __Stack].

-compile({inline,yeccpars2_251_/1}).
-file("megaco_text_parser_prev3b.yrl", 867).
yeccpars2_251_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_253_/1}).
-file("megaco_text_parser_prev3b.yrl", 1218).
yeccpars2_253_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_257_COMMA/1}).
-file("megaco_text_parser_prev3b.yrl", 1248).
yeccpars2_257_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_257_RBRKT/1}).
-file("megaco_text_parser_prev3b.yrl", 1248).
yeccpars2_257_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_263_/1}).
-file("megaco_text_parser_prev3b.yrl", 1240).
yeccpars2_263_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { stream , __3 }
  end | __Stack].

-compile({inline,yeccpars2_264_/1}).
-file("megaco_text_parser_prev3b.yrl", 1120).
yeccpars2_264_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_streamID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_266_/1}).
-file("megaco_text_parser_prev3b.yrl", 1242).
yeccpars2_266_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { signal_type , __3 }
  end | __Stack].

-compile({inline,yeccpars2_267_/1}).
-file("megaco_text_parser_prev3b.yrl", 1256).
yeccpars2_267_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   brief
  end | __Stack].

-compile({inline,yeccpars2_268_/1}).
-file("megaco_text_parser_prev3b.yrl", 1254).
yeccpars2_268_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onOff
  end | __Stack].

-compile({inline,yeccpars2_269_/1}).
-file("megaco_text_parser_prev3b.yrl", 1255).
yeccpars2_269_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   timeOut
  end | __Stack].

-compile({inline,yeccpars2_271_/1}).
-file("megaco_text_parser_prev3b.yrl", 1313).
yeccpars2_271_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_requestID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_272_/1}).
-file("megaco_text_parser_prev3b.yrl", 1250).
yeccpars2_272_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { requestId , __3 }
  end | __Stack].

-compile({inline,yeccpars2_275_/1}).
-file("megaco_text_parser_prev3b.yrl", 1263).
yeccpars2_275_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_276_/1}).
-file("megaco_text_parser_prev3b.yrl", 1266).
yeccpars2_276_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onInterruptByEvent
  end | __Stack].

-compile({inline,yeccpars2_277_/1}).
-file("megaco_text_parser_prev3b.yrl", 1267).
yeccpars2_277_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onInterruptByNewSignalDescr
  end | __Stack].

-compile({inline,yeccpars2_278_/1}).
-file("megaco_text_parser_prev3b.yrl", 1268).
yeccpars2_278_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   otherReason
  end | __Stack].

-compile({inline,yeccpars2_279_/1}).
-file("megaco_text_parser_prev3b.yrl", 1265).
yeccpars2_279_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onTimeOut
  end | __Stack].

-compile({inline,yeccpars2_282_/1}).
-file("megaco_text_parser_prev3b.yrl", 1263).
yeccpars2_282_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_283_/1}).
-file("megaco_text_parser_prev3b.yrl", 1262).
yeccpars2_283_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_284_/1}).
-file("megaco_text_parser_prev3b.yrl", 1247).
yeccpars2_284_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { notify_completion , [ __4 | __5 ] }
  end | __Stack].

-compile({inline,yeccpars2_286_/1}).
-file("megaco_text_parser_prev3b.yrl", 1244).
yeccpars2_286_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { duration , ensure_uint16 ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_288_/1}).
-file("megaco_text_parser_prev3b.yrl", 1249).
yeccpars2_288_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { direction , __3 }
  end | __Stack].

-compile({inline,yeccpars2_289_/1}).
-file("megaco_text_parser_prev3b.yrl", 1260).
yeccpars2_289_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   both
  end | __Stack].

-compile({inline,yeccpars2_290_/1}).
-file("megaco_text_parser_prev3b.yrl", 1258).
yeccpars2_290_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   external
  end | __Stack].

-compile({inline,yeccpars2_291_/1}).
-file("megaco_text_parser_prev3b.yrl", 1259).
yeccpars2_291_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   internal
  end | __Stack].

-compile({inline,yeccpars2_292_/1}).
-file("megaco_text_parser_prev3b.yrl", 1252).
yeccpars2_292_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { other , ensure_NAME ( __1 ) , __2 }
  end | __Stack].

-compile({inline,yeccpars2_297_/1}).
-file("megaco_text_parser_prev3b.yrl", 1056).
yeccpars2_297_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , unequalTo } }
  end | __Stack].

-compile({inline,yeccpars2_298_/1}).
-file("megaco_text_parser_prev3b.yrl", 1454).
yeccpars2_298_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_value ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_299_/1}).
-file("megaco_text_parser_prev3b.yrl", 1453).
yeccpars2_299_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_value ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_300_/1}).
-file("megaco_text_parser_prev3b.yrl", 1059).
yeccpars2_300_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , smallerThan } }
  end | __Stack].

-compile({inline,yeccpars2_301_/1}).
-file("megaco_text_parser_prev3b.yrl", 1062).
yeccpars2_301_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , greaterThan } }
  end | __Stack].

-compile({inline,yeccpars2_302_/1}).
-file("megaco_text_parser_prev3b.yrl", 1083).
yeccpars2_302_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __1 ] }
  end | __Stack].

-compile({inline,yeccpars2_303_/1}).
-file("megaco_text_parser_prev3b.yrl", 1053).
yeccpars2_303_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_306_/1}).
-file("megaco_text_parser_prev3b.yrl", 1086).
yeccpars2_306_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_310_/1}).
-file("megaco_text_parser_prev3b.yrl", 1086).
yeccpars2_310_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_311_/1}).
-file("megaco_text_parser_prev3b.yrl", 1085).
yeccpars2_311_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_313_/1}).
-file("megaco_text_parser_prev3b.yrl", 1075).
yeccpars2_313_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 , __4 ] ,
    extraInfo = { range , true } }
  end | __Stack].

-compile({inline,yeccpars2_314_/1}).
-file("megaco_text_parser_prev3b.yrl", 1079).
yeccpars2_314_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 | __3 ] ,
    extraInfo = { sublist , true } }
  end | __Stack].

-compile({inline,yeccpars2_315_/1}).
-file("megaco_text_parser_prev3b.yrl", 1086).
yeccpars2_315_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_317_/1}).
-file("megaco_text_parser_prev3b.yrl", 1071).
yeccpars2_317_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 | __3 ] ,
    extraInfo = { sublist , false } }
  end | __Stack].

-compile({inline,yeccpars2_320_/1}).
-file("megaco_text_parser_prev3b.yrl", 1218).
yeccpars2_320_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_321_/1}).
-file("megaco_text_parser_prev3b.yrl", 1217).
yeccpars2_321_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_322_/1}).
-file("megaco_text_parser_prev3b.yrl", 1214).
yeccpars2_322_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_signalRequest ( __1 , [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_324_/1}).
-file("megaco_text_parser_prev3b.yrl", 1405).
yeccpars2_324_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_packagesItem ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_326_/1}).
-file("megaco_text_parser_prev3b.yrl", 887).
yeccpars2_326_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudPackagesDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_328_/1}).
-file("megaco_text_parser_prev3b.yrl", 802).
yeccpars2_328_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { termStateDescr , __1 }
  end | __Stack].

-compile({inline,yeccpars2_329_/1}).
-file("megaco_text_parser_prev3b.yrl", 800).
yeccpars2_329_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_330_/1}).
-file("megaco_text_parser_prev3b.yrl", 801).
yeccpars2_330_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamDescr , __1 }
  end | __Stack].

-compile({inline,yeccpars2_331_/1}).
-file("megaco_text_parser_prev3b.yrl", 811).
yeccpars2_331_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamParms' { statisticsDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_332_/1}).
-file("megaco_text_parser_prev3b.yrl", 805).
yeccpars2_332_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_333_/1}).
-file("megaco_text_parser_prev3b.yrl", 809).
yeccpars2_333_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamParms' { localControlDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_339_/1}).
-file("megaco_text_parser_prev3b.yrl", 839).
yeccpars2_339_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_indAudTerminationStateParm ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_341_/1}).
-file("megaco_text_parser_prev3b.yrl", 833).
yeccpars2_341_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudTerminationStateDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_346_/1}).
-file("megaco_text_parser_prev3b.yrl", 815).
yeccpars2_346_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamDescriptor' { streamID = __3 ,
    streamParms = __5 }
  end | __Stack].

-compile({inline,yeccpars2_348_/1}).
-file("megaco_text_parser_prev3b.yrl", 828).
yeccpars2_348_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_indAudLocalParm ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_349_/1}).
-file("megaco_text_parser_prev3b.yrl", 824).
yeccpars2_349_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_352_/1}).
-file("megaco_text_parser_prev3b.yrl", 824).
yeccpars2_352_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_353_/1}).
-file("megaco_text_parser_prev3b.yrl", 823).
yeccpars2_353_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_354_/1}).
-file("megaco_text_parser_prev3b.yrl", 821).
yeccpars2_354_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudLocalControlDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_357_/1}).
-file("megaco_text_parser_prev3b.yrl", 805).
yeccpars2_357_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_358_/1}).
-file("megaco_text_parser_prev3b.yrl", 804).
yeccpars2_358_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_359_/1}).
-file("megaco_text_parser_prev3b.yrl", 794).
yeccpars2_359_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudMediaDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_365_/1}).
-file("megaco_text_parser_prev3b.yrl", 857).
yeccpars2_365_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudEventsDescriptor' { requestID = __3 ,
    pkgdName = __5 }
  end | __Stack].

-compile({inline,yeccpars2_367_/1}).
-file("megaco_text_parser_prev3b.yrl", 849).
yeccpars2_367_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_369_/1}).
-file("megaco_text_parser_prev3b.yrl", 842).
yeccpars2_369_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_370_/1}).
-file("megaco_text_parser_prev3b.yrl", 845).
yeccpars2_370_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudEventBufferDescriptor ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_372_/1}).
-file("megaco_text_parser_prev3b.yrl", 1196).
yeccpars2_372_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_NAME ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_374_/1}).
-file("megaco_text_parser_prev3b.yrl", 852).
yeccpars2_374_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamID , __1 }
  end | __Stack].

-compile({inline,yeccpars2_375_/1}).
-file("megaco_text_parser_prev3b.yrl", 853).
yeccpars2_375_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventParameterName , __1 }
  end | __Stack].

-compile({inline,yeccpars2_378_/1}).
-file("megaco_text_parser_prev3b.yrl", 889).
yeccpars2_378_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_379_/1}).
-file("megaco_text_parser_prev3b.yrl", 848).
yeccpars2_379_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_380_/1}).
-file("megaco_text_parser_prev3b.yrl", 736).
yeccpars2_380_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_auditDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_381_/1}).
-file("megaco_text_parser_prev3b.yrl", 738).
yeccpars2_381_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_383_/1}).
-file("megaco_text_parser_prev3b.yrl", 742).
yeccpars2_383_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_384_/1}).
-file("megaco_text_parser_prev3b.yrl", 741).
yeccpars2_384_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_385_/1}).
-file("megaco_text_parser_prev3b.yrl", 769).
yeccpars2_385_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_387_/1}).
-file("megaco_text_parser_prev3b.yrl", 774).
yeccpars2_387_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_393_/1}).
-file("megaco_text_parser_prev3b.yrl", 773).
yeccpars2_393_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_394_/1}).
-file("megaco_text_parser_prev3b.yrl", 678).
yeccpars2_394_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_401_/1}).
-file("megaco_text_parser_prev3b.yrl", 1355).
yeccpars2_401_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { time_stamp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_402_/1}).
-file("megaco_text_parser_prev3b.yrl", 1357).
yeccpars2_402_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { version , __1 }
  end | __Stack].

-compile({inline,yeccpars2_403_/1}).
-file("megaco_text_parser_prev3b.yrl", 1350).
yeccpars2_403_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { reason , __1 }
  end | __Stack].

-compile({inline,yeccpars2_404_/1}).
-file("megaco_text_parser_prev3b.yrl", 1353).
yeccpars2_404_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { profile , __1 }
  end | __Stack].

-compile({inline,yeccpars2_405_/1}).
-file("megaco_text_parser_prev3b.yrl", 1347).
yeccpars2_405_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_406_/1}).
-file("megaco_text_parser_prev3b.yrl", 1356).
yeccpars2_406_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mgc_id , __1 }
  end | __Stack].

-compile({inline,yeccpars2_407_/1}).
-file("megaco_text_parser_prev3b.yrl", 1349).
yeccpars2_407_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { method , __1 }
  end | __Stack].

-compile({inline,yeccpars2_408_/1}).
-file("megaco_text_parser_prev3b.yrl", 1351).
yeccpars2_408_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { delay , __1 }
  end | __Stack].

-compile({inline,yeccpars2_409_/1}).
-file("megaco_text_parser_prev3b.yrl", 1352).
yeccpars2_409_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { address , __1 }
  end | __Stack].

-compile({inline,yeccpars2_410_/1}).
-file("megaco_text_parser_prev3b.yrl", 1451).
yeccpars2_410_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_extensionParameter ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_412_/1}).
-file("megaco_text_parser_prev3b.yrl", 1354).
yeccpars2_412_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { extension , __1 }
  end | __Stack].

-compile({inline,yeccpars2_413_/1}).
-file("megaco_text_parser_prev3b.yrl", 1359).
yeccpars2_413_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { audit_item , __1 }
  end | __Stack].

-compile({inline,yeccpars2_420_/1}).
-file("megaco_text_parser_prev3b.yrl", 1358).
yeccpars2_420_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   incomplete
  end | __Stack].

-compile({inline,yeccpars2_421_/1}).
-file("megaco_text_parser_prev3b.yrl", 1407).
yeccpars2_421_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_timeStamp ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_424_/1}).
-file("megaco_text_parser_prev3b.yrl", 1376).
yeccpars2_424_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_version ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_425_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_425_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_426_/1}).
-file("megaco_text_parser_prev3b.yrl", 1370).
yeccpars2_426_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { portNumber , __3 }
  end | __Stack].

-compile({inline,yeccpars2_427_/1}).
-file("megaco_text_parser_prev3b.yrl", 1368).
yeccpars2_427_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_429_/1}).
-file("megaco_text_parser_prev3b.yrl", 1364).
yeccpars2_429_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 ]
  end | __Stack].

-compile({inline,yeccpars2_431_/1}).
-file("megaco_text_parser_prev3b.yrl", 1374).
yeccpars2_431_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_profile ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_432_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_432_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_433_/1}).
-file("megaco_text_parser_prev3b.yrl", 1372).
yeccpars2_433_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_435_/1}).
-file("megaco_text_parser_prev3b.yrl", 1362).
yeccpars2_435_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_serviceChangeMethod ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_437_/1}).
-file("megaco_text_parser_prev3b.yrl", 1366).
yeccpars2_437_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_uint32 ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_438_/1}).
-file("megaco_text_parser_prev3b.yrl", 1379).
yeccpars2_438_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'PropertyParm' .name , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_441_/1}).
-file("megaco_text_parser_prev3b.yrl", 1347).
yeccpars2_441_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_442_/1}).
-file("megaco_text_parser_prev3b.yrl", 1346).
yeccpars2_442_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_443_/1}).
-file("megaco_text_parser_prev3b.yrl", 1343).
yeccpars2_443_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_ServiceChangeParm ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_444_/1}).
-file("megaco_text_parser_prev3b.yrl", 915).
yeccpars2_444_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { serviceChangeReq , __1 } ,
    # 'ServiceChangeRequest' { terminationID = [ __3 ] ,
    serviceChangeParms = __5 } )
  end | __Stack].

-compile({inline,yeccpars2_446_/1}).
-file("megaco_text_parser_prev3b.yrl", 1449).
yeccpars2_446_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_450_/1}).
-file("megaco_text_parser_prev3b.yrl", 901).
yeccpars2_450_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'NotifyRequest' { observedEventsDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_452_/1}).
-file("megaco_text_parser_prev3b.yrl", 903).
yeccpars2_452_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'NotifyRequest' { errorDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_456_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_456_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_457_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_457_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_459_/1}).
-file("megaco_text_parser_prev3b.yrl", 1293).
yeccpars2_459_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_461_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_461_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_462_/1}).
-file("megaco_text_parser_prev3b.yrl", 1293).
yeccpars2_462_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_463_/1}).
-file("megaco_text_parser_prev3b.yrl", 1292).
yeccpars2_463_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_464_/1}).
-file("megaco_text_parser_prev3b.yrl", 1289).
yeccpars2_464_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'ObservedEventsDescriptor' { requestId = __3 ,
    observedEventLst = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_465_/1}).
-file("megaco_text_parser_prev3b.yrl", 1305).
yeccpars2_465_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_466_/1}).
-file("megaco_text_parser_prev3b.yrl", 1300).
yeccpars2_466_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_observed_event ( __3 , __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_468_/1}).
-file("megaco_text_parser_prev3b.yrl", 1308).
yeccpars2_468_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_471_/1}).
-file("megaco_text_parser_prev3b.yrl", 1194).
yeccpars2_471_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   select_stream_or_other ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_474_/1}).
-file("megaco_text_parser_prev3b.yrl", 1308).
yeccpars2_474_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_475_/1}).
-file("megaco_text_parser_prev3b.yrl", 1307).
yeccpars2_475_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_476_/1}).
-file("megaco_text_parser_prev3b.yrl", 1304).
yeccpars2_476_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_478_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_478_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_480_/1}).
-file("megaco_text_parser_prev3b.yrl", 1305).
yeccpars2_480_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_481_/1}).
-file("megaco_text_parser_prev3b.yrl", 1298).
yeccpars2_481_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_observed_event ( __6 , __5 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_482_/1}).
-file("megaco_text_parser_prev3b.yrl", 897).
yeccpars2_482_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { notifyReq , __1 } ,
    setelement ( # 'NotifyRequest' .terminationID , __5 , [ __3 ] ) )
  end | __Stack].

-compile({inline,yeccpars2_484_/1}).
-file("megaco_text_parser_prev3b.yrl", 1447).
yeccpars2_484_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_485_/1}).
-file("megaco_text_parser_prev3b.yrl", 1040).
yeccpars2_485_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   false
  end | __Stack].

-compile({inline,yeccpars2_486_/1}).
-file("megaco_text_parser_prev3b.yrl", 1039).
yeccpars2_486_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   true
  end | __Stack].

-compile({inline,yeccpars2_491_/1}).
-file("megaco_text_parser_prev3b.yrl", 581).
yeccpars2_491_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_492_/1}).
-file("megaco_text_parser_prev3b.yrl", 574).
yeccpars2_492_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_493_/1}).
-file("megaco_text_parser_prev3b.yrl", 578).
yeccpars2_493_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   emergencyAudit
  end | __Stack].

-compile({inline,yeccpars2_494_/1}).
-file("megaco_text_parser_prev3b.yrl", 580).
yeccpars2_494_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   iepsCallind
  end | __Stack].

-compile({inline,yeccpars2_495_/1}).
-file("megaco_text_parser_prev3b.yrl", 579).
yeccpars2_495_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   priorityAudit
  end | __Stack].

-compile({inline,yeccpars2_496_/1}).
-file("megaco_text_parser_prev3b.yrl", 577).
yeccpars2_496_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   topologyAudit
  end | __Stack].

-compile({inline,yeccpars2_499_/1}).
-file("megaco_text_parser_prev3b.yrl", 574).
yeccpars2_499_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_500_/1}).
-file("megaco_text_parser_prev3b.yrl", 573).
yeccpars2_500_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_501_/1}).
-file("megaco_text_parser_prev3b.yrl", 570).
yeccpars2_501_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_502_/1}).
-file("megaco_text_parser_prev3b.yrl", 564).
yeccpars2_502_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_context_attr_audit_request (
    # 'ContextAttrAuditRequest' { } , __3 )
  end | __Stack].

-compile({inline,yeccpars2_505_/1}).
-file("megaco_text_parser_prev3b.yrl", 1329).
yeccpars2_505_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_511_/1}).
-file("megaco_text_parser_prev3b.yrl", 561).
yeccpars2_511_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_514_/1}).
-file("megaco_text_parser_prev3b.yrl", 561).
yeccpars2_514_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_515_/1}).
-file("megaco_text_parser_prev3b.yrl", 560).
yeccpars2_515_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_516_/1}).
-file("megaco_text_parser_prev3b.yrl", 558).
yeccpars2_516_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __4 | __5 ]
  end | __Stack].

-compile({inline,yeccpars2_517_/1}).
-file("megaco_text_parser_prev3b.yrl", 555).
yeccpars2_517_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { contextList , __3 }
  end | __Stack].

-compile({inline,yeccpars2_518_/1}).
-file("megaco_text_parser_prev3b.yrl", 1050).
yeccpars2_518_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'PropertyParm' .name , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_519_/1}).
-file("megaco_text_parser_prev3b.yrl", 1327).
yeccpars2_519_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_521_/1}).
-file("megaco_text_parser_prev3b.yrl", 1329).
yeccpars2_521_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_522_/1}).
-file("megaco_text_parser_prev3b.yrl", 1328).
yeccpars2_522_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_523_/1}).
-file("megaco_text_parser_prev3b.yrl", 553).
yeccpars2_523_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { contextProp , __3 }
  end | __Stack].

-compile({inline,yeccpars2_525_/1}).
-file("megaco_text_parser_prev3b.yrl", 679).
yeccpars2_525_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_526_/1}).
-file("megaco_text_parser_prev3b.yrl", 683).
yeccpars2_526_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { auditValueRequest , __1 } ,
    # 'AuditRequest' { terminationID = __3 ,
    auditDescriptor = __4 } )
  end | __Stack].

-compile({inline,yeccpars2_528_/1}).
-file("megaco_text_parser_prev3b.yrl", 679).
yeccpars2_528_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_529_/1}).
-file("megaco_text_parser_prev3b.yrl", 688).
yeccpars2_529_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { auditCapRequest , __1 } ,
    # 'AuditRequest' { terminationID = __3 ,
    auditDescriptor = __4 } )
  end | __Stack].

-compile({inline,yeccpars2_530_/1}).
-file("megaco_text_parser_prev3b.yrl", 525).
yeccpars2_530_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_action_request ( __3 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_531_/1}).
-file("megaco_text_parser_prev3b.yrl", 527).
yeccpars2_531_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_533_/1}).
-file("megaco_text_parser_prev3b.yrl", 531).
yeccpars2_533_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_534_/1}).
-file("megaco_text_parser_prev3b.yrl", 530).
yeccpars2_534_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_536_/1}).
-file("megaco_text_parser_prev3b.yrl", 643).
yeccpars2_536_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_537_/1}).
-file("megaco_text_parser_prev3b.yrl", 633).
yeccpars2_537_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Descs = merge_AmmRequest_descriptors ( __4 , [ ] ) ,
    make_commandRequest ( __1 ,
    # 'AmmRequest' { terminationID = [ __3 ] ,
    descriptors = Descs } )
  end | __Stack].

-compile({inline,yeccpars2_539_/1}).
-file("megaco_text_parser_prev3b.yrl", 657).
yeccpars2_539_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_540_/1}).
-file("megaco_text_parser_prev3b.yrl", 654).
yeccpars2_540_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_541_/1}).
-file("megaco_text_parser_prev3b.yrl", 651).
yeccpars2_541_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { muxDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_542_/1}).
-file("megaco_text_parser_prev3b.yrl", 650).
yeccpars2_542_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { modemDescriptor , deprecated }
  end | __Stack].

-compile({inline,yeccpars2_543_/1}).
-file("megaco_text_parser_prev3b.yrl", 649).
yeccpars2_543_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_544_/1}).
-file("megaco_text_parser_prev3b.yrl", 652).
yeccpars2_544_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_545_/1}).
-file("megaco_text_parser_prev3b.yrl", 653).
yeccpars2_545_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_546_/1}).
-file("megaco_text_parser_prev3b.yrl", 655).
yeccpars2_546_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { digitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_547_/1}).
-file("megaco_text_parser_prev3b.yrl", 656).
yeccpars2_547_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_548_/1}).
-file("megaco_text_parser_prev3b.yrl", 646).
yeccpars2_548_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_549_/1}).
-file("megaco_text_parser_prev3b.yrl", 1335).
yeccpars2_549_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_DMD ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_550_/1}).
-file("megaco_text_parser_prev3b.yrl", 1089).
yeccpars2_550_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_551_/1}).
-file("megaco_text_parser_prev3b.yrl", 1125).
yeccpars2_551_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'EventsDescriptor' { requestID = asn1_NOVALUE ,
    eventList = [ ] }
  end | __Stack].

-compile({inline,yeccpars2_555_/1}).
-file("megaco_text_parser_prev3b.yrl", 1205).
yeccpars2_555_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_558_/1}).
-file("megaco_text_parser_prev3b.yrl", 1415).
yeccpars2_558_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_559_/1}).
-file("megaco_text_parser_prev3b.yrl", 1419).
yeccpars2_559_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'StatisticsParameter' { statName = __1 ,
    statValue = asn1_NOVALUE }
  end | __Stack].

-compile({inline,yeccpars2_561_/1}).
-file("megaco_text_parser_prev3b.yrl", 1422).
yeccpars2_561_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'StatisticsParameter' { statName = __1 ,
    statValue = [ __3 ] }
  end | __Stack].

-compile({inline,yeccpars2_564_/1}).
-file("megaco_text_parser_prev3b.yrl", 1415).
yeccpars2_564_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_565_/1}).
-file("megaco_text_parser_prev3b.yrl", 1414).
yeccpars2_565_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_566_/1}).
-file("megaco_text_parser_prev3b.yrl", 1412).
yeccpars2_566_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_568_/1}).
-file("megaco_text_parser_prev3b.yrl", 1211).
yeccpars2_568_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signal , __1 }
  end | __Stack].

-compile({inline,yeccpars2_569_/1}).
-file("megaco_text_parser_prev3b.yrl", 1208).
yeccpars2_569_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_570_/1}).
-file("megaco_text_parser_prev3b.yrl", 1210).
yeccpars2_570_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { seqSigList , __1 }
  end | __Stack].

-compile({inline,yeccpars2_575_/1}).
-file("megaco_text_parser_prev3b.yrl", 1277).
yeccpars2_575_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_578_/1}).
-file("megaco_text_parser_prev3b.yrl", 1277).
yeccpars2_578_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_579_/1}).
-file("megaco_text_parser_prev3b.yrl", 1276).
yeccpars2_579_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_580_/1}).
-file("megaco_text_parser_prev3b.yrl", 1272).
yeccpars2_580_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'SeqSigList' { id = ensure_uint16 ( __3 ) ,
    signalList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_583_/1}).
-file("megaco_text_parser_prev3b.yrl", 1208).
yeccpars2_583_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_584_/1}).
-file("megaco_text_parser_prev3b.yrl", 1207).
yeccpars2_584_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_585_/1}).
-file("megaco_text_parser_prev3b.yrl", 1204).
yeccpars2_585_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_587_/1}).
-file("megaco_text_parser_prev3b.yrl", 1118).
yeccpars2_587_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_muxType ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_589_/1}).
-file("megaco_text_parser_prev3b.yrl", 1115).
yeccpars2_589_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'MuxDescriptor' { muxType = __3 ,
    termList = __4 }
  end | __Stack].

-compile({inline,yeccpars2_591_/1}).
-file("megaco_text_parser_prev3b.yrl", 977).
yeccpars2_591_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_594_/1}).
-file("megaco_text_parser_prev3b.yrl", 977).
yeccpars2_594_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_595_/1}).
-file("megaco_text_parser_prev3b.yrl", 976).
yeccpars2_595_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_596_/1}).
-file("megaco_text_parser_prev3b.yrl", 973).
yeccpars2_596_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_599_/1}).
-file("megaco_text_parser_prev3b.yrl", 0).
yeccpars2_599_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_600_/1}).
-file("megaco_text_parser_prev3b.yrl", 0).
yeccpars2_600_(__Stack0) ->
 [begin
   '$undefined'
  end | __Stack0].

-compile({inline,yeccpars2_603_/1}).
-file("megaco_text_parser_prev3b.yrl", 0).
yeccpars2_603_(__Stack0) ->
 [begin
   '$undefined'
  end | __Stack0].

-compile({inline,yeccpars2_604_/1}).
-file("megaco_text_parser_prev3b.yrl", 0).
yeccpars2_604_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_605_/1}).
-file("megaco_text_parser_prev3b.yrl", 1325).
yeccpars2_605_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_606_/1}).
-file("megaco_text_parser_prev3b.yrl", 0).
yeccpars2_606_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_608_/1}).
-file("megaco_text_parser_prev3b.yrl", 1329).
yeccpars2_608_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_610_/1}).
-file("megaco_text_parser_prev3b.yrl", 1324).
yeccpars2_610_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_611_/1}).
-file("megaco_text_parser_prev3b.yrl", 1325).
yeccpars2_611_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_612_/1}).
-file("megaco_text_parser_prev3b.yrl", 0).
yeccpars2_612_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_614_/1}).
-file("megaco_text_parser_prev3b.yrl", 998).
yeccpars2_614_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { termState , __1 }
  end | __Stack].

-compile({inline,yeccpars2_615_/1}).
-file("megaco_text_parser_prev3b.yrl", 994).
yeccpars2_615_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_616_/1}).
-file("megaco_text_parser_prev3b.yrl", 996).
yeccpars2_616_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_617_/1}).
-file("megaco_text_parser_prev3b.yrl", 1009).
yeccpars2_617_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statistics , __1 }
  end | __Stack].

-compile({inline,yeccpars2_618_/1}).
-file("megaco_text_parser_prev3b.yrl", 988).
yeccpars2_618_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_619_/1}).
-file("megaco_text_parser_prev3b.yrl", 1008).
yeccpars2_619_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { control , __1 }
  end | __Stack].

-compile({inline,yeccpars2_621_/1}).
-file("megaco_text_parser_prev3b.yrl", 1003).
yeccpars2_621_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   PGs = ensure_prop_groups ( __1 ) ,
    { local , # 'LocalRemoteDescriptor' { propGrps = PGs } }
  end | __Stack].

-compile({inline,yeccpars2_622_/1}).
-file("megaco_text_parser_prev3b.yrl", 1006).
yeccpars2_622_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   PGs = ensure_prop_groups ( __1 ) ,
    { remote , # 'LocalRemoteDescriptor' { propGrps = PGs } }
  end | __Stack].

-compile({inline,yeccpars2_626_/1}).
-file("megaco_text_parser_prev3b.yrl", 1031).
yeccpars2_626_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_627_/1}).
-file("megaco_text_parser_prev3b.yrl", 1099).
yeccpars2_627_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { serviceState , __1 }
  end | __Stack].

-compile({inline,yeccpars2_628_/1}).
-file("megaco_text_parser_prev3b.yrl", 1101).
yeccpars2_628_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { propertyParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_629_/1}).
-file("megaco_text_parser_prev3b.yrl", 1100).
yeccpars2_629_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferControl , __1 }
  end | __Stack].

-compile({inline,yeccpars2_633_/1}).
-file("megaco_text_parser_prev3b.yrl", 1103).
yeccpars2_633_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_634_/1}).
-file("megaco_text_parser_prev3b.yrl", 1107).
yeccpars2_634_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   inSvc
  end | __Stack].

-compile({inline,yeccpars2_635_/1}).
-file("megaco_text_parser_prev3b.yrl", 1106).
yeccpars2_635_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   outOfSvc
  end | __Stack].

-compile({inline,yeccpars2_636_/1}).
-file("megaco_text_parser_prev3b.yrl", 1105).
yeccpars2_636_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   test
  end | __Stack].

-compile({inline,yeccpars2_638_/1}).
-file("megaco_text_parser_prev3b.yrl", 1109).
yeccpars2_638_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_639_/1}).
-file("megaco_text_parser_prev3b.yrl", 1112).
yeccpars2_639_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lockStep
  end | __Stack].

-compile({inline,yeccpars2_640_/1}).
-file("megaco_text_parser_prev3b.yrl", 1111).
yeccpars2_640_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   off
  end | __Stack].

-compile({inline,yeccpars2_643_/1}).
-file("megaco_text_parser_prev3b.yrl", 1031).
yeccpars2_643_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_644_/1}).
-file("megaco_text_parser_prev3b.yrl", 1030).
yeccpars2_644_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_645_/1}).
-file("megaco_text_parser_prev3b.yrl", 1028).
yeccpars2_645_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_terminationStateDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_649_/1}).
-file("megaco_text_parser_prev3b.yrl", 1017).
yeccpars2_649_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_652_/1}).
-file("megaco_text_parser_prev3b.yrl", 1017).
yeccpars2_652_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_653_/1}).
-file("megaco_text_parser_prev3b.yrl", 1016).
yeccpars2_653_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_654_/1}).
-file("megaco_text_parser_prev3b.yrl", 1013).
yeccpars2_654_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'StreamDescriptor' { streamID = __3 ,
    streamParms = merge_streamParms ( [ __5 | __6 ] ) }
  end | __Stack].

-compile({inline,yeccpars2_656_/1}).
-file("megaco_text_parser_prev3b.yrl", 1037).
yeccpars2_656_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_657_/1}).
-file("megaco_text_parser_prev3b.yrl", 1023).
yeccpars2_657_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_662_/1}).
-file("megaco_text_parser_prev3b.yrl", 1035).
yeccpars2_662_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { value , __3 }
  end | __Stack].

-compile({inline,yeccpars2_664_/1}).
-file("megaco_text_parser_prev3b.yrl", 1034).
yeccpars2_664_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { group , __3 }
  end | __Stack].

-compile({inline,yeccpars2_666_/1}).
-file("megaco_text_parser_prev3b.yrl", 1036).
yeccpars2_666_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { mode , __3 }
  end | __Stack].

-compile({inline,yeccpars2_667_/1}).
-file("megaco_text_parser_prev3b.yrl", 1046).
yeccpars2_667_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   inactive
  end | __Stack].

-compile({inline,yeccpars2_668_/1}).
-file("megaco_text_parser_prev3b.yrl", 1047).
yeccpars2_668_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   loopBack
  end | __Stack].

-compile({inline,yeccpars2_669_/1}).
-file("megaco_text_parser_prev3b.yrl", 1044).
yeccpars2_669_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   recvOnly
  end | __Stack].

-compile({inline,yeccpars2_670_/1}).
-file("megaco_text_parser_prev3b.yrl", 1043).
yeccpars2_670_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sendOnly
  end | __Stack].

-compile({inline,yeccpars2_671_/1}).
-file("megaco_text_parser_prev3b.yrl", 1045).
yeccpars2_671_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sendRecv
  end | __Stack].

-compile({inline,yeccpars2_674_/1}).
-file("megaco_text_parser_prev3b.yrl", 1023).
yeccpars2_674_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_675_/1}).
-file("megaco_text_parser_prev3b.yrl", 1022).
yeccpars2_675_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_676_/1}).
-file("megaco_text_parser_prev3b.yrl", 1020).
yeccpars2_676_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_679_/1}).
-file("megaco_text_parser_prev3b.yrl", 988).
yeccpars2_679_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_680_/1}).
-file("megaco_text_parser_prev3b.yrl", 987).
yeccpars2_680_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_681_/1}).
-file("megaco_text_parser_prev3b.yrl", 985).
yeccpars2_681_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_mediaDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_685_/1}).
-file("megaco_text_parser_prev3b.yrl", 1133).
yeccpars2_685_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_686_/1}).
-file("megaco_text_parser_prev3b.yrl", 1140).
yeccpars2_686_(__Stack0) ->
 [begin
   # 'RequestedEvent' { evParList = [ ] }
  end | __Stack0].

-compile({inline,yeccpars2_687_/1}).
-file("megaco_text_parser_prev3b.yrl", 1136).
yeccpars2_687_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'RequestedEvent' .pkgdName , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_690_/1}).
-file("megaco_text_parser_prev3b.yrl", 1144).
yeccpars2_690_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_694_/1}).
-file("megaco_text_parser_prev3b.yrl", 1200).
yeccpars2_694_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_eventDM ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_696_COMMA/1}).
-file("megaco_text_parser_prev3b.yrl", 1147).
yeccpars2_696_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_696_RBRKT/1}).
-file("megaco_text_parser_prev3b.yrl", 1147).
yeccpars2_696_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_700_/1}).
-file("megaco_text_parser_prev3b.yrl", 1163).
yeccpars2_700_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'SecondEventsDescriptor' { requestID = asn1_NOVALUE ,
    eventList = [ ] }
  end | __Stack].

-compile({inline,yeccpars2_704_/1}).
-file("megaco_text_parser_prev3b.yrl", 1171).
yeccpars2_704_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_705_/1}).
-file("megaco_text_parser_prev3b.yrl", 1179).
yeccpars2_705_(__Stack0) ->
 [begin
   # 'SecondRequestedEvent' { evParList = [ ] }
  end | __Stack0].

-compile({inline,yeccpars2_706_/1}).
-file("megaco_text_parser_prev3b.yrl", 1175).
yeccpars2_706_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'SecondRequestedEvent' .pkgdName , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_708_/1}).
-file("megaco_text_parser_prev3b.yrl", 1182).
yeccpars2_708_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_713_COMMA/1}).
-file("megaco_text_parser_prev3b.yrl", 1185).
yeccpars2_713_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_713_RBRKT/1}).
-file("megaco_text_parser_prev3b.yrl", 1185).
yeccpars2_713_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_716_/1}).
-file("megaco_text_parser_prev3b.yrl", 1191).
yeccpars2_716_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { second_embed , __3 }
  end | __Stack].

-compile({inline,yeccpars2_719_/1}).
-file("megaco_text_parser_prev3b.yrl", 1182).
yeccpars2_719_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_720_/1}).
-file("megaco_text_parser_prev3b.yrl", 1181).
yeccpars2_720_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_721_/1}).
-file("megaco_text_parser_prev3b.yrl", 1178).
yeccpars2_721_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_secondEventParameters ( [ __2 | __3 ] )
  end | __Stack].

-compile({inline,yeccpars2_724_/1}).
-file("megaco_text_parser_prev3b.yrl", 1171).
yeccpars2_724_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_725_/1}).
-file("megaco_text_parser_prev3b.yrl", 1170).
yeccpars2_725_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_726_/1}).
-file("megaco_text_parser_prev3b.yrl", 1167).
yeccpars2_726_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'SecondEventsDescriptor' { requestID = __3 ,
    eventList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_727_/1}).
-file("megaco_text_parser_prev3b.yrl", 1160).
yeccpars2_727_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , asn1_NOVALUE , __3 }
  end | __Stack].

-compile({inline,yeccpars2_729_/1}).
-file("megaco_text_parser_prev3b.yrl", 1157).
yeccpars2_729_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , __3 , asn1_NOVALUE }
  end | __Stack].

-compile({inline,yeccpars2_731_/1}).
-file("megaco_text_parser_prev3b.yrl", 1155).
yeccpars2_731_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , __3 , __5 }
  end | __Stack].

-compile({inline,yeccpars2_734_/1}).
-file("megaco_text_parser_prev3b.yrl", 1144).
yeccpars2_734_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_735_/1}).
-file("megaco_text_parser_prev3b.yrl", 1143).
yeccpars2_735_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_736_/1}).
-file("megaco_text_parser_prev3b.yrl", 1139).
yeccpars2_736_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_eventParameters ( [ __2 | __3 ] )
  end | __Stack].

-compile({inline,yeccpars2_739_/1}).
-file("megaco_text_parser_prev3b.yrl", 1133).
yeccpars2_739_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_740_/1}).
-file("megaco_text_parser_prev3b.yrl", 1132).
yeccpars2_740_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_741_/1}).
-file("megaco_text_parser_prev3b.yrl", 1129).
yeccpars2_741_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'EventsDescriptor' { requestID = __3 ,
    eventList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_742_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_742_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_743_/1}).
-file("megaco_text_parser_prev3b.yrl", 1096).
yeccpars2_743_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_eventSpec ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_744_/1}).
-file("megaco_text_parser_prev3b.yrl", 1094).
yeccpars2_744_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_746_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_746_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_747_/1}).
-file("megaco_text_parser_prev3b.yrl", 1094).
yeccpars2_747_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_748_/1}).
-file("megaco_text_parser_prev3b.yrl", 1093).
yeccpars2_748_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_749_/1}).
-file("megaco_text_parser_prev3b.yrl", 1091).
yeccpars2_749_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_752_/1}).
-file("megaco_text_parser_prev3b.yrl", 646).
yeccpars2_752_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_753_/1}).
-file("megaco_text_parser_prev3b.yrl", 645).
yeccpars2_753_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_754_/1}).
-file("megaco_text_parser_prev3b.yrl", 642).
yeccpars2_754_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_757_/1}).
-file("megaco_text_parser_prev3b.yrl", 521).
yeccpars2_757_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_758_/1}).
-file("megaco_text_parser_prev3b.yrl", 520).
yeccpars2_758_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_759_/1}).
-file("megaco_text_parser_prev3b.yrl", 509).
yeccpars2_759_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = asn1_NOVALUE ,
    actions = [ __3 | __4 ] }
  end | __Stack].

-compile({inline,yeccpars2_761_/1}).
-file("megaco_text_parser_prev3b.yrl", 939).
yeccpars2_761_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint32 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_763_/1}).
-file("megaco_text_parser_prev3b.yrl", 521).
yeccpars2_763_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_765_/1}).
-file("megaco_text_parser_prev3b.yrl", 513).
yeccpars2_765_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = asn1_NOVALUE ,
    actions = [ __4 | __5 ] }
  end | __Stack].

-compile({inline,yeccpars2_767_/1}).
-file("megaco_text_parser_prev3b.yrl", 521).
yeccpars2_767_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_769_/1}).
-file("megaco_text_parser_prev3b.yrl", 517).
yeccpars2_769_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = ensure_transactionID ( __3 ) ,
    actions = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_771_/1}).
-file("megaco_text_parser_prev3b.yrl", 500).
yeccpars2_771_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_772_/1}).
-file("megaco_text_parser_prev3b.yrl", 502).
yeccpars2_772_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_transactionAck ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_775_/1}).
-file("megaco_text_parser_prev3b.yrl", 500).
yeccpars2_775_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_776_/1}).
-file("megaco_text_parser_prev3b.yrl", 499).
yeccpars2_776_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_777_/1}).
-file("megaco_text_parser_prev3b.yrl", 497).
yeccpars2_777_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_780_/1}).
-file("megaco_text_parser_prev3b.yrl", 598).
yeccpars2_780_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_783_/1}).
-file("megaco_text_parser_prev3b.yrl", 597).
yeccpars2_783_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   'NULL'
  end | __Stack].

-compile({inline,yeccpars2_785_/1}).
-file("megaco_text_parser_prev3b.yrl", 600).
yeccpars2_785_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionError , __1 }
  end | __Stack].

-compile({inline,yeccpars2_786_/1}).
-file("megaco_text_parser_prev3b.yrl", 604).
yeccpars2_786_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_791_/1}).
-file("megaco_text_parser_prev3b.yrl", 625).
yeccpars2_791_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_792_/1}).
-file("megaco_text_parser_prev3b.yrl", 628).
yeccpars2_792_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_793_/1}).
-file("megaco_text_parser_prev3b.yrl", 611).
yeccpars2_793_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'ActionReply' { errorDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_794_/1}).
-file("megaco_text_parser_prev3b.yrl", 629).
yeccpars2_794_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { context , __1 }
  end | __Stack].

-compile({inline,yeccpars2_795_/1}).
-file("megaco_text_parser_prev3b.yrl", 623).
yeccpars2_795_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_796_/1}).
-file("megaco_text_parser_prev3b.yrl", 626).
yeccpars2_796_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_798_/1}).
-file("megaco_text_parser_prev3b.yrl", 627).
yeccpars2_798_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_800_/1}).
-file("megaco_text_parser_prev3b.yrl", 663).
yeccpars2_800_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   addReply
  end | __Stack].

-compile({inline,yeccpars2_803_/1}).
-file("megaco_text_parser_prev3b.yrl", 665).
yeccpars2_803_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modReply
  end | __Stack].

-compile({inline,yeccpars2_804_/1}).
-file("megaco_text_parser_prev3b.yrl", 664).
yeccpars2_804_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   moveReply
  end | __Stack].

-compile({inline,yeccpars2_807_/1}).
-file("megaco_text_parser_prev3b.yrl", 666).
yeccpars2_807_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   subtractReply
  end | __Stack].

-compile({inline,yeccpars2_809_/1}).
-file("megaco_text_parser_prev3b.yrl", 928).
yeccpars2_809_(__Stack0) ->
 [begin
   { serviceChangeResParms , # 'ServiceChangeResParm' { } }
  end | __Stack0].

-compile({inline,yeccpars2_810_/1}).
-file("megaco_text_parser_prev3b.yrl", 920).
yeccpars2_810_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceChangeReply ,
    # 'ServiceChangeReply' { terminationID = [ __3 ] ,
    serviceChangeResult = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_816_/1}).
-file("megaco_text_parser_prev3b.yrl", 1396).
yeccpars2_816_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { time_stamp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_817_/1}).
-file("megaco_text_parser_prev3b.yrl", 1395).
yeccpars2_817_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { version , __1 }
  end | __Stack].

-compile({inline,yeccpars2_818_/1}).
-file("megaco_text_parser_prev3b.yrl", 1394).
yeccpars2_818_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { profile , __1 }
  end | __Stack].

-compile({inline,yeccpars2_819_/1}).
-file("megaco_text_parser_prev3b.yrl", 1393).
yeccpars2_819_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mgc_id , __1 }
  end | __Stack].

-compile({inline,yeccpars2_820_/1}).
-file("megaco_text_parser_prev3b.yrl", 1392).
yeccpars2_820_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { address , __1 }
  end | __Stack].

-compile({inline,yeccpars2_821_/1}).
-file("megaco_text_parser_prev3b.yrl", 1390).
yeccpars2_821_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_828_/1}).
-file("megaco_text_parser_prev3b.yrl", 1390).
yeccpars2_828_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_829_/1}).
-file("megaco_text_parser_prev3b.yrl", 1389).
yeccpars2_829_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_830_/1}).
-file("megaco_text_parser_prev3b.yrl", 1386).
yeccpars2_830_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_ServiceChangeResParm ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_831_/1}).
-file("megaco_text_parser_prev3b.yrl", 925).
yeccpars2_831_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { errorDescriptor , __2 }
  end | __Stack].

-compile({inline,yeccpars2_832_/1}).
-file("megaco_text_parser_prev3b.yrl", 927).
yeccpars2_832_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceChangeResParms , __2 }
  end | __Stack].

-compile({inline,yeccpars2_834_/1}).
-file("megaco_text_parser_prev3b.yrl", 911).
yeccpars2_834_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_835_/1}).
-file("megaco_text_parser_prev3b.yrl", 906).
yeccpars2_835_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { notifyReply ,
    # 'NotifyReply' { terminationID = [ __3 ] ,
    errorDescriptor = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_838_/1}).
-file("megaco_text_parser_prev3b.yrl", 910).
yeccpars2_838_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_840_/1}).
-file("megaco_text_parser_prev3b.yrl", 707).
yeccpars2_840_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditResult ,
    # 'AuditResult' { terminationID = __1 ,
    terminationAuditResult = [ ] } }
  end | __Stack].

-compile({inline,yeccpars2_841_/1}).
-file("megaco_text_parser_prev3b.yrl", 697).
yeccpars2_841_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditValueReply , __3 }
  end | __Stack].

-compile({inline,yeccpars2_843_/1}).
-file("megaco_text_parser_prev3b.yrl", 702).
yeccpars2_843_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextAuditResult , __1 }
  end | __Stack].

-compile({inline,yeccpars2_844_/1}).
-file("megaco_text_parser_prev3b.yrl", 693).
yeccpars2_844_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditValueReply , __4 }
  end | __Stack].

-compile({inline,yeccpars2_849_/1}).
-file("megaco_text_parser_prev3b.yrl", 934).
yeccpars2_849_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint ( __1 , 0 , 999 )
  end | __Stack].

-compile({inline,yeccpars2_851_/1}).
-file("megaco_text_parser_prev3b.yrl", 937).
yeccpars2_851_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_853_/1}).
-file("megaco_text_parser_prev3b.yrl", 936).
yeccpars2_853_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   value_of ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_854_/1}).
-file("megaco_text_parser_prev3b.yrl", 931).
yeccpars2_854_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'ErrorDescriptor' { errorCode = __3 ,
    errorText = __5 }
  end | __Stack].

-compile({inline,yeccpars2_855_/1}).
-file("megaco_text_parser_prev3b.yrl", 704).
yeccpars2_855_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { error , __2 }
  end | __Stack].

-compile({inline,yeccpars2_858_/1}).
-file("megaco_text_parser_prev3b.yrl", 730).
yeccpars2_858_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_859_/1}).
-file("megaco_text_parser_prev3b.yrl", 726).
yeccpars2_859_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_860_/1}).
-file("megaco_text_parser_prev3b.yrl", 731).
yeccpars2_860_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { packagesDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_861_/1}).
-file("megaco_text_parser_prev3b.yrl", 728).
yeccpars2_861_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { observedEventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_862_/1}).
-file("megaco_text_parser_prev3b.yrl", 724).
yeccpars2_862_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { muxDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_863_/1}).
-file("megaco_text_parser_prev3b.yrl", 0).
yeccpars2_863_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_864_/1}).
-file("megaco_text_parser_prev3b.yrl", 722).
yeccpars2_864_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_865_/1}).
-file("megaco_text_parser_prev3b.yrl", 725).
yeccpars2_865_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_866_/1}).
-file("megaco_text_parser_prev3b.yrl", 729).
yeccpars2_866_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_867_/1}).
-file("megaco_text_parser_prev3b.yrl", 732).
yeccpars2_867_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { errorDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_868_/1}).
-file("megaco_text_parser_prev3b.yrl", 727).
yeccpars2_868_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { digitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_869_/1}).
-file("megaco_text_parser_prev3b.yrl", 720).
yeccpars2_869_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_870_/1}).
-file("megaco_text_parser_prev3b.yrl", 733).
yeccpars2_870_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditReturnItem , __1 }
  end | __Stack].

-compile({inline,yeccpars2_871_/1}).
-file("megaco_text_parser_prev3b.yrl", 748).
yeccpars2_871_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   mediaToken
  end | __Stack].

-compile({inline,yeccpars2_872_/1}).
-file("megaco_text_parser_prev3b.yrl", 747).
yeccpars2_872_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modemToken
  end | __Stack].

-compile({inline,yeccpars2_873_/1}).
-file("megaco_text_parser_prev3b.yrl", 746).
yeccpars2_873_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   muxToken
  end | __Stack].

-compile({inline,yeccpars2_874_/1}).
-file("megaco_text_parser_prev3b.yrl", 751).
yeccpars2_874_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   observedEventsToken
  end | __Stack].

-compile({inline,yeccpars2_875_/1}).
-file("megaco_text_parser_prev3b.yrl", 752).
yeccpars2_875_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   packagesToken
  end | __Stack].

-compile({inline,yeccpars2_876_/1}).
-file("megaco_text_parser_prev3b.yrl", 750).
yeccpars2_876_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statsToken
  end | __Stack].

-compile({inline,yeccpars2_878_/1}).
-file("megaco_text_parser_prev3b.yrl", 1403).
yeccpars2_878_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_881_/1}).
-file("megaco_text_parser_prev3b.yrl", 1403).
yeccpars2_881_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_882_/1}).
-file("megaco_text_parser_prev3b.yrl", 1402).
yeccpars2_882_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_883_/1}).
-file("megaco_text_parser_prev3b.yrl", 1400).
yeccpars2_883_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_884_/1}).
-file("megaco_text_parser_prev3b.yrl", 717).
yeccpars2_884_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_terminationAudit ( [ __1 | __2 ] )
  end | __Stack].

-compile({inline,yeccpars2_886_/1}).
-file("megaco_text_parser_prev3b.yrl", 720).
yeccpars2_886_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_887_/1}).
-file("megaco_text_parser_prev3b.yrl", 719).
yeccpars2_887_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_888_/1}).
-file("megaco_text_parser_prev3b.yrl", 711).
yeccpars2_888_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditResult ,
    # 'AuditResult' { terminationID = __1 ,
    terminationAuditResult = __3 } }
  end | __Stack].

-compile({inline,yeccpars2_890_/1}).
-file("megaco_text_parser_prev3b.yrl", 699).
yeccpars2_890_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditCapReply , __3 }
  end | __Stack].

-compile({inline,yeccpars2_892_/1}).
-file("megaco_text_parser_prev3b.yrl", 695).
yeccpars2_892_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditCapReply , __4 }
  end | __Stack].

-compile({inline,yeccpars2_893_/1}).
-file("megaco_text_parser_prev3b.yrl", 608).
yeccpars2_893_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'ActionReply' .contextId , __5 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_895_/1}).
-file("megaco_text_parser_prev3b.yrl", 669).
yeccpars2_895_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_896_/1}).
-file("megaco_text_parser_prev3b.yrl", 660).
yeccpars2_896_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { __1 , # 'AmmsReply' { terminationID = [ __3 ] ,
    terminationAudit = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_899_/1}).
-file("megaco_text_parser_prev3b.yrl", 668).
yeccpars2_899_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_900_/1}).
-file("megaco_text_parser_prev3b.yrl", 613).
yeccpars2_900_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_action_reply ( [ __1 | __2 ] )
  end | __Stack].

-compile({inline,yeccpars2_902_/1}).
-file("megaco_text_parser_prev3b.yrl", 620).
yeccpars2_902_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ { error , __2 } ]
  end | __Stack].

-compile({inline,yeccpars2_903_/1}).
-file("megaco_text_parser_prev3b.yrl", 623).
yeccpars2_903_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_904_/1}).
-file("megaco_text_parser_prev3b.yrl", 622).
yeccpars2_904_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_905_/1}).
-file("megaco_text_parser_prev3b.yrl", 601).
yeccpars2_905_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { actionReplies , [ __1 | __2 ] }
  end | __Stack].

-compile({inline,yeccpars2_907_/1}).
-file("megaco_text_parser_prev3b.yrl", 604).
yeccpars2_907_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_908_/1}).
-file("megaco_text_parser_prev3b.yrl", 603).
yeccpars2_908_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_909_/1}).
-file("megaco_text_parser_prev3b.yrl", 593).
yeccpars2_909_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionReply' { transactionId = __3 ,
    immAckRequired = __5 ,
    transactionResult = __6 }
  end | __Stack].

-compile({inline,yeccpars2_913_/1}).
-file("megaco_text_parser_prev3b.yrl", 505).
yeccpars2_913_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionPending' { transactionId = ensure_transactionID ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_914_/1}).
-file("megaco_text_parser_prev3b.yrl", 489).
yeccpars2_914_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_915_/1}).
-file("megaco_text_parser_prev3b.yrl", 980).
yeccpars2_915_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_pathName ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_916_/1}).
-file("megaco_text_parser_prev3b.yrl", 951).
yeccpars2_916_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { deviceName , __1 }
  end | __Stack].

-compile({inline,yeccpars2_917_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_917_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_918_/1}).
-file("megaco_text_parser_prev3b.yrl", 476).
yeccpars2_918_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_919_/1}).
-file("megaco_text_parser_prev3b.yrl", 968).
yeccpars2_919_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_mtpAddress ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_920_/1}).
-file("megaco_text_parser_prev3b.yrl", 944).
yeccpars2_920_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_921_/1}).
-file("megaco_text_parser_prev3b.yrl", 943).
yeccpars2_921_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].


-file("megaco_text_parser_prev3b.yrl", 1602).
