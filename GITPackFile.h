//
//  GITPackFile.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITPackIndex.h"
#import "GITErrors.h"
#import "GITObject.h"

/*! Series of constants to define the different types of GIT objects
 *  the exist in a PACK file.
 */
enum {
    // Base Types - These mirror those of GITObjectType
    kGITPackFileTypeCommit = 1,
    kGITPackFileTypeTree   = 2,
    kGITPackFileTypeBlob   = 3,
    kGITPackFileTypeTag    = 4,
    
    // Delta Types
    kGITPackFileTypeDeltaOfs  = 6,
    kGITPackFileTypeDeltaRefs = 7
};

/*! GITPackFile is a class which provides access to individual
 * PACK files within a git repository.
 *
 * A PACK file is an archive format used by git primarily for
 * network transmission of repository objects. Once transmitted
 * the received PACK files are then used for access to the stored
 * objects.
 *
 * \attention GITPackFile is a class cluster, subclasses must
 * override the following primitive methods.
 */
@interface GITPackFile : NSObject
{
}

#pragma mark -
#pragma mark Primitive Methods
/*! Returns the version of PACK file which the receiver is providing
 * access to.
 * \return Numerical version of the receiver
 * \internal Subclasses must override this method
 */
- (NSUInteger)version;

/*! Returns the corresponding index for the receiver
 * \return The index for the receiver
 * \internal Subclasses must override this method
 */
- (GITPackIndex*)index;

/*! Convenience method to create and returns a new, autoreleased
 * PACK object at the specified <tt>path</tt>.
 * This is a convenience method that calls -initWithPath:path error:NULL.
 * \param path Path of the PACK file in the repository
 * \return A new PACK object
 * \internal
 */
+ (id) packFileWithPath:(NSString *)thePath;

/*! Creates and returns a new PACK object at the specified <tt>path</tt>.
 * This is a convenience method that calls -initWithPath:path error:NULL.
 * \param path Path of the PACK file in the repository
 * \return A new PACK object
 * \internal
 */
- (id)initWithPath:(NSString*)path;

/*! Convenience method to create and returns a new, autoreleased
 * PACK object at the specified <tt>path</tt>.
 * This is a convenience method that calls -initWithPath:path error:NULL.
 * \param path Path of the PACK file in the repository
 * \return A new PACK object
 * \internal
 */
+ (id) packFileWithPath:(NSString *)thePath error:(NSError **)error;

/*! Creates and returns a new PACK object at the specified <tt>path</tt>.
 * \param path Path of the PACK file in the repository
 * \param[out] error NSError object containing any errors, pass NULL if you don't care
 * \return A new PACK object
 * \internal
 * Subclasses must override this method, failure to do so will result in
 * an error. The overriding implementation should not call this implementation
 * as part of itself. Instead it is recommended to use [super init] instead.
 */
- (id)initWithPath:(NSString*)path error:(NSError **)error;

/*! Creates and returns a new PACK object from the specified <tt>data</tt>.
 * \param packData NSData containing packed objects
 * \param[out] error NSError object containing any errors, pass NULL if you don't care
 * \return A new PACK object
 * \internal
 * Subclasses must override this method, failure to do so will result in
 * an error. The overriding implementation should not call this implementation
 * as part of itself. Instead it is recommended to use [super init] instead.
 */
- (id)initWithData:(NSData *)packData error:(NSError **)error;

/*! Creates and returns a new PACK object at the specified <tt>path</tt>
 *  with a corresponding index file at the specified indexPath.
 * \param path Path of the PACK file in the repository
 * \param idxPath Path of the index file for this PACK file in the repository
 * \param[out] error NSError object containing any errors, pass NULL if you don't care
 * \return A new PACK object
 * \internal
 * Subclasses must override this method, failure to do so will result in
 * an error. The overriding implementation should not call this implementation
 * as part of itself. Instead it is recommended to use [super init] instead.
 */
- (id)initWithPath:(NSString*)path indexPath:(NSString *)idxPath error:(NSError **)error;

/*! Returns the data for the object specified by the given <tt>sha1</tt>.
 * The <tt>sha1</tt> will first be checked to see if it exists
 * \param sha1 The SHA1 of the object to retrieve the data for.
 * \return Data for the object or <tt>nil</tt> if the object is not in
 * the receiver
 * \deprecated use -loadObjectWithSha1:intoData:type:error: instead
 */
- (NSData*)dataForObjectWithSha1:(NSString*)sha1;

/*! Loads and returns the contents of an object.
 * \param sha1 The SHA1 name of the object to load
 * \param[out] data Data to load the object contents into
 * \param[out] type The GITObjectType of the object
 * \param[out] error NSError object containing any errors, pass NULL if you don't care
 * \return YES on successful load, NO if an error occurred
 * \internal
 * We might possibly consider the following extension to this method once Deltas
 * are being parsed. If the type parameter has a non-zero value then this will be
 * perceived as an expected type setting, an error should be returned if this
 * expected type is not met.
 */
- (BOOL)loadObjectWithSha1:(NSString*)sha1 intoData:(NSData**)data
                      type:(GITObjectType*)type error:(NSError**)error;

#pragma mark -
#pragma mark Checksum Methods
/*! Returns checksum data for the receiver
 * \return Checksum data of the receiver
 */
- (NSData*)checksum;

/*! Returns checksum string for the receiver
 * \return Checksum string of the receiver
 */
- (NSString*)checksumString;

/*! Verifies if the checksum matches for the contents of the receiver.
 * \return YES if checksum matches, NO if it does not.
 */
- (BOOL)verifyChecksum;

#pragma mark -
#pragma mark Derived Methods
/*! Returns the number of objects in the receiver
 * \return Number of objects in the receiver
 */
- (NSUInteger)numberOfObjects;

/*! Indicates whether the receiver contains the object specified by the
 * given <tt>sha1</tt>.
 * \param sha1 The SHA1 of the object to check the presence of
 * \return BOOL indicating if the receiver contains the object
 */
- (BOOL)hasObjectWithSha1:(NSString*)sha1;

@end

#import "GITPlaceholderPackFile.h"
#import "GITPackFileVersion2.h"
