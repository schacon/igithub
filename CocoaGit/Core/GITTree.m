//
//  GITTree.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITTree.h"
#import "GITRepo.h"
#import "GITTreeEntry.h"
#import "GITErrors.h"

NSString * const kGITObjectTreeName = @"tree";

/*! \cond
 Make properties readwrite so we can use
 them within the class.
*/
@interface GITTree ()
@property(readwrite,copy) NSArray * entries;
@end
/*! \endcond */

@implementation GITTree
@synthesize entries;

+ (NSString*)typeName
{
    return kGITObjectTreeName;
}
- (GITObjectType)objectType
{
    return GITObjectTypeTree;
}

#pragma mark -
#pragma mark Mem overrides
- (void)dealloc
{
    self.entries = nil;
    [super dealloc];
}
- (id)copyWithZone:(NSZone*)zone
{
    GITTree * tree  = (GITTree*)[super copyWithZone:zone];
    tree.entries    = self.entries;
    
    return tree;
}

#pragma mark -
#pragma mark Data Parser
- (BOOL)parseRawData:(NSData*)raw error:(NSError**)error
{
    // TODO: Update this method to support errors
    NSError * undError;
    NSString * errorDescription;

    NSString  * dataStr = [[NSString alloc] initWithData:raw
                                                encoding:NSASCIIStringEncoding];

    NSMutableArray *treeEntries = [NSMutableArray arrayWithCapacity:2];
    unsigned entryStart = 0;

    do {
        NSRange searchRange = NSMakeRange(entryStart, [dataStr length] - entryStart);
        NSUInteger entrySha1Start = [dataStr rangeOfString:@"\0" 
                                                   options:0
                                                     range:searchRange].location;

        NSRange entryRange = NSMakeRange(entryStart, 
            entrySha1Start - entryStart + kGITPackedSha1Length + 1);

        NSString * treeLine = [dataStr substringWithRange:entryRange];
        GITTreeEntry * entry = [[GITTreeEntry alloc] initWithRawString:treeLine parent:self error:&undError];

        if (!entry)
        {
            errorDescription = NSLocalizedString(@"Failed to parse entry for tree", @"GITErrorObjectParsingFailed (GITTree)");
            GITErrorWithInfo(error, GITErrorObjectParsingFailed, NSLocalizedDescriptionKey, errorDescription, NSUnderlyingErrorKey, undError, nil);
            return NO;
        }

        [treeEntries addObject:entry];
        [entry release];
        entryStart = entryRange.location + entryRange.length;
    } while(entryStart < [dataStr length]);
    
    self.entries = treeEntries;
    [dataStr release];
    
    return YES;
}

#pragma mark -
#pragma mark Output Methods
- (NSData*)rawContent
{
    NSMutableData * content = [NSMutableData dataWithCapacity:self.size];
    for (GITTreeEntry * entry in self.entries)
    {
        [content appendData:[entry raw]];
    }
    return [content copy];
}

@end
