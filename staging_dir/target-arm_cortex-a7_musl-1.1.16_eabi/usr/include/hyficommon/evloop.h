/*
 * Copyright (c) 2010 Qualcomm Atheros, Inc.
 *
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#ifndef evloop__h
#define evloop__h

#include <stdlib.h>

                    /*-,- From evloop.c */
/*-M- evloop -- central event loop for single-threaded event-driven programs.
 *
 * Description:
 * evloop is suitable only for single-threaded programs which can be
 * written in an event-driven fashion, meaning that no code should
 * ever "block" or "sleep" other than the central event loop.
 * Typically main() will call initialization routines, and then disappear
 * into a call to evloopRun(), which makes occasional calls to 
 * registered callback functions when certain events happen.
 * These events are (as determined by the application)
 * the passage of a certain amount of time, or a (unix type)
 * socket or file ("descriptor") being ready to read or write.
 *
 * Callbacks can be registered in any single-thread context:
 * during the initializations before evloopRun() (at least some must be) 
 * and from any callback function.
 * Timeout callbacks automatically disable themselves when they expire.
 * By contrast, "ready" callbacks are called whenever a descriptor
 * is ready (to read or write depending on how registered) ... which
 * means that the callback function MUST actually read or write something,
 * or cancel the callback.
 * Generally a callback function should NOT do more than one call to
 * read() or write() as such would be blocking or might fail...
 * a write() might in any event write less than asked, so write buffering
 * should always be used.
 *
 * Callbacks are called with just one cookie, since that is usually
 * sufficient.
 * Should you need to use additional cookies, they can be set
 * with Cookie*Set functions and they can be obtained
 * using the Cookie*Get functions provided you can find the 
 * evloop object based on the first cookie.
 * One approach is to use the address of the evloop object as the
 * first cookie.
 * 
 * Implementation issues:
 * evloop is written for posix compliant (sp. linux) operating systems.
 * The assumption is made that timeouts may be honored milliseconds after scheduled
 * without harm, and for even longer periods after scheduling without any great
 * harm.
 * Since no system call to obtain "time since boot" with millisecond precision,
 * it is necessary to use the system call to get time of day time, which introduces
 * a problem in that the time of day may be changed arbitrarily using settimeofday()
 * by another process... the workaround for this issue requires that evloop sleep
 * for no more than a limited period (e.g. 20 seconds).
 */

                    /*-,- From evloop.c */
/*-D- Required includes
*/


                    /*-,- From evloop.c */
/*-D- EVLOOP_N_CONTEXT -- how many global variables set at each callback 
*  to provide a simple way of providing different contexts within the
*  same address space.
*  The variables are 
*     unsigned evloopContext[0] ... evloopContext[EVLOOP_N_CONTEXT-1]
*  and must be used according to some sort of program-wide strategy
*  for each program using evloop.
*  Each evloopTimeout or evloopReady has it's own copy of these
*  variables, copied from the global variables at creation time;
*  at each callback, they are copied back to the global variables.
*  The trick is to create static or global data as an array:
*       struct mydata myglobaldata[MY_N_CONTEXT];
*  and reference it as (assuming using evloopContext[0]):
*       myglobaldata[evloopContextGet(0))]
*  ... obviously the values assigned to evloopContext[0] must be
*  small integers less than MY_N_CONTEXT!
*
*  For portability, do NOT refer to evloopContext directly,
*  instead use access functions.
*/
#define EVLOOP_N_CONTEXT 0


                    /*-,- From evloop.c */
                    extern
/*-G- evloopContext -- see description below
*/
unsigned evloopContext[EVLOOP_N_CONTEXT];
                              /*-;-*/


                    /*-,- From evloop.c */
