@class SUActiveOrientationManager;

@interface SpringBoard (Sushi)
@property (nonatomic, retain) SUActiveOrientationManager *sushiOrientationManager;
- (void)addActiveOrientationObserver:(id)manager;
@end
