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

@end
