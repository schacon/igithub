//
//  GITRef.h
//  CocoaGit
//
//  Created by Brian Chapados on 2/10/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITRepo.h"

@class GITRepo;
@class GITCommit;

@interface GITRef : NSObject {
    NSString *name;
    NSString *linkName;
    NSString *sha1;
    BOOL isLink;
    BOOL isPacked;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *sha1;
@property (nonatomic, copy) NSString *linkName;
@property (nonatomic, assign) BOOL isLink;
@property (nonatomic, assign) BOOL isPacked;

+ (id) refWithName:(NSString *)refName sha1:(NSString *)sha1String;
+ (id) refWithName:(NSString *)refName sha1:(NSString *)sha1String packed:(BOOL)refIsPacked;
+ (id) refWithContentsOfFile:(NSString *)aPath name:(NSString *)refName;
+ (id) refWithContentsOfFile:(NSString *)aPath;
+ (id) refWithPacketLine:(NSString *)packetLine;

- (id) initWithName:(NSString *)refName sha1:(NSString *)refSha1;
- (id) initWithName:(NSString *)refName sha1:(NSString *)refSha1 packed:(BOOL)refIsPacked;
- (id) initWithName:(NSString *)refName sha1:(NSString *)refSha1 
           linkName:(NSString *)refLink packed:(BOOL)refIsPacked;

- (NSString *) shortName;
- (GITCommit *) commitWithRepo:(GITRepo *)repo;
@end