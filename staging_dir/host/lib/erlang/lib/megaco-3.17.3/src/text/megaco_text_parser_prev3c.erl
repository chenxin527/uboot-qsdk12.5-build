-module(megaco_text_parser_prev3c).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("megaco_text_parser_prev3c.yrl", 1665).

%% The following directive is needed for (significantly) faster compilation
%% of the generated .erl file by the HiPE compiler.  Please do not remove.
-compile([{hipe,[{regalloc,linear_scan}]}]).

-include("megaco_text_parser_prev3c.hrl").



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



-file("./megaco_text_parser_prev3c.erl", 197).

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
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(85=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_85(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(86=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(87=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_87(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(88=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_88(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(89=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_89(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(90=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_90(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(91=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(92=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_92(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(93=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_93(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(94=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_94(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(95=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_95(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(96=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(97=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(98=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_98(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(99=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_99(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(100=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_100(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(101=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_101(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(102=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(103=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(104=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_104(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(105=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_105(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(106=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_106(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(107=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_107(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(108=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_108(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(109=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_109(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(110=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(111=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_111(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(112=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_112(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(113=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_113(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(121=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(122=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(123=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(124=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_124(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(125=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(126=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(127=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(133=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_133(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(141=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_141(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(142=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_142(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(143=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_143(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(144=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_144(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(145=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_145(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(146=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_146(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(147=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_147(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(148=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_148(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(149=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_149(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(150=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_150(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(151=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_151(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(152=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_152(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(153=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_153(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(154=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_154(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(162=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_162(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(163=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(164=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_164(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(165=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_165(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(166=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(167=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_167(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(168=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_168(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(169=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_169(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_164(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(181=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_181(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(182=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(183=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_183(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(184=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(185=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_185(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(186=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_186(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(187=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(188=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_188(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(189=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_189(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(190=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(191=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_191(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(192=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_192(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(193=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(194=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_194(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(195=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_195(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(196=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_196(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(197=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(198=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_198(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(199=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_199(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(200=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_200(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(201=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_201(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(202=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_202(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(203=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_203(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(204=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_204(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(205=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_205(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(206=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_206(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(207=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_207(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(208=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_208(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(209=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_209(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(210=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_210(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(211=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(212=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(213=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_213(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(214=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_214(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(215=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_215(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(216=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_216(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(217=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_217(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(218=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_218(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(219=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_219(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(220=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_220(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(221=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_221(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(222=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(223=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_223(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(224=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_224(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(225=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_225(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(226=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_226(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(227=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(233=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_233(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(234=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_234(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(235=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(236=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_236(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(237=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_237(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(238=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(239=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_239(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(240=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_240(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(241=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_241(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(242=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_242(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(243=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_243(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(244=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_244(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(245=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_245(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(246=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_246(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(247=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_247(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(248=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(249=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_249(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(250=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_250(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(251=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_251(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(252=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_252(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(253=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_253(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(254=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(255=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_255(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(256=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_256(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(257=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_257(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(258=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_258(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(259=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(260=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_260(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(261=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(262=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_262(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(263=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_263(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(264=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_264(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(271=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_271(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(272=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_272(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(273=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_265(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(274=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_274(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(275=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_275(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(276=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_276(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(277=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(278=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_278(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(279=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(280=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_280(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(281=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_281(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(282=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_282(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(283=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_283(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(284=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_284(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(285=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_285(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(286=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_286(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(287=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_287(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(288=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(289=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(290=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(291=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_291(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(292=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_292(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(293=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_293(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(294=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(295=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_295(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(296=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_296(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(297=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_297(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(298=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(299=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(300=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_300(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(301=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_301(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(302=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(303=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(304=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_304(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(305=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_305(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(306=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_306(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(307=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_307(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(308=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_308(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(309=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_309(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(310=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_310(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(311=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_311(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(312=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_312(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(313=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_243(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(314=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_314(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(315=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_315(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(316=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_316(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(317=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(318=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_318(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(319=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_319(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(320=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_320(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(321=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_321(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(322=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_322(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(323=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_323(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(324=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_324(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(325=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_325(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(326=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_326(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(327=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_327(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(328=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_328(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(329=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_329(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(330=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_330(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(331=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_331(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(332=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_332(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(333=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_333(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(334=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_334(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(335=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_335(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(336=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_336(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(337=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_337(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(338=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_338(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(339=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_339(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(340=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_340(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(341=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_341(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(342=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_341(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(343=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_343(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(344=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(345=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_345(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(346=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_346(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(347=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_347(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(348=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_348(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(349=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_349(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(350=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(351=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_351(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(352=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_352(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(353=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_353(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(354=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_354(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(355=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_355(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(356=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_356(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(357=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_357(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(358=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_358(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(359=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_359(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(360=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_360(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(361=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_361(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(362=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_362(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(363=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_362(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(364=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_364(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(365=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_365(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(366=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_366(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(367=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_367(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(368=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_368(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(369=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_369(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(370=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_370(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(371=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_371(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(372=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_355(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(373=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_373(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(374=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_374(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(375=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_375(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(376=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_376(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(377=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_321(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(378=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_378(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(379=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_379(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(380=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_380(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(381=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(382=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(383=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_383(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(384=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_384(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(385=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_385(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(386=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_386(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(387=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(388=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_388(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(389=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_389(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(390=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(391=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_391(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(392=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_392(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(393=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_393(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(394=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_394(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(395=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_395(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(396=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_396(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(397=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_397(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(398=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_398(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(399=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_399(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(400=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_400(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(401=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_401(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(402=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_402(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(403=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_403(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(404=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_404(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(405=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_405(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(406=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_406(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(407=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_407(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(408=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_408(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(409=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_409(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(410=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_410(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(411=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_411(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(412=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_412(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(413=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_413(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(414=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_414(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(415=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_415(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(416=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(417=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_417(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(418=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_418(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(419=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_419(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(420=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_420(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(421=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_421(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(422=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_422(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(423=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_423(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(424=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_424(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(425=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_425(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(426=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_426(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(427=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_427(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(428=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_428(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(429=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_429(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(430=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_430(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(431=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_431(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(432=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_245(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(433=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_433(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(434=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_434(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(435=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_435(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(436=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_436(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(437=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_437(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(438=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_438(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(439=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_439(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(440=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_440(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(441=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_441(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(442=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_442(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(443=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_443(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(444=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(445=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_445(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(446=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_446(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(447=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_447(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(448=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_448(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(449=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(450=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_450(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(451=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(452=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_452(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(453=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_453(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(454=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_454(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(455=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(456=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_456(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(457=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(458=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_458(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(459=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_459(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(460=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_460(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(461=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_421(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(462=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_462(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(463=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_463(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(464=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_464(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(465=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_465(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(466=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(467=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_467(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(468=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(469=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_469(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(470=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_470(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(471=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_471(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(472=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_472(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(473=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_473(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(474=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_474(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(475=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(476=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_476(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(477=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_477(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(478=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_478(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(479=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(480=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_480(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(481=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_481(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(482=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_482(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(483=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_483(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(484=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_484(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(485=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_485(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(486=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_486(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(487=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_487(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(488=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(489=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_489(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(490=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_490(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(491=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_245(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(492=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_492(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(498=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_498(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(499=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_499(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(500=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(501=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_501(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(502=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_502(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(503=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_503(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(504=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_504(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(505=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_505(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(506=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_506(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(507=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_507(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(508=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_508(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(516=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_516(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(517=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_517(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(524=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_524(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(525=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_525(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(526=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_526(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(527=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_527(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(528=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_528(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(529=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_529(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(530=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_530(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(531=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_531(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(532=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_532(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(533=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_533(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(534=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_534(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(535=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_535(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(536=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_536(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(537=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(538=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_538(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(539=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_539(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(540=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(541=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_541(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(542=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_542(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(543=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_543(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(544=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_544(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(545=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_545(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(551=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(552=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_552(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(553=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_245(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(554=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_554(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(555=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_555(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(556=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_556(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(557=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_557(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(558=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_558(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(559=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_559(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(560=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(561=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_561(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(562=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_562(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(563=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(564=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_564(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(565=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_565(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(566=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_566(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(567=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_567(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(568=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_133(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(569=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_569(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(570=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_570(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(571=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(580=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_580(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(581=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_581(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(582=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_582(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(583=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_583(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(584=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_584(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(585=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_585(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(586=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_586(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(587=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_587(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(588=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_588(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(589=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_589(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(590=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_590(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(591=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_591(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(592=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_592(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(593=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(594=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_594(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(595=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_595(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(596=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_596(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(597=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_597(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(598=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(599=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_599(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(600=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_600(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(601=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_601(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(602=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_602(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(603=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(604=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_604(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(605=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_605(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(606=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_606(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(607=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_607(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(608=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_608(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(609=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_609(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(610=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_610(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(611=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_611(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(612=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(613=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_613(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(614=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(615=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_615(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(616=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_616(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(617=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(618=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_618(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(619=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_619(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(620=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_620(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(621=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_621(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(622=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_607(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(623=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_623(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(624=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_624(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(625=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_625(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(626=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(627=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_627(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(628=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_628(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(629=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_629(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(630=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(631=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_631(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(632=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_632(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(633=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_633(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(634=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(635=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(636=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_636(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(637=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_637(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(638=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_638(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(639=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(640=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_640(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(641=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_641(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(642=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_642(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(643=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_643(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(644=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(645=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_645(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(646=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_646(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(647=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_647(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(656=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_656(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(657=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_657(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(658=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_658(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(659=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_659(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(660=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_660(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(661=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_661(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(662=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_662(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(663=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_663(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(664=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_664(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(665=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_665(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(666=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_666(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(667=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_667(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(668=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_668(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(669=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_341(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(670=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_670(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(671=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_671(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(672=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_672(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(673=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_673(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(674=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_674(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(675=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_675(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(676=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_662(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(677=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_677(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(678=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_678(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(679=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_679(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(680=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(681=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_681(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(682=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_682(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(683=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_683(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(684=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_684(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(685=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_682(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(686=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_686(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(687=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_687(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(688=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_688(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(689=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_689(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(690=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_690(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(691=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_691(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(692=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_692(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(693=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_693(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(694=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_694(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(695=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_504(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(696=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_696(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(697=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_504(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(698=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_698(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(699=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_362(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(700=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_700(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(701=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_701(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(702=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_689(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(703=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_703(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(704=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_704(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(705=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_705(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(706=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_706(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(707=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_650(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(708=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_708(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(709=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_709(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(710=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_710(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(711=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(712=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_712(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(713=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(714=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_714(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(715=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_715(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(716=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_716(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(717=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_717(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(718=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_718(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(719=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_719(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(720=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_720(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(721=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_721(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(722=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_722(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(723=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_723(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(724=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_724(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(725=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_725(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(726=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_726(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(727=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_727(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(728=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_728(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(729=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_729(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(730=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_730(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(731=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_731(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(732=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_732(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(733=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_733(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(734=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_734(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(735=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_735(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(736=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_736(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(749=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_749(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(750=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_750(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(751=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_751(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(752=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_752(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(753=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_753(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(754=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_754(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(755=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_755(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(756=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_756(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(757=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_757(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(758=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_758(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(759=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_746(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(760=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_760(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(761=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_761(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(762=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_762(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(763=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_763(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(764=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(765=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_765(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(766=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_766(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(767=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_767(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(768=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_768(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(769=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_769(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(770=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_770(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(771=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_771(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(772=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_772(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(773=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_773(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(774=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_774(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(775=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_775(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(776=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_717(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(777=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_777(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(778=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_778(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(779=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_779(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(780=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_780(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(781=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(782=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_782(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(783=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_783(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(784=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_784(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(785=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_785(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(786=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_786(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(787=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_787(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(788=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_788(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(789=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_789(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(790=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_790(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(791=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_791(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(792=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_792(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(793=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_793(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(794=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_574(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(795=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_795(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(796=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_796(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(797=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_797(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(798=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_798(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(799=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(800=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_800(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(801=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_801(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(802=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_802(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(803=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_803(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(804=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_804(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(805=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(806=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_806(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(807=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_807(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(808=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_808(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(809=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(810=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_810(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(811=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_811(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(812=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_812(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(813=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(814=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_814(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(815=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_815(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(816=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_816(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(817=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(818=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_818(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(819=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_819(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(820=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_820(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(821=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(829=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_829(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(830=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_830(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(831=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(832=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_832(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(833=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_833(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(834=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_834(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(835=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_835(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(836=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_836(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(837=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_837(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(838=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_838(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(839=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_839(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(840=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_840(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(841=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_841(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(842=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_842(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(843=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_843(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(844=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_844(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(845=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_845(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(846=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_846(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(847=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_847(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(848=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_848(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(849=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_849(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(850=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_850(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(851=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(852=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_852(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(853=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_853(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(854=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_854(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(855=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_855(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(856=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_856(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(857=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_857(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(858=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_858(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(865=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_865(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(866=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_866(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(867=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_867(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(868=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_868(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(869=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_869(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(870=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_858(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(871=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_871(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(872=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_872(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(873=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_873(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(874=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_874(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(875=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_875(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(876=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(877=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_877(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(878=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_878(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(879=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_879(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(880=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_880(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(881=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_881(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(882=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_882(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(883=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_883(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(884=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_884(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(885=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_885(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(886=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_886(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(887=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_887(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(888=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_888(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(889=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_889(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(890=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_890(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(891=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(892=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_892(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(893=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_893(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(894=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_894(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(895=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_895(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(896=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_896(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(897=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_897(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(898=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_898(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(899=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_899(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(900=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_900(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(906=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_906(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(907=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_907(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(908=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_908(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(909=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_909(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(910=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_910(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(911=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_911(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(912=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_912(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(913=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_913(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(914=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_914(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(915=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_915(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(916=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_916(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(917=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_917(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(918=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_918(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(919=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_919(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(920=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(921=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_921(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(922=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_922(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(923=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(924=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_924(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(925=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_925(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(926=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_926(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(927=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_927(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(928=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_899(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(929=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_929(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(930=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_930(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(931=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_931(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(932=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_932(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(933=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_933(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(934=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_934(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(935=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_935(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(936=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_936(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(937=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(938=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_938(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(939=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_939(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(940=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_899(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(941=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_941(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(942=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_942(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(943=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_943(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(944=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_833(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(945=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_945(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(946=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_946(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(947=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_947(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(948=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_948(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(949=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_949(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(950=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_950(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(951=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_951(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(952=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_952(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(953=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(954=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_954(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(955=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_955(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(956=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_956(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(957=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_957(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(958=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_958(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(959=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_959(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(960=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_960(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(961=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_961(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(962=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_962(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(963=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_963(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(964=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_964(S, Cat, Ss, Stack, T, Ts, Tzr);
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

yeccpars2_4(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_4(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_4(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
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
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
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

%% yeccpars2_84: see yeccpars2_4

yeccpars2_85(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_85(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_86: see yeccpars2_4

yeccpars2_87(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_87_(Stack),
 yeccpars2_88(_S, Cat, [87 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_88_(Stack),
 yeccgoto_authenticationHeader(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_89(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_89_(Stack),
 yeccpars2_92(92, Cat, [89 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_90(S, endOfMessage, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 91, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_91(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_91_(Stack),
 yeccgoto_megacoMessage(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_92(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'MtpAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 962, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_92(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_93(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 121, Ss, Stack, T, Ts, Tzr);
yeccpars2_93(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 122, Ss, Stack, T, Ts, Tzr);
yeccpars2_93(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 123, Ss, Stack, T, Ts, Tzr);
yeccpars2_93(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 124, Ss, Stack, T, Ts, Tzr);
yeccpars2_93(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 125, Ss, Stack, T, Ts, Tzr);
yeccpars2_93(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mId(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mId(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_96: see yeccpars2_4

yeccpars2_97(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_97_(Stack),
 yeccpars2_99(99, Cat, [97 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_98(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_98_(Stack),
 yeccpars2_107(_S, Cat, [98 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_99(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_99(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_100(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 100, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_100(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_100_(Stack),
 yeccpars2_101(_S, Cat, [100 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_101_(Stack),
 yeccgoto_daddr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_102(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_102(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_102_(Stack),
 yeccgoto_domainAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_103: see yeccpars2_4

yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_104_(Stack),
 yeccgoto_portNumber(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_105(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_105(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_105_(Stack),
 yeccpars2_106(_S, Cat, [105 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_106_(Stack),
 yeccgoto_domainAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_107_(Stack),
 yeccgoto_daddr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_108(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 109, Ss, Stack, T, Ts, Tzr);
yeccpars2_108(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_109(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 110, Ss, Stack, T, Ts, Tzr);
yeccpars2_109(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_109_(Stack),
 yeccgoto_domainName(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_110: see yeccpars2_4

yeccpars2_111(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_111(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_111_(Stack),
 yeccpars2_112(_S, Cat, [111 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_112(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_112_(Stack),
 yeccgoto_domainName(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_113_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_114_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_115_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_116_(Stack),
 yeccgoto_transactionItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_117_(Stack),
 yeccgoto_messageBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_118(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 122, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 123, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 124, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 125, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_118_(Stack),
 yeccgoto_transactionList(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_119_(Stack),
 yeccgoto_message(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_120_(Stack),
 yeccgoto_messageBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_121(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 891, Ss, Stack, T, Ts, Tzr);
yeccpars2_121(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_122(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 953, Ss, Stack, T, Ts, Tzr);
yeccpars2_122(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_123(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 821, Ss, Stack, T, Ts, Tzr);
yeccpars2_123(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_124(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 813, Ss, Stack, T, Ts, Tzr);
yeccpars2_124(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_125(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 126, Ss, Stack, T, Ts, Tzr);
yeccpars2_125(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 127, Ss, Stack, T, Ts, Tzr);
yeccpars2_125(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_126(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 805, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_126(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_127(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 129, Ss, Stack, T, Ts, Tzr);
yeccpars2_127(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_128(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 799, Ss, Stack, T, Ts, Tzr);
yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_128_(Stack),
 yeccpars2_798(798, Cat, [128 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_129(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 130, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_130: see yeccpars2_4

yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_131_(Stack),
 yeccgoto_contextID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_132(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 133, Ss, Stack, T, Ts, Tzr);
yeccpars2_132(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_133(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 149, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 150, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 151, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 152, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 153, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 154, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 156, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 157, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 158, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 159, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 160, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 161, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 162, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 163, Ss, Stack, T, Ts, Tzr);
yeccpars2_133(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_134_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_137_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_139_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_140_(Stack),
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_141(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_141_(Stack),
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_142(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_143(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_143_(Stack),
 yeccgoto_actionRequestItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_144(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_145(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 571, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_146(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_commandRequest(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_147(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 568, Ss, Stack, T, Ts, Tzr);
yeccpars2_147(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_147_(Stack),
 yeccpars2_567(_S, Cat, [147 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_148(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 566, Ss, Stack, T, Ts, Tzr);
yeccpars2_148(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_149(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_149_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_150(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 563, Ss, Stack, T, Ts, Tzr);
yeccpars2_150(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_151(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 560, Ss, Stack, T, Ts, Tzr);
yeccpars2_151(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_152(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 559, Ss, Stack, T, Ts, Tzr);
yeccpars2_152(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_153(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 508, Ss, Stack, T, Ts, Tzr);
yeccpars2_153(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_154_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_155_(Stack),
 yeccgoto_contextProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_156(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 504, Ss, Stack, T, Ts, Tzr);
yeccpars2_156(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_157_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_158_(Stack),
 yeccgoto_ammToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_159(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 468, Ss, Stack, T, Ts, Tzr);
yeccpars2_159(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_160(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 466, Ss, Stack, T, Ts, Tzr);
yeccpars2_160(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_161(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 416, Ss, Stack, T, Ts, Tzr);
yeccpars2_161(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_162(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 184, Ss, Stack, T, Ts, Tzr);
yeccpars2_162(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_163(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 164, Ss, Stack, T, Ts, Tzr);
yeccpars2_163(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_164(S, 'BothwayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'IsolateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 171, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'OnewayBothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 172, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'OnewayExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'OnewayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 174, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 175, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_topologyDescComp(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_166(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 180, Ss, Stack, T, Ts, Tzr);
yeccpars2_166(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_166_(Stack),
 yeccpars2_179(179, Cat, [166 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_167(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_167_(Stack),
 yeccgoto_topologyDescComp(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_168_(Stack),
 yeccgoto_terminationID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_169(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_(Stack),
 yeccgoto_topologyDescComp(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_170(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_170_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_171_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_172(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_172_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_173(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_173_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_174_(Stack),
 yeccgoto_topologyDirection(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_175(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 176, Ss, Stack, T, Ts, Tzr);
yeccpars2_175(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_176: see yeccpars2_4

yeccpars2_177(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_177_(Stack),
 yeccgoto_eventStream(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_178_(Stack),
 yeccgoto_streamID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_179(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 183, Ss, Stack, T, Ts, Tzr);
yeccpars2_179(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_180: see yeccpars2_164

yeccpars2_181(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 180, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_181_(Stack),
 yeccpars2_182(_S, Cat, [181 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_182(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_182_(Stack),
 yeccgoto_topologyDescCompList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_183(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_183_(Stack),
 yeccgoto_topologyDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_184(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 187, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_185_(Stack),
 yeccgoto_termIDList(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_186(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 195, Ss, Stack, T, Ts, Tzr);
yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_186_(Stack),
 yeccpars2_194(_S, Cat, [186 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_187: see yeccpars2_4

yeccpars2_188(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 190, Ss, Stack, T, Ts, Tzr);
yeccpars2_188(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_188_(Stack),
 yeccpars2_189(189, Cat, [188 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_189(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 193, Ss, Stack, T, Ts, Tzr);
yeccpars2_189(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_190: see yeccpars2_4

yeccpars2_191(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 190, Ss, Stack, T, Ts, Tzr);
yeccpars2_191(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_191_(Stack),
 yeccpars2_192(_S, Cat, [191 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_192(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_192_(Stack),
 yeccgoto_terminationIDListRepeat(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_193(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_193_(Stack),
 yeccgoto_termIDList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_194(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_194_(Stack),
 yeccgoto_subtractRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_195(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 197, Ss, Stack, T, Ts, Tzr);
yeccpars2_195(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_196(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 415, Ss, Stack, T, Ts, Tzr);
yeccpars2_196(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_197(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 198, Ss, Stack, T, Ts, Tzr);
yeccpars2_197(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_198(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 211, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 212, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 213, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 214, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 215, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 216, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 217, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 218, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 219, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_198(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_198_(Stack),
 yeccpars2_210(210, Cat, [198 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_199_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_200_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_201(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_201_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_202_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_203_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_204(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_204_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_205(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_205_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_206(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_206_(Stack),
 yeccgoto_indAudauditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_207(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 407, Ss, Stack, T, Ts, Tzr);
yeccpars2_207(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_207_(Stack),
 yeccpars2_406(_S, Cat, [207 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_auditItem(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_209(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 403, Ss, Stack, T, Ts, Tzr);
yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_209_(Stack),
 yeccpars2_402(_S, Cat, [209 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_210(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 401, Ss, Stack, T, Ts, Tzr);
yeccpars2_210(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_211(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_211_(Stack),
 yeccgoto_indAuddigitMapDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_212(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_212_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_213(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 390, Ss, Stack, T, Ts, Tzr);
yeccpars2_213(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_213_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_214(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 381, Ss, Stack, T, Ts, Tzr);
yeccpars2_214(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 382, Ss, Stack, T, Ts, Tzr);
yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_214_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_215(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 321, Ss, Stack, T, Ts, Tzr);
yeccpars2_215(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_215_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_216(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_216_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_217(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_217_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_218(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_218_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_219(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 317, Ss, Stack, T, Ts, Tzr);
yeccpars2_219(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_219_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_220(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 227, Ss, Stack, T, Ts, Tzr);
yeccpars2_220(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_220_(Stack),
 yeccgoto_auditItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_221(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 222, Ss, Stack, T, Ts, Tzr);
yeccpars2_221(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_221_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_222: see yeccpars2_4

yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_223_(Stack),
 yeccgoto_pkgdName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_224(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 225, Ss, Stack, T, Ts, Tzr);
yeccpars2_224(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_225(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_225_(Stack),
 yeccgoto_indAudstatisticsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_226_(Stack),
 yeccgoto_indAudsignalsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_227(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 233, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 234, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_228_(Stack),
 yeccgoto_indAudsignalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_229(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 243, Ss, Stack, T, Ts, Tzr);
yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_229_(Stack),
 yeccgoto_signalRequest(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_signalName(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_231(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 242, Ss, Stack, T, Ts, Tzr);
yeccpars2_231(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_232_(Stack),
 yeccgoto_indAudsignalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_233(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_233_(Stack),
 yeccgoto_optIndAudsignalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_234(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 235, Ss, Stack, T, Ts, Tzr);
yeccpars2_234(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_235: see yeccpars2_4

yeccpars2_236(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 238, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_236_(Stack),
 yeccgoto_indAudsignalList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_237(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_237_(Stack),
 yeccgoto_signalListId(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_238: see yeccpars2_4

yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_signalListParm(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_240(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 241, Ss, Stack, T, Ts, Tzr);
yeccpars2_240(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_241(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_241_(Stack),
 yeccgoto_indAudsignalList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_242(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_242_(Stack),
 yeccgoto_optIndAudsignalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_243(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 246, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 247, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'IntsigDelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 248, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 249, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 250, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 251, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 252, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 253, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_244(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 313, Ss, Stack, T, Ts, Tzr);
yeccpars2_244(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_244_(Stack),
 yeccpars2_312(312, Cat, [244 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_245(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 287, Ss, Stack, T, Ts, Tzr);
yeccpars2_245(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 288, Ss, Stack, T, Ts, Tzr);
yeccpars2_245(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 289, Ss, Stack, T, Ts, Tzr);
yeccpars2_245(S, 'NEQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 290, Ss, Stack, T, Ts, Tzr);
yeccpars2_245(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_246(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 281, Ss, Stack, T, Ts, Tzr);
yeccpars2_246(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_247(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 279, Ss, Stack, T, Ts, Tzr);
yeccpars2_247(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_248(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 277, Ss, Stack, T, Ts, Tzr);
yeccpars2_248(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_249(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_249_COMMA(Stack),
 yeccgoto_sigParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_249(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_249_RBRKT(Stack),
 yeccgoto_sigParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_249(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_250(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 264, Ss, Stack, T, Ts, Tzr);
yeccpars2_250(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_251(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 261, Ss, Stack, T, Ts, Tzr);
yeccpars2_251(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_252(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 256, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_253(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 254, Ss, Stack, T, Ts, Tzr);
yeccpars2_253(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_254: see yeccpars2_4

yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_255_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_256(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 258, Ss, Stack, T, Ts, Tzr);
yeccpars2_256(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 259, Ss, Stack, T, Ts, Tzr);
yeccpars2_256(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 260, Ss, Stack, T, Ts, Tzr);
yeccpars2_256(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_257(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_257_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_258(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_258_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_259(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_259_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_260(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_260_(Stack),
 yeccgoto_signalType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_261: see yeccpars2_4

yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_262_(Stack),
 yeccgoto_requestID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_263(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_263_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_264(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 265, Ss, Stack, T, Ts, Tzr);
yeccpars2_264(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_265(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 267, Ss, Stack, T, Ts, Tzr);
yeccpars2_265(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 268, Ss, Stack, T, Ts, Tzr);
yeccpars2_265(S, 'IterationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 269, Ss, Stack, T, Ts, Tzr);
yeccpars2_265(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 270, Ss, Stack, T, Ts, Tzr);
yeccpars2_265(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 271, Ss, Stack, T, Ts, Tzr);
yeccpars2_265(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_266(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 273, Ss, Stack, T, Ts, Tzr);
yeccpars2_266(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_266_(Stack),
 yeccpars2_272(272, Cat, [266 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_267(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_267_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_268(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_268_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_269(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_269_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_270(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_270_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_271(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_271_(Stack),
 yeccgoto_notificationReason(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_272(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 276, Ss, Stack, T, Ts, Tzr);
yeccpars2_272(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_273: see yeccpars2_265

yeccpars2_274(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 273, Ss, Stack, T, Ts, Tzr);
yeccpars2_274(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_274_(Stack),
 yeccpars2_275(_S, Cat, [274 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_275(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_275_(Stack),
 yeccgoto_notificationReasons(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_276(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_276_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_277: see yeccpars2_4

yeccpars2_278(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_278_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_279: see yeccpars2_4

yeccpars2_280(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_280_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_281(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 283, Ss, Stack, T, Ts, Tzr);
yeccpars2_281(S, 'ExternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 284, Ss, Stack, T, Ts, Tzr);
yeccpars2_281(S, 'InternalToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 285, Ss, Stack, T, Ts, Tzr);
yeccpars2_281(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_282(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_282_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_283(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_283_(Stack),
 yeccgoto_direction(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_284(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_284_(Stack),
 yeccgoto_direction(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_285(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_285_(Stack),
 yeccgoto_direction(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_286(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_286_(Stack),
 yeccgoto_sigParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_287(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 298, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 299, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 293, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_287(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_288(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 293, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_288(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_289: see yeccpars2_288

%% yeccpars2_290: see yeccpars2_288

yeccpars2_291(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_291_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_292_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_293(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_293_(Stack),
 yeccgoto_value(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_294(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_294_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_295(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_295_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_296(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_296_(Stack),
 yeccgoto_alternativeValue(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_297_(Stack),
 yeccgoto_parmValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_298: see yeccpars2_288

%% yeccpars2_299: see yeccpars2_288

yeccpars2_300(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 302, Ss, Stack, T, Ts, Tzr);
yeccpars2_300(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 303, Ss, Stack, T, Ts, Tzr);
yeccpars2_300(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_300_(Stack),
 yeccpars2_301(301, Cat, [300 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_301(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 308, Ss, Stack, T, Ts, Tzr);
yeccpars2_301(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_302: see yeccpars2_288

%% yeccpars2_303: see yeccpars2_288

yeccpars2_304(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 303, Ss, Stack, T, Ts, Tzr);
yeccpars2_304(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_304_(Stack),
 yeccpars2_305(_S, Cat, [304 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_305(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_305_(Stack),
 yeccgoto_valueList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_306(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 307, Ss, Stack, T, Ts, Tzr);
yeccpars2_306(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_307(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_307_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_308(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_308_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_309(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 303, Ss, Stack, T, Ts, Tzr);
yeccpars2_309(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_309_(Stack),
 yeccpars2_310(310, Cat, [309 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_310(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 311, Ss, Stack, T, Ts, Tzr);
yeccpars2_310(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_311(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_311_(Stack),
 yeccgoto_alternativeValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_312(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 316, Ss, Stack, T, Ts, Tzr);
yeccpars2_312(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_313: see yeccpars2_243

yeccpars2_314(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 313, Ss, Stack, T, Ts, Tzr);
yeccpars2_314(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_314_(Stack),
 yeccpars2_315(_S, Cat, [314 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_315(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_315_(Stack),
 yeccgoto_sigParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_316(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_316_(Stack),
 yeccgoto_signalRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_317: see yeccpars2_4

yeccpars2_318(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_318_(Stack),
 yeccgoto_packagesItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_319(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 320, Ss, Stack, T, Ts, Tzr);
yeccpars2_319(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_320(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_320_(Stack),
 yeccgoto_indAudpackagesDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_321(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 331, Ss, Stack, T, Ts, Tzr);
yeccpars2_321(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 332, Ss, Stack, T, Ts, Tzr);
yeccpars2_321(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 333, Ss, Stack, T, Ts, Tzr);
yeccpars2_321(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_321(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_321(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 328, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_321(S, 'LocalDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 329, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_321(S, 'RemoteDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 330, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_321(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_322(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_322_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_323(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_323_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_324_(Stack),
 yeccgoto_indAudmediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_325(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_325_(Stack),
 yeccgoto_indAudstreamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_326(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 377, Ss, Stack, T, Ts, Tzr);
yeccpars2_326(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_326_(Stack),
 yeccpars2_376(376, Cat, [326 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_327(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_327_(Stack),
 yeccgoto_indAudstreamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_328(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 355, Ss, Stack, T, Ts, Tzr);
yeccpars2_328(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_329_(Stack),
 yeccgoto_indAudstreamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_330(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_330_(Stack),
 yeccgoto_indAudstreamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_331(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 222, Ss, Stack, T, Ts, Tzr);
yeccpars2_331(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_332(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 350, Ss, Stack, T, Ts, Tzr);
yeccpars2_332(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_333(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 334, Ss, Stack, T, Ts, Tzr);
yeccpars2_333(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_334(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 339, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 340, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_335(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_335_(Stack),
 yeccgoto_indAudterminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_336(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 287, Ss, Stack, T, Ts, Tzr);
yeccpars2_336(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 288, Ss, Stack, T, Ts, Tzr);
yeccpars2_336(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 289, Ss, Stack, T, Ts, Tzr);
yeccpars2_336(S, 'NEQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 290, Ss, Stack, T, Ts, Tzr);
yeccpars2_336(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_336_(Stack),
 yeccgoto_indAudterminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_337(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 348, Ss, Stack, T, Ts, Tzr);
yeccpars2_337(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_338(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_indAudterminationStateParm(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_339(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_339_(Stack),
 yeccgoto_indAudterminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_340(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 341, Ss, Stack, T, Ts, Tzr);
yeccpars2_340(S, 'INEQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 342, Ss, Stack, T, Ts, Tzr);
yeccpars2_340(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_340_(Stack),
 yeccgoto_iaServiceStates(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_341(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 344, Ss, Stack, T, Ts, Tzr);
yeccpars2_341(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 345, Ss, Stack, T, Ts, Tzr);
yeccpars2_341(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 346, Ss, Stack, T, Ts, Tzr);
yeccpars2_341(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_342: see yeccpars2_341

yeccpars2_343(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_343_(Stack),
 yeccgoto_iaServiceStates(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_344_(Stack),
 yeccgoto_serviceStatesValue(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_345(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_345_(Stack),
 yeccgoto_serviceStatesValue(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_346(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_346_(Stack),
 yeccgoto_serviceStatesValue(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_347(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_347_(Stack),
 yeccgoto_iaServiceStates(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_348(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_348_(Stack),
 yeccgoto_indAudterminationStateDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_349(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_349_(Stack),
 yeccgoto_propertyParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_350: see yeccpars2_4

yeccpars2_351(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 352, Ss, Stack, T, Ts, Tzr);
yeccpars2_351(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_352(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 331, Ss, Stack, T, Ts, Tzr);
yeccpars2_352(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_321(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_353(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 354, Ss, Stack, T, Ts, Tzr);
yeccpars2_353(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_354(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_354_(Stack),
 yeccgoto_indAudstreamDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_355(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 359, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 360, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 361, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_355(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_356(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_356_(Stack),
 yeccgoto_indAudlocalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_357(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 287, Ss, Stack, T, Ts, Tzr);
yeccpars2_357(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 288, Ss, Stack, T, Ts, Tzr);
yeccpars2_357(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 289, Ss, Stack, T, Ts, Tzr);
yeccpars2_357(S, 'NEQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 290, Ss, Stack, T, Ts, Tzr);
yeccpars2_357(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_357_(Stack),
 yeccgoto_indAudlocalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_358(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 372, Ss, Stack, T, Ts, Tzr);
yeccpars2_358(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_358_(Stack),
 yeccpars2_371(371, Cat, [358 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_359(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 362, Ss, Stack, T, Ts, Tzr);
yeccpars2_359(S, 'INEQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 363, Ss, Stack, T, Ts, Tzr);
yeccpars2_359(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_359_(Stack),
 yeccgoto_indAudlocalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_360(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_360_(Stack),
 yeccgoto_indAudlocalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_361(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_361_(Stack),
 yeccgoto_indAudlocalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_362(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 365, Ss, Stack, T, Ts, Tzr);
yeccpars2_362(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 366, Ss, Stack, T, Ts, Tzr);
yeccpars2_362(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 367, Ss, Stack, T, Ts, Tzr);
yeccpars2_362(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 368, Ss, Stack, T, Ts, Tzr);
yeccpars2_362(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 369, Ss, Stack, T, Ts, Tzr);
yeccpars2_362(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_363: see yeccpars2_362

yeccpars2_364(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_364_(Stack),
 yeccgoto_indAudlocalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_365(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_365_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_366(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_366_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_367(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_367_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_368(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_368_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_369(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_369_(Stack),
 yeccgoto_streamModes(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_370(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_370_(Stack),
 yeccgoto_indAudlocalParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_371(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 375, Ss, Stack, T, Ts, Tzr);
yeccpars2_371(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_372: see yeccpars2_355

yeccpars2_373(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 372, Ss, Stack, T, Ts, Tzr);
yeccpars2_373(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_373_(Stack),
 yeccpars2_374(_S, Cat, [373 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_374_(Stack),
 yeccgoto_indAudlocalParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_375(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_375_(Stack),
 yeccgoto_indAudlocalControlDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_376(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 380, Ss, Stack, T, Ts, Tzr);
yeccpars2_376(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_377: see yeccpars2_321

yeccpars2_378(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 377, Ss, Stack, T, Ts, Tzr);
yeccpars2_378(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_378_(Stack),
 yeccpars2_379(_S, Cat, [378 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_379(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_379_(Stack),
 yeccgoto_indAudmediaParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_380(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_380_(Stack),
 yeccgoto_indAudmediaDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_381: see yeccpars2_4

%% yeccpars2_382: see yeccpars2_4

yeccpars2_383(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_indAudrequestedEvent(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_384(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 385, Ss, Stack, T, Ts, Tzr);
yeccpars2_384(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_385(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_385_(Stack),
 yeccgoto_indAudeventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_386(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 387, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_387: see yeccpars2_4

yeccpars2_388(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 389, Ss, Stack, T, Ts, Tzr);
yeccpars2_388(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_389(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_389_(Stack),
 yeccgoto_indAudeventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_390: see yeccpars2_4

yeccpars2_391(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 395, Ss, Stack, T, Ts, Tzr);
yeccpars2_391(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_391_(Stack),
 yeccpars2_394(_S, Cat, [391 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_392(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 393, Ss, Stack, T, Ts, Tzr);
yeccpars2_392(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_393(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_393_(Stack),
 yeccgoto_indAudeventBufferDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_394(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_394_(Stack),
 yeccgoto_indAudeventSpec(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_395(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 175, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_396_(Stack),
 yeccgoto_eventParameterName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_397(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 400, Ss, Stack, T, Ts, Tzr);
yeccpars2_397(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_398(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_398_(Stack),
 yeccgoto_indAudeventSpecParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_399(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_399_(Stack),
 yeccgoto_indAudeventSpecParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_400(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_400_(Stack),
 yeccgoto_optIndAudeventSpecParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_401_(Stack),
 yeccgoto_auditDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_402_(Stack),
 yeccgoto_auditDescriptorBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_403(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 211, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 212, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 213, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 214, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 215, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 216, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 217, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 218, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 219, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_403(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_404(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 403, Ss, Stack, T, Ts, Tzr);
yeccpars2_404(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_404_(Stack),
 yeccpars2_405(_S, Cat, [404 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_405(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_405_(Stack),
 yeccgoto_auditItemList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_406(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_406_(Stack),
 yeccgoto_indAudterminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_407(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 211, Ss, Stack, T, Ts, Tzr);
yeccpars2_407(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 409, Ss, Stack, T, Ts, Tzr);
yeccpars2_407(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 410, Ss, Stack, T, Ts, Tzr);
yeccpars2_407(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 411, Ss, Stack, T, Ts, Tzr);
yeccpars2_407(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 412, Ss, Stack, T, Ts, Tzr);
yeccpars2_407(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 413, Ss, Stack, T, Ts, Tzr);
yeccpars2_407(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 331, Ss, Stack, T, Ts, Tzr);
yeccpars2_407(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_408(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 407, Ss, Stack, T, Ts, Tzr);
yeccpars2_408(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_408_(Stack),
 yeccpars2_414(_S, Cat, [408 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_409(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 390, Ss, Stack, T, Ts, Tzr);
yeccpars2_409(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_410(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 381, Ss, Stack, T, Ts, Tzr);
yeccpars2_410(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 382, Ss, Stack, T, Ts, Tzr);
yeccpars2_410(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_411(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 321, Ss, Stack, T, Ts, Tzr);
yeccpars2_411(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_412(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 317, Ss, Stack, T, Ts, Tzr);
yeccpars2_412(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_413(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 227, Ss, Stack, T, Ts, Tzr);
yeccpars2_413(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_414(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_414_(Stack),
 yeccgoto_indAudterminationAuditList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_415(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_415_(Stack),
 yeccgoto_optAuditDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_416: see yeccpars2_184

yeccpars2_417(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 418, Ss, Stack, T, Ts, Tzr);
yeccpars2_417(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_418(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 420, Ss, Stack, T, Ts, Tzr);
yeccpars2_418(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_419(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 465, Ss, Stack, T, Ts, Tzr);
yeccpars2_419(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_420(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_420(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_421(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 435, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 211, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 212, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 213, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 214, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 215, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 436, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 437, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 216, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 217, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 218, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 219, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 438, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 439, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 440, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'ServiceChangeIncompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 441, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 442, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 443, Ss, Stack, T, Ts, Tzr);
yeccpars2_421(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_422(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_422_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_423(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_423_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_424(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_424_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_425(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_425_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_426(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 461, Ss, Stack, T, Ts, Tzr);
yeccpars2_426(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_426_(Stack),
 yeccpars2_460(460, Cat, [426 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_427(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_427_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_428(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_428_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_429(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_429_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_430(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_430_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_431(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_431_(Stack),
 yeccgoto_extensionParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_432: see yeccpars2_245

yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_433_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_434(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_434_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_435(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 457, Ss, Stack, T, Ts, Tzr);
yeccpars2_435(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_436(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 455, Ss, Stack, T, Ts, Tzr);
yeccpars2_436(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_437(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 453, Ss, Stack, T, Ts, Tzr);
yeccpars2_437(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_438(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 451, Ss, Stack, T, Ts, Tzr);
yeccpars2_438(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_439(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 449, Ss, Stack, T, Ts, Tzr);
yeccpars2_439(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_440(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 446, Ss, Stack, T, Ts, Tzr);
yeccpars2_440(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_441(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_441_(Stack),
 yeccgoto_serviceChangeParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_442(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_442_(Stack),
 yeccgoto_timeStamp(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_443(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 444, Ss, Stack, T, Ts, Tzr);
yeccpars2_443(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_444: see yeccpars2_4

yeccpars2_445(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_445_(Stack),
 yeccgoto_serviceChangeVersion(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_446(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 11, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'AuthToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'BothToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 13, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'BriefToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 14, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ContextAuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 15, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'DiscardToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'DisconnectedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'FailoverToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ForcedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'GracefulToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'H221Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'H223Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'H226Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'HandOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'InSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'InactiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'InterruptByEventToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'InterruptByNewSignalsDescrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'LoopbackToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'MessageSegmentToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'Nx64Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'OnOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'OtherReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'OutOfSvcToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'PendingToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'RecvonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ReplyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ResponseAckToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 57, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'RestartToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 58, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'SafeChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 59, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'SegmentationCompleteToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 60, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'SendonlyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 61, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'SendrecvToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 62, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 64, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 65, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'SynchISDNToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 69, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'TestToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'TimeOutToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 72, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'TransToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'V18Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'V22Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'V22bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 76, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'V32Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'V32bisToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'V34Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 79, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'V76Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'V90Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'V91Token', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 82, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_446(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_446_(Stack),
 yeccpars2_92(92, Cat, [446 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_447(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_447_(Stack),
 yeccgoto_serviceChangeAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_448(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_448_(Stack),
 yeccgoto_serviceChangeAddress(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_449: see yeccpars2_288

yeccpars2_450(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_450_(Stack),
 yeccgoto_serviceChangeReason(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_451: see yeccpars2_4

yeccpars2_452(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_452_(Stack),
 yeccgoto_serviceChangeProfile(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_453(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 96, Ss, Stack, T, Ts, Tzr);
yeccpars2_453(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 97, Ss, Stack, T, Ts, Tzr);
yeccpars2_453(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_453(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_453_(Stack),
 yeccpars2_92(92, Cat, [453 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_454(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_454_(Stack),
 yeccgoto_serviceChangeMgcId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_455: see yeccpars2_4

yeccpars2_456(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_456_(Stack),
 yeccgoto_serviceChangeMethod(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_457: see yeccpars2_4

yeccpars2_458(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_458_(Stack),
 yeccgoto_serviceChangeDelay(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_459(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_459_(Stack),
 yeccgoto_extension(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_460(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 464, Ss, Stack, T, Ts, Tzr);
yeccpars2_460(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_461: see yeccpars2_421

yeccpars2_462(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 461, Ss, Stack, T, Ts, Tzr);
yeccpars2_462(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_462_(Stack),
 yeccpars2_463(_S, Cat, [462 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_463(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_463_(Stack),
 yeccgoto_serviceChangeParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_464(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_464_(Stack),
 yeccgoto_serviceChangeDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_465(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_465_(Stack),
 yeccgoto_serviceChangeRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_466: see yeccpars2_4

yeccpars2_467(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_467_(Stack),
 yeccgoto_priority(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_468: see yeccpars2_184

yeccpars2_469(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 470, Ss, Stack, T, Ts, Tzr);
yeccpars2_469(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_470(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 121, Ss, Stack, T, Ts, Tzr);
yeccpars2_470(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 474, Ss, Stack, T, Ts, Tzr);
yeccpars2_470(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_471(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_471_(Stack),
 yeccgoto_notifyRequestBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_472(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 503, Ss, Stack, T, Ts, Tzr);
yeccpars2_472(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_473(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_473_(Stack),
 yeccgoto_notifyRequestBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_474(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 475, Ss, Stack, T, Ts, Tzr);
yeccpars2_474(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_475: see yeccpars2_4

yeccpars2_476(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 477, Ss, Stack, T, Ts, Tzr);
yeccpars2_476(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_477(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_477(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 442, Ss, Stack, T, Ts, Tzr);
yeccpars2_477(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_477_(Stack),
 yeccpars2_4(479, Cat, [477 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_478(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_478(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_478_(Stack),
 yeccpars2_498(498, Cat, [478 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_479: see yeccpars2_4

yeccpars2_480(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 482, Ss, Stack, T, Ts, Tzr);
yeccpars2_480(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_480_(Stack),
 yeccpars2_481(481, Cat, [480 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_481(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 485, Ss, Stack, T, Ts, Tzr);
yeccpars2_481(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_482(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_482(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 442, Ss, Stack, T, Ts, Tzr);
yeccpars2_482(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_482_(Stack),
 yeccpars2_4(479, Cat, [482 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_483(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 482, Ss, Stack, T, Ts, Tzr);
yeccpars2_483(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_483_(Stack),
 yeccpars2_484(_S, Cat, [483 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_484(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_484_(Stack),
 yeccgoto_observedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_485(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_485_(Stack),
 yeccgoto_observedEventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_486(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 488, Ss, Stack, T, Ts, Tzr);
yeccpars2_486(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_486_(Stack),
 yeccpars2_487(_S, Cat, [486 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_487(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_487_(Stack),
 yeccgoto_observedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_488: see yeccpars2_4

yeccpars2_489(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 494, Ss, Stack, T, Ts, Tzr);
yeccpars2_489(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_489_(Stack),
 yeccpars2_493(493, Cat, [489 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_490(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_observedEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_491: see yeccpars2_245

yeccpars2_492(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_492_(Stack),
 yeccgoto_eventStreamOrOther(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

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
 yeccgoto_observedEventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_497(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_497_(Stack),
 yeccgoto_observedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_498(S, 'COLON', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 499, Ss, Stack, T, Ts, Tzr);
yeccpars2_498(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_499(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_499(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_499_(Stack),
 yeccpars2_4(500, Cat, [499 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_500: see yeccpars2_4

yeccpars2_501(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 488, Ss, Stack, T, Ts, Tzr);
yeccpars2_501(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_501_(Stack),
 yeccpars2_502(_S, Cat, [501 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_502(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_502_(Stack),
 yeccgoto_observedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_503(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_503_(Stack),
 yeccgoto_notifyRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_504(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 506, Ss, Stack, T, Ts, Tzr);
yeccpars2_504(S, 'OnToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 507, Ss, Stack, T, Ts, Tzr);
yeccpars2_504(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_505(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_505_(Stack),
 yeccgoto_iepsValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_506(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_506_(Stack),
 yeccgoto_onOrOff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_507(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_507_(Stack),
 yeccgoto_onOrOff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_508(S, 'AndAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 518, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 519, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 520, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 521, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 522, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 523, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 524, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 525, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_508(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_509(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_509_(Stack),
 yeccgoto_contextAuditSelector(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_510(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_510_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_511(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 558, Ss, Stack, T, Ts, Tzr);
yeccpars2_511(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_512(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_512_(Stack),
 yeccgoto_contextAuditSelector(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_513(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_513_(Stack),
 yeccgoto_contextAuditSelector(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_514(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_515(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 545, Ss, Stack, T, Ts, Tzr);
yeccpars2_515(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_515_(Stack),
 yeccpars2_556(556, Cat, [515 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_516(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_contextAuditSelector(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_517(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_517_(Stack),
 yeccgoto_contextAuditSelector(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_518(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_518_(Stack),
 yeccgoto_auditSelectLogic(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_519(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 529, Ss, Stack, T, Ts, Tzr);
yeccpars2_519(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_520(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_520_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_521(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 526, Ss, Stack, T, Ts, Tzr);
yeccpars2_521(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_522(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 504, Ss, Stack, T, Ts, Tzr);
yeccpars2_522(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_522_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_523(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_523_(Stack),
 yeccgoto_auditSelectLogic(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_524(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 466, Ss, Stack, T, Ts, Tzr);
yeccpars2_524(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_524_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_525(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_525_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_526(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 527, Ss, Stack, T, Ts, Tzr);
yeccpars2_526(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 528, Ss, Stack, T, Ts, Tzr);
yeccpars2_526(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_527(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_527_(Stack),
 yeccgoto_emergencyValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_528(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_528_(Stack),
 yeccgoto_emergencyValue(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_529(S, 'AndAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 518, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 152, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 535, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 520, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 521, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 522, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 523, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 524, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 525, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_529(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_530(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 555, Ss, Stack, T, Ts, Tzr);
yeccpars2_530(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_531(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 551, Ss, Stack, T, Ts, Tzr);
yeccpars2_531(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_531_(Stack),
 yeccpars2_550(_S, Cat, [531 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_532(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 287, Ss, Stack, T, Ts, Tzr);
yeccpars2_532(S, 'GREATER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 288, Ss, Stack, T, Ts, Tzr);
yeccpars2_532(S, 'LESSER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 289, Ss, Stack, T, Ts, Tzr);
yeccpars2_532(S, 'NEQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 290, Ss, Stack, T, Ts, Tzr);
yeccpars2_532(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_532_(Stack),
 yeccgoto_contextAuditProperty(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_533(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 549, Ss, Stack, T, Ts, Tzr);
yeccpars2_533(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_534(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 545, Ss, Stack, T, Ts, Tzr);
yeccpars2_534(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_534_(Stack),
 yeccpars2_544(544, Cat, [534 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_535(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 536, Ss, Stack, T, Ts, Tzr);
yeccpars2_535(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_536(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 537, Ss, Stack, T, Ts, Tzr);
yeccpars2_536(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_537: see yeccpars2_4

yeccpars2_538(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 540, Ss, Stack, T, Ts, Tzr);
yeccpars2_538(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_538_(Stack),
 yeccpars2_539(539, Cat, [538 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_539(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 543, Ss, Stack, T, Ts, Tzr);
yeccpars2_539(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_540: see yeccpars2_4

yeccpars2_541(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 540, Ss, Stack, T, Ts, Tzr);
yeccpars2_541(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_541_(Stack),
 yeccpars2_542(_S, Cat, [541 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_542(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_542_(Stack),
 yeccgoto_contextIDs(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_543(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_543_(Stack),
 yeccgoto_contextIdList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_544(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 548, Ss, Stack, T, Ts, Tzr);
yeccpars2_544(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_545(S, 'AndAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 518, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 152, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 520, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'EmergencyValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 521, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 522, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'OrAUDITselectToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 523, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 524, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 525, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_545(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_546(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 545, Ss, Stack, T, Ts, Tzr);
yeccpars2_546(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_546_(Stack),
 yeccpars2_547(_S, Cat, [546 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_547(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_547_(Stack),
 yeccgoto_contextAuditProperties(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_548(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_548_(Stack),
 yeccgoto_indAudcontextAttrDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_549(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_549_(Stack),
 yeccgoto_contextAttrDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_550(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_550_(Stack),
 yeccgoto_propertyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_551: see yeccpars2_4

yeccpars2_552(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 551, Ss, Stack, T, Ts, Tzr);
yeccpars2_552(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_552_(Stack),
 yeccpars2_554(_S, Cat, [552 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_553: see yeccpars2_245

yeccpars2_554(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_554_(Stack),
 yeccgoto_propertyParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_555(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_555_(Stack),
 yeccgoto_contextAttrDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_556(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 557, Ss, Stack, T, Ts, Tzr);
yeccpars2_556(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_557(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_557_(Stack),
 yeccgoto_contextAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_558(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_558_(Stack),
 yeccgoto_contextAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_559(S, 'ContextListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 535, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_559(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_560: see yeccpars2_184

yeccpars2_561(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 195, Ss, Stack, T, Ts, Tzr);
yeccpars2_561(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_561_(Stack),
 yeccpars2_562(_S, Cat, [561 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_562(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_562_(Stack),
 yeccgoto_auditRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_563: see yeccpars2_184

yeccpars2_564(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 195, Ss, Stack, T, Ts, Tzr);
yeccpars2_564(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_564_(Stack),
 yeccpars2_565(_S, Cat, [564 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_565(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_565_(Stack),
 yeccgoto_auditRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_566(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_566_(Stack),
 yeccgoto_actionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_567(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_567_(Stack),
 yeccgoto_actionRequestBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_568: see yeccpars2_133

yeccpars2_569(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 568, Ss, Stack, T, Ts, Tzr);
yeccpars2_569(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_569_(Stack),
 yeccpars2_570(_S, Cat, [569 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_570(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_570_(Stack),
 yeccgoto_actionRequestItems(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_571: see yeccpars2_184

yeccpars2_572(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 574, Ss, Stack, T, Ts, Tzr);
yeccpars2_572(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_572_(Stack),
 yeccpars2_573(_S, Cat, [572 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_573(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_573_(Stack),
 yeccgoto_ammRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_574(S, 'AuditToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 197, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 585, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 586, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 587, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 588, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 589, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 590, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 591, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 592, Ss, Stack, T, Ts, Tzr);
yeccpars2_574(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_575(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_575_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_576(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_576_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_577(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_577_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_578(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_578_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_579_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_580(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_580_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_581(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_581_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_582(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_582_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_583(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_583_(Stack),
 yeccgoto_ammParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_584(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 794, Ss, Stack, T, Ts, Tzr);
yeccpars2_584(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_584_(Stack),
 yeccpars2_793(793, Cat, [584 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_585(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_585_(Stack),
 yeccgoto_digitMapDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_586(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 785, Ss, Stack, T, Ts, Tzr);
yeccpars2_586(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_586_(Stack),
 yeccgoto_eventBufferDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_587(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 711, Ss, Stack, T, Ts, Tzr);
yeccpars2_587(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_587_(Stack),
 yeccgoto_eventsDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_588(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 650, Ss, Stack, T, Ts, Tzr);
yeccpars2_588(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_589(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 634, Ss, Stack, T, Ts, Tzr);
yeccpars2_589(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 635, Ss, Stack, T, Ts, Tzr);
yeccpars2_589(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_590(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 626, Ss, Stack, T, Ts, Tzr);
yeccpars2_590(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_591(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 607, Ss, Stack, T, Ts, Tzr);
yeccpars2_591(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_591_(Stack),
 yeccgoto_signalsDescriptor(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_592(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 593, Ss, Stack, T, Ts, Tzr);
yeccpars2_592(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_593: see yeccpars2_4

yeccpars2_594(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 603, Ss, Stack, T, Ts, Tzr);
yeccpars2_594(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_594_(Stack),
 yeccpars2_602(602, Cat, [594 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_595(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 596, Ss, Stack, T, Ts, Tzr);
yeccpars2_595(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_595_(Stack),
 yeccgoto_statisticsParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_596(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 598, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 293, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_596(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_597(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_597_(Stack),
 yeccgoto_statisticsParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_598: see yeccpars2_288

yeccpars2_599(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 303, Ss, Stack, T, Ts, Tzr);
yeccpars2_599(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_599_(Stack),
 yeccpars2_600(600, Cat, [599 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_600(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 601, Ss, Stack, T, Ts, Tzr);
yeccpars2_600(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_601(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_601_(Stack),
 yeccgoto_statisticsParameter(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_602(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 606, Ss, Stack, T, Ts, Tzr);
yeccpars2_602(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_603: see yeccpars2_4

yeccpars2_604(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 603, Ss, Stack, T, Ts, Tzr);
yeccpars2_604(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_604_(Stack),
 yeccpars2_605(_S, Cat, [604 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_605(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_605_(Stack),
 yeccgoto_statisticsParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_606(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_606_(Stack),
 yeccgoto_statisticsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_607(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 611, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_607(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_608(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_608_(Stack),
 yeccgoto_signalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_609(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 622, Ss, Stack, T, Ts, Tzr);
yeccpars2_609(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_609_(Stack),
 yeccpars2_621(621, Cat, [609 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_610(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_610_(Stack),
 yeccgoto_signalParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_611(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 612, Ss, Stack, T, Ts, Tzr);
yeccpars2_611(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_612: see yeccpars2_4

yeccpars2_613(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 614, Ss, Stack, T, Ts, Tzr);
yeccpars2_613(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_614: see yeccpars2_4

yeccpars2_615(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 617, Ss, Stack, T, Ts, Tzr);
yeccpars2_615(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_615_(Stack),
 yeccpars2_616(616, Cat, [615 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_616(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 620, Ss, Stack, T, Ts, Tzr);
yeccpars2_616(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_617: see yeccpars2_4

yeccpars2_618(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 617, Ss, Stack, T, Ts, Tzr);
yeccpars2_618(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_618_(Stack),
 yeccpars2_619(_S, Cat, [618 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_619(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_619_(Stack),
 yeccgoto_signalListParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_620(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_620_(Stack),
 yeccgoto_signalList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_621(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 625, Ss, Stack, T, Ts, Tzr);
yeccpars2_621(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_622: see yeccpars2_607

yeccpars2_623(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 622, Ss, Stack, T, Ts, Tzr);
yeccpars2_623(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_623_(Stack),
 yeccpars2_624(_S, Cat, [623 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_624(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_624_(Stack),
 yeccgoto_signalParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_625(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_625_(Stack),
 yeccgoto_signalsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_626: see yeccpars2_4

yeccpars2_627(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_627_(Stack),
 yeccgoto_muxType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_628(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 630, Ss, Stack, T, Ts, Tzr);
yeccpars2_628(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_629(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_629_(Stack),
 yeccgoto_muxDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_630: see yeccpars2_4

yeccpars2_631(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 190, Ss, Stack, T, Ts, Tzr);
yeccpars2_631(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_631_(Stack),
 yeccpars2_632(632, Cat, [631 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_632(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 633, Ss, Stack, T, Ts, Tzr);
yeccpars2_632(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_633(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_633_(Stack),
 yeccgoto_terminationIDList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_634: see yeccpars2_4

%% yeccpars2_635: see yeccpars2_4

yeccpars2_636(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_636_(Stack),
 yeccgoto_modemType(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_637(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 639, Ss, Stack, T, Ts, Tzr);
yeccpars2_637(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_637_(Stack),
 yeccpars2_638(638, Cat, [637 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_638(S, 'RSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 642, Ss, Stack, T, Ts, Tzr);
yeccpars2_638(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_639: see yeccpars2_4

yeccpars2_640(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 639, Ss, Stack, T, Ts, Tzr);
yeccpars2_640(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_640_(Stack),
 yeccpars2_641(_S, Cat, [640 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_641(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_641_(Stack),
 yeccgoto_modemTypeList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_642(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 644, Ss, Stack, T, Ts, Tzr);
yeccpars2_642(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_642_(Stack),
 yeccpars2_643(_S, Cat, [642 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_643(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_643_(Stack),
 yeccgoto_modemDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_644: see yeccpars2_4

yeccpars2_645(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 551, Ss, Stack, T, Ts, Tzr);
yeccpars2_645(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_645_(Stack),
 yeccpars2_646(646, Cat, [645 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_646(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 647, Ss, Stack, T, Ts, Tzr);
yeccpars2_646(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_647(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_647_(Stack),
 yeccgoto_optPropertyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_648(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 644, Ss, Stack, T, Ts, Tzr);
yeccpars2_648(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_648_(Stack),
 yeccpars2_649(_S, Cat, [648 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_649(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_649_(Stack),
 yeccgoto_modemDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_650(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 592, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 660, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, 'TerminationStateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 661, Ss, Stack, T, Ts, Tzr);
yeccpars2_650(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_650(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_650(S, 'LocalControlToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 657, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_650(S, 'LocalDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 658, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_650(S, 'RemoteDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 659, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_650(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_651(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_651_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_652(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_652_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_653_(Stack),
 yeccgoto_mediaParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_654_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_655(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 707, Ss, Stack, T, Ts, Tzr);
yeccpars2_655(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_655_(Stack),
 yeccpars2_706(706, Cat, [655 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_656_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_657(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 689, Ss, Stack, T, Ts, Tzr);
yeccpars2_657(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_658(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_658_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_659(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_659_(Stack),
 yeccgoto_streamParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_660(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 680, Ss, Stack, T, Ts, Tzr);
yeccpars2_660(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_661(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 662, Ss, Stack, T, Ts, Tzr);
yeccpars2_661(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_662(S, 'BufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 667, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'ServiceStatesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 668, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_662(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_663(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 676, Ss, Stack, T, Ts, Tzr);
yeccpars2_663(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_663_(Stack),
 yeccpars2_675(675, Cat, [663 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_664(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_664_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_665(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_665_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_666(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_666_(Stack),
 yeccgoto_terminationStateParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_667(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 671, Ss, Stack, T, Ts, Tzr);
yeccpars2_667(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_668(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 669, Ss, Stack, T, Ts, Tzr);
yeccpars2_668(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_669: see yeccpars2_341

yeccpars2_670(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_670_(Stack),
 yeccgoto_serviceStates(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_671(S, 'LockStepToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 673, Ss, Stack, T, Ts, Tzr);
yeccpars2_671(S, 'OffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 674, Ss, Stack, T, Ts, Tzr);
yeccpars2_671(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_672(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_672_(Stack),
 yeccgoto_eventBufferControl(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_673(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_673_(Stack),
 yeccgoto_eventBufferControlValue(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_674(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_674_(Stack),
 yeccgoto_eventBufferControlValue(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_675(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 679, Ss, Stack, T, Ts, Tzr);
yeccpars2_675(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_676: see yeccpars2_662

yeccpars2_677(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 676, Ss, Stack, T, Ts, Tzr);
yeccpars2_677(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_677_(Stack),
 yeccpars2_678(_S, Cat, [677 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_678(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_678_(Stack),
 yeccgoto_terminationStateParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_679(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_679_(Stack),
 yeccgoto_terminationStateDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_680: see yeccpars2_4

yeccpars2_681(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 682, Ss, Stack, T, Ts, Tzr);
yeccpars2_681(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_682(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 592, Ss, Stack, T, Ts, Tzr);
yeccpars2_682(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_650(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_683(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 685, Ss, Stack, T, Ts, Tzr);
yeccpars2_683(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_683_(Stack),
 yeccpars2_684(684, Cat, [683 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_684(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 688, Ss, Stack, T, Ts, Tzr);
yeccpars2_684(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_685: see yeccpars2_682

yeccpars2_686(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 685, Ss, Stack, T, Ts, Tzr);
yeccpars2_686(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_686_(Stack),
 yeccpars2_687(_S, Cat, [686 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_687(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_687_(Stack),
 yeccgoto_streamParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_688(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_688_(Stack),
 yeccgoto_streamDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_689(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'ModeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 692, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'ReservedGroupToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 693, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'ReservedValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 694, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_689(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_690(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_690_(Stack),
 yeccgoto_localParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_691(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 702, Ss, Stack, T, Ts, Tzr);
yeccpars2_691(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_691_(Stack),
 yeccpars2_701(701, Cat, [691 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_692(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 699, Ss, Stack, T, Ts, Tzr);
yeccpars2_692(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_693(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 697, Ss, Stack, T, Ts, Tzr);
yeccpars2_693(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_694(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 695, Ss, Stack, T, Ts, Tzr);
yeccpars2_694(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_695: see yeccpars2_504

yeccpars2_696(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_696_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_697: see yeccpars2_504

yeccpars2_698(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_698_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_699: see yeccpars2_362

yeccpars2_700(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_700_(Stack),
 yeccgoto_localParm(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_701(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 705, Ss, Stack, T, Ts, Tzr);
yeccpars2_701(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_702: see yeccpars2_689

yeccpars2_703(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 702, Ss, Stack, T, Ts, Tzr);
yeccpars2_703(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_703_(Stack),
 yeccpars2_704(_S, Cat, [703 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_704(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_704_(Stack),
 yeccgoto_localParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_705(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_705_(Stack),
 yeccgoto_localControlDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_706(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 710, Ss, Stack, T, Ts, Tzr);
yeccpars2_706(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_707: see yeccpars2_650

yeccpars2_708(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 707, Ss, Stack, T, Ts, Tzr);
yeccpars2_708(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_708_(Stack),
 yeccpars2_709(_S, Cat, [708 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_709(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_709_(Stack),
 yeccgoto_mediaParmList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_710(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_710_(Stack),
 yeccgoto_mediaDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_711: see yeccpars2_4

yeccpars2_712(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 713, Ss, Stack, T, Ts, Tzr);
yeccpars2_712(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_713: see yeccpars2_4

yeccpars2_714(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 781, Ss, Stack, T, Ts, Tzr);
yeccpars2_714(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_714_(Stack),
 yeccpars2_780(780, Cat, [714 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_715(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 717, Ss, Stack, T, Ts, Tzr);
yeccpars2_715(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_715_(Stack),
 yeccpars2_716(_S, Cat, [715 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_716(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_716_(Stack),
 yeccgoto_requestedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_717(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 725, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 726, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 727, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 728, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 729, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 730, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 731, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_717(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_718(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_718_(Stack),
 yeccgoto_notifyBehaviour(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_719(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_719_(Stack),
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_720(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_721(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 776, Ss, Stack, T, Ts, Tzr);
yeccpars2_721(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_721_(Stack),
 yeccpars2_775(775, Cat, [721 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_722(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_723(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_724(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_725(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_725_(Stack),
 yeccgoto_eventDM(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_726(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 736, Ss, Stack, T, Ts, Tzr);
yeccpars2_726(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_727(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_727_COMMA(Stack),
 yeccgoto_eventParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_727(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_727_RBRKT(Stack),
 yeccgoto_eventParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_727(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_728(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_728_(Stack),
 yeccgoto_notifyBehaviour(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_729(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_729_(Stack),
 yeccgoto_notifyBehaviour(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_730(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 732, Ss, Stack, T, Ts, Tzr);
yeccpars2_730(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_730_(Stack),
 yeccgoto_notifyRegulated(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_731(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_731_(Stack),
 yeccgoto_eventParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_732(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 735, Ss, Stack, T, Ts, Tzr);
yeccpars2_732(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_733(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 774, Ss, Stack, T, Ts, Tzr);
yeccpars2_733(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_734(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 773, Ss, Stack, T, Ts, Tzr);
yeccpars2_734(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_735(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 736, Ss, Stack, T, Ts, Tzr);
yeccpars2_735(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_736(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 739, Ss, Stack, T, Ts, Tzr);
yeccpars2_736(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 591, Ss, Stack, T, Ts, Tzr);
yeccpars2_736(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_737(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 769, Ss, Stack, T, Ts, Tzr);
yeccpars2_737(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 770, Ss, Stack, T, Ts, Tzr);
yeccpars2_737(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_738(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 768, Ss, Stack, T, Ts, Tzr);
yeccpars2_738(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_739(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 740, Ss, Stack, T, Ts, Tzr);
yeccpars2_739(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_739_(Stack),
 yeccgoto_embedFirst(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_740: see yeccpars2_4

yeccpars2_741(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 742, Ss, Stack, T, Ts, Tzr);
yeccpars2_741(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_742: see yeccpars2_4

yeccpars2_743(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 764, Ss, Stack, T, Ts, Tzr);
yeccpars2_743(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_743_(Stack),
 yeccpars2_763(763, Cat, [743 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_744(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 746, Ss, Stack, T, Ts, Tzr);
yeccpars2_744(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_744_(Stack),
 yeccpars2_745(_S, Cat, [744 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_745(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_745_(Stack),
 yeccgoto_secondRequestedEvent(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_746(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 725, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 752, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 753, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'NeverNotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 728, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'NotifyImmediateToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 729, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'NotifyRegulatedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 730, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'ResetEventsDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 754, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_746(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_747(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 759, Ss, Stack, T, Ts, Tzr);
yeccpars2_747(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_747_(Stack),
 yeccpars2_758(758, Cat, [747 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_748_(Stack),
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_749(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_750(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_751(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_752(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 755, Ss, Stack, T, Ts, Tzr);
yeccpars2_752(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_753(_S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_753_COMMA(Stack),
 yeccgoto_secondEventParameter(hd(Ss), 'COMMA', Ss, NewStack, T, Ts, Tzr);
yeccpars2_753(_S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_753_RBRKT(Stack),
 yeccgoto_secondEventParameter(hd(Ss), 'RBRKT', Ss, NewStack, T, Ts, Tzr);
yeccpars2_753(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_754(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_754_(Stack),
 yeccgoto_secondEventParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_755(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 591, Ss, Stack, T, Ts, Tzr);
yeccpars2_755(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_756(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 757, Ss, Stack, T, Ts, Tzr);
yeccpars2_756(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_757(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_757_(Stack),
 yeccgoto_embedSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_758(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 762, Ss, Stack, T, Ts, Tzr);
yeccpars2_758(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_759: see yeccpars2_746

yeccpars2_760(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 759, Ss, Stack, T, Ts, Tzr);
yeccpars2_760(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_760_(Stack),
 yeccpars2_761(_S, Cat, [760 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_761(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_761_(Stack),
 yeccgoto_secondEventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_762(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_762_(Stack),
 yeccgoto_secondRequestedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_763(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 767, Ss, Stack, T, Ts, Tzr);
yeccpars2_763(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_764: see yeccpars2_4

yeccpars2_765(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 764, Ss, Stack, T, Ts, Tzr);
yeccpars2_765(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_765_(Stack),
 yeccpars2_766(_S, Cat, [765 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_766(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_766_(Stack),
 yeccgoto_secondRequestedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_767(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_767_(Stack),
 yeccgoto_embedFirst(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_768(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_768_(Stack),
 yeccgoto_embedNoSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_769(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 739, Ss, Stack, T, Ts, Tzr);
yeccpars2_769(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_770(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_770_(Stack),
 yeccgoto_embedWithSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_771(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 772, Ss, Stack, T, Ts, Tzr);
yeccpars2_771(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_772(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_772_(Stack),
 yeccgoto_embedWithSig(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_773(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_773_(Stack),
 yeccgoto_notifyRegulated(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_774(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_774_(Stack),
 yeccgoto_notifyRegulated(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_775(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 779, Ss, Stack, T, Ts, Tzr);
yeccpars2_775(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_776: see yeccpars2_717

yeccpars2_777(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 776, Ss, Stack, T, Ts, Tzr);
yeccpars2_777(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_777_(Stack),
 yeccpars2_778(_S, Cat, [777 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_778(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_778_(Stack),
 yeccgoto_eventParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_779(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_779_(Stack),
 yeccgoto_requestedEventBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_780(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 784, Ss, Stack, T, Ts, Tzr);
yeccpars2_780(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_781: see yeccpars2_4

yeccpars2_782(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 781, Ss, Stack, T, Ts, Tzr);
yeccpars2_782(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_782_(Stack),
 yeccpars2_783(_S, Cat, [782 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_783(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_783_(Stack),
 yeccgoto_requestedEvents(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_784(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_784_(Stack),
 yeccgoto_eventsDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_785(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_785(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 442, Ss, Stack, T, Ts, Tzr);
yeccpars2_785(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_785_(Stack),
 yeccpars2_4(479, Cat, [785 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_786(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_786_(Stack),
 yeccgoto_eventSpec(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_787(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 789, Ss, Stack, T, Ts, Tzr);
yeccpars2_787(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_787_(Stack),
 yeccpars2_788(788, Cat, [787 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_788(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 792, Ss, Stack, T, Ts, Tzr);
yeccpars2_788(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_789(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_789(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 442, Ss, Stack, T, Ts, Tzr);
yeccpars2_789(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_789_(Stack),
 yeccpars2_4(479, Cat, [789 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_790(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 789, Ss, Stack, T, Ts, Tzr);
yeccpars2_790(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_790_(Stack),
 yeccpars2_791(_S, Cat, [790 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_791(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_791_(Stack),
 yeccgoto_eventSpecList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_792(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_792_(Stack),
 yeccgoto_eventBufferDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_793(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 797, Ss, Stack, T, Ts, Tzr);
yeccpars2_793(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_794: see yeccpars2_574

yeccpars2_795(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 794, Ss, Stack, T, Ts, Tzr);
yeccpars2_795(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_795_(Stack),
 yeccpars2_796(_S, Cat, [795 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_796(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_796_(Stack),
 yeccgoto_ammParameters(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_797(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_797_(Stack),
 yeccgoto_ammRequestBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_798(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 802, Ss, Stack, T, Ts, Tzr);
yeccpars2_798(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_799: see yeccpars2_127

yeccpars2_800(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 799, Ss, Stack, T, Ts, Tzr);
yeccpars2_800(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_800_(Stack),
 yeccpars2_801(_S, Cat, [800 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_801(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_801_(Stack),
 yeccgoto_actionRequestList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_802(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_802_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_803(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 809, Ss, Stack, T, Ts, Tzr);
yeccpars2_803(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_804(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_804_(Stack),
 yeccgoto_transactionID(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_805: see yeccpars2_127

yeccpars2_806(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 799, Ss, Stack, T, Ts, Tzr);
yeccpars2_806(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_806_(Stack),
 yeccpars2_807(807, Cat, [806 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_807(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 808, Ss, Stack, T, Ts, Tzr);
yeccpars2_807(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_808(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_808_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_809: see yeccpars2_127

yeccpars2_810(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 799, Ss, Stack, T, Ts, Tzr);
yeccpars2_810(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_810_(Stack),
 yeccpars2_811(811, Cat, [810 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_811(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 812, Ss, Stack, T, Ts, Tzr);
yeccpars2_811(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_812(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_812_(Stack),
 yeccgoto_transactionRequest(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_813: see yeccpars2_4

yeccpars2_814(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 817, Ss, Stack, T, Ts, Tzr);
yeccpars2_814(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_814_(Stack),
 yeccpars2_816(816, Cat, [814 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_815(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_815_(Stack),
 yeccgoto_transactionAck(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_816(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 820, Ss, Stack, T, Ts, Tzr);
yeccpars2_816(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_817: see yeccpars2_4

yeccpars2_818(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 817, Ss, Stack, T, Ts, Tzr);
yeccpars2_818(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_818_(Stack),
 yeccpars2_819(_S, Cat, [818 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_819(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_819_(Stack),
 yeccgoto_transactionAckList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_820(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_820_(Stack),
 yeccgoto_transactionResponseAck(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_821: see yeccpars2_4

yeccpars2_822(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 823, Ss, Stack, T, Ts, Tzr);
yeccpars2_822(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_823(S, 'ImmAckRequiredToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 825, Ss, Stack, T, Ts, Tzr);
yeccpars2_823(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_823_(Stack),
 yeccpars2_824(824, Cat, [823 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_824(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 830, Ss, Stack, T, Ts, Tzr);
yeccpars2_824(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 121, Ss, Stack, T, Ts, Tzr);
yeccpars2_824(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_825(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 826, Ss, Stack, T, Ts, Tzr);
yeccpars2_825(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_826(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_826_(Stack),
 yeccgoto_optImmAckRequired(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_827(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 952, Ss, Stack, T, Ts, Tzr);
yeccpars2_827(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_828(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_828_(Stack),
 yeccgoto_transactionReplyBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_829(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 949, Ss, Stack, T, Ts, Tzr);
yeccpars2_829(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_829_(Stack),
 yeccpars2_948(_S, Cat, [829 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_830(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 831, Ss, Stack, T, Ts, Tzr);
yeccpars2_830(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_831: see yeccpars2_4

yeccpars2_832(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 833, Ss, Stack, T, Ts, Tzr);
yeccpars2_832(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_832_(Stack),
 yeccgoto_actionReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_833(S, 'AddToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 843, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'AuditCapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 844, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'AuditValueToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 845, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'ContextAttrToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 152, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'EmergencyOffToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 154, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'EmergencyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 121, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'IEPSToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 156, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'ModifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 846, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'MoveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 847, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'NotifyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 848, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'PriorityToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 160, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'ServiceChangeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 849, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'SubtractToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 850, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(S, 'TopologyToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 163, Ss, Stack, T, Ts, Tzr);
yeccpars2_833(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_834(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_834_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_835(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_835_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_836(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_836_(Stack),
 yeccgoto_actionReplyBody(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_837(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_837_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_838(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 944, Ss, Stack, T, Ts, Tzr);
yeccpars2_838(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_838_(Stack),
 yeccpars2_943(_S, Cat, [838 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_839(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_839_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_840(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 937, Ss, Stack, T, Ts, Tzr);
yeccpars2_840(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_841(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_841_(Stack),
 yeccgoto_commandReplys(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_842(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 936, Ss, Stack, T, Ts, Tzr);
yeccpars2_842(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_843(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_843_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_844(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 932, Ss, Stack, T, Ts, Tzr);
yeccpars2_844(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_845(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 882, Ss, Stack, T, Ts, Tzr);
yeccpars2_845(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_846(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_846_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_847(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_847_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_848(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 876, Ss, Stack, T, Ts, Tzr);
yeccpars2_848(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_849(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 851, Ss, Stack, T, Ts, Tzr);
yeccpars2_849(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_850(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_850_(Stack),
 yeccgoto_ammsToken(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_851: see yeccpars2_184

yeccpars2_852(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 854, Ss, Stack, T, Ts, Tzr);
yeccpars2_852(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_852_(Stack),
 yeccpars2_853(_S, Cat, [852 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_853(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_853_(Stack),
 yeccgoto_serviceChangeReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_854(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 121, Ss, Stack, T, Ts, Tzr);
yeccpars2_854(S, 'ServicesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 857, Ss, Stack, T, Ts, Tzr);
yeccpars2_854(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_855(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 875, Ss, Stack, T, Ts, Tzr);
yeccpars2_855(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_856(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 874, Ss, Stack, T, Ts, Tzr);
yeccpars2_856(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_857(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 858, Ss, Stack, T, Ts, Tzr);
yeccpars2_857(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_858(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 865, Ss, Stack, T, Ts, Tzr);
yeccpars2_858(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 866, Ss, Stack, T, Ts, Tzr);
yeccpars2_858(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 867, Ss, Stack, T, Ts, Tzr);
yeccpars2_858(S, 'TimeStampToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 442, Ss, Stack, T, Ts, Tzr);
yeccpars2_858(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 868, Ss, Stack, T, Ts, Tzr);
yeccpars2_858(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_859_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_860(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_860_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_861(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_861_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_862_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_863(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_863_(Stack),
 yeccgoto_servChgReplyParm(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_864(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 870, Ss, Stack, T, Ts, Tzr);
yeccpars2_864(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_864_(Stack),
 yeccpars2_869(869, Cat, [864 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_865(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 453, Ss, Stack, T, Ts, Tzr);
yeccpars2_865(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_866(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 451, Ss, Stack, T, Ts, Tzr);
yeccpars2_866(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_867(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 446, Ss, Stack, T, Ts, Tzr);
yeccpars2_867(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_868(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 444, Ss, Stack, T, Ts, Tzr);
yeccpars2_868(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_869(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 873, Ss, Stack, T, Ts, Tzr);
yeccpars2_869(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_870: see yeccpars2_858

yeccpars2_871(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 870, Ss, Stack, T, Ts, Tzr);
yeccpars2_871(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_871_(Stack),
 yeccpars2_872(_S, Cat, [871 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_872(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_872_(Stack),
 yeccgoto_servChgReplyParms(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_873(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_873_(Stack),
 yeccgoto_serviceChangeReplyDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_874(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_874_(Stack),
 yeccgoto_serviceChangeReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_875(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_875_(Stack),
 yeccgoto_serviceChangeReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_876: see yeccpars2_184

yeccpars2_877(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 879, Ss, Stack, T, Ts, Tzr);
yeccpars2_877(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_877_(Stack),
 yeccpars2_878(_S, Cat, [877 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_878(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_878_(Stack),
 yeccgoto_notifyReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_879(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 121, Ss, Stack, T, Ts, Tzr);
yeccpars2_879(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_880(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 881, Ss, Stack, T, Ts, Tzr);
yeccpars2_880(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_881(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_881_(Stack),
 yeccgoto_notifyReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_882(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 885, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 187, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_882(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_883(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 899, Ss, Stack, T, Ts, Tzr);
yeccpars2_883(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_883_(Stack),
 yeccgoto_auditOther(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_884(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_884_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_885(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 888, Ss, Stack, T, Ts, Tzr);
yeccpars2_885(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_886(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_886_(Stack),
 yeccgoto_contextTerminationAudit(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_887(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_887_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_888(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 16, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 890, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_888(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_889(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 898, Ss, Stack, T, Ts, Tzr);
yeccpars2_889(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_890(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 891, Ss, Stack, T, Ts, Tzr);
yeccpars2_890(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_891: see yeccpars2_4

yeccpars2_892(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_892_(Stack),
 yeccgoto_errorCode(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_893(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 894, Ss, Stack, T, Ts, Tzr);
yeccpars2_893(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_894(S, 'QuotedChars', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 896, Ss, Stack, T, Ts, Tzr);
yeccpars2_894(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_894_(Stack),
 yeccpars2_895(895, Cat, [894 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_895(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 897, Ss, Stack, T, Ts, Tzr);
yeccpars2_895(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_896(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_896_(Stack),
 yeccgoto_errorText(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_897(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_897_(Stack),
 yeccgoto_errorDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_898(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_898_(Stack),
 yeccgoto_contextTerminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_899(S, 'DigitMapDescriptorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 585, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'DigitMapToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 212, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 121, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'EventBufferToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 586, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'EventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 587, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'MediaToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 914, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'ModemToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 915, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'MuxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 916, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'ObservedEventsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 917, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'PackagesToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 918, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'SignalsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 591, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(S, 'StatsToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 919, Ss, Stack, T, Ts, Tzr);
yeccpars2_899(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_900(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 931, Ss, Stack, T, Ts, Tzr);
yeccpars2_900(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_901(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_901_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_902(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_902_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_903(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_903_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_904(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_904_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_905(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_905_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_906(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_906_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_907(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_907_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_908(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_908_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_909(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_909_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_910(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_910_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_911(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_911_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_912(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 928, Ss, Stack, T, Ts, Tzr);
yeccpars2_912(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_912_(Stack),
 yeccpars2_927(_S, Cat, [912 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_913(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_913_(Stack),
 yeccgoto_auditReturnParameter(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_914(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 650, Ss, Stack, T, Ts, Tzr);
yeccpars2_914(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_914_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_915(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 634, Ss, Stack, T, Ts, Tzr);
yeccpars2_915(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 635, Ss, Stack, T, Ts, Tzr);
yeccpars2_915(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_915_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_916(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 626, Ss, Stack, T, Ts, Tzr);
yeccpars2_916(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_916_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_917(S, 'EQUAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 475, Ss, Stack, T, Ts, Tzr);
yeccpars2_917(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_917_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_918(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 920, Ss, Stack, T, Ts, Tzr);
yeccpars2_918(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_918_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_919(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 593, Ss, Stack, T, Ts, Tzr);
yeccpars2_919(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_919_(Stack),
 yeccgoto_auditReturnItem(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_920: see yeccpars2_4

yeccpars2_921(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 923, Ss, Stack, T, Ts, Tzr);
yeccpars2_921(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_921_(Stack),
 yeccpars2_922(922, Cat, [921 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_922(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 926, Ss, Stack, T, Ts, Tzr);
yeccpars2_922(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_923: see yeccpars2_4

yeccpars2_924(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 923, Ss, Stack, T, Ts, Tzr);
yeccpars2_924(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_924_(Stack),
 yeccpars2_925(_S, Cat, [924 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_925(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_925_(Stack),
 yeccgoto_packagesItems(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_926(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_926_(Stack),
 yeccgoto_packagesDescriptor(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_927(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_927_(Stack),
 yeccgoto_terminationAudit(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_928: see yeccpars2_899

yeccpars2_929(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 928, Ss, Stack, T, Ts, Tzr);
yeccpars2_929(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_929_(Stack),
 yeccpars2_930(_S, Cat, [929 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_930(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_930_(Stack),
 yeccgoto_auditReturnParameterList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_931(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_931_(Stack),
 yeccgoto_auditOther(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_932(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 934, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'DelayToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'DirectionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'DurationToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'EmbedToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'ErrorToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'KeepActiveToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'LSBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 187, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'MethodToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'MgcIdToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'NotifyCompletionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'ProfileToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'ReasonToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 53, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'RequestIDToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'ServiceChangeAddressToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 63, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'SignalListToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 66, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'SignalTypeToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 67, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'StreamToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 68, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, 'VersionToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_932(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_4(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_933(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_933_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_934(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 888, Ss, Stack, T, Ts, Tzr);
yeccpars2_934(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_safeToken2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_935(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_935_(Stack),
 yeccgoto_auditReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_936(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_936_(Stack),
 yeccgoto_actionReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_937: see yeccpars2_184

yeccpars2_938(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 940, Ss, Stack, T, Ts, Tzr);
yeccpars2_938(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_938_(Stack),
 yeccpars2_939(_S, Cat, [938 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_939(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_939_(Stack),
 yeccgoto_ammsReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_940: see yeccpars2_899

yeccpars2_941(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 942, Ss, Stack, T, Ts, Tzr);
yeccpars2_941(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_942(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_942_(Stack),
 yeccgoto_ammsReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_943(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_943_(Stack),
 yeccgoto_actionReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_944: see yeccpars2_833

yeccpars2_945(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_945_(Stack),
 yeccgoto_commandReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_946(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 944, Ss, Stack, T, Ts, Tzr);
yeccpars2_946(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_946_(Stack),
 yeccpars2_947(_S, Cat, [946 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_947(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_947_(Stack),
 yeccgoto_commandReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_948(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_948_(Stack),
 yeccgoto_transactionReplyBody(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_949(S, 'CtxToken', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 830, Ss, Stack, T, Ts, Tzr);
yeccpars2_949(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_950(S, 'COMMA', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 949, Ss, Stack, T, Ts, Tzr);
yeccpars2_950(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_950_(Stack),
 yeccpars2_951(_S, Cat, [950 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_951(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_951_(Stack),
 yeccgoto_actionReplyList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_952(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_952_(Stack),
 yeccgoto_transactionReply(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_953: see yeccpars2_4

yeccpars2_954(S, 'LBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 955, Ss, Stack, T, Ts, Tzr);
yeccpars2_954(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_955(S, 'RBRKT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 956, Ss, Stack, T, Ts, Tzr);
yeccpars2_955(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_956(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_956_(Stack),
 yeccgoto_transactionPending(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_957(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_957_(Stack),
 yeccgoto_transactionList(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_958(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_958_(Stack),
 yeccgoto_pathName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_959(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_959_(Stack),
 yeccgoto_deviceName(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_960(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_960(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_960_(Stack),
 yeccpars2_964(_S, Cat, [960 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_961(S, 'SEP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_961(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_961_(Stack),
 yeccpars2_963(_S, Cat, [961 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_962(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_962_(Stack),
 yeccgoto_mtpAddress(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_963(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_963_(Stack),
 yeccgoto_mId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_964(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_964_(Stack),
 yeccgoto_mId(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccgoto_actionReply(824, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_829(829, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionReply(949, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_950(950, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionReplyBody(833, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_842(842, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionReplyList(829=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_948(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionReplyList(950=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_951(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequest(127, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_128(128, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(799, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_800(800, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(805, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_806(806, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequest(809, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_810(810, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestBody(133, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_148(148, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestItem(133, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_147(147, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestItem(568, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_569(569, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestItems(147=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_567(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestItems(569=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_570(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_actionRequestList(128, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_798(798, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(800=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_801(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(806, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_807(807, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_actionRequestList(810, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_811(811, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_alternativeValue(287=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_297(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammParameter(574, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_584(584, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammParameter(794, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_795(795, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammParameters(584, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_793(793, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammParameters(795=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_796(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammRequest(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammRequest(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_146(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammRequestBody(572=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_573(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammToken(133, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_145(145, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammToken(568, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_145(145, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsReply(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_841(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammsReply(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_841(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsReplyBody(938=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_939(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ammsToken(833, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_840(840, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ammsToken(944, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_840(840, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditDescriptor(195, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_196(196, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_583(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditDescriptor(794=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_583(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditDescriptorBody(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(210, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditItem(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_209(209, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(403, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_404(404, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_434(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItem(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_434(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditItemList(209=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditItemList(404=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_405(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditOther(882=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_884(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditOther(932=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_933(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReply(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_839(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReply(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_839(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditRequest(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_144(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditRequest(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_144(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnItem(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(403=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_913(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_913(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnItem(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_913(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnParameter(899, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_912(912, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameter(928, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_929(929, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameter(940, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_912(912, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditReturnParameterList(912=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_927(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditReturnParameterList(929=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_930(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_auditSelectLogic(508=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_517(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditSelectLogic(529=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_517(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_auditSelectLogic(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_517(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_authenticationHeader(1, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(4, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandReplyList(838=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_943(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandReplyList(946=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_947(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandReplys(833, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_838(838, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandReplys(944, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_946(946, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_commandRequest(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_143(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_commandRequest(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_143(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAttrDescriptor(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(508=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_516(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(529=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_516(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_516(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAttrDescriptor(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_142(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAudit(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_141(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAudit(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_141(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAuditProperties(515, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_556(556, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperties(534, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_544(544, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperties(546=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_547(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAuditProperty(508, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_515(515, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperty(529, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_534(534, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditProperty(545, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_546(546, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextAuditSelector(508=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_514(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditSelector(529=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_514(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextAuditSelector(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_514(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextID(130, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(132, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextID(537, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_538(538, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextID(540, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_541(541, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextID(831, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_832(832, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextIDs(538, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_539(539, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextIDs(541=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_542(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextIdList(529, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_533(533, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextIdList(559, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_533(533, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextProperty(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_837(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextProperty(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_837(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contextTerminationAudit(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_887(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_contextTerminationAudit(934=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_935(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_daddr(97, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(99, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_daddr(98=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_107(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_daddr(100=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_101(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_deviceName(92, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_961(961, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_digitMapDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_582(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(794=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_582(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_911(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_911(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_digitMapDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_911(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_direction(281=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_282(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_domainAddress(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainAddress(446=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainAddress(453=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_domainName(89=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainName(446=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_domainName(453=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedFirst(736, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_738(738, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedFirst(769, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_771(771, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedNoSig(717=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_724(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedNoSig(732, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_734(734, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedNoSig(776=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_724(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedSig(746=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_751(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedSig(759=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_751(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_embedWithSig(717=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_723(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedWithSig(732, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_733(733, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_embedWithSig(776=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_723(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_emergencyValue(508=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_513(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_emergencyValue(529=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_513(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_emergencyValue(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_513(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorCode(891, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_893(893, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorDescriptor(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(470=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_473(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(824=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_828(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_836(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(854, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_856(856, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(879, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_880(880, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(888, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_889(889, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_910(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_910(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_910(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_errorDescriptor(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_945(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_errorText(894, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_895(895, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferControl(662=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_666(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferControl(676=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_666(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferControlValue(671=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_672(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventBufferDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_581(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(794=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_581(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_909(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_909(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventBufferDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_909(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventDM(717=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_722(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(746=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_750(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(759=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_750(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventDM(776=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_722(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameter(717, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_721(721, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameter(776, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_777(777, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameterName(395=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_399(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(488, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(491, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(494, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(491, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(717, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(491, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(746, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(491, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(759, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(491, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameterName(776, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(491, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventParameters(721, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_775(775, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventParameters(777=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_778(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventSpec(785, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_787(787, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventSpec(789, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_790(790, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventSpecList(787, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_788(788, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventSpecList(790=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_791(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventStream(164=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_169(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStream(180=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_169(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStream(395=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_398(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventStreamOrOther(488=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_490(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(494=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_490(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(717=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_720(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(746=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_749(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(759=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_749(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventStreamOrOther(776=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_720(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_eventsDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_580(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(794=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_580(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_908(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_908(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_eventsDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_908(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_extension(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_extension(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_extensionParameter(421, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(432, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_extensionParameter(461, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(432, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_iaServiceStates(334=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_338(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_iepsValue(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_iepsValue(508=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_512(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_iepsValue(529=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_512(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_iepsValue(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_512(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_iepsValue(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_iepsValue(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_iepsValue(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudauditReturnParameter(198, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_207(207, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(403, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_207(207, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(407, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_408(408, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(421, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_207(207, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudauditReturnParameter(461, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_207(207, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudcontextAttrDescriptor(508, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_511(511, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAuddigitMapDescriptor(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(403=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(407=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAuddigitMapDescriptor(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventBufferDescriptor(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_205(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(403=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_205(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(407=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_205(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_205(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventBufferDescriptor(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_205(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventSpec(390, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_392(392, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventSpecParameter(395, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_397(397, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudeventsDescriptor(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_204(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(403=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_204(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(407=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_204(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_204(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudeventsDescriptor(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_204(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalControlDescriptor(321=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_327(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalControlDescriptor(352=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_327(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalControlDescriptor(377=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_327(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalParm(355, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_358(358, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalParm(372, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_373(373, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudlocalParmList(358, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_371(371, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudlocalParmList(373=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaDescriptor(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(403=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(407=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaDescriptor(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaParm(321, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_326(326, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaParm(377, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_378(378, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudmediaParms(326, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_376(376, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudmediaParms(378=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_379(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudpackagesDescriptor(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(403=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(407=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudpackagesDescriptor(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudrequestedEvent(382, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_384(384, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudrequestedEvent(387, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_388(388, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalList(227=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_232(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalParm(227, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_231(231, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudsignalsDescriptor(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_201(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(403=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_201(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(407=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_201(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_201(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudsignalsDescriptor(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_201(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstatisticsDescriptor(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(321=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_325(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(352=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_325(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(377=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_325(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(403=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(407=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstatisticsDescriptor(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstreamDescriptor(321=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstreamDescriptor(377=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudstreamParm(321=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_323(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstreamParm(352, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_353(353, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudstreamParm(377=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_323(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationAudit(198=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(403=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAudit(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_199(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationAuditList(207=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_406(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationAuditList(408=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_414(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationStateDescriptor(321=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_322(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indAudterminationStateDescriptor(377=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_322(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indAudterminationStateParm(334, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_337(337, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localControlDescriptor(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(682=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(685=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localControlDescriptor(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_656(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localParm(689, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_691(691, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localParm(702, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_703(703, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_localParmList(691, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_701(701, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_localParmList(703=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_704(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mId(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_93(93, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mId(446=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_448(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mId(453=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_454(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(794=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_579(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_907(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_907(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_907(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaParm(650, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_655(655, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaParm(707, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_708(708, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mediaParmList(655, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_706(706, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mediaParmList(708=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_709(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_megacoMessage(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_message(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(90, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_messageBody(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_578(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(794=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_578(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_906(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_906(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_906(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemType(634, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_648(648, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemType(635, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_637(637, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemType(639, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_640(640, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modemTypeList(637, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_638(638, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_modemTypeList(640=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_641(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mtpAddress(92, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_960(960, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_muxDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_577(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(794=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_577(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_905(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_905(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_muxDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_905(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_muxType(626, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_628(628, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notificationReason(265, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_266(266, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notificationReason(273, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_274(274, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notificationReasons(266, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_272(272, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notificationReasons(274=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_275(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyBehaviour(717=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_719(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyBehaviour(746=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyBehaviour(759=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_748(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyBehaviour(776=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_719(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyRegulated(717=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_718(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyRegulated(746=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_718(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyRegulated(759=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_718(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyRegulated(776=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_718(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyReply(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_835(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyReply(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_835(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyReplyBody(877=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_878(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyRequest(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_notifyRequest(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notifyRequestBody(470, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_472(472, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEvent(477, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_480(480, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(482, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_483(483, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(785=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_786(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvent(789=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_786(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventBody(486=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_487(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventBody(501=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_502(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventParameter(488, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_489(489, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventParameter(494, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_495(495, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventParameters(489, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_493(493, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventParameters(495=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_496(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEvents(480, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_481(481, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEvents(483=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_484(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_observedEventsDescriptor(470=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_471(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_904(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_904(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_observedEventsDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_904(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_onOrOff(504=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_505(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_onOrOff(695=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_696(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_onOrOff(697=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_698(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optAuditDescriptor(186=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_194(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optAuditDescriptor(561=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_562(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optAuditDescriptor(564=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_565(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optImmAckRequired(823, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_824(824, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optIndAudeventSpecParameter(391=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_394(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optIndAudsignalParm(220=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optIndAudsignalParm(413=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optPropertyParms(642=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_643(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optPropertyParms(648=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_649(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_optSep(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_88(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(89, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(92, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(105=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_106(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(111=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_112(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(446, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(92, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(453, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(92, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(477, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(479, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(478, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_498(498, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(482, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(479, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(499, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(500, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(785, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(479, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(789, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(479, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(960=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_964(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_optSep(961=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_963(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_903(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_903(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_903(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesItem(317, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_319(319, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItem(920, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_921(921, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItem(923, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_924(924, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_packagesItems(921, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_922(922, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_packagesItems(924=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_925(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_parmValue(245=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_286(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(336=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_349(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(357=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_349(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(432=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_459(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(491=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_492(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(532=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_349(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parmValue(553=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_349(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_pathName(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_959(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_pkgdName(222, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(224, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(227=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(238=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(334, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_336(336, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(355, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_357(357, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(372, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_357(357, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_383(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(387=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_383(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(390, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_391(391, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(479, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_486(486, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(500, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_501(501, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(508=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_510(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(529, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_532(532, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_510(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(551, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(553, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(559, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(553, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(593, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_595(595, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(603, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_595(595, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(607=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(614=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(617=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(622=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(644, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(553, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(662, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(553, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(676, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(553, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(689, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(553, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(702, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(553, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(713, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_715(715, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(742, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_744(744, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(764, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_744(744, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_pkgdName(781, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_715(715, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_portNumber(103, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_105(105, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_portNumber(110, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_111(111, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_portNumber(446=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_447(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_priority(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(508=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_509(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(529=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_509(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_509(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_priority(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParm(334=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_335(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(355=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_356(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_356(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(529, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_531(531, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(551, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_552(552, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(559, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_531(531, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(644, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_645(645, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(662=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_665(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(676=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_665(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(689=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_690(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParm(702=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_690(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParmList(531=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_550(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParmList(552=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_554(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParmList(645, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_646(646, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_propertyParms(529, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_530(530, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_propertyParms(559, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_530(530, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestID(261=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_263(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(381, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_386(386, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(475, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_476(476, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(711, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_712(712, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestID(740, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_741(741, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEvent(713, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_714(714, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestedEvent(781, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_782(782, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEventBody(715=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_716(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_requestedEvents(714, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_780(780, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_requestedEvents(782=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_783(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_safeToken(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(89, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(6, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(8, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(84, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(85, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(86, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(87, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_958(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(96, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_108(108, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(97, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(98, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(98, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(98, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(100, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(98, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(110=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(126=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_804(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(130=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(164=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(176=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(180=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(184=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(187=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(190=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(227=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(235=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_237(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(238=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(243, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(245, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(254=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(261=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(277=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_278(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(279=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_280(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(287=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(288=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(289=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(290=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(298=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(299=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(302=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(303=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(313, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(245, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(317=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_318(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(334=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(350=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(355=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(381=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(387=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(390=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(395=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(416=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_431(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(444=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_445(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(446=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(449=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(451=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_452(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(455=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_456(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(457=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_458(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_431(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(466=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_467(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(468=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(475=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(479=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(488=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(494=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(500=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(508=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(529=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(537=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(540=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(551=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(559=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(560=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(563=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(571=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(593=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(596=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(598=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(603=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(607=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(612=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_237(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(614=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(617=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(622=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(626=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_627(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(630=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(634=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_636(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(635=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_636(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(639=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_636(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(644=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(662=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(676=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(680=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(689=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(702=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(711=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(717=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(740=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(742=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(746=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(759=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(764=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(776=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(781=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(813=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_815(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(817=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_815(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(821=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_804(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(831=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(851=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(876=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(882=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(888=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(891=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_892(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(920=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_318(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(923=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_318(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(932=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(937=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken(953=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_804(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_safeToken2(4=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(6=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(84=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(86=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(92=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(96=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(97=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(98=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(100=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(110=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(126=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(130=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(164=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(176=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(180=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(184=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(187=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(190=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(222=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(227=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(235=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(238=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(243=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(254=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(261=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(277=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(279=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(287=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(288=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(289=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(290=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(298=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(299=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(302=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(303=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(313=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(317=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(334=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(350=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(355=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(372=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(381=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(382=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(387=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(390=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(395=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(416=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(444=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(446=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(449=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(451=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(455=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(457=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(466=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(468=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(475=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(479=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(488=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(494=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(500=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(508=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(529=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(537=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(540=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(545=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(551=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(559=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(560=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(563=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(571=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(593=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(596=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(598=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(603=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(607=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(612=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(614=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(617=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(622=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(626=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(630=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(634=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(635=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(639=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(644=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(662=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(676=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(680=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(689=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(702=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(711=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(713=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(717=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(740=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(742=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(746=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(759=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(764=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(776=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(781=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(813=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(817=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(821=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(831=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(851=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(876=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(882=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(888=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(891=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(920=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(923=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(932=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(937=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_safeToken2(953=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondEventParameter(746, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_747(747, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondEventParameter(759, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_760(760, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondEventParameters(747, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_758(758, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondEventParameters(760=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_761(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEvent(742, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_743(743, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondRequestedEvent(764, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_765(765, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEventBody(744=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_745(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_secondRequestedEvents(743, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_763(763, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_secondRequestedEvents(765=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_766(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_servChgReplyParm(858, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_864(864, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_servChgReplyParm(870, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_871(871, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_servChgReplyParms(864, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_869(869, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_servChgReplyParms(871=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_872(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeAddress(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_430(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_430(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(858=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_863(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeAddress(870=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_863(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeDelay(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_429(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeDelay(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_429(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeDescriptor(418, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_419(419, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeMethod(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_428(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMethod(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_428(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeMgcId(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_427(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_427(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(858=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeMgcId(870=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_862(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeParm(421, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_426(426, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeParm(461, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_462(462, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeParms(426, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_460(460, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeParms(462=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_463(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeProfile(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_425(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_425(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(858=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_861(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeProfile(870=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_861(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReason(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_424(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeReason(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_424(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReply(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_834(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeReply(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_834(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReplyBody(852=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_853(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeReplyDescriptor(854, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_855(855, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeRequest(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeRequest(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceChangeVersion(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_423(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_423(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(858=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_860(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceChangeVersion(870=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_860(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceStates(662=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_664(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceStates(676=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_664(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_serviceStatesValue(341=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_347(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceStatesValue(342=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_343(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_serviceStatesValue(669=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_670(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_sigParameter(243, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_244(244, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sigParameter(313, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_314(314, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_sigParameters(244, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_312(312, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sigParameters(314=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_315(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalList(607=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_610(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalList(622=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_610(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListId(235, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_236(236, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListId(612, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_613(613, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListParm(238, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_240(240, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParm(614, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_615(615, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParm(617, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_618(618, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalListParms(615, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_616(616, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalListParms(618=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_619(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalName(227, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(229, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(238, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(229, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(607, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(229, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(614, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(229, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(617, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(229, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalName(622, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(229, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalParm(607, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_609(609, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalParm(622, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_623(623, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalParms(609, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_621(621, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalParms(623=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_624(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalRequest(227=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(238=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(607=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_608(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(614=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(617=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalRequest(622=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_608(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalType(256=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_257(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_signalsDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_576(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(736, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_737(737, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(755, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_756(756, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(794=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_576(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_902(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_902(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_signalsDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_902(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsDescriptor(574=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_575(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(682=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(685=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_654(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(794=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_575(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(899=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_901(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(928=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_901(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsDescriptor(940=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_901(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsParameter(593, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_594(594, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsParameter(603, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_604(604, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statisticsParameters(594, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_602(602, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statisticsParameters(604=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_605(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamDescriptor(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamDescriptor(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_653(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamID(176=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_177(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(254=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(350, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_351(351, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamID(680, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_681(681, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamModes(362=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_370(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamModes(363=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_364(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamModes(699=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_700(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamParm(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_652(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(682, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_683(683, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(685, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_686(686, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParm(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_652(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_streamParmList(683, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_684(684, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_streamParmList(686=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_687(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_subtractRequest(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_subtractRequest(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_135(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_termIDList(184, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(186, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(416, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_417(417, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(468, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_469(469, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(560, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_561(561, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(563, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_564(564, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(571, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_572(572, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(851, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_852(852, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(876, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_877(877, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(882, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_883(883, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(932, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_883(883, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_termIDList(937, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_938(938, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationAudit(899, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_900(900, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationAudit(940, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_941(941, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationID(164=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_167(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(180=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_167(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(184=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(187, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(188, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(190, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(191, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(416=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(468=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(560=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(563=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(571=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(630, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_631(631, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(851=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(876=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(882=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(888, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_631(631, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(932=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationID(937=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationIDList(628=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_629(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDList(885=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_886(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDList(934=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_886(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationIDListRepeat(188, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(189, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDListRepeat(191=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationIDListRepeat(631, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_632(632, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateDescriptor(650=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_651(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateDescriptor(707=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_651(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateParm(662, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_663(663, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateParm(676, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_677(677, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_terminationStateParms(663, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_675(675, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_terminationStateParms(677=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_678(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_timeStamp(421=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_422(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(461=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_422(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(477, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_478(478, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(482, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_478(478, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(785, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_478(478, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(789, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_478(478, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(858=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_timeStamp(870=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_859(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDescComp(164, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(166, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescComp(180, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_181(181, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDescCompList(166, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(179, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescCompList(181=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDescriptor(133=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(568=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(833=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDescriptor(944=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_134(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_topologyDirection(164=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_topologyDirection(180=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionAck(813, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_814(814, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionAck(817, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_818(818, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionAckList(814, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_816(816, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionAckList(818=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_819(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionID(126, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_803(803, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionID(821, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_822(822, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionID(953, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_954(954, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionItem(93, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionItem(118, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionList(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionList(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_957(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionPending(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionPending(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionReply(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionReply(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionReplyBody(824, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_827(827, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionRequest(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionRequest(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_transactionResponseAck(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_transactionResponseAck(118=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_value(287=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_296(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(288=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_295(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(289=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(290=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_291(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(298, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_309(309, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(299, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_300(300, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(302, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_306(306, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(303, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_304(304, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(449=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_450(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(596=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_597(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_value(598, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_599(599, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_valueList(300, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(301, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_valueList(304=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_305(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_valueList(309, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_310(310, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_valueList(599, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_600(600, Cat, Ss, Stack, T, Ts, Tzr).

-compile({inline,yeccpars2_0_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_0_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_1_/1}).
-file("megaco_text_parser_prev3c.yrl", 487).
yeccpars2_1_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_3_/1}).
-file("megaco_text_parser_prev3c.yrl", 481).
yeccpars2_3_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sep
  end | __Stack].

-compile({inline,yeccpars2_7_/1}).
-file("megaco_text_parser_prev3c.yrl", 1537).
yeccpars2_7_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   make_safe_token ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_87_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_87_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_88_/1}).
-file("megaco_text_parser_prev3c.yrl", 486).
yeccpars2_88_(__Stack0) ->
 [__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_auth_header ( __3 , __5 , __7 )
  end | __Stack].

-compile({inline,yeccpars2_89_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_89_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_91_/1}).
-file("megaco_text_parser_prev3c.yrl", 479).
yeccpars2_91_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'MegacoMessage' { authHeader = __2 , mess = __3 }
  end | __Stack].

-compile({inline,yeccpars2_97_/1}).
-file("megaco_text_parser_prev3c.yrl", 1014).
yeccpars2_97_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_98_/1}).
-file("megaco_text_parser_prev3c.yrl", 1014).
yeccpars2_98_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_100_/1}).
-file("megaco_text_parser_prev3c.yrl", 1014).
yeccpars2_100_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_101_/1}).
-file("megaco_text_parser_prev3c.yrl", 1015).
yeccpars2_101_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ colon | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_102_/1}).
-file("megaco_text_parser_prev3c.yrl", 1012).
yeccpars2_102_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainAddress ( __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_104_/1}).
-file("megaco_text_parser_prev3c.yrl", 1019).
yeccpars2_104_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_105_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_105_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_106_/1}).
-file("megaco_text_parser_prev3c.yrl", 1010).
yeccpars2_106_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainAddress ( __2 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_107_/1}).
-file("megaco_text_parser_prev3c.yrl", 1016).
yeccpars2_107_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_109_/1}).
-file("megaco_text_parser_prev3c.yrl", 1002).
yeccpars2_109_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainName ( __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_111_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_111_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_112_/1}).
-file("megaco_text_parser_prev3c.yrl", 1000).
yeccpars2_112_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_domainName ( __2 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_113_/1}).
-file("megaco_text_parser_prev3c.yrl", 501).
yeccpars2_113_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionResponseAck , __1 }
  end | __Stack].

-compile({inline,yeccpars2_114_/1}).
-file("megaco_text_parser_prev3c.yrl", 498).
yeccpars2_114_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionRequest , __1 }
  end | __Stack].

-compile({inline,yeccpars2_115_/1}).
-file("megaco_text_parser_prev3c.yrl", 499).
yeccpars2_115_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionReply , __1 }
  end | __Stack].

-compile({inline,yeccpars2_116_/1}).
-file("megaco_text_parser_prev3c.yrl", 500).
yeccpars2_116_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionPending , __1 }
  end | __Stack].

-compile({inline,yeccpars2_117_/1}).
-file("megaco_text_parser_prev3c.yrl", 493).
yeccpars2_117_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactions , __1 }
  end | __Stack].

-compile({inline,yeccpars2_118_/1}).
-file("megaco_text_parser_prev3c.yrl", 495).
yeccpars2_118_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_119_/1}).
-file("megaco_text_parser_prev3c.yrl", 490).
yeccpars2_119_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_message ( __1 , __2 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_120_/1}).
-file("megaco_text_parser_prev3c.yrl", 492).
yeccpars2_120_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { messageError , __1 }
  end | __Stack].

-compile({inline,yeccpars2_128_/1}).
-file("megaco_text_parser_prev3c.yrl", 530).
yeccpars2_128_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_131_/1}).
-file("megaco_text_parser_prev3c.yrl", 1007).
yeccpars2_131_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_contextID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_134_/1}).
-file("megaco_text_parser_prev3c.yrl", 555).
yeccpars2_134_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { topology , __1 }
  end | __Stack].

-compile({inline,yeccpars2_137_/1}).
-file("megaco_text_parser_prev3c.yrl", 556).
yeccpars2_137_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { priority , __1 }
  end | __Stack].

-compile({inline,yeccpars2_139_/1}).
-file("megaco_text_parser_prev3c.yrl", 559).
yeccpars2_139_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { iepsCallind , __1 }
  end | __Stack].

-compile({inline,yeccpars2_140_/1}).
-file("megaco_text_parser_prev3c.yrl", 549).
yeccpars2_140_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextProp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_141_/1}).
-file("megaco_text_parser_prev3c.yrl", 550).
yeccpars2_141_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextAudit , __1 }
  end | __Stack].

-compile({inline,yeccpars2_143_/1}).
-file("megaco_text_parser_prev3c.yrl", 551).
yeccpars2_143_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { commandRequest , __1 }
  end | __Stack].

-compile({inline,yeccpars2_147_/1}).
-file("megaco_text_parser_prev3c.yrl", 547).
yeccpars2_147_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_149_/1}).
-file("megaco_text_parser_prev3c.yrl", 666).
yeccpars2_149_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { addReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_154_/1}).
-file("megaco_text_parser_prev3c.yrl", 558).
yeccpars2_154_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { emergency , false }
  end | __Stack].

-compile({inline,yeccpars2_155_/1}).
-file("megaco_text_parser_prev3c.yrl", 557).
yeccpars2_155_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { emergency , true }
  end | __Stack].

-compile({inline,yeccpars2_157_/1}).
-file("megaco_text_parser_prev3c.yrl", 668).
yeccpars2_157_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { modReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_158_/1}).
-file("megaco_text_parser_prev3c.yrl", 667).
yeccpars2_158_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { moveReq , __1 }
  end | __Stack].

-compile({inline,yeccpars2_166_/1}).
-file("megaco_text_parser_prev3c.yrl", 1515).
yeccpars2_166_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_167_/1}).
-file("megaco_text_parser_prev3c.yrl", 1511).
yeccpars2_167_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { tid , __1 }
  end | __Stack].

-compile({inline,yeccpars2_168_/1}).
-file("megaco_text_parser_prev3c.yrl", 1037).
yeccpars2_168_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_terminationID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_169_/1}).
-file("megaco_text_parser_prev3c.yrl", 1512).
yeccpars2_169_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { sid , __1 }
  end | __Stack].

-compile({inline,yeccpars2_170_/1}).
-file("megaco_text_parser_prev3c.yrl", 1519).
yeccpars2_170_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { direction , bothway }
  end | __Stack].

-compile({inline,yeccpars2_171_/1}).
-file("megaco_text_parser_prev3c.yrl", 1520).
yeccpars2_171_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { direction , isolate }
  end | __Stack].

-compile({inline,yeccpars2_172_/1}).
-file("megaco_text_parser_prev3c.yrl", 1523).
yeccpars2_172_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { direction_ext , onewayboth }
  end | __Stack].

-compile({inline,yeccpars2_173_/1}).
-file("megaco_text_parser_prev3c.yrl", 1522).
yeccpars2_173_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { direction_ext , onewayexternal }
  end | __Stack].

-compile({inline,yeccpars2_174_/1}).
-file("megaco_text_parser_prev3c.yrl", 1521).
yeccpars2_174_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { direction , oneway }
  end | __Stack].

-compile({inline,yeccpars2_177_/1}).
-file("megaco_text_parser_prev3c.yrl", 939).
yeccpars2_177_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_178_/1}).
-file("megaco_text_parser_prev3c.yrl", 1176).
yeccpars2_178_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_streamID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_181_/1}).
-file("megaco_text_parser_prev3c.yrl", 1515).
yeccpars2_181_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_182_/1}).
-file("megaco_text_parser_prev3c.yrl", 1517).
yeccpars2_182_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_183_/1}).
-file("megaco_text_parser_prev3c.yrl", 1509).
yeccpars2_183_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_topologyDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_185_/1}).
-file("megaco_text_parser_prev3c.yrl", 1023).
yeccpars2_185_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_186_/1}).
-file("megaco_text_parser_prev3c.yrl", 706).
yeccpars2_186_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_188_/1}).
-file("megaco_text_parser_prev3c.yrl", 1032).
yeccpars2_188_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_191_/1}).
-file("megaco_text_parser_prev3c.yrl", 1032).
yeccpars2_191_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_192_/1}).
-file("megaco_text_parser_prev3c.yrl", 1031).
yeccpars2_192_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_193_/1}).
-file("megaco_text_parser_prev3c.yrl", 1025).
yeccpars2_193_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_194_/1}).
-file("megaco_text_parser_prev3c.yrl", 700).
yeccpars2_194_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   SR = # 'SubtractRequest' { terminationID = __3 ,
    auditDescriptor = __4 } ,
    make_commandRequest ( { subtractReq , __1 } , SR )
  end | __Stack].

-compile({inline,yeccpars2_198_/1}).
-file("megaco_text_parser_prev3c.yrl", 758).
yeccpars2_198_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_199_/1}).
-file("megaco_text_parser_prev3c.yrl", 779).
yeccpars2_199_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { terminationAudit , __1 }
  end | __Stack].

-compile({inline,yeccpars2_200_/1}).
-file("megaco_text_parser_prev3c.yrl", 806).
yeccpars2_200_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudStatisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_201_/1}).
-file("megaco_text_parser_prev3c.yrl", 800).
yeccpars2_201_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudSignalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_202_/1}).
-file("megaco_text_parser_prev3c.yrl", 808).
yeccpars2_202_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudPackagesDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_203_/1}).
-file("megaco_text_parser_prev3c.yrl", 796).
yeccpars2_203_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudMediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_204_/1}).
-file("megaco_text_parser_prev3c.yrl", 798).
yeccpars2_204_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudEventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_205_/1}).
-file("megaco_text_parser_prev3c.yrl", 804).
yeccpars2_205_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudEventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_206_/1}).
-file("megaco_text_parser_prev3c.yrl", 802).
yeccpars2_206_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { indAudDigitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_207_/1}).
-file("megaco_text_parser_prev3c.yrl", 793).
yeccpars2_207_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_209_/1}).
-file("megaco_text_parser_prev3c.yrl", 761).
yeccpars2_209_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_211_/1}).
-file("megaco_text_parser_prev3c.yrl", 931).
yeccpars2_211_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_IADMD ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_212_/1}).
-file("megaco_text_parser_prev3c.yrl", 768).
yeccpars2_212_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   digitMapToken
  end | __Stack].

-compile({inline,yeccpars2_213_/1}).
-file("megaco_text_parser_prev3c.yrl", 777).
yeccpars2_213_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   eventBufferToken
  end | __Stack].

-compile({inline,yeccpars2_214_/1}).
-file("megaco_text_parser_prev3c.yrl", 778).
yeccpars2_214_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   eventsToken
  end | __Stack].

-compile({inline,yeccpars2_215_/1}).
-file("megaco_text_parser_prev3c.yrl", 767).
yeccpars2_215_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   mediaToken
  end | __Stack].

-compile({inline,yeccpars2_216_/1}).
-file("megaco_text_parser_prev3c.yrl", 766).
yeccpars2_216_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modemToken
  end | __Stack].

-compile({inline,yeccpars2_217_/1}).
-file("megaco_text_parser_prev3c.yrl", 765).
yeccpars2_217_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   muxToken
  end | __Stack].

-compile({inline,yeccpars2_218_/1}).
-file("megaco_text_parser_prev3c.yrl", 770).
yeccpars2_218_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   observedEventsToken
  end | __Stack].

-compile({inline,yeccpars2_219_/1}).
-file("megaco_text_parser_prev3c.yrl", 771).
yeccpars2_219_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   packagesToken
  end | __Stack].

-compile({inline,yeccpars2_220_/1}).
-file("megaco_text_parser_prev3c.yrl", 776).
yeccpars2_220_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   signalsToken
  end | __Stack].

-compile({inline,yeccpars2_221_/1}).
-file("megaco_text_parser_prev3c.yrl", 769).
yeccpars2_221_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statsToken
  end | __Stack].

-compile({inline,yeccpars2_223_/1}).
-file("megaco_text_parser_prev3c.yrl", 1178).
yeccpars2_223_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_pkgdName ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_225_/1}).
-file("megaco_text_parser_prev3c.yrl", 934).
yeccpars2_225_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStatisticsDescriptor' { statName = __3 }
  end | __Stack].

-compile({inline,yeccpars2_226_/1}).
-file("megaco_text_parser_prev3c.yrl", 911).
yeccpars2_226_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_228_/1}).
-file("megaco_text_parser_prev3c.yrl", 918).
yeccpars2_228_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signal , ensure_indAudSignal ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_229_/1}).
-file("megaco_text_parser_prev3c.yrl", 1287).
yeccpars2_229_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_signalRequest ( __1 , [ ] )
  end | __Stack].

-compile({inline,yeccpars2_232_/1}).
-file("megaco_text_parser_prev3c.yrl", 917).
yeccpars2_232_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { seqSigList , __1 }
  end | __Stack].

-compile({inline,yeccpars2_233_/1}).
-file("megaco_text_parser_prev3c.yrl", 914).
yeccpars2_233_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   asn1_NOVALUE
  end | __Stack].

-compile({inline,yeccpars2_236_/1}).
-file("megaco_text_parser_prev3c.yrl", 921).
yeccpars2_236_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudSeqSigList' { id = ensure_uint16 ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_237_/1}).
-file("megaco_text_parser_prev3c.yrl", 1357).
yeccpars2_237_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_241_/1}).
-file("megaco_text_parser_prev3c.yrl", 924).
yeccpars2_241_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudSeqSigList' { id = ensure_uint16 ( __3 ) ,
    signalList =
    ensure_indAudSignalListParm ( __5 ) }
  end | __Stack].

-compile({inline,yeccpars2_242_/1}).
-file("megaco_text_parser_prev3c.yrl", 915).
yeccpars2_242_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_244_/1}).
-file("megaco_text_parser_prev3c.yrl", 1290).
yeccpars2_244_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_249_COMMA/1}).
-file("megaco_text_parser_prev3c.yrl", 1321).
yeccpars2_249_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_249_RBRKT/1}).
-file("megaco_text_parser_prev3c.yrl", 1321).
yeccpars2_249_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_255_/1}).
-file("megaco_text_parser_prev3c.yrl", 1313).
yeccpars2_255_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { stream , __3 }
  end | __Stack].

-compile({inline,yeccpars2_257_/1}).
-file("megaco_text_parser_prev3c.yrl", 1315).
yeccpars2_257_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { signal_type , __3 }
  end | __Stack].

-compile({inline,yeccpars2_258_/1}).
-file("megaco_text_parser_prev3c.yrl", 1333).
yeccpars2_258_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   brief
  end | __Stack].

-compile({inline,yeccpars2_259_/1}).
-file("megaco_text_parser_prev3c.yrl", 1331).
yeccpars2_259_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onOff
  end | __Stack].

-compile({inline,yeccpars2_260_/1}).
-file("megaco_text_parser_prev3c.yrl", 1332).
yeccpars2_260_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   timeOut
  end | __Stack].

-compile({inline,yeccpars2_262_/1}).
-file("megaco_text_parser_prev3c.yrl", 1391).
yeccpars2_262_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_requestID ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_263_/1}).
-file("megaco_text_parser_prev3c.yrl", 1325).
yeccpars2_263_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { requestId , __3 }
  end | __Stack].

-compile({inline,yeccpars2_266_/1}).
-file("megaco_text_parser_prev3c.yrl", 1340).
yeccpars2_266_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_267_/1}).
-file("megaco_text_parser_prev3c.yrl", 1343).
yeccpars2_267_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onInterruptByEvent
  end | __Stack].

-compile({inline,yeccpars2_268_/1}).
-file("megaco_text_parser_prev3c.yrl", 1344).
yeccpars2_268_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onInterruptByNewSignalDescr
  end | __Stack].

-compile({inline,yeccpars2_269_/1}).
-file("megaco_text_parser_prev3c.yrl", 1346).
yeccpars2_269_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   iteration
  end | __Stack].

-compile({inline,yeccpars2_270_/1}).
-file("megaco_text_parser_prev3c.yrl", 1345).
yeccpars2_270_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   otherReason
  end | __Stack].

-compile({inline,yeccpars2_271_/1}).
-file("megaco_text_parser_prev3c.yrl", 1342).
yeccpars2_271_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   onTimeOut
  end | __Stack].

-compile({inline,yeccpars2_274_/1}).
-file("megaco_text_parser_prev3c.yrl", 1340).
yeccpars2_274_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_275_/1}).
-file("megaco_text_parser_prev3c.yrl", 1339).
yeccpars2_275_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_276_/1}).
-file("megaco_text_parser_prev3c.yrl", 1320).
yeccpars2_276_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { notify_completion , [ __4 | __5 ] }
  end | __Stack].

-compile({inline,yeccpars2_278_/1}).
-file("megaco_text_parser_prev3c.yrl", 1327).
yeccpars2_278_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { intersigDelay , ensure_uint16 ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_280_/1}).
-file("megaco_text_parser_prev3c.yrl", 1317).
yeccpars2_280_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { duration , ensure_uint16 ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_282_/1}).
-file("megaco_text_parser_prev3c.yrl", 1323).
yeccpars2_282_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { direction , __3 }
  end | __Stack].

-compile({inline,yeccpars2_283_/1}).
-file("megaco_text_parser_prev3c.yrl", 1337).
yeccpars2_283_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   both
  end | __Stack].

-compile({inline,yeccpars2_284_/1}).
-file("megaco_text_parser_prev3c.yrl", 1335).
yeccpars2_284_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   external
  end | __Stack].

-compile({inline,yeccpars2_285_/1}).
-file("megaco_text_parser_prev3c.yrl", 1336).
yeccpars2_285_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   internal
  end | __Stack].

-compile({inline,yeccpars2_286_/1}).
-file("megaco_text_parser_prev3c.yrl", 1329).
yeccpars2_286_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { other , ensure_NAME ( __1 ) , __2 }
  end | __Stack].

-compile({inline,yeccpars2_291_/1}).
-file("megaco_text_parser_prev3c.yrl", 1111).
yeccpars2_291_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , unequalTo } }
  end | __Stack].

-compile({inline,yeccpars2_292_/1}).
-file("megaco_text_parser_prev3c.yrl", 1535).
yeccpars2_292_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_value ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_293_/1}).
-file("megaco_text_parser_prev3c.yrl", 1534).
yeccpars2_293_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_value ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_294_/1}).
-file("megaco_text_parser_prev3c.yrl", 1114).
yeccpars2_294_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , smallerThan } }
  end | __Stack].

-compile({inline,yeccpars2_295_/1}).
-file("megaco_text_parser_prev3c.yrl", 1117).
yeccpars2_295_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 ] ,
    extraInfo = { relation , greaterThan } }
  end | __Stack].

-compile({inline,yeccpars2_296_/1}).
-file("megaco_text_parser_prev3c.yrl", 1138).
yeccpars2_296_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __1 ] }
  end | __Stack].

-compile({inline,yeccpars2_297_/1}).
-file("megaco_text_parser_prev3c.yrl", 1108).
yeccpars2_297_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_300_/1}).
-file("megaco_text_parser_prev3c.yrl", 1141).
yeccpars2_300_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_304_/1}).
-file("megaco_text_parser_prev3c.yrl", 1141).
yeccpars2_304_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_305_/1}).
-file("megaco_text_parser_prev3c.yrl", 1140).
yeccpars2_305_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_307_/1}).
-file("megaco_text_parser_prev3c.yrl", 1130).
yeccpars2_307_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 , __4 ] ,
    extraInfo = { range , true } }
  end | __Stack].

-compile({inline,yeccpars2_308_/1}).
-file("megaco_text_parser_prev3c.yrl", 1134).
yeccpars2_308_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 | __3 ] ,
    extraInfo = { sublist , true } }
  end | __Stack].

-compile({inline,yeccpars2_309_/1}).
-file("megaco_text_parser_prev3c.yrl", 1141).
yeccpars2_309_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_311_/1}).
-file("megaco_text_parser_prev3c.yrl", 1126).
yeccpars2_311_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'PropertyParm' { value = [ __2 | __3 ] ,
    extraInfo = { sublist , false } }
  end | __Stack].

-compile({inline,yeccpars2_314_/1}).
-file("megaco_text_parser_prev3c.yrl", 1290).
yeccpars2_314_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_315_/1}).
-file("megaco_text_parser_prev3c.yrl", 1289).
yeccpars2_315_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_316_/1}).
-file("megaco_text_parser_prev3c.yrl", 1286).
yeccpars2_316_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_signalRequest ( __1 , [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_318_/1}).
-file("megaco_text_parser_prev3c.yrl", 1483).
yeccpars2_318_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_packagesItem ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_320_/1}).
-file("megaco_text_parser_prev3c.yrl", 937).
yeccpars2_320_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudPackagesDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_322_/1}).
-file("megaco_text_parser_prev3c.yrl", 821).
yeccpars2_322_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { termStateDescr , __1 }
  end | __Stack].

-compile({inline,yeccpars2_323_/1}).
-file("megaco_text_parser_prev3c.yrl", 819).
yeccpars2_323_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_324_/1}).
-file("megaco_text_parser_prev3c.yrl", 820).
yeccpars2_324_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamDescr , __1 }
  end | __Stack].

-compile({inline,yeccpars2_325_/1}).
-file("megaco_text_parser_prev3c.yrl", 836).
yeccpars2_325_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamParms' { statisticsDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_326_/1}).
-file("megaco_text_parser_prev3c.yrl", 824).
yeccpars2_326_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_327_/1}).
-file("megaco_text_parser_prev3c.yrl", 834).
yeccpars2_327_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamParms' { localControlDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_329_/1}).
-file("megaco_text_parser_prev3c.yrl", 831).
yeccpars2_329_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   LD = ensure_prop_groups ( __1 ) ,
    # 'IndAudStreamParms' { localDescriptor = LD }
  end | __Stack].

-compile({inline,yeccpars2_330_/1}).
-file("megaco_text_parser_prev3c.yrl", 828).
yeccpars2_330_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   RD = ensure_prop_groups ( __1 ) ,
    # 'IndAudStreamParms' { remoteDescriptor = RD }
  end | __Stack].

-compile({inline,yeccpars2_335_/1}).
-file("megaco_text_parser_prev3c.yrl", 877).
yeccpars2_335_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_336_/1}).
-file("megaco_text_parser_prev3c.yrl", 878).
yeccpars2_336_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { name , __1 }
  end | __Stack].

-compile({inline,yeccpars2_339_/1}).
-file("megaco_text_parser_prev3c.yrl", 876).
yeccpars2_339_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   bufferToken
  end | __Stack].

-compile({inline,yeccpars2_340_/1}).
-file("megaco_text_parser_prev3c.yrl", 881).
yeccpars2_340_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   serviceStatesToken
  end | __Stack].

-compile({inline,yeccpars2_343_/1}).
-file("megaco_text_parser_prev3c.yrl", 885).
yeccpars2_343_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceStates , { inequal , __3 } }
  end | __Stack].

-compile({inline,yeccpars2_344_/1}).
-file("megaco_text_parser_prev3c.yrl", 1163).
yeccpars2_344_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   inSvc
  end | __Stack].

-compile({inline,yeccpars2_345_/1}).
-file("megaco_text_parser_prev3c.yrl", 1162).
yeccpars2_345_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   outOfSvc
  end | __Stack].

-compile({inline,yeccpars2_346_/1}).
-file("megaco_text_parser_prev3c.yrl", 1161).
yeccpars2_346_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   test
  end | __Stack].

-compile({inline,yeccpars2_347_/1}).
-file("megaco_text_parser_prev3c.yrl", 883).
yeccpars2_347_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceStates , { equal , __3 } }
  end | __Stack].

-compile({inline,yeccpars2_348_/1}).
-file("megaco_text_parser_prev3c.yrl", 869).
yeccpars2_348_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudTerminationStateDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_349_/1}).
-file("megaco_text_parser_prev3c.yrl", 1105).
yeccpars2_349_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'PropertyParm' .name , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_354_/1}).
-file("megaco_text_parser_prev3c.yrl", 840).
yeccpars2_354_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudStreamDescriptor' { streamID = __3 ,
    streamParms = __5 }
  end | __Stack].

-compile({inline,yeccpars2_356_/1}).
-file("megaco_text_parser_prev3c.yrl", 863).
yeccpars2_356_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_357_/1}).
-file("megaco_text_parser_prev3c.yrl", 864).
yeccpars2_357_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { name , __1 }
  end | __Stack].

-compile({inline,yeccpars2_358_/1}).
-file("megaco_text_parser_prev3c.yrl", 851).
yeccpars2_358_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_359_/1}).
-file("megaco_text_parser_prev3c.yrl", 860).
yeccpars2_359_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modeToken
  end | __Stack].

-compile({inline,yeccpars2_360_/1}).
-file("megaco_text_parser_prev3c.yrl", 858).
yeccpars2_360_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   reservedGroupToken
  end | __Stack].

-compile({inline,yeccpars2_361_/1}).
-file("megaco_text_parser_prev3c.yrl", 859).
yeccpars2_361_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   reservedValueToken
  end | __Stack].

-compile({inline,yeccpars2_364_/1}).
-file("megaco_text_parser_prev3c.yrl", 862).
yeccpars2_364_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { mode , { inequal , __3 } }
  end | __Stack].

-compile({inline,yeccpars2_365_/1}).
-file("megaco_text_parser_prev3c.yrl", 1101).
yeccpars2_365_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   inactive
  end | __Stack].

-compile({inline,yeccpars2_366_/1}).
-file("megaco_text_parser_prev3c.yrl", 1102).
yeccpars2_366_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   loopBack
  end | __Stack].

-compile({inline,yeccpars2_367_/1}).
-file("megaco_text_parser_prev3c.yrl", 1099).
yeccpars2_367_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   recvOnly
  end | __Stack].

-compile({inline,yeccpars2_368_/1}).
-file("megaco_text_parser_prev3c.yrl", 1098).
yeccpars2_368_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sendOnly
  end | __Stack].

-compile({inline,yeccpars2_369_/1}).
-file("megaco_text_parser_prev3c.yrl", 1100).
yeccpars2_369_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   sendRecv
  end | __Stack].

-compile({inline,yeccpars2_370_/1}).
-file("megaco_text_parser_prev3c.yrl", 861).
yeccpars2_370_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { mode , { equal , __3 } }
  end | __Stack].

-compile({inline,yeccpars2_373_/1}).
-file("megaco_text_parser_prev3c.yrl", 851).
yeccpars2_373_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_374_/1}).
-file("megaco_text_parser_prev3c.yrl", 850).
yeccpars2_374_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_375_/1}).
-file("megaco_text_parser_prev3c.yrl", 847).
yeccpars2_375_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudLocalControlDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_378_/1}).
-file("megaco_text_parser_prev3c.yrl", 824).
yeccpars2_378_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_379_/1}).
-file("megaco_text_parser_prev3c.yrl", 823).
yeccpars2_379_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_380_/1}).
-file("megaco_text_parser_prev3c.yrl", 813).
yeccpars2_380_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudMediaDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_385_/1}).
-file("megaco_text_parser_prev3c.yrl", 902).
yeccpars2_385_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudEventsDescriptor' { pkgdName = __3 }
  end | __Stack].

-compile({inline,yeccpars2_389_/1}).
-file("megaco_text_parser_prev3c.yrl", 905).
yeccpars2_389_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'IndAudEventsDescriptor' { requestID = __3 ,
    pkgdName = __5 }
  end | __Stack].

-compile({inline,yeccpars2_391_/1}).
-file("megaco_text_parser_prev3c.yrl", 895).
yeccpars2_391_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_393_/1}).
-file("megaco_text_parser_prev3c.yrl", 888).
yeccpars2_393_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_394_/1}).
-file("megaco_text_parser_prev3c.yrl", 891).
yeccpars2_394_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_indAudEventBufferDescriptor ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_396_/1}).
-file("megaco_text_parser_prev3c.yrl", 1268).
yeccpars2_396_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_NAME ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_398_/1}).
-file("megaco_text_parser_prev3c.yrl", 898).
yeccpars2_398_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamID , __1 }
  end | __Stack].

-compile({inline,yeccpars2_399_/1}).
-file("megaco_text_parser_prev3c.yrl", 899).
yeccpars2_399_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventParameterName , __1 }
  end | __Stack].

-compile({inline,yeccpars2_400_/1}).
-file("megaco_text_parser_prev3c.yrl", 894).
yeccpars2_400_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_401_/1}).
-file("megaco_text_parser_prev3c.yrl", 755).
yeccpars2_401_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_auditDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_402_/1}).
-file("megaco_text_parser_prev3c.yrl", 757).
yeccpars2_402_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_404_/1}).
-file("megaco_text_parser_prev3c.yrl", 761).
yeccpars2_404_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_405_/1}).
-file("megaco_text_parser_prev3c.yrl", 760).
yeccpars2_405_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_406_/1}).
-file("megaco_text_parser_prev3c.yrl", 788).
yeccpars2_406_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_408_/1}).
-file("megaco_text_parser_prev3c.yrl", 793).
yeccpars2_408_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_414_/1}).
-file("megaco_text_parser_prev3c.yrl", 792).
yeccpars2_414_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_415_/1}).
-file("megaco_text_parser_prev3c.yrl", 705).
yeccpars2_415_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_422_/1}).
-file("megaco_text_parser_prev3c.yrl", 1433).
yeccpars2_422_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { time_stamp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_423_/1}).
-file("megaco_text_parser_prev3c.yrl", 1435).
yeccpars2_423_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { version , __1 }
  end | __Stack].

-compile({inline,yeccpars2_424_/1}).
-file("megaco_text_parser_prev3c.yrl", 1428).
yeccpars2_424_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { reason , __1 }
  end | __Stack].

-compile({inline,yeccpars2_425_/1}).
-file("megaco_text_parser_prev3c.yrl", 1431).
yeccpars2_425_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { profile , __1 }
  end | __Stack].

-compile({inline,yeccpars2_426_/1}).
-file("megaco_text_parser_prev3c.yrl", 1425).
yeccpars2_426_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_427_/1}).
-file("megaco_text_parser_prev3c.yrl", 1434).
yeccpars2_427_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mgc_id , __1 }
  end | __Stack].

-compile({inline,yeccpars2_428_/1}).
-file("megaco_text_parser_prev3c.yrl", 1427).
yeccpars2_428_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { method , __1 }
  end | __Stack].

-compile({inline,yeccpars2_429_/1}).
-file("megaco_text_parser_prev3c.yrl", 1429).
yeccpars2_429_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { delay , __1 }
  end | __Stack].

-compile({inline,yeccpars2_430_/1}).
-file("megaco_text_parser_prev3c.yrl", 1430).
yeccpars2_430_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { address , __1 }
  end | __Stack].

-compile({inline,yeccpars2_431_/1}).
-file("megaco_text_parser_prev3c.yrl", 1532).
yeccpars2_431_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_extensionParameter ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_433_/1}).
-file("megaco_text_parser_prev3c.yrl", 1432).
yeccpars2_433_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { extension , __1 }
  end | __Stack].

-compile({inline,yeccpars2_434_/1}).
-file("megaco_text_parser_prev3c.yrl", 1437).
yeccpars2_434_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { audit_item , __1 }
  end | __Stack].

-compile({inline,yeccpars2_441_/1}).
-file("megaco_text_parser_prev3c.yrl", 1436).
yeccpars2_441_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   incomplete
  end | __Stack].

-compile({inline,yeccpars2_442_/1}).
-file("megaco_text_parser_prev3c.yrl", 1485).
yeccpars2_442_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_timeStamp ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_445_/1}).
-file("megaco_text_parser_prev3c.yrl", 1454).
yeccpars2_445_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_version ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_446_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_446_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_447_/1}).
-file("megaco_text_parser_prev3c.yrl", 1448).
yeccpars2_447_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { portNumber , __3 }
  end | __Stack].

-compile({inline,yeccpars2_448_/1}).
-file("megaco_text_parser_prev3c.yrl", 1446).
yeccpars2_448_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_450_/1}).
-file("megaco_text_parser_prev3c.yrl", 1442).
yeccpars2_450_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 ]
  end | __Stack].

-compile({inline,yeccpars2_452_/1}).
-file("megaco_text_parser_prev3c.yrl", 1452).
yeccpars2_452_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_profile ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_453_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_453_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_454_/1}).
-file("megaco_text_parser_prev3c.yrl", 1450).
yeccpars2_454_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_456_/1}).
-file("megaco_text_parser_prev3c.yrl", 1440).
yeccpars2_456_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_serviceChangeMethod ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_458_/1}).
-file("megaco_text_parser_prev3c.yrl", 1444).
yeccpars2_458_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_uint32 ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_459_/1}).
-file("megaco_text_parser_prev3c.yrl", 1457).
yeccpars2_459_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'PropertyParm' .name , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_462_/1}).
-file("megaco_text_parser_prev3c.yrl", 1425).
yeccpars2_462_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_463_/1}).
-file("megaco_text_parser_prev3c.yrl", 1424).
yeccpars2_463_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_464_/1}).
-file("megaco_text_parser_prev3c.yrl", 1421).
yeccpars2_464_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_ServiceChangeParm ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_465_/1}).
-file("megaco_text_parser_prev3c.yrl", 965).
yeccpars2_465_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { serviceChangeReq , __1 } ,
    # 'ServiceChangeRequest' { terminationID = __3 ,
    serviceChangeParms = __5 } )
  end | __Stack].

-compile({inline,yeccpars2_467_/1}).
-file("megaco_text_parser_prev3c.yrl", 1530).
yeccpars2_467_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_uint16 ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_471_/1}).
-file("megaco_text_parser_prev3c.yrl", 952).
yeccpars2_471_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'NotifyRequest' { observedEventsDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_473_/1}).
-file("megaco_text_parser_prev3c.yrl", 954).
yeccpars2_473_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'NotifyRequest' { errorDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_477_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_477_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_478_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_478_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_480_/1}).
-file("megaco_text_parser_prev3c.yrl", 1371).
yeccpars2_480_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_482_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_482_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_483_/1}).
-file("megaco_text_parser_prev3c.yrl", 1371).
yeccpars2_483_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_484_/1}).
-file("megaco_text_parser_prev3c.yrl", 1370).
yeccpars2_484_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_485_/1}).
-file("megaco_text_parser_prev3c.yrl", 1367).
yeccpars2_485_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'ObservedEventsDescriptor' { requestId = __3 ,
    observedEventLst = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_486_/1}).
-file("megaco_text_parser_prev3c.yrl", 1383).
yeccpars2_486_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_487_/1}).
-file("megaco_text_parser_prev3c.yrl", 1378).
yeccpars2_487_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_observed_event ( __3 , __2 , asn1_NOVALUE )
  end | __Stack].

-compile({inline,yeccpars2_489_/1}).
-file("megaco_text_parser_prev3c.yrl", 1386).
yeccpars2_489_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_492_/1}).
-file("megaco_text_parser_prev3c.yrl", 1266).
yeccpars2_492_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   select_stream_or_other ( __1 , __2 )
  end | __Stack].

-compile({inline,yeccpars2_495_/1}).
-file("megaco_text_parser_prev3c.yrl", 1386).
yeccpars2_495_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_496_/1}).
-file("megaco_text_parser_prev3c.yrl", 1385).
yeccpars2_496_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_497_/1}).
-file("megaco_text_parser_prev3c.yrl", 1382).
yeccpars2_497_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_499_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_499_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_501_/1}).
-file("megaco_text_parser_prev3c.yrl", 1383).
yeccpars2_501_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_502_/1}).
-file("megaco_text_parser_prev3c.yrl", 1376).
yeccpars2_502_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_observed_event ( __6 , __5 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_503_/1}).
-file("megaco_text_parser_prev3c.yrl", 947).
yeccpars2_503_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   NR = setelement ( # 'NotifyRequest' .terminationID ,
    __5 , __3 ) ,
    make_commandRequest ( { notifyReq , __1 } , NR )
  end | __Stack].

-compile({inline,yeccpars2_505_/1}).
-file("megaco_text_parser_prev3c.yrl", 1525).
yeccpars2_505_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_506_/1}).
-file("megaco_text_parser_prev3c.yrl", 1095).
yeccpars2_506_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   false
  end | __Stack].

-compile({inline,yeccpars2_507_/1}).
-file("megaco_text_parser_prev3c.yrl", 1094).
yeccpars2_507_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   true
  end | __Stack].

-compile({inline,yeccpars2_509_/1}).
-file("megaco_text_parser_prev3c.yrl", 600).
yeccpars2_509_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { select_prio , __1 }
  end | __Stack].

-compile({inline,yeccpars2_510_/1}).
-file("megaco_text_parser_prev3c.yrl", 596).
yeccpars2_510_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_512_/1}).
-file("megaco_text_parser_prev3c.yrl", 602).
yeccpars2_512_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { select_ieps , __1 }
  end | __Stack].

-compile({inline,yeccpars2_513_/1}).
-file("megaco_text_parser_prev3c.yrl", 601).
yeccpars2_513_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { select_emergency , __1 }
  end | __Stack].

-compile({inline,yeccpars2_515_/1}).
-file("megaco_text_parser_prev3c.yrl", 589).
yeccpars2_515_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_517_/1}).
-file("megaco_text_parser_prev3c.yrl", 603).
yeccpars2_517_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { select_logic , __1 }
  end | __Stack].

-compile({inline,yeccpars2_518_/1}).
-file("megaco_text_parser_prev3c.yrl", 606).
yeccpars2_518_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { andAUDITSelect , 'NULL' }
  end | __Stack].

-compile({inline,yeccpars2_520_/1}).
-file("megaco_text_parser_prev3c.yrl", 593).
yeccpars2_520_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   emergencyAudit
  end | __Stack].

-compile({inline,yeccpars2_522_/1}).
-file("megaco_text_parser_prev3c.yrl", 595).
yeccpars2_522_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   iepsCallind
  end | __Stack].

-compile({inline,yeccpars2_523_/1}).
-file("megaco_text_parser_prev3c.yrl", 607).
yeccpars2_523_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { orAUDITSelect , 'NULL' }
  end | __Stack].

-compile({inline,yeccpars2_524_/1}).
-file("megaco_text_parser_prev3c.yrl", 594).
yeccpars2_524_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   priorityAudit
  end | __Stack].

-compile({inline,yeccpars2_525_/1}).
-file("megaco_text_parser_prev3c.yrl", 592).
yeccpars2_525_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   topologyAudit
  end | __Stack].

-compile({inline,yeccpars2_527_/1}).
-file("megaco_text_parser_prev3c.yrl", 1528).
yeccpars2_527_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   false
  end | __Stack].

-compile({inline,yeccpars2_528_/1}).
-file("megaco_text_parser_prev3c.yrl", 1527).
yeccpars2_528_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   true
  end | __Stack].

-compile({inline,yeccpars2_531_/1}).
-file("megaco_text_parser_prev3c.yrl", 1407).
yeccpars2_531_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_532_/1}).
-file("megaco_text_parser_prev3c.yrl", 596).
yeccpars2_532_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_534_/1}).
-file("megaco_text_parser_prev3c.yrl", 589).
yeccpars2_534_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_538_/1}).
-file("megaco_text_parser_prev3c.yrl", 571).
yeccpars2_538_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_541_/1}).
-file("megaco_text_parser_prev3c.yrl", 571).
yeccpars2_541_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_542_/1}).
-file("megaco_text_parser_prev3c.yrl", 570).
yeccpars2_542_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_543_/1}).
-file("megaco_text_parser_prev3c.yrl", 568).
yeccpars2_543_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __4 | __5 ]
  end | __Stack].

-compile({inline,yeccpars2_546_/1}).
-file("megaco_text_parser_prev3c.yrl", 589).
yeccpars2_546_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_547_/1}).
-file("megaco_text_parser_prev3c.yrl", 588).
yeccpars2_547_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_548_/1}).
-file("megaco_text_parser_prev3c.yrl", 585).
yeccpars2_548_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_549_/1}).
-file("megaco_text_parser_prev3c.yrl", 565).
yeccpars2_549_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { contextList , __3 }
  end | __Stack].

-compile({inline,yeccpars2_550_/1}).
-file("megaco_text_parser_prev3c.yrl", 1405).
yeccpars2_550_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_552_/1}).
-file("megaco_text_parser_prev3c.yrl", 1407).
yeccpars2_552_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_554_/1}).
-file("megaco_text_parser_prev3c.yrl", 1406).
yeccpars2_554_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_555_/1}).
-file("megaco_text_parser_prev3c.yrl", 563).
yeccpars2_555_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { contextProp , __3 }
  end | __Stack].

-compile({inline,yeccpars2_557_/1}).
-file("megaco_text_parser_prev3c.yrl", 579).
yeccpars2_557_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_context_attr_audit_request (
    # 'ContextAttrAuditRequest' { } , [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_558_/1}).
-file("megaco_text_parser_prev3c.yrl", 575).
yeccpars2_558_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_context_attr_audit_request (
    # 'ContextAttrAuditRequest' { } , __3 )
  end | __Stack].

-compile({inline,yeccpars2_561_/1}).
-file("megaco_text_parser_prev3c.yrl", 706).
yeccpars2_561_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_562_/1}).
-file("megaco_text_parser_prev3c.yrl", 709).
yeccpars2_562_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { auditValueRequest , __1 } ,
    make_auditRequest ( __3 , __4 ) )
  end | __Stack].

-compile({inline,yeccpars2_564_/1}).
-file("megaco_text_parser_prev3c.yrl", 706).
yeccpars2_564_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_565_/1}).
-file("megaco_text_parser_prev3c.yrl", 712).
yeccpars2_565_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_commandRequest ( { auditCapRequest , __1 } ,
    make_auditRequest ( __3 , __4 ) )
  end | __Stack].

-compile({inline,yeccpars2_566_/1}).
-file("megaco_text_parser_prev3c.yrl", 541).
yeccpars2_566_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_action_request ( __3 , __5 )
  end | __Stack].

-compile({inline,yeccpars2_567_/1}).
-file("megaco_text_parser_prev3c.yrl", 543).
yeccpars2_567_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_569_/1}).
-file("megaco_text_parser_prev3c.yrl", 547).
yeccpars2_569_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_570_/1}).
-file("megaco_text_parser_prev3c.yrl", 546).
yeccpars2_570_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_572_/1}).
-file("megaco_text_parser_prev3c.yrl", 671).
yeccpars2_572_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_573_/1}).
-file("megaco_text_parser_prev3c.yrl", 661).
yeccpars2_573_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Descs = merge_AmmRequest_descriptors ( __4 , [ ] ) ,
    make_commandRequest ( __1 ,
    # 'AmmRequest' { terminationID = __3 ,
    descriptors = Descs } )
  end | __Stack].

-compile({inline,yeccpars2_575_/1}).
-file("megaco_text_parser_prev3c.yrl", 685).
yeccpars2_575_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_576_/1}).
-file("megaco_text_parser_prev3c.yrl", 682).
yeccpars2_576_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_577_/1}).
-file("megaco_text_parser_prev3c.yrl", 679).
yeccpars2_577_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { muxDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_578_/1}).
-file("megaco_text_parser_prev3c.yrl", 678).
yeccpars2_578_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { modemDescriptor , deprecated }
  end | __Stack].

-compile({inline,yeccpars2_579_/1}).
-file("megaco_text_parser_prev3c.yrl", 677).
yeccpars2_579_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_580_/1}).
-file("megaco_text_parser_prev3c.yrl", 680).
yeccpars2_580_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_581_/1}).
-file("megaco_text_parser_prev3c.yrl", 681).
yeccpars2_581_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_582_/1}).
-file("megaco_text_parser_prev3c.yrl", 683).
yeccpars2_582_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { digitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_583_/1}).
-file("megaco_text_parser_prev3c.yrl", 684).
yeccpars2_583_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_584_/1}).
-file("megaco_text_parser_prev3c.yrl", 674).
yeccpars2_584_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_585_/1}).
-file("megaco_text_parser_prev3c.yrl", 1413).
yeccpars2_585_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_DMD ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_586_/1}).
-file("megaco_text_parser_prev3c.yrl", 1144).
yeccpars2_586_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_587_/1}).
-file("megaco_text_parser_prev3c.yrl", 1181).
yeccpars2_587_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'EventsDescriptor' { requestID = asn1_NOVALUE ,
    eventList = [ ] }
  end | __Stack].

-compile({inline,yeccpars2_591_/1}).
-file("megaco_text_parser_prev3c.yrl", 1277).
yeccpars2_591_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ ]
  end | __Stack].

-compile({inline,yeccpars2_594_/1}).
-file("megaco_text_parser_prev3c.yrl", 1493).
yeccpars2_594_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_595_/1}).
-file("megaco_text_parser_prev3c.yrl", 1497).
yeccpars2_595_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'StatisticsParameter' { statName = __1 ,
    statValue = asn1_NOVALUE }
  end | __Stack].

-compile({inline,yeccpars2_597_/1}).
-file("megaco_text_parser_prev3c.yrl", 1500).
yeccpars2_597_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'StatisticsParameter' { statName = __1 ,
    statValue = [ __3 ] }
  end | __Stack].

-compile({inline,yeccpars2_599_/1}).
-file("megaco_text_parser_prev3c.yrl", 1141).
yeccpars2_599_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_601_/1}).
-file("megaco_text_parser_prev3c.yrl", 1503).
yeccpars2_601_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'StatisticsParameter' { statName = __1 ,
    statValue = [ __4 | __5 ] }
  end | __Stack].

-compile({inline,yeccpars2_604_/1}).
-file("megaco_text_parser_prev3c.yrl", 1493).
yeccpars2_604_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_605_/1}).
-file("megaco_text_parser_prev3c.yrl", 1492).
yeccpars2_605_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_606_/1}).
-file("megaco_text_parser_prev3c.yrl", 1490).
yeccpars2_606_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_608_/1}).
-file("megaco_text_parser_prev3c.yrl", 1283).
yeccpars2_608_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signal , __1 }
  end | __Stack].

-compile({inline,yeccpars2_609_/1}).
-file("megaco_text_parser_prev3c.yrl", 1280).
yeccpars2_609_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_610_/1}).
-file("megaco_text_parser_prev3c.yrl", 1282).
yeccpars2_610_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { seqSigList , __1 }
  end | __Stack].

-compile({inline,yeccpars2_615_/1}).
-file("megaco_text_parser_prev3c.yrl", 1355).
yeccpars2_615_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_618_/1}).
-file("megaco_text_parser_prev3c.yrl", 1355).
yeccpars2_618_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_619_/1}).
-file("megaco_text_parser_prev3c.yrl", 1354).
yeccpars2_619_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_620_/1}).
-file("megaco_text_parser_prev3c.yrl", 1350).
yeccpars2_620_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'SeqSigList' { id = ensure_uint16 ( __3 ) ,
    signalList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_623_/1}).
-file("megaco_text_parser_prev3c.yrl", 1280).
yeccpars2_623_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_624_/1}).
-file("megaco_text_parser_prev3c.yrl", 1279).
yeccpars2_624_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_625_/1}).
-file("megaco_text_parser_prev3c.yrl", 1276).
yeccpars2_625_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_627_/1}).
-file("megaco_text_parser_prev3c.yrl", 1174).
yeccpars2_627_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_muxType ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_629_/1}).
-file("megaco_text_parser_prev3c.yrl", 1171).
yeccpars2_629_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'MuxDescriptor' { muxType = __3 ,
    termList = __4 }
  end | __Stack].

-compile({inline,yeccpars2_631_/1}).
-file("megaco_text_parser_prev3c.yrl", 1032).
yeccpars2_631_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_633_/1}).
-file("megaco_text_parser_prev3c.yrl", 1028).
yeccpars2_633_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_636_/1}).
-file("megaco_text_parser_prev3c.yrl", 0).
yeccpars2_636_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_637_/1}).
-file("megaco_text_parser_prev3c.yrl", 0).
yeccpars2_637_(__Stack0) ->
 [begin
   '$undefined'
  end | __Stack0].

-compile({inline,yeccpars2_640_/1}).
-file("megaco_text_parser_prev3c.yrl", 0).
yeccpars2_640_(__Stack0) ->
 [begin
   '$undefined'
  end | __Stack0].

-compile({inline,yeccpars2_641_/1}).
-file("megaco_text_parser_prev3c.yrl", 0).
yeccpars2_641_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_642_/1}).
-file("megaco_text_parser_prev3c.yrl", 1403).
yeccpars2_642_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_643_/1}).
-file("megaco_text_parser_prev3c.yrl", 0).
yeccpars2_643_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_645_/1}).
-file("megaco_text_parser_prev3c.yrl", 1407).
yeccpars2_645_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_647_/1}).
-file("megaco_text_parser_prev3c.yrl", 1402).
yeccpars2_647_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_648_/1}).
-file("megaco_text_parser_prev3c.yrl", 1403).
yeccpars2_648_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_649_/1}).
-file("megaco_text_parser_prev3c.yrl", 0).
yeccpars2_649_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_651_/1}).
-file("megaco_text_parser_prev3c.yrl", 1053).
yeccpars2_651_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { termState , __1 }
  end | __Stack].

-compile({inline,yeccpars2_652_/1}).
-file("megaco_text_parser_prev3c.yrl", 1049).
yeccpars2_652_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_653_/1}).
-file("megaco_text_parser_prev3c.yrl", 1051).
yeccpars2_653_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { streamDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_654_/1}).
-file("megaco_text_parser_prev3c.yrl", 1064).
yeccpars2_654_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statistics , __1 }
  end | __Stack].

-compile({inline,yeccpars2_655_/1}).
-file("megaco_text_parser_prev3c.yrl", 1043).
yeccpars2_655_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_656_/1}).
-file("megaco_text_parser_prev3c.yrl", 1063).
yeccpars2_656_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { control , __1 }
  end | __Stack].

-compile({inline,yeccpars2_658_/1}).
-file("megaco_text_parser_prev3c.yrl", 1058).
yeccpars2_658_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   PGs = ensure_prop_groups ( __1 ) ,
    { local , # 'LocalRemoteDescriptor' { propGrps = PGs } }
  end | __Stack].

-compile({inline,yeccpars2_659_/1}).
-file("megaco_text_parser_prev3c.yrl", 1061).
yeccpars2_659_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   PGs = ensure_prop_groups ( __1 ) ,
    { remote , # 'LocalRemoteDescriptor' { propGrps = PGs } }
  end | __Stack].

-compile({inline,yeccpars2_663_/1}).
-file("megaco_text_parser_prev3c.yrl", 1086).
yeccpars2_663_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_664_/1}).
-file("megaco_text_parser_prev3c.yrl", 1155).
yeccpars2_664_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { serviceState , __1 }
  end | __Stack].

-compile({inline,yeccpars2_665_/1}).
-file("megaco_text_parser_prev3c.yrl", 1157).
yeccpars2_665_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { propertyParm , __1 }
  end | __Stack].

-compile({inline,yeccpars2_666_/1}).
-file("megaco_text_parser_prev3c.yrl", 1156).
yeccpars2_666_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferControl , __1 }
  end | __Stack].

-compile({inline,yeccpars2_670_/1}).
-file("megaco_text_parser_prev3c.yrl", 1159).
yeccpars2_670_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_672_/1}).
-file("megaco_text_parser_prev3c.yrl", 1165).
yeccpars2_672_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_673_/1}).
-file("megaco_text_parser_prev3c.yrl", 1168).
yeccpars2_673_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lockStep
  end | __Stack].

-compile({inline,yeccpars2_674_/1}).
-file("megaco_text_parser_prev3c.yrl", 1167).
yeccpars2_674_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   off
  end | __Stack].

-compile({inline,yeccpars2_677_/1}).
-file("megaco_text_parser_prev3c.yrl", 1086).
yeccpars2_677_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_678_/1}).
-file("megaco_text_parser_prev3c.yrl", 1085).
yeccpars2_678_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_679_/1}).
-file("megaco_text_parser_prev3c.yrl", 1083).
yeccpars2_679_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_terminationStateDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_683_/1}).
-file("megaco_text_parser_prev3c.yrl", 1072).
yeccpars2_683_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_686_/1}).
-file("megaco_text_parser_prev3c.yrl", 1072).
yeccpars2_686_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_687_/1}).
-file("megaco_text_parser_prev3c.yrl", 1071).
yeccpars2_687_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_688_/1}).
-file("megaco_text_parser_prev3c.yrl", 1068).
yeccpars2_688_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'StreamDescriptor' { streamID = __3 ,
    streamParms = merge_streamParms ( [ __5 | __6 ] ) }
  end | __Stack].

-compile({inline,yeccpars2_690_/1}).
-file("megaco_text_parser_prev3c.yrl", 1092).
yeccpars2_690_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { prop , __1 }
  end | __Stack].

-compile({inline,yeccpars2_691_/1}).
-file("megaco_text_parser_prev3c.yrl", 1078).
yeccpars2_691_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_696_/1}).
-file("megaco_text_parser_prev3c.yrl", 1090).
yeccpars2_696_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { value , __3 }
  end | __Stack].

-compile({inline,yeccpars2_698_/1}).
-file("megaco_text_parser_prev3c.yrl", 1089).
yeccpars2_698_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { group , __3 }
  end | __Stack].

-compile({inline,yeccpars2_700_/1}).
-file("megaco_text_parser_prev3c.yrl", 1091).
yeccpars2_700_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { mode , __3 }
  end | __Stack].

-compile({inline,yeccpars2_703_/1}).
-file("megaco_text_parser_prev3c.yrl", 1078).
yeccpars2_703_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_704_/1}).
-file("megaco_text_parser_prev3c.yrl", 1077).
yeccpars2_704_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_705_/1}).
-file("megaco_text_parser_prev3c.yrl", 1075).
yeccpars2_705_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_708_/1}).
-file("megaco_text_parser_prev3c.yrl", 1043).
yeccpars2_708_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_709_/1}).
-file("megaco_text_parser_prev3c.yrl", 1042).
yeccpars2_709_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_710_/1}).
-file("megaco_text_parser_prev3c.yrl", 1040).
yeccpars2_710_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_mediaDescriptor ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_714_/1}).
-file("megaco_text_parser_prev3c.yrl", 1189).
yeccpars2_714_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_715_/1}).
-file("megaco_text_parser_prev3c.yrl", 1196).
yeccpars2_715_(__Stack0) ->
 [begin
   # 'RequestedEvent' { evParList = [ ] }
  end | __Stack0].

-compile({inline,yeccpars2_716_/1}).
-file("megaco_text_parser_prev3c.yrl", 1192).
yeccpars2_716_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'RequestedEvent' .pkgdName , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_718_/1}).
-file("megaco_text_parser_prev3c.yrl", 1208).
yeccpars2_718_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { notifyRegulated , __1 }
  end | __Stack].

-compile({inline,yeccpars2_719_/1}).
-file("megaco_text_parser_prev3c.yrl", 1220).
yeccpars2_719_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { notifyBehaviour , __1 }
  end | __Stack].

-compile({inline,yeccpars2_721_/1}).
-file("megaco_text_parser_prev3c.yrl", 1212).
yeccpars2_721_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_725_/1}).
-file("megaco_text_parser_prev3c.yrl", 1272).
yeccpars2_725_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_eventDM ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_727_COMMA/1}).
-file("megaco_text_parser_prev3c.yrl", 1215).
yeccpars2_727_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_727_RBRKT/1}).
-file("megaco_text_parser_prev3c.yrl", 1215).
yeccpars2_727_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_728_/1}).
-file("megaco_text_parser_prev3c.yrl", 1207).
yeccpars2_728_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { neverNotify , 'NULL' }
  end | __Stack].

-compile({inline,yeccpars2_729_/1}).
-file("megaco_text_parser_prev3c.yrl", 1206).
yeccpars2_729_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { notifyImmediate , 'NULL' }
  end | __Stack].

-compile({inline,yeccpars2_730_/1}).
-file("megaco_text_parser_prev3c.yrl", 1200).
yeccpars2_730_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'RegulatedEmbeddedDescriptor' { }
  end | __Stack].

-compile({inline,yeccpars2_731_/1}).
-file("megaco_text_parser_prev3c.yrl", 1221).
yeccpars2_731_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   resetEventsDescriptor
  end | __Stack].

-compile({inline,yeccpars2_739_/1}).
-file("megaco_text_parser_prev3c.yrl", 1233).
yeccpars2_739_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'SecondEventsDescriptor' { requestID = asn1_NOVALUE ,
    eventList = [ ] }
  end | __Stack].

-compile({inline,yeccpars2_743_/1}).
-file("megaco_text_parser_prev3c.yrl", 1241).
yeccpars2_743_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_744_/1}).
-file("megaco_text_parser_prev3c.yrl", 1249).
yeccpars2_744_(__Stack0) ->
 [begin
   # 'SecondRequestedEvent' { evParList = [ ] }
  end | __Stack0].

-compile({inline,yeccpars2_745_/1}).
-file("megaco_text_parser_prev3c.yrl", 1245).
yeccpars2_745_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'SecondRequestedEvent' .pkgdName , __2 , __1 )
  end | __Stack].

-compile({inline,yeccpars2_747_/1}).
-file("megaco_text_parser_prev3c.yrl", 1252).
yeccpars2_747_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_748_/1}).
-file("megaco_text_parser_prev3c.yrl", 1259).
yeccpars2_748_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { notifyBehaviour , __1 }
  end | __Stack].

-compile({inline,yeccpars2_753_COMMA/1}).
-file("megaco_text_parser_prev3c.yrl", 1255).
yeccpars2_753_COMMA(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_753_RBRKT/1}).
-file("megaco_text_parser_prev3c.yrl", 1255).
yeccpars2_753_RBRKT(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   keepActive
  end | __Stack].

-compile({inline,yeccpars2_754_/1}).
-file("megaco_text_parser_prev3c.yrl", 1260).
yeccpars2_754_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   resetEventsDescriptor
  end | __Stack].

-compile({inline,yeccpars2_757_/1}).
-file("megaco_text_parser_prev3c.yrl", 1263).
yeccpars2_757_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { second_embed , __3 }
  end | __Stack].

-compile({inline,yeccpars2_760_/1}).
-file("megaco_text_parser_prev3c.yrl", 1252).
yeccpars2_760_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_761_/1}).
-file("megaco_text_parser_prev3c.yrl", 1251).
yeccpars2_761_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_762_/1}).
-file("megaco_text_parser_prev3c.yrl", 1248).
yeccpars2_762_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_secondEventParameters ( [ __2 | __3 ] )
  end | __Stack].

-compile({inline,yeccpars2_765_/1}).
-file("megaco_text_parser_prev3c.yrl", 1241).
yeccpars2_765_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_766_/1}).
-file("megaco_text_parser_prev3c.yrl", 1240).
yeccpars2_766_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_767_/1}).
-file("megaco_text_parser_prev3c.yrl", 1237).
yeccpars2_767_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'SecondEventsDescriptor' { requestID = __3 ,
    eventList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_768_/1}).
-file("megaco_text_parser_prev3c.yrl", 1230).
yeccpars2_768_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , asn1_NOVALUE , __3 }
  end | __Stack].

-compile({inline,yeccpars2_770_/1}).
-file("megaco_text_parser_prev3c.yrl", 1227).
yeccpars2_770_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , __3 , asn1_NOVALUE }
  end | __Stack].

-compile({inline,yeccpars2_772_/1}).
-file("megaco_text_parser_prev3c.yrl", 1225).
yeccpars2_772_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { embed , __3 , __5 }
  end | __Stack].

-compile({inline,yeccpars2_773_/1}).
-file("megaco_text_parser_prev3c.yrl", 1204).
yeccpars2_773_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_RegulatedEmbeddedDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_774_/1}).
-file("megaco_text_parser_prev3c.yrl", 1202).
yeccpars2_774_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_RegulatedEmbeddedDescriptor ( __3 )
  end | __Stack].

-compile({inline,yeccpars2_777_/1}).
-file("megaco_text_parser_prev3c.yrl", 1212).
yeccpars2_777_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_778_/1}).
-file("megaco_text_parser_prev3c.yrl", 1211).
yeccpars2_778_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_779_/1}).
-file("megaco_text_parser_prev3c.yrl", 1195).
yeccpars2_779_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_eventParameters ( [ __2 | __3 ] )
  end | __Stack].

-compile({inline,yeccpars2_782_/1}).
-file("megaco_text_parser_prev3c.yrl", 1189).
yeccpars2_782_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_783_/1}).
-file("megaco_text_parser_prev3c.yrl", 1188).
yeccpars2_783_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_784_/1}).
-file("megaco_text_parser_prev3c.yrl", 1185).
yeccpars2_784_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'EventsDescriptor' { requestID = __3 ,
    eventList = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_785_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_785_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_786_/1}).
-file("megaco_text_parser_prev3c.yrl", 1152).
yeccpars2_786_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_eventSpec ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_787_/1}).
-file("megaco_text_parser_prev3c.yrl", 1150).
yeccpars2_787_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_789_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_789_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_790_/1}).
-file("megaco_text_parser_prev3c.yrl", 1150).
yeccpars2_790_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_791_/1}).
-file("megaco_text_parser_prev3c.yrl", 1149).
yeccpars2_791_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_792_/1}).
-file("megaco_text_parser_prev3c.yrl", 1147).
yeccpars2_792_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_795_/1}).
-file("megaco_text_parser_prev3c.yrl", 674).
yeccpars2_795_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_796_/1}).
-file("megaco_text_parser_prev3c.yrl", 673).
yeccpars2_796_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_797_/1}).
-file("megaco_text_parser_prev3c.yrl", 670).
yeccpars2_797_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_800_/1}).
-file("megaco_text_parser_prev3c.yrl", 530).
yeccpars2_800_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_801_/1}).
-file("megaco_text_parser_prev3c.yrl", 529).
yeccpars2_801_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_802_/1}).
-file("megaco_text_parser_prev3c.yrl", 518).
yeccpars2_802_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = asn1_NOVALUE ,
    actions = [ __3 | __4 ] }
  end | __Stack].

-compile({inline,yeccpars2_804_/1}).
-file("megaco_text_parser_prev3c.yrl", 992).
yeccpars2_804_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint32 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_806_/1}).
-file("megaco_text_parser_prev3c.yrl", 530).
yeccpars2_806_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_808_/1}).
-file("megaco_text_parser_prev3c.yrl", 522).
yeccpars2_808_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = asn1_NOVALUE ,
    actions = [ __4 | __5 ] }
  end | __Stack].

-compile({inline,yeccpars2_810_/1}).
-file("megaco_text_parser_prev3c.yrl", 530).
yeccpars2_810_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_812_/1}).
-file("megaco_text_parser_prev3c.yrl", 526).
yeccpars2_812_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionRequest' { transactionId = ensure_transactionID ( __3 ) ,
    actions = [ __5 | __6 ] }
  end | __Stack].

-compile({inline,yeccpars2_814_/1}).
-file("megaco_text_parser_prev3c.yrl", 509).
yeccpars2_814_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_815_/1}).
-file("megaco_text_parser_prev3c.yrl", 511).
yeccpars2_815_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_transactionAck ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_818_/1}).
-file("megaco_text_parser_prev3c.yrl", 509).
yeccpars2_818_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_819_/1}).
-file("megaco_text_parser_prev3c.yrl", 508).
yeccpars2_819_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_820_/1}).
-file("megaco_text_parser_prev3c.yrl", 505).
yeccpars2_820_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_823_/1}).
-file("megaco_text_parser_prev3c.yrl", 624).
yeccpars2_823_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_826_/1}).
-file("megaco_text_parser_prev3c.yrl", 623).
yeccpars2_826_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   'NULL'
  end | __Stack].

-compile({inline,yeccpars2_828_/1}).
-file("megaco_text_parser_prev3c.yrl", 626).
yeccpars2_828_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { transactionError , __1 }
  end | __Stack].

-compile({inline,yeccpars2_829_/1}).
-file("megaco_text_parser_prev3c.yrl", 630).
yeccpars2_829_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_832_/1}).
-file("megaco_text_parser_prev3c.yrl", 636).
yeccpars2_832_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'ActionReply' { contextId = __3 }
  end | __Stack].

-compile({inline,yeccpars2_834_/1}).
-file("megaco_text_parser_prev3c.yrl", 653).
yeccpars2_834_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_835_/1}).
-file("megaco_text_parser_prev3c.yrl", 656).
yeccpars2_835_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_836_/1}).
-file("megaco_text_parser_prev3c.yrl", 639).
yeccpars2_836_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   # 'ActionReply' { errorDescriptor = __1 }
  end | __Stack].

-compile({inline,yeccpars2_837_/1}).
-file("megaco_text_parser_prev3c.yrl", 657).
yeccpars2_837_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { context , __1 }
  end | __Stack].

-compile({inline,yeccpars2_838_/1}).
-file("megaco_text_parser_prev3c.yrl", 651).
yeccpars2_838_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_839_/1}).
-file("megaco_text_parser_prev3c.yrl", 654).
yeccpars2_839_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_841_/1}).
-file("megaco_text_parser_prev3c.yrl", 655).
yeccpars2_841_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { command , __1 }
  end | __Stack].

-compile({inline,yeccpars2_843_/1}).
-file("megaco_text_parser_prev3c.yrl", 691).
yeccpars2_843_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   addReply
  end | __Stack].

-compile({inline,yeccpars2_846_/1}).
-file("megaco_text_parser_prev3c.yrl", 693).
yeccpars2_846_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modReply
  end | __Stack].

-compile({inline,yeccpars2_847_/1}).
-file("megaco_text_parser_prev3c.yrl", 692).
yeccpars2_847_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   moveReply
  end | __Stack].

-compile({inline,yeccpars2_850_/1}).
-file("megaco_text_parser_prev3c.yrl", 694).
yeccpars2_850_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   subtractReply
  end | __Stack].

-compile({inline,yeccpars2_852_/1}).
-file("megaco_text_parser_prev3c.yrl", 980).
yeccpars2_852_(__Stack0) ->
 [begin
   { serviceChangeResParms , # 'ServiceChangeResParm' { } }
  end | __Stack0].

-compile({inline,yeccpars2_853_/1}).
-file("megaco_text_parser_prev3c.yrl", 971).
yeccpars2_853_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceChangeReply ,
    # 'ServiceChangeReply' { terminationID = __3 ,
    serviceChangeResult = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_859_/1}).
-file("megaco_text_parser_prev3c.yrl", 1474).
yeccpars2_859_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { time_stamp , __1 }
  end | __Stack].

-compile({inline,yeccpars2_860_/1}).
-file("megaco_text_parser_prev3c.yrl", 1473).
yeccpars2_860_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { version , __1 }
  end | __Stack].

-compile({inline,yeccpars2_861_/1}).
-file("megaco_text_parser_prev3c.yrl", 1472).
yeccpars2_861_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { profile , __1 }
  end | __Stack].

-compile({inline,yeccpars2_862_/1}).
-file("megaco_text_parser_prev3c.yrl", 1471).
yeccpars2_862_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mgc_id , __1 }
  end | __Stack].

-compile({inline,yeccpars2_863_/1}).
-file("megaco_text_parser_prev3c.yrl", 1470).
yeccpars2_863_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { address , __1 }
  end | __Stack].

-compile({inline,yeccpars2_864_/1}).
-file("megaco_text_parser_prev3c.yrl", 1468).
yeccpars2_864_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_871_/1}).
-file("megaco_text_parser_prev3c.yrl", 1468).
yeccpars2_871_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_872_/1}).
-file("megaco_text_parser_prev3c.yrl", 1467).
yeccpars2_872_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_873_/1}).
-file("megaco_text_parser_prev3c.yrl", 1464).
yeccpars2_873_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_ServiceChangeResParm ( [ __3 | __4 ] )
  end | __Stack].

-compile({inline,yeccpars2_874_/1}).
-file("megaco_text_parser_prev3c.yrl", 976).
yeccpars2_874_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { errorDescriptor , __2 }
  end | __Stack].

-compile({inline,yeccpars2_875_/1}).
-file("megaco_text_parser_prev3c.yrl", 978).
yeccpars2_875_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { serviceChangeResParms , __2 }
  end | __Stack].

-compile({inline,yeccpars2_877_/1}).
-file("megaco_text_parser_prev3c.yrl", 961).
yeccpars2_877_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_878_/1}).
-file("megaco_text_parser_prev3c.yrl", 957).
yeccpars2_878_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { notifyReply , # 'NotifyReply' { terminationID = __3 ,
    errorDescriptor = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_881_/1}).
-file("megaco_text_parser_prev3c.yrl", 960).
yeccpars2_881_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_883_/1}).
-file("megaco_text_parser_prev3c.yrl", 730).
yeccpars2_883_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   merge_auditOther ( __1 , [ ] )
  end | __Stack].

-compile({inline,yeccpars2_884_/1}).
-file("megaco_text_parser_prev3c.yrl", 720).
yeccpars2_884_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditValueReply , __3 }
  end | __Stack].

-compile({inline,yeccpars2_886_/1}).
-file("megaco_text_parser_prev3c.yrl", 725).
yeccpars2_886_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { contextAuditResult , __1 }
  end | __Stack].

-compile({inline,yeccpars2_887_/1}).
-file("megaco_text_parser_prev3c.yrl", 716).
yeccpars2_887_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditValueReply , __4 }
  end | __Stack].

-compile({inline,yeccpars2_892_/1}).
-file("megaco_text_parser_prev3c.yrl", 987).
yeccpars2_892_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_uint ( __1 , 0 , 999 )
  end | __Stack].

-compile({inline,yeccpars2_894_/1}).
-file("megaco_text_parser_prev3c.yrl", 990).
yeccpars2_894_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_896_/1}).
-file("megaco_text_parser_prev3c.yrl", 989).
yeccpars2_896_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   value_of ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_897_/1}).
-file("megaco_text_parser_prev3c.yrl", 984).
yeccpars2_897_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'ErrorDescriptor' { errorCode = __3 ,
    errorText = __5 }
  end | __Stack].

-compile({inline,yeccpars2_898_/1}).
-file("megaco_text_parser_prev3c.yrl", 727).
yeccpars2_898_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { error , __2 }
  end | __Stack].

-compile({inline,yeccpars2_901_/1}).
-file("megaco_text_parser_prev3c.yrl", 749).
yeccpars2_901_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { statisticsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_902_/1}).
-file("megaco_text_parser_prev3c.yrl", 745).
yeccpars2_902_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { signalsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_903_/1}).
-file("megaco_text_parser_prev3c.yrl", 750).
yeccpars2_903_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { packagesDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_904_/1}).
-file("megaco_text_parser_prev3c.yrl", 747).
yeccpars2_904_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { observedEventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_905_/1}).
-file("megaco_text_parser_prev3c.yrl", 743).
yeccpars2_905_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { muxDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_906_/1}).
-file("megaco_text_parser_prev3c.yrl", 0).
yeccpars2_906_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   '$undefined'
  end | __Stack].

-compile({inline,yeccpars2_907_/1}).
-file("megaco_text_parser_prev3c.yrl", 741).
yeccpars2_907_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { mediaDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_908_/1}).
-file("megaco_text_parser_prev3c.yrl", 744).
yeccpars2_908_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventsDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_909_/1}).
-file("megaco_text_parser_prev3c.yrl", 748).
yeccpars2_909_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { eventBufferDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_910_/1}).
-file("megaco_text_parser_prev3c.yrl", 751).
yeccpars2_910_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { errorDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_911_/1}).
-file("megaco_text_parser_prev3c.yrl", 746).
yeccpars2_911_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { digitMapDescriptor , __1 }
  end | __Stack].

-compile({inline,yeccpars2_912_/1}).
-file("megaco_text_parser_prev3c.yrl", 739).
yeccpars2_912_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_913_/1}).
-file("megaco_text_parser_prev3c.yrl", 752).
yeccpars2_913_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { auditReturnItem , __1 }
  end | __Stack].

-compile({inline,yeccpars2_914_/1}).
-file("megaco_text_parser_prev3c.yrl", 767).
yeccpars2_914_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   mediaToken
  end | __Stack].

-compile({inline,yeccpars2_915_/1}).
-file("megaco_text_parser_prev3c.yrl", 766).
yeccpars2_915_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   modemToken
  end | __Stack].

-compile({inline,yeccpars2_916_/1}).
-file("megaco_text_parser_prev3c.yrl", 765).
yeccpars2_916_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   muxToken
  end | __Stack].

-compile({inline,yeccpars2_917_/1}).
-file("megaco_text_parser_prev3c.yrl", 770).
yeccpars2_917_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   observedEventsToken
  end | __Stack].

-compile({inline,yeccpars2_918_/1}).
-file("megaco_text_parser_prev3c.yrl", 771).
yeccpars2_918_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   packagesToken
  end | __Stack].

-compile({inline,yeccpars2_919_/1}).
-file("megaco_text_parser_prev3c.yrl", 769).
yeccpars2_919_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statsToken
  end | __Stack].

-compile({inline,yeccpars2_921_/1}).
-file("megaco_text_parser_prev3c.yrl", 1481).
yeccpars2_921_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_924_/1}).
-file("megaco_text_parser_prev3c.yrl", 1481).
yeccpars2_924_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_925_/1}).
-file("megaco_text_parser_prev3c.yrl", 1480).
yeccpars2_925_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_926_/1}).
-file("megaco_text_parser_prev3c.yrl", 1478).
yeccpars2_926_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __4 ]
  end | __Stack].

-compile({inline,yeccpars2_927_/1}).
-file("megaco_text_parser_prev3c.yrl", 736).
yeccpars2_927_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_terminationAudit ( [ __1 | __2 ] )
  end | __Stack].

-compile({inline,yeccpars2_929_/1}).
-file("megaco_text_parser_prev3c.yrl", 739).
yeccpars2_929_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_930_/1}).
-file("megaco_text_parser_prev3c.yrl", 738).
yeccpars2_930_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_931_/1}).
-file("megaco_text_parser_prev3c.yrl", 732).
yeccpars2_931_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   merge_auditOther ( __1 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_933_/1}).
-file("megaco_text_parser_prev3c.yrl", 722).
yeccpars2_933_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditCapReply , __3 }
  end | __Stack].

-compile({inline,yeccpars2_935_/1}).
-file("megaco_text_parser_prev3c.yrl", 718).
yeccpars2_935_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { auditCapReply , __4 }
  end | __Stack].

-compile({inline,yeccpars2_936_/1}).
-file("megaco_text_parser_prev3c.yrl", 634).
yeccpars2_936_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   setelement ( # 'ActionReply' .contextId , __5 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_938_/1}).
-file("megaco_text_parser_prev3c.yrl", 697).
yeccpars2_938_(__Stack0) ->
 [begin
   asn1_NOVALUE
  end | __Stack0].

-compile({inline,yeccpars2_939_/1}).
-file("megaco_text_parser_prev3c.yrl", 688).
yeccpars2_939_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { __1 , # 'AmmsReply' { terminationID = __3 ,
    terminationAudit = __4 } }
  end | __Stack].

-compile({inline,yeccpars2_942_/1}).
-file("megaco_text_parser_prev3c.yrl", 696).
yeccpars2_942_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_943_/1}).
-file("megaco_text_parser_prev3c.yrl", 641).
yeccpars2_943_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   merge_action_reply ( [ __1 | __2 ] )
  end | __Stack].

-compile({inline,yeccpars2_945_/1}).
-file("megaco_text_parser_prev3c.yrl", 648).
yeccpars2_945_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ { error , __2 } ]
  end | __Stack].

-compile({inline,yeccpars2_946_/1}).
-file("megaco_text_parser_prev3c.yrl", 651).
yeccpars2_946_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_947_/1}).
-file("megaco_text_parser_prev3c.yrl", 650).
yeccpars2_947_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_948_/1}).
-file("megaco_text_parser_prev3c.yrl", 627).
yeccpars2_948_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { actionReplies , [ __1 | __2 ] }
  end | __Stack].

-compile({inline,yeccpars2_950_/1}).
-file("megaco_text_parser_prev3c.yrl", 630).
yeccpars2_950_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_951_/1}).
-file("megaco_text_parser_prev3c.yrl", 629).
yeccpars2_951_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __3 ]
  end | __Stack].

-compile({inline,yeccpars2_952_/1}).
-file("megaco_text_parser_prev3c.yrl", 619).
yeccpars2_952_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionReply' { transactionId = __3 ,
    immAckRequired = __5 ,
    transactionResult = __6 }
  end | __Stack].

-compile({inline,yeccpars2_956_/1}).
-file("megaco_text_parser_prev3c.yrl", 514).
yeccpars2_956_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   # 'TransactionPending' { transactionId = ensure_transactionID ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_957_/1}).
-file("megaco_text_parser_prev3c.yrl", 496).
yeccpars2_957_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_958_/1}).
-file("megaco_text_parser_prev3c.yrl", 1035).
yeccpars2_958_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_pathName ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_959_/1}).
-file("megaco_text_parser_prev3c.yrl", 1004).
yeccpars2_959_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { deviceName , __1 }
  end | __Stack].

-compile({inline,yeccpars2_960_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_960_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_961_/1}).
-file("megaco_text_parser_prev3c.yrl", 482).
yeccpars2_961_(__Stack0) ->
 [begin
   no_sep
  end | __Stack0].

-compile({inline,yeccpars2_962_/1}).
-file("megaco_text_parser_prev3c.yrl", 1021).
yeccpars2_962_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_mtpAddress ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_963_/1}).
-file("megaco_text_parser_prev3c.yrl", 997).
yeccpars2_963_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_964_/1}).
-file("megaco_text_parser_prev3c.yrl", 996).
yeccpars2_964_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].


-file("megaco_text_parser_prev3c.yrl", 1674).
