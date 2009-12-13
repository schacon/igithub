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
#import "GITErrors.h"
#import "GITObject+Parsing.h"

NSString * const kGITObjectCommitName = @"commit";

static struct objectRecord recTree =  { "tree ", 5, 5, 40, '\n' };
static struct objectRecord recParent = { "parent ", 7, 7, 40, '\n' };
static struct objectRecord recRawDate = { "committer ", 10, -17, 10, '\n' };
static struct objectRecord recAuthor = { "author ", 7, 7, 0, '\n' };
static struct objectRecord recAuthorInfo = { "author ", 7, 7, 0, '>' };
static struct objectRecord recCommitterInfo = { "committer ", 10, 10, 0, '>' };
static struct objectRecord recDate = { " ", 1, 1, 10, ' ' };
static struct objectRecord recTz = { "", 0, 0, 5, '\n' };

/*! \cond
 Make properties readwrite so we can use
 them within the class.
*/
@interface GITCommit ()
@property(readwrite,copy) NSString * treeSha1;
@property(readwrite,copy) GITTree * tree;
@property(readwrite,copy) NSArray * parents;
@property(readwrite,copy) GITActor * author;
@property(readwrite,copy) GITActor * committer;
@property(readwrite,copy) GITDateTime * authored;
@property(readwrite,copy) GITDateTime * committed;
@property(readwrite,copy) NSString * message;
@property(readwrite,retain) NSData *cachedRawData;
- (void) parseCachedRawData;
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
@synthesize sortDate;
@synthesize message;
@synthesize cachedRawData;

+ (NSString*)typeName
{
    return kGITObjectCommitName;
}
- (GITObjectType)objectType
{
    return GITObjectTypeCommit;
}

#pragma mark -
#pragma mark Mem overrides
- (void)dealloc
{
    self.tree = nil;
    self.treeSha1 = nil;
    self.parents = nil;
    self.parentShas = nil;
    self.author = nil;
    self.committer = nil;
    self.authored = nil;
    self.committed = nil;
    self.cachedRawData = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
    GITCommit * commit  = (GITCommit*)[super copyWithZone:zone];
    commit.tree         = self.tree;
    commit.treeSha1     = self.treeSha1;
    commit.parents      = self.parents;
    commit.parentShas   = self.parentShas;
    commit.author       = self.author;
    commit.committer    = self.committer;
    commit.authored     = self.authored;
    commit.committed    = self.committed;
    commit.cachedRawData = self.cachedRawData;
    
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
    return [self.parents lastObject];
}

- (NSArray *)parents
{
    if (!parents && self.parentShas) {
        NSMutableArray *newParents = [[NSMutableArray alloc] initWithCapacity:[self.parentShas count]];
        for (NSString *parentSha1 in self.parentShas) {
            GITCommit *parent = [self.repo commitWithSha1:parentSha1 error:NULL];
            [newParents addObject:parent];
        }
        self.parents = newParents;
        [newParents release];
    }
    return parents;
}

#pragma mark Lazy Loaders

- (GITActor *) author
{
    if ( !author ) {
        [self parseCachedRawData];
    }
    return author;
}

- (GITDateTime *) authored
{
    if ( !authored ) {
        [self parseCachedRawData];
    }
    return authored;
}

- (GITActor *) committer
{
    if ( !committer ) {
        [self parseCachedRawData];
    }
    return committer;
}

- (GITDateTime *) committed
{
    if ( !committed ) {
        [self parseCachedRawData];
    }
    return committed;
}

- (NSString *) message
{
    if ( !message ) {
        [self parseCachedRawData];
    }
    return message;
}

#pragma mark -
#pragma mark Data Parser

