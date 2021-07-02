#import "SUSettingsController.h"

CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

@implementation SUSettingsController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.iconView.image = [UIImage imageWithContentsOfFile:[[self resourceBundle] pathForResource:@"logo" ofType:@"png"]];
	self.iconView.transform = CGAffineTransformMakeScale(0.8, 0.8);
}

- (void)testBanner {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (CFStringRef)@"xyz.skitty.sushi.test", nil, nil, true);
}

@end
