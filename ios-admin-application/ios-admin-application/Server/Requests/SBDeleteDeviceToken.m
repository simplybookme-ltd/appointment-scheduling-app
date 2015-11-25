//
//  SBDeleteDeviceToken.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBDeleteDeviceToken.h"
#import "SBRequestOperation_Private.h"

@implementation SBDeleteDeviceToken

- (NSString *)method
{
    return @"deleteDeviceToken";
}

- (NSArray *)params
{
    return @[self.deviceToken];
}

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.deviceToken = self.deviceToken;
    return copy;
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSNumber class]];
}

- (SBCachePolicy)cachePolicy
{
    return SBNoCachePolicy;
}

@end
