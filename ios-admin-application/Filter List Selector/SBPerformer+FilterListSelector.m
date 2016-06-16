//
//  SBPerformer+FilterListSelector.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBPerformer+FilterListSelector.h"
#import "UIColor+SimplyBookColors.h"

@implementation SBPerformer (FilterListSelector)

- (NSString *)itemID
{
    return self.performerID;
}

- (NSString *)title
{
    return self.name;
}

- (NSString *)subtitle
{
    NSMutableString *subtitle = [NSMutableString string];
    if (self.email) {
        [subtitle appendFormat:@"%@\t", self.email];
    }
    if (self.phone) {
        [subtitle appendString:self.phone];
    }
    return subtitle;
}

- (UIColor *)colorObject
{
    if (self.color) {
        return [UIColor colorFromHEXString:self.color];
    }
    return nil;
}

@end
