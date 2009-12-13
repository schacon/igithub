//
//  GITObjectStore.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 09/10/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITErrors.h"
#import "GITObject.h"

/*! Generic object storage class.
 * Desendants of GITObjectStore implement different ways of
 * accessing the objects of a repository.
 */
@interface GITObjectStore : NSObject
{
}
/*! Convenience method that creates and returns a new, autoreleased
 * store object from the provided .git root. 
 * \attention This method calls -initWithRoot:error:
 * \param root Path to the .git root directory
 * \return A new store object.
 */
+ (id) storeWithRoot:(NSString *)root;

/*! Convenience method that creates and returns a new, autoreleased
 * store object from the provided .git root. 
 * \attention This method calls -initWithRoot:error:
 * \param root Path to the .git root directory
 * \return A new store object.
 */
+ (id) storeWithRoot:(NSString *)root error:(NSError **)error;

/*! Creates and returns a new store object from the provided .git root
 * \attention This method must be overridden
 * \param root Path to the .git root directory
 * \return A new store object.
 */
- (id)initWithRoot:(NSString*)root;

/*! Creates and returns a new store object from the provided .git root
 * \attention This method must be overridden
 * \param root Path to the .git root directory
 * \param[out] error Object encapsulating any errors which occur
 * \return A new store object or nil on error
 * \par Error Codes:
 * \li \c GITErrorObjectStoreNotAccessible store could not be loaded
 */
- (id)initWithRoot:(NSString*)root error:(NSError**)error;

/*! Returns the contents of an object for the given <tt>sha1</tt>.
 * The data returned should be in a form which is usable to initialise an
 * object. If the data is stored compressed or encrypted it should be
 * decompressed or decrypted before returning.
 * \attention This method must be overridden
 * \param sha1 The object reference to return the data for
 * \return Contents of an object, nil if the object cannot be found
 * \deprecated use -loadObjectWithSha1:intoData:type:error: instead
 */
- (NSData*)dataWithContentsOfObject:(NSString*)sha1;

/*! \internal
 * Returns if the receiver can return the object with the given <tt>sha1</tt>.
 * Indicates if the receiver is able to return data for an object with the
 * given <tt>sha1</tt> identifer.
 * \param sha1 Name of the object to check for
 * \return YES if has data for object, NO if not.
 */
- (BOOL)hasObjectWithSha1:(NSString*)sha1;

/*! Extracts the basic information from a git object file.
 * \param sha1 The object reference to extract the data from
 * \param[out] type The type of the object as a string
 * \param[out] size The size of <tt>data</tt> in bytes
 * \param[out] data The data content of the object
 * \return Indication that the extraction was successful.
 * \deprecated use -loadObjectWithSha1:intoData:type:error: instead
 */
- (BOOL)extractFromObject:(NSString*)sha1 type:(NSString**)type
                     size:(NSUInteger*)size data:(NSData**)data;

/*! Loads and returns the contents of an object.
 * \param sha1 The SHA1 name of the object to load
 * \param[out] data Data to load the object contents into
 * \param[out] type The GITObjectType of the object
 * \param[out] error NSError object containing any errors, pass NULL if you don't care
 * \return YES on successful load, NO if an error occurred
 * \par Errors:
 * \li \c GITErrorObjectNotFound no object with \a sha1 could be found in the receiver
 * \li \c GITErrorObjectSizeMismatch size of object identified by \a sha1 does not match meta data
 * \internal
 * We might possibly consider the following extension to this method once Deltas
 * are being parsed. If the type parameter has a non-zero value then this will be
 * perceived as an expected type setting, an error should be returned if this
 * expected type is not met.
 */
- (BOOL)loadObjectWithSha1:(NSString*)sha1 intoData:(NSData**)data
                      type:(GITObjectType*)type error:(NSError**)error;
@end
