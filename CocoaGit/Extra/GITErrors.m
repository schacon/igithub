//
//  GITError.m
//  CocoaGit
//
//  Created by Geoffrey Garside on 09/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import "GITErrors.h"
#define __git_error(code, val) const NSInteger code = val
#define __git_error_domain(dom, str) NSString * dom = str

__git_error_domain(GITErrorDomain, @"com.manicpanda.GIT.ErrorDomain");

#pragma mark Object Loading Errors
__git_error(GITErrorObjectSizeMismatch,             -1);
__git_error(GITErrorObjectNotFound,                 -2);
__git_error(GITErrorObjectTypeMismatch,             -3);
__git_error(GITErrorObjectParsingFailed,            -4);

#pragma mark File Reading Errors
__git_error(GITErrorFileNotFound,                   -100);

#pragma mark Store Error Codes
__git_error(GITErrorObjectStoreNotAccessible,       -200);
__git_error(GITErrorRefStoreNotAccessible,          -201);

#pragma mark PACK and Index Error Codes
__git_error(GITErrorPackIndexUnsupportedVersion,    -300);
__git_error(GITErrorPackIndexCorrupted,             -301);
__git_error(GITErrorPackIndexChecksumMismatch,      -302);
__git_error(GITErrorPackIndexNotAvailable,          -303);

__git_error(GITErrorPackFileInvalid,                -400);
__git_error(GITErrorPackFileNotSupported,           -401);
__git_error(GITErrorPackFileChecksumMismatch,       -402);

#undef __git_error
