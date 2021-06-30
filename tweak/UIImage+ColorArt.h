#import <UIKit/UIKit.h>

@interface UIImage (ColorArt)
- (UIColor *)backgroundColor;
@end

@interface UIColor (ColorArt)
- (BOOL)isBlackOrWhite;
@end

@interface UICountedColor: NSObject
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) UIColor *color;
- (id)initWithColor:(UIColor *)color count:(NSUInteger)count;
@end
