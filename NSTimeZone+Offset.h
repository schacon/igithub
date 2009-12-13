//
//  NSTimeZone+Offset.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 28/07/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSTimeZone.h>

@interface NSTimeZone (Offset)

/*! Creates and returns a time zone with the specified offset.
 * The string is broken down into the hour and minute components
 * which are then used to work out the number of seconds from GMT.
 * \param offset The timezone offset as a string such as "+0100"
 * \return A time zone with the specified offset
 * \see +timeZoneForSecondsFromGMT:
 */
+ (id)timeZoneWithStringOffset:(NSString*)offset;

/*! Returns the receivers offset as an HHMM formatted string.
 * \return The receivers offset as a string in HHMM format.
 */
- (NSString*)offsetString;
@end
