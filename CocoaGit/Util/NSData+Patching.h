//
//  NSData+Patching.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 01/02/2009.
//  Copyright 2009 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (Patching)

- (void)patchDeltaHeader:(NSData*)deltaData size:(unsigned long*)size
                position:(unsigned long*)position;
- (NSData*)dataByPatchingWithDelta:(NSData*)delta;

@end
