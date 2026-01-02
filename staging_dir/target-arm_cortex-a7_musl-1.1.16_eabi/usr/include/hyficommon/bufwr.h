/*
 * Copyright (c) 2010 Qualcomm Atheros, Inc.
 *
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#ifndef bufwr__h
#define bufwr__h
                    /*-,- From bufwr.c */
/*-M- bufwr -- buffered writing for single-threaded event-driven programs.
 *
 * This module implements flow control for writing to e.g. TCP 
 * and UDP sockets.
 * A producer callback function is called whenever a buffer for the
 * produced data is below a low water mark of fullness AND the 
 * socket / descriptor is ready for writing.
 * The producer callback function should then generate some more data;
 * the amount of data it generates is not limited but care should be
 * taken not to generate too much at one time in order to avoid
 * excessive memory consumption.
 * Asyncronously, when the socket / descriptor is ready for writing,
 * data is written to the descriptor.
 *
 * The application must maintain a "struct bufwr" control block.
 * After the descriptor has been obtained, the control block is 
 * initialized via a call to bufwrCreate().
 * When the application callback is called, it should pass data
 * via bufwrWrite().
 * When the control block is no longer needed, it should be cleaned
 * via a call to bufwrDestroy*() (this close the file descriptor...
 * dup it if you need to keep it).
 *
 * Calls to bufwrWrite() may be made from any single-threaded context,
 * not just the callback function.
 * If the application callback does not have anything to write, it
 * doesn't have to; it may be called one or more times again but
 * will eventually not be called any more if no more has been written.
 * At any time, the application can (from some other context)
 * write more which will resume the cycle of calling the callback.
 *
 * Up to three cookies (Cookie1, Cookie2 and Cookie3) may be stored
 * by the application in the bufwr object.
 * Cookie1 is normally set by the Create() call, and may be changed
 * thereafter using the SetCookie1 function, and the other cookies
 * may be set after the Create() call using the SetCookie* functions.
 * The current value of Cookie1 is passed to the callback function,
 * and the other cookies can be obtained using the GetCookie* functions
 * provided that the burwr object can be located; one possibility
 * is to use the ptr to the burwr object as Cookie1 and then use
 * the GetCookie2 and GetCookie3 functions to get two cookies.
 */

                    /*-,- From bufwr.c */
/*-D- Required includes
*/
#include <evloop.h>


                    /*-,- From bufwr.c */
/*-D- bufwr -- control structure for buffered writing.
 */
struct bufwr {
    struct evloopReady Ready;   /* Direct interface to event loop */
    void (*CB)(void *Cookie1);
            /* CB: NULL or called when pending bytes <= LowWater */
    void *Cookie1;              /* app use */   
    unsigned LowWater;
    unsigned char *Buf;         /* NULL or buffering */
    int BufSize;                /* nbytes alloc in *Buf if Buf != NULL */
    int NFull;                  /* how many bytes stored */
    unsigned Fatal : 1;         /* set on fatal error */
    unsigned IOError : 1;       /* set on write error */
    unsigned Quit : 1;          /* nonzero for delayed destroy */
    unsigned Allocated : 1;     /* if buffer was allocated w/ malloc */
    unsigned Fixed : 1;         /* if buffer will not be reallocated */
};



                    /*-,- From bufwr.c */
/*-D- bufwrErrorGet -- returns nonzero on fatal error.
 */
static inline int bufwrErrorGet(struct bufwr *B)
{
    return B->Fatal;
}



                    /*-,- From bufwr.c */
/*-D- bufwrWriteErrorGet -- returns nonzero on (fatal) write error.
*       This helps distinguish from memory allocation errors.
*/
static inline int bufwrWriteErrorGet(struct bufwr *B)
{
    return B->IOError;
}



                    /*-,- From bufwr.c */
/*-D- bufwrQGet -- return no. of bytes waiting to be written.
 */
static inline int bufwrQGet(struct bufwr *B)
{
    return B->NFull;
}



                    /*-,- From bufwr.c */
/*-D- bufwrDescriptionGet -- return buffer description.
 */
static inline const char *bufwrDescriptionGet(struct bufwr *B)
{
    return evloopReadyDescriptionGet(&B->Ready);
}



                    /*-,- From bufwr.c */
/*-D- bufwrFdGet -- return which descriptor.
 */
static inline int bufwrFdGet(struct bufwr *B)
{
    return evloopReadyFdGet(&B->Ready);
}



                    /*-,- From bufwr.c */
/*-D- bufwrCookie1Get -- return 1st application cookie.
 */
static inline void *bufwrCookie1Get(struct bufwr *B)
{
    return B->Cookie1;
}



                    /*-,- From bufwr.c */
/*-D- bufwrCookie2Get -- return 2nd application cookie.
 */
