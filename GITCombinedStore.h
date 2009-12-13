//
//  GITCombinedStore.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 24/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITObjectStore.h"

/*! A series of priority levels for use when adding stores to a GITCombinedStore
 */
typedef enum {
    GITHighPriority = 0,    //!< Adds the store to the head of the list so it is checked first
    GITNormalPriority = 1,  //!< Adds the store to the end of the list
    GITLowPriority = 2,     //!< Adds the store to the end of the list
} GITCombinedStorePriority;

/*! Implements a store which is composed of other stores.
 * The GITCombinedStore allows the user to combine a selection of GITObjectStore subclasses into
 * a single store unit. The primary use would be for combining a GITFileStore with a GITPackStore
 * so that both loose file objects and packed objects can be accessed through one object.
 */
@interface GITCombinedStore : GITObjectStore
{
    NSMutableArray * stores;
    GITObjectStore * recentStore;
}

@property(readonly,retain) NSMutableArray * stores;

/*! Creates and returns a new combined store.
 * The newly created store will have no internal stores until you add them with
 * a call to <tt>-addStore:</tt> or <tt>-addStore:priority:</tt>.
 * \returns A new combined store
 */
- (id)init;

/*! Creates and returns a new combined store with the provided stores.
 * The newly created store will be composed of the stores provided.
 * \param firstStore A variable nil terminated list of stores to add
 * to the receiver. The stores will be added with the Normal priority.
 * \return A new combined store
 */
- (id)initWithStores:(GITObjectStore*)firstStore, ...;

/*! Adds a store to the receiver with the Normal priority.
 * \param store The GITObjectStore instance to add to the receiver
 */
- (void)addStore:(GITObjectStore*)store;

/*! Adds a list of stores to the receiver with normal priority.
 * \param firstStore A variable nil terminated list of stores to add to the receiver
 */
- (void)addStores:(GITObjectStore*)firstStore, ...;

/*! Adds a list of stores to the receiver with normal priority.
 * \param firstStore A variable nil terminated list of stores to add to the receiver
 * \param args Variable argument list of extra stores to add to the receiver
 */
- (void)addStores:(GITObjectStore*)firstStore args:(va_list)args;

/*! Adds a store to the receiver with <tt>priority</tt>.
 * \param store The GITObjectStore instance to add to the receiver
 * \param priority The priority indicates where the list of stores the <tt>store</tt>
 * should be placed. If you want the <tt>store</tt> to be checked first then you can
 * pass a higher priority.
 * \see GITCombinedStorePriority
 */
- (void)addStore:(GITObjectStore*)store priority:(GITCombinedStorePriority)priority;

@end
