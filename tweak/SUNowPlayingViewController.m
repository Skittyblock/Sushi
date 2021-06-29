#import "SUNowPlayingViewController.h"
#import <MediaRemote/MediaRemote.h>
#import "UIImage+Private.h"
#import "UIStatusBar.h"

@implementation SUNowPlayingViewController

- (instancetype)init {
	self = [super init];

	if (self) {
		self.location = 0;

		double statusBarHeight = 0;
		if (@available(iOS 14.0, *)) {
			statusBarHeight = [NSClassFromString(@"UIStatusBar") _heightForStyle:306 orientation:1 forStatusBarFrame:NO inWindow:nil];
			if (statusBarHeight <= 0) statusBarHeight = [NSClassFromString(@"UIStatusBar_Modern") _heightForStyle:1 orientation:1 forStatusBarFrame:NO inWindow:nil];
		} else {
			statusBarHeight = [NSClassFromString(@"UIStatusBar") _heightForStyle:306 orientation:1 forStatusBarFrame:NO];
			if (statusBarHeight <= 0) statusBarHeight = [NSClassFromString(@"UIStatusBar_Modern") _heightForStyle:1 orientation:1 forStatusBarFrame:NO];
		}
		self.bannerOffset = statusBarHeight;

		self.bannerView = [[SUNowPlayingBanner alloc] init];
		self.bannerView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.view addSubview:self.bannerView];

		CGFloat offset = -(self.bannerOffset+self.bannerHeightConstraint.constant/2);
		[self.bannerView setCenter:CGPointMake(self.bannerView.center.x, self.location == 0 ? offset : [UIScreen mainScreen].bounds.size.height - offset)];

		self.bannerView.applicationIcon = [UIImage _applicationIconImageForBundleIdentifier:@"com.apple.Music" format:2];

		UIPanGestureRecognizer *dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragged:)];
		[dragRecognizer setMinimumNumberOfTouches:1];
		[dragRecognizer setMaximumNumberOfTouches:1];
		[self.bannerView addGestureRecognizer:dragRecognizer];

		self.bannerLeadingConstraint = [self.bannerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
		if (self.location == 0) self.bannerTopConstraint = [self.bannerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.bannerOffset];
		else self.bannerTopConstraint = [self.bannerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-self.bannerOffset];
		self.bannerWidthConstraint = [self.bannerView.widthAnchor constraintLessThanOrEqualToConstant:350];
		self.bannerHeightConstraint = [self.bannerView.heightAnchor constraintEqualToConstant:44];

		self.bannerLeadingConstraint.active = YES;
		self.bannerTopConstraint.active = YES;
		self.bannerWidthConstraint.active = YES;
		self.bannerHeightConstraint.active = YES;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingUpdate:) name:@"xyz.skitty.sushi.songchange" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appPlayingUpdate:) name:@"xyz.skitty.sushi.appchange" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expansionChanged:) name:@"xyz.skitty.sushi.expanded" object:nil];
	}

	return self;
}

