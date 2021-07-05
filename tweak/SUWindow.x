#import "SUWindow.h"

%subclass SUWindow : SBSecureWindow
%property (nonatomic, assign) BOOL enabled;

-  (instancetype)initWithScreen:(UIScreen *)screen debugName:(NSString *)name {
	self = %orig;

	if (self) {
		self.hidden = YES;
		self.windowLevel = UIWindowLevelStatusBar + 100.0;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:@"xyz.skitty.sushi.orient" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(show) name:@"xyz.skitty.sushi.shown" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hide) name:@"xyz.skitty.sushi.hidden" object:nil];
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

%new
- (void)hide {
	self.hidden = YES;
}

%new
- (void)show {
	if (self.enabled) self.hidden = NO;
}

%new
- (void)orientationChange:(NSNotification *)notification {
	int orientation = [(NSNumber *)notification.userInfo[@"orientation"] intValue];

	[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		if (orientation < 3) {
			self.transform = CGAffineTransformIdentity;
			self.frame = self.screen.bounds;
		} else {
			self.transform = CGAffineTransformMakeRotation(M_PI_2);
			self.frame = CGRectMake(0, 0, self.screen.bounds.size.height, self.screen.bounds.size.width);
		}
	} completion:nil];
}

%end
