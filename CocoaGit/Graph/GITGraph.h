//
//  GITGraph.h
//  CocoaGit
//
//  Created by chapbr on 4/23/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GITNode;
@class GITCommit;
@interface GITGraph : NSObject {
    NSMutableDictionary *nodes;
}
- (NSUInteger) countOfNodes;
//- (NSUInteger) countOfEdges;

- (BOOL) hasNode:(GITNode *)aNode;
- (GITNode *) nodeWithKey:(NSString *)aKey;

- (void) addNode:(GITNode *)newNode;
- (void) removeNode:(GITNode *)aNode;
- (void) addEdgeFromNode:(GITNode *)sourceNode toNode:(GITNode *)targetNode;
//- (void) removeEdgeFromNode:(GITNode *)sourceNode toNode:(GITNode *)targetNode;

- (void) buildGraphWithStartingCommit:(GITCommit *)commit;
- (NSArray *) nodesSortedByDate;
- (NSArray *) nodesSortedByTopology:(BOOL)useLifo;

- (void) removeObjectsFromNodes;
//- (void) addCommit:(GITCommit *)gitCommit;
//- (void) removeCommit:(GITCommit *)gitCommit;
//- (void) addCommit:(GITCommit *)gitCommit includeTree:(BOOL)includeTree;
//- (void) removeCommit:(GITCommit *)gitCommit includeTree:(BOOL)includeTree;
@end