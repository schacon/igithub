//
//  NSTimeZone+Offset.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 28/07/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "NSTimeZone+Offset.h"

static const unsigned short int HourInSeconds = 3600;
static const unsigned short int MinuteInSeconds = 60;

@implementation NSTimeZone (Offset)

+ (id)timeZoneWithStringOffset:(NSString*)offset
{
    NSString * hours = [offset substringWithRange:NSMakeRange(1, 2)];
    NSString * mins  = [offset substringWithRange:NSMakeRange(3, 2)];
    
    NSTimeInterval seconds = ([hours integerValue] * HourInSeconds) + ([mins integerValue] * MinuteInSeconds);
    if ([offset characterAtIndex:0] == '-')
        seconds = seconds * -1;
    
    return [self timeZoneForSecondsFromGMT:seconds];
}
- (NSString*)offsetString
{
    BOOL negative = NO;
    unsigned short int hours, mins; //!< Shouldn't ever be > 60
    
    NSTimeInterval seconds = [self secondsFromGMT];
    if (seconds < 0) {
        negative = YES;
        seconds = seconds * -1;
    }
    
    hours = (NSInteger)seconds / HourInSeconds;
    mins  = ((NSInteger)seconds % HourInSeconds) / MinuteInSeconds;
    
    return [NSString stringWithFormat:@"%c%02d%02d",
            negative ? '-' : '+', hours, mins];
}

@end
