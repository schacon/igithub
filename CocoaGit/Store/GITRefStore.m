//
//  GITRefStore.m
//  CocoaGit
//
//  Created by chapbr on 4/7/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import "GITRefStore.h"
#import "GITErrors.h"
#import "GITRef.h"
#import "GITRepo.h"
#import "GITUtilityBelt.h"

NSString * const GITRefsDirectoryName = @"refs";
NSString * const GITPackedRefsFileName = @"packed-refs";
NSString * const GITHeadRefName = @"HEAD";

@interface GITRefStore ()
- (NSString *) sha1ByRecursivelyResolvingSymbolicRef:(GITRef *)symRef;
- (void) resolveSymbolicRefs;
- (NSDictionary *) cachedRefs;
- (void) fetchRefs;
- (void) fetchLooseRefs;
- (void) fetchPackedRefs;
@end

// declare private GITRef method so we can use it to resolve symbolic refs
@interface GITRef ()
- (BOOL) resolveWithStore:(GITRefStore *)store error:(NSError **)error;
@end

@implementation GITRefStore
@synthesize rootDir;
@synthesize refsDir;
@synthesize packFile;
@synthesize headFile;

- (id) initWithRepo:(GITRepo *)repo error:(NSError **)error;
{
    return [self initWithRoot:[repo root] error:error];
}

- (id) initWithRoot:(NSString *)rootPath error:(NSError **)error;
{
    if ( ! [super init] )
        return nil;
    
    if ( [[rootPath lastPathComponent] isEqual:GITRefsDirectoryName] )
        rootPath = [rootPath stringByDeletingLastPathComponent];

    NSString *refsPath = [rootPath stringByAppendingPathComponent:GITRefsDirectoryName];    
    BOOL isDir;
    NSFileManager * fm = [NSFileManager defaultManager];
    if ( !([fm fileExistsAtPath:refsPath isDirectory:&isDir] && isDir) ) {
        NSString * errFmt = NSLocalizedString(@"Ref store not accessible %@ does not exist or is not a directory", @"GITErrorRefStoreNotAccessible (GITRefStore)");
        NSString * errDesc = [NSString stringWithFormat:errFmt, refsPath];
        GITError(error, GITErrorRefStoreNotAccessible, errDesc);
        [self release];
        return nil;
    }
    [self setRootDir:rootPath];
    [self setRefsDir:refsPath];
    
    NSString *packedRefsFile = [rootPath stringByAppendingPathComponent:GITPackedRefsFileName];
    if ( [fm fileExistsAtPath:packedRefsFile] ) {
        [self setPackFile:packedRefsFile];
    }
    
    NSString *headRefFile = [rootPath stringByAppendingPathComponent:GITHeadRefName];
    if ( [fm fileExistsAtPath:headRefFile] ) {
        [self setHeadFile:headRefFile];
    }
    
    cachedRefs = [NSMutableDictionary new];
    symbolicRefs = [NSMutableArray new];
    
    return self;
}

- (void) dealloc
{
    [refsDir release];
    [packFile release];
    [cachedRefs release];
    [symbolicRefs release];
    [super dealloc];
}

#pragma mark Public Methods
- (NSArray *) refsWithPrefix:(NSString *)refPrefix
{
    [self fetchRefs];
        
    if ( ![refPrefix hasPrefix:@"refs/"] )
        refPrefix = [NSString stringWithFormat:@"refs/%@", refPrefix];
    
    NSMutableArray *matchingRefs = [NSMutableArray arrayWithCapacity:[cachedRefs count]/2];
    for (NSString *key in cachedRefs) {
        if ( ![key hasPrefix:refPrefix] )
            continue;
        GITRef *ref = [[cachedRefs objectForKey:key] copy];
        [matchingRefs addObject:ref];
        [ref release];
    }
    return [NSArray arrayWithArray:matchingRefs];
}

- (NSArray *) allRefs
{
    return [[[NSArray alloc] initWithArray:
             [[self cachedRefs] allValues] copyItems:YES] autorelease];
}

- (NSArray *) branches
{
    return [self refsWithPrefix:@"refs/heads"];
}

- (NSArray *) heads
{
    return [[self refsWithPrefix:@"refs/heads"] arrayByAddingObject:[self head]];
}

- (NSArray *) tags
{
    return [self refsWithPrefix:@"refs/tags"];
}

- (NSArray *) remotes
{
    return [self refsWithPrefix:@"refs/remotes"];
}

- (GITRef *) head
{
    return [self refWithName:GITHeadRefName];
}

- (GITRef *) refWithName:(NSString *)refName
{
    return [[[[self cachedRefs] objectForKey:refName] copy] autorelease];
}

- (GITRef *) refByResolvingSymbolicRef:(GITRef *)symRef
{
    if ( ![symRef isLink] )
        return symRef;
    NSString *sha1 = [self sha1WithSymbolicRef:symRef];
    [symRef setSha1:sha1];
    return [[symRef copy] autorelease];
}

