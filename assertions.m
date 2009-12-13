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

#import "assertions.h"
#import <Foundation/Foundation.h>
#import <unistd.h> // For getpid()

// RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease/2008-09-09/OmniGroup/Frameworks/OmniBase/assertions.m 102862 2008-07-15 05:14:37Z bungi $")

#ifdef OMNI_ASSERTIONS_ON

BOOL OBEnableExpensiveAssertions = NO;

void OBLogAssertionFailure(const char *type, const char *expression, const char *file, unsigned int lineNumber)
{
    fprintf(stderr, "%s failed: requires '%s', file %s, line %d\n", type, expression, file, lineNumber);
}

static NSString *OBShouldAbortOnAssertFailureEnabled = @"OBShouldAbortOnAssertFailureEnabled";

static void OBDefaultAssertionHandler(const char *type, const char *expression, const char *file, unsigned int lineNumber)
{
    OBLogAssertionFailure(type, expression, file, lineNumber);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:OBShouldAbortOnAssertFailureEnabled])
        abort();
    else if (OBIsRunningUnitTests()) {
        // If we are running unit tests, abort on assertion failure.  We could make assertions throw exceptions, but note that this wouldn't catch cases where you are using 'shouldRaise' and hit an assertion.
#ifdef DEBUG
        // If we're failing in a debug build, give the developer a little time to connect in gdb before crashing
        fprintf(stderr, "You have 15 seconds to attach to pid %u in gdb...\n", getpid());
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:15.0]];
#endif
        abort();
    }
}

static OBAssertionFailureHandler currentAssertionHandler = OBDefaultAssertionHandler;
void OBSetAssertionFailureHandler(OBAssertionFailureHandler handler)
{
    if (handler)
        currentAssertionHandler = handler;
    else
        currentAssertionHandler = OBDefaultAssertionHandler;
}

void OBAssertFailed(const char *type, const char *expression, const char *file, unsigned int lineNumber)
{
     currentAssertionHandler(type, expression, file, lineNumber);
}

#endif

#if defined(OMNI_ASSERTIONS_ON) || defined(DEBUG)

static void _OBAssertionLoad(void) __attribute__((constructor));
static void _OBAssertionLoad(void)
{
#ifdef OMNI_ASSERTIONS_ON
    OBEnableExpensiveAssertions = [[NSUserDefaults standardUserDefaults] boolForKey:@"OBEnableExpensiveAssertions"];
    if (getenv("OBASSERT_NO_BANNER") == NULL) {
        fprintf(stderr, "*** Assertions are ON ***\n");
        if (OBEnableExpensiveAssertions)
            fprintf(stderr, "*** Expensive assertions are ON ***\n");
    }
#elif DEBUG
    if (getenv("OBASSERT_NO_BANNER") == NULL)
        fprintf(stderr, "*** Assertions are OFF ***\n");
#endif
}
#endif
