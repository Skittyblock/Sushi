#import "SUNowPlayingControlsView.h"
#import <MediaRemote/MediaRemote.h>

@implementation SUNowPlayingControlsView

- (instancetype)init {
	self = [super init];

	if (self) {
		self.userInteractionEnabled = YES;

		self.previousButton = [SUMusicControlButton buttonWithType:UIButtonTypeCustom];
		[self.previousButton addTarget:self action:@selector(heldPrevious) forControlEvents:UIControlEventTouchDown];
		[self.previousButton addTarget:self action:@selector(releasedPrevious) forControlEvents:UIControlEventTouchUpInside];
		[self.previousButton addTarget:self action:@selector(resetHold) forControlEvents:UIControlEventTouchUpOutside];
		[self.previousButton addTarget:self action:@selector(resetHold) forControlEvents:UIControlEventTouchCancel];
		self.previousButton.icon = [UIImage systemImageNamed:@"backward.fill"];
		self.previousButton.tintColor = [UIColor blackColor];
		self.previousButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
		self.previousButton.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.previousButton];

		self.playPauseButton = [SUMusicControlButton buttonWithType:UIButtonTypeCustom];
		[self.playPauseButton addTarget:self action:@selector(playPause) forControlEvents:UIControlEventTouchUpInside];
		self.playPauseButton.icon = [UIImage systemImageNamed:@"play.fill"];
		self.playPauseButton.tintColor = [UIColor blackColor];
		self.playPauseButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
		self.playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.playPauseButton];

		self.nextButton = [SUMusicControlButton buttonWithType:UIButtonTypeCustom];
		[self.nextButton addTarget:self action:@selector(heldNext) forControlEvents:UIControlEventTouchDown];
		[self.nextButton addTarget:self action:@selector(releasedNext) forControlEvents:UIControlEventTouchUpInside];
		[self.nextButton addTarget:self action:@selector(resetHold) forControlEvents:UIControlEventTouchUpOutside];
		[self.nextButton addTarget:self action:@selector(resetHold) forControlEvents:UIControlEventTouchCancel];
		self.nextButton.icon = [UIImage systemImageNamed:@"forward.fill"];
		self.nextButton.tintColor = [UIColor blackColor];
		self.nextButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
		self.nextButton.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.nextButton];

		[self activateConstraints];
	}

	return self;
}

- (void)activateConstraints {
	[NSLayoutConstraint activateConstraints:@[
		[self.previousButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
		[self.previousButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
		[self.previousButton.widthAnchor constraintEqualToConstant:31 + 20],
		[self.previousButton.heightAnchor constraintEqualToAnchor:self.heightAnchor],

		[self.playPauseButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
		[self.playPauseButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
		[self.playPauseButton.widthAnchor constraintEqualToConstant:26 + 20],
		[self.playPauseButton.heightAnchor constraintEqualToAnchor:self.heightAnchor],

		[self.nextButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
		[self.nextButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
		[self.nextButton.widthAnchor constraintEqualToConstant:31 + 20],
		[self.nextButton.heightAnchor constraintEqualToAnchor:self.heightAnchor]
	]];
}

- (void)setPaused:(BOOL)paused {
	_paused = paused;
	self.playPauseButton.icon = [UIImage systemImageNamed:paused ? @"play.fill" : @"pause.fill"];
}

- (void)playPause {
	MRMediaRemoteSendCommand(MRMediaRemoteCommandTogglePlayPause, nil);
	self.paused = !self.paused;
}

- (void)rewind {
	MRMediaRemoteSendCommand(MRMediaRemoteCommandBeginRewind, nil);
}

- (void)fastForward {
	MRMediaRemoteSendCommand(MRMediaRemoteCommandBeginFastForward, nil);
}

- (void)resetHold {
	[self.heldTimer invalidate];
	self.heldDownDate = nil;
	self.heldTimer = nil;
	self.backgroundColor = [UIColor clearColor];
}

- (void)heldPrevious {
	self.heldDownDate = [NSDate date];
	self.heldTimer = [NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(rewind) userInfo:nil repeats:NO];
}

- (void)heldNext {
	self.heldDownDate = [NSDate date];
	self.heldTimer = [NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(fastForward) userInfo:nil repeats:NO];
}

- (void)releasedPrevious {
	NSTimeInterval interval = -[self.heldDownDate timeIntervalSinceNow];
	MRMediaRemoteSendCommand(interval < 0.75 ? MRMediaRemoteCommandPreviousTrack : MRMediaRemoteCommandEndRewind, nil);
	[self resetHold];
}

- (void)releasedNext {
	NSTimeInterval interval = -[self.heldDownDate timeIntervalSinceNow];
	MRMediaRemoteSendCommand(interval < 0.75 ? MRMediaRemoteCommandNextTrack : MRMediaRemoteCommandEndFastForward, nil);
	[self resetHold];
}

@end