/*-D- evloopContextGet -- global variables set at each callback which
*  provide a simple way of providing different contexts within the
*  same address space.
*  The variables are 
*     unsigned evloopContext[0] ... evloopContext[EVLOOP_N_CONTEXT-1]
*  and must be used according to some sort of program-wide strategy
*  for each program using evloop.
*  Each evloopTimeout or evloopReady has it's own copy of these
*  variables, copied from the global variables at creation time;
*  at each callback, they are copied back to the global variables.
*  The trick is to create static or global data as an array:
*       struct mydata myglobaldata[MY_N_CONTEXT];
*  and reference it as (assuming using evloopContext[0]):
*       myglobaldata[evloopContextGet(0))]
*  ... obviously the values assigned to evloopContext[0] must be
*  small integers less than MY_N_CONTEXT!
*
*  For portability, do NOT refer to evloopContext directly,
*  instead use access functions.
*/
/* For efficiency, this must be inline! */
static inline unsigned evloopContextGet(int IContext)
{
    return evloopContext[IContext];
}


                    /*-,- From evloop.c */
/*-D- evloopTimeout -- control struct for event loop timeout detect.
 * DO NOT ACCESS FIELDS DIRECTLY! FOR FUTURE PORTABILITY AND 
 * ACCOUNTABILITY, USE THE PROVIDED ACCESS FUNCTIONS.
 */
struct evloopTimeout {
    struct evloopTimeout *Next;   /* for linked list */
    struct evloopTimeout *Prev;   /* for linked list */
    const char *Description;    /* for debugging */
    void (*CB)(void *Cookie1);        /* called on timeout */
    void *Cookie1;              /* app use */
    void *Cookie2;              /* app use */
    void *Cookie3;              /* app use */
    /* Timeout nodes are queued in order, with USecMore storing the additional
     * time to wait relative to the previous node... or relative to "now"
     * for the first node.
     */
    long long USecMore;         /* time to sleep after previous node */
    #if EVLOOP_N_CONTEXT > 0
    unsigned Context[EVLOOP_N_CONTEXT];
    #endif
};
static inline int evloopTimeoutArmedGet(struct evloopTimeout *T)
{
    return (T->Next != NULL);
}
static inline const char *evloopTimeoutDescriptionGet(struct evloopTimeout *T)
{
    return T->Description;
}
static inline void evloopTimeoutCookie1Set(
        struct evloopTimeout *T,
        void *Cookie1)
{
    T->Cookie1 = Cookie1;
}
static inline void *evloopTimeoutCookie1Get(struct evloopTimeout *T)
{
    return T->Cookie1;
}
static inline void evloopTimeoutCookie2Set(
        struct evloopTimeout *T,
        void *Cookie2)
{
    T->Cookie2 = Cookie2;
}
static inline void *evloopTimeoutCookie2Get(struct evloopTimeout *T)
{
    return T->Cookie2;
}
static inline void evloopTimeoutCookie3Set(
        struct evloopTimeout *T,
        void *Cookie3)
{
    T->Cookie3 = Cookie3;
}
static inline void *evloopTimeoutCookie3Get(struct evloopTimeout *T)
{
    return T->Cookie3;
}
#if EVLOOP_N_CONTEXT > 0
static inline unsigned evloopTimeoutContextValueGet(
        struct evloopTimeout *T,
        int IContext)
{
    return T->Context[IContext];
}
static inline void evloopTimeoutContextValueSet(
        struct evloopTimeout *T,
        int IContext,
        unsigned Value)
{
    /* NOTE: you should not have to use this function */
    T->Context[IContext] = Value;
}
#endif  // EVLOOP_N_CONTEXT > 0


                    /*-,- From evloop.c */
/*-D- evloopReady -- control struct for event loop descriptor ready detect.
 * DO NOT ACCESS FIELDS DIRECTLY! FOR FUTURE PORTABILITY AND 
 * ACCOUNTABILITY, USE THE PROVIDED ACCESS FUNCTIONS.
 */
