#import <UIKit/UIKit.h>

@interface SBSecureWindow : UIWindow
- (instancetype)initWithScreen:(UIScreen *)screen debugName:(NSString *)name;
- (instancetype)initWithScreen:(UIScreen *)screen role:(id)role debugName:(NSString *)name;
@end
