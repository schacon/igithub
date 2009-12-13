//
//  GITPackStore.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 07/10/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITObjectStore.h"

@class GITPackFile;

/*! Packed objects storage.
 * Accesses objects stored as in PACK files in
 * <tt>.git/objects/pack</tt> directory.
 * \internal
 * PACK files are do not independently represent
 * the objects of a repository. Instead each PACK
 * holds only the objects which were not already
 * stored within a PACK.
 * For this reason the GITPackStore must to keep a
 * reference to each PACK file within the packsDir
 * so that it may correctly find the objects which
 * are requested. To improve the speed of retrieval
 * some kind of caching should probably be done.
 * The two main options I can see are an NSDictionary
 * of SHA1 -> PACK mappings and a reference to the
 * last PACK which successfully returned an object.
 * The first method is primarily useful for repetitive
 * accesses of the same SHA, while possible it would
 * probably be a better idea to leave this option for
 * now and see how often a SHA is accessed. The other
 * method is useful for accessing objects which are
 * likely to be nearby to each other. This would be
 * the most useful as typical operation would involve
 * reading a Commit, accessing its Tree and the Tree
 * contents. These objects are all reasonably likely
 * to be contained within the same PACK file.
 *
 * Houston we have a problem
 * PACK files do not store the object data in a similar
 * way to loose files. Loose files include a type/size
 * meta header at the top of the loose file. The data
 * for an object in a PACK file is just the contents.
 * The type/size meta header information is not present
 * within the object data. Instead this information is
 * separate within the PACK file just before the object
 * data. This poses a problem for the current method of
 * extracting the object data from a store and creating
 * an instance of the correct class from that data.
 * This could require a fundamental re-engineering of
 * the way in which objects are retrieved from stores &
 * the way in which objects are instanciated from the
 * data retrieved from the stores.
 *
 * The main question is, how do we change it and into
 * what form?
 */
@interface GITPackStore : GITObjectStore
{
    NSString * packsDir;    //!< Path to <tt>.git/objects/pack</tt> directory.
    NSArray * packFiles;
    GITPackFile * lastReadPack;
}

@property(readonly,copy) NSString * packsDir;

@end