struct evloopReady {
    struct evloopReady *Next;   /* for linked list */
    struct evloopReady *Prev;   /* for linked list */
    const char *Description;    /* for debugging */
    int Fd;                     /* which file descriptor */
    int Mode;          /* one of EVLOOP_READY_xxx */
    void (*CB)(void *Cookie1);  /* called when ready */
    void *Cookie1;              /* app use */   
    void *Cookie2;              /* app use */
    void *Cookie3;              /* app use */
    unsigned Events;    /* internal use by evloop module */
    #if EVLOOP_N_CONTEXT > 0
    unsigned Context[EVLOOP_N_CONTEXT];
    #endif
};
static inline const char *evloopReadyDescriptionGet(struct evloopReady *R)
{
    return R->Description;
}
static inline int evloopReadyFdGet(struct evloopReady *R)
{
    return R->Fd;
}
static inline void evloopReadyCookie1Set(
        struct evloopReady *R,
        void *Cookie1)
{
    R->Cookie1 = Cookie1;
}
static inline void *evloopReadyCookie1Get(struct evloopReady *R)
{
    return R->Cookie1;
}
static inline void evloopReadyCookie2Set(
        struct evloopReady *R,
        void *Cookie2)
{
    R->Cookie2 = Cookie2;
}
static inline void *evloopReadyCookie2Get(struct evloopReady *R)
{
    return R->Cookie2;
}
static inline void evloopReadyCookie3Set(
        struct evloopReady *R,
        void *Cookie3)
{
    R->Cookie3 = Cookie3;
}
static inline void *evloopReadyCookie3Get(struct evloopReady *R)
{
    return R->Cookie3;
}
#if EVLOOP_N_CONTEXT > 0
static inline unsigned evloopReadyContextValueGet(
        struct evloopTimeout *R,
        int IContext)
{
    return R->Context[IContext];
}
static inline void evloopReadyContextValueSet(
        struct evloopReady *R,
        int IContext,
        unsigned Value)
{
    /* NOTE: you should not have to use this function */
    R->Context[IContext] = Value;
}
#endif  // EVLOOP_N_CONTEXT > 0


                    /*-,- From evloop.c */
                    extern
/*-F- evloopTimeoutCreate -- set up timeout control (unregistered).
 *      After return from this function,
 *      the timeout struct can be registered and unregistered as needed.
 *      Do NOT call this if the timeout struct might be in use/registered.
 *      If the timeout struct is known to not be registered, then you
 *      may reuse the memory for any purpose (e.g. call free() or
 *      do another Create).
 *
 *      You may however change the cookies at any time after "Create", using 
 *      e.g. evloopTimeoutCookie1Set() etc.
 *      When registered timeout expires, the callback function CB
 *      whill be called back with the current value of Cookie1.
 */
void evloopTimeoutCreate(
        struct evloopTimeout *T,  /* control struct provided by app */
        const char *Description,    /* of nonvolatile string! for debugging */
        void (*CB)(void *Cookie1),
        void *Cookie1               /* app use */
        )
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopTimeoutRegister -- register to receive timeout notification.
 * Initially the control structure must have set up with eveloopTimeoutCreate.
 *
 * Once registered, it must not be written by the app 
 * (e.g. freed, or another call to evloopTimeoutCreate)
 * unless first unregistered... or if it is known with certainty to
 * have expired (better to cancel to be sure).
 * It is permitted to call evloopTimeoutRegister at any time
 * (after "Create") with a new timeout even if already registered...
 * any old timeout is forgotten.
 * The timeout is always relative to present (in the future).
 * The timeout is automatically cancelled when it expires,
 * at which point the callback (CB) function is called with the
 * current value of Cookie1.
 */
void evloopTimeoutRegister(
        struct evloopTimeout *T,  /* control struct provided by app */
        unsigned Seconds,           /* time in future relative from now */
        unsigned USec               /* microseconds component of rel. time */
        )
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopTimeoutUnregister -- cancel evloopTimeoutRegister registration.
 * Any pending timeout is cancelled.
 * OK to call even if not registered.
 * OK to call even if never "Create"d IFF the struct was zeroed
 * (as is the case for C static/global data).
 */
