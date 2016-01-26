//
//  SBServerIDValidator.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBServerIDValidator.h"

@implementation SBServerIDValidator

- (BOOL)isValid:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        SBValidator *notEmptyStringValidator = [SBValidator notEmptyStringValidator];
        return [notEmptyStringValidator isValid:value] && ![value isEqualToString:@"0"];
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        return ![value isEqualToNumber:@0];
    }
    return NO;
}

@end
