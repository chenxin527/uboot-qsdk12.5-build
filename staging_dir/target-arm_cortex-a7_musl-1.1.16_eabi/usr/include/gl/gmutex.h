/*
 * gmutex.h
 *
 *  Created on: Sep 4, 2016
 *      Author: parallels
 */

#ifndef SRC_PUB_GMUTEX_H_
#define SRC_PUB_GMUTEX_H_

#include <semaphore.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Generate a resource lock or use an existing one
 */
extern sem_t* glock_init(const char* resource_name);

/**
 * Wait until the resource is available
 * Returns: 0 on success, other value when failed
 */
extern int glock_wait(sem_t* resource_lock);

/**
 * Try to access the resource, returns immediately if unavailable
 * Returns: 0=available, other value if occupied by other processes
 */
extern int glock_try_wait(sem_t* resource_lock);

/**
 * Release a resource. Must be called in pair with glock_wait().
 */
extern int glock_exit(sem_t* resource_lock);

/**
 * Free the resource lock. Must be called in pair with glock_init().
 */
extern void glock_free(sem_t* resource_lock,const char* resource_name);

/**
 * Free a resource lock when it is in an ill condition (e.g., process aborted before calling glock_exit and glock_free)
 */
extern void glock_force_free(const char* resource_name);

///**
// * Lock a resource once for exclusive access. This is only used for infrequent access.
// * For frequent access, use the combination of glock_init, glock_wait, glock_exit, glock_free instead.
// */
//sem_t* glock_lockonce(const char* resource_name);
//
///**
// * Free the resource lock. Must be called in pair with glock_lockonce().
// */
//int glock_unlockonce(sem_t* resource_lock,const char* resource_name);
//

#ifdef __cplusplus
}
#endif

#endif /* SRC_PUB_GMUTEX_H_ */
