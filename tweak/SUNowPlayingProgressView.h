#import <UIKit/UIKit.h>
#import "SUNowPlayingProgressKnobView.h"

@interface SUNowPlayingProgressView : UIView

@property (nonatomic, assign) double elapsedTime;
@property (nonatomic, assign) double duration;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UIView *elapsedTrack;
@property (nonatomic, strong) UIView *remainingTrack;

@property (nonatomic, strong) SUNowPlayingProgressKnobView *knobView;

@property (nonatomic, strong) UILabel *elapsedLabel;
@property (nonatomic, strong) UILabel *remainingLabel;

@property (nonatomic, strong) NSLayoutConstraint *elapsedTrackWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *knobViewLeadingConstraint;

- (void)startTimer;
- (void)stopTimer;

@end
