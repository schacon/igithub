//
//  GITError.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 09/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//
// We use the __git_error and __git_error_domain macros to
// make it easier to enter and update the error codes in
// the project. If you define them here with the macro then
// you can copy/paste the same code into GITErrors.m and
// then add the value argument to the end of them.
//

#import <Foundation/Foundation.h>
#define __git_error(code) extern const NSInteger code
#define __git_error_domain(dom) extern NSString * dom

__git_error_domain(GITErrorDomain);

#import "NSError-OBExtensions.h"

// Define GITError* macros to use the OmniBase _OBError helper functions. If we decide to move away from OmniBase code, we can just redfine these.
#define GITError(error, code, description) _OBError(error, GITErrorDomain, code, __FILE__, __LINE__, NSLocalizedDescriptionKey, description, nil)
#define GITErrorWithInfo(error, code, ...) _OBError(error, GITErrorDomain, code, __FILE__, __LINE__, ## __VA_ARGS__)

#pragma mark Object Loading Errors
__git_error(GITErrorObjectSizeMismatch);
__git_error(GITErrorObjectNotFound);
__git_error(GITErrorObjectTypeMismatch);
__git_error(GITErrorObjectParsingFailed);

#pragma mark File Reading Errors
__git_error(GITErrorFileNotFound);

#pragma mark Store Error Codes
__git_error(GITErrorObjectStoreNotAccessible);
__git_error(GITErrorRefStoreNotAccessible);

#pragma mark PACK and Index Error Codes
__git_error(GITErrorPackIndexUnsupportedVersion);
__git_error(GITErrorPackIndexCorrupted);
__git_error(GITErrorPackIndexChecksumMismatch);
__git_error(GITErrorPackIndexNotAvailable);
__git_error(GITErrorPackFileInvalid);
__git_error(GITErrorPackFileNotSupported);
__git_error(GITErrorPackFileChecksumMismatch);

#undef __git_error
#undef __git_error_domain
