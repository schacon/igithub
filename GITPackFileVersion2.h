//
//  GITPackFileVersion2.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 04/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITPackFile.h"

@class GITPackIndex;
@interface GITPackFileVersion2 : GITPackFile
{
    NSString * path;
    NSData   * data;
    GITPackIndex * index;
    NSUInteger numberOfObjects;
}

// These may be removed at a later date.
@property(readonly,copy) NSString * path;
@property(readonly,retain) NSData * data;
@property(readonly,retain) GITPackIndex * index;

@end
