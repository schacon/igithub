//
//  GITObject+Parsing.m
//  CocoaGit
//
//  Created by Brian R. Chapados on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GITObject+Parsing.h"


@implementation GITObject (Parsing)
BOOL parseObjectRecord(const char **buffer, struct objectRecord record, const char **matchStart, NSUInteger *matchLength)
{
    const char *buf = *buffer;
    if ( record.patternLen > 0 && memcmp(buf, record.startPattern, record.patternLen) ) {
        //NSLog(@"start pattern does not match: %s\nbuf:%s", record.startPattern, buf);
        return NO;
    }
    
    // set start position
    const char *start;
    if ( record.startLen > 0 ) {
        start = buf+record.startLen;
    } else {
        start = buf+record.patternLen;
    }
    
    // set end position, and reset startLen if its relative to the end (startLen < 0)
    const char *end = start;
    if ( (record.startLen >= 0) && (record.matchLen > 0) ) {
        end = start+record.matchLen;
    } else {
        while ( *end++ != record.endChar )
            ;
        // TODO: BRC- use size for bounds check
        if ( record.startLen < 0 ) {
            // move the start pointer
            NSUInteger len = end - start;
            start += len + record.startLen;
        }
        --end; // end should point to the delimiting char
    }
    
    // check that end = endChar, otherwise there was a parsing problem
    if ( end[0] != record.endChar ) {
        NSLog(@"end delimiter (%c) does not match end char:%c\n", record.endChar, end[0]);
        return NO;
    }    
    
    // set matchLen
    NSUInteger matchLen = record.matchLen;
    if ( record.matchLen == 0 )
        matchLen = end - start;
    
    if ( matchStart != NULL )
        *matchStart = start;
    if ( matchLength != NULL )
        *matchLength = matchLen;
    
    *buffer = end + 1; // skip over the delimiting char
    return YES;
}

// 'create' prefix indicates that the caller owns the string
- (NSString *) createStringWithObjectRecord:(struct objectRecord)record bytes:(const char **)bytes
{
    return [self createStringWithObjectRecord:record bytes:bytes encoding:NSASCIIStringEncoding];
}

// 'create' prefix indicates that the caller owns the string
- (NSString *) createStringWithObjectRecord:(struct objectRecord)record bytes:(const char **)bytes encoding:(NSStringEncoding)stringEncoding
{
    const char *start;
    NSUInteger len;
    if ( !parseObjectRecord(bytes, record, &start, &len) )
        return nil;
    return [[NSString alloc] initWithBytes:start
                                    length:len
                                  encoding:stringEncoding];
}
@end