- (BOOL)parseRawData:(NSData*)raw error:(NSError**)error
{
    const char *rawString = [raw bytes];
    const char *start = rawString;
    NSString *errorDescription;
    NSMutableArray *commitParents = [NSMutableArray new];
    
    NSString *treeString = [self createStringWithObjectRecord:recTree bytes:&rawString];
    if ( !treeString ) {
        errorDescription = NSLocalizedString(@"Failed to parse tree reference for commit", @"GITErrorObjectParsingFailed (GITCommit:tree)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }
    [self setTreeSha1:treeString];
    [treeString release];
    
    // parents
    NSString *parentString;
    while ( nil != (parentString = [self createStringWithObjectRecord:recParent bytes:&rawString]) ) {
        if ( !parentString ) {
            errorDescription = NSLocalizedString(@"Failed to parse parent reference for commit", @"GITErrorObjectParsingFailed (GITCommit:parent)");
            GITError(error, GITErrorObjectParsingFailed, errorDescription);
            [commitParents release];
            return NO;
        }
        [commitParents addObject:parentString];
        [parentString release];
    }
    
    [self setParentShas:commitParents];
    [commitParents release];
    
    // use this pointer to save the raw data for lazy parsing later
    const char *buf = rawString;
    NSUInteger bufLen = [raw length] - (buf-start);
    NSData *cachedData = [[NSData alloc] initWithBytes:buf length:bufLen];
    [self setCachedRawData:cachedData];
    [cachedData release];

    parseObjectRecord(&rawString, recAuthor, NULL, NULL);
    const char *rawDate;
    if ( !parseObjectRecord(&rawString, recRawDate, &rawDate, NULL) ) {
        errorDescription = NSLocalizedString(@"Failed to parse committer date", @"GITErrorObjectParsingFailed (GITCommit:committer)");
        GITError(error, GITErrorObjectParsingFailed, errorDescription);
        return NO;
    }
    sortDate = (unsigned long)strtoul(rawDate, NULL, recRawDate.matchLen);
    
    return YES;
}

- (GITDateTime *) dateWithBytes:(const char **)bytes
{
    const char *date;
    parseObjectRecord(bytes, recDate, &date, NULL);
    unsigned long timeInSec = (unsigned long)strtoul(date, NULL, recDate.matchLen);
    
    const char *tzData;
    parseObjectRecord(bytes, recTz, &tzData, NULL);
    NSInteger tz = (NSInteger)atoi(tzData);

    return [[GITDateTime alloc] initWithBSDTime:timeInSec timeZoneOffset:tz];
}

- (void) parseCachedRawData
{
    if ( cachedRawData == nil )
        return;
    const char *rawString = [cachedRawData bytes];
    const char *start = rawString;
    NSString *authorInfo = [self createStringWithObjectRecord:recAuthorInfo bytes:&rawString];
    GITActor *authorActor = [[GITActor alloc] initWithString:authorInfo];
    [authorInfo release];
    [self setAuthor:authorActor];
    [authorActor release];
    
    GITDateTime *authorDate = [self dateWithBytes:&rawString];
    [self setAuthored:authorDate];
    [authorDate release];
    
    NSString *committerInfo = [self createStringWithObjectRecord:recCommitterInfo bytes:&rawString];
    GITActor *committerActor = [[GITActor alloc] initWithString:committerInfo];
    [committerInfo release];
    [self setCommitter:committerActor];
    [committerActor release];
        
    GITDateTime *commitDate = [self dateWithBytes:&rawString];
    [self setCommitted:commitDate];
    [commitDate release];
    
    rawString++; // skip '\n'
    NSUInteger messageLength = [cachedRawData length] - (rawString - start) - 1;
    NSString *messageString = [[NSString alloc] initWithBytes:rawString
                                                       length:messageLength
                                                     encoding:NSASCIIStringEncoding];
    [self setMessage:messageString];
    [messageString release];
    [self setCachedRawData:nil];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"Commit <%@>", self.sha1];
}

#pragma mark -
#pragma mark Output Methods
- (NSData*)rawContent
{
    NSMutableString *treeString = [NSMutableString stringWithFormat:@"tree %@\n", self.tree.sha1];                                   
    for (GITCommit *parent in [self parents]) {
        [treeString appendFormat:@"parent %@\n", [parent sha1]];
    }
    NSString *contentString = [NSString stringWithFormat:@"%@author %@ %@\ncommitter %@ %@\n\n%@\n",
                               treeString, self.author, self.authored,
                               self.committer, self.committed, self.message];
    return [contentString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
