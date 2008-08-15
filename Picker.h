/*

File: Picker.h
Abstract: 
 A view that displays both the currently advertised game name and a list of
other games
 available on the local network (discovered & displayed by
BrowserViewController).
 
*/

#import <UIKit/UIKit.h>
#import "BrowserViewController.h"

@interface Picker : UIView {

@private
	UILabel* _gameNameLabel;
	BrowserViewController* _bvc;
}

@property (nonatomic, assign) id<BrowserViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString* gameName;

- (id)initWithFrame:(CGRect)frame type:(NSString *)type;

@end
