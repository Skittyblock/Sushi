#import "SUNowPlayingWindow.h"
#import "SUNowPlayingManager.h"
#import "SUNowPlayingViewController.h"

%subclass SUNowPlayingWindow : SBSecureWindow
%property (nonatomic, retain) SUNowPlayingManager *manager;
%property (nonatomic, assign) BOOL hsRotation;

-  (instancetype)initWithScreen:(UIScreen *)screen debugName:(NSString *)name {
	self = %orig;

	if (self) {
		self.hidden = YES;
		self.windowLevel = UIWindowLevelStatusBar + 100.0;
	}

	return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *view = %orig;

	if (view != self.rootViewController.view) return view;

	return nil;
}

- (BOOL)_shouldControlAutorotation {
    return NO;
}

- (void)setRootViewController:(UIViewController *)viewController {
	%orig;
	self.rootViewController.window = self;
}

%new
- (void)orientationDidChangeToOrientation:(UIInterfaceOrientation)orientation {
	[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		switch (orientation) {
			case UIInterfaceOrientationPortrait:
				if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
					self.transform = CGAffineTransformMakeRotation(-M_PI_2);
					self.frame = CGRectMake(0, 0, self.screen.bounds.size.height, self.screen.bounds.size.width);
				} else {
					self.transform = CGAffineTransformIdentity;
					self.frame = self.screen.bounds;
				}
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
					self.transform = CGAffineTransformMakeRotation(M_PI_2);
					self.frame = CGRectMake(0, 0, self.screen.bounds.size.height, self.screen.bounds.size.width);
				} else {
					self.transform = CGAffineTransformMakeRotation(M_PI);
					self.frame = self.screen.bounds;
				}
				break;
			case UIInterfaceOrientationLandscapeLeft:
				if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
					self.transform = CGAffineTransformMakeRotation(M_PI);
					self.frame = self.screen.bounds;
				} else {
					self.transform = CGAffineTransformMakeRotation(-M_PI_2);
					self.frame = CGRectMake(0, 0, self.screen.bounds.size.height, self.screen.bounds.size.width);
				}
				break;
			case UIInterfaceOrientationLandscapeRight:
				if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
					self.transform = CGAffineTransformIdentity;
					self.frame = self.screen.bounds;
				} else {
					self.transform = CGAffineTransformMakeRotation(M_PI_2);
					self.frame = CGRectMake(0, 0, self.screen.bounds.size.height, self.screen.bounds.size.width);
				}
				break;
			default:
				break;
		}
	} completion:nil];
}

%end
