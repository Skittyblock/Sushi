@class SUNowPlayingManager, SBApplication;

@interface SpringBoard
@property (nonatomic, retain) SUNowPlayingManager *sushiManager;
- (void)addActiveOrientationObserver:(id)manager;
- (BOOL)homeScreenSupportsRotation;
- (SBApplication *)_accessibilityFrontMostApplication;
@end
