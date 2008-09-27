//
//  ObjGitTest.m
//  ObjGit
//

#import <SenTestingKit/SenTestingKit.h>

@interface ObjGitTest : SenTestCase {	}
@end

@implementation ObjGitTest

- (void) testSomething {
	STAssertNotNil(@"hi", @"something cool");
}

@end
