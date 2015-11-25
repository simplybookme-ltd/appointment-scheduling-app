//
//  UIColor+SimplyBookColors.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "UIColor+SimplyBookColors.h"

@implementation UIColor (SimplyBookColors)

+ (instancetype)sb_navigationBarColor
{
    return [UIColor colorWithRed:0.184 green:0.639 blue:0.847 alpha:1];
}

+ (instancetype)sb_tintColor
{
    return [UIColor colorWithRed:0.184 green:0.639 blue:0.847 alpha:1];
}

+ (instancetype)colorFromHEXString:(NSString *)HEXString
{
    NSParameterAssert(HEXString != nil);
    NSParameterAssert([HEXString isKindOfClass:[NSString class]]);
    if ([HEXString hasPrefix:@"#"]) {
        HEXString = [HEXString substringFromIndex:1];
    }
    if (![HEXString hasPrefix:@"0x"]) {
        HEXString = [NSString stringWithFormat:@"0x%@", HEXString];
    }
    NSScanner *scanner = [NSScanner scannerWithString:HEXString];
    unsigned int color = 0;
    if ([scanner scanHexInt:&color]) {
        return [UIColor colorWithRed:((float) ((color & 0xFF0000) >> 16)) / 255.0
                               green:((float) ((color & 0xFF00) >> 8)) / 255.0
                                blue:((float) (color & 0xFF)) / 255.0 alpha:1.0];
    }
    return nil;
}

+ (instancetype)sb_gridColor
{
    return [UIColor colorWithRed:0.783922 green:0.780392 blue:0.8 alpha:1];
}

+ (instancetype)sb_defaultBookingColor
{
    return [UIColor colorWithRed:0.106 green:0.518 blue:0.627 alpha:1.000];
}

- (SBColorBrightness)sb_colorBrightness
{
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a]) {
        CGFloat colorBrightness = ((r * 299) + (g * 587) + (b * 114)) / 1000;
        return colorBrightness < .5 ? SBColorDarkColorBrightness : SBColorLightColorBrightness;
    }
    return SBColorUndefinedColorBrightness;
}

- (UIColor *)sb_colorLighterByPercent:(CGFloat)percent
{
    CGFloat b, h, s, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a]) {
        return [UIColor colorWithHue:h saturation:s brightness:MIN(1, b+((b/100) * percent)) alpha:a];
    }
    return nil;
}

- (UIColor *)sb_colorDarkerByPercent:(CGFloat)percent
{
    CGFloat b, h, s, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a]) {
        return [UIColor colorWithHue:h saturation:s brightness:MAX(0, b-((b/100) * percent)) alpha:a];
    }
    return nil;
}

@end
