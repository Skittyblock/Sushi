#import <UIKit/UIKit.h>
#import "SUNowPlayingBanner.h"

@interface SUNowPlayingViewController : UIViewController

@property (nonatomic, strong) SUNowPlayingBanner *bannerView;

@property (nonatomic, assign) CGFloat bannerOffset;
@property (nonatomic, strong) NSString *currentTitle;
@property (nonatomic, strong) NSString *currentArtist;

@property (nonatomic, strong) NSString *nowPlayingApp;
@property (nonatomic, strong) NSTimer *dismissTimer;
@property (nonatomic, strong) NSDate *lastTouchedDate;

@property (nonatomic, assign) NSInteger location; // 0 = top, 1 = bottom
@property (nonatomic, assign) NSInteger dismissInterval;
@property (nonatomic, assign) BOOL dismissWhenExpanded;
@property (nonatomic, assign) BOOL shouldPlayFeedback;
@property (nonatomic, assign) BOOL playedFeedback;

@property (nonatomic, weak) NSLayoutConstraint *bannerLeadingConstraint;
@property (nonatomic, weak) NSLayoutConstraint *bannerTopConstraint;
@property (nonatomic, weak) NSLayoutConstraint *bannerWidthConstraint;
@property (nonatomic, weak) NSLayoutConstraint *bannerHeightConstraint;

- (void)animateInAfter:(NSTimeInterval)seconds;
- (void)animateIn;
- (void)animateOut;

@end
