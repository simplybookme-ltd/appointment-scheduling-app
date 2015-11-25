//
//  SBIsPluginActivatedRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 13.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBIsPluginActivatedRequest.h"
#import "SBRequestOperation_Private.h"

@interface SBIsPluginActivatedResultProcessor : SBResultProcessor

@end

@implementation SBIsPluginActivatedRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.pluginName = self.pluginName;
    return copy;
}

- (NSArray *)params
{
    return @[self.pluginName];
}

- (NSString *)method
{
    return @"isPluginActivated";
}

- (SBResultProcessor *)resultProcessor
{
    return [SBIsPluginActivatedResultProcessor new];
}

@end

@implementation SBIsPluginActivatedResultProcessor

- (BOOL)process:(id)result
{
    if ([result isEqual:[NSNull null]]) {
        self.result = @(NO);
    }
    else if ([result isKindOfClass:[NSString class]]) {
        self.result = @([result isEqualToString:@"1"]);
    }
    else if ([result isKindOfClass:[NSNumber class]]) {
        self.result = @([result boolValue]);
    }
    else {
        self.result = @(NO);
    }
    return YES;
}

@end