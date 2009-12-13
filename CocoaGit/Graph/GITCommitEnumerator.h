//
//  GITCommitEnumerator.h
//  CocoaGit
//
//  Created by chapbr on 4/24/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    GITEnumeratorDFS = 0,
    GITEnumeratorBFS = 1,
} GITEnumeratorTraversalMode;

@class GITRepo, GITCommit;
@interface GITCommitEnumerator : NSEnumerator {
    GITRepo *repo;
    GITEnumeratorTraversalMode mode;

    NSMutableArray *nodeQueue;
    NSMutableSet *visitedNodes;
    BOOL started;
}
@property (nonatomic, readwrite, retain) GITRepo *repo;
+ (id) enumeratorWithRepo:(GITRepo *)gitRepo;
+ (id) enumeratorWithRepo:(GITRepo *)gitRepo mode:(GITEnumeratorTraversalMode)theMode;
- (void) setStartCommit:(GITCommit *)startCommit;
@end
