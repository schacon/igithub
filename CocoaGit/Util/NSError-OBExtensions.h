// Copyright 1997-2005, 2008 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the Omni Source License, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// **OPEN PERMISSION TO USE AND REPRODUCE OMNI SOURCE CODE SOFTWARE**
// 
// Omni Source Code software is available from The Omni Group on their
// web site at [www.omnigroup.com](http://www.omnigroup.com/).
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// Any original copyright notices and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease/2008-09-09/OmniGroup/Frameworks/OmniBase/NSError-OBExtensions.h 102857 2008-07-15 04:22:17Z bungi $

#import <Foundation/Foundation.h>
#import <Foundation/NSError.h>

#if defined(__cplusplus)
extern "C" {
#endif

#define GIT_BUNDLE_IDENTIFIER @"com.manicpanda.GIT"
	
extern NSString * const OBUserCancelledActionErrorKey;
extern NSString * const OBFileNameAndNumberErrorKey;

@interface NSError (OBExtensions)

- (BOOL)hasUnderlyingErrorDomain:(NSString *)domain code:(int)code;
- (BOOL)causedByUserCancelling;

- initWithPropertyList:(NSDictionary *)propertyList;
- (NSDictionary *)toPropertyList;
@end

extern void OBErrorv(NSError **error, NSString *domain, int code, const char *fileName, unsigned int line, NSString *firstKey, va_list args);
extern void _OBError(NSError **error, NSString *domain, int code, const char *fileName, unsigned int line, NSString *firstKey, ...);
extern void _OBErrorWithDescription(NSError **error, NSString *domain, int code, const char *fileName, unsigned int line, NSString *message, ...);
#ifdef OMNI_BUNDLE_IDENTIFIER
// It is expected that -DOMNI_BUNDLE_IDENTIFIER=@"com.foo.bar" will be set when building your code.  Build configurations make this easy since you can set it in the target's configuration and then have your Other C Flags have -DOMNI_BUNDLE_IDENTIFIER=@\"$(OMNI_BUNDLE_IDENTIFIER)\" and also use $(OMNI_BUNDLE_IDENTIFIER) in your Info.plist instead of duplicating it.
#define OBError(error, code, description) _OBError(error, OMNI_BUNDLE_IDENTIFIER, code, __FILE__, __LINE__, NSLocalizedDescriptionKey, description, nil)
#define OBErrorWithInfo(error, code, ...) _OBError(error, OMNI_BUNDLE_IDENTIFIER, code, __FILE__, __LINE__, ## __VA_ARGS__)
#endif

// Unlike the other routines in this file, but like all the other Foundation routines, this takes its key-value pairs with each value followed by its key.  The disadvantage to this is that you can't easily have runtime-ignored values (the nil value is a terminator rather than being skipped).
void OBErrorWithErrnoObjectsAndKeys(NSError **error, int errno_value, const char *function, NSString *argument, NSString *localizedDescription, ...);
#define OBErrorWithErrno(error, errno_value, function, argument, localizedDescription) OBErrorWithErrnoObjectsAndKeys(error, errno_value, function, argument, localizedDescription, nil)


#if defined(__cplusplus)
} // extern "C"
#endif

