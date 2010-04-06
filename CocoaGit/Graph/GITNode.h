//
//  GITNode.h
//  CocoaGit
//
//  Created by chapbr on 4/23/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GITNode : NSObject
{
    id key;
    id object;

    // These arrays DO NOT retain members 
    CFMutableArrayRef inNodes;
    CFMutableArrayRef outNodes;
    
@public
    BOOL visited;
    BOOL processed;
    NSUInteger indegree;
    unsigned long date;
}
@property (readwrite, copy) id key;
@property (readwrite, retain) id object;
@property (readwrite, assign) NSUInteger indegree;
@property (readonly) unsigned long date;
+ (id) nodeWithObject:(id)anObject;
- (id) initWithObject:(id)anObject;
- (void) resetIndegree;
- (void) incrementIndegree;
- (void) decrementIndegree;

- (NSArray *) outNodes;
- (void) addOutNode:(id)outNode;
- (void) removeOutNode:(id)outNode;

- (NSArray *) inNodes;
- (void) addInNode:(id)inNode;
- (void) removeInNode:(id)inNode;

- (BOOL) wasVisited;
- (void) visit;
- (void) unvisit;
- (void) incrementIndegree;
- (void) decrementIndegree;

- (void) removeObject;
@end