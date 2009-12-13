//
//  GITObject+Parsing.h
//  CocoaGit
//
//  Created by Brian Chapados on 4/29/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITObject.h"

struct objectRecord {
    char *startPattern;
    NSUInteger patternLen;
    NSInteger startLen;
    NSUInteger matchLen;
    char endChar;
};

@interface GITObject (Parsing)
BOOL parseObjectRecord(const char **buffer, struct objectRecord delim, const char **matchStart, NSUInteger *matchLength);
// 'create' prefix indicates that the caller owns the string
- (NSString *) createStringWithObjectRecord:(struct objectRecord)record bytes:(const char **)bytes;
- (NSString *) createStringWithObjectRecord:(struct objectRecord)record bytes:(const char **)bytes encoding:(NSStringEncoding)encoding;
@end
