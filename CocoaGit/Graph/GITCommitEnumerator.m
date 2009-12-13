//
//  GITCommitEnumerator.m
//  CocoaGit
//
//  Created by chapbr on 4/24/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import "GITCommitEnumerator.h"
#import "GITCommit.h"
#import "GITRepo.h"

@interface GITCommitEnumerator()
- (id) initWithRepo:(GITRepo *)gitRepo mode:(GITEnumeratorTraversalMode)theMode;
@end

@implementation GITCommitEnumerator
@synthesize repo;

+ (id) enumeratorWithRepo:(GITRepo *)gitRepo
{
    return [[[self alloc] initWithRepo:gitRepo mode:GITEnumeratorDFS] autorelease];
}

+ (id) enumeratorWithRepo:(GITRepo *)gitRepo mode:(GITEnumeratorTraversalMode)theMode;
{
    return [[[self alloc] initWithRepo:gitRepo mode:theMode] autorelease];
}

- (id) init
{
    if ( !(self = [super init]) ) {
        [self release];
        return nil;
    }
    nodeQueue = [NSMutableArray new];
    visitedNodes = [NSMutableSet new];
    mode = GITEnumeratorDFS;
    started = NO;
    return self;
}

- (id) initWithRepo:(GITRepo *)gitRepo mode:(GITEnumeratorTraversalMode)theMode
{
    if ( ![self init] ) {
        return nil;
    }
    [self setRepo:gitRepo];
    [self setStartCommit:[gitRepo head]];
    mode = theMode;
    return self;
}

- (void) dealloc
{
    [repo release], repo = nil;
    [nodeQueue release], nodeQueue = nil;
    [visitedNodes release], visitedNodes = nil;
    [super dealloc];
}

- (void) setStartCommit:(GITCommit *)startCommit;
{
    NSAssert(!started, @"Cannot set start commit after enumeration has started");
    if ( !started )
        [nodeQueue addObject:startCommit];
}

// traverse through the graph of commits, in the order specified by 'mode'
// returning each commit object to the caller
- (id) nextObject
{
    if ( started ) {
        if ( nodeQueue == nil || [nodeQueue count] == 0 ) {
            [visitedNodes release], visitedNodes = nil;
            [nodeQueue release], nodeQueue = nil;
            return nil;
        }
    } else {
        if ( nodeQueue == nil || [nodeQueue count] == 0 ) {
            [self setStartCommit:[repo head]];
        }
        started = YES;
    }
    
    GITCommit *currentCommit;
    if ( mode == GITEnumeratorDFS ) {
        // DFS => LIFO queue
        currentCommit = (GITCommit *)[[nodeQueue lastObject] retain];
        [nodeQueue removeLastObject];
    } else {
        // BFS => FIFO queue
        currentCommit = (GITCommit *)[[nodeQueue objectAtIndex:0] retain];
        [nodeQueue removeObjectAtIndex:0];
    }

    id key = [currentCommit sha1];
    if ( ![visitedNodes containsObject:key] ) {
        [visitedNodes addObject:key];
    }

    for ( NSString *parentSha1 in [currentCommit parentShas] ) {
        if ( ![visitedNodes containsObject:parentSha1] ) {
            GITCommit *c = [[self repo] commitWithSha1:parentSha1];
            [visitedNodes addObject:parentSha1];
            [nodeQueue addObject:c];
        }
    }
    return [currentCommit autorelease];
}

- (NSArray *) allObjects
{
    NSMutableArray *all = [NSMutableArray array];
    id commit;
    while ( commit = [self nextObject] ) {
        [all addObject:commit];
    }
    return [NSArray arrayWithArray:all];
}

@end