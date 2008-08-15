/*

File: TapView.m
Abstract: UIView subclass that can highlight itself when locally or remotely
tapped.

Version: 1.5

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import "AppController.h"

//CONSTANTS:

#define kActivationInset	10

//CLASS IMPLEMENTATIONS:

@implementation TapView

- (void) touchDown:(BOOL)remote
{
	//Set "tap down" visual state if necessary
	if(!localTouch && !remoteTouch)
		self.frame=CGRectInset(self.frame, kActivationInset, kActivationInset);
	
	if (remote)
		remoteTouch = YES;
	else
		localTouch = YES;
}

- (void) touchUp:(BOOL)remote
{
	BOOL wasDown = localTouch || remoteTouch;
	
	if (remote)
		remoteTouch = NO;
	else
		localTouch = NO;
	
	BOOL isDown = localTouch || remoteTouch;

	//Run "tap up" visual animation if necessary
	if(wasDown != isDown) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.1];
		self.frame = CGRectInset(self.frame, -kActivationInset, -kActivationInset);
		[UIView commitAnimations];
	}
}

- (void) localTouchUp
{
	[self touchUp:NO];
	[(AppController*)[[UIApplication sharedApplication] delegate] deactivateView:self];
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self touchDown:NO];
	[(AppController*)[[UIApplication sharedApplication] delegate] activateView:self];
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self localTouchUp];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self localTouchUp];
}

@end
