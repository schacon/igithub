//
//  GITDateTime.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 07/10/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GITDateTime : NSObject <NSCopying> {
    NSDate * date;
    NSTimeZone * timezone;
}

@property(readonly,copy) NSDate * date;
@property(readonly,copy) NSTimeZone * timezone;

- (id)initWithDate:(NSDate*)theDate timeZone:(NSTimeZone*)theTimeZone;
- (id)initWithTimestamp:(NSTimeInterval)seconds timeZoneOffset:(NSString*)offset;

/*! Creates and returns dateTime object given the BSD time (time in seconds since 1970)
 *  and the timeZone offset from GMT in units of hours*100. The units of hours*100,
 *  though bizarre, result from converting a typical timeZone string "-0700" into an
 *  integer.
 * \param seconds BSD time (in seconds since 1970).
 * \param tz timeZone offset from GMT in units of hours*100.
 * \return An actor object with the extracted name and email.
 */
- (id) initWithBSDTime:(unsigned long)seconds timeZoneOffset:(NSInteger)tz;
- (NSComparisonResult)compare:(GITDateTime*)object;

@end
