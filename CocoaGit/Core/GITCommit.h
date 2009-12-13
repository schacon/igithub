//
//  GITCommit.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITObject.h"

extern NSString * const kGITObjectCommitName;

@class GITTree, GITActor, GITDateTime;
@interface GITCommit : GITObject
{
    NSString * treeSha1;
    NSArray * parents;
	NSArray	 * parentShas;

    GITTree  * tree;

    GITActor  * author;
    GITActor  * committer;

    GITDateTime * authored;
    GITDateTime * committed;
    unsigned long sortDate;
    
    NSString * message;
    NSData *cachedRawData;
}

@property(readonly,copy) NSString * treeSha1;
@property(readonly,copy) NSString * parentSha1;
@property(readwrite,retain) NSArray  * parentShas;
@property(readonly,copy) GITTree * tree;
@property(readonly,copy) GITCommit * parent;
@property(readonly,copy) NSArray *parents;
@property(readonly,copy) GITActor * author;
@property(readonly,copy) GITActor * committer;
@property(readonly,copy) GITDateTime * authored;
@property(readonly,copy) GITDateTime * committed;
@property(readonly) unsigned long sortDate;
@property(readonly,copy) NSString * message;

- (BOOL)isFirstCommit;

@end
