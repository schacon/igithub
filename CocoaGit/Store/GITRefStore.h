//
//  GITRefStore.h
//  CocoaGit
//
//  Created by chapbr on 4/7/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GITRepo, GITRef;

@interface GITRefStore : NSObject {
    // properties
    NSString *rootDir;
    NSString *refsDir;
    NSString *packFile;
    NSString *headFile;
    
    // internal state
    NSMutableDictionary *cachedRefs;
    NSMutableArray *symbolicRefs;
    BOOL fetchedLoose;
    BOOL fetchedPacked;
}
@property (readwrite, copy) NSString *rootDir;
@property (readwrite, copy) NSString *refsDir;
@property (readwrite, copy) NSString *packFile;
@property (readwrite, copy) NSString *headFile;

- (id) initWithRepo:(GITRepo *)repo error:(NSError **)error;
- (id) initWithRoot:(NSString *)aPath error:(NSError **)error;

//- (id) initWithPath:(NSString *)aPath packFile:(NSString *)packedRefsFile error:(NSError **)error;

- (GITRef *) head;
- (GITRef *) refWithName:(NSString *)refName;
- (GITRef *) refByResolvingSymbolicRef:(GITRef *)symRef;
- (NSString *) sha1WithSymbolicRef:(GITRef *)symRef;

- (NSArray *) refsWithPrefix:(NSString *)refPrefix;
- (NSArray *) allRefs;
- (NSArray *) branches;
- (NSArray *) heads;
- (NSArray *) tags;
- (NSArray *) remotes;

- (BOOL) writeRef:(GITRef *)aRef error:(NSError **)error;
- (void) invalidateCachedRefs;
@end