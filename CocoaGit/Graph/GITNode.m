//
//  GITNode.m
//  CocoaGit
//
//  Created by chapbr on 4/23/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import "GITNode.h"
#import "GITCommit.h"

@implementation GITNode
@synthesize key, object;
@synthesize indegree, date;

static Boolean GITNodeEqual(const void *a, const void *b)
{
    const GITNode *u = a;
    const GITNode *v = b;
    return (Boolean)([u isEqual:v]);
}

static CFArrayCallBacks kGITNodeArrayCallbacks = {0, NULL, NULL, NULL, GITNodeEqual};

+ (id) nodeWithObject:(id)anObject;
{
    return [[[self alloc] initWithObject:anObject] autorelease];
}

- (id) initWithObject:(id)anObject;
{
    if ( !(self = [super init]) ) {
        [self release];
        return nil;
    }
    if ( !anObject ) {
        // isEqual and hash depend on object, so it can't be nil
        [self release];
        return nil;
    }
    [self setKey:[(GITObject *)anObject sha1]];
    [self setObject:anObject];
    date = [anObject sortDate];
    inNodes = CFArrayCreateMutable(NULL, 0, &kGITNodeArrayCallbacks);
    outNodes = CFArrayCreateMutable(NULL, 0, &kGITNodeArrayCallbacks);

    return self;
}

- (void) dealloc
{
    CFRelease(inNodes);
    CFRelease(outNodes);
    [key release], key = nil;
    if (object)
        [object release], object = nil;
    [super dealloc];
}

- (BOOL) isEqual:(id)other
{
    if ( self == other )
        return YES;
    return [[self key] isEqual:[other key]];
}

- (NSUInteger) hash
{
    return [key hash];
}

- (BOOL) wasVisited { return visited; }

- (void) visit { visited = YES; }

- (void) unvisit { visited = NO; }

- (void) resetIndegree
{
    indegree = CFArrayGetCount(inNodes);
}

- (void) incrementIndegree { indegree++; }

- (void) decrementIndegree { indegree--; }

- (NSArray *) inNodes
{
    return [NSArray arrayWithArray:(NSMutableArray *)inNodes];
}

- (void) addInNode:(id)inNode;
{
    CFArrayAppendValue(inNodes, inNode);
}

- (void) removeInNode:(id)inNode;
{
    NSUInteger i = CFArrayGetFirstIndexOfValue(inNodes,
                                               CFRangeMake(0, CFArrayGetCount(inNodes)),
                                               inNode);
    CFArrayRemoveValueAtIndex(inNodes, i);
}

- (NSArray *) outNodes
{
    return [NSArray arrayWithArray:(NSMutableArray *)outNodes];
}

- (void) addOutNode:(id)outNode;
{
    CFArrayAppendValue(outNodes, outNode);
}

- (void) removeOutNode:(id)outNode;
{
    NSUInteger i = CFArrayGetFirstIndexOfValue(outNodes,
                                               CFRangeMake(0, CFArrayGetCount(outNodes)),
                                               outNode);
    CFArrayRemoveValueAtIndex(outNodes, i);
}

- (void) removeObject
{
    [object release], object = nil;
}

@end
