/*
 * Copyright (c) 2010, 2017 Qualcomm Technologies, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Technologies, Inc.
 *
 * 2010 Qualcomm Atheros, Inc.
 *
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#ifndef cmd__h
#define cmd__h
                    /*-,- From cmd.c */
/*-D- Required includes
 */
#include <stdio.h>
#include <stdarg.h>


                    /*-,- From cmd.c */
/*-D- CMD_STDOUT_REDIRECT_FEATURE -- nonzero if stdout file descriptor
 * can be switched during use, allowing printf to be directed to 
 * the session issuing the command.
 */
#define CMD_STDOUT_REDIRECT_FEATURE() 1

                    /*-,- From cmd.c */
/*-D- CMD_MAC_ADDR_STR_LEN -- Maximum length of the mac address of the
 * format aa:bb:cc:dd:ee:ff
 */
#define CMD_MAC_ADDR_STR_LEN (20)



                    /*-,- From cmd.c */
                    extern
/*-F- cmdInit -- optionally call to ensure early initialization
 * of cmd module.
 */
void cmdInit(void)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- isWordEnd -- return nonzero if the character is '\n','\0' or beacon character. 
 */

int isWordEnd(char ch, char cbeacon)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- isValidPhoneNumber -- return nonzero if the string is valid phone number.
 * the valid phone number including the charachter '0-9', ' ', '*', '-', '#',
 * '(', ')'.
 */
int isValidPhoneNumber(const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordLenWithBeacon -- return the length of string S with terminated beacon*/
int cmdWordLenWithBeacon(const char *S, char cbeacon)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordNextWithBeacon -- return the next string which these strings separated
 *by the special beacon character.
 */
const char* cmdWordNextWithBeacon(const char *S, char cbeacon)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdIsWord -- returns nonzero if S begins with a word.
 * A word is non-whitespace.
 */
int cmdIsWord(const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordLen -- returns length of word at begin of S.
 * A word is non-whitespace.
 * If S begins with whitespace, returns 0.
 */
int cmdWordLen(
        const char *S)  /* NOT NULL */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordDigits -- returns nonzero if word is made of digits
 * A word is non-whitespace; may be terminated by whitespace or null char.
 * Returns 1 if S is made of digits
 * Returns 0 otherwise
 */
int cmdWordDigits(const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordEq -- returns nonzero if two words are equal.
 * A word is non-whitespace; may be terminated by whitespace or null char.
 * Returns 0 if S1 and S2 are not both at words; a non-word can never
 * equal anything else.
 * Returns 0 if S1 or S2 is NULL.
 */
int cmdWordEq(const char *S1, const char *S2)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordFirst -- skip leading whitespace
 * Returns NULL if S is NULL.
 */
const char *cmdWordFirst(const char *S) 
;
                              /*-;-*/

                    /*-,- From cmd.c */
                    extern
/*-F- cmdGetCurrArgNullTerm -- get the current argument from S to Out.
*       Copies the word till the whitespace or upto Size-1 characters,
*       followed by NULL termination.
*       No more than the word size is copied; if S does not begin with
*       a word then the word size is zero.
*       A NUL char is always put at the end except where Size is zero.
*
*       Returns nonzero if Size <= 0 or the word was truncated.
*/
int cmdGetCurrArgNullTerm(const char *S, char *Out, int Size);

                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordNext -- skip word and following whitespace.
 * S should be sitting at a word; if it is sitting at whitespace,
 * we just skip the whitespace in an attempt to do something useful
 * in a broken situation.
 * A word is non-whitespace.
 * Returns NULL if S is NULL.
 */
const char *cmdWordNext(const char *S) 
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordNth -- returns "" or pointer to Nth word (0 based).
*       Skips initial whitespace.
*       Words are defined as for cmdIsWord().
*       Returns "" if S is NULL or if there is no Nth word.
*       If return value points to empty string, there is no Nth word.
*/
const char *cmdWordNth(
        const char *S,
        int N)  /* which word to find */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordCopy -- copy up to Size-1 chars of the first word from S
*       into Buf, followed by a NUL char for termination.
*       No more than the word size is copied; if S does not begin with
*       a word then the word size is zero.
*       A NUL char is always put at the end except where Size is zero.
*
*       Returns nonzero if Size <= 0 or the word was truncated.
*/       
int cmdWordCopy(
        char *Buf,      /* output buffer; not NULL */
        const char *S,  /* input or NULL */
        int Size)    /* bytes in Buf that can be modified */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdWordDup -- allocate and return a null-terminated copy of a word.
 * A word is non-whitespace.
 * Returns NULL on malloc failure.
 */
char *cmdWordDup(const char *S) ;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdLineDup -- allocate and return a newline- or null-terminated copy 
 * of line, minus trailing whitespace.
 * Returns NULL on malloc failure.
 */
char *cmdLineDup(const char *S) ;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdDupEncodeHex -- encode a buffer as a string of hex characters.
*       (Big endian representation).
*       The returned value (malloc'd memory which must be freed!)
*       will be null terminated string of twice the length as the input.
*       Returns NULL on malloc failure.
*/
char *cmdDupEncodeHex(const void *Buf, int NBytes)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdDupEscapeHex -- encode a string as a string of hex characters.
*       (Big endian representation).
*       The returned value (malloc'd memory which must be freed!)
*       will be null terminated string of twice the length as the input.
*       Returns NULL on malloc failure.
*/
char *cmdDupEscapeHex(const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdDupUnescapeHex -- decode hex encoding into string.
*       (Big endian representation).
*       The returned value (malloc'd memory which must be freed!)
*       will be null terminated string of half the length as the input.
*       Returns NULL on malloc failure.
*
*       Stops at first conversion error!
*/
char *cmdDupUnescapeHex(const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdDupEscapeC -- allocate a copy of string w/ character escape.
 *      Follows "C" rules for escaping:
 *              graphical and spaces unescaped except for  \
 *              \ --> \\
 *              other --> \ooo where "o" is octal digit
 *      If S is NULL, "" is implied.
 *      Returns NULL on malloc failure.
 */
char *cmdDupEscapeC(const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdDupUnescapeC -- allocate a copy w/ reverse translation
 *      compared with cmdDupEscapeC.
 *
 *      If S is NULL, "" is implied.
 *      Returns NULL on malloc failure.
 */
char *cmdDupUnescapeC(const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
/*-D- CMD_ESCAPE_XML_CHAR_BUF_SIZE -- minimal size buffer for cmdEscapeXmlChar
 */
#define CMD_ESCAPE_XML_CHAR_BUF_SIZE 8


                    /*-,- From cmd.c */
                    extern
/*-F- cmdEscapeXmlChar -- translate one utf-8 byte into xml sequence.
 *      Follows XML rules for escaping (note we assume utf-8 encoding):
 *              code 0x00 (nul character) terminates string
 *              Control characters (codes 0x01-0x1F and 0x7F) are encoded as 
 *                      &#decimal;
 *              where decimal is decimal value of control character.
 *              The following are specially translated:
 *                      "       &quot;
 *                      '       &apos;
 *                      &       &amp;
 *                      <       &lt;
 *                      >       &gt;
 *              Codes 0x80-0xFE are assumed to be parts of utf-8
 *              multi-character sequences.
 *              utf-8 multi-character sequences consist entirely of
 *              characters in the range 0x80-0xFD.
 *              There are some multi-character sequences that follow this
 *              rule but are not legal; we pass these through anyway.
 *              0xFE and 0xFF are illegal in utf8; we treat them as
 *              end of string.
 *      Returns number of output characters (0 at end of string),
 *      and puts output characters plus a terminating nul char into *Buf.
 */
int cmdEscapeXmlChar(
        char *Buf,     /* size at least CMD_ESCAPE_XML_CHAR_BUF_SIZE */
        unsigned char C)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdUnescapeXmlChar -- reverse translation of one char.
 *      Returns number of >consumed< bytes (0 at end of string),
 *      and puts output characters plus a terminating nul char into *Buf.
 */
int cmdUnescapeXmlChar(
        char *Buf,      /* at least 2 bytes big */
        const char *S)  /* input */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdEscapeXmlLength -- pre-compute length of escaped xml string.
 * Returns 0 if S is NULL.
 */
int cmdEscapeXmlLength(
        const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdUnescapeXmlLength -- pre-compute length of unescaped xml string.
 * Returns 0 if S is NULL.
 */
int cmdUnescapeXmlLength(
        const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdDupEscapeXml -- allocate a copy of string w/ character escape.
 *      If S is NULL, "" is implied.
 *      Returns NULL on malloc failure.
 */
char *cmdDupEscapeXml(const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdDupUnescapeXml -- allocate a copy w/ reverse translation
 *      compared with cmdDupEscapeXml.
 *
 *      If S is NULL, "" is implied.
 *      Returns NULL on malloc failure.
 */
char *cmdDupUnescapeXml(const char *S)
;
                              /*-;-*/


                    /*-,- From cmd.c */
/*-D- cmdMenuItem -- matches a callback function to a command name.
 */
struct cmdContext;
struct cmdMenuItem {
    const char *CommandName;            /* for match to first word */
    /* Caution: command handler callback function MUST not sleep!
     */
    void (*CommandHandler)(
            struct cmdContext *Context, /* As passed down */
            const char *Cmd); /* command string, excludes command name */
    /* Menu must be a menu if used with CommandHandler == cmdMenu
     * or a proxy thereof else it can be used for anything else
     * (it's value may be obtained using cmdItemDataGet()).
     */
    struct cmdMenuItem *Menu;        /* NULL or Menu to use or private use */
    const char * const *HelpMessage;   /* printed from help command */
};


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextCreate -- allocate a new independent context.
 * The returned context is zeroed, and then intialized from the
 * reference context, if one is provided, else from the default
 * reference context.
 * The context may be used as is to use the main menu (or menu assigned
 * to the reference context); 
 * otherwise, call cmdContextMenuSet() to assign a menu for it's use.
 * Returns NULL on malloc failure.
 *
 * Free up memory with cmdContextDestroy (not with free()).
 *
 * Changes to the context will not effect the "parent context".
 */
struct cmdContext *cmdContextCreate(
        struct cmdContext *ReferenceContext)       /* or NULL */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextDestroy -- deallocate a context safely.
 */
void cmdContextDestroy(struct cmdContext *Context)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextMenuSet -- assign menu array to be used for context.
 * The menu array should be terminated by a zeroed item.
 * Note that the menu array must be nonvolatile for the time
 * that the context is used, since it is used by pointer (not copy).
 */
void cmdContextMenuSet(
        struct cmdContext *Context,     /* NULL to set defaults */
        const struct cmdMenuItem *Menu)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextCommandNameSet -- assign command name assoc. w/ context.
 * The name is terminated by whitespace or null char, and is copied.
 */
void cmdContextCommandNameSet(
        struct cmdContext *Context,     /* NULL to set defaults */
        const char *CommandName)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextOutFdSet -- set fd for printfs.
 * The fd is NOT ever destroyed by cmd; it belongs to the caller.
 * For efficiency reasons, this is used only to the top level
 * context; it is used to temporarily redirect output to the shell
 * that is currently executing a command.
 */
void cmdContextOutFdSet(
        struct cmdContext *Context,     /* NULL to set defaults */
        int OutFd)              /* or 0 or -1 to disable */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextOutFileSet -- assign FILE* to print stuff to.
 * The FILE is NOT ever destroyed by cmd; it belongs to the caller.
 *
 * Cancels any previous cmdDebugHere() if done at same context.
 */
void cmdContextOutFileSet(
        struct cmdContext *Context,     /* NULL to set defaults */
        FILE *OutF)     /* output file queue, or NULL for stdout */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextOutFileGet -- returns FILE* to print stuff to.
 * This allows use of e.g. fprintf etc. 
 */
FILE *cmdContextOutFileGet(
        struct cmdContext *Context)     /* NULL for defaults */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextAutoPromptSet -- (un)set mode to print prompt after command.
 *      Will print a prompt immediately...
 *      be sure to set out file first, if needed.
 */
void cmdContextAutoPromptSet(
        struct cmdContext *Context,     /* NULL to set defaults */
        int Set)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextExitHandlerSet -- set handler called just before
*       context destruction.
*       (Any child context have already been destroyed).
*/
void cmdContextExitHandlerSet(
        struct cmdContext *Context,     /* NULL to set defaults */
        void (*ExitHandler)(struct cmdContext *Context))
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextPromptHandlerSet -- set function to print prompt.
*       The PromptHandler is called only when a prompt is needed.
*       The PromptHandler should do a cmdf(Context, ....)
*       to print the prompt.
*/
void cmdContextPromptHandlerSet(
        struct cmdContext *Context,     /* NULL to set defaults */
        void (*PromptHandler)(struct cmdContext *Context))
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextEnvDestroy -- remove environmental variable in given context
*/
void cmdContextEnvDestroy(
        struct cmdContext *Context,     /* NOT NULL */
        void *Key)              /* identify env. var */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdContextEnvGet -- get environmental variable in given session.
*       The session is the (grand)parent context of Context.
*       The Key is a unique pointer value used only to name the variable;
*       what the pointer points to is irrelevent.
*       The environmental variable is a data structure that is allocated
*       and zeroed if not previously existing in the context.
*       The application may write the environment data as it wishes.
*
*       Returns NULL on error.
*/
void *cmdContextEnvGet(
        struct cmdContext *Context,     /* NOT NULL */
        const void *Key,              /* identify env. var */
        unsigned Size)  /* MUST be passed same every time */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdf -- fprintf to correct place.
 * See cmdContextOutFileGet() for another alternative.
 */
void cmdf(
        struct cmdContext *Context,   /* NULL for default reference context */
        const char *Format,
        ...                     /* printf-like */
        )
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdv -- vfprintf to correct place.
 * See cmdContextOutFileGet() for another alternative.
 */
void cmdv(
        struct cmdContext *Context,   /* NULL for default reference context */
        const char *Format,
        va_list ArgP
        )
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-G- cmdHelpShortHelp -- help for short help command
 */
const char *cmdHelpShortHelp[] ;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdHelpShort -- short help command
 * Used by CMD_MENU_STANDARD_STUFF() which should be at top of your menu.
 */
void cmdHelpShort(
        struct cmdContext *Context, /* As passed down */
        const char *Cmd)  /* command string excludes command name */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-G- cmdHelpLongHelp -- help for long help command
 * Used by CMD_MENU_STANDARD_STUFF() which should be at top of your menu.
 */
const char *cmdHelpLongHelp[] ;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdHelpLong -- long help command
 */
void cmdHelpLong(
        struct cmdContext *Context, /* As passed down */
        const char *Cmd)  /* command string excludes command name */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-G- cmdQuitHelp -- help for q command
 */
const char *cmdQuitHelp[] ;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdQuit -- q (quit) command
 * Any command handler can cause a quit from the menu that refers it
 * by calling cmdQuit(Context,NULL).
 */
void cmdQuit(
        struct cmdContext *Context, /* As passed down */
        const char *Cmd)  /* ignored... may be NULL */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-G- cmdExitHelp -- help for exit command
 */
const char *cmdExitHelp[] ;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdExit -- exit command
 * This causes the server to terminate.
 */
void cmdExit(
        struct cmdContext *Context, /* As passed down */
        const char *Cmd)  /* ignored... may be NULL */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdNull -- a command that does nothing, in case you need it!
 */
void cmdNull(
        struct cmdContext *Context, /* As passed down */
        const char *Cmd)  /* ignored... may be NULL */
;
                              /*-;-*/


                    /*-,- From cmd.c */
/*-D- CMD_MENU_STANDARD_STUFF() -- put at top of most menus.
 * This provides commands for online help, and "q" command to quit menu.
 */
#define CMD_MENU_STANDARD_STUFF() \
    {"h", cmdHelpShort, NULL, cmdHelpShortHelp},        \
    {"help", cmdHelpLong, NULL, cmdHelpLongHelp},       \
    {"q", cmdQuit, NULL, cmdQuitHelp}


                    /*-,- From cmd.c */
/*-D- CMD_MENU_END() -- put at bottom of most menus.
 * This terminates the menu!
 */
#define CMD_MENU_END()  {}


                    /*-,- From cmd.c */
                    extern
/*-F- cmdMenuAdd -- copy item to end of pre-zeroed menu buffer.
 * Returns nonzero on error (menu full).
 */
int cmdMenuAdd(
        struct cmdMenuItem *Menu,       /* menu buffer */
        int MaxItems,           /* size of buffer, allowing for null item */
        const struct cmdMenuItem *Item)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdMainMenuAdd -- copy item to main menu.
 * Returns nonzero on error (menu full).
 */
int cmdMainMenuAdd(const struct cmdMenuItem *Item)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdMenu -- execute command string against arbitrary context.
 */
void cmdMenu(
        struct cmdContext *Context, /* must not be NULL */
        const char *S)
;
                              /*-;-*/

                    /*-,- From cmd.c */
                    extern
/*-F- cmdMenuDiag -- execute command and log into diagnostics debug.
 */
void cmdMenuDiag(
        char *Buf)
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdPromptMake -- make prompt based upon menus traversed.
 * This is useful for interactive shells.
 * If the prompt would get too long, tries to be smart about it.
 */
void cmdPromptMake(
        struct cmdContext *Context,     /* must not be NULL */
        char *Buf,      /* where to put the prompt */
        int BufMax)     /* size of buf */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdAutoPrompt -- emit auto-generated prompt, if enabled.
 *      Context is the root context, i.e. original context for session.
 */
void cmdAutoPrompt(
        struct cmdContext *Context)   /* must not be NULL */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdInputAdd -- add stream characters to buffering and invoke
 *      menu context for each line.
 *      Returns nonzero if stream termination is desired.
 */
int cmdInputAdd(
        struct cmdContext *Context,   /* must not be NULL */
        char *Buf,      /* buffer we're holding input in */
        int *BufFullP,  /* in/out: chars in buffer so far */
        int BufMax,     /* size of buffer */
        const char *Input,      /* input from stream */
        int InputSize   /* no. of bytes of input */
        )
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdInputFromFile -- execute from a file.
 * Reads from file must not block! ... so it must be a disk file.
 * Generally you will need to create a new context to use for this.
 *
 * Returns nonzero on error.
 */
int cmdInputFromFile(
        struct cmdContext *Context,   /* must not be NULL */
        const char *FilePath,
        char *Buf,              /* or NULL for default buffer */
        int BufSize)            /* if Buf is not NULL */
;
                              /*-;-*/


                    /*-,- From cmd.c */
                    extern
/*-F- cmdDebugHere -- fork debug messages to current session.
 * (The session is the (grand)parent context of Context).
 * Returns nonzero on error.
 * Does nothing (return 0) if already so redirected.
 *
 * With Enable==0, disables any previous fork.
 */
int cmdDebugHere(
        struct cmdContext *Context,   /* must not be NULL */
        int Enable
        )
;

/*-F- cmdInputLine -- Input a line from stream
 * This function will block the caller!
 * And it will not return until it reaches the ending of a line.
 * Returns the nubmer of characters, or -1 on errors
 */
int cmdInputLine(
        struct cmdContext *Context,   /* must not be NULL */
        char *Buf,              /* buffer  */
        int BufSize)            /* size of buffer */
;

/*-F- cmdInputPacket -- Input Packet from stream
 * Returns bytes of data, or -1 on errors
 */
int cmdInputPacket(
        struct cmdContext *Context,   /* must not be NULL */
        char *Buf,              /* buffer */
        int BufSize)            /* size of buffer */
;
 
#endif /* cmd__h */
