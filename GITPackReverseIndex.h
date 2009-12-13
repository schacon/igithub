//
//  GITPackReverseIndex.h
//  CocoaGit
//
//  Created by Brian Chapados on 2/16/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITPackIndex.h"

@interface GITPackReverseIndex : NSObject {
    GITPackIndex *index;
    NSArray *offsets;
    NSArray *offsets64;
    NSArray *indexMap;
    NSArray *indexMap64;
}
@property (nonatomic, assign) GITPackIndex *index;
@property (nonatomic, copy) NSArray *offsets;
@property (nonatomic, copy) NSArray *indexMap;
@property (nonatomic, copy) NSArray *offsets64;
@property (nonatomic, copy) NSArray *indexMap64;

- (id) initWithPackIndex:(GITPackIndex *)packIndex;
- (NSUInteger) indexWithOffset:(off_t)offset;
- (off_t) nextOffsetWithOffset:(off_t)thisOffset;
@end
