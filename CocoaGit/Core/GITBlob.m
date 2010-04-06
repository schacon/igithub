//
//  GITBlob.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITBlob.h"
#import "GITRepo.h"
#import "GITErrors.h"

#import "NSData+Searching.h"

NSString * const kGITObjectBlobName = @"blob";

/*! \cond
 Make properties readwrite so we can use
 them within the class.
*/
@interface GITBlob ()
@property(readwrite,copy) NSData * data;
@end
/*! \endcond */

@implementation GITBlob
@synthesize data;

+ (NSString*)typeName
{
    return kGITObjectBlobName;
}
- (GITObjectType)objectType
{
    return GITObjectTypeBlob;
}

#pragma mark -
#pragma mark Deprecated Initialisers
- (id)initWithSha1:(NSString*)newSha1 data:(NSData*)raw repo:(GITRepo*)theRepo
{
    if (self = [super initType:kGITObjectBlobName sha1:newSha1
                          size:[raw length] repo:theRepo])
    {
        self.data = raw;
    }
    return self;
}

#pragma mark -
#pragma mark Mem overrides
- (void)dealloc
{
    self.data = nil;
    [super dealloc];
}
- (id)copyWithZone:(NSZone*)zone
{
    GITBlob * blob = (GITBlob*)[super copyWithZone:zone];
    blob.data = self.data;
    return blob;
}

#pragma mark -
#pragma mark Data Parser
- (BOOL)parseRawData:(NSData*)raw error:(NSError**)error
{
    self.data = raw;
    return YES;
}

#pragma mark -
#pragma mark Blob methods
- (BOOL)canBeRepresentedAsString
{
    // If we can't find a null byte then it can be represented as string
    if ([self.data rangeOfNullTerminatedBytesFrom:0].location == NSNotFound)
        return YES;
    return NO;
}
- (NSString*)stringValue
{
    return [[[NSString alloc] initWithData:self.data encoding:NSASCIIStringEncoding] autorelease];
}

#pragma mark -
#pragma mark Output Methods
- (NSData*)rawContent
{
    return self.data;
}
@end