//
//  GITDateTime.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 07/10/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITDateTime.h"
#import "NSTimeZone+Offset.h"

/*! \cond
 Make properties readwrite so we can use
 them within the class.
*/
@interface GITDateTime ()
@property(readwrite,copy) NSDate * date;
@property(readwrite,copy) NSTimeZone * timezone;
@end
/*! \endcond */

@implementation GITDateTime
@synthesize date;
@synthesize timezone;

- (id)initWithDate:(NSDate*)theDate timeZone:(NSTimeZone*)theTimeZone
{
    if (self = [super init])
    {
        self.date = theDate;
        self.timezone = theTimeZone;
    }
    return self;
}
- (id)initWithTimestamp:(NSTimeInterval)seconds timeZoneOffset:(NSString*)offset
{
    return [self initWithDate:[NSDate dateWithTimeIntervalSince1970:seconds]
                     timeZone:[NSTimeZone timeZoneWithStringOffset:offset]];
}
- (void)dealloc
{
    self.date = nil;
    self.timezone = nil;
    [super dealloc];
}
- (id)copyWithZone:(NSZone*)zone
{
    return [[GITDateTime allocWithZone:zone] initWithDate:self.date timeZone:self.timezone];
}
- (NSString*)description
{
    return [NSString stringWithFormat:@"%.0f %@",
            [self.date timeIntervalSince1970], [self.timezone offsetString]];
}
@end
