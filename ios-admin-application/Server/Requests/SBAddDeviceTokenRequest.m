//
//  SBAddDeviceTokenRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBAddDeviceTokenRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBAddDeviceTokenRequest

- (NSString *)method
{
    return @"addDeviceToken";
}

- (NSArray *)params
{
    return @[self.deviceToken, @"apple"];
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
