#import "SUNowPlayingProgressKnobView.h"

@implementation SUNowPlayingProgressKnobView

- (instancetype)init {
	self = [super init];

	if (self) {
		self.knob = [[UIView alloc] init];
		self.knob.backgroundColor = [UIColor blackColor];
		self.knob.layer.cornerRadius = 3.5;
		self.knob.layer.shadowColor = [UIColor blackColor].CGColor;
		self.knob.layer.shadowOpacity = 0.15;
		self.knob.layer.shadowRadius = 3;
		self.knob.layer.shadowOffset = CGSizeMake(0, 1);
		self.knob.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.knob];

		self.hitbox = [[UIView alloc] init];
		self.hitbox.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.hitbox];

		[self.hitbox.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
		[self.hitbox.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
		[self.hitbox.widthAnchor constraintEqualToConstant:13].active = YES;
		[self.hitbox.heightAnchor constraintEqualToConstant:13].active = YES;

		[self.knob.centerXAnchor constraintEqualToAnchor:self.hitbox.centerXAnchor].active = YES;
		[self.knob.centerYAnchor constraintEqualToAnchor:self.hitbox.centerYAnchor].active = YES;
		[self.knob.widthAnchor constraintEqualToConstant:7].active = YES;
		[self.knob.heightAnchor constraintEqualToConstant:7].active = YES;
	}

	return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.transform = CGAffineTransformMakeScale(3, 3);
	} completion:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.transform = CGAffineTransformMakeScale(1, 1);
	} completion:nil];
}

@end
