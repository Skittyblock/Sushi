#import "UIColor+SushiColors.h"

@implementation UIColor (SushiColors)

+ (UIColor *)sushiSecondaryLabelColor {
	return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
		if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			return [UIColor darkSushiSecondaryLabelColor];
		} else {
			return [UIColor lightSushiSecondaryLabelColor];
		}
	}];
}

+ (UIColor *)darkSushiSecondaryLabelColor {
	return [UIColor colorWithRed:0.96 green:0.96 blue:1 alpha:0.3];
}

+ (UIColor *)lightSushiSecondaryLabelColor {
	return [UIColor colorWithWhite:0 alpha:0.2];
}

@end
