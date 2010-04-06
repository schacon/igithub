//
//  GITBranch.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GITRepo, GITCommit;
@interface GITBranch : NSObject
{
    GITRepo  * repo;
    NSString * name;
}

@property(readonly,copy) NSString * name;

- (GITCommit*)head;

@end
