//
//  GITTreeEntry.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITTreeEntry.h"
#import "GITObject.h"
#import "GITTree.h"
#import "GITRepo.h"
#import "GITUtilityBelt.h"
#import "GITErrors.h"

const NSUInteger GITTreeEntryTypeMask   = 00170000;
const NSUInteger GITTreeEntryLinkMask   =  0120000;
const NSUInteger GITTreeEntryFileMask   =  0100000;
const NSUInteger GITTreeEntryDirMask    =  0040000;
const NSUInteger GITTreeEntryModMask    =  0160000;

/*! \cond
 Make properties readwrite so we can use
 them within the class.
*/
@interface GITTreeEntry ()
@property(readwrite,copy) NSString * name;
@property(readwrite,assign) NSUInteger mode;
@property(readwrite,copy) NSString * sha1;
@property(readwrite,copy) GITTree * parent;
@property(readwrite,copy) GITObject * object;
@end
/*! \endcond */

@implementation GITTreeEntry
@synthesize name;
@synthesize mode;
@synthesize sha1;
@synthesize parent;
@synthesize object;

#pragma mark -
#pragma mark Deprecated Initialisers
- (id)initWithTreeLine:(NSString*)line parent:(GITTree*)parentTree
{
    return [self initWithRawString:line parent:parentTree error:NULL];
}

- (id)initWithMode:(NSUInteger)theMode name:(NSString*)theName
              sha1:(NSString*)theHash parent:(GITTree*)parentTree
{
    return [self initWithFileMode:theMode
                             name:theName
                             sha1:theHash
                           parent:parentTree
                            error:NULL];
}

- (id)initWithModeString:(NSString*)str name:(NSString*)theName
                    sha1:(NSString*)hash parent:(GITTree*)parentTree
{
    NSUInteger theMode = [str integerValue];
    return [self initWithMode:theMode name:theName sha1:hash parent:parentTree];
}

#pragma mark -
#pragma mark Error Aware Initialisers
- (id)initWithRawString:(NSString*)raw parent:(GITTree*)parentTree error:(NSError**)error
{
    NSString * errorDescription;

    NSScanner * scanner = [NSScanner scannerWithString:raw];
    NSString  * entryMode, * entryName, * entrySha1;

    while ([scanner isAtEnd] == NO)
    {
        if ([scanner scanUpToString:@" " intoString:&entryMode] &&
            [scanner scanUpToString:@"\0" intoString:&entryName])
        {
            entrySha1 = [[scanner string] substringFromIndex:[scanner scanLocation] + 1];
            [scanner setScanLocation:[scanner scanLocation] + 1 + kGITPackedSha1Length];

            if (!entrySha1)
            {
                errorDescription = NSLocalizedString(@"Failed to parse object reference for tree entry", @"GITErrorObjectParsingFailed (GITTreeEntry:entrySha1)");
                GITError(error, GITErrorObjectParsingFailed, errorDescription);
                return nil;
            }
        }
        else
        {
            errorDescription = NSLocalizedString(@"Failed to parse file mode or name for tree entry", @"GITErrorObjectParsingFailed (GITTreeEntry)");
            GITError(error, GITErrorObjectParsingFailed, errorDescription);
            return nil;
        }
    }

    return [self initWithFileMode:[entryMode integerValue] name:entryName
                             sha1:unpackSHA1FromString(entrySha1) parent:parentTree error:error];
}

- (id)initWithFileMode:(NSUInteger)theMode name:(NSString*)theName
                  sha1:(NSString*)theSha1 parent:(GITTree*)parentTree error:(NSError**)error
{
    if (self = [super init])
    {
        self.mode = theMode;
        self.name = theName;
        self.sha1 = theSha1;
        self.parent = parentTree;
    }
    return self;
}

- (void)dealloc
{
    self.name = nil;
    self.mode = 0;
    self.sha1 = nil;
    self.parent = nil;
    [object release], object = nil;
    [super dealloc];
}

- (GITObject *) object    //!< Lazily loads the target object
{
    // How should we make this error aware as its doing object loading?
    if (!object && self.sha1)
        self.object = [self.parent.repo objectWithSha1:self.sha1];
    return object;
}

- (NSData *) raw
{
    NSString * meta = [NSString stringWithFormat:@"%lu %@\0",
                       (unsigned long)self.mode, self.name];
    NSMutableData * data = [NSMutableData dataWithData:[meta dataUsingEncoding:NSASCIIStringEncoding]];
    [data appendData:packSHA1(self.sha1)];
    return data;
}
@end