- (NSString *) sha1WithSymbolicRef:(GITRef *)symRef
{
    GITRef *targetRef = [[self cachedRefs] objectForKey:[symRef linkName]];
    return [[[targetRef sha1] copy] autorelease];
}

- (void) invalidateCachedRefs
{
    [cachedRefs release];
    cachedRefs = [NSMutableDictionary new];
    fetchedLoose = NO;
    fetchedPacked = NO;
    [symbolicRefs release];
    symbolicRefs = [NSMutableArray new];
}

#pragma mark Write/Update refs

// only write/update loose refs
- (BOOL) writeRef:(GITRef *)aRef error:(NSError **)error;
{
    NSParameterAssert(aRef != nil);
    
    NSString *contents;
    if ( [aRef isLink] ) {
        contents = [NSString stringWithFormat:@"ref: %@", [aRef linkName]];
        if ( ![aRef resolveWithStore:self error:error] )
            return NO;
    } else {
        contents = [aRef sha1];
    }
    
    NSString *targetPath = [[self rootDir] stringByAppendingPathComponent:[aRef name]];
    BOOL success = [contents writeToFile:targetPath atomically:YES encoding:NSUTF8StringEncoding error:error];
    if ( !success )
        return NO;
    
    [cachedRefs setObject:aRef forKey:[aRef name]];
    return YES;
}

#pragma mark Internal Ref Parsing and Caching

- (NSString *) sha1ByRecursivelyResolvingSymbolicRef:(GITRef *)symRef
{
    GITRef *targetRef = [cachedRefs objectForKey:[symRef linkName]];
    if ( [targetRef isLink] )
        return [self sha1ByRecursivelyResolvingSymbolicRef:targetRef];
    return [[[targetRef sha1] copy] autorelease];
}

- (void) resolveSymbolicRefs
{
    while ([symbolicRefs count] > 0) {
        GITRef *symRef = [[symbolicRefs lastObject] retain];
        [symbolicRefs removeLastObject];
        NSString *sha1 = [self sha1ByRecursivelyResolvingSymbolicRef:symRef];
        NSAssert(isSha1StringValid(sha1), @"linked ref has invalid sha1");
        [symRef setSha1:sha1];
        [symRef release];
    }
}

- (NSDictionary *) cachedRefs
{
    [self fetchRefs];
    return cachedRefs;
}

- (void) fetchRefs
{
    if ( fetchedLoose && ( fetchedPacked || !packFile ) )
        return;
    if ( !fetchedLoose )
        [self fetchLooseRefs];
    if ( !(packFile && fetchedPacked) )
        [self fetchPackedRefs];
    [self resolveSymbolicRefs];
}

- (void) fetchLooseRefs
{
    NSString *thisRef;
    NSFileManager *fm =  [NSFileManager defaultManager];
    NSEnumerator *e = [fm enumeratorAtPath:[self refsDir]];
    while ( (thisRef = [e nextObject]) ) {
        NSString *tempRef = [[self refsDir] stringByAppendingPathComponent:thisRef];
        BOOL isDir;
        if ( [fm fileExistsAtPath:tempRef isDirectory:&isDir] && !isDir ) {
            NSString *refName = [NSString stringWithFormat:@"refs/%@", thisRef];
            if ( ![cachedRefs objectForKey:refName] ) {
                id theRef = [GITRef refWithContentsOfFile:tempRef];
                [cachedRefs setObject:theRef forKey:refName];
                if ( [theRef isLink] )
                    [symbolicRefs addObject:theRef];
            }
        }
    }
    if ( ![cachedRefs objectForKey:GITHeadRefName] ) {
        id headRef = [GITRef refWithContentsOfFile:[self headFile] name:GITHeadRefName];
        [cachedRefs setObject:headRef forKey:GITHeadRefName];
        [symbolicRefs addObject:headRef];
    }
    fetchedLoose = YES;
}

- (void) fetchPackedRefs
{
    if ( ![self packFile] )
        return;
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:[self packFile]] )
        return;    
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSString *packedRefs = [[NSString alloc]
                            initWithContentsOfFile:[self packFile]
                                          encoding:NSASCIIStringEncoding 
                                             error:NULL];
    NSArray *packedRefLines = [packedRefs componentsSeparatedByCharactersInSet:
                               [NSCharacterSet newlineCharacterSet]];
    for (NSString *line in packedRefLines) {
        if ([line length] < 1 || [line hasPrefix:@"#"] || [line hasPrefix:@"^"])
            continue;
        // line with ref = @"<40-char sha1> <refName>"
        NSString *thisSha = [line substringWithRange:NSMakeRange(0,40)];
        NSString *thisRef = [line substringFromIndex:41];
        if ( ![cachedRefs objectForKey:thisRef] ) {
            id theRef = [GITRef refWithName:thisRef sha1:thisSha packed:YES];
            [cachedRefs setObject:theRef forKey:thisRef];
            if ( [theRef isLink] )
                [symbolicRefs addObject:theRef];
        }
    }
    [packedRefs release];
    [pool release];
    fetchedPacked = YES;
}
@end