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

#import "NSError-OBExtensions.h"
#import "assertions.h"

// RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease/2008-09-09/OmniGroup/Frameworks/OmniBase/NSError-OBExtensions.m 103848 2008-08-07 00:10:55Z wiml $");

// If this is built as part of a tool (like the OSU check tool), we won't get a bundle identifier defined.

// Must be a better way to do this, rather than redefine it here.
#define DEFAULT_ERROR_DOMAIN @"com.manicpanda.GIT.ErrorDomain"

NSString * const OBUserCancelledActionErrorKey = DEFAULT_ERROR_DOMAIN @".ErrorDueToUserCancel";
NSString * const OBFileNameAndNumberErrorKey = DEFAULT_ERROR_DOMAIN @".FileLineAndNumber";

static NSMutableDictionary *_createUserInfo(NSString *firstKey, va_list args)
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];

    NSString *key = firstKey;
    while (key) { // firstKey might be nil
	id value = va_arg(args, id);
        if (value)
            [userInfo setObject:value forKey:key];
	key = va_arg(args, id);
    }
    
    return userInfo;
}

@implementation NSError (OBExtensions)

// Returns YES if the error or any of its underlying errors has the indicated domain and code.
- (BOOL)hasUnderlyingErrorDomain:(NSString *)domain code:(int)code;
{
    NSError *error = self;
    while (error) {
	if ([[error domain] isEqualToString:domain] && [error code] == code)
	    return YES;
	error = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
    }
    return NO;
}

/*" Returns YES if the receiver or any of its underlying errors has a user info key of OBUserCancelledActionErrorKey with a boolean value of YES.  Under 10.4 and higher, this also returns YES if the receiver or any of its underlying errors has the domain NSCocoaErrorDomain and code NSUserCancelledError (see NSResponder.h). "*/
- (BOOL)causedByUserCancelling;
{    
    NSError *error = self;
    while (error) {
	NSDictionary *userInfo = [error userInfo];
	if ([[userInfo objectForKey:OBUserCancelledActionErrorKey] boolValue])
	    return YES;
	
#if defined(MAC_OS_X_VERSION_10_4) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
	// TJW: There is also NSUserCancelledError in 10.4.  See NSResponder.h -- it says NSApplication will bail on presenting the error if the domain is NSCocoaErrorDomain and code is NSUserCancelledError.  It's unclear if NSApplication checks the whole chain (question open on cocoa-dev as of 2005/09/29).
	if ([[error domain] isEqualToString:NSCocoaErrorDomain] && [error code] == NSUserCancelledError)
	    return YES;
#endif
	
	error = [userInfo objectForKey:NSUnderlyingErrorKey];
    }
    return NO;
}


static void _mapPlistValueToUserInfoEntry(const void *key, const void *value, void *context)
{
    NSString *keyString = (NSString *)key;
    id valueObject = (id)value;
    NSMutableDictionary *mappedUserInfo = (NSMutableDictionary *)context;
    
    // This is lossy, but once something is plist-ified, we can't be sure where it came from.
    if ([keyString isEqualToString:NSUnderlyingErrorKey])
        valueObject = [[[NSError alloc] initWithPropertyList:valueObject] autorelease];
    
    [mappedUserInfo setObject:valueObject forKey:keyString];
}

- initWithPropertyList:(NSDictionary *)propertyList;
{
    NSString *domain = [propertyList objectForKey:@"domain"];
    NSNumber *code = [propertyList objectForKey:@"code"];
    
    OBASSERT(domain);
    OBASSERT(code);
    
    NSDictionary *userInfo = [propertyList objectForKey:@"userInfo"];
    if (userInfo) {
        NSMutableDictionary *mappedUserInfo = [NSMutableDictionary dictionary];
        CFDictionaryApplyFunction((CFDictionaryRef)userInfo, _mapPlistValueToUserInfoEntry, mappedUserInfo);
        userInfo = mappedUserInfo;
    }
    
    return [self initWithDomain:domain code:[code intValue] userInfo:userInfo];
}

