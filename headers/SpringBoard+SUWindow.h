@class SUWindow, SBApplication;

@interface SpringBoard
@property (nonatomic, retain) SUWindow *sushiWindow;
- (SBApplication *)_accessibilityFrontMostApplication;
@end
