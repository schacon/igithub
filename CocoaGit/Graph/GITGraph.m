//
//  GITGraph.m
//  CocoaGit
//
//  Created by chapbr on 4/23/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import "GITGraph.h"
#import "GITNode.h"
#import "GITCommit.h"
#import "GITRepo.h"

@implementation GITGraph

- (id) init;
{
    if ( !(self = [super init]) ) {
        [self release];
        return nil;
    }
    nodes = [NSMutableDictionary new];
    return self;
}

- (void) dealloc
{
    [nodes release], nodes = nil;
    [super dealloc];
}

- (GITNode *) nodeWithKey:(NSString *)aKey;
{
    return [nodes objectForKey:aKey];
}

- (NSUInteger) countOfNodes;
{
    return [nodes count];
}

- (NSArray *)nodes;
{
    return (NSArray *)[nodes allValues];
}

// BRC for debugging -- never call this method, it will eventually be removed
- (NSDictionary *)rawNodes;
{
    return [NSDictionary dictionaryWithDictionary:nodes];
}

- (BOOL) hasNode:(GITNode *)aNode;
{
    return ([nodes objectForKey:[aNode key]] != nil);
}

- (void) addNode:(GITNode *)newNode;
{
    [nodes setObject:newNode forKey:[newNode key]];
}

- (void) removeNode:(GITNode *)aNode;
{
    [nodes removeObjectForKey:[aNode key]];
}

- (void) addEdgeFromNode:(GITNode *)sourceNode toNode:(GITNode *)targetNode;
{
    [sourceNode addOutNode:targetNode];
    [targetNode addInNode:sourceNode];
}

- (void) removeEdgeFromNode:(GITNode *)sourceNode toNode:(GITNode *)targetNode;
{
    [sourceNode removeOutNode:targetNode];
    [targetNode removeInNode:sourceNode];
}

- (void) removeObjectsFromNodes
{
    [[nodes allValues] makeObjectsPerformSelector:@selector(removeObject)];
}

// dfs iteration
- (void) buildGraphWithStartingNode:(id)startNode
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSUInteger poolCount = 0;
    [self addNode:startNode];

    NSMutableArray *q = [[NSMutableArray alloc] initWithObjects:startNode,nil];
    GITRepo *repo = [(GITCommit *)[startNode object] repo];
    while( [q count] > 0 ) {
        if ( poolCount++ == 1000 ) {
            poolCount = 0;
            [pool drain];
            pool = [NSAutoreleasePool new];
        }
        id node = [[q lastObject] retain];
        [q removeLastObject];
        [node visit];
        
        NSArray *parentShas = [[node object] parentShas];
        for (NSString *key in parentShas) {
            GITNode *parentNode = [nodes objectForKey:key];
            if ( !parentNode ) {
                id commit = [repo commitWithSha1:key];
                parentNode = [GITNode nodeWithObject:commit];
                [nodes setObject:parentNode forKey:key];
            }
            parentNode->indegree++;
            [self addEdgeFromNode:node toNode:parentNode];
            if ( ![parentNode wasVisited] )
            {
                [parentNode visit];
                // Do not build child-relationship for now
                // [self addEdgeFromNode:parentNode toNode:node];
                [q addObject:parentNode];
            }
        }
        [node release];
    }
    [q release];
    [pool drain];
}

- (void) buildGraphWithStartingCommit:(GITCommit *)commit;
{
    [self buildGraphWithStartingNode:[GITNode nodeWithObject:commit]];
}


static CFComparisonResult compareDateDescending(const void *a_, const void *b_, void *context)
{
    const GITNode *a = a_;
    const GITNode *b = b_;
    return (CFComparisonResult) (a->date < b->date) ? 1 : (a->date > b->date) ? -1 : 0;
}

static CFComparisonResult compareDateAscending(const void *a_, const void *b_, void *context)
{
    const GITNode *a = a_;
    const GITNode *b = b_;
    return (CFComparisonResult) (a->date < b->date) ? -1 : (a->date > b->date) ? 1 : 0;
}

// This is the default ordering for git-rev-list.
// Walk the commit tree (depth-first) and maintain a priority queue of 'parents' sorted by date.
// Note the this procedure allows parents to appear before _all_ of their children
// since we ignore  the'in degree' of a node, and only use the traversal ordering.
- (NSArray *) nodesSortedByDate
{
    NSMutableArray *roots = [NSMutableArray new];
    NSMutableArray *sorted = [[NSMutableArray alloc] initWithCapacity:[self countOfNodes]];
    
    GITNode *node;
    for ( node in [self nodes] ) {
        node->visited = NO;
        node->processed = NO;
        if ( node->indegree == 0 ) {
            [roots addObject:node];
        }
    }
        
    while ( [roots count] > 0) {
        GITNode *v = [[roots lastObject] retain];
        if ( !v->processed ) {
            [sorted addObject:v];
            v->processed = YES;
        }
        [roots removeLastObject];
        
        for (GITNode *w in [v outNodes]) {
            if ( ![w wasVisited] ) {
                [w visit];
                NSUInteger i = CFArrayBSearchValues((CFMutableArrayRef)roots,
                                                    CFRangeMake(0, [roots count]),
                                                    w, compareDateAscending, NULL);
                [roots insertObject:w atIndex:i];
            }
        }
        [v release];
    }
    [roots release];
    return (NSArray *)[sorted autorelease];
}

- (NSArray *) nodesSortedByTopology:(BOOL)useLifo
{
    NSMutableArray *roots = [NSMutableArray new];
    NSMutableArray *sorted = [[NSMutableArray alloc] initWithCapacity:[self countOfNodes]];
    
    GITNode *node;
    for ( node in [self nodes] ) {
        [node resetIndegree];
        if ( node->indegree == 0 ) {
            [roots addObject:node];
        }
    }

    if ( !useLifo )
        CFArraySortValues((CFMutableArrayRef)roots,
                          CFRangeMake(0, [roots count]),
                          compareDateAscending,
                          NULL);
    
    while ( [roots count] > 0) {
        GITNode *v = [roots lastObject];
        [sorted addObject:v];
        [roots removeLastObject];
        
        for (GITNode *w in [v outNodes]) {
            if ( --(w->indegree) == 0 ) {
                if ( useLifo ) {
                    [roots addObject:w];
                } else {
                    // --date-order sorting
                    NSUInteger i = CFArrayBSearchValues((CFMutableArrayRef)roots,
                                                        CFRangeMake(0, [roots count]),
                                                        w, compareDateAscending, NULL);
                    [roots insertObject:w atIndex:i];
                }
            }
        }
    }
    [roots release];
    return (NSArray *)[sorted autorelease];
}

@end
