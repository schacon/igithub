//
//  GITCombinedStore.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 24/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITCombinedStore.h"

/*! \cond */
@interface GITCombinedStore ()
@property(readwrite,retain) NSMutableArray * stores;
@property(readwrite,assign) GITObjectStore * recentStore;
@end
/*! \endcond */

@implementation GITCombinedStore
@synthesize stores;
@synthesize recentStore;

- (void) dealloc
{
    [stores release], stores = nil;
    recentStore = nil;
    [super dealloc];
}

- (id)init
{
    return [self initWithStores:nil];
}
- (id)initWithRoot:(NSString*)root
{
    return [self initWithStores:nil];
}
- (id)initWithRoot:(NSString*)root error:(NSError**)error
{
    return [self initWithStores:nil];
}
- (id)initWithStores:(GITObjectStore*)firstStore, ...
{
    if (self = [super init])
    {
        self.stores = [NSMutableArray array];
        self.recentStore = nil;

        va_list args;
        va_start(args, firstStore);
        [self addStores:firstStore args:args];
        va_end(args);
    }

    return self;
}

- (void)addStore:(GITObjectStore*)store
{
    [self addStore:store priority:GITNormalPriority];
}
- (void)addStores:(GITObjectStore*)firstStore, ...
{
    va_list args;
    va_start(args, firstStore);
    [self addStores:firstStore args:args];
    va_end(args);
}
- (void)addStores:(GITObjectStore*)firstStore args:(va_list)args
{
    GITObjectStore * eachStore = firstStore;
    while (eachStore) {
        [self addStore:eachStore priority:GITNormalPriority];
        eachStore = va_arg(args, GITObjectStore*);
    }
}
- (void)addStore:(GITObjectStore*)store priority:(GITCombinedStorePriority)priority
{
    // High goes at the front, Normal and Low append to the end.
    switch (priority)
    {
        case GITHighPriority:
            [self.stores insertObject:store atIndex:0];
            break;
        case GITNormalPriority:
        case GITLowPriority:
            [self.stores addObject:store];
            break;
    }
}
- (NSData*)dataWithContentsOfObject:(NSString*)sha1
{
    NSData * objectData = nil;
    if (self.recentStore)
        objectData = [self.recentStore dataWithContentsOfObject:sha1];
    if (objectData) return objectData;

    for (GITObjectStore * store in self.stores)
    {
        objectData = [store dataWithContentsOfObject:sha1];
        if (objectData)
        {
            self.recentStore = store;
            return objectData;
        }
    }

    return nil;
}
- (BOOL)loadObjectWithSha1:(NSString*)sha1 intoData:(NSData**)data
                      type:(GITObjectType*)type error:(NSError**)error
{
    NSError * undError = nil;
	
    if (recentStore != nil) {
        if ([self.recentStore loadObjectWithSha1:sha1 intoData:data type:type error:&undError])
            return YES;

        if ([undError code] != GITErrorObjectNotFound) {
            GITError(error, [undError code], [undError localizedDescription]);
			return NO;
		}
    }
    
    for (GITObjectStore * store in self.stores) {
        if (store == self.recentStore)
			continue;
		
		if ([store loadObjectWithSha1:sha1 intoData:data type:type error:&undError]) {
			self.recentStore = store;
			return YES;
		}
        
		if ([undError code] != GITErrorObjectNotFound) {
            GITError(error, [undError code], [undError localizedDescription]);
			return NO;
		}
    }

    // If we've made it this far then the object can't be found
	NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Object %@ not found", @"GITErrorObjectNotFound"), sha1];
	GITError(error, GITErrorObjectNotFound, errorDescription);
    return NO;
}
- (BOOL)writeObject:(NSData*)data type:(GITObjectType)type error:(NSError**)error
{
    // NOTE: For now we'll just pass it on to the first store object.
    return [[self.stores objectAtIndex:0] writeObject:data type:type error:error];
}

@end
