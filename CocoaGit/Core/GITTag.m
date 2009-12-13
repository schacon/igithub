//
//  GITTag.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITTag.h"
#import "GITRepo.h"
#import "GITActor.h"
#import "GITCommit.h"
#import "GITDateTime.h"
#import "GITErrors.h"

NSString * const kGITObjectTagName = @"tag";

/*! \cond
 Make properties readwrite so we can use
 them within the class.
*/
@interface GITTag ()
@property(readwrite,copy) NSString * name;
@property(readwrite,copy) NSString * objectSha1;
@property(readwrite,copy) GITCommit * commit;
@property(readwrite,copy) GITActor * tagger;
@property(readwrite,copy) GITDateTime * tagged;
@property(readwrite,copy) NSString * message;
@end
/*! \endcond */

@implementation GITTag
@synthesize name;
@synthesize objectSha1;
@synthesize commit;
@synthesize tagger;
@synthesize tagged;
@synthesize message;

+ (NSString*)typeName
{
    return kGITObjectTagName;
}
- (GITObjectType)objectType
{
    return GITObjectTypeTag;
}

#pragma mark -
#pragma mark Mem overrides
- (void)dealloc
{
    self.name = nil;
    self.objectSha1 = nil;
    self.commit = nil;
    self.tagger = nil;
    self.tagged = nil;
    self.message = nil;
    
    [super dealloc];
}
- (id)copyWithZone:(NSZone*)zone
{
    GITTag * tag    = (GITTag*)[super copyWithZone:zone];
    tag.name        = self.name;
    tag.objectSha1  = self.objectSha1;
    tag.commit      = self.commit;
    tag.tagger      = self.tagger;
    tag.tagged      = self.tagged;
    tag.message     = self.message;
    
    return tag;
}

#pragma mark -
#pragma mark Object Loaders
- (GITCommit*)commit
{
    if (!commit && self.objectSha1)
        self.commit = [self.repo commitWithSha1:objectSha1 error:NULL]; //!< Ideally we'd like to care about the error
    return commit;
}

#pragma mark -
#pragma mark Data Parser
- (BOOL)parseRawData:(NSData*)raw error:(NSError**)error
{
    // TODO: Update this method to support errors
    NSString * errorDescription;

    NSString  * dataStr = [[NSString alloc] initWithData:raw
                                                encoding:NSASCIIStringEncoding];
    NSScanner * scanner = [NSScanner scannerWithString:dataStr];
    [dataStr release];
    
    static NSString * NewLine = @"\n";
    NSString * taggedCommit,
             * taggedType,      //!< Should be @"commit"
             * tagName,
             * taggerName,
             * taggerEmail,
             * taggerTimezone;
     NSTimeInterval taggerTimestamp;
    
    if ([scanner scanString:@"object" intoString:NULL] &&
        [scanner scanUpToString:NewLine intoString:&taggedCommit] &&
        [scanner scanString:@"type" intoString:NULL] &&
        [scanner scanUpToString:NewLine intoString:&taggedType] &&
        [taggedType isEqualToString:@"commit"])
    {
        self.objectSha1 = taggedCommit;
        if (!self.objectSha1) return NO;
    }
    else
    {
        errorDescription = NSLocalizedString(@"Failed to parse object (commit) reference for tag", @"GITErrorObjectParsingFailed (GITTag:object)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }
    
    if ([scanner scanString:@"tag" intoString:NULL] &&
        [scanner scanUpToString:NewLine intoString:&tagName])
    {
        self.name = tagName;
    }
    else
    {

        errorDescription = NSLocalizedString(@"Failed to parse name for tag", @"GITErrorObjectParsingFailed (GITTag:tag)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }
    
    if ([scanner scanString:@"tagger" intoString:NULL] &&
        [scanner scanUpToString:@"<" intoString:&taggerName] &&
        [scanner scanString:@"<" intoString:NULL] &&
        [scanner scanUpToString:@">" intoString:&taggerEmail] &&
        [scanner scanString:@">" intoString:NULL] &&
        [scanner scanDouble:&taggerTimestamp] &&
        [scanner scanUpToString:NewLine intoString:&taggerTimezone])
    {
        self.tagger = [GITActor actorWithName:taggerName email:taggerEmail];
        self.tagged = [[[GITDateTime alloc] initWithTimestamp:taggerTimestamp
                                               timeZoneOffset:taggerTimezone] autorelease];
    }
    else
    {
        errorDescription = NSLocalizedString(@"Failed to parse tagger for tag", @"GITErrorObjectParsingFailed (GITTag:tagger)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }
        
    self.message = [dataStr substringFromIndex:[scanner scanLocation]];
    if (!self.message)
    {
        errorDescription = NSLocalizedString(@"Failed to parse message for tag", @"GITErrorObjectParsingFailed (GITTag:message)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }

    return YES;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"Tag: %@ <%@>",
                                        self.name, self.sha1];
}

#pragma mark -
#pragma mark Output Methods
- (NSData*)rawContent
{
    return [[NSString stringWithFormat:@"object %@\ntype %@\ntag %@\ntagger %@ %@\n%@",
             self.commit.sha1, self.commit.type, self.name, self.tagger, self.tagged,
             self.message] dataUsingEncoding:NSASCIIStringEncoding];
}

@end
