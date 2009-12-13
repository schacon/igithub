//
//  GITPackIndexVersion2.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 04/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITPackIndex.h"
#import "GITPackReverseIndex.h"

#define EXTENDED_OFFSET_FLAG (1 << 31)

@class GITPackReverseIndex;

@interface GITPackIndexVersion2 : GITPackIndex
{
    NSString *path;
    NSData   *data;
    NSArray  *offsets;
    GITPackReverseIndex *revIndex;
}

@property(readwrite,copy) NSString * path;
@property(readwrite,retain) NSData * data;

@end
