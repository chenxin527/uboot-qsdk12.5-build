-module(snmpc_mib_gram).
-export([parse/1, parse_and_scan/1, format_error/1]).
-file("snmpc_mib_gram.yrl", 751).
%%----------------------------------------------------------------------

-include("snmp_types.hrl").
-include("snmpc_lib.hrl").
-include("snmpc.hrl").

% value
val(Token) -> element(3, Token).

line_of(Token) -> element(2, Token).

%% category
cat(Token) -> element(1, Token). 

statusv1(Tok) ->
    case val(Tok) of
        mandatory -> mandatory;
        optional -> optional;
        obsolete -> obsolete;
        deprecated -> deprecated;
        Else -> return_error(line_of(Tok),
                             "(statusv1) syntax error before: " ++ atom_to_list(Else))
    end.

statusv2(Tok) ->
    case val(Tok) of
        current -> current;
        deprecated -> deprecated;
        obsolete -> obsolete;
        Else -> return_error(line_of(Tok),
                             "(statusv2) syntax error before: " ++ atom_to_list(Else))
    end.

ac_status(Tok) ->
    case val(Tok) of
        current -> current;
        obsolete -> obsolete;
        Else -> return_error(line_of(Tok),
                             "(ac_status) syntax error before: " ++ atom_to_list(Else))
    end.

accessv1(Tok) ->
    case val(Tok) of
        'read-only' -> 'read-only';
        'read-write' -> 'read-write';
        'write-only' -> 'write-only';
        'not-accessible' -> 'not-accessible';
        Else -> return_error(line_of(Tok),
                             "(accessv1) syntax error before: " ++ atom_to_list(Else))
    end.

accessv2(Tok) ->
    case val(Tok) of
        'not-accessible' -> 'not-accessible';
        'accessible-for-notify' -> 'accessible-for-notify';
        'read-only' -> 'read-only';
        'read-write' -> 'read-write';
        'read-create' -> 'read-create';
        Else -> return_error(line_of(Tok),
                             "(accessv2) syntax error before: " ++ atom_to_list(Else))
    end.

ac_access(Tok) ->
    case val(Tok) of
        'not-implemented' -> 'not-implemented'; % only for notifications
        'accessible-for-notify' -> 'accessible-for-notify';
        'read-only' -> 'read-only';
        'read-write' -> 'read-write';
        'read-create' -> 'read-create';
        'write-only' -> 'write-only'; % for backward-compatibility only
        Else -> return_error(line_of(Tok),
                             "(ac_access) syntax error before: " ++ atom_to_list(Else))
    end.

%% ---------------------------------------------------------------------
%% Various basic record build functions
%% ---------------------------------------------------------------------

make_module_identity(Name, LU, Org, CI, Desc, Revs, NA) ->
    #mc_module_identity{name         = Name,
                        last_updated = LU,
	                organization = Org,
	                contact_info = CI,
	                description  = Desc,
	                revisions    = Revs, 
	                name_assign  = NA}.

make_revision(Rev, Desc) ->
    #mc_revision{revision    = Rev,
	         description = Desc}.

make_object_type(Name, Syntax, MaxAcc, Status, Desc, Ref, Kind, NA) ->
    #mc_object_type{name        = Name,
                    syntax      = Syntax,
	            max_access  = MaxAcc,
	            status      = Status,
	            description = Desc,
	            reference   = Ref,
	            kind        = Kind, 
	            name_assign = NA}.

make_object_type(Name, Syntax, Units, MaxAcc, Status, Desc, Ref, Kind, NA) ->
    #mc_object_type{name        = Name,
                    syntax      = Syntax, 
                    units       = Units, 
	            max_access  = MaxAcc,
	            status      = Status,
	            description = Desc,
	            reference   = Ref,
	            kind        = Kind, 
	            name_assign = NA}.

make_new_type(Name, Macro, Syntax) ->
    #mc_new_type{name   = Name, 
	         macro  = Macro,
                 syntax = Syntax}.

make_new_type(Name, Macro, DisplayHint, Status, Desc, Ref, Syntax) ->
    #mc_new_type{name         = Name, 
	         macro        = Macro,
                 status       = Status,
                 description  = Desc,
                 reference    = Ref,
	         display_hint = DisplayHint,
                 syntax       = Syntax}.

make_trap(Name, Ent, Vars, Desc, Ref, Num) ->
    #mc_trap{name        = Name,
             enterprise  = Ent,
             vars        = Vars,
             description = Desc,
	     reference   = Ref,
	     num         = Num}.

make_notification(Name, Vars, Status, Desc, Ref, NA) ->
    #mc_notification{name        = Name,
                     vars        = Vars,
                     status      = Status,
                     description = Desc,
	             reference   = Ref,
	             name_assign = NA}.

make_agent_capabilities(Name, ProdRel, Status, Desc, Ref, Mods, NA) ->
    #mc_agent_capabilities{name            = Name,
                           product_release = ProdRel,
                           status          = Status,
                           description     = Desc,
	                   reference       = Ref,
                           modules         = Mods,
	                   name_assign     = NA}.

make_ac_variation(Name, 
		  undefined = _Syntax, 
		  undefined = _WriteSyntax, 
		  Access, 
		  undefined = _Creation, 
		  undefined = _DefVal, 
		  Desc) ->
%%     io:format("make_ac_variation -> entry with"
%% 	      "~n   Name:        ~p"
%% 	      "~n   Access:      ~p"
%% 	      "~n   Desc:        ~p"
%% 	      "~n", [Name, Access, Desc]),
    #mc_ac_notification_variation{name        = Name, 
 				  access      = Access,
 				  description = Desc};

make_ac_variation(Name, Syntax, WriteSyntax, Access, Creation, DefVal, Desc) ->
%%     io:format("make_ac_variation -> entry with"
%% 	      "~n   Name:        ~p"
%% 	      "~n   Syntax:      ~p"
%% 	      "~n   WriteSyntax: ~p"
%% 	      "~n   Access:      ~p"
%% 	      "~n   Creation:    ~p"
%% 	      "~n   DefVal:      ~p"
%% 	      "~n   Desc:        ~p"
%% 	      "~n", [Name, Syntax, WriteSyntax, Access, Creation, DefVal, Desc]),
    #mc_ac_object_variation{name          = Name, 
			    syntax        = Syntax, 
			    write_syntax  = WriteSyntax, 
			    access        = Access,
			    creation      = Creation,
			    default_value = DefVal,
			    description   = Desc}.

make_ac_module(Name, Grps, Var) ->
    #mc_ac_module{name      = Name, 
		  groups    = Grps,
		  variation = Var}.


make_module_compliance(Name, Status, Desc, Ref, Mods, NA) ->
    #mc_module_compliance{name        = Name,
                          status      = Status,
                          description = Desc,
	                  reference   = Ref,
                          modules     = Mods,
	                  name_assign = NA}.

make_mc_module(Name, Mand, Compl) ->
    #mc_mc_module{name       = Name, 
		  mandatory  = Mand,
		  compliance = Compl}.

make_mc_compliance_group(Name, Desc) ->
    #mc_mc_compliance_group{name        = Name,
			    description = Desc}.

make_mc_object(Name, Syntax, WriteSyntax, Access, Desc) ->
    #mc_mc_object{name         = Name,
		  syntax       = Syntax,
		  write_syntax = WriteSyntax,
		  access       = Access, 
		  description  = Desc}.

make_object_group(Name, Objs, Status, Desc, Ref, NA) ->
    #mc_object_group{name        = Name,
                     objects     = Objs,
                     status      = Status,
                     description = Desc,
	             reference   = Ref,
	             name_assign = NA}.

make_notification_group(Name, Objs, Status, Desc, Ref, NA) ->
    #mc_notification_group{name        = Name,
                           objects     = Objs,
                           status      = Status,
                           description = Desc,
	                   reference   = Ref,
	                   name_assign = NA}.

make_sequence(Name, Fields) ->
    #mc_sequence{name   = Name, 
                 fields = Fields}.

make_internal(Name, Macro, Parent, SubIdx) ->
    #mc_internal{name      = Name, 
                 macro     = Macro, 
                 parent    = Parent, 
                 sub_index = SubIdx}.



%% ---------------------------------------------------------------------


%%----------------------------------------------------------------------
%% Purpose: Find how much room needs to be allocated for the data type
%%          (when sending it in a PDU (the maximum difference will be 
%%           the size allocated)).
%%          This is applicable for OCTET STRINGs and OBJECT IDENTIFIERs.
%%
%%     Or : Find the range of integers in the integer list.
%%          This is applicable for INTEGERs
%%
%% Arg: A list of integers.
%%----------------------------------------------------------------------

make_range_integer(RevHexStr, h) ->
    erlang:list_to_integer(lists:reverse(RevHexStr), 16);
make_range_integer(RevHexStr, 'H') ->
    erlang:list_to_integer(lists:reverse(RevHexStr), 16);
make_range_integer(RevBitStr, b) ->
    erlang:list_to_integer(lists:reverse(RevBitStr), 2);
make_range_integer(RevBitStr, 'B') ->
    erlang:list_to_integer(lists:reverse(RevBitStr), 2);
make_range_integer(RevStr, Base) ->
    throw({error, {invalid_base, Base, lists:reverse(RevStr)}}).

make_range(XIntList) ->
    IntList = lists:flatten(XIntList),
    {range, lists:min(IntList), lists:max(IntList)}.

make_defval_for_string(Line, Str, Atom) ->
    case lists:member(Atom, [h, 'H', b, 'B']) of
	true ->
	    case catch make_defval_for_string2(Str, Atom) of
		Defval when is_list(Defval) ->
		    Defval;
		{error, ErrStr} ->
		    snmpc_lib:print_error("Bad DEFVAL ~w string ~p - ~s",
						 [Atom, Str, ErrStr],
						 Line),
		    "";
		_Else ->
		    snmpc_lib:print_error("Bad DEFVAL ~w string ~p",
						 [Atom, Str],
						 Line),
		    ""
	    end;
	false ->
	    snmpc_lib:print_error("Bad DEFVAL string type ~w for ~p",
					 [Atom, Str],
					 Line),
	    ""
    end.
	    

make_defval_for_string2([], h) -> [];
make_defval_for_string2([X16,X|HexString], h) ->
    lists:append(hex_to_bytes(snmpc_misc:to_upper([X16,X])),
		 make_defval_for_string2(HexString, h));
make_defval_for_string2([_Odd], h) ->
    throw({error, "odd number of bytes in hex string"});
make_defval_for_string2(HexString, 'H') ->
    make_defval_for_string2(HexString,h);

make_defval_for_string2(BitString, 'B') ->
    bits_to_bytes(BitString);
make_defval_for_string2(BitString, b) ->
    make_defval_for_string2(BitString, 'B').

bits_to_bytes(BitStr) ->
    lists:reverse(bits_to_bytes(lists:reverse(BitStr), 1, 0)).

bits_to_bytes([], 1, _Byte) ->   % empty bitstring
    [];
bits_to_bytes([], 256, _Byte) -> % correct; multiple of 8
    [];
% If we are to support arbitrary length of bitstrings.  This migth
% be needed in the new SMI.
%bits_to_bytes([], N, Byte) ->
%    [Byte];
bits_to_bytes([], _N, _Byte) ->
    throw({error, "not a multiple of eight bits in bitstring"});
bits_to_bytes(Rest, 256, Byte) ->
    [Byte | bits_to_bytes(Rest, 1, 0)];
bits_to_bytes([$1 | T], N, Byte) ->
    bits_to_bytes(T, N*2, N + Byte);
bits_to_bytes([$0 | T], N, Byte) ->
    bits_to_bytes(T, N*2, Byte);
bits_to_bytes([_BadChar | _T], _N, _Byte) ->
    throw({error, "bad character in bit string"}).

%%----------------------------------------------------------------------
%% These HEX conversion routines are stolen from module asn1_bits by 
%% klacke@erix.ericsson.se
%% I didn't want to ship the entire asn1-compiler so I used cut-and-paste.
%%----------------------------------------------------------------------

%% hex_to_bytes(HexNumber) when is_atom(HexNumber) ->
%%     hex_to_bytes(atom_to_list(HexNumber));

hex_to_bytes(HexNumber) ->
    case length(HexNumber) rem 2 of
	1 ->  %% Odd
	    hex_to_bytes(lists:append(HexNumber,[$0]),[]);
	0 ->  %% even
	    hex_to_bytes(HexNumber,[])
    end.

hex_to_bytes([],R) ->
    lists:reverse(R);
hex_to_bytes([Hi,Lo|Rest],Res) ->
    hex_to_bytes(Rest,[hex_to_byte(Hi,Lo)|Res]).

hex_to_four_bits(Hex) ->
    if
	Hex == $0 -> 0;
	Hex == $1 -> 1;
	Hex == $2 -> 2;
	Hex == $3 -> 3;
	Hex == $4 -> 4;
	Hex == $5 -> 5;
	Hex == $6 -> 6;
	Hex == $7 -> 7;
	Hex == $8 -> 8;
	Hex == $9 -> 9;
	Hex == $A -> 10;
	Hex == $B -> 11;
	Hex == $C -> 12;
	Hex == $D -> 13;
	Hex == $E -> 14;
	Hex == $F -> 15;
	true -> throw({error, "bad hex character"})
    end.

hex_to_byte(Hi,Lo) ->
    (hex_to_four_bits(Hi) bsl 4) bor hex_to_four_bits(Lo).