static inline void *bufwrCookie2Get(struct bufwr *B)
{
    return evloopReadyCookie2Get(&B->Ready);
}



                    /*-,- From bufwr.c */
/*-D- bufwrCookie3Get -- return 3rd application cookie.
 */
static inline void *bufwrCookie3Get(struct bufwr *B)
{
    return evloopReadyCookie3Get(&B->Ready);
}



                    /*-,- From bufwr.c */
/*-D- bufwrCookie1Set -- set 1st application cookie.
 */
static inline void bufwrCookie1Set(
        struct bufwr *B,
        void *Cookie1)
{
    B->Cookie1 = Cookie1;
}



                    /*-,- From bufwr.c */
/*-D- bufwrCookie2Set -- set 2nd application cookie.
 */
static inline void bufwrCookie2Set(
        struct bufwr *B,
        void *Cookie2)
{
    evloopReadyCookie2Set(&B->Ready, Cookie2);
}



                    /*-,- From bufwr.c */
/*-D- bufwrCookie3Set -- set 3rd application cookie.
 */
static inline void bufwrCookie3Set(
        struct bufwr *B,
        void *Cookie3)
{
    evloopReadyCookie3Set(&B->Ready, Cookie3);
}



                    /*-,- From bufwr.c */
                    extern
/*-F-  bufwrFlush -- force some data out of buffer
 * If FlushAll==0, can return after flushing only some
 * (can occur if a short write occurs).
 * If FlushAll != 0, returns only after flushing all or if error.
 *
 * Returns nonzero on fatal error (B->Fatal also set).
 */
int bufwrFlush(
        struct bufwr *B,
        int FlushAll)
;
                              /*-;-*/


                    /*-,- From bufwr.c */
                    extern
/*-F- bufwrCreate -- set up write buffering
 * The descriptor Fd is "given" to bufwr, and will be closed by
 * bufwrDestroy*() ... dup it if you need to keep it.
 */
void bufwrCreate(
        struct bufwr *B,        /* control struct provided by app */
        const char *Description,    /* of nonvolatile string! for debugging */
        int Fd,                 /* descriptor to write to */
        int LowWater,           /* call CB when we have <= this many bytes */
        void (*CB)(void *Cookie1),      /* NULL, or called when ready */
        void *Cookie1               /* app use */
        )
;
                              /*-;-*/


                    /*-,- From bufwr.c */
                    extern
/*-F- bufwrBufferSet -- set buffer/size to use.
 * The buffer will now not be allowed to grow (except BufSize == 0).
 * Additions that would exceed the buffer result in immediate,
 * possibly blocking writes to the file descriptor.
 * This must be called after bufwrCreate but only when nothing is buffered.
 *
 * If BufSize is <= 0 and Buf is NULL the buffer is allowed to
 * grow again as needed.
 * If BufSize is <= 0 and Buf is non-NULL the buffer is not used
 * and all writes are done immediately even if they block.
 */
void bufwrBufferSet(
        struct bufwr *B,        /* control struct provided by app */
        void *Buf,      /* NULL to malloc; or buffer to use */
        int BufSize)    /* size of buffer / to malloc */
;
                              /*-;-*/


                    /*-,- From bufwr.c */
                    extern
/*-F- bufwrDestroyNow -- take down write buffering
 * This unregisters and frees allocated buffer if any,
 * as well as freeing the file descriptor!
 * Any data not yet actually written will be lost.
 * Don't use B after this.
 */
void bufwrDestroyNow(
        struct bufwr *B)        /* control struct provided by app */
;
                              /*-;-*/


                    /*-,- From bufwr.c */
                    extern
/*-F- bufwrDestroyDelayed -- take down write buffering
 * after all output has been written.
 * Don't use B after this.
 */
void bufwrDestroyDelayed(
        struct bufwr *B)        /* control struct provided by app */
;
                              /*-;-*/


                    /*-,- From bufwr.c */
                    extern
/*-F- bufwrWrite -- add bytes to be written when possible.
 * Returns nonzero on fatal error, after which the bufwr should
 * be destroyed.
 *
 * Feature: if "Fixed" flag is set, and a packet passed per call
 * to bufwrWrite(), the actual writes to sockets etc.
 * will preserve the packet boundaries (but may put multiple
 * packets into one).
 */
int bufwrWrite(
        struct bufwr *B,
        const char *Buf,
        int NBytes)     /* now much to write from Buf */
;
                              /*-;-*/


                    /*-,- From bufwr.c */
                    extern
/*-F- bufwrWriteString -- add bytes to be written when possible.
 * No. of bytes determined by strlen.
 * Returns nonzero on fatal error, after which the bufwr should
 * be destroyed.
 */
int bufwrWriteString(
        struct bufwr *B,
        const char *Buf)        /* null terminated string */
;
                              /*-;-*/

#endif  /* bufwr__h */
