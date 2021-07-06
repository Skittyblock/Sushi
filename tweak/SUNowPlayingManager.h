#import <UIKit/UIKit.h>
#import "SBUIActiveOrientationObserver.h"
#import "SUNowPlayingWindow.h"

@interface SUNowPlayingManager : NSObject <SBUIActiveOrientationObserver>

@property (nonatomic, retain) SUNowPlayingWindow *window;
@property (nonatomic, assign) BOOL enabled;

+ (instancetype)sharedManager;
- (void)showWindow;
- (void)hideWindow;

@end
