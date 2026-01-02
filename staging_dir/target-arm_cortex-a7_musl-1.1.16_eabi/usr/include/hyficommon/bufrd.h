/*
 * Copyright (c) 2010 Qualcomm Atheros, Inc.
 *
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#ifndef bufrd__h
#define bufrd__h
                    /*-,- From bufrd.c */
/*-M- bufrd -- buffered reading for single-threaded event-driven programs.
 *
 * The reason for buffering reads is to allow the application to
 * group data out of the input stream.
 * Since the input stream may come in in chunks unaligned to the
 * intended blocking of the data, using buffering becomes essential.
 * The bufrd module also tracks error / end of file condition.
 *
 * The application maintains a "struct bufrd" control block.
 * After obtaining the socket/stream/file descriptor, the application
 * intializes the control block via a call to bufrdCreate(),
 * which sets up the buffering and polling of descriptor.
 * Thereafter, the application callback function is called whenever
 * more data is added (by bufrd) to the buffer.
 * The callback function should do the following:
 * -- Check for errors / EOF via bufrdErrorGet(). Close out if error.
 * -- Obtain buffer address and content size via calls to
 *      bufrdBufGet() and bufrdNBytesGet().
 * -- Check if the buffer obtains complete parsing units or not.
 *      If so, parse the unit and call bufrdConsume for each parsing unit
 *      (call bufrdBufGet() and bufrdNBytesGet() each time).
 *      It is permissible to modify the parsing unit in place if that
 *      helps.
 * When the buffering is no longer needed, it should be closed out
 * with bufrdDestroy() call. (This closes the file descriptor...
 * dup it if you need it).
 *
 * In case the application is not ready to process the data when the
 * callback is called, it may simply do nothing, but at some later
 * time the above described processing should be done from another context.
 *
 * Up to three cookies (Cookie1, Cookie2 and Cookie3) may be stored
 * by the application in the bufrd object.
 * Cookie1 is normally set by the Create() call, and may be changed
 * thereafter using the SetCookie1 function, and the other cookies
 * may be set after the Create() call using the SetCookie* functions.
 * The current value of Cookie1 is passed to the callback function,
 * and the other cookies can be obtained using the GetCookie* functions
 * provided that the bufrd object can be located; one possibility
 * is to use the ptr to the bufrd object as Cookie1 and then use
 * the GetCookie2 and GetCookie3 functions to get two cookies.
 */

                    /*-,- From bufrd.c */
/*-D- required includes
*/
#include <evloop.h>



                    /*-,- From bufrd.c */
/*-D- bufrd -- control structure for buffered reading.
 */
struct bufrd {
    struct evloopReady Ready;   /* Direct interface to event loop */
    /* CB: NULL or called when more is added to Buf.  */
    void (*CB)(void *Cookie1);
    void *Cookie1;              /* app use */   
    unsigned char *Buf;         /* NULL or buffering */
    int BufSize;                /* nbytes alloc in *Buf if Buf != NULL */
    int NBytes;                 /* no. of bytes waiting in Buf */
    int Fatal;                  /* nonzero on fatal error or EOF */
};



                    /*-,- From bufrd.c */
/*-D- bufrdErrorGet -- returns nonzero on fatal error.
 */
static inline int bufrdErrorGet(struct bufrd *B)
{
    return B->Fatal;
}



                    /*-,- From bufrd.c */
/*-D- bufrdBufGet -- get buffer location.
 * May return NULL if nothing is buffered.
 */
static inline void *bufrdBufGet(struct bufrd *B)
{
    return B->Buf;
}



                    /*-,- From bufrd.c */
/*-D- bufrdNBytesGet -- get buffer content size.
 */
static inline int bufrdNBytesGet(struct bufrd *B)
{
    return B->NBytes;
}



                    /*-,- From bufrd.c */
/*-D- bufrdDescriptionGet -- return buffer description.
 */
static inline const char *bufrdDescriptionGet(struct bufrd *B)
{
    return evloopReadyDescriptionGet(&B->Ready);
}



                    /*-,- From bufrd.c */
/*-D- bufrdFdGet -- return which descriptor.
 */
static inline int bufrdFdGet(struct bufrd *B)
{
    return evloopReadyFdGet(&B->Ready);
}



                    /*-,- From bufrd.c */
/*-D- bufrdCookie1Get -- return 1st application cookie.
 */
static inline void *bufrdCookie1Get(struct bufrd *B)
{
    return B->Cookie1;
}



                    /*-,- From bufrd.c */
/*-D- bufrdCookie2Get -- return 2nd application cookie.
 */
static inline void *bufrdCookie2Get(struct bufrd *B)
{
    return evloopReadyCookie2Get(&B->Ready);
}



                    /*-,- From bufrd.c */
/*-D- bufrdCookie3Get -- return 3rd application cookie.
 */
static inline void *bufrdCookie3Get(struct bufrd *B)
{
    return evloopReadyCookie3Get(&B->Ready);
}



                    /*-,- From bufrd.c */
/*-D- bufrdCookie1Set -- set 1st application cookie.
 */
static inline void bufrdCookie1Set(
        struct bufrd *B,
        void *Cookie1)
{
    B->Cookie1 = Cookie1;
}



                    /*-,- From bufrd.c */
/*-D- bufrdCookie2Set -- set 2nd application cookie.
 */
static inline void bufrdCookie2Set(
        struct bufrd *B,
        void *Cookie2)
{
    evloopReadyCookie2Set(&B->Ready, Cookie2);
}



                    /*-,- From bufrd.c */
/*-D- bufrdCookie3Set -- set 3rd application cookie.
 */
static inline void bufrdCookie3Set(
        struct bufrd *B,
        void *Cookie3)
{
    evloopReadyCookie3Set(&B->Ready, Cookie3);
}



                    /*-,- From bufrd.c */
                    extern
/*-F- bufrdCreate -- set up read buffering
 * The descriptor Fd is "given" to bufrd, and will be closed by
 * bufrdDestroy() ... dup it if you need to keep it.
 */
void bufrdCreate(
        struct bufrd *B,        /* control struct provided by app */
        const char *Description,    /* of nonvolatile string! for debugging */
        int Fd,                 /* descriptor to write to */
        int BufSize,            /* how large a buffer to use */
        void (*CB)(void *Cookie1),      /* NULL, or called when ready */
        void *Cookie1               /* app use */
        )
;
                              /*-;-*/


                    /*-,- From bufrd.c */
                    extern
/*-F- bufrdDestroy -- take down read buffering
 * This unregisters and frees allocated buffer if any.
 */
void bufrdDestroy(
        struct bufrd *B         /* control struct provided by app */
        )
;
                              /*-;-*/


                    /*-,- From bufrd.c */
                    extern
/*-F- bufrdConsume -- call when one or more bytes from front of buffer
 * have been processed and should not be seen again.
 */
void bufrdConsume(
        struct bufrd *B,        /* control struct provided by app */
        int NBytes)             /* no. of bytes to take off of buffer */
;
                              /*-;-*/


                    /*-,- From bufrd.c */
                    extern
/*-F- bufrdLineDup -- returns copy of next text line in buffer,
 *      which is consumed.
 *      The text line must end with a newline character, which is
 *      replaced in the copy with a null character; however,
 *      an extra space is left in the allocation so that the
 *      newline may be restored (two null chars are put at end,
 *      the first of which can be replaced with a newline).
 *      If there is not a line of text available, returns NULL.
 *
 *      The returned memory must be freed via call to free().
 */
char *bufrdLineDup(
        struct bufrd *B)        /* control struct provided by app */
;
                              /*-;-*/

#endif  /* bufrd__h */
