//
//  SBValidator.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBValidator.h"

@interface SBNotEmptyStringValidator : SBValidator
@end

@interface SBNotNullValidator : SBValidator
@end

@implementation SBValidator

+ (instancetype)notEmptyStringValidator
{
    return [SBNotEmptyStringValidator new];
}

+ (instancetype)notNullValidator
{
    return [SBNotNullValidator new];
}

- (BOOL)isValid:(id)value
{
    NSAssertNotImplementedFeature(@"This method should be overwritten by subclasses.");
    return YES;
}

@end

#pragma mark -

@implementation SBNotEmptyStringValidator

- (BOOL)isValid:(NSString *)value
{
    if (![value isKindOfClass:[NSString class]]) {
        return NO;
    }
    return ![[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""];
}

@end

#pragma mark -

@implementation SBNotNullValidator

- (BOOL)isValid:(id)value
{
    return value != nil && ![value isEqual:[NSNull null]];
}

@end