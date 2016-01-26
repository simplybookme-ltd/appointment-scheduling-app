//
//  UIColor+SimplyBookColors.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SBColorBrightness) {
    SBColorUndefinedColorBrightness,
    SBColorLightColorBrightness,
    SBColorDarkColorBrightness
};

@interface UIColor (SimplyBookColors)

+ (instancetype)sb_navigationBarColor;
+ (instancetype)sb_tintColor;
+ (instancetype)colorFromHEXString:(NSString *)HEXString;
+ (instancetype)sb_gridColor;
+ (instancetype)sb_defaultBookingColor;
- (SBColorBrightness)sb_colorBrightness;
- (UIColor *)sb_colorLighterByPercent:(CGFloat)percent;
- (UIColor *)sb_colorDarkerByPercent:(CGFloat)percent;

@end
