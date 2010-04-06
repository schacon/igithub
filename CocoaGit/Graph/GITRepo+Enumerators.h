//
//  GITRepo+Enumerators.h
//  CocoaGit
//
//  Created by chapbr on 4/30/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITRepo.h"

@class GITCommitEnumerator;
@interface GITRepo (Enumerators)
- (NSEnumerator *)commitEnumeratorBFS;
- (NSEnumerator *)commitEnumeratorDFS;
@end
