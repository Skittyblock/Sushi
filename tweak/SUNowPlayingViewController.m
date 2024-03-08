#import "SUNowPlayingViewController.h"
#import <MediaRemote/MediaRemote.h>
#import "SUNowPlayingManager.h"
#import "SUNowPlayingWindow.h"
#import "UIStatusBar.h"
#import <rootless.h>

#define FEEDBACK_THRESHOLD 20 // drag distance to trigger haptic feedback + expansion

// banner sizes
#define BANNER_WIDTH 350 // maximum width for the banner
#define EXPANDED_WIDTH 338 // width of the expanded view with controls
#define EXPANDED_WIDTH_NOTCHED 350

#define BANNER_HEIGHT 44
#define EXPANDED_HEIGHT 152

// locations
#define TOP 0
#define BOTTOM 1

@implementation SUNowPlayingViewController

- (instancetype)init {
	self = [super init];

	if (self) {
		double statusBarHeight = 0;
		if (@available(iOS 14.0, *)) {
			statusBarHeight = [NSClassFromString(@"UIStatusBar") _heightForStyle:306 orientation:1 forStatusBarFrame:NO inWindow:nil];
			if (statusBarHeight <= 0) statusBarHeight = [NSClassFromString(@"UIStatusBar_Modern") _heightForStyle:1 orientation:1 forStatusBarFrame:NO inWindow:nil];
		} else {
			statusBarHeight = [NSClassFromString(@"UIStatusBar") _heightForStyle:306 orientation:1 forStatusBarFrame:NO];
			if (statusBarHeight <= 0) statusBarHeight = [NSClassFromString(@"UIStatusBar_Modern") _heightForStyle:1 orientation:1 forStatusBarFrame:NO];
		}
		self.bannerInset = statusBarHeight;
		self.bannerOffset = 0;
		self.useNotchedLayout = statusBarHeight > 20;
		self.nowPlayingApp = @"com.apple.Music";

		self.bannerView = [[SUNowPlayingBanner alloc] initWithNotchedLayout:self.useNotchedLayout];
		self.bannerView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.view addSubview:self.bannerView];

		self.location = 0;

		UIPanGestureRecognizer *dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragged:)];
		[dragRecognizer setMinimumNumberOfTouches:1];
		[dragRecognizer setMaximumNumberOfTouches:1];
		[self.bannerView addGestureRecognizer:dragRecognizer];

		self.bannerLeadingConstraint = [self.bannerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
		self.bannerWidthConstraint = [self.bannerView.widthAnchor constraintLessThanOrEqualToConstant:self.useNotchedLayout ? EXPANDED_WIDTH_NOTCHED : EXPANDED_WIDTH];
		self.bannerHeightConstraint = [self.bannerView.heightAnchor constraintEqualToConstant:44];

		[NSLayoutConstraint activateConstraints:@[
			self.bannerLeadingConstraint,
			self.bannerWidthConstraint,
			self.bannerHeightConstraint
		]];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expansionChanged:) name:@"xyz.skitty.sushi.expanded" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendTestBanner) name:@"xyz.skitty.sushi.test" object:nil];
	}

	return self;
}