static void _mapUserInfoEntryToPlistValue(const void *key, const void *value, void *context)
{
    NSString *keyString = (NSString *)key;
    id valueObject = (id)value;
    NSMutableDictionary *mappedUserInfo = (NSMutableDictionary *)context;
    
    if ([valueObject isKindOfClass:[NSError class]])
        valueObject = [(NSError *)valueObject toPropertyList];
    
    if ([valueObject isKindOfClass:[NSURL class]])
        valueObject = [valueObject absoluteString];
    
    // We can only bring along plist-able values (so, for example, no NSRecoveryAttempterErrorKey).
    if (![NSPropertyListSerialization propertyList:valueObject isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
#ifdef DEBUG
        NSLog(@"'%@' of class '%@' is not a property list value.", valueObject, [valueObject class]);
#endif
        valueObject = [valueObject description];
    }
    
    if (!valueObject)
        valueObject = @"<empty string>";
    
    [mappedUserInfo setObject:valueObject forKey:keyString];
}

- (NSDictionary *)toPropertyList;
{
    NSMutableDictionary *plist = [NSMutableDictionary dictionary];
    
    [plist setObject:[self domain] forKey:@"domain"];
    [plist setObject:[NSNumber numberWithInt:[self code]] forKey:@"code"];
    
    NSDictionary *userInfo = [self userInfo];
    if (userInfo) {
        NSMutableDictionary *mappedUserInfo = [NSMutableDictionary dictionary];
        CFDictionaryApplyFunction((CFDictionaryRef)userInfo, _mapUserInfoEntryToPlistValue, mappedUserInfo);
        [plist setObject:mappedUserInfo forKey:@"userInfo"];
    }
    
    return plist;
}

@end

void OBErrorWithDomainv(NSError **error, NSString *domain, int code, const char *fileName, unsigned int line, NSString *firstKey, va_list args)
{
    // Some uncertainty about whether it's really kosher to have a NULL error here. Some Foundation code on 10.4 would crash if you did this, but on 10.5, many methods are documented to allow it. So let's allow it also.
    if (!error)
        return;
    
    NSMutableDictionary *userInfo = _createUserInfo(firstKey, args);
    
    // Add in the previous error, if there was one
    if (*error) {
	OBASSERT(![userInfo objectForKey:NSUnderlyingErrorKey]); // Don't pass NSUnderlyingErrorKey in the varargs to this macro, silly!
	[userInfo setObject:*error forKey:NSUnderlyingErrorKey];
    }
    
    // Add in file and line information if the file was supplied
    if (fileName) {
	NSString *fileString = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:fileName length:strlen(fileName)];
	[userInfo setObject:[fileString stringByAppendingFormat:@":%d", line] forKey:OBFileNameAndNumberErrorKey];
    }
    
    *error = [NSError errorWithDomain:domain code:code userInfo:userInfo];
    [userInfo release];
}

/*" Convenience function, invoked by the OBError macro, that allows for creating error objects with user info objects without creating a dictionary object.  The keys and values list must be terminated with a nil key. "*/
void _OBError(NSError **error, NSString *domain, int code, const char *fileName, unsigned int line, NSString *firstKey, ...)
{
    OBPRECONDITION(domain != nil && [domain length] > 0);
    
    if (!error)
        return;
    
    va_list args;
    va_start(args, firstKey);
    OBErrorWithDomainv(error, domain, code, fileName, line, firstKey, args);
    va_end(args);
}

void _OBErrorWithDescription(NSError **error, NSString *domain, int code, const char *fileName, unsigned int line, NSString *message, ...)
{
    OBPRECONDITION(domain != nil && [domain length] > 0);
    
    if (!error)
        return;
    
    va_list args;
    va_start(args, message);
    NSString *localizedDescription = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    _OBError(error, domain, code, fileName, line, NSLocalizedDescriptionKey, localizedDescription);
    [localizedDescription release];
}

void OBErrorWithErrnoObjectsAndKeys(NSError **error, int errno_value, const char *function, NSString *argument, NSString *localizedDescription, ...)
{
    if (!error)
        return;
    
    NSMutableString *description = [[NSMutableString alloc] init];
    if (function)
        [description appendFormat:@"%s: ", function];
    if (argument) {
        [description appendString:argument];
        [description appendString:@": "];
    }
    [description appendFormat:@"%s", strerror(errno_value)];
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:description forKey:NSLocalizedFailureReasonErrorKey];
    [description release];
    if (localizedDescription)
        [userInfo setObject:localizedDescription forKey:NSLocalizedDescriptionKey];
    
    va_list kvargs;
    va_start(kvargs, localizedDescription);
    for(;;) {
        NSObject *anObject = va_arg(kvargs, NSObject *);
        if (!anObject)
            break;
        NSString *aKey = va_arg(kvargs, NSString *);
        if (!aKey) {
            NSLog(@"*** OBErrorWithErrnoObjectsAndKeys(..., %s, %@, ...) called with an odd number of varargs!", function, localizedDescription);
            break;
        }
        [userInfo setObject:anObject forKey:aKey];
    }
    va_end(kvargs);
    
    *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno_value userInfo:userInfo];
    [userInfo release];
}

