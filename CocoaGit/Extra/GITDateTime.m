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

- (id) initWithBSDTime:(unsigned long)timeInSec timeZoneOffset:(NSInteger)tz
{   
    NSDate *aDate = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)timeInSec];
    NSInteger min = abs(tz);
    min = ((min/100)*60) + (min % 100);
    min = (tz < 0) ? -min : min;
    NSTimeZone *aTimeZone = [NSTimeZone timeZoneForSecondsFromGMT:(min*60)];
    return [self initWithDate:aDate timeZone:aTimeZone];
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
- (NSComparisonResult)compare:(GITDateTime*)anotherGITDateTime
{
    NSParameterAssert(anotherGITDateTime);
    
    NSCalendar *selfDateCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    [selfDateCalendar setTimeZone:timezone];
    NSCalendar *anotherDateCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    [anotherDateCalendar setTimeZone:anotherGITDateTime.timezone];
    
    NSCalendarUnit unitFlags = NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|kCFCalendarUnitHour|kCFCalendarUnitMinute|kCFCalendarUnitSecond;
    
    NSDateComponents *selfDateComponents = [selfDateCalendar components:unitFlags fromDate:date];
    NSDateComponents *anotherDateComponents = [anotherDateCalendar components:unitFlags fromDate:anotherGITDateTime.date];
    
    NSDate *selfDate = [selfDateCalendar dateFromComponents:selfDateComponents];
    NSDate *anotherDate = [anotherDateCalendar dateFromComponents:anotherDateComponents];
    
    return [selfDate compare:anotherDate];
}
@end
