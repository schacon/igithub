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

// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease/2008-09-09/OmniGroup/Frameworks/OmniBase/assertions.h 102857 2008-07-15 04:22:17Z bungi $

#import <objc/objc.h>

#if defined(DEBUG) || defined(OMNI_FORCE_ASSERTIONS)
#define OMNI_ASSERTIONS_ON
#endif

// This allows you to turn off assertions when debugging
#if defined(OMNI_FORCE_ASSERTIONS_OFF)
#undef OMNI_ASSERTIONS_ON
#warning Forcing assertions off!
#endif


// Make sure that we don't accidentally use the ASSERT macro instead of OBASSERT
#ifdef ASSERT
#undef ASSERT
#endif

#if defined(__cplusplus)
extern "C" {
#endif    

typedef void (*OBAssertionFailureHandler)(const char *type, const char *expression, const char *file, unsigned int lineNumber);

extern void OBLogAssertionFailure(const char *type, const char *expression, const char *file, unsigned int lineNumber); // in case you want to integrate the normal behavior with your handler

#if defined(OMNI_ASSERTIONS_ON)

    extern void OBSetAssertionFailureHandler(OBAssertionFailureHandler handler);

    extern void OBAssertFailed(const char *type, const char *expression, const char *file, unsigned int lineNumber);

    extern BOOL OBEnableExpensiveAssertions;

    #define OBPRECONDITION(expression)                                            \
    do {                                                                        \
        if (!(expression))                                                      \
            OBAssertFailed("PRECONDITION", #expression, __FILE__, __LINE__);    \
    } while (NO)

    #define OBPOSTCONDITION(expression)                                           \
    do {                                                                        \
        if (!(expression))                                                      \
            OBAssertFailed("POSTCONDITION", #expression, __FILE__, __LINE__);   \
    } while (NO)

    #define OBINVARIANT(expression)                                               \
    do {                                                                        \
        if (!(expression))                                                      \
            OBAssertFailed("INVARIANT", #expression, __FILE__, __LINE__);       \
    } while (NO)

    #define OBASSERT(expression)                                                  \
    do {                                                                        \
        if (!(expression))                                                      \
            OBAssertFailed("ASSERT", #expression, __FILE__, __LINE__);          \
    } while (NO)

    #define OBASSERT_NOT_REACHED(reason)                                        \
    do {                                                                        \
        OBAssertFailed("NOTREACHED", reason, __FILE__, __LINE__);              \
    } while (NO)

    #define OBPRECONDITION_EXPENSIVE(expression) do { \
        if (OBEnableExpensiveAssertions) \
            OBPRECONDITION(expression); \
    } while(NO)

    #define OBPOSTCONDITION_EXPENSIVE(expression) do { \
        if (OBEnableExpensiveAssertions) \
            OBPOSTCONDITION(expression); \
    } while(NO)

    #define OBINVARIANT_EXPENSIVE(expression) do { \
        if (OBEnableExpensiveAssertions) \
            OBINVARIANT(expression); \
    } while(NO)

    #define OBASSERT_EXPENSIVE(expression) do { \
        if (OBEnableExpensiveAssertions) \
            OBASSERT(expression); \
    } while(NO)

#else	// else insert blank lines into the code

    #define OBPRECONDITION(expression)
    #define OBPOSTCONDITION(expression)
    #define OBINVARIANT(expression)
    #define OBASSERT(expression)
    #define OBASSERT_NOT_REACHED(reason)

    #define OBPRECONDITION_EXPENSIVE(expression)
    #define OBPOSTCONDITION_EXPENSIVE(expression)
    #define OBINVARIANT_EXPENSIVE(expression)
    #define OBASSERT_EXPENSIVE(expression)

#endif
#if defined(__cplusplus)
} // extern "C"
#endif
