#import <UIKit/UIKit.h>

@interface SUNowPlayingProgressView : UIView

@property (nonatomic, assign) double elapsedTime;
@property (nonatomic, assign) double duration;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UIView *elapsedTrack;
@property (nonatomic, strong) UIView *remainingTrack;

@property (nonatomic, strong) UILabel *elapsedLabel;
@property (nonatomic, strong) UILabel *remainingLabel;

- (void)startTimer;
- (void)stopTimer;

@end
