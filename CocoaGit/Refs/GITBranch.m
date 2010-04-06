//
//  GITBranch.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITBranch.h"
#import "GITRepo.h"
#import "GITCommit.h"

/*! \cond
 Make properties readwrite so we can use
 them within the class.
*/
@interface GITBranch ()
@property(readwrite,retain) GITRepo * repo;
@property(readwrite,copy) NSString * name;
@end
/*! \endcond */

@implementation GITBranch
@synthesize repo;
@synthesize name;

- (void) dealloc
{
    [repo release], repo = nil;
    [name release], name = nil;
    [super dealloc];
}

- (GITCommit*) head
{
    for (NSDictionary *ref in [self.repo refs]) {
        if ([[ref objectForKey:@"name"] hasSuffix:self.name]) {
            return [self.repo commitWithSha1:[ref objectForKey:@"sha"]];
        }
    }
    return nil;
}

@end
