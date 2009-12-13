//
//  GITUser.h
//  CocoaGit
//
//  Created by Geoffrey Garside on 01/07/2008.
//  Copyright 2008 ManicPanda.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! A git user.
 * The actor class encapsulates the name and email pair for a user
 * of git. The actor can be thought of as similar to the
 * \code
 * git config user.name
 * git config user.email\endcode
 * configuration settings.
 *
 * \see GITCommit
 * \see GITTag
 * \internal
 * Presently only used by Tag and Commit objects.
 */
@interface GITActor : NSObject <NSCopying> {
    NSString * name;    //!< Name of the actor
    NSString * email;   //!< Email address of the actor
}

@property(readonly,copy) NSString * name;
@property(readonly,copy) NSString * email;

+ (id) actorWithName:(NSString *)theName;
+ (id) actorWithName:(NSString *)theName email:(NSString *)theEmail;
+ (id) actorWithString:(NSString *)raw;

/*! Creates and returns an actor object with the provided name.
 * The created actor object will have an email address of <tt>nil</tt>.
 * \param theName The name of the actor to create.
 * \return An actor object with the provided name.
 */
- (id)initWithName:(NSString*)theName;

/*! Creates and returns an actor object with the provided name and email.
 * \param theName The name of the actor.
 * \param theEmail The email address of the actor.
 * \return An actor object with the provided name and email.
 */
- (id)initWithName:(NSString*)theName email:(NSString*)theEmail;

/*! Creates and returns an actor object by parsing the name and email from
 *  a string contained in a GITCommit header (author or committer) line.
 *  This method expects pre-processed input of the form: "[name] <[email]".
 *  example: "E. L. Gato <elgato@catz.com"
 *    where name and email are separated by the string " <"
 * \param commitString A preprocessed string of the form "[name] <[email]"
 * \return An actor object with the extracted name and email.
 */
- (id) initWithString:(NSString *)commitString;


@end