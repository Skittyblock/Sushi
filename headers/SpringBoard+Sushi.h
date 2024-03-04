@class SUNowPlayingManager, SBApplication;

@interface SpringBoard : UIApplication
@property (nonatomic, retain) SUNowPlayingManager *sushiManager;
- (void)addActiveOrientationObserver:(id)manager;
- (BOOL)homeScreenSupportsRotation;
- (SBApplication *)_accessibilityFrontMostApplication;
@end
