//
//  NSFileManager+DirHelper.h
//  ObjectiveGit


#import <Foundation/Foundation.h>

@interface NSFileManager (DirHelpers)

+ (BOOL) directoryExistsAtPath:(NSString *) aPath;
+ (BOOL) directoryExistsAtURL:(NSURL *) aURL;
+ (BOOL) fileExistsAtPath:(NSString *) aPath;
+ (BOOL) fileExistsAtURL:(NSURL *) aURL;

@end