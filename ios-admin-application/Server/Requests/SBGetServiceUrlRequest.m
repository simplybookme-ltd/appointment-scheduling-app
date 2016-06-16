//
//  SBGetServiceUrlRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 20.04.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBGetServiceUrlRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBResultProcessor.h"

@implementation SBGetServiceUrlRequest

- (instancetype)initWithCompanyLogin:(NSString *)companyLogin
{
    NSParameterAssert(companyLogin != nil);
    return [self initWithToken:nil comanyLogin:companyLogin];
}

- (NSString *)method
{
    return @"getServiceUrl";
}

- (NSArray *)params
{
    NSParameterAssert(self.companyLogin != nil);
    return @[self.companyLogin];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSString class]];
}

@end