void evloopTimeoutUnregister(
        struct evloopTimeout *T   /* control struct provided by app */
        )
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopTimeoutRemaining -- compute remaining timeout for a evloopTimeout.
*       Returns nonzero and sets output to 0 if timeout is not active.
*/
int evloopTimeoutRemaining(
        struct evloopTimeout *T,  /* control struct provided by app */
        unsigned *SecondsP,      /* NULL or out */
        unsigned *USecP)         /* NULL or out */
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopReadReadyCreate -- init for descriptor ready notification.
 *
 * After "Create", the evloopReady object is in an "unregistered" state,
 * meaning that it is inactive.
 * You will need to call evloopReadRegister once initially
 * to activate, after which you can switch activation on and off
 * via calls to "Register" and "Unregister".
 *
 * Do NOT reuse the memory for other purposes or call "Create" again
 * UNLESS the evloopReady object is unregistered 
 * (call "Unregister" to make sure).
 */
void evloopReadReadyCreate(
        struct evloopReady *R,  /* control struct provided by app */
        const char *Description,    /* of nonvolatile string! for debugging */
        int Fd,                 /* file descriptor; -1 to cancel */
        void (*CB)(void *Cookie1),      /* called when ready */
        void *Cookie1               /* app use */
        )
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopWriteReadyCreate -- init for descriptor ready notification.
 *
 * After "Create", the evloopReady object is in an "unregistered" state,
 * meaning that it is inactive.
 * You will need to call evloopReadRegister once initially
 * to activate, after which you can switch activation on and off
 * via calls to "Register" and "Unregister".
 *
 * Do NOT reuse the memory for other purposes or call "Create" again
 * UNLESS the evloopReady object is unregistered 
 * (call "Unregister" to make sure).
 */
void evloopWriteReadyCreate(
        struct evloopReady *R,  /* control struct provided by app */
        const char *Description,    /* of nonvolatile string! for debugging */
        int Fd,                 /* file descriptor; -1 to cancel */
        void (*CB)(void *Cookie1),      /* called when ready */
        void *Cookie1               /* app use */
        )
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopReadyRegister -- register for descriptor ready notification.
 * Callback CB will be called when Fd is ready to read or write
 * (depending upon how created). 
 * CB is called with current value of Cookie1 as argument.
 *
 * Once registered, it must not be written by the app (e.g. freed
 * or new call to "Create") unless first unregistered.
 */
void evloopReadyRegister(
        struct evloopReady *R)  /* control struct provided by app */
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopReadyUnregister -- cancel evloopReadyRegister registration.
 * The evloopReady struct is unmodified except for being removed
 * from the active list.
 * OK to call even if already unregistered.
 * OK to call even if never "Create"d IFF the memory was zeroed
 * (as is true for C static/global data).
 */
void evloopReadyUnregister(
        struct evloopReady *R)  /* control struct provided by app */
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopContextSet -- set global IContext'th variable to Value
*       This should normally only be done from main() or similar
*       in an initialization loop of contexts before calling evloopRun();
*       and will affect all subsequent creates.
*/
void evloopContextSet(int IContext, unsigned Value)
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopOnce -- wait once for events and dispatch.
 */
/*static*/ void evloopOnce(void)
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopRun -- endless loop waiting for events and calling callbacks.
 * This will typically be the last thing called from main(),
 * following initializations.
 * It never returns unless evloopAbort() is called from some callback
 * function or signal handler.
 */
void evloopRun(void)
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopAbort -- cause evloopRun to return to caller at next opportunity.
 * Unlike most other evloop functions, can be called from a signal handler.
 */
void evloopAbort(void)
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopRunPrepare
 */
void evloopRunPrepare(void)
;
                              /*-;-*/


                    /*-,- From evloop.c */
                    extern
/*-F- evloopIsAbort
 */
int evloopIsAbort(void)
;

#endif  /* evloop__h */
