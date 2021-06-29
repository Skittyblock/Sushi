#import <UIKit/UIKit.h>
#import "SUMusicControlButton.h"

@interface SUNowPlayingControlsView : UIView

@property (nonatomic, assign) BOOL paused;

@property (nonatomic, strong) SUMusicControlButton *previousButton;
@property (nonatomic, strong) SUMusicControlButton *playPauseButton;
@property (nonatomic, strong) SUMusicControlButton *nextButton;

@property (nonatomic, strong) NSTimer *heldTimer;
@property (nonatomic, strong) NSDate *heldDownDate;

@end
