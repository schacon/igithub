//
//  GITPackReverseIndex.h
//  CocoaGit
//
//  Created by Brian Chapados on 2/16/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GITPackIndex;
@interface GITPackReverseIndex : NSObject {
    GITPackIndex *index;
    CFMutableArrayRef offsets;
    NSUInteger size;
}
@property (nonatomic, readonly, assign) GITPackIndex *index;

- (id) initWithPackIndex:(GITPackIndex *)packIndex;
- (NSUInteger) indexWithOffset:(off_t)offset;
- (off_t) nextOffsetWithOffset:(off_t)thisOffset;
- (off_t) baseOffsetWithOffset:(off_t)theOffset;
@end
