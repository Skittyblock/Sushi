// Modified code from ColorArt (https://github.com/panicinc/ColorArt)
//
// Copyright (C) 2012 Panic Inc. Code by Wade Cosgrove. All rights reserved.
//
// Redistribution and use, with or without modification, are permitted provided that the following conditions are met:
// - Redistributions must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// - Neither the name of Panic Inc nor the names of its contributors may be used to endorse or promote works derived from this software without specific prior written permission from Panic Inc.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL PANIC INC BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "UIImage+ColorArt.h"

typedef struct RGBAPixel {
	Byte red;
	Byte green;
	Byte blue;
	Byte alpha;
} RGBAPixel;

@implementation UIImage (ColorArt)

- (UIColor *)backgroundColor {
	CGImageRef imageRep = self.CGImage;

	NSUInteger pixelRange = 8;
	NSUInteger scale = 256 / pixelRange;
	NSUInteger rawImageColors[pixelRange][pixelRange][pixelRange];
	NSUInteger rawEdgeColors[pixelRange][pixelRange][pixelRange];
	
	for (NSUInteger b = 0; b < pixelRange; b++) {
		for (NSUInteger g = 0; g < pixelRange; g++) {
			for (NSUInteger r = 0; r < pixelRange; r++) {
				rawImageColors[r][g][b] = 0;
				rawEdgeColors[r][g][b] = 0;
			}
		}
	}

	NSInteger width = CGImageGetWidth(imageRep);
	NSInteger height = CGImageGetHeight(imageRep);

	CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, 4 * width, cs, kCGImageAlphaNoneSkipLast);
	CGContextDrawImage(bmContext, CGRectMake(0, 0, width, height), self.CGImage);
	CGColorSpaceRelease(cs);
	const RGBAPixel *pixels = (const RGBAPixel *)CGBitmapContextGetData(bmContext);

	int edgeThreshold = 5;
	for (NSUInteger y = 0; y < height; y++) {
		for (NSUInteger x = 0; x < width; x++) {
			const NSUInteger index = x + y * width;
			RGBAPixel pixel = pixels[index];
			Byte r = pixel.red / scale;
			Byte g = pixel.green / scale;
			Byte b = pixel.blue / scale;
			rawImageColors[r][g][b] = rawImageColors[r][g][b] + 1;
			if (x < edgeThreshold || x > width - edgeThreshold || y < edgeThreshold || y > height - edgeThreshold) rawEdgeColors[r][g][b] = rawEdgeColors[r][g][b] + 1;
		}
	}
	CGContextRelease(bmContext);

	NSMutableArray *imageColors = [NSMutableArray array];
	NSMutableArray *edgeColors = [NSMutableArray array];
	
	NSUInteger randomColorThreshold = 2;
	for (NSUInteger b = 0; b < pixelRange; b++) {
		for (NSUInteger g = 0; g < pixelRange; g++) {
			for (NSUInteger r = 0; r < pixelRange; r++) {
				NSUInteger count = rawImageColors[r][g][b];
				if (count > randomColorThreshold) {
					UIColor *color = [UIColor colorWithRed: r / (CGFloat)pixelRange green: g / (CGFloat)pixelRange blue: b / (CGFloat)pixelRange alpha: 1];
					UICountedColor *countedColor = [[UICountedColor alloc] initWithColor: color count: count];
					[imageColors addObject: countedColor];
				}
				
				count = rawEdgeColors[r][g][b];
				if (count > randomColorThreshold) {
					UIColor *color = [UIColor colorWithRed: r / (CGFloat)pixelRange green: g / (CGFloat)pixelRange blue: b / (CGFloat)pixelRange alpha: 1];
					UICountedColor *countedColor = [[UICountedColor alloc] initWithColor: color count: count];
					[edgeColors addObject: countedColor];
				}
			}
		}
	}
	
	NSMutableArray *sortedColors = edgeColors;
	[sortedColors sortUsingSelector: @selector(compare:)];

	UICountedColor *proposedEdgeColor = nil;
	if ([sortedColors count] > 0) {
		proposedEdgeColor = [sortedColors objectAtIndex: 0];
		if ([proposedEdgeColor.color isBlackOrWhite]) { // want to choose color over black/white so we keep looking
			for (NSInteger i = 1; i < [sortedColors count]; i++) {
				UICountedColor *nextProposedColor = [sortedColors objectAtIndex: i];
				if (((double)nextProposedColor.count / (double)proposedEdgeColor.count) > 0.4) { // make sure the second choice color is 40% as common as the first choice
					if (![nextProposedColor.color isBlackOrWhite]) {
						proposedEdgeColor = nextProposedColor;
						break;
					}
				}
				else break; // reached color threshold less than 40% of the original proposed edge color so bail
			}
		}
	}

	return proposedEdgeColor.color;
}

@end


@implementation UIColor (ColorArt)

- (BOOL)isBlackOrWhite {
	if (self) {
		CGFloat r, g, b, a;
		[self getRed: &r green: &g blue: &b alpha: &a];
		if ((r > 0.91 && g > 0.91 && b > 0.91) || (r < 0.09 && g < 0.09 && b < 0.09)) return YES;
	}
	return NO;
}

@end


@implementation UICountedColor

- (id)initWithColor:(UIColor *)color count:(NSUInteger)count {
	self = [super init];

	if (self) {
		self.color = color;
		self.count = count;
	}

	return self;
}

- (NSComparisonResult)compare:(UICountedColor *)object {
	if ([object isKindOfClass: [UICountedColor class]]) {
		if (self.count < object.count) return NSOrderedDescending;
		else if (self.count == object.count) return NSOrderedSame;
	}

	return NSOrderedAscending;
}

@end
