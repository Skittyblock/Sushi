#import "SUActiveOrientationManager.h"

@implementation SUActiveOrientationManager

- (void)activeInterfaceOrientationWillChangeToOrientation:(UIInterfaceOrientation)orientation {
}

- (void)activeInterfaceOrientationDidChangeToOrientation:(UIInterfaceOrientation)orientation willAnimateWithDuration:(NSTimeInterval)duration fromOrientation:(UIInterfaceOrientation)previousOrientation {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"xyz.skitty.sushi.orient" object:nil userInfo:@{ @"orientation": @(orientation) }];
}

@end
