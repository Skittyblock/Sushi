#import "SUSettingsController.h"

CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

@implementation SUSettingsController

- (void)testBanner {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (CFStringRef)@"xyz.skitty.sushi.test", nil, nil, true);
}

@end
