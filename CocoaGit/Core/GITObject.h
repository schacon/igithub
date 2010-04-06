//
//  GITObject.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! Series of constants to define the different types of GIT objects.
 */
typedef enum {
    GITObjectTypeUnknown = 0,
    GITObjectTypeCommit  = 1,
    GITObjectTypeTree    = 2,
    GITObjectTypeBlob    = 3,
    GITObjectTypeTag     = 4,
} GITObjectType;

@class GITRepo;
/*! Abstract base class for the git objects
 */
@interface GITObject : NSObject <NSCopying>
{
    GITRepo  * repo;    //!< Repository the object belongs to
    NSString * sha1;    //!< The SHA1 identifier of the object
    NSString * type;    //!< The blob/commit/tag/tree type
    NSUInteger size;    //!< Size of the content of the object
}

@property(readonly,retain) GITRepo  * repo;
@property(readonly,copy)   NSString * sha1;
@property(readonly,copy)   NSString * type;
@property(readonly,assign) NSUInteger size;

/*! Returns the string name of the type.
 * \deprecated It was a bad idea and it should be removed
 */
+ (NSString*)typeName;

#pragma mark -
#pragma mark GITObjectType Translators
/*! Returns the enum type value for the type string
 * \param type String to return the corresponding object type for
 * \return Object type which corresponds to the type passed
 */
+ (GITObjectType)objectTypeForString:(NSString*)type;

/*! Returns the string for the object type.
 * \param type GITObjectType for the string
 * \return String for the object type
 */
+ (NSString*)stringForObjectType:(GITObjectType)type;

/*! Returns the object type for the receiver
 * \return GITObjectType enum value of the receivers class
 */
- (GITObjectType)objectType;

#pragma mark -
#pragma mark Deprecated Initializsers
/*! Creates and returns a new git object for the given <tt>sha1</tt>
 * in the <tt>repo</tt>.
 *
 * This initialiser requests the object data from the <tt>repo</tt> and
 * then creates the object from the returned data.
 *
 * This the most common initialiser to use to load a type of git object.
 *
 * \attention This is a concrete method.
 * \param sha1 The hash of the object to load
 * \param repo The repository to load the object from
 * \return A new git object for the given <tt>sha1</tt> in the <tt>repo</tt>
 * \deprecated Use -initWithSha1:repo:error: or -initWithSha1:type:data:error:
 */
- (id)initWithSha1:(NSString*)sha1 repo:(GITRepo*)repo;

/*! Creates and returns a new git object.
 * This method is intended to be called only by children of this
 * class in their own initialisers. Where they would normally do
 * \code
 * if (self = [super init])
 * \endcode
 * they will instead do (assuming a blob in this instance)
 * \code
 * if (self = [super initType:@"blob" sha:theSHA1
 *                       size:objectSize repo:theRepo])
 * \endcode
 * and this will setup the common fields for each object type.
 *
 * \attention This is a concrete method.
 * \param newType The type blob/commit/tag/tree of the object
 * \param newSha1 The SHA hash of the object
 * \param newSize The size of the object
 * \param theRepo The repo to which this object belongs
 * \return New git object.
 * \deprecated Use -initWithSha1:repo:error: or -initWithSha1:type:data:error:
 */
- (id)initType:(NSString*)newType sha1:(NSString*)newSha1
          size:(NSUInteger)newSize repo:(GITRepo*)theRepo;

#pragma mark -
#pragma mark Error Aware Initializers
/*! Creates and returns a new GITObject.
 * \param sha1 The SHA1 name of the objects
 * \param repo The GITRepo the object belongs to
 * \param[out] error The NSError containing the error details
 * \return New GITObject or nil if an error occurred
 * \see -initWithSha1:type:data:repo:error:
 * \see GITRepo
 * \see GITObjectStore
 */
- (id)initWithSha1:(NSString*)sha1 repo:(GITRepo*)repo error:(NSError**)error;

/*! Creates and returns a new GITObject.
 * \param sha1 The SHA1 name of the objects
 * \param type The GITObjectType enum value of the object
 * \param data The raw data of the objects contents
 * \param repo The GITRepo the object belongs to
 * \param[out] error The NSError containing the error details
 * \return New GITObject or nil if an error occurred
 * \par Errors:
 * \li \c GITErrorObjectParsingFailed indicates a problem parsing the raw object data
 * \li \c GITErrorObjectTypeMismatch indicates the object identified by \a sha1 is not of type \a type
 */
- (id)initWithSha1:(NSString*)sha1 type:(GITObjectType)type data:(NSData*)data
              repo:(GITRepo*)repo error:(NSError**)error;

#pragma mark -
#pragma mark Data Parser
/*! Parses the contents of the raw data for the reciever.
 * \param raw The raw object data to be parsed
 * \param[out] error The NSError containing the error details
 * \return YES if parsed successfully, NO if an error occurred.
 * \par Errors:
 * \li \c GITErrorObjectParsingFailed indicates a problem parsing the raw object data
 */
- (BOOL)parseRawData:(NSData*)raw error:(NSError**)error;

#pragma mark -
#pragma mark NSCopying
/*! Returns a new instance that's a copy of the receiver.
 * Children should call this implementation first when overriding it as this will init
 * the fields of the base object first. Children can then add to the copied object any
 * further content which is required.
 *
 * Here is an example implementation for a child defining a blob object
 * \code
 * - (id)copyWithZone:(NSZone*)zone
 * {
 *     MyBlob * blob = (MyBlob*)[super copyWithZone:zone];
 *     blob.data = self.data;
 *     return blob;
 * }
 * \endcode
 * \attention This is a concrete method.
 * \param zone The zone identifies an area of memory from which to allocate for the new 
 * instance. If zone is <tt>NULL</tt>, the new instance is allocated from the default 
 * zone, which is returned from the function NSDefaultMallocZone.
 * \return A new instance that's a copy of the receiver.
 */
- (id)copyWithZone:(NSZone*)zone;

#pragma mark -
#pragma mark Comparison methods
/*! Returns a Boolean value that indicates whether the receiver and a given GITObject are equal.
 *
 * Instances of GITObject and GITObject subclasses are equal if their Sha1 values are equal.
 * \otherObject The object to be compared to the receiver.
 * \return YES if the receiver and otherObject are equal, otherwise NO.
 */
- (BOOL) isEqual:(GITObject *)otherObject;

#pragma mark -
#pragma mark Raw Format methods
/*! Returns the raw data representations of the object. Raw Data is the 
 *  git-format data for an object including the header (type + size) information.
 * \attention This is a concrete method.
 * \see rawContent
 * \return Raw data of the object
 */
- (NSData *) rawData;

/*! Returns the raw content of the object. Raw content is the git-format data
 *  for an object without the header (type + size) information.
 * \attention This is an abstract method.
 * \see rawData
 * \return Raw content of the object
 */
- (NSData *) rawContent;
@end
