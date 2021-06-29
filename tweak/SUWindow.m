#import "SUWindow.h"

@implementation SUWindow

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	if (self) {
		self.hidden = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(show) name:@"xyz.skitty.sushi.shown" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hide) name:@"xyz.skitty.sushi.hidden" object:nil];
	}

	return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *view = [super hitTest:point withEvent:event];

	if (view != self.rootViewController.view) return view;

	return nil;
}

- (void)hide {
	self.hidden = YES;
}

- (void)show {
	if (self.enabled) self.hidden = NO;
}

- (void)setEnabled:(BOOL)enabled {
	_enabled = enabled;
	if (!enabled) self.hidden = YES;
}

@end
