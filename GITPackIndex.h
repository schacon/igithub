//
//  GITPackIndex.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 04/11/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! GITPackIndex is a class cluster.
 */
@interface GITPackIndex : NSObject
{
}

/*! \internal
 */
- (id)copyWithZone:(NSZone*)zone;

#pragma mark -
#pragma mark Primitive Methods
/*! Returns the version of IDX file which the receiver is providing
 * access to.
 * \return Numerical version of the receiver
 * \internal Subclasses must override this method
 */
- (NSUInteger)version;

/*! Convenience method that creates and returns a new, autoreleased IDX object 
 * at the specified <tt>path</tt>.
 * \param path Path of the IDX file in the repository
 * \return A new IDX object
 * \internal
 * This method is wrapper that eventually calls -initWithPath:error:
 */
+ (id)packIndexWithPath:(NSString*)thePath;

/*! Convenience method that creates and returns a new, autoreleased IDX object 
 * at the specified <tt>path</tt>.
 * \param path Path of the IDX file in the repository
 * \return A new IDX object
 * \internal
 * This method is wrapper that calls -initWithPath:error:
 */
+ (id)packIndexWithPath:(NSString*)thePath error:(NSError**)outError;

/*! Creates and returns a new IDX object at the specified <tt>path</tt>.
 * \param path Path of the IDX file in the repository
 * \return A new IDX object
 * \internal
 * Subclasses must override this method, failure to do so will result in
 * an error. The overriding implementation should not call this implementation
 * as part of itself. Instead it is recommended to use [super init] instead.
 */
- (id)initWithPath:(NSString*)path;

/*! Creates and returns a new IDX object at the specified <tt>path</tt>.
 * \param path Path of the IDX file in the repository
 * \param[out] error Error object or NULL if you don't care
 * \return A new IDX object or nil if error
 * \internal
 * Subclasses must override this method, failure to do so will result in
 * an error. The overriding implementation should not call this implementation
 * as part of itself. Instead it is recommended to use [super init] instead.
 */
- (id)initWithPath:(NSString*)thePath error:(NSError**)error;

/*! Returns the offset within the associated PACK file where the
 * object specified by the given <tt>sha1</tt> can be located.
 * \param sha1 The SHA1 of the object to return the pack offset for
 * \return Offset value within the associated PACK file for the SHA1 or NSNotFound if not found
 */
- (off_t)packOffsetForSha1:(NSString*)sha1;

/*! Returns the offset within the associated PACK file where the
 * object specified by the given <tt>sha1</tt> can be located.
 * \param sha1 The SHA1 of the object to return the pack offset for
 * \param[out] error Error object or NULL if you don't care
 * \return Offset value within the associated PACK file for the SHA1 or NSNotFound if not found
 */
- (off_t)packOffsetForSha1:(NSString*)sha1 error:(NSError**)error;

#pragma mark -
#pragma mark Reverse Index Lookup Methods
- (off_t)nextOffsetWithOffset:(off_t)offset;
- (NSString *)sha1WithOffset:(off_t)offset;
- (off_t)packOffsetWithIndex:(NSUInteger)i;


#pragma mark -
#pragma mark Internal Primitive Methods
/*! Returns an array of the offsets within the receiver where the offset within
 * the associated PACK file can be found.
 * \returns Array of SHA1 offsets within the receiver
 * \internal
 * This method is required for some of the derived methods
 * it is much more low level than most code requires.
 */
- (NSArray*)offsets;

#pragma mark -
#pragma mark Checksum Methods
/*! Returns checksum data for the receiver
 * \return Checksum data of the receiver
 */
- (NSData*)checksum;

/*! Returns checksum data for the pack file of the receiver
 * \return Checksum data for the pack file of the receiver
 */
- (NSData*)packChecksum;

/*! Returns checksum string for the receiver
 * \return Checksum string of the receiver
 */
- (NSString*)checksumString;

/*! Returns checksum string for the pack file of the receiver
 * \return Checksum string for the pack file of the receiver
 */
- (NSString*)packChecksumString;

/*! Verifies if the checksum matches for the contents of the receiver.
 * \return YES if checksum matches, NO if it does not.
 */
- (BOOL)verifyChecksum;

#pragma mark -
#pragma mark Derived Methods
/*! Returns the number of objects in the receivers PACK file
 * \return Number of objects in the receivers PACK file.
 */
- (NSUInteger)numberOfObjects;

/*! Returns the number of objects whose names (SHA1) begin with the
 * provided first byte.
 * \param byte The byte to get the number of objects for
 * \return Number of objects starting with <tt>byte</tt>
 */
- (NSUInteger)numberOfObjectsWithFirstByte:(uint8_t)byte;

/*! Returns a range describing the number of objects to the beginning of
 * those starting with <tt>byte</tt> and the number of objects ending
 * with <tt>byte</tt>.
 * \param byte The byte to get the range of objects for
 * \return Range describing the objects with the first byte
 */
- (NSRange)rangeOfObjectsWithFirstByte:(uint8_t)byte;

/*! Returns YES if the object identified by <tt>sha1</tt> exists in the
 * receivers PACK file.
 * \param sha1 The name of the object to search for
 * \return YES if the sha1 exists in the receiver, NO if it doesn't.
 */
- (BOOL)hasObjectWithSha1:(NSString*)sha1;

@end

#import "GITPlaceholderPackIndex.h"
#import "GITPackIndexVersion1.h"
#import "GITPackIndexVersion2.h"