- (void)nowPlayingUpdate:(NSNotification *)notification {
	self.lastTouchedDate = [NSDate date];

	NSString *title = [notification.userInfo objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
	NSString *artist = [notification.userInfo objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist];
	NSData *artworkData = [notification.userInfo objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
	NSNumber *elapsed = [notification.userInfo objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime];
	NSNumber *duration = [notification.userInfo objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDuration];
	NSNumber *playbackRate = [notification.userInfo objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoPlaybackRate];

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

		if ([notification.userInfo[@"enabledInApp"] isEqual:@(0)] && notification.userInfo[@"currentApplication"] == self.nowPlayingApp) return;
		if ([(NSArray *)notification.userInfo[@"blacklistedApps"] containsObject:self.nowPlayingApp]) return;
		if ([notification.userInfo[@"locked"] isEqual:@(1)]) return;
		
		if (!self.bannerView.expanded) {
			[self animateOutWithCompletion:^(BOOL finished) {
				self.bannerView.title = title;
				self.bannerView.artist = artist;
				self.bannerView.progressView.duration = [duration doubleValue];
				if (elapsed != nil) self.bannerView.progressView.elapsedTime = [elapsed doubleValue];
				if (artworkData != nil) self.bannerView.albumImage = [UIImage imageWithData:artworkData];
				[self animateIn];
			}];
		} else {
			self.bannerView.title = title;
			self.bannerView.artist = artist;
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

- (void)appPlayingUpdate:(NSNotification *)notification {
	NSString *bundleIdentifier = notification.userInfo[@"id"];
	if (bundleIdentifier) {
		self.bannerView.applicationIcon = [UIImage _applicationIconImageForBundleIdentifier:bundleIdentifier format:2];
		self.nowPlayingApp = bundleIdentifier;
	}
}

- (void)animateInAfter:(NSTimeInterval)seconds {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"xyz.skitty.sushi.shown" object:nil userInfo:nil];
	self.bannerView.transform = CGAffineTransformIdentity;
	CGFloat offset = -(self.bannerOffset + self.bannerHeightConstraint.constant / 2);
	if (self.location == 1) offset = [UIScreen mainScreen].bounds.size.height - offset;
	[self.bannerView setCenter:CGPointMake(self.bannerView.center.x, offset)];
	self.bannerView.userInteractionEnabled = YES;

	[self.bannerView updateColors];

	[UIView animateWithDuration:0.4 delay:seconds options:UIViewAnimationOptionCurveEaseOut animations:^{
		CGFloat offset = self.bannerOffset + self.bannerHeightConstraint.constant / 2;
		if (self.location == 1) offset = [UIScreen mainScreen].bounds.size.height - offset;
		[self.bannerView setCenter:CGPointMake(self.bannerView.center.x, offset)];
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
	[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		CGFloat offset = -(self.bannerOffset + self.bannerHeightConstraint.constant / 2) * 2;
		if (self.location == 1) offset *= -1;
		self.bannerView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, offset);
	} completion:completion];
}

- (void)animateOut {
	[self animateOutWithCompletion:^(BOOL finished) {
		self.bannerView.expanded = NO;
		self.bannerView.userInteractionEnabled = YES;
		self.bannerView.transform = CGAffineTransformIdentity;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"xyz.skitty.sushi.hidden" object:nil userInfo:nil];
	}];
}

- (void)dragged:(UIPanGestureRecognizer *)sender {
	static CGFloat pos;
	static CGFloat fakePos;

	CGPoint translatedPoint = [sender translationInView:self.bannerView];
	CGFloat velocity = [sender velocityInView:self.bannerView].y;

	CGFloat startPos = self.bannerOffset + self.bannerHeightConstraint.constant / 2;
	CGFloat fakeStartPos = self.bannerOffset + self.bannerHeightConstraint.constant / 2;
	if (self.location == 1) startPos = [UIScreen mainScreen].bounds.size.height - startPos;

	self.lastTouchedDate = [NSDate date];

	if (sender.state == UIGestureRecognizerStateBegan) {
		pos = startPos;
		fakePos = fakeStartPos;
	} else if (sender.state == UIGestureRecognizerStateChanged) {
		CGFloat translatedY = translatedPoint.y;
		CGFloat distance = self.bannerView.center.y + translatedY;
		pos += translatedY;
		if (self.location == 1) fakePos -= translatedY;
		if (self.location == 0 && distance > startPos) distance = startPos * (1 + log10(pos/startPos));
		else if (self.location == 1 && distance < startPos) distance = [UIScreen mainScreen].bounds.size.height - (fakeStartPos * (1 + log10(fakePos/fakeStartPos)));

		translatedPoint = CGPointMake(self.bannerView.center.x, distance);
		[self.bannerView setCenter:translatedPoint];
		[sender setTranslation:CGPointZero inView:self.bannerView];

		if ((self.location == 0 && self.bannerView.center.y > startPos + 20) || (self.location == 1 && self.bannerView.center.y < startPos - 20)) {
			if (self.shouldPlayFeedback && !self.playedFeedback && !self.bannerView.expanded) {
				UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
				[feedback impactOccurred];
				self.playedFeedback = YES;
			}
		}
	} else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
		self.playedFeedback = NO;
		if (self.location == 0 && self.bannerView.center.y < startPos && velocity < 0) return [self animateOut];
		else if (self.location == 1 && self.bannerView.center.y > startPos && velocity > 0) return [self animateOut];

		if (self.location == 0 && self.bannerView.center.y > startPos + 20 && !self.bannerView.expanded) self.bannerView.expanded = YES;
		else if (self.location == 1 && self.bannerView.center.y < startPos - 20 && !self.bannerView.expanded) self.bannerView.expanded = YES;

		startPos = self.bannerOffset + self.bannerHeightConstraint.constant / 2;
		if (self.location == 1) startPos = [UIScreen mainScreen].bounds.size.height - startPos;

		[UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
			[self.bannerView setCenter:CGPointMake(self.bannerView.center.x, startPos)];
		} completion:nil];
	}
}

- (void)expansionChanged:(NSNotification *)notification {
	self.lastTouchedDate = [NSDate date];
	NSNumber *expanded = notification.userInfo[@"expanded"];
	if ([expanded isEqual:@(YES)]) {
		self.bannerWidthConstraint.active = NO;
		self.bannerWidthConstraint = [self.bannerView.widthAnchor constraintEqualToConstant:338];
		self.bannerWidthConstraint.active = YES;
		self.bannerHeightConstraint.constant = 152;
	} else {
		self.bannerWidthConstraint.active = NO;
		self.bannerWidthConstraint = [self.bannerView.widthAnchor constraintLessThanOrEqualToConstant:350];
		self.bannerWidthConstraint.active = YES;
		self.bannerHeightConstraint.constant = 44;
	}
}

- (void)setNowPlayingApp:(NSString *)nowPlayingApp {
	_nowPlayingApp = nowPlayingApp;
	self.bannerView.nowPlayingAppIdentifier = nowPlayingApp;
}

- (void)setLocation:(NSInteger)location {
	_location = location;
	if (self.bannerTopConstraint) {
		self.bannerTopConstraint.active = NO;
		if (location == 0) self.bannerTopConstraint = [self.bannerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.bannerOffset];
		else self.bannerTopConstraint = [self.bannerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-self.bannerOffset];
		self.bannerTopConstraint.active = YES;
	}
}

@end
