#import "SUNowPlayingBanner.h"
#import "SBApplication.h"
#import "UIApplication+Private.h"
#import "UIImage+Private.h"
#import "UIImage+ColorArt.h"
#import "UIColor+SushiColors.h"
#import <rootless.h>

#define CORNER_RADIUS 10
#define EXPANDED_RADIUS 12
#define NOTCHED_EXPANDED_RADIUS 18

#define SHADOW_OPACITY 0.15
#define DARK_SHADOW_OPACITY 0.4

@implementation SUNowPlayingBanner

- (instancetype)initWithNotchedLayout:(BOOL)notchedLayout {
	self = [super init];

	if (self) {
		self.expanded = NO;
		self.useNotchedLayout = notchedLayout;
		self.layer.cornerRadius = CORNER_RADIUS;
		self.layer.cornerCurve = kCACornerCurveContinuous;
		self.layer.shadowColor = [UIColor blackColor].CGColor;
		self.layer.shadowOpacity = SHADOW_OPACITY;
		self.layer.shadowRadius = 10;
		self.layer.shadowOffset = CGSizeMake(0, 5);

		// Content view (for bounds clipping)
		self.contentView = [[UIView alloc] init];
		self.contentView.layer.cornerRadius = self.layer.cornerRadius;
		self.contentView.layer.cornerCurve = kCACornerCurveContinuous;
		self.contentView.clipsToBounds = YES;
		self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.contentView];

		self.tintView = [[UIView alloc] init];
		self.tintView.alpha = 0;
		self.tintView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:self.tintView];

		// Blur background
		self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
		self.visualEffectView.hidden = YES;
		self.visualEffectView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:self.visualEffectView];

		// Now playing app icon / album art
		self.iconView = [UIButton buttonWithType:UIButtonTypeCustom];
		[self.iconView addTarget:self action:@selector(openNowPlayingApp) forControlEvents:UIControlEventTouchUpInside];
		self.iconView.imageView.contentMode = UIViewContentModeScaleAspectFit;
		self.iconView.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
		self.iconView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
		self.iconView.layer.cornerRadius = 5.6;
		self.iconView.layer.masksToBounds = YES;
		self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:self.iconView];

		// Song title label
		self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(43, 13, 64, 18)];
		self.titleLabel.font = [UIFont boldSystemFontOfSize:15];
		self.titleLabel.textColor = [UIColor labelColor];
		self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:self.titleLabel];

		// Song artist label
		self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(112, 13, 119, 18)];
		self.messageLabel.font = [UIFont systemFontOfSize:15];
		self.messageLabel.textColor = [UIColor sushiSecondaryLabelColor];
		self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:self.messageLabel];

		// Music note glyph
		self.glyphView = [[UIImageView alloc] init];
		self.glyphView.image = [[UIImage imageWithContentsOfFile:ROOT_PATH_NS(@"/Library/Application Support/Sushi/MusicGlyph.png")] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		self.glyphView.tintColor = [UIColor sushiSecondaryLabelColor];
		self.glyphView.alpha = 0;
		self.glyphView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:self.glyphView];

		// Song progress track
		self.progressView = [[SUNowPlayingProgressView alloc] init];
		self.progressView.alpha = 0;
		self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:self.progressView];

		// Play/pause, skip, and rewind buttons
		self.musicControlsView = [[SUNowPlayingControlsView alloc] init];
		self.musicControlsView.alpha = 0;
		self.musicControlsView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:self.musicControlsView];

		[self activateConstraints];
	}

	return self;
}

