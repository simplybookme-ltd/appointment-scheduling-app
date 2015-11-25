//
//  SBGetUserTokenRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetUserTokenRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBGetUserTokenRequest

- (instancetype)initWithComanyLogin:(NSString *)companyLogin
{
    return [self initWithToken:nil comanyLogin:companyLogin];
}

- (SBCachePolicy)cachePolicy
{
    return SBNoCachePolicy;
}

- (NSString *)method
{
    return @"getUserToken";
}

- (NSArray *)params
{
    return @[[self.companyLogin lowercaseString], self.login, self.password];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSString class]];
}

@end
