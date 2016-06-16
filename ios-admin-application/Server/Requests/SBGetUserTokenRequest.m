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

- (instancetype)copyWithToken:(NSString *)token
{
    NSAssertNotImplementedFeature(@"this request can't be duplicated");
    return nil;
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
    NSAssert(self.companyLogin != nil, @"company login can't be nil");
    NSAssert(self.login != nil, @"login can't be nil");
    NSAssert(self.password != nil, @"password can't be nil");
    return @[self.companyLogin ? [self.companyLogin lowercaseString] : @"",
             self.login ? self.login : @"",
             self.password ? self.password : @""];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSString class]];
}

@end
