//
//  SBService+FilterListSelector.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBService+FilterListSelector.h"
#import "SBCompanyInfo.h"

@implementation SBService (FilterListSelector)

- (NSString *)itemID
{
    return self.serviceID;
}

- (NSString *)title
{
    return self.name;
}

- (NSString *)subtitle
{
    static NSNumberFormatter *sb_service_priceFormatter = nil;
    if (sb_service_priceFormatter == nil) {
        sb_service_priceFormatter = [NSNumberFormatter new];
        sb_service_priceFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    }
    NSMutableString *subtitle = [NSMutableString string];
    if ([self.duration integerValue] > 0) {
        [subtitle appendFormat:@"%@\t", [SBCompanyInfo localizedStringForServiceDuration:[self.duration integerValue]]];
    }
    if (self.price && [self.price floatValue] > 0) {
        [sb_service_priceFormatter setCurrencyCode:self.currency];
        [subtitle appendString:[sb_service_priceFormatter stringFromNumber:self.price]];
    }
    return subtitle;
}

- (UIColor *)colorObject
{
    return nil;
}

@end