kind(DefValPart,IndexPart) ->
    case DefValPart of
	undefined ->
	    case IndexPart of
		{indexes, undefined} -> {variable, []};
		{indexes, Indexes}  ->
		    {table_entry, {indexes, Indexes}};
		{augments,Table} ->
		    {table_entry,{augments,Table}}
	    end;
	{defval, DefVal} -> {variable, [{defval, DefVal}]}
    end.    

display_hint(Val) ->
    case val(Val) of
        Str when is_list(Str) ->
            lists:reverse(Str);
        _ ->
            throw({error, {invalid_display_hint, Val}})
    end.

units(Val) ->
    case val(Val) of
        Str when is_list(Str) ->
            lists:reverse(Str);
        _ ->
            throw({error, {invalid_units, Val}})
    end.

ensure_ver(Ver, Line, What) ->
    case get(snmp_version) of
	Ver -> ok;
	_Other ->
	    snmpc_lib:print_error(
	      "~s is only allowed in SNMPv~p.",[What,Ver],Line)
    end.


ensure_ver(Ver,Token) ->
    ensure_ver(Ver,line_of(Token), atom_to_list(cat(Token))).

filter_v2imports(2,'Integer32')  -> {builtin, 'Integer32'};
filter_v2imports(2,'Counter32')  -> {builtin, 'Counter32'};
filter_v2imports(2,'Gauge32')    -> {builtin, 'Gauge32'};
filter_v2imports(2,'Unsigned32') -> {builtin, 'Unsigned32'};
filter_v2imports(2,'Counter64')  -> {builtin, 'Counter64'};
filter_v2imports(_,Type)         -> {type, Type}.
    
w(F, A) ->
    ?vwarning(F, A).

lreverse(_Tag, L) when is_list(L) ->
    lists:reverse(L);
lreverse(Tag, X) ->
    exit({bad_list, Tag, X}).


%% i(F, A) ->
%%     io:format("~w:" ++ F ++ "~n", [?MODULE|A]).


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



-file("./snmpc_mib_gram.erl", 629).

