//
//  GITCommit.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITCommit.h"
#import "GITRepo.h"
#import "GITTree.h"
#import "GITActor.h"
#import "GITDateTime.h"

NSString * const kGITObjectCommitName = @"commit";

/*! \cond
 Make properties readwrite so we can use
 them within the class.
*/
@interface GITCommit ()
@property(readwrite,copy) NSString * treeSha1;
@property(readwrite,copy) GITTree * tree;
@property(readwrite,copy) NSSet * parents;
@property(readwrite,copy) GITActor * author;
@property(readwrite,copy) GITActor * committer;
@property(readwrite,copy) GITDateTime * authored;
@property(readwrite,copy) GITDateTime * committed;
@property(readwrite,copy) NSString * message;

- (void)extractFieldsFromData:(NSData*)data;

@end
/*! \endcond */

@implementation GITCommit
@synthesize treeSha1;
@synthesize parentShas;
@synthesize tree;
@synthesize parents;
@synthesize author;
@synthesize committer;
@synthesize authored;
@synthesize committed;
@synthesize message;

+ (NSString*)typeName
{
    return kGITObjectCommitName;
}
- (GITObjectType)objectType
{
    return GITObjectTypeCommit;
}

#pragma mark -
#pragma mark Deprecated Initialisers
- (id)initWithSha1:(NSString*)newSha1 data:(NSData*)raw repo:(GITRepo*)theRepo
{
	self.cachedRawData = raw;
    if (self = [super initType:kGITObjectCommitName sha1:newSha1
                          size:[raw length] repo:theRepo])
    {
        [self extractFieldsFromData:raw];
    }
    return self;
}

#pragma mark -
#pragma mark Mem overrides
- (void)dealloc
{
    self.tree = nil;
    self.parents = nil;
    self.author = nil;
    self.committer = nil;
    self.authored = nil;
    self.committed = nil;
    
    [super dealloc];
}
- (id)copyWithZone:(NSZone*)zone
{
    GITCommit * commit  = (GITCommit*)[super copyWithZone:zone];
    commit.tree         = self.tree;
    commit.parents      = self.parents;
    commit.author       = self.author;
    commit.committer    = self.committer;
    commit.authored     = self.authored;
    commit.committed    = self.committed;
    
    return commit;
}

- (BOOL)isFirstCommit
{
    return ([self.parents count] > 0);
}

#pragma mark -
#pragma mark Object Loaders
- (GITTree*)tree
{
    if (!tree && self.treeSha1)
        self.tree = [self.repo treeWithSha1:self.treeSha1 error:NULL];  //!< Ideally we'd like to care about the error
    return tree;
}

- (NSString *)parentSha1
{
    return self.parent.sha1;
}

- (GITCommit*)parent
{
    return [self.parents anyObject];
}

- (NSSet *)parents
{
    if (!parents && self.parentShas) {
        NSMutableSet *newParents = [[NSMutableSet alloc] initWithCapacity:[self.parentShas count]];
        for (NSString *parentSha1 in self.parentShas) {
            GITCommit *parent = [self.repo commitWithSha1:parentSha1 error:NULL];
            [newParents addObject:parent];
        }
        self.parents = newParents;
        [newParents release];
    }
    return parents;
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
    
    static NSString * NewLine = @"\n";
    NSString * commitTree,
             * commitParent,
             * authorName,
             * authorEmail,
             * authorTimezone,
             * committerName,
             * committerEmail,
             * committerTimezone;

	NSMutableArray *newParentShas = [[NSMutableArray alloc] init];

    NSTimeInterval authorTimestamp,
                   committerTimestamp;
     
    if ([scanner scanString:@"tree" intoString:NULL] &&
        [scanner scanUpToString:NewLine intoString:&commitTree])
    {
        self.treeSha1 = commitTree;
        if (!self.treeSha1) return NO;
    }
    else
    {
        errorDescription = NSLocalizedString(@"Failed to parse tree reference for commit", @"GITErrorObjectParsingFailed (GITCommit:tree)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }
    
    while ([scanner scanString:@"parent" intoString:NULL])
    {
        // If we've got a parent at all then we'll parse the name
        if ([scanner scanUpToString:NewLine intoString:&commitParent])
        {
			[newParentShas addObject:commitParent];
        }
        else
        {
            errorDescription = NSLocalizedString(@"Failed to parse parent reference for commit", @"GITErrorObjectParsingFailed (GITCommit:parent)");
            GITError(error, GITErrorObjectParsingFailed, errorDescription);
            return NO;
        }
    }
	
	[self setParentShas:newParentShas];
    
    if ([scanner scanString:@"author" intoString:NULL] &&
        [scanner scanUpToString:@"<" intoString:&authorName] &&
        [scanner scanString:@"<" intoString:NULL] &&
        [scanner scanUpToString:@">" intoString:&authorEmail] &&
        [scanner scanString:@">" intoString:NULL] &&
        [scanner scanDouble:&authorTimestamp] &&
        [scanner scanUpToString:NewLine intoString:&authorTimezone])
    {
        self.author = [[GITActor alloc] initWithName:authorName andEmail:authorEmail];
        self.authored = [[GITDateTime alloc] initWithTimestamp:authorTimestamp
                                                timeZoneOffset:authorTimezone];
    }
    else
    {
        errorDescription = NSLocalizedString(@"Failed to parse author details for commit", @"GITErrorObjectParsingFailed (GITCommit:author)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }
    
    if ([scanner scanString:@"committer" intoString:NULL] &&
        [scanner scanUpToString:@"<" intoString:&committerName] &&
        [scanner scanString:@"<" intoString:NULL] &&
        [scanner scanUpToString:@">" intoString:&committerEmail] &&
        [scanner scanString:@">" intoString:NULL] &&
        [scanner scanDouble:&committerTimestamp] &&
        [scanner scanUpToString:NewLine intoString:&committerTimezone])
    {
        self.committer = [[GITActor alloc] initWithName:committerName andEmail:committerEmail];
        self.committed = [[GITDateTime alloc] initWithTimestamp:committerTimestamp
                                                 timeZoneOffset:committerTimezone];
    }
    else
    {
        errorDescription = NSLocalizedString(@"Failed to parse committer details for commit", @"GITErrorObjectParsingFailed (GITCommit:committer)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }
        
    self.message = [[[scanner string] substringFromIndex:[scanner scanLocation]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!self.message)
    {
        errorDescription = NSLocalizedString(@"Failed to parse message for commit", @"GITErrorObjectParsingFailed (GITCommit:message)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }

    return YES;
}
- (void)extractFieldsFromData:(NSData*)data
{
    [self parseRawData:data error:NULL];
}
- (NSString*)description
{
    return [NSString stringWithFormat:@"Commit <%@>", self.sha1];
}

#pragma mark -
#pragma mark Output Methods
- (NSData*)rawContent
{
    return [[NSString stringWithFormat:@"tree %@\nparent %@\nauthor %@ %@\ncommitter %@ %@\n%@",
             self.tree.sha1, self.parent.sha1, self.author, self.authored,
             self.committer, self.committed, self.message] dataUsingEncoding:NSASCIIStringEncoding];
}

@end
