//
//  GITRef.h
//  CocoaGit
//
//  Created by Brian Chapados on 2/10/09.
//  Copyright 2009 Brian Chapados. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GITRef : NSObject {
    NSString *name;
    NSString *sha1;
    NSString *alias;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *sha1;
@property (nonatomic, copy) NSString *alias;

+ (id) refWithName:(NSString *)refName sha1:(NSString *)sha1String;
+ (id) refWithName:(NSString *)refName alias:(NSString *)refAlias;
+ (id) refWithContentsOfFile:(NSString *)aPath;
+ (id) refWithPacketLine:(NSString *)packetLine;

- (id) initWithName:(NSString *)refName sha1:(NSString *)sha1String alias:(NSString *)refAlias;


- (BOOL) isAlias;

@end
