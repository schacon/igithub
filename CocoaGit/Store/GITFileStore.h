//
//  GITFileStore.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 07/10/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITObjectStore.h"

/*! Loose file object storage.
 * Accesses objects stored as compressed files in <tt>.git/objects</tt>
 * directory.
 */
@interface GITFileStore : GITObjectStore
{
    NSString * objectsDir;  //!< Path to the <tt>.git/objects</tt> directory
}

@property(readonly,copy) NSString * objectsDir;

/*! Returns the path to the object in the objects directory.
 * \param sha1 The object reference to generate the path for.
 * \return Path to the object identified by <tt>sha1</tt>
 */
- (NSString*)stringWithPathToObject:(NSString*)sha1;
@end
