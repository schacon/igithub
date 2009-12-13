//
//  GITPackFile.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITPackFile.h"

@implementation GITPackFile
#pragma mark -
#pragma mark Class Cluster Alloc Methods
+ (id)alloc
{
    if ([self isEqual:[GITPackFile class]])
        return [GITPlaceholderPackFile alloc];
    else return [super alloc];
}
+ (id)allocWithZone:(NSZone*)zone
{
    if ([self isEqual:[GITPackFile class]])
        return [GITPlaceholderPackFile allocWithZone:zone];
    else return [super allocWithZone:zone];
}
- (id)copyWithZone:(NSZone*)zone
{
    return self;
}

#pragma mark -
#pragma mark Primitive Methods
- (NSUInteger)version
{
    return 0;
}
- (GITPackIndex*)index
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

+ (id)packFileWithPath:(NSString *)thePath
{
    return [[[self alloc] initWithPath:thePath] autorelease];
}

- (id)initWithPath:(NSString*)thePath
{
    return [self initWithPath:thePath error:NULL];
}

+ (id)packFileWithPath:(NSString *)thePath error:(NSError **)error
{
    return [[[self alloc] initWithPath:thePath error:error] autorelease];
}

- (id)initWithPath:(NSString*)thePath error:(NSError **)error
{
	[self doesNotRecognizeSelector: _cmd];
    [self release];
    return nil;
}

- (id)initWithPath:(NSString*)path indexPath:(NSString *)idxPath error:(NSError **)error
{
    [self doesNotRecognizeSelector: _cmd];
    [self release];
    return nil;
}

- (id)initWithData:(NSData *)packData error:(NSError **)error
{
    [self doesNotRecognizeSelector: _cmd];
    [self release];
    return nil;
}

- (NSData*)dataForObjectWithSha1:(NSString*)sha1
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}
- (BOOL)loadObjectWithSha1:(NSString*)sha1 intoData:(NSData**)data
                      type:(GITObjectType*)type error:(NSError**)error
{
    [self doesNotRecognizeSelector: _cmd];
    return NO;
}

#pragma mark -
#pragma mark Checksum Methods
- (NSData*)checksum
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}
- (NSString*)checksumString
{
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}
- (BOOL)verifyChecksum
{
    [self doesNotRecognizeSelector: _cmd];
    return NO;
}

#pragma mark -
#pragma mark Derived Methods
- (NSUInteger)numberOfObjects
{
    return [[self index] numberOfObjects];
}
- (BOOL)hasObjectWithSha1:(NSString*)sha1
{
    return [[self index] hasObjectWithSha1:sha1];
}
@end
