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

#ifndef dbg__h
#define dbg__h
                    /*-,- From dbg.c */
/*-M- dbg -- debug printf system.
 *                              Author: Ted Merrill, June 2008
 *
 * The idea:
 * You put into your code statements such as:
 *      #include <dbg.h>
 *      ...
 *      struct dbgModule *fooDebugModule;
 *      ...
 *      fooDebugModule = dbgModuleFind("foo");
 *      ...
 *      #define foof(...) dbgf(fooDebugModule, __VA_ARGS__)
 *      ...
 *      foof(DBGDEBUG, "Entering function fooBar x=%d", x);
 *      ...
 * and the message will be printed to stderr (or can be redirected or
 * forked) only if debugs have been turned on for module "foo" at level
 * DBGDEBUG or higher... or if debugs have been turned on at this level
 * or higher globally.
 * And how to turn on such debugs? through environmental variable "DBG_LEVELS"
 * or by other means as provided (e.g. command line args, debugging menu, etc),
 * which take precedence over environmental variables in the order invoked.
 *
 * Environmental variables:
 *
 * DBG_LEVELS -- this environmental variable is read at startup.
 * It may contain multiple of the form <modulename>=<level>
 * separated by commas,
 * where <modulename> is a name that will (or may) be used by later
 * dbgf calls, <level> is one of the strings NONE, ERR, INFO,
 * DEBUG, or DUMP.
 * Also <modulename> can be "all" to set all modules to the new level:
 *      for example, DBG_LEVELS=all=DEBUG
 * The module name "unknown" may have a special meaning if software
 * fails to use dbgModuleFind() to obtain a handle (and use NULL instead).
 *
 * DBG_APPEND_FILE_PATH -- this environmental variable is read at startup
 * and if present determines file path to write debug messages to.
 * The output file is appended to, if it pre-exists.
 *
 * DBG_OUT_FILE_PATH -- this environmental variable is read at startup
 * and if present determines file path to write debug messages to.
 * The output file is first truncated, if it pre-exists.
 * (DBG_APPEND_FILE_PATH has precedence).
 *
 * TODO:
 * -- Add replication of messages to multiple FILEs
 */

                    /*-,- From dbg.c */
/*-D- Required includes
 */
#include <stdio.h>
#include <stdarg.h>


                    /*-,- From dbg.c */
/*-D- dbgLevel -- allows filtering according to levels of importance.
 */
enum dbgLevel {
    DBGNONE = -1,       /* suppress all dbg messages */
    DBGERR = 0,         /* for serious errors only */
        /* ERR: Serious errors are errors in the local firmware */
    DBGINFO = 1,        /* important information, including minor errors */
        /* INFO: Major events, and apparent errors of other hosts */
    DBGDEBUG = 2,       /* for typical debugging */
        /* DEBUG: Messages useful for debugging individual modules */
    DBGDUMP = 3         /* for volumnous outputs */
        /* DUMP: e.g. packet traces etc. */
};


                    /*-,- From dbg.c */
/*-D- dbgModule -- track debugging module information 
 */
struct dbgModule {
    /* do NOT access fields directly -- use access functions! */
    const char *ModuleName;
    unsigned NameHash;
    enum dbgLevel Level;
    struct dbgModule *HashNext;
    struct dbgModule *AddedNext;
};


                    /*-,- From dbg.c */
                    extern
/*-F- dbgProgramNameSet -- set program name to use in dbg messages.
 * This does not need to be same name as actual program, and in fact
 * is best kept very short ...
 * try to keep all program names <= 4 chars for best readability
 * on terminal windows of limited width.
 */
void dbgProgramNameSet(const char *Name) ;
                              /*-;-*/


                    /*-,- From dbg.c */
/*-D- dbgInitOptions -- options to pass to dbgInit1
 *      The ProgramName should be a four letter name for best formatting.
 *      The EnvName is the name of an environmental variable to use for
 *      debug levels initialization.
 *      If this is NULL or there is no env. variable by the given name,
 *      the environmental variable DBG_LEVELS is used if present.
 */
struct dbgInitOptions {
    char *ProgramName;  /* NULL, but should be 4 letter program name */
    char *EnvName;      /* NULL; or instead of DBG_LEVELS */
};


                    /*-,- From dbg.c */
                    extern
/*-F- dbgInit1 -- first time initialization, with options.
 */
void dbgInit1(
        const struct dbgInitOptions *Opt)       /* input */
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgFILERedirect -- redirect output using FILE *
 */
