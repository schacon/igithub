//
//  GITBlob.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITObject.h"

extern NSString * const kGITObjectBlobName;

/*! Git object type representing a file.
 */
@interface GITBlob : GITObject
{
    NSData   * data;    //!< The binary data of this blob
}

@property(readonly,copy) NSData * data;

/*! Returns flag indicating probability that data is textual.
 * It is important to note that this indicates only the probability
 * that the receiver's data is textual. The indication is based on
 * the presence, or lack, of a <tt>NULL</tt> byte in the receivers
 * data.
 * \return Flag indicating probability that data is textual.
 */
- (BOOL)canBeRepresentedAsString;

/*! Returns string contents of data.
 * \return String contents of data.
 */
- (NSString*)stringValue;

@end
