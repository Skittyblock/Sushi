#import "SUMusicControlButton.h"

@implementation SUMusicControlButton

+ (instancetype)buttonWithType:(UIButtonType)type {
	SUMusicControlButton *button = [super buttonWithType:type];

	if (button) {
		button.imageView.contentMode = UIViewContentModeScaleAspectFit;
		button.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
	}

	return button;
}

- (void)setIcon:(UIImage *)icon {
	_icon = icon;
	[self setImage:icon forState:UIControlStateNormal];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.transform = CGAffineTransformMakeScale(0.8, 0.8);
	} completion:nil];

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.transform = CGAffineTransformMakeScale(1, 1);
	} completion:nil];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.transform = CGAffineTransformMakeScale(1, 1);
	} completion:nil];
}

@end