- (void)activateConstraints {
	self.iconViewTopConstraint = [self.iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
	self.iconViewLeadingConstraint = [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10];
	self.iconViewWidthConstraint = [self.iconView.widthAnchor constraintEqualToConstant:24];
	self.iconViewHeightConstraint = [self.iconView.heightAnchor constraintEqualToConstant:24];

	self.titleTopConstraint = [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
	self.titleLeadingConstraint = [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:43];
	self.titleWidthConstraint = [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.messageLabel.leadingAnchor constant:-5];
	self.titleHeightConstraint = [self.titleLabel.heightAnchor constraintEqualToConstant:18];
	[self.titleLabel.widthAnchor constraintLessThanOrEqualToConstant:172].active = YES;

	self.messageTopConstraint = [self.messageLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
	self.messageTrailingConstraint = [self.messageLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10];
	self.messageWidthConstraint = [self.messageLabel.widthAnchor constraintLessThanOrEqualToConstant:121];
	self.messageHeightConstraint = [self.messageLabel.heightAnchor constraintEqualToConstant:18];

	[NSLayoutConstraint activateConstraints:@[
		[self.tintView.widthAnchor constraintEqualToAnchor:self.widthAnchor],
		[self.tintView.heightAnchor constraintEqualToAnchor:self.heightAnchor],

		[self.visualEffectView.widthAnchor constraintEqualToAnchor:self.widthAnchor],
		[self.visualEffectView.heightAnchor constraintEqualToAnchor:self.heightAnchor],

		[self.contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
		[self.contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
		[self.contentView.heightAnchor constraintEqualToAnchor:self.heightAnchor],
		[self.contentView.widthAnchor constraintEqualToAnchor:self.widthAnchor],

		[self.glyphView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-23],
		[self.glyphView.topAnchor constraintEqualToAnchor:self.topAnchor constant:21],
		[self.glyphView.widthAnchor constraintEqualToConstant:17],
		[self.glyphView.heightAnchor constraintEqualToConstant:19],

		[self.progressView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
		[self.progressView.topAnchor constraintEqualToAnchor:self.topAnchor constant:77],
		[self.progressView.widthAnchor constraintEqualToConstant:312],
		[self.progressView.heightAnchor constraintEqualToConstant:31],

		[self.musicControlsView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
		[self.musicControlsView.topAnchor constraintEqualToAnchor:self.topAnchor constant:106],
		[self.musicControlsView.widthAnchor constraintEqualToConstant:180],
		[self.musicControlsView.heightAnchor constraintEqualToConstant:28],

		self.iconViewTopConstraint,
		self.iconViewLeadingConstraint,
		self.iconViewWidthConstraint,
		self.iconViewHeightConstraint,
		self.titleTopConstraint,
		self.titleLeadingConstraint,
		self.titleWidthConstraint,
		self.titleHeightConstraint,
		self.messageTopConstraint,
		self.messageTrailingConstraint,
		self.messageWidthConstraint,
		self.messageHeightConstraint,
	]];
}

- (UIBlurEffectStyle)getBlurStyleWithAppearance:(NSInteger)appearance thickness:(NSInteger)thickness {
	switch (appearance) {
		case 0:
			switch (thickness) {
				case 0: return UIBlurEffectStyleSystemThinMaterial;
				case 1: return UIBlurEffectStyleSystemMaterial;
				case 2: return UIBlurEffectStyleSystemThickMaterial;
			}
			break;
		case 1:
			switch (thickness) {
				case 0: return UIBlurEffectStyleSystemThinMaterialDark;
				case 1: return UIBlurEffectStyleSystemMaterialDark;
				case 2: return UIBlurEffectStyleSystemThickMaterialDark;
			}
			break;
		case 2:
			switch (thickness) {
				case 0: return UIBlurEffectStyleSystemThinMaterialLight;
				case 1: return UIBlurEffectStyleSystemMaterialLight;
				case 2: return UIBlurEffectStyleSystemThickMaterialLight;
			}
			break;
	}
	return UIBlurEffectStyleSystemMaterial;
}

- (void)updateColors {
	if (!self.blurred) self.visualEffectView.hidden = YES;
	else {
		self.visualEffectView.hidden = NO;
		self.backgroundColor = [UIColor clearColor];
	}

	if (self.darkMode && self.matchSystemTheme) {
		if (self.oled && !self.blurred) self.backgroundColor = [UIColor systemBackgroundColor];
		else if (!self.blurred) self.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
		else if (self.blurred) self.visualEffectView.effect = [UIBlurEffect effectWithStyle:[self getBlurStyleWithAppearance:0 thickness:self.blurThickness]];
		self.titleLabel.textColor = [UIColor labelColor];
		self.messageLabel.textColor = [UIColor sushiSecondaryLabelColor];
		self.glyphView.tintColor = [UIColor sushiSecondaryLabelColor];
		self.musicControlsView.previousButton.tintColor = [UIColor labelColor];
		self.musicControlsView.playPauseButton.tintColor = [UIColor labelColor];
		self.musicControlsView.nextButton.tintColor = [UIColor labelColor];
		self.progressView.elapsedTrack.backgroundColor = [UIColor labelColor];
		self.progressView.remainingTrack.backgroundColor = [UIColor sushiSecondaryLabelColor];
		self.progressView.knobView.knob.backgroundColor = [UIColor labelColor];
		self.progressView.elapsedLabel.textColor = [UIColor labelColor];
		self.progressView.remainingLabel.textColor = [UIColor sushiSecondaryLabelColor];
		if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			self.layer.shadowOpacity = DARK_SHADOW_OPACITY;
		} else {
			self.layer.shadowOpacity = SHADOW_OPACITY;
		}
	} else if (self.darkMode) {
		if (self.oled && !self.blurred) self.backgroundColor = [UIColor blackColor];
		else if (!self.blurred) self.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1];
		else if (self.blurred) self.visualEffectView.effect = [UIBlurEffect effectWithStyle:[self getBlurStyleWithAppearance:1 thickness:self.blurThickness]];
		self.titleLabel.textColor = [UIColor whiteColor];
		self.messageLabel.textColor = [UIColor darkSushiSecondaryLabelColor];
		self.glyphView.tintColor = [UIColor darkSushiSecondaryLabelColor];
		self.musicControlsView.previousButton.tintColor = [UIColor whiteColor];
		self.musicControlsView.playPauseButton.tintColor = [UIColor whiteColor];
		self.musicControlsView.nextButton.tintColor = [UIColor whiteColor];
		self.progressView.elapsedTrack.backgroundColor = [UIColor whiteColor];
		self.progressView.remainingTrack.backgroundColor = [UIColor darkSushiSecondaryLabelColor];
		self.progressView.knobView.knob.backgroundColor = [UIColor whiteColor];
		self.progressView.elapsedLabel.textColor = [UIColor whiteColor];
		self.progressView.remainingLabel.textColor = [UIColor darkSushiSecondaryLabelColor];
		self.layer.shadowOpacity = DARK_SHADOW_OPACITY;
	} else {
		if (!self.blurred) self.backgroundColor = [UIColor whiteColor];
		else if (self.blurred) self.visualEffectView.effect = [UIBlurEffect effectWithStyle:[self getBlurStyleWithAppearance:2 thickness:self.blurThickness]];
		self.titleLabel.textColor = [UIColor blackColor];
		self.messageLabel.textColor = [UIColor lightSushiSecondaryLabelColor];
		self.glyphView.tintColor = [UIColor lightSushiSecondaryLabelColor];
		self.musicControlsView.previousButton.tintColor = [UIColor blackColor];
		self.musicControlsView.playPauseButton.tintColor = [UIColor blackColor];
		self.musicControlsView.nextButton.tintColor = [UIColor blackColor];
		self.progressView.elapsedTrack.backgroundColor = [UIColor blackColor];
		self.progressView.remainingTrack.backgroundColor = [UIColor lightSushiSecondaryLabelColor];
		self.progressView.knobView.knob.backgroundColor = [UIColor blackColor];
		self.progressView.elapsedLabel.textColor = [UIColor blackColor];
		self.progressView.remainingLabel.textColor = [UIColor lightSushiSecondaryLabelColor];
		self.layer.shadowOpacity = SHADOW_OPACITY;
	}
}

- (void)openNowPlayingApp {
	if (self.nowPlayingAppIdentifier) {
		[[UIApplication sharedApplication] launchApplicationWithIdentifier:self.nowPlayingAppIdentifier suspended:NO];
	}
}

- (void)setExpanded:(BOOL)expanded {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"xyz.skitty.sushi.expanded" object:nil userInfo:@{ @"expanded": [NSNumber numberWithBool:expanded] }];
	if (!_expanded && expanded) { // Expand view into media player
		if (!self.showBannerArt) {
			[UIView transitionWithView:self.iconView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
				[self.iconView setImage:self.albumImage forState:UIControlStateNormal];
			} completion:nil];
		}
		
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			self.transform = CGAffineTransformMakeScale(1, 1);
			self.layer.cornerRadius = self.useNotchedLayout ? NOTCHED_EXPANDED_RADIUS : EXPANDED_RADIUS;
			self.contentView.layer.cornerRadius = self.layer.cornerRadius;

			self.iconView.layer.cornerRadius = 5;
			self.messageLabel.text = self.artist;

			self.glyphView.alpha = 1;
			self.progressView.alpha = 1;
			self.musicControlsView.alpha = 1;

			self.iconViewTopConstraint.active = NO;
			self.iconViewTopConstraint = [self.iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:19];
			self.iconViewTopConstraint.active = YES;
			self.iconViewLeadingConstraint.constant = 19;
			self.iconViewWidthConstraint.constant = 55;
			self.iconViewHeightConstraint.constant = 55;
			
			self.titleTopConstraint.active = NO;
			self.titleTopConstraint = [self.titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:27];
			self.titleTopConstraint.active = YES;
			self.titleLeadingConstraint.constant = 88;
			self.titleWidthConstraint.active = NO;
			self.titleWidthConstraint = [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-46];
			self.titleWidthConstraint.active = YES;
			
			self.messageTopConstraint.active = NO;
			self.messageTopConstraint = [self.messageLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:47];
			self.messageTopConstraint.active = YES;
			self.messageWidthConstraint.active = NO;
			self.messageWidthConstraint = [self.messageLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:88];
			self.messageWidthConstraint.active = YES;
			self.messageTrailingConstraint.constant = -20;

			[self layoutIfNeeded];
			[self.superview layoutIfNeeded];
		} completion:nil];
	} else if (_expanded && !expanded) { // Contract view into banner
		if (!self.showBannerArt) {
			[UIView transitionWithView:self.iconView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
				[self.iconView setImage:self.applicationIcon forState:UIControlStateNormal];
			} completion:nil];
		}
		
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			self.transform = CGAffineTransformMakeScale(1, 1);
			self.layer.cornerRadius = CORNER_RADIUS;
			self.contentView.layer.cornerRadius = self.layer.cornerRadius;

			self.iconView.layer.cornerRadius = 5.6;
			self.messageLabel.text = [NSString stringWithFormat:@"by %@", self.artist];

			self.glyphView.alpha = 0;
			self.progressView.alpha = 0;
			self.musicControlsView.alpha = 0;

			self.iconViewTopConstraint.active = NO;
			self.iconViewTopConstraint = [self.iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
			self.iconViewTopConstraint.active = YES;
			self.iconViewLeadingConstraint.constant = 10;
			self.iconViewWidthConstraint.constant = 24;
			self.iconViewHeightConstraint.constant = 24;

			self.titleTopConstraint.active = NO;
			self.titleTopConstraint = [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
			self.titleTopConstraint.active = YES;
			self.titleLeadingConstraint.constant = 43;
			self.titleWidthConstraint.active = NO;
			self.titleWidthConstraint = [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.messageLabel.leadingAnchor constant:-5];
			self.titleWidthConstraint.active = YES;

			self.messageTopConstraint.active = NO;
			self.messageTopConstraint = [self.messageLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
			self.messageTopConstraint.active = YES;
			self.messageWidthConstraint.active = NO;
			self.messageWidthConstraint = [self.messageLabel.widthAnchor constraintLessThanOrEqualToConstant:121];
			self.messageWidthConstraint.active = YES;
			self.messageTrailingConstraint.constant = -10;

			[self layoutIfNeeded];
			[self.superview layoutIfNeeded];
		} completion:nil];
	}
	_expanded = expanded;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.transform = CGAffineTransformMakeScale(0.95, 0.95);
	} completion:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	self.expanded = !self.expanded;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.transform = CGAffineTransformMakeScale(1, 1);
	} completion:nil];
}

