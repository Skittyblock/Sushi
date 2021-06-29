#import "SUNowPlayingProgressView.h"
#import <MediaRemote/MediaRemote.h>

@implementation SUNowPlayingProgressView

- (instancetype)init {
	self = [super init];

	if (self) {
		self.remainingTrack = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 3)];
		self.remainingTrack.layer.cornerRadius = 2;
		self.remainingTrack.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
		[self addSubview:self.remainingTrack];

		self.elapsedTrack = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 3)];
		self.elapsedTrack.layer.cornerRadius = 2;
		self.elapsedTrack.backgroundColor = [UIColor blackColor];
		[self addSubview:self.elapsedTrack];

		self.elapsedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 11, 40, 12)];
		self.elapsedLabel.textColor = [UIColor blackColor];
		self.elapsedLabel.font = [UIFont boldSystemFontOfSize:13];
		self.elapsedLabel.text = @"0:00";
		[self addSubview:self.elapsedLabel];

		self.remainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(260, 11, 40, 12)];
		self.remainingLabel.textColor = [UIColor lightGrayColor];
		self.remainingLabel.font = [UIFont boldSystemFontOfSize:13];
		self.remainingLabel.textAlignment = NSTextAlignmentRight;
		self.remainingLabel.text = @"0:00";
		[self addSubview:self.remainingLabel];

		self.duration = 0;
		self.elapsedTime = 0;
	}

	return self;
}

- (void)setDuration:(double)duration {
	_duration = duration;

	if (!duration || duration < 0) duration = 0;

	NSUInteger m = ((NSUInteger)floor(duration) / 60);
	NSUInteger s = (NSUInteger)floor(duration) % 60;

	self.remainingLabel.text = [NSString stringWithFormat:@"%lu:%02lu", m, s];
}

- (void)setElapsedTime:(double)elapsed {
	_elapsedTime = elapsed;

	if (!elapsed || elapsed < 0) elapsed = 0;

	NSUInteger m = ((NSUInteger)floor(elapsed) / 60);
	NSUInteger s = (NSUInteger)floor(elapsed) % 60;

	CGFloat width = (self.duration > 0 ? (elapsed/(self.duration))*297 : 0) + 3;

	self.elapsedTrack.frame = CGRectMake(0, 0, width, 3);
	self.elapsedLabel.text = [NSString stringWithFormat:@"%lu:%02lu", m, s];
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
		CFAbsoluteTime timeStarted = CFDateGetAbsoluteTime((CFDateRef)[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTimestamp]);
		double lastStoredTime = [[(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoElapsedTime] doubleValue];
		double realTimeElapsed = (CFAbsoluteTimeGetCurrent() - timeStarted) + (lastStoredTime > 1 ? lastStoredTime : 0);

		self.elapsedTime = realTimeElapsed;
	});
}

@end
