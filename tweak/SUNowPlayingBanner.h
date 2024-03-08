#import <UIKit/UIKit.h>
#import "SUNowPlayingProgressView.h"
#import "SUNowPlayingControlsView.h"

@interface SUNowPlayingBanner : UIView

@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, assign) BOOL useNotchedLayout;

@property (nonatomic, assign) BOOL blurred;
@property (nonatomic, assign) BOOL matchSystemTheme;
@property (nonatomic, assign) BOOL darkMode;
@property (nonatomic, assign) BOOL oled;
@property (nonatomic, assign) BOOL showBannerArt;
@property (nonatomic, assign) NSInteger blurThickness;
@property (nonatomic, assign) CGFloat tintStrength;

@property (nonatomic, assign) NSString *nowPlayingAppIdentifier;

@property (nonatomic, strong) UIImage *applicationIcon;
@property (nonatomic, strong) UIImage *albumImage;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *artist;

@property (nonatomic, strong) UIVisualEffectView *visualEffectView;
@property (nonatomic, strong) UIView *tintView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIButton *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;

@property (nonatomic, strong) UIImageView *glyphView;
@property (nonatomic, strong) SUNowPlayingProgressView *progressView;
@property (nonatomic, strong) SUNowPlayingControlsView *musicControlsView;

@property (nonatomic, strong) UIImageView *rewindButtonView;
@property (nonatomic, strong) UIImageView *playPauseButtonView;
@property (nonatomic, strong) UIImageView *skipButtonView;

@property (nonatomic, weak) NSLayoutConstraint *iconViewTopConstraint;
@property (nonatomic, weak) NSLayoutConstraint *iconViewLeadingConstraint;
@property (nonatomic, weak) NSLayoutConstraint *iconViewHeightConstraint;
@property (nonatomic, weak) NSLayoutConstraint *iconViewWidthConstraint;

@property (nonatomic, weak) NSLayoutConstraint *titleTopConstraint;
@property (nonatomic, weak) NSLayoutConstraint *titleLeadingConstraint;
@property (nonatomic, weak) NSLayoutConstraint *titleHeightConstraint;
@property (nonatomic, weak) NSLayoutConstraint *titleWidthConstraint;

@property (nonatomic, weak) NSLayoutConstraint *messageTopConstraint;
@property (nonatomic, weak) NSLayoutConstraint *messageLeadingConstraint;
@property (nonatomic, weak) NSLayoutConstraint *messageTrailingConstraint;
@property (nonatomic, weak) NSLayoutConstraint *messageHeightConstraint;
@property (nonatomic, weak) NSLayoutConstraint *messageWidthConstraint;

- (instancetype)initWithNotchedLayout:(BOOL)notchedLayout;
- (void)updateColors;

@end