- (void)nowPlayingUpdate:(NSDictionary *)info {
	self.lastTouchedDate = [NSDate date];

	NSString *title = [info objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
	NSString *artist = [info objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist];
	NSData *artworkData = [info objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
	NSNumber *elapsed = [info objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime];
	NSNumber *duration = [info objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDuration];
	NSNumber *playbackRate = [info objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoPlaybackRate];

	if ([playbackRate isEqual:@(1)]) {
		self.bannerView.musicControlsView.paused = NO;
		[self.bannerView.progressView startTimer];
	} else {
		self.bannerView.musicControlsView.paused = YES;
		[self.bannerView.progressView stopTimer];
	}

	if ([title isEqual:self.currentTitle] && [artist isEqual:self.currentArtist]) {
		if (duration != nil) self.bannerView.progressView.duration = [duration doubleValue];
		if (elapsed != nil) self.bannerView.progressView.elapsedTime = [elapsed doubleValue];
		if (artworkData != nil) self.bannerView.albumImage = [UIImage imageWithData:artworkData];
	} else if (title && artist) {
		self.currentTitle = title;
		self.currentArtist = artist;

		if ([info[@"enabledInApp"] isEqual:@(0)] && info[@"currentApplication"] == self.nowPlayingApp) return;
		if ([(NSArray *)info[@"blacklistedApps"] containsObject:self.nowPlayingApp]) return;
		if ([info[@"locked"] isEqual:@(1)]) return;

		if (self.previousNowPlayingApp) {
			// restore previous app after switching to preferences for testing banner
			self.nowPlayingApp = self.previousNowPlayingApp;
			self.previousNowPlayingApp = nil;
		}
		if (self.testingBanner) {
			self.previousNowPlayingApp = self.nowPlayingApp;
			self.nowPlayingApp = @"com.apple.Preferences";
			self.testingBanner = NO;
		}

		if (!self.bannerView.expanded) {
			[self animateOutWithCompletion:^(BOOL finished) {
				self.bannerView.title = title;
				self.bannerView.artist = artist;
				self.bannerView.nowPlayingAppIdentifier = self.nowPlayingApp;
				self.bannerView.progressView.duration = [duration doubleValue];
				if (elapsed != nil) self.bannerView.progressView.elapsedTime = [elapsed doubleValue];
				if (artworkData != nil) self.bannerView.albumImage = [UIImage imageWithData:artworkData];
				[self animateIn];
			}];
		} else {
			self.bannerView.title = title;
			self.bannerView.artist = artist;
			self.bannerView.nowPlayingAppIdentifier = self.nowPlayingApp;
			self.bannerView.progressView.duration = [duration doubleValue];
			if (elapsed != nil) self.bannerView.progressView.elapsedTime = [elapsed doubleValue];
			if (artworkData != nil) self.bannerView.albumImage = [UIImage imageWithData:artworkData];
		}
	}
}

- (void)tickDismissTimer {
	if (!self.lastTouchedDate) {
		self.lastTouchedDate = [NSDate date];
		return;
	}
	if (self.bannerView.expanded && !self.dismissWhenExpanded) return;
	NSTimeInterval interval = -[self.lastTouchedDate timeIntervalSinceNow];
	if (interval > self.dismissInterval) {
		[self animateOut];
	}
}

- (void)appPlayingUpdate:(NSString *)bundleIdentifier {
	if (bundleIdentifier) {
		self.nowPlayingApp = bundleIdentifier;
	}
}

- (void)animateInAfter:(NSTimeInterval)seconds {
	[self.window.manager showWindow];
	self.bannerView.userInteractionEnabled = YES;

	self.bannerOffset = -(self.bannerInset + self.bannerHeightConstraint.constant);
	[self updateBannerPosition];

	[self.bannerView updateColors];

	[UIView animateWithDuration:0.4 delay:seconds options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.bannerOffset = 0;
		[self updateBannerPosition];
		self.dismissTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tickDismissTimer) userInfo:nil repeats:YES];
	} completion:nil];
}

- (void)animateIn {
	[self animateInAfter:0];
}

- (void)animateOutWithCompletion:(void (^)(BOOL))completion {
	[self.dismissTimer invalidate];
	self.dismissTimer = nil;
	self.lastTouchedDate = nil;
	self.bannerView.userInteractionEnabled = NO;
	[UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.bannerOffset = -(self.bannerInset + self.bannerHeightConstraint.constant);
		[self updateBannerPosition];
	} completion:completion];
}

- (void)animateOut {
	[self animateOutWithCompletion:^(BOOL finished) {
		self.bannerView.expanded = NO;
		self.bannerView.userInteractionEnabled = YES;
		[self.window.manager hideWindow];
	}];
}

