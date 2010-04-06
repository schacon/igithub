//
//  ServerViewController.h
//  iGitHub
//
//  Created by Scott Chacon on 9/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ServerViewController : UIViewController {
	UILabel* serverNameLabel;
}

@property (nonatomic, retain) UILabel* serverNameLabel;

- (void)setServerName:(NSString *)string;

@end
