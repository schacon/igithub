//
//  NSFileManager+DirHelper.m
//  ObjectiveGit


#import "NSFileManager+DirHelper.h"

@implementation NSFileManager (DirHelpers)

+ (BOOL) directoryExistsAtPath:(NSString *) aPath;
{
	BOOL isDir;
	return [[self defaultManager] fileExistsAtPath:aPath isDirectory:&isDir] && isDir;
}

+ (BOOL) directoryExistsAtURL:(NSURL *) aURL;
{
	if (![aURL isFileURL])
		return NO;
	
	NSString *aPath = [aURL path];
	BOOL isDir;
	return [[self defaultManager] fileExistsAtPath:aPath isDirectory:&isDir] && isDir;
}

+ (BOOL) fileExistsAtPath:(NSString *) aPath;
{
	return [[self defaultManager] fileExistsAtPath:aPath];
}


+ (BOOL) fileExistsAtURL:(NSURL *) aURL;
{
	if (![aURL isFileURL])
		return NO;
	
	NSString *aPath = [aURL path];
	return [[self defaultManager] fileExistsAtPath:aPath];
}		
@end
