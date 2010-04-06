//
//  GITRepo+Enumerators.m
//  CocoaGit
//
//  Created by chapbr on 4/30/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import "GITRepo+Enumerators.h"
#import "GITCommitEnumerator.h"

@implementation GITRepo (Enumerators)
- (NSEnumerator *)commitEnumeratorBFS
{
    return [GITCommitEnumerator enumeratorWithRepo:self mode:GITEnumeratorBFS];
}

- (NSEnumerator *)commitEnumeratorDFS
{
    return [GITCommitEnumerator enumeratorWithRepo:self mode:GITEnumeratorDFS];
}
@end
