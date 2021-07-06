#import "SUNowPlayingManager.h"

@implementation SUNowPlayingManager

+ (instancetype)sharedManager {
    static SUNowPlayingManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void)hideWindow {
	self.window.hidden = YES;
}

- (void)showWindow {
	if (self.enabled) self.window.hidden = NO;
}

- (void)setWindow:(SUNowPlayingWindow *)window {
	_window = window;
	self.window.manager = self;
	[self.window orientationDidChangeToOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void)activeInterfaceOrientationWillChangeToOrientation:(UIInterfaceOrientation)orientation {}

- (void)activeInterfaceOrientationDidChangeToOrientation:(UIInterfaceOrientation)orientation willAnimateWithDuration:(NSTimeInterval)duration fromOrientation:(UIInterfaceOrientation)previousOrientation {
	[self.window orientationDidChangeToOrientation:orientation];
}

@end