void dbgFILERedirect(
        FILE *OutF,
        int AutoClose)  /* close if redirected again */
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgFileRedirect -- redirect output to file.
 * Returns nonzero if error (can't write to file).
 */
int dbgFileRedirect(
        const char *FilePath,
        int Append)     /* nonzero to append to this file if it exists */
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgFileRedirectCancel -- cancel message redirection
 */
void dbgFileRedirectCancel(void)
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgOutFork -- copy dbg output to another place.
 * CAUTION: non-responsive pipes etc. can cause
 * blocking of the main event loop!
 *
 * To undo the forking, call dbgOutForkCancel.
 * Make sure you do this before closing the output FILE.
 *
 * Returns NULL if error.
 */
struct dbgOutput * dbgOutFork(
        FILE *OutF
        )
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgOutForkCancel -- remove dbg output forking.
 * Does not affect the default output stream.
 * Does not close OutF.
 */
void dbgOutForkCancel(
        struct dbgOutput *Out   /* from dbgOutFork; or NULL is ignored */
        )
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgLevelFromString -- convert level name or numeral to number.
 *      Returns nonzero if error.
 */
int dbgLevelFromString(
    const char *S,      /* string to convert */
    enum dbgLevel *LevelP       /* output */
    )
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgLevelToString -- convert level to level name
 * Returns NULL if no match.
 */
const char *dbgLevelToString(enum dbgLevel Level)
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgModuleFind -- find module / add module to list of known modules.
 * The returned handled will be needed to make calls to change
 * per-module debugging attributes.
 * For efficiency, call this once and remember the handle.
 */
struct dbgModule * dbgModuleFind(const char *ModuleName)
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgModuleLevelSet -- set module debug level
 */
void dbgModuleLevelSet(
        struct dbgModule *MP, 
        int Level)
;
                              /*-;-*/


                    /*-,- From dbg.c */
/*-D- dbgModuleLevelGet -- get module debug level
*       Note that this may change at runtime!
*/
static inline enum dbgLevel dbgModuleLevelGet(
        struct dbgModule *MP)   /* if NULL, a harmless value is returned */
{
    if (MP)
        return MP->Level;
    return (enum dbgLevel) 999;  /* force a debug message so Init will be called */
}


                    /*-,- From dbg.c */
                    extern
/*-F- dbgAllModulesLevelSet -- set all present and future modules to level.
 */
void dbgAllModulesLevelSet(enum dbgLevel Level)
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgModuleLevelFromBuf -- store result of <modulename>[=]<level>
 * Returns nonzero if error.
 * Not an error if there is no <level> value.
 * <modulename> and <level> can be separated by whitespace and/or
 * equal sign.
 *
 * NOTE NOTE the passed buffer is scribbled over (within the bounds
 * of the original string).
 */
int dbgModuleLevelFromBuf(
        char *B)        /* we can scribble over this input */
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgModuleLevelsFromString -- set levels of zero or more modules.
 * String may contain multiple of the form <modulename>=<level>
 * separated by commas,
 * where <modulename> is a name that will (or may) be used by later
 * dbgf calls, <level> is one of the strings NONE, ERR, INFO,
 * DEBUG, or DUMP.
 * Also <modulename> can be "all" to set all modules to the new level.
 *
 * Returns nonzero if there were any errors, in which case the
 * operation is completed as much as it can be.
 */
int dbgModuleLevelsFromString(const char *S)
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgParseCmdFromBuffer -- parse commands from buffer.
 * Wrapper to format Commands and apply to diag or dbg or cmd modules.
 * dbg level command <modulename> and <level> can be separated by whitespace and/or
 * equal sign.
 * Diagnostics commands should be separated by whitespaces.
 * All other commands could be used as it is.
 *
 * NOTE NOTE the passed buffer is scribbled over (within the bounds
 * of the original string).
 */
void dbgParseCmdFromBuffer(char *B);
                              /*-;-*/


                    /*-,- From dbg.c */
/*-D- dbgf -- conditionally print a debug message.
 * The message is printed if Level is less than or equal to the module level.
 * The module level defaults to global debug level.
 *
 * Return value is undefined.
 */
#ifdef __RELEASE__
#define dbgf(...) 
#else
int Dbgf(
        struct dbgModule *MP,
        enum dbgLevel Level,
        const char *Format,
        ...)    /* printf-like args */
        #ifdef __GNUC__
        __attribute__ ((format (printf, 3, 4)))
        #endif 
        ;
#define dbgf(...) Dbgf(__VA_ARGS__)
#endif


                    /*-,- From dbg.c */
                    extern
/*-F- dbgLevelsPrint -- print debug levels per module.
 * Pass NULL to print all modules.
 */
void dbgLevelsPrint(
        FILE *OutF,
        const char *ModuleName)     /* or NULL for all */
;
                              /*-;-*/


                    /*-,- From dbg.c */
                    extern
/*-F- dbgStatusPrint -- print useful info about dbg state
 * including debug levels.
 */
void dbgStatusPrint(FILE *OutF)
;

#endif  /* dbg__h */
