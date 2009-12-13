//
//  GITTreeEntry.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 05/08/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSUInteger kGITPackedSha1Length;
extern const NSUInteger kGITUnpackedSha1Length;

@class GITObject, GITTree;
/*! An entry in tree listing.
 * \todo Consider changing from having a GITRepo instance
 * as part of the class to having an instance of the tree
 * which the entry is a part of. We can then defer to the
 * trees repo for object loading. We then need to be very
 * careful about creating memory dependencies which are
 * difficult to manage and may result in memory leakage.
 */
@interface GITTreeEntry : NSObject
{
    NSString * name;    //!< Name of the entry, either a file or directory name
    NSUInteger mode;    //!< File mode of the entry
    NSString * sha1;    //!< SHA1 of the object referenced
    GITTree  * parent;  //!< The tree object this entry belongs to.
    GITObject * object; //!< The object which is referenced. This is lazy loaded.
}

@property(readonly,copy) NSString  * name;
@property(readonly,assign) NSUInteger mode;
@property(readonly,copy) NSString  * sha1;
@property(readonly,copy) GITTree   * parent;
@property(readonly,copy) GITObject * object;

#pragma mark -
#pragma mark Deprecated Initialisers
/*! Creates and returns a new entry by extracting the information tree line.
 * \param line The raw line as extracted from a tree object file
 * \param parent The parent tree this entry belongs to
 * \return A new entry
 * \deprecated Use -initWithRawString:parent:error: instead
 */
- (id)initWithTreeLine:(NSString*)line parent:(GITTree*)parent;

/*! Creates and returns a new entry the given settings
 * \param mode The file mode of the file or directory described
 * \param name The file name of the filr or directory described
 * \param hash The SHA1 of the object referenced
 * \param parent The parent tree this entry belongs to
 * \return A new entry
 * \deprecated Use -initWithFileMode:name:sha1:parent:error: instead
 */
- (id)initWithMode:(NSUInteger)mode name:(NSString*)name
              sha1:(NSString*)hash parent:(GITTree*)parent;

/*! Creates and returns a new entry the given settings
 * \param mode The file mode as a string of the file or directory described
 * \param name The file name of the filr or directory described
 * \param hash The SHA1 of the object referenced
 * \param parent The parent tree this entry belongs to
 * \return A new entry
 * \deprecated Use -initWithFileMode:name:sha1:parent:error: instead
 */
- (id)initWithModeString:(NSString*)mode name:(NSString*)name
                    sha1:(NSString*)hash parent:(GITTree*)parent;

#pragma mark -
#pragma mark Error Aware Initialisers
/*! Creates and returns a new entry by extracting the fields from the raw string.
 * \param raw The raw string from a tree object file
 * \param parent The parent tree this entry belongs to
 * \param[out] error Error containing a description of any errors if they occurred
 * \return A new entry or nil if an error occurred
 * \par Errors:
 * \li \c GITErrorObjectParsingFailed indicates a problem parsing the formatted tree entry
 */
- (id)initWithRawString:(NSString*)raw parent:(GITTree*)parent error:(NSError**)error;

/*! Creates and returns a new entry the given settings
 * \param mode The file mode of the file or directory described
 * \param name The file name of the filr or directory described
 * \param sha1 The SHA1 of the object referenced
 * \param parent The parent tree this entry belongs to
 * \param[out] error Error containing a description of any errors if they occurred
 * \return A new entry or nil if error
 */
- (id)initWithFileMode:(NSUInteger)mode name:(NSString*)name sha1:(NSString*)sha1 parent:(GITTree*)parent error:(NSError**)error;

- (NSData*)raw;
@end