- (void)dragged:(UIPanGestureRecognizer *)sender {
	static CGFloat pos;

	CGPoint translatedPoint = [sender translationInView:self.bannerView];
	CGFloat velocity = [sender velocityInView:self.bannerView].y;
	if (self.location == BOTTOM) velocity *= -1;

	CGFloat startPos = self.bannerInset;

	self.lastTouchedDate = [NSDate date];

	if (sender.state == UIGestureRecognizerStateBegan) {
		pos = startPos;
	} else if (sender.state == UIGestureRecognizerStateChanged) {
		CGFloat translatedY = translatedPoint.y;
		if (self.location == BOTTOM) translatedY *= -1;
		CGFloat distance = startPos + self.bannerOffset + translatedY;
		pos += translatedY;
		if (distance > startPos) distance = startPos * (1 + log10(pos/startPos));

		self.bannerOffset = distance - startPos;
		[self updateBannerPosition];
		[sender setTranslation:CGPointZero inView:self.bannerView];

		if (self.bannerOffset > FEEDBACK_THRESHOLD) {
			if (self.shouldPlayFeedback && !self.playedFeedback && !self.bannerView.expanded) {
				UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
				[feedback impactOccurred];
				self.playedFeedback = YES;
			}
		}
	} else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
		self.playedFeedback = NO;
		if (self.bannerOffset < 0 && velocity < 0) {
			return [self animateOut];
		}
		if (self.bannerOffset > FEEDBACK_THRESHOLD && !self.bannerView.expanded) {
			self.bannerView.expanded = YES;
		}
		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
			self.bannerOffset = 0;
			[self updateBannerPosition];
		} completion:nil];
	}
}

- (void)expansionChanged:(NSNotification *)notification {
	self.lastTouchedDate = [NSDate date];
	NSNumber *expanded = notification.userInfo[@"expanded"];
	if ([expanded isEqual:@(YES)]) {
		self.bannerWidthConstraint.active = NO;
		self.bannerWidthConstraint = [self.bannerView.widthAnchor constraintEqualToConstant:self.useNotchedLayout ? EXPANDED_WIDTH_NOTCHED : EXPANDED_WIDTH];
		self.bannerWidthConstraint.active = YES;
		self.bannerHeightConstraint.constant = EXPANDED_HEIGHT;
	} else {
		self.bannerWidthConstraint.active = NO;
		self.bannerWidthConstraint = [self.bannerView.widthAnchor constraintLessThanOrEqualToConstant:BANNER_WIDTH];
		self.bannerWidthConstraint.active = YES;
		self.bannerHeightConstraint.constant = BANNER_HEIGHT;
	}
}

- (void)sendTestBanner {
	NSDictionary *fakeMusicInfo = @{
		@"currentApplication": @"com.apple.Preferences",
		@"locked": @(NO),
		@"enabledInApp": @(YES),
		@"blacklistedApps": @[],
		(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle: @"Title",
		(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist: @"Artist",
		(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData: UIImagePNGRepresentation([UIImage imageWithContentsOfFile:ROOT_PATH_NS(@"/Library/Application Support/Sushi/MusicIcon.png")]),
		(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime: @(0),
		(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDuration: @(0),
		(__bridge NSString *)kMRMediaRemoteNowPlayingInfoPlaybackRate: @(0)
	};
	self.testingBanner = YES;
	self.currentTitle = @"Old Title";
	self.currentArtist = @"Old Artist";
	[self nowPlayingUpdate:fakeMusicInfo];
}

- (void)setNowPlayingApp:(NSString *)nowPlayingApp {
	_nowPlayingApp = nowPlayingApp;
	self.bannerView.nowPlayingAppIdentifier = nowPlayingApp;
}

- (void)setLocation:(NSInteger)location {
	_location = location;
	if (self.bannerTopConstraint) {
		self.bannerTopConstraint.active = NO;
	}
	if (location == TOP) {
		self.bannerTopConstraint = [self.bannerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.bannerInset];
	} else {
		self.bannerTopConstraint = [self.bannerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-self.bannerInset];
	}
	self.bannerTopConstraint.active = YES;
	[self updateBannerPosition];
}

- (void)updateBannerPosition {
	if (self.bannerTopConstraint) {
		CGFloat constant = self.bannerInset + self.bannerOffset;
		if (self.location == BOTTOM) constant *= -1;
		self.bannerTopConstraint.constant = constant;
		[self.view layoutIfNeeded];
	}
}

@end
