#import <UIKit/UIKit.h>
#import "SBSecureWindow.h"
#import "SUNowPlayingViewController.h"

@class SUNowPlayingManager;

@interface SUNowPlayingWindow : SBSecureWindow

@property (nonatomic, retain) SUNowPlayingViewController *rootViewController;
@property (nonatomic, retain) SUNowPlayingManager *manager;
@property (nonatomic, assign) BOOL hsRotation;

- (void)orientationDidChangeToOrientation:(UIInterfaceOrientation)orientation;

@end
