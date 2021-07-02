#import "SUNowPlayingProgressView.h"
#import <MediaRemote/MediaRemote.h>

@implementation SUNowPlayingProgressView

- (instancetype)init {
	self = [super init];

	if (self) {
		self.userInteractionEnabled = YES;

		self.remainingTrack = [[UIView alloc] init];
		self.remainingTrack.layer.cornerRadius = 2;
		self.remainingTrack.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
		self.remainingTrack.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.remainingTrack];

		self.elapsedTrack = [[UIView alloc] init];
		self.elapsedTrack.layer.cornerRadius = 2;
		self.elapsedTrack.backgroundColor = [UIColor blackColor];
		self.elapsedTrack.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.elapsedTrack];

		self.knobView = [[SUNowPlayingProgressKnobView alloc] init];
		self.knobView.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.knobView];

		self.elapsedLabel = [[UILabel alloc] init];
		self.elapsedLabel.textColor = [UIColor blackColor];
		self.elapsedLabel.font = [UIFont boldSystemFontOfSize:13];
		self.elapsedLabel.text = @"0:00";
		self.elapsedLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.elapsedLabel];

		self.remainingLabel = [[UILabel alloc] init];
		self.remainingLabel.textColor = [UIColor lightGrayColor];
		self.remainingLabel.font = [UIFont boldSystemFontOfSize:13];
		self.remainingLabel.textAlignment = NSTextAlignmentRight;
		self.remainingLabel.text = @"0:00";
		self.remainingLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.remainingLabel];

		UIPanGestureRecognizer *scrubRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrubbed:)];
		[scrubRecognizer setMinimumNumberOfTouches:1];
		[scrubRecognizer setMaximumNumberOfTouches:1];
		[self.knobView addGestureRecognizer:scrubRecognizer];

		[self activateConstraints];

		self.duration = 0;
		self.elapsedTime = 0;
	}

	return self;
}

- (void)activateConstraints {
	[self.remainingTrack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:6].active = YES;
	[self.remainingTrack.topAnchor constraintEqualToAnchor:self.topAnchor constant:8].active = YES;
	[self.remainingTrack.widthAnchor constraintEqualToConstant:300].active = YES;
	[self.remainingTrack.heightAnchor constraintEqualToConstant:3].active = YES;

	[self.elapsedTrack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:6].active = YES;
	[self.elapsedTrack.topAnchor constraintEqualToAnchor:self.topAnchor constant:8].active = YES;
	self.elapsedTrackWidthConstraint = [self.elapsedTrack.widthAnchor constraintEqualToConstant:3];
	self.elapsedTrackWidthConstraint.active = YES;
	[self.elapsedTrack.heightAnchor constraintEqualToConstant:3].active = YES;

	self.knobViewLeadingConstraint = [self.knobView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
	self.knobViewLeadingConstraint.active = YES;
	[self.knobView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
	[self.knobView.widthAnchor constraintEqualToConstant:19].active = YES;
	[self.knobView.heightAnchor constraintEqualToConstant:19].active = YES;

	[self.elapsedLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:6].active = YES;
	[self.elapsedLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:19].active = YES;
	[self.elapsedLabel.widthAnchor constraintEqualToConstant:50].active = YES;
	[self.elapsedLabel.heightAnchor constraintEqualToConstant:12].active = YES;

	[self.remainingLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-6].active = YES;
	[self.remainingLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:19].active = YES;
	[self.remainingLabel.widthAnchor constraintEqualToConstant:50].active = YES;
	[self.remainingLabel.heightAnchor constraintEqualToConstant:12].active = YES;
}

- (void)startTimer {
	[self stopTimer];
	self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tickTimeElapsed) userInfo:nil repeats:YES];
}

- (void)stopTimer {
	if (self.timer) [self.timer invalidate];
	self.timer = nil;
}

- (void)tickTimeElapsed {
	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
		NSNumber *playbackRate = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoPlaybackRate];
		if ([playbackRate isEqual:@(0)]) return;

		CFAbsoluteTime timeStarted = CFDateGetAbsoluteTime((CFDateRef)[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTimestamp]);
		double lastStoredTime = [[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime] doubleValue];
		double realTimeElapsed = (CFAbsoluteTimeGetCurrent() - timeStarted) + (lastStoredTime > 1 ? lastStoredTime : 0);

		self.elapsedTime = realTimeElapsed;
	});
}

- (void)setDuration:(double)duration {
	_duration = duration;

	if (!duration || duration < 0) duration = 0;

	NSUInteger m = ((NSUInteger)floor(duration) / 60);
	NSUInteger s = (NSUInteger)floor(duration) % 60;

	self.remainingLabel.text = [NSString stringWithFormat:@"%lu:%02lu", m, s];
}

- (void)setElapsedTime:(double)elapsed {
	if (elapsed > self.duration) return;

	_elapsedTime = elapsed;

	if (!elapsed || elapsed < 0) elapsed = 0;

	NSUInteger m = ((NSUInteger)floor(elapsed) / 60);
	NSUInteger s = (NSUInteger)floor(elapsed) % 60;

	CGFloat width = (self.duration > 0 ? (elapsed/(self.duration))*293 : 0) + 6;

	self.elapsedTrackWidthConstraint.constant = width;
	self.knobViewLeadingConstraint.constant = width-6;
	self.elapsedLabel.text = [NSString stringWithFormat:@"%lu:%02lu", m, s];
}

- (void)tapped:(UILongPressGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateBegan) {
		[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			self.knobView.transform = CGAffineTransformMakeScale(3, 3);
		} completion:nil];
	} else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
		[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			self.knobView.transform = CGAffineTransformMakeScale(1, 1);
		} completion:nil];
	}
}

- (void)scrubbed:(UIPanGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateBegan) {
		[self stopTimer];
	} else if (sender.state == UIGestureRecognizerStateChanged) {
		CGFloat distance = self.knobViewLeadingConstraint.constant + [sender translationInView:self].x;
		if (distance < 0) distance = 0;
		else if (distance > 293) distance = 293;

		if (self.duration <= 0) {
			self.elapsedTrackWidthConstraint.constant = distance + 3;
			self.knobViewLeadingConstraint.constant = distance;
		} else {
			self.elapsedTime = distance / 293 * self.duration;
		}

		[sender setTranslation:CGPointZero inView:self];
	} else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
		[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			self.knobView.transform = CGAffineTransformMakeScale(1, 1);
		} completion:nil];

		if (self.duration > 0) {
			double distance = self.knobViewLeadingConstraint.constant;
			double elapsedTime = distance / 293 * self.duration;
			MRMediaRemoteSetElapsedTime(elapsedTime);
			[self startTimer];
		}
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	return;
}

@end