- (void)setTintStrength:(CGFloat)tintStrength {
	_tintStrength = tintStrength;
	self.tintView.alpha = tintStrength;
}

- (void)setNowPlayingAppIdentifier:(NSString *)identifier {
	_nowPlayingAppIdentifier = identifier;
	self.applicationIcon = [UIImage _applicationIconImageForBundleIdentifier:identifier format:2];
}

- (void)setApplicationIcon:(UIImage *)icon {
	_applicationIcon = icon;
	if (!self.expanded && !self.showBannerArt) [self.iconView setImage:icon forState:UIControlStateNormal];
}

- (void)setAlbumImage:(UIImage *)image {
	_albumImage = image;
	self.tintView.backgroundColor = [image backgroundColor];
	if (self.expanded || self.showBannerArt) [self.iconView setImage:image forState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title {
	_title = title;
	self.titleLabel.text = title;
}

- (void)setArtist:(NSString *)artist {
	_artist = artist;
	if (!self.expanded) self.messageLabel.text = [NSString stringWithFormat:@"by %@", artist];
	else self.messageLabel.text = artist;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	if (self.darkMode && self.matchSystemTheme) {
		if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			self.layer.shadowOpacity = DARK_SHADOW_OPACITY;
		} else {
			self.layer.shadowOpacity = SHADOW_OPACITY;
		}
	}
}

@end