yeccpars2(0=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_0(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(1=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_1(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(2=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_2(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(3=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_3(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(4=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(5=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_5(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(6=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_6(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(7=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_7(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(8=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_8(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(9=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_9(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(10=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_10(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(11=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_11(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(12=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(13=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_13(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(14=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_14(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(15=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_15(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(16=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_16(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(53=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_53(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(54=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_12(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(55=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_55(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(56=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_56(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(57=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_57(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(58=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_58(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(59=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_59(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(60=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_60(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(61=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_61(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(62=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_62(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(63=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_63(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(64=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(65=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_65(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(66=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_66(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(67=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_67(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(68=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_68(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(69=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_69(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(70=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_70(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(71=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_71(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(72=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_72(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(73=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_73(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(74=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_74(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(75=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_75(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(76=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_76(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(77=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_77(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(78=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_78(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(79=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_79(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(80=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_80(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(81=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_81(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(82=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_82(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(83=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_83(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(84=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_84(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(85=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_85(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(86=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_86(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(87=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_87(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(88=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(89=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_89(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(90=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_90(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(91=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_91(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(92=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_92(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(93=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_93(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(94=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_94(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(95=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_95(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(96=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_96(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(97=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_97(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(98=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_98(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(99=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_99(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(100=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_100(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(101=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_101(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(102=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_102(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(103=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_103(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(104=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_104(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(105=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_105(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(106=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_106(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(107=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_107(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(108=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_108(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(109=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_109(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(110=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_110(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(111=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_111(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(112=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_112(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(121=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_121(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(122=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_122(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(123=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_123(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(124=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(125=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_125(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(126=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_126(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(127=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_127(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(128=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_128(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(129=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_129(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(130=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_130(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(131=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_131(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(132=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_132(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(148=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_148(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(163=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_163(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(164=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_164(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(165=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_165(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(166=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(167=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_167(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(168=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_168(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(169=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_169(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(170=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_170(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(171=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_171(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(172=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_172(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(173=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_173(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(174=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_174(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(175=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(176=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_176(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(177=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_177(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(178=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_178(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(179=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_179(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(180=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_180(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(181=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_181(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(182=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(183=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_183(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(184=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_184(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(185=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_185(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(186=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_186(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(187=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(188=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_188(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(189=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_189(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(190=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_190(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(191=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_191(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(192=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_192(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(193=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_193(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(194=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_194(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(195=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_195(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(196=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_196(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(197=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_197(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(198=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_198(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(199=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_180(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(200=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_200(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(201=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(202=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_202(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(203=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_203(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(204=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_204(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(205=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_187(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(206=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_206(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(207=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_207(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(208=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_208(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(209=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_209(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(210=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_210(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(211=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_211(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(212=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_212(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%% yeccpars2(219=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_219(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(220=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_220(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(221=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_218(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(222=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_222(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(223=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_223(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(224=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_224(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(225=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_218(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(226=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_226(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(227=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_227(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(228=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_228(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(229=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_229(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(230=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_230(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_175(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(245=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_245(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(246=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(247=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_247(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(248=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_248(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(249=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_249(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(250=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_250(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(251=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_251(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(252=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_252(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(253=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_253(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(254=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(255=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_255(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(256=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_256(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(257=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_257(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(258=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_258(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(259=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(260=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_260(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(261=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_254(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(262=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_262(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(263=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_263(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(264=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(265=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_265(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(266=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_266(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(267=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_267(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(268=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(269=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_269(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(270=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_270(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(279=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_279(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(285=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_285(S, Cat, Ss, Stack, T, Ts, Tzr);
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
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(292=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_292(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(293=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_293(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(294=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_294(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(295=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(296=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_296(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(297=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_297(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(298=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_298(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(299=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(300=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_300(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(301=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_301(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(302=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(303=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_303(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(304=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_304(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(305=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(306=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_306(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(307=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_307(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(308=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(309=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_309(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(310=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(311=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_311(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(312=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_312(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(313=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(314=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_314(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(315=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_315(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(316=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_316(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(317=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(318=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_318(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(319=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_319(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(320=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(321=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_321(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(322=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_322(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(323=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(324=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_324(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(325=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_325(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(326=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(327=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_327(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(328=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_166(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(329=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_329(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(330=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_330(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(331=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_331(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(332=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_332(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(333=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(334=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_334(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(335=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_335(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(336=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_336(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(337=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_337(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(338=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_338(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(339=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_339(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(340=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(341=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_341(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(342=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_342(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(343=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_343(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(344=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_344(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(345=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_345(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(346=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_346(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(347=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_347(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(348=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(349=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(350=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_350(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(351=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_351(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(352=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(353=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_353(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(354=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_354(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(355=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(356=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_356(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(357=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_357(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(358=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_243(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(359=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_359(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(360=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_360(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(361=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_361(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(362=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_362(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(363=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_363(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(364=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_364(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(365=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_365(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(366=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_366(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(367=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_367(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(368=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_368(S, Cat, Ss, Stack, T, Ts, Tzr);
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
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(376=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_376(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(377=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_377(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(378=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_378(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(379=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_379(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(380=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_380(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(381=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(382=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_382(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(383=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_383(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(384=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_384(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(385=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_385(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(386=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_386(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(387=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(388=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_388(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(389=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_389(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(390=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_390(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(391=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_391(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(392=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_392(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(393=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_393(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(394=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_394(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(395=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_395(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(396=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_396(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(397=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(398=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_398(S, Cat, Ss, Stack, T, Ts, Tzr);
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
yeccpars2(406=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_406(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(407=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_407(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(408=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(409=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_409(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(410=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_410(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(411=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_411(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(412=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(413=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_413(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(414=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_414(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(415=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(416=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_416(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(417=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_417(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(418=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_418(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(419=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(420=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_420(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(421=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_421(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(422=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_175(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(423=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_423(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(424=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_424(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(425=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_425(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(426=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_426(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(427=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_427(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(428=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_428(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(429=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_429(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(430=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_430(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(431=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_431(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(432=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_432(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(433=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_433(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(434=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_434(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(435=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(436=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_436(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(437=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_437(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(438=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_438(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(439=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_259(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(440=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_440(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(441=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_441(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(442=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_4(S, Cat, Ss, Stack, T, Ts, Tzr);
%% yeccpars2(443=S, Cat, Ss, Stack, T, Ts, Tzr) ->
%%  yeccpars2_443(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(444=S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_444(S, Cat, Ss, Stack, T, Ts, Tzr);
yeccpars2(Other, _, _, _, _, _, _) ->
 erlang:error({yecc_bug,"1.4",{missing_state_in_action_table, Other}}).

yeccpars2_0(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_0(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_1(S, 'DEFINITIONS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 4, Ss, Stack, T, Ts, Tzr);
yeccpars2_1(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_2(_S, '$end', _Ss, Stack, _T, _Ts, _Tzr) ->
 {ok, hd(Stack)};
yeccpars2_2(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_3(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_3_(Stack),
 yeccgoto_mibname(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_4(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 6, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(S, '::=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 7, Ss, Stack, T, Ts, Tzr);
yeccpars2_4(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_5(S, 'BEGIN', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 10, Ss, Stack, T, Ts, Tzr);
yeccpars2_5(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_6(S, ':', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 8, Ss, Stack, T, Ts, Tzr);
yeccpars2_6(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_7(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_implies(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_8(S, '=', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 9, Ss, Stack, T, Ts, Tzr);
yeccpars2_8(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_9(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_9_(Stack),
 yeccgoto_implies(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_10(S, 'IMPORTS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 12, Ss, Stack, T, Ts, Tzr);
yeccpars2_10(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_10_(Stack),
 yeccpars2_11(11, Cat, [10 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_11(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 70, Ss, Stack, T, Ts, Tzr);
yeccpars2_11(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_11(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_12(S, 'AGENT-CAPABILITIES', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'AutonomousType', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'BITS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'Counter', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'DateAndTime', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'DisplayString', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'Gauge', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'InstancePointer', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'IpAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'MODULE-COMPLIANCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'MODULE-IDENTITY', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'MacAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'NOTIFICATION-GROUP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'NOTIFICATION-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'NetworkAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'OBJECT-GROUP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'OBJECT-IDENTITY', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'OBJECT-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'Opaque', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'PhysAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'RowPointer', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'RowStatus', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'StorageType', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'TAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'TDomain', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'TEXTUAL-CONVENTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'TRAP-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'TestAndIncr', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'TimeInterval', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'TimeStamp', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'TimeTicks', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'TruthValue', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, 'VariablePointer', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_12(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_13(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 54, Ss, Stack, T, Ts, Tzr);
yeccpars2_13(S, 'FROM', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 55, Ss, Stack, T, Ts, Tzr);
yeccpars2_13(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_14(S, 'AGENT-CAPABILITIES', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 17, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'AutonomousType', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 18, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'BITS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 19, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'Counter', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 20, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'DateAndTime', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 21, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'DisplayString', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 22, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'Gauge', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 23, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'InstancePointer', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 24, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'IpAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 25, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'MODULE-COMPLIANCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 26, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'MODULE-IDENTITY', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 27, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'MacAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 28, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'NOTIFICATION-GROUP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 29, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'NOTIFICATION-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 30, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'NetworkAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 31, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'OBJECT-GROUP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 32, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'OBJECT-IDENTITY', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 33, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'OBJECT-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 34, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'Opaque', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 35, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'PhysAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 36, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'RowPointer', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 37, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'RowStatus', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 38, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'StorageType', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 39, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'TAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 40, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'TDomain', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 41, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'TEXTUAL-CONVENTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 42, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'TRAP-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 43, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'TestAndIncr', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 44, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'TimeInterval', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 45, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'TimeStamp', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 46, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'TimeTicks', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 47, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'TruthValue', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 48, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, 'VariablePointer', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 49, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 50, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 51, Ss, Stack, T, Ts, Tzr);
yeccpars2_14(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_14_(Stack),
 yeccgoto_imports(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_15(S, ';', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 52, Ss, Stack, T, Ts, Tzr);
yeccpars2_15(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_16_(Stack),
 yeccgoto_listofimports(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_17(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_17_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_18(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_18_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_19(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_19_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_20(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_20_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_21(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_21_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_22(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_22_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_23(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_23_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_24(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_24_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_25(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_25_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_26(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_26_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_27(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_27_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_28(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_28_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_29(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_29_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_30(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_30_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_31(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_31_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_32(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_32_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_33(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_33_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_34(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_34_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_35(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_35_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_36(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_36_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_37(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_37_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_38(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_38_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_39(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_39_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_40(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_40_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_41(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_41_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_42(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_42_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_43(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_43_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_44(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_44_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_45(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_45_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_46(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_46_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_47(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_47_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_48(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_48_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_49(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_49_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_50(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_50_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_51(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_51_(Stack),
 yeccgoto_import_stuff(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_52(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_52_(Stack),
 yeccgoto_import(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_53_(Stack),
 yeccgoto_imports(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_54: see yeccpars2_12

yeccpars2_55(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 56, Ss, Stack, T, Ts, Tzr);
yeccpars2_55(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_56(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_56_(Stack),
 yeccgoto_imports_from_one_mib(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_57_(Stack),
 yeccgoto_listofimports(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_58(S, 'END', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 444, Ss, Stack, T, Ts, Tzr);
yeccpars2_58(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definition(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_60(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definition(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_61(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definition(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_62(S, 'OBJECT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 234, Ss, Stack, T, Ts, Tzr);
yeccpars2_62(S, 'OBJECT-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 406, Ss, Stack, T, Ts, Tzr);
yeccpars2_62(S, 'TRAP-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 407, Ss, Stack, T, Ts, Tzr);
yeccpars2_62(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_63(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definition(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_64: see yeccpars2_4

yeccpars2_65(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definition(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_66_(Stack),
 yeccpars2_114(114, Cat, [66 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_67(S, 'MODULE-IDENTITY', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 74, Ss, Stack, T, Ts, Tzr);
yeccpars2_67(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_68(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_68(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_68_(Stack),
 yeccgoto_v1orv2(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_69_(Stack),
 yeccgoto_listofdefinitions(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_70(_S, 'MODULE-IDENTITY', Ss, Stack, T, Ts, Tzr) ->
 NewStack = 'yeccpars2_70_MODULE-IDENTITY'(Stack),
 yeccgoto_mibid(hd(Ss), 'MODULE-IDENTITY', Ss, NewStack, T, Ts, Tzr);
yeccpars2_70(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_70_(Stack),
 yeccgoto_objectname(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_71(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_71_(Stack),
 yeccgoto_newtypename(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_72_(Stack),
 yeccgoto_listofdefinitions(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_73(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_73_(Stack),
 yeccgoto_objectname(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_74(S, 'LAST-UPDATED', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 75, Ss, Stack, T, Ts, Tzr);
yeccpars2_74(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_75(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 77, Ss, Stack, T, Ts, Tzr);
yeccpars2_75(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_76(S, 'ORGANIZATION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 78, Ss, Stack, T, Ts, Tzr);
yeccpars2_76(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_77(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_77_(Stack),
 yeccgoto_last_updated(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_78(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 80, Ss, Stack, T, Ts, Tzr);
yeccpars2_78(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_79(S, 'CONTACT-INFO', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 81, Ss, Stack, T, Ts, Tzr);
yeccpars2_79(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_80(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_80_(Stack),
 yeccgoto_organization(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_81(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 83, Ss, Stack, T, Ts, Tzr);
yeccpars2_81(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_82(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 84, Ss, Stack, T, Ts, Tzr);
yeccpars2_82(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_83(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_83_(Stack),
 yeccgoto_contact_info(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_84(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_84(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_84_(Stack),
 yeccpars2_85(85, Cat, [84 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_85(S, 'REVISION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_85(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_85_(Stack),
 yeccpars2_4(88, Cat, [85 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_86(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_86_(Stack),
 yeccgoto_descriptionfield(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_87(S, 'REVISION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 90, Ss, Stack, T, Ts, Tzr);
yeccpars2_87(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_87_(Stack),
 yeccgoto_revisionpart(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_88: see yeccpars2_4

yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_89_(Stack),
 yeccgoto_revisions(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_90(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 92, Ss, Stack, T, Ts, Tzr);
yeccpars2_90(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_91(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 93, Ss, Stack, T, Ts, Tzr);
yeccpars2_91(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_92(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_92_(Stack),
 yeccgoto_revision_string(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_93(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 95, Ss, Stack, T, Ts, Tzr);
yeccpars2_93(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_94_(Stack),
 yeccgoto_revision(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_95(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_95_(Stack),
 yeccgoto_revision_desc(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_96_(Stack),
 yeccgoto_moduleidentity(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_97(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 98, Ss, Stack, T, Ts, Tzr);
yeccpars2_97(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_98(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 102, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_98(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_99(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 112, Ss, Stack, T, Ts, Tzr);
yeccpars2_99(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_100(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_fatherobjectname(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_101(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_101(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_101(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_102(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 106, Ss, Stack, T, Ts, Tzr);
yeccpars2_102(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_102_(Stack),
 yeccgoto_objectname(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_103(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_103(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_103(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_103_(Stack),
 yeccgoto_parentintegers(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_104_(Stack),
 yeccgoto_parentintegers(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_105(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 106, Ss, Stack, T, Ts, Tzr);
yeccpars2_105(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_106(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 107, Ss, Stack, T, Ts, Tzr);
yeccpars2_106(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_107(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 108, Ss, Stack, T, Ts, Tzr);
yeccpars2_107(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_108(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 105, Ss, Stack, T, Ts, Tzr);
yeccpars2_108(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 103, Ss, Stack, T, Ts, Tzr);
yeccpars2_108(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_108_(Stack),
 yeccgoto_parentintegers(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_109(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_109_(Stack),
 yeccgoto_parentintegers(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_110(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 111, Ss, Stack, T, Ts, Tzr);
yeccpars2_110(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_111(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_111_(Stack),
 yeccgoto_nameassign(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_112(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_112_(Stack),
 yeccgoto_nameassign(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_113_(Stack),
 yeccgoto_revisions(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_114(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_114(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 71, Ss, Stack, T, Ts, Tzr);
yeccpars2_114(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_114_(Stack),
 yeccgoto_v1orv2(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_118(S, 'AGENT-CAPABILITIES', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 230, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'MODULE-COMPLIANCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 231, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'NOTIFICATION-GROUP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 232, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'NOTIFICATION-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 233, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OBJECT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 234, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OBJECT-GROUP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 235, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OBJECT-IDENTITY', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 236, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(S, 'OBJECT-TYPE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 237, Ss, Stack, T, Ts, Tzr);
yeccpars2_118(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_121(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_122(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_124: see yeccpars2_4

yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_126(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_127(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_127_(Stack),
 yeccgoto_listofdefinitionsv2(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_definitionv2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_129(S, 'BITS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 135, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, 'SEQUENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 151, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, 'TEXTUAL-CONVENTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 155, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 162, Ss, Stack, T, Ts, Tzr);
yeccpars2_129(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_129(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_cont_129(S, 'AutonomousType', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 133, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'BIT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 134, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'Counter', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 136, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'DateAndTime', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 137, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'DisplayString', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 138, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'Gauge', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 139, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'INTEGER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 140, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'InstancePointer', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 141, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'IpAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 142, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'MacAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 143, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'NetworkAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 144, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'OBJECT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 145, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'OCTET', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 146, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'Opaque', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 147, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'PhysAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 148, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'RowPointer', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 149, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'RowStatus', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 150, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'StorageType', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 152, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'TAddress', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 153, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'TDomain', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 154, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'TestAndIncr', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 156, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'TimeInterval', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 157, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'TimeStamp', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 158, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'TimeTicks', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 159, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'TruthValue', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 160, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(S, 'VariablePointer', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 161, Ss, Stack, T, Ts, Tzr);
yeccpars2_cont_129(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_130(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 210, Ss, Stack, T, Ts, Tzr);
yeccpars2_130(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_130_(Stack),
 yeccgoto_syntax(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_131(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 210, Ss, Stack, T, Ts, Tzr);
yeccpars2_131(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_131_(Stack),
 yeccgoto_syntax(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_132_(Stack),
 yeccgoto_newtype(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_133(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_133_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_134(S, 'STRING', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 208, Ss, Stack, T, Ts, Tzr);
yeccpars2_134(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_135(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 187, Ss, Stack, T, Ts, Tzr);
yeccpars2_135(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_136(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_136_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_137(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_137_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_138(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_138_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_139(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_139_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_140(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 205, Ss, Stack, T, Ts, Tzr);
yeccpars2_140(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_type(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_141(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_141_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_142(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_type(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_143(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_143_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_144(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_type(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_145(S, 'IDENTIFIER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 204, Ss, Stack, T, Ts, Tzr);
yeccpars2_145(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_146(S, 'STRING', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 203, Ss, Stack, T, Ts, Tzr);
yeccpars2_146(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_147(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_type(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_148(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_148_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_149(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_149_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_150(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_150_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_151(S, 'OF', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 178, Ss, Stack, T, Ts, Tzr);
yeccpars2_151(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 180, Ss, Stack, T, Ts, Tzr);
yeccpars2_151(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_152(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_152_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_153(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_153_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_154(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_154_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_155(S, 'DISPLAY-HINT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 164, Ss, Stack, T, Ts, Tzr);
yeccpars2_155(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_155_(Stack),
 yeccpars2_163(163, Cat, [155 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_156(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_156_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_157(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_157_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_158(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_158_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_159(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_type(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_160(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_160_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_161(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_161_(Stack),
 yeccgoto_type(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_162(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_usertype(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_163(S, 'STATUS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 166, Ss, Stack, T, Ts, Tzr);
yeccpars2_163(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_164(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 165, Ss, Stack, T, Ts, Tzr);
yeccpars2_164(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_165(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_165_(Stack),
 yeccgoto_displaypart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_166(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 168, Ss, Stack, T, Ts, Tzr);
yeccpars2_166(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_167(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_167(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_167_(Stack),
 yeccpars2_169(169, Cat, [167 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_168(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_168_(Stack),
 yeccgoto_statusv2(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_169(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_169(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_169_(Stack),
 yeccpars2_172(172, Cat, [169 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_170(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 171, Ss, Stack, T, Ts, Tzr);
yeccpars2_170(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_171(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_171_(Stack),
 yeccgoto_description(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_172(S, 'SYNTAX', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 175, Ss, Stack, T, Ts, Tzr);
yeccpars2_172(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_173(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 174, Ss, Stack, T, Ts, Tzr);
yeccpars2_173(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_174(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_174_(Stack),
 yeccgoto_referpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_175(S, 'BITS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 135, Ss, Stack, T, Ts, Tzr);
yeccpars2_175(S, 'SEQUENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 177, Ss, Stack, T, Ts, Tzr);
yeccpars2_175(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 162, Ss, Stack, T, Ts, Tzr);
yeccpars2_175(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_129(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_176_(Stack),
 yeccgoto_textualconvention(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_177(S, 'OF', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 178, Ss, Stack, T, Ts, Tzr);
yeccpars2_177(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_178(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 162, Ss, Stack, T, Ts, Tzr);
yeccpars2_178(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_179_(Stack),
 yeccgoto_syntax(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_180(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 183, Ss, Stack, T, Ts, Tzr);
yeccpars2_180(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_181(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 199, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 200, Ss, Stack, T, Ts, Tzr);
yeccpars2_181(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_182(S, 'BITS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 186, Ss, Stack, T, Ts, Tzr);
yeccpars2_182(S, 'SEQUENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 177, Ss, Stack, T, Ts, Tzr);
yeccpars2_182(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 162, Ss, Stack, T, Ts, Tzr);
yeccpars2_182(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_129(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_183(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_fieldname(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_fsyntax(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_185_(Stack),
 yeccgoto_fields(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_186(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 187, Ss, Stack, T, Ts, Tzr);
yeccpars2_186(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_186_(Stack),
 yeccgoto_fsyntax(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_187(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 189, Ss, Stack, T, Ts, Tzr);
yeccpars2_187(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_188(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 193, Ss, Stack, T, Ts, Tzr);
yeccpars2_188(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 194, Ss, Stack, T, Ts, Tzr);
yeccpars2_188(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_189(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 190, Ss, Stack, T, Ts, Tzr);
yeccpars2_189(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_190(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 191, Ss, Stack, T, Ts, Tzr);
yeccpars2_190(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_191(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 192, Ss, Stack, T, Ts, Tzr);
yeccpars2_191(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_192(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_192_(Stack),
 yeccgoto_namedbits(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_193(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 195, Ss, Stack, T, Ts, Tzr);
yeccpars2_193(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_194(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_194_(Stack),
 yeccgoto_syntax(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_195(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 196, Ss, Stack, T, Ts, Tzr);
yeccpars2_195(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_196(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 197, Ss, Stack, T, Ts, Tzr);
yeccpars2_196(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_197(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 198, Ss, Stack, T, Ts, Tzr);
yeccpars2_197(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_198(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_198_(Stack),
 yeccgoto_namedbits(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_199: see yeccpars2_180

yeccpars2_200(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_200_(Stack),
 yeccgoto_tableentrydefinition(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_201: see yeccpars2_182

yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_202_(Stack),
 yeccgoto_fields(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_203(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_203_(Stack),
 yeccgoto_type(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_204(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_204_(Stack),
 yeccgoto_type(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_205: see yeccpars2_187

yeccpars2_206(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 193, Ss, Stack, T, Ts, Tzr);
yeccpars2_206(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 207, Ss, Stack, T, Ts, Tzr);
yeccpars2_206(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_207(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_207_(Stack),
 yeccgoto_syntax(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_208(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_208_(Stack),
 yeccgoto_type(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_209_(Stack),
 yeccgoto_syntax(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_210(S, 'SIZE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 213, Ss, Stack, T, Ts, Tzr);
yeccpars2_210(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_218(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_211(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 228, Ss, Stack, T, Ts, Tzr);
yeccpars2_211(S, '|', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_211(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_212(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 224, Ss, Stack, T, Ts, Tzr);
yeccpars2_212(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_212_(Stack),
 yeccgoto_sizedescr(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_213(S, '(', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 218, Ss, Stack, T, Ts, Tzr);
yeccpars2_213(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_214(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_214_(Stack),
 yeccgoto_range_num(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_215(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 216, Ss, Stack, T, Ts, Tzr);
yeccpars2_215(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 217, Ss, Stack, T, Ts, Tzr);
yeccpars2_215(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_216(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_216_(Stack),
 yeccgoto_range_num(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_217(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_217_(Stack),
 yeccgoto_range_num(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_218(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 214, Ss, Stack, T, Ts, Tzr);
yeccpars2_218(S, quote, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 215, Ss, Stack, T, Ts, Tzr);
yeccpars2_218(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_219(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 220, Ss, Stack, T, Ts, Tzr);
yeccpars2_219(S, '|', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_219(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_220(S, ')', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 223, Ss, Stack, T, Ts, Tzr);
yeccpars2_220(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_221: see yeccpars2_218

yeccpars2_222(S, '|', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_222(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_222_(Stack),
 yeccgoto_sizedescr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_223(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_223_(Stack),
 yeccgoto_size(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_224(S, '.', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 225, Ss, Stack, T, Ts, Tzr);
yeccpars2_224(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_225: see yeccpars2_218

yeccpars2_226(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 214, Ss, Stack, T, Ts, Tzr);
yeccpars2_226(S, quote, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 215, Ss, Stack, T, Ts, Tzr);
yeccpars2_226(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_226_(Stack),
 yeccgoto_sizedescr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_227(S, '|', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 221, Ss, Stack, T, Ts, Tzr);
yeccpars2_227(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_227_(Stack),
 yeccgoto_sizedescr(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_228(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_228_(Stack),
 yeccgoto_size(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_229_(Stack),
 yeccgoto_syntax(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_230(S, 'PRODUCT-RELEASE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 366, Ss, Stack, T, Ts, Tzr);
yeccpars2_230(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_231(S, 'STATUS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 328, Ss, Stack, T, Ts, Tzr);
yeccpars2_231(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_232(S, 'NOTIFICATIONS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 319, Ss, Stack, T, Ts, Tzr);
yeccpars2_232(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_233(S, 'OBJECTS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 298, Ss, Stack, T, Ts, Tzr);
yeccpars2_233(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_233_(Stack),
 yeccpars2_312(312, Cat, [233 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_234(S, 'IDENTIFIER', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 310, Ss, Stack, T, Ts, Tzr);
yeccpars2_234(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_235(S, 'OBJECTS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 298, Ss, Stack, T, Ts, Tzr);
yeccpars2_235(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_235_(Stack),
 yeccpars2_297(297, Cat, [235 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_236(S, 'STATUS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 291, Ss, Stack, T, Ts, Tzr);
yeccpars2_236(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_237(S, 'SYNTAX', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 238, Ss, Stack, T, Ts, Tzr);
yeccpars2_237(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_238: see yeccpars2_175

yeccpars2_239(S, 'UNITS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 241, Ss, Stack, T, Ts, Tzr);
yeccpars2_239(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_239_(Stack),
 yeccpars2_240(240, Cat, [239 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_240(S, 'MAX-ACCESS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 243, Ss, Stack, T, Ts, Tzr);
yeccpars2_240(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_241(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 242, Ss, Stack, T, Ts, Tzr);
yeccpars2_241(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_242(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_242_(Stack),
 yeccgoto_unitspart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_243(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 245, Ss, Stack, T, Ts, Tzr);
yeccpars2_243(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_244(S, 'STATUS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 246, Ss, Stack, T, Ts, Tzr);
yeccpars2_244(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_245(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_245_(Stack),
 yeccgoto_accessv2(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_246: see yeccpars2_166

yeccpars2_247(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 248, Ss, Stack, T, Ts, Tzr);
yeccpars2_247(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_248(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_248(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_248_(Stack),
 yeccpars2_249(249, Cat, [248 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_249(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_249(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_249_(Stack),
 yeccpars2_250(250, Cat, [249 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_250(S, 'AUGMENTS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 252, Ss, Stack, T, Ts, Tzr);
yeccpars2_250(S, 'INDEX', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 253, Ss, Stack, T, Ts, Tzr);
yeccpars2_250(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_250_(Stack),
 yeccpars2_251(251, Cat, [250 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_251(S, 'DEFVAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 269, Ss, Stack, T, Ts, Tzr);
yeccpars2_251(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_251_(Stack),
 yeccpars2_4(268, Cat, [251 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_252(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 264, Ss, Stack, T, Ts, Tzr);
yeccpars2_252(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_253(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 254, Ss, Stack, T, Ts, Tzr);
yeccpars2_253(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_254(S, 'IMPLIED', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 259, Ss, Stack, T, Ts, Tzr);
yeccpars2_254(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_254(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_index(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_256(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_256_(Stack),
 yeccgoto_indextypesv2(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_257(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 261, Ss, Stack, T, Ts, Tzr);
yeccpars2_257(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 262, Ss, Stack, T, Ts, Tzr);
yeccpars2_257(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_258(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_indextypev2(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_259(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 73, Ss, Stack, T, Ts, Tzr);
yeccpars2_259(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_260(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_260_(Stack),
 yeccgoto_indextypev2(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_261: see yeccpars2_254

yeccpars2_262(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_262_(Stack),
 yeccgoto_indexpartv2(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_263(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_263_(Stack),
 yeccgoto_indextypesv2(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_264: see yeccpars2_259

yeccpars2_265(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_entry(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_266(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 267, Ss, Stack, T, Ts, Tzr);
yeccpars2_266(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_267(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_267_(Stack),
 yeccgoto_indexpartv2(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_268: see yeccpars2_4

yeccpars2_269(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 270, Ss, Stack, T, Ts, Tzr);
yeccpars2_269(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_270(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 271, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 272, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, quote, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 273, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 274, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 275, Ss, Stack, T, Ts, Tzr);
yeccpars2_270(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_271(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 289, Ss, Stack, T, Ts, Tzr);
yeccpars2_271(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_272(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 288, Ss, Stack, T, Ts, Tzr);
yeccpars2_272(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_273(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 284, Ss, Stack, T, Ts, Tzr);
yeccpars2_273(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 285, Ss, Stack, T, Ts, Tzr);
yeccpars2_273(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_274(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 283, Ss, Stack, T, Ts, Tzr);
yeccpars2_274(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_275(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 278, Ss, Stack, T, Ts, Tzr);
yeccpars2_275(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_275_(Stack),
 yeccpars2_276(276, Cat, [275 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_276(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 281, Ss, Stack, T, Ts, Tzr);
yeccpars2_276(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_277(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 279, Ss, Stack, T, Ts, Tzr);
yeccpars2_277(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_defbitsvalue(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_278(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_278_(Stack),
 yeccgoto_defbitsnames(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_279(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 280, Ss, Stack, T, Ts, Tzr);
yeccpars2_279(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_280(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_280_(Stack),
 yeccgoto_defbitsnames(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_281(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 282, Ss, Stack, T, Ts, Tzr);
yeccpars2_281(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_282(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_282_(Stack),
 yeccgoto_defvalpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_283(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_283_(Stack),
 yeccgoto_defvalpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_284(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 287, Ss, Stack, T, Ts, Tzr);
yeccpars2_284(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_285(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 286, Ss, Stack, T, Ts, Tzr);
yeccpars2_285(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_286(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_286_(Stack),
 yeccgoto_defvalpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_287(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_287_(Stack),
 yeccgoto_defvalpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_288(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_288_(Stack),
 yeccgoto_defvalpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_289(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_289_(Stack),
 yeccgoto_defvalpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_290(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_290_(Stack),
 yeccgoto_objecttypev2(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_291: see yeccpars2_166

yeccpars2_292(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 293, Ss, Stack, T, Ts, Tzr);
yeccpars2_292(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_293(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 294, Ss, Stack, T, Ts, Tzr);
yeccpars2_293(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_294(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_294(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_294_(Stack),
 yeccpars2_4(295, Cat, [294 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_295: see yeccpars2_4

yeccpars2_296(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_296_(Stack),
 yeccgoto_objectidentity(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_297(S, 'STATUS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 305, Ss, Stack, T, Ts, Tzr);
yeccpars2_297(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_298(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 299, Ss, Stack, T, Ts, Tzr);
yeccpars2_298(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_299: see yeccpars2_259

yeccpars2_300(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 302, Ss, Stack, T, Ts, Tzr);
yeccpars2_300(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 303, Ss, Stack, T, Ts, Tzr);
yeccpars2_300(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_301_(Stack),
 yeccgoto_objects(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_302: see yeccpars2_259

yeccpars2_303(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_303_(Stack),
 yeccgoto_objectspart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_304(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_304_(Stack),
 yeccgoto_objects(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_305: see yeccpars2_166

yeccpars2_306(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_306(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_306_(Stack),
 yeccpars2_307(307, Cat, [306 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_307(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_307(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_307_(Stack),
 yeccpars2_4(308, Cat, [307 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_308: see yeccpars2_4

yeccpars2_309(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_309_(Stack),
 yeccgoto_objectgroup(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_310: see yeccpars2_4

yeccpars2_311(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_311_(Stack),
 yeccgoto_objectidentifier(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_312(S, 'STATUS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 313, Ss, Stack, T, Ts, Tzr);
yeccpars2_312(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_313: see yeccpars2_166

yeccpars2_314(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 315, Ss, Stack, T, Ts, Tzr);
yeccpars2_314(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_315(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_315(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_315_(Stack),
 yeccpars2_316(316, Cat, [315 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_316(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_316(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_316_(Stack),
 yeccpars2_4(317, Cat, [316 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_317: see yeccpars2_4

yeccpars2_318(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_318_(Stack),
 yeccgoto_notification(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_319(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 320, Ss, Stack, T, Ts, Tzr);
yeccpars2_319(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_320: see yeccpars2_259

yeccpars2_321(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 302, Ss, Stack, T, Ts, Tzr);
yeccpars2_321(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 322, Ss, Stack, T, Ts, Tzr);
yeccpars2_321(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_322(S, 'STATUS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 323, Ss, Stack, T, Ts, Tzr);
yeccpars2_322(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_323: see yeccpars2_166

yeccpars2_324(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_324(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_324_(Stack),
 yeccpars2_325(325, Cat, [324 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_325(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_325(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_325_(Stack),
 yeccpars2_4(326, Cat, [325 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_326: see yeccpars2_4

yeccpars2_327(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_327_(Stack),
 yeccgoto_notificationgroup(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_328: see yeccpars2_166

yeccpars2_329(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_329(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_329_(Stack),
 yeccpars2_330(330, Cat, [329 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_330(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_330(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_330_(Stack),
 yeccpars2_331(331, Cat, [330 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_331(S, 'MODULE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 335, Ss, Stack, T, Ts, Tzr);
yeccpars2_331(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_331_(Stack),
 yeccpars2_4(333, Cat, [331 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_332(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_332_(Stack),
 yeccgoto_mc_modulepart(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_333: see yeccpars2_4

yeccpars2_334(S, 'MODULE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 335, Ss, Stack, T, Ts, Tzr);
yeccpars2_334(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_334_(Stack),
 yeccgoto_mc_modules(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_335(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_335(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_335_(Stack),
 yeccpars2_337(337, Cat, [335 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_336(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mc_modulenamepart(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_337(S, 'MANDATORY-GROUPS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 339, Ss, Stack, T, Ts, Tzr);
yeccpars2_337(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_337_(Stack),
 yeccpars2_338(338, Cat, [337 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_338(S, 'GROUP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 348, Ss, Stack, T, Ts, Tzr);
yeccpars2_338(S, 'OBJECT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 349, Ss, Stack, T, Ts, Tzr);
yeccpars2_338(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_338_(Stack),
 yeccpars2_345(_S, Cat, [338 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_339(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 340, Ss, Stack, T, Ts, Tzr);
yeccpars2_339(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_340: see yeccpars2_259

yeccpars2_341(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 302, Ss, Stack, T, Ts, Tzr);
yeccpars2_341(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 342, Ss, Stack, T, Ts, Tzr);
yeccpars2_341(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_342(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_342_(Stack),
 yeccgoto_mc_mandatorypart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_343(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mc_compliance(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_344_(Stack),
 yeccgoto_mc_compliancepart(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_345(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_345_(Stack),
 yeccgoto_mc_module(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_346(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_mc_compliance(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_347(S, 'GROUP', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 348, Ss, Stack, T, Ts, Tzr);
yeccpars2_347(S, 'OBJECT', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 349, Ss, Stack, T, Ts, Tzr);
yeccpars2_347(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_347_(Stack),
 yeccgoto_mc_compliances(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_348: see yeccpars2_259

%% yeccpars2_349: see yeccpars2_259

yeccpars2_350(S, 'SYNTAX', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 352, Ss, Stack, T, Ts, Tzr);
yeccpars2_350(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_350_(Stack),
 yeccpars2_351(351, Cat, [350 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_351(S, 'WRITE-SYNTAX', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 355, Ss, Stack, T, Ts, Tzr);
yeccpars2_351(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_351_(Stack),
 yeccpars2_354(354, Cat, [351 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_352: see yeccpars2_175

yeccpars2_353(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_353_(Stack),
 yeccgoto_syntaxpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_354(S, 'MIN-ACCESS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 358, Ss, Stack, T, Ts, Tzr);
yeccpars2_354(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_354_(Stack),
 yeccpars2_357(357, Cat, [354 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_355: see yeccpars2_175

yeccpars2_356(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_356_(Stack),
 yeccgoto_writesyntaxpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_357(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_357(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_357_(Stack),
 yeccpars2_360(_S, Cat, [357 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_358: see yeccpars2_243

yeccpars2_359(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_359_(Stack),
 yeccgoto_mc_accesspart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_360(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_360_(Stack),
 yeccgoto_mc_object(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_361(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_361(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_361_(Stack),
 yeccpars2_362(_S, Cat, [361 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_362(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_362_(Stack),
 yeccgoto_mc_compliancegroup(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_363(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_363_(Stack),
 yeccgoto_mc_compliances(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_364(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_364_(Stack),
 yeccgoto_mc_modules(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_365(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_365_(Stack),
 yeccgoto_modulecompliance(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_366(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 368, Ss, Stack, T, Ts, Tzr);
yeccpars2_366(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_367(S, 'STATUS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 369, Ss, Stack, T, Ts, Tzr);
yeccpars2_367(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_368(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_368_(Stack),
 yeccgoto_prodrel(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_369(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 371, Ss, Stack, T, Ts, Tzr);
yeccpars2_369(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_370(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_370(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_370_(Stack),
 yeccpars2_372(372, Cat, [370 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_371(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_371_(Stack),
 yeccgoto_ac_status(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_372(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_372(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_372_(Stack),
 yeccpars2_373(373, Cat, [372 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_373(S, 'SUPPORTS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 377, Ss, Stack, T, Ts, Tzr);
yeccpars2_373(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_373_(Stack),
 yeccpars2_4(375, Cat, [373 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_374_(Stack),
 yeccgoto_ac_modulepart(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_375: see yeccpars2_4

yeccpars2_376(S, 'SUPPORTS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 377, Ss, Stack, T, Ts, Tzr);
yeccpars2_376(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_376_(Stack),
 yeccgoto_ac_modules(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_377(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 3, Ss, Stack, T, Ts, Tzr);
yeccpars2_377(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_377_(Stack),
 yeccpars2_379(379, Cat, [377 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_378(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_ac_modulenamepart(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_379(S, 'INCLUDES', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 380, Ss, Stack, T, Ts, Tzr);
yeccpars2_379(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_380(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 381, Ss, Stack, T, Ts, Tzr);
yeccpars2_380(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_381: see yeccpars2_259

yeccpars2_382(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 302, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 383, Ss, Stack, T, Ts, Tzr);
yeccpars2_382(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_383(S, 'VARIATION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 387, Ss, Stack, T, Ts, Tzr);
yeccpars2_383(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_383_(Stack),
 yeccpars2_385(_S, Cat, [383 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_384(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_384_(Stack),
 yeccgoto_ac_variationpart(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_385(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_385_(Stack),
 yeccgoto_ac_module(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_386(S, 'VARIATION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 387, Ss, Stack, T, Ts, Tzr);
yeccpars2_386(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_386_(Stack),
 yeccgoto_ac_variations(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_387: see yeccpars2_259

yeccpars2_388(S, 'SYNTAX', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 352, Ss, Stack, T, Ts, Tzr);
yeccpars2_388(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_388_(Stack),
 yeccpars2_389(389, Cat, [388 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_389(S, 'WRITE-SYNTAX', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 355, Ss, Stack, T, Ts, Tzr);
yeccpars2_389(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_389_(Stack),
 yeccpars2_390(390, Cat, [389 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_390(S, 'ACCESS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 392, Ss, Stack, T, Ts, Tzr);
yeccpars2_390(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_390_(Stack),
 yeccpars2_391(391, Cat, [390 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_391(S, 'CREATION-REQUIRES', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 396, Ss, Stack, T, Ts, Tzr);
yeccpars2_391(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_391_(Stack),
 yeccpars2_395(395, Cat, [391 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_392(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 394, Ss, Stack, T, Ts, Tzr);
yeccpars2_392(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_393(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_393_(Stack),
 yeccgoto_ac_accesspart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_394(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_394_(Stack),
 yeccgoto_ac_access(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_395(S, 'DEFVAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 269, Ss, Stack, T, Ts, Tzr);
yeccpars2_395(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_395_(Stack),
 yeccpars2_400(400, Cat, [395 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_396(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 397, Ss, Stack, T, Ts, Tzr);
yeccpars2_396(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_397: see yeccpars2_259

yeccpars2_398(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 302, Ss, Stack, T, Ts, Tzr);
yeccpars2_398(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 399, Ss, Stack, T, Ts, Tzr);
yeccpars2_398(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_399(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_399_(Stack),
 yeccgoto_ac_creationpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_400(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_400(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_400_(Stack),
 yeccpars2_401(_S, Cat, [400 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_401_(Stack),
 yeccgoto_ac_variation(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_402_(Stack),
 yeccgoto_ac_variations(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_|Nss] = Ss,
 NewStack = yeccpars2_403_(Stack),
 yeccgoto_ac_modules(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_404(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_404_(Stack),
 yeccgoto_agentcapabilities(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_405(S, 'BITS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 135, Ss, Stack, T, Ts, Tzr);
yeccpars2_405(S, 'SEQUENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 151, Ss, Stack, T, Ts, Tzr);
yeccpars2_405(S, variable, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 162, Ss, Stack, T, Ts, Tzr);
yeccpars2_405(S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_cont_129(S, Cat, Ss, Stack, T, Ts, Tzr).

yeccpars2_406(S, 'SYNTAX', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 422, Ss, Stack, T, Ts, Tzr);
yeccpars2_406(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_407(S, 'ENTERPRISE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 408, Ss, Stack, T, Ts, Tzr);
yeccpars2_407(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_408: see yeccpars2_259

yeccpars2_409(S, 'VARIABLES', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 411, Ss, Stack, T, Ts, Tzr);
yeccpars2_409(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_409_(Stack),
 yeccpars2_410(410, Cat, [409 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_410(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 170, Ss, Stack, T, Ts, Tzr);
yeccpars2_410(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_410_(Stack),
 yeccpars2_418(418, Cat, [410 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_411(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 412, Ss, Stack, T, Ts, Tzr);
yeccpars2_411(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_412: see yeccpars2_259

yeccpars2_413(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 415, Ss, Stack, T, Ts, Tzr);
yeccpars2_413(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 416, Ss, Stack, T, Ts, Tzr);
yeccpars2_413(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_414(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_414_(Stack),
 yeccgoto_variables(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

%% yeccpars2_415: see yeccpars2_259

yeccpars2_416(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_416_(Stack),
 yeccgoto_varpart(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_417(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_417_(Stack),
 yeccgoto_variables(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_418(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_418(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_418_(Stack),
 yeccpars2_4(419, Cat, [418 | Ss], NewStack, T, Ts, Tzr).

%% yeccpars2_419: see yeccpars2_4

yeccpars2_420(S, integer, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 421, Ss, Stack, T, Ts, Tzr);
yeccpars2_420(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_421(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_421_(Stack),
 yeccgoto_traptype(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_422: see yeccpars2_175

yeccpars2_423(S, 'ACCESS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 424, Ss, Stack, T, Ts, Tzr);
yeccpars2_423(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_424(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 426, Ss, Stack, T, Ts, Tzr);
yeccpars2_424(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_425(S, 'STATUS', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 427, Ss, Stack, T, Ts, Tzr);
yeccpars2_425(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_426(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_426_(Stack),
 yeccgoto_accessv1(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_427(S, atom, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 429, Ss, Stack, T, Ts, Tzr);
yeccpars2_427(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_428(S, 'DESCRIPTION', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 430, Ss, Stack, T, Ts, Tzr);
yeccpars2_428(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_429(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_429_(Stack),
 yeccgoto_statusv1(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_430(S, string, Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 86, Ss, Stack, T, Ts, Tzr);
yeccpars2_430(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_430_(Stack),
 yeccpars2_431(431, Cat, [430 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_431(S, 'REFERENCE', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 173, Ss, Stack, T, Ts, Tzr);
yeccpars2_431(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_431_(Stack),
 yeccpars2_432(432, Cat, [431 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_432(S, 'INDEX', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 434, Ss, Stack, T, Ts, Tzr);
yeccpars2_432(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_432_(Stack),
 yeccpars2_433(433, Cat, [432 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_433(S, 'DEFVAL', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 269, Ss, Stack, T, Ts, Tzr);
yeccpars2_433(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_433_(Stack),
 yeccpars2_4(442, Cat, [433 | Ss], NewStack, T, Ts, Tzr).

yeccpars2_434(S, '{', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 435, Ss, Stack, T, Ts, Tzr);
yeccpars2_434(_, _, _, _, T, _, _) ->
 yeccerror(T).

%% yeccpars2_435: see yeccpars2_259

yeccpars2_436(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 NewStack = yeccpars2_436_(Stack),
 yeccgoto_indextypesv1(hd(Ss), Cat, Ss, NewStack, T, Ts, Tzr).

yeccpars2_437(S, ',', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 439, Ss, Stack, T, Ts, Tzr);
yeccpars2_437(S, '}', Ss, Stack, T, Ts, Tzr) ->
 yeccpars1(S, 440, Ss, Stack, T, Ts, Tzr);
yeccpars2_437(_, _, _, _, T, _, _) ->
 yeccerror(T).

yeccpars2_438(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccgoto_indextypev1(hd(Ss), Cat, Ss, Stack, T, Ts, Tzr).

%% yeccpars2_439: see yeccpars2_259

yeccpars2_440(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_|Nss] = Ss,
 NewStack = yeccpars2_440_(Stack),
 yeccgoto_indexpartv1(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_441(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_|Nss] = Ss,
 NewStack = yeccpars2_441_(Stack),
 yeccgoto_indextypesv1(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

%% yeccpars2_442: see yeccpars2_4

yeccpars2_443(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_,_,_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_443_(Stack),
 yeccgoto_objecttypev1(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccpars2_444(_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 [_,_,_,_,_,_|Nss] = Ss,
 NewStack = yeccpars2_444_(Stack),
 yeccgoto_mib(hd(Nss), Cat, Nss, NewStack, T, Ts, Tzr).

yeccgoto_ac_access(392=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_393(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_accesspart(390, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_391(391, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_creationpart(391, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_395(395, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_module(373, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_376(376, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ac_module(376, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_376(376, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_modulenamepart(377, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_379(379, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_modulepart(373, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(375, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_modules(373=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_374(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ac_modules(376=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_403(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_status(369, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_370(370, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_variation(383, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_386(386, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ac_variation(386, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_386(386, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_variationpart(383=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_385(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_ac_variations(383=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_384(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_ac_variations(386=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_402(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_accessv1(424, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_425(425, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_accessv2(243, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_244(244, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_accessv2(358=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_359(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_agentcapabilities(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_128(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_contact_info(81, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_82(82, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_defbitsnames(275, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_277(277, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_defbitsvalue(275, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_276(276, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_definition(11=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_69(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_definition(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_72(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_definitionv2(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_127(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_defvalpart(251, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(268, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_defvalpart(395, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_400(400, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_defvalpart(433, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(442, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_description(167, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_169(169, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_description(306, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_307(307, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_description(324, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_325(325, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_description(329, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_330(330, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_description(357=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_360(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_description(361=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_362(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_description(370, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_372(372, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_description(400=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_401(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_description(410, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_418(418, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_descriptionfield(84, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_85(85, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_descriptionfield(248, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_249(249, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_descriptionfield(315, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_316(316, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_descriptionfield(430, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_431(431, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_displaypart(155, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_163(163, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_entry(264, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_266(266, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_fatherobjectname(98, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_101(101, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_fieldname(180, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(182, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_fieldname(199, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_182(201, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_fields(180, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_181(181, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_fsyntax(182=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_185(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_fsyntax(201=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_202(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_implies(4, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_5(5, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(64, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_405(405, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(88, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(124, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_129(129, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(268, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(295, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(308, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(310, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(317, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(326, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(333, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(375, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(419, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_420(420, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_implies(442, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_97(97, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_import(10, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_11(11, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_import_stuff(12=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_import_stuff(14=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_16(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_import_stuff(54=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_57(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_imports(12, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_15(15, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_imports(14=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_53(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_imports_from_one_mib(12, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_imports_from_one_mib(14, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_14(14, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_index(254=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_258(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_index(259=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_260(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_index(261=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_258(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_index(435=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_438(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_index(439=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_438(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indexpartv1(432, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_433(433, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indexpartv2(250, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_251(251, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indextypesv1(435, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_437(437, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indextypesv2(254, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_257(257, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indextypev1(435=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_436(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indextypev1(439=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_441(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_indextypev2(254=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_256(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_indextypev2(261=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_263(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_last_updated(75, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_76(76, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_listofdefinitions(11, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_68(68, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_listofdefinitionsv2(66, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_114(114, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_listofimports(12, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(13, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_listofimports(14, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_13(13, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_accesspart(354, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_357(357, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_compliance(338, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_347(347, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mc_compliance(347, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_347(347, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_compliancegroup(338=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_346(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mc_compliancegroup(347=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_346(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_compliancepart(338=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_345(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_compliances(338=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_344(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mc_compliances(347=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_363(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_mandatorypart(337, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_338(338, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_module(331, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_334(334, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mc_module(334, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_334(334, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_modulenamepart(335, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_337(337, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_modulepart(331, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(333, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_modules(331=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_332(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mc_modules(334=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_364(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mc_object(338=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_343(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mc_object(347=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_343(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mib(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_2(2, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mibid(11, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_67(67, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_mibname(0, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_1(1, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mibname(335=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_336(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_mibname(377=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_378(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_modulecompliance(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_126(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_moduleidentity(11=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_66(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_nameassign(88=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_96(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_nameassign(268=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_290(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_nameassign(295=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_296(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_nameassign(308=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_309(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_nameassign(310=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_311(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_nameassign(317=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_318(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_nameassign(326=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_327(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_nameassign(333=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_365(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_nameassign(375=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_404(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_nameassign(442=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_443(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_namedbits(187, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_188(188, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_namedbits(205, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_206(206, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_newtype(11=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_newtype(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_65(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_newtype(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_125(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_newtypename(11, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(64, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_newtypename(68, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(64, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_newtypename(114, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(124, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notification(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_123(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_notificationgroup(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_122(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_objectgroup(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_121(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_objectidentifier(11=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectidentifier(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_63(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectidentifier(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_120(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_objectidentity(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_119(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_objectname(11, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_62(62, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(68, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_62(62, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(98=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_100(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(114, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_118(118, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(254=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(259=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(261=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(264=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_265(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(299=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(302=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_304(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(320=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(340=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(348, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_361(361, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(349, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_350(350, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(381=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(387, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_388(388, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(397=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_301(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(408, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_409(409, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(412=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_414(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(415=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_417(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(435=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectname(439=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_255(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_objects(299, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_300(300, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objects(320, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_321(321, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objects(340, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_341(341, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objects(381, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_382(382, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objects(397, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_398(398, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_objectspart(233, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_312(312, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objectspart(235, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_297(297, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_objecttypev1(11=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_objecttypev1(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_61(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_objecttypev2(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_117(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_organization(78, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_79(79, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_parentintegers(98, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_99(99, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parentintegers(101, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_110(110, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parentintegers(103=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_104(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_parentintegers(108=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_109(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_prodrel(366, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_367(367, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_range_num(210, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(212, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_range_num(218, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(212, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_range_num(221, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(212, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_range_num(225, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_226(226, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_range_num(226, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_212(212, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_referpart(169, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_172(172, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_referpart(249, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_250(250, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_referpart(294, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(295, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_referpart(307, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(308, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_referpart(316, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(317, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_referpart(325, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(326, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_referpart(330, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_331(331, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_referpart(372, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_373(373, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_referpart(418, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(419, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_referpart(431, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_432(432, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_revision(85=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_89(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_revision(87=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_113(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_revision_desc(93=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_94(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_revision_string(90, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_91(91, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_revisionpart(85, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_4(88, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_revisions(85, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_87(87, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_size(130=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_229(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_size(131=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_209(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_sizedescr(210, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_211(211, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sizedescr(218, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_219(219, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sizedescr(221, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_222(222, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_sizedescr(226, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_227(227, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statusv1(427, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_428(428, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_statusv2(166, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_167(167, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statusv2(246, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_247(247, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statusv2(291, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_292(292, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statusv2(305, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_306(306, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statusv2(313, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_314(314, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statusv2(323, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_324(324, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_statusv2(328, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_329(329, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_syntax(129=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_syntax(175=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_176(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_syntax(182=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_syntax(201=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_184(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_syntax(238, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_239(239, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_syntax(352=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_353(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_syntax(355=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_356(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_syntax(405=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_132(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_syntax(422, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_423(423, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_syntaxpart(350, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_351(351, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_syntaxpart(388, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_389(389, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_tableentrydefinition(11=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_60(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_tableentrydefinition(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_60(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_tableentrydefinition(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_116(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_textualconvention(114=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_115(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_traptype(11=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_traptype(68=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_59(_S, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_type(129, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_type(175, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_type(182, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_type(201, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_type(238, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_type(352, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_type(355, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_type(405, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_type(422, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_131(131, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_unitspart(239, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_240(240, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_usertype(129, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_usertype(175, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_usertype(178=_S, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_179(_S, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_usertype(182, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_usertype(201, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_usertype(238, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_usertype(352, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_usertype(355, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_usertype(405, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_usertype(422, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_130(130, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_v1orv2(11, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_58(58, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_variables(412, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_413(413, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_varpart(409, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_410(410, Cat, Ss, Stack, T, Ts, Tzr).

yeccgoto_writesyntaxpart(351, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_354(354, Cat, Ss, Stack, T, Ts, Tzr);
yeccgoto_writesyntaxpart(389, Cat, Ss, Stack, T, Ts, Tzr) ->
 yeccpars2_390(390, Cat, Ss, Stack, T, Ts, Tzr).

-compile({inline,yeccpars2_3_/1}).
-file("snmpc_mib_gram.yrl", 497).
yeccpars2_3_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   val ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_9_/1}).
-file("snmpc_mib_gram.yrl", 449).
yeccpars2_9_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   w ( "Sloppy asignment on line ~p" , [ line_of ( __1 ) ] ) , __1
  end | __Stack].

-compile({inline,yeccpars2_10_/1}).
-file("snmpc_mib_gram.yrl", 242).
yeccpars2_10_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_14_/1}).
-file("snmpc_mib_gram.yrl", 251).
yeccpars2_14_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_16_/1}).
-file("snmpc_mib_gram.yrl", 267).
yeccpars2_16_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_17_/1}).
-file("snmpc_mib_gram.yrl", 290).
yeccpars2_17_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'AGENT-CAPABILITIES' }
  end | __Stack].

-compile({inline,yeccpars2_18_/1}).
-file("snmpc_mib_gram.yrl", 312).
yeccpars2_18_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'AutonomousType' }
  end | __Stack].

-compile({inline,yeccpars2_19_/1}).
-file("snmpc_mib_gram.yrl", 334).
yeccpars2_19_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'BITS' }
  end | __Stack].

-compile({inline,yeccpars2_20_/1}).
-file("snmpc_mib_gram.yrl", 279).
yeccpars2_20_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { builtin , 'Counter' }
  end | __Stack].

-compile({inline,yeccpars2_21_/1}).
-file("snmpc_mib_gram.yrl", 326).
yeccpars2_21_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'DateAndTime' }
  end | __Stack].

-compile({inline,yeccpars2_22_/1}).
-file("snmpc_mib_gram.yrl", 302).
yeccpars2_22_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'DisplayString' }
  end | __Stack].

-compile({inline,yeccpars2_23_/1}).
-file("snmpc_mib_gram.yrl", 280).
yeccpars2_23_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { builtin , 'Gauge' }
  end | __Stack].

-compile({inline,yeccpars2_24_/1}).
-file("snmpc_mib_gram.yrl", 314).
yeccpars2_24_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'InstancePointer' }
  end | __Stack].

-compile({inline,yeccpars2_25_/1}).
-file("snmpc_mib_gram.yrl", 278).
yeccpars2_25_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { builtin , 'IpAddress' }
  end | __Stack].

-compile({inline,yeccpars2_26_/1}).
-file("snmpc_mib_gram.yrl", 292).
yeccpars2_26_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'MODULE-COMPLIANCE' }
  end | __Stack].

-compile({inline,yeccpars2_27_/1}).
-file("snmpc_mib_gram.yrl", 286).
yeccpars2_27_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'MODULE-IDENTITY' }
  end | __Stack].

-compile({inline,yeccpars2_28_/1}).
-file("snmpc_mib_gram.yrl", 306).
yeccpars2_28_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'MacAddress' }
  end | __Stack].

-compile({inline,yeccpars2_29_/1}).
-file("snmpc_mib_gram.yrl", 294).
yeccpars2_29_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'NOTIFICATION-GROUP' }
  end | __Stack].

-compile({inline,yeccpars2_30_/1}).
-file("snmpc_mib_gram.yrl", 288).
yeccpars2_30_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'NOTIFICATION-TYPE' }
  end | __Stack].

-compile({inline,yeccpars2_31_/1}).
-file("snmpc_mib_gram.yrl", 276).
yeccpars2_31_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { builtin , 'NetworkAddress' }
  end | __Stack].

-compile({inline,yeccpars2_32_/1}).
-file("snmpc_mib_gram.yrl", 296).
yeccpars2_32_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'OBJECT-GROUP' }
  end | __Stack].

-compile({inline,yeccpars2_33_/1}).
-file("snmpc_mib_gram.yrl", 298).
yeccpars2_33_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'OBJECT-IDENTITY' }
  end | __Stack].

-compile({inline,yeccpars2_34_/1}).
-file("snmpc_mib_gram.yrl", 274).
yeccpars2_34_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { builtin , 'OBJECT-TYPE' }
  end | __Stack].

-compile({inline,yeccpars2_35_/1}).
-file("snmpc_mib_gram.yrl", 281).
yeccpars2_35_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { builtin , 'Opaque' }
  end | __Stack].

-compile({inline,yeccpars2_36_/1}).
-file("snmpc_mib_gram.yrl", 304).
yeccpars2_36_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'PhysAddress' }
  end | __Stack].

-compile({inline,yeccpars2_37_/1}).
-file("snmpc_mib_gram.yrl", 318).
yeccpars2_37_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'RowPointer' }
  end | __Stack].

-compile({inline,yeccpars2_38_/1}).
-file("snmpc_mib_gram.yrl", 320).
yeccpars2_38_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'RowStatus' }
  end | __Stack].

-compile({inline,yeccpars2_39_/1}).
-file("snmpc_mib_gram.yrl", 328).
yeccpars2_39_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'StorageType' }
  end | __Stack].

-compile({inline,yeccpars2_40_/1}).
-file("snmpc_mib_gram.yrl", 332).
yeccpars2_40_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'TAddress' }
  end | __Stack].

-compile({inline,yeccpars2_41_/1}).
-file("snmpc_mib_gram.yrl", 330).
yeccpars2_41_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'TDomain' }
  end | __Stack].

-compile({inline,yeccpars2_42_/1}).
-file("snmpc_mib_gram.yrl", 300).
yeccpars2_42_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'TEXTUAL-CONVENTION' }
  end | __Stack].

-compile({inline,yeccpars2_43_/1}).
-file("snmpc_mib_gram.yrl", 275).
yeccpars2_43_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { builtin , 'TRAP-TYPE' }
  end | __Stack].

-compile({inline,yeccpars2_44_/1}).
-file("snmpc_mib_gram.yrl", 310).
yeccpars2_44_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'TestAndIncr' }
  end | __Stack].

-compile({inline,yeccpars2_45_/1}).
-file("snmpc_mib_gram.yrl", 324).
yeccpars2_45_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'TimeInterval' }
  end | __Stack].

-compile({inline,yeccpars2_46_/1}).
-file("snmpc_mib_gram.yrl", 322).
yeccpars2_46_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'TimeStamp' }
  end | __Stack].

-compile({inline,yeccpars2_47_/1}).
-file("snmpc_mib_gram.yrl", 277).
yeccpars2_47_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { builtin , 'TimeTicks' }
  end | __Stack].

-compile({inline,yeccpars2_48_/1}).
-file("snmpc_mib_gram.yrl", 308).
yeccpars2_48_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'TruthValue' }
  end | __Stack].

-compile({inline,yeccpars2_49_/1}).
-file("snmpc_mib_gram.yrl", 316).
yeccpars2_49_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , { builtin , 'VariablePointer' }
  end | __Stack].

-compile({inline,yeccpars2_50_/1}).
-file("snmpc_mib_gram.yrl", 283).
yeccpars2_50_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { node , val ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_51_/1}).
-file("snmpc_mib_gram.yrl", 282).
yeccpars2_51_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   filter_v2imports ( get ( snmp_version ) , val ( __1 ) )
  end | __Stack].

-compile({inline,yeccpars2_52_/1}).
-file("snmpc_mib_gram.yrl", 246).
yeccpars2_52_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_53_/1}).
-file("snmpc_mib_gram.yrl", 256).
yeccpars2_53_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_56_/1}).
-file("snmpc_mib_gram.yrl", 262).
yeccpars2_56_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { { val ( __3 ) , lreverse ( imports_from_one_mib , __1 ) } , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_57_/1}).
-file("snmpc_mib_gram.yrl", 272).
yeccpars2_57_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_66_/1}).
-file("snmpc_mib_gram.yrl", 551).
yeccpars2_66_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_68_/1}).
-file("snmpc_mib_gram.yrl", 231).
yeccpars2_68_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { v1_mib , lreverse ( v1orv2_list , __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_69_/1}).
-file("snmpc_mib_gram.yrl", 239).
yeccpars2_69_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,'yeccpars2_70_MODULE-IDENTITY'/1}).
-file("snmpc_mib_gram.yrl", 523).
'yeccpars2_70_MODULE-IDENTITY'(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   val ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_70_/1}).
-file("snmpc_mib_gram.yrl", 496).
yeccpars2_70_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   val ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_71_/1}).
-file("snmpc_mib_gram.yrl", 499).
yeccpars2_71_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   val ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_72_/1}).
-file("snmpc_mib_gram.yrl", 240).
yeccpars2_72_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_73_/1}).
-file("snmpc_mib_gram.yrl", 496).
yeccpars2_73_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   val ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_77_/1}).
-file("snmpc_mib_gram.yrl", 524).
yeccpars2_77_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( last_updated , val ( __1 ) )
  end | __Stack].

-compile({inline,yeccpars2_80_/1}).
-file("snmpc_mib_gram.yrl", 525).
yeccpars2_80_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( organization , val ( __1 ) )
  end | __Stack].

-compile({inline,yeccpars2_83_/1}).
-file("snmpc_mib_gram.yrl", 526).
yeccpars2_83_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( contact_info , val ( __1 ) )
  end | __Stack].

-compile({inline,yeccpars2_84_/1}).
-file("snmpc_mib_gram.yrl", 451).
yeccpars2_84_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_85_/1}).
-file("snmpc_mib_gram.yrl", 528).
yeccpars2_85_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_86_/1}).
-file("snmpc_mib_gram.yrl", 450).
yeccpars2_86_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( descriptionfield , val ( __1 ) )
  end | __Stack].

-compile({inline,yeccpars2_87_/1}).
-file("snmpc_mib_gram.yrl", 529).
yeccpars2_87_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( revisionpart , __1 )
  end | __Stack].

-compile({inline,yeccpars2_89_/1}).
-file("snmpc_mib_gram.yrl", 531).
yeccpars2_89_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_92_/1}).
-file("snmpc_mib_gram.yrl", 536).
yeccpars2_92_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( revision_string , val ( __1 ) )
  end | __Stack].

-compile({inline,yeccpars2_94_/1}).
-file("snmpc_mib_gram.yrl", 534).
yeccpars2_94_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_revision ( __2 , __4 )
  end | __Stack].

-compile({inline,yeccpars2_95_/1}).
-file("snmpc_mib_gram.yrl", 537).
yeccpars2_95_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( revision_desc , val ( __1 ) )
  end | __Stack].

-compile({inline,yeccpars2_96_/1}).
-file("snmpc_mib_gram.yrl", 519).
yeccpars2_96_(__Stack0) ->
 [__12,__11,__10,__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   MI = make_module_identity ( __1 , __4 , __6 , __8 ,
    __10 , __11 , __12 ) ,
    { MI , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_102_/1}).
-file("snmpc_mib_gram.yrl", 496).
yeccpars2_102_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   val ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_103_/1}).
-file("snmpc_mib_gram.yrl", 470).
yeccpars2_103_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ val ( __1 ) ]
  end | __Stack].

-compile({inline,yeccpars2_104_/1}).
-file("snmpc_mib_gram.yrl", 472).
yeccpars2_104_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ val ( __1 ) | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_108_/1}).
-file("snmpc_mib_gram.yrl", 471).
yeccpars2_108_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ val ( __3 ) ]
  end | __Stack].

-compile({inline,yeccpars2_109_/1}).
-file("snmpc_mib_gram.yrl", 473).
yeccpars2_109_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ val ( __3 ) | __5 ]
  end | __Stack].

-compile({inline,yeccpars2_111_/1}).
-file("snmpc_mib_gram.yrl", 439).
yeccpars2_111_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { __3 , __4 }
  end | __Stack].

-compile({inline,yeccpars2_112_/1}).
-file("snmpc_mib_gram.yrl", 440).
yeccpars2_112_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { root , __3 }
  end | __Stack].

-compile({inline,yeccpars2_113_/1}).
-file("snmpc_mib_gram.yrl", 532).
yeccpars2_113_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_114_/1}).
-file("snmpc_mib_gram.yrl", 230).
yeccpars2_114_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { v2_mib , [ __1 | lreverse ( v1orv2_mod , __2 ) ] }
  end | __Stack].

-compile({inline,yeccpars2_127_/1}).
-file("snmpc_mib_gram.yrl", 552).
yeccpars2_127_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __2 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_130_/1}).
-file("snmpc_mib_gram.yrl", 380).
yeccpars2_130_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { { type , val ( __1 ) } , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_131_/1}).
-file("snmpc_mib_gram.yrl", 381).
yeccpars2_131_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { { type , cat ( __1 ) } , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_132_/1}).
-file("snmpc_mib_gram.yrl", 362).
yeccpars2_132_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   NT = make_new_type ( __1 , dummy , __3 ) ,
    { NT , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_133_/1}).
-file("snmpc_mib_gram.yrl", 426).
yeccpars2_133_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_136_/1}).
-file("snmpc_mib_gram.yrl", 417).
yeccpars2_136_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 1 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_137_/1}).
-file("snmpc_mib_gram.yrl", 433).
yeccpars2_137_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_138_/1}).
-file("snmpc_mib_gram.yrl", 421).
yeccpars2_138_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_139_/1}).
-file("snmpc_mib_gram.yrl", 418).
yeccpars2_139_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 1 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_141_/1}).
-file("snmpc_mib_gram.yrl", 427).
yeccpars2_141_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_143_/1}).
-file("snmpc_mib_gram.yrl", 423).
yeccpars2_143_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_148_/1}).
-file("snmpc_mib_gram.yrl", 422).
yeccpars2_148_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_149_/1}).
-file("snmpc_mib_gram.yrl", 429).
yeccpars2_149_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_150_/1}).
-file("snmpc_mib_gram.yrl", 430).
yeccpars2_150_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_152_/1}).
-file("snmpc_mib_gram.yrl", 434).
yeccpars2_152_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_153_/1}).
-file("snmpc_mib_gram.yrl", 436).
yeccpars2_153_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_154_/1}).
-file("snmpc_mib_gram.yrl", 435).
yeccpars2_154_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_155_/1}).
-file("snmpc_mib_gram.yrl", 456).
yeccpars2_155_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_156_/1}).
-file("snmpc_mib_gram.yrl", 425).
yeccpars2_156_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_157_/1}).
-file("snmpc_mib_gram.yrl", 432).
yeccpars2_157_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_158_/1}).
-file("snmpc_mib_gram.yrl", 431).
yeccpars2_158_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_160_/1}).
-file("snmpc_mib_gram.yrl", 424).
yeccpars2_160_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_161_/1}).
-file("snmpc_mib_gram.yrl", 428).
yeccpars2_161_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) , __1
  end | __Stack].

-compile({inline,yeccpars2_165_/1}).
-file("snmpc_mib_gram.yrl", 455).
yeccpars2_165_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   display_hint ( __2 )
  end | __Stack].

-compile({inline,yeccpars2_167_/1}).
-file("snmpc_mib_gram.yrl", 453).
yeccpars2_167_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_168_/1}).
-file("snmpc_mib_gram.yrl", 730).
yeccpars2_168_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statusv2 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_169_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_169_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_171_/1}).
-file("snmpc_mib_gram.yrl", 452).
yeccpars2_171_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   lreverse ( description , val ( __2 ) )
  end | __Stack].

-compile({inline,yeccpars2_174_/1}).
-file("snmpc_mib_gram.yrl", 505).
yeccpars2_174_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   lreverse ( referpart , val ( __2 ) )
  end | __Stack].

-compile({inline,yeccpars2_176_/1}).
-file("snmpc_mib_gram.yrl", 556).
yeccpars2_176_(__Stack0) ->
 [__10,__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   NT = make_new_type ( __1 , 'TEXTUAL-CONVENTION' , __4 ,
    __6 , __7 , __8 , __10 ) ,
    { NT , line_of ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_179_/1}).
-file("snmpc_mib_gram.yrl", 390).
yeccpars2_179_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { { sequence_of , val ( __3 ) } , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_185_/1}).
-file("snmpc_mib_gram.yrl", 371).
yeccpars2_185_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ { val ( __1 ) , __2 } ]
  end | __Stack].

-compile({inline,yeccpars2_186_/1}).
-file("snmpc_mib_gram.yrl", 375).
yeccpars2_186_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   { { bits , [ { dummy , 0 } ] } , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_192_/1}).
-file("snmpc_mib_gram.yrl", 405).
yeccpars2_192_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ { val ( __1 ) , val ( __3 ) } ]
  end | __Stack].

-compile({inline,yeccpars2_194_/1}).
-file("snmpc_mib_gram.yrl", 387).
yeccpars2_194_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   ensure_ver ( 2 , __1 ) ,
    { { bits , __3 } , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_198_/1}).
-file("snmpc_mib_gram.yrl", 407).
yeccpars2_198_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ { val ( __3 ) , val ( __5 ) } | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_200_/1}).
-file("snmpc_mib_gram.yrl", 366).
yeccpars2_200_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Seq = make_sequence ( __1 , lreverse ( tableentrydefinition , __5 ) ) ,
    { Seq , line_of ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_202_/1}).
-file("snmpc_mib_gram.yrl", 373).
yeccpars2_202_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ { val ( __3 ) , __4 } | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_203_/1}).
-file("snmpc_mib_gram.yrl", 411).
yeccpars2_203_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { 'OCTET STRING' , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_204_/1}).
-file("snmpc_mib_gram.yrl", 413).
yeccpars2_204_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { 'OBJECT IDENTIFIER' , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_207_/1}).
-file("snmpc_mib_gram.yrl", 385).
yeccpars2_207_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { { integer_with_enum , 'INTEGER' , __3 } , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_208_/1}).
-file("snmpc_mib_gram.yrl", 412).
yeccpars2_208_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { 'BIT STRING' , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_209_/1}).
-file("snmpc_mib_gram.yrl", 382).
yeccpars2_209_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { { type_with_size , cat ( __1 ) , __2 } , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_212_/1}).
-file("snmpc_mib_gram.yrl", 398).
yeccpars2_212_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_214_/1}).
-file("snmpc_mib_gram.yrl", 401).
yeccpars2_214_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   val ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_216_/1}).
-file("snmpc_mib_gram.yrl", 402).
yeccpars2_216_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   make_range_integer ( val ( __1 ) , val ( __2 ) )
  end | __Stack].

-compile({inline,yeccpars2_217_/1}).
-file("snmpc_mib_gram.yrl", 403).
yeccpars2_217_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   make_range_integer ( val ( __1 ) , val ( __2 ) )
  end | __Stack].

-compile({inline,yeccpars2_222_/1}).
-file("snmpc_mib_gram.yrl", 399).
yeccpars2_222_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 , __3 ]
  end | __Stack].

-compile({inline,yeccpars2_223_/1}).
-file("snmpc_mib_gram.yrl", 393).
yeccpars2_223_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_range ( __4 )
  end | __Stack].

-compile({inline,yeccpars2_226_/1}).
-file("snmpc_mib_gram.yrl", 396).
yeccpars2_226_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 , __4 ]
  end | __Stack].

-compile({inline,yeccpars2_227_/1}).
-file("snmpc_mib_gram.yrl", 397).
yeccpars2_227_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 , __4 | __5 ]
  end | __Stack].

-compile({inline,yeccpars2_228_/1}).
-file("snmpc_mib_gram.yrl", 392).
yeccpars2_228_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_range ( __2 )
  end | __Stack].

-compile({inline,yeccpars2_229_/1}).
-file("snmpc_mib_gram.yrl", 383).
yeccpars2_229_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { { type_with_size , val ( __1 ) , __2 } , line_of ( __1 ) }
  end | __Stack].

-compile({inline,yeccpars2_233_/1}).
-file("snmpc_mib_gram.yrl", 741).
yeccpars2_233_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_235_/1}).
-file("snmpc_mib_gram.yrl", 741).
yeccpars2_235_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_239_/1}).
-file("snmpc_mib_gram.yrl", 727).
yeccpars2_239_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_242_/1}).
-file("snmpc_mib_gram.yrl", 728).
yeccpars2_242_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   units ( __2 )
  end | __Stack].

-compile({inline,yeccpars2_245_/1}).
-file("snmpc_mib_gram.yrl", 732).
yeccpars2_245_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   accessv2 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_248_/1}).
-file("snmpc_mib_gram.yrl", 451).
yeccpars2_248_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_249_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_249_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_250_/1}).
-file("snmpc_mib_gram.yrl", 717).
yeccpars2_250_(__Stack0) ->
 [begin
   { indexes , undefined }
  end | __Stack0].

-compile({inline,yeccpars2_251_/1}).
-file("snmpc_mib_gram.yrl", 488).
yeccpars2_251_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_256_/1}).
-file("snmpc_mib_gram.yrl", 719).
yeccpars2_256_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_260_/1}).
-file("snmpc_mib_gram.yrl", 722).
yeccpars2_260_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   { implied , __2 }
  end | __Stack].

-compile({inline,yeccpars2_262_/1}).
-file("snmpc_mib_gram.yrl", 715).
yeccpars2_262_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { indexes , lreverse ( indexpartv2 , __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_263_/1}).
-file("snmpc_mib_gram.yrl", 720).
yeccpars2_263_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_267_/1}).
-file("snmpc_mib_gram.yrl", 716).
yeccpars2_267_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { augments , __3 }
  end | __Stack].

-compile({inline,yeccpars2_275_/1}).
-file("snmpc_mib_gram.yrl", 491).
yeccpars2_275_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_278_/1}).
-file("snmpc_mib_gram.yrl", 493).
yeccpars2_278_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ val ( __1 ) ]
  end | __Stack].

-compile({inline,yeccpars2_280_/1}).
-file("snmpc_mib_gram.yrl", 494).
yeccpars2_280_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ val ( __3 ) | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_282_/1}).
-file("snmpc_mib_gram.yrl", 477).
yeccpars2_282_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { defval , __4 }
  end | __Stack].

-compile({inline,yeccpars2_283_/1}).
-file("snmpc_mib_gram.yrl", 487).
yeccpars2_283_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { defval , lreverse ( defvalpart_string , val ( __3 ) ) }
  end | __Stack].

-compile({inline,yeccpars2_286_/1}).
-file("snmpc_mib_gram.yrl", 483).
yeccpars2_286_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { defval , make_defval_for_string ( line_of ( __1 ) ,
    lreverse ( defvalpart_quote_variable , val ( __3 ) ) ,
    val ( __4 ) ) }
  end | __Stack].

-compile({inline,yeccpars2_287_/1}).
-file("snmpc_mib_gram.yrl", 479).
yeccpars2_287_(__Stack0) ->
 [__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { defval , make_defval_for_string ( line_of ( __1 ) ,
    lreverse ( defvalpart_quote_atom , val ( __3 ) ) ,
    val ( __4 ) ) }
  end | __Stack].

-compile({inline,yeccpars2_288_/1}).
-file("snmpc_mib_gram.yrl", 475).
yeccpars2_288_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { defval , val ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_289_/1}).
-file("snmpc_mib_gram.yrl", 476).
yeccpars2_289_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { defval , val ( __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_290_/1}).
-file("snmpc_mib_gram.yrl", 710).
yeccpars2_290_(__Stack0) ->
 [__15,__14,__13,__12,__11,__10,__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Kind = kind ( __14 , __13 ) ,
    OT = make_object_type ( __1 , __4 , __5 , __7 , __9 ,
    __11 , __12 , Kind , __15 ) ,
    { OT , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_294_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_294_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_296_/1}).
-file("snmpc_mib_gram.yrl", 562).
yeccpars2_296_(__Stack0) ->
 [__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { Parent , SubIndex } = __8 ,
    Int = make_internal ( __1 , 'OBJECT-IDENTITY' ,
    Parent , SubIndex ) ,
    { Int , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_301_/1}).
-file("snmpc_mib_gram.yrl", 743).
yeccpars2_301_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_303_/1}).
-file("snmpc_mib_gram.yrl", 740).
yeccpars2_303_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   lreverse ( objectspart , __3 )
  end | __Stack].

-compile({inline,yeccpars2_304_/1}).
-file("snmpc_mib_gram.yrl", 744).
yeccpars2_304_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_306_/1}).
-file("snmpc_mib_gram.yrl", 453).
yeccpars2_306_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_307_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_307_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_309_/1}).
-file("snmpc_mib_gram.yrl", 569).
yeccpars2_309_(__Stack0) ->
 [__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   OG = make_object_group ( __1 , __3 , __5 , __6 , __7 , __8 ) ,
    { OG , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_311_/1}).
-file("snmpc_mib_gram.yrl", 344).
yeccpars2_311_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { Parent , SubIndex } = __4 ,
    Int = make_internal ( __1 , dummy , Parent , SubIndex ) ,
    { Int , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_315_/1}).
-file("snmpc_mib_gram.yrl", 451).
yeccpars2_315_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_316_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_316_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_318_/1}).
-file("snmpc_mib_gram.yrl", 737).
yeccpars2_318_(__Stack0) ->
 [__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Not = make_notification ( __1 , __3 , __5 , __7 , __8 , __9 ) ,
    { Not , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_324_/1}).
-file("snmpc_mib_gram.yrl", 453).
yeccpars2_324_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_325_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_325_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_327_/1}).
-file("snmpc_mib_gram.yrl", 575).
yeccpars2_327_(__Stack0) ->
 [__11,__10,__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   NG = make_notification_group ( __1 , __5 , __8 , __9 ,
    __10 , __11 ) ,
    { NG , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_329_/1}).
-file("snmpc_mib_gram.yrl", 453).
yeccpars2_329_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_330_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_330_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_331_/1}).
-file("snmpc_mib_gram.yrl", 652).
yeccpars2_331_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_332_/1}).
-file("snmpc_mib_gram.yrl", 654).
yeccpars2_332_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( mc_modulepart , __1 )
  end | __Stack].

-compile({inline,yeccpars2_334_/1}).
-file("snmpc_mib_gram.yrl", 657).
yeccpars2_334_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_335_/1}).
-file("snmpc_mib_gram.yrl", 665).
yeccpars2_335_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_337_/1}).
-file("snmpc_mib_gram.yrl", 670).
yeccpars2_337_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_338_/1}).
-file("snmpc_mib_gram.yrl", 675).
yeccpars2_338_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_342_/1}).
-file("snmpc_mib_gram.yrl", 668).
yeccpars2_342_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   lreverse ( mc_mandatorypart , __3 )
  end | __Stack].

-compile({inline,yeccpars2_344_/1}).
-file("snmpc_mib_gram.yrl", 673).
yeccpars2_344_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( mc_compliancepart , __1 )
  end | __Stack].

-compile({inline,yeccpars2_345_/1}).
-file("snmpc_mib_gram.yrl", 662).
yeccpars2_345_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_mc_module ( __2 , __3 , __4 )
  end | __Stack].

-compile({inline,yeccpars2_347_/1}).
-file("snmpc_mib_gram.yrl", 678).
yeccpars2_347_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_350_/1}).
-file("snmpc_mib_gram.yrl", 694).
yeccpars2_350_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_351_/1}).
-file("snmpc_mib_gram.yrl", 697).
yeccpars2_351_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_353_/1}).
-file("snmpc_mib_gram.yrl", 693).
yeccpars2_353_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_354_/1}).
-file("snmpc_mib_gram.yrl", 700).
yeccpars2_354_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_356_/1}).
-file("snmpc_mib_gram.yrl", 696).
yeccpars2_356_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_357_/1}).
-file("snmpc_mib_gram.yrl", 453).
yeccpars2_357_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_359_/1}).
-file("snmpc_mib_gram.yrl", 699).
yeccpars2_359_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_360_/1}).
-file("snmpc_mib_gram.yrl", 691).
yeccpars2_360_(__Stack0) ->
 [__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_mc_object ( __2 , __3 , __4 , __5 , __6 )
  end | __Stack].

-compile({inline,yeccpars2_361_/1}).
-file("snmpc_mib_gram.yrl", 453).
yeccpars2_361_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_362_/1}).
-file("snmpc_mib_gram.yrl", 688).
yeccpars2_362_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_mc_compliance_group ( __2 , __3 )
  end | __Stack].

-compile({inline,yeccpars2_363_/1}).
-file("snmpc_mib_gram.yrl", 680).
yeccpars2_363_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_364_/1}).
-file("snmpc_mib_gram.yrl", 659).
yeccpars2_364_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_365_/1}).
-file("snmpc_mib_gram.yrl", 589).
yeccpars2_365_(__Stack0) ->
 [__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   MC = make_module_compliance ( __1 , __4 , __5 , __6 ,
    __7 , __8 ) ,
   
   
   
    { MC , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_368_/1}).
-file("snmpc_mib_gram.yrl", 605).
yeccpars2_368_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( prodrel , val ( __1 ) )
  end | __Stack].

-compile({inline,yeccpars2_370_/1}).
-file("snmpc_mib_gram.yrl", 453).
yeccpars2_370_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_371_/1}).
-file("snmpc_mib_gram.yrl", 607).
yeccpars2_371_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ac_status ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_372_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_372_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_373_/1}).
-file("snmpc_mib_gram.yrl", 612).
yeccpars2_373_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_374_/1}).
-file("snmpc_mib_gram.yrl", 610).
yeccpars2_374_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( ac_modulepart , __1 )
  end | __Stack].

-compile({inline,yeccpars2_376_/1}).
-file("snmpc_mib_gram.yrl", 615).
yeccpars2_376_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_377_/1}).
-file("snmpc_mib_gram.yrl", 623).
yeccpars2_377_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_383_/1}).
-file("snmpc_mib_gram.yrl", 626).
yeccpars2_383_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_384_/1}).
-file("snmpc_mib_gram.yrl", 628).
yeccpars2_384_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   lreverse ( ac_variationpart , __1 )
  end | __Stack].

-compile({inline,yeccpars2_385_/1}).
-file("snmpc_mib_gram.yrl", 620).
yeccpars2_385_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_ac_module ( __2 , __5 , __7 )
  end | __Stack].

-compile({inline,yeccpars2_386_/1}).
-file("snmpc_mib_gram.yrl", 631).
yeccpars2_386_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_388_/1}).
-file("snmpc_mib_gram.yrl", 694).
yeccpars2_388_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_389_/1}).
-file("snmpc_mib_gram.yrl", 697).
yeccpars2_389_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_390_/1}).
-file("snmpc_mib_gram.yrl", 642).
yeccpars2_390_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_391_/1}).
-file("snmpc_mib_gram.yrl", 649).
yeccpars2_391_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_393_/1}).
-file("snmpc_mib_gram.yrl", 641).
yeccpars2_393_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   __2
  end | __Stack].

-compile({inline,yeccpars2_394_/1}).
-file("snmpc_mib_gram.yrl", 644).
yeccpars2_394_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   ac_access ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_395_/1}).
-file("snmpc_mib_gram.yrl", 488).
yeccpars2_395_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_399_/1}).
-file("snmpc_mib_gram.yrl", 647).
yeccpars2_399_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   lreverse ( ac_creationpart , __3 )
  end | __Stack].

-compile({inline,yeccpars2_400_/1}).
-file("snmpc_mib_gram.yrl", 453).
yeccpars2_400_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_401_/1}).
-file("snmpc_mib_gram.yrl", 639).
yeccpars2_401_(__Stack0) ->
 [__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   make_ac_variation ( __2 , __3 , __4 , __5 , __6 , __7 , __8 )
  end | __Stack].

-compile({inline,yeccpars2_402_/1}).
-file("snmpc_mib_gram.yrl", 633).
yeccpars2_402_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_403_/1}).
-file("snmpc_mib_gram.yrl", 617).
yeccpars2_403_(__Stack0) ->
 [__2,__1 | __Stack] = __Stack0,
 [begin
   [ __1 | __2 ]
  end | __Stack].

-compile({inline,yeccpars2_404_/1}).
-file("snmpc_mib_gram.yrl", 601).
yeccpars2_404_(__Stack0) ->
 [__10,__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   AC = make_agent_capabilities ( __1 , __4 , __6 , __7 ,
    __8 , __9 , __10 ) ,
    { AC , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_409_/1}).
-file("snmpc_mib_gram.yrl", 443).
yeccpars2_409_(__Stack0) ->
 [begin
   [ ]
  end | __Stack0].

-compile({inline,yeccpars2_410_/1}).
-file("snmpc_mib_gram.yrl", 453).
yeccpars2_410_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_414_/1}).
-file("snmpc_mib_gram.yrl", 445).
yeccpars2_414_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_416_/1}).
-file("snmpc_mib_gram.yrl", 444).
yeccpars2_416_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   __3
  end | __Stack].

-compile({inline,yeccpars2_417_/1}).
-file("snmpc_mib_gram.yrl", 446).
yeccpars2_417_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_418_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_418_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_421_/1}).
-file("snmpc_mib_gram.yrl", 338).
yeccpars2_421_(__Stack0) ->
 [__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Trap = make_trap ( __1 , __4 , lreverse ( traptype , __5 ) ,
    __6 , __7 , val ( __9 ) ) ,
    { Trap , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_426_/1}).
-file("snmpc_mib_gram.yrl", 501).
yeccpars2_426_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   accessv1 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_429_/1}).
-file("snmpc_mib_gram.yrl", 503).
yeccpars2_429_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   statusv1 ( __1 )
  end | __Stack].

-compile({inline,yeccpars2_430_/1}).
-file("snmpc_mib_gram.yrl", 451).
yeccpars2_430_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_431_/1}).
-file("snmpc_mib_gram.yrl", 506).
yeccpars2_431_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_432_/1}).
-file("snmpc_mib_gram.yrl", 461).
yeccpars2_432_(__Stack0) ->
 [begin
   { indexes , undefined }
  end | __Stack0].

-compile({inline,yeccpars2_433_/1}).
-file("snmpc_mib_gram.yrl", 488).
yeccpars2_433_(__Stack0) ->
 [begin
   undefined
  end | __Stack0].

-compile({inline,yeccpars2_436_/1}).
-file("snmpc_mib_gram.yrl", 463).
yeccpars2_436_(__Stack0) ->
 [__1 | __Stack] = __Stack0,
 [begin
   [ __1 ]
  end | __Stack].

-compile({inline,yeccpars2_440_/1}).
-file("snmpc_mib_gram.yrl", 460).
yeccpars2_440_(__Stack0) ->
 [__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { indexes , lreverse ( indexpartv1 , __3 ) }
  end | __Stack].

-compile({inline,yeccpars2_441_/1}).
-file("snmpc_mib_gram.yrl", 464).
yeccpars2_441_(__Stack0) ->
 [__3,__2,__1 | __Stack] = __Stack0,
 [begin
   [ __3 | __1 ]
  end | __Stack].

-compile({inline,yeccpars2_443_/1}).
-file("snmpc_mib_gram.yrl", 356).
yeccpars2_443_(__Stack0) ->
 [__14,__13,__12,__11,__10,__9,__8,__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   Kind = kind ( __13 , __12 ) ,
    OT = make_object_type ( __1 , __4 , __6 , __8 , __10 ,
    __11 , Kind , __14 ) ,
    { OT , line_of ( __2 ) }
  end | __Stack].

-compile({inline,yeccpars2_444_/1}).
-file("snmpc_mib_gram.yrl", 223).
yeccpars2_444_(__Stack0) ->
 [__7,__6,__5,__4,__3,__2,__1 | __Stack] = __Stack0,
 [begin
   { Version , Defs } = __6 ,
    # pdata { mib_version = Version ,
    mib_name = __1 ,
    imports = __5 ,
    defs = Defs }
  end | __Stack].


-file("snmpc_mib_gram.yrl", 1192).
