//
//  SBGetCurrentUserDetailsRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 06.06.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBGetCurrentUserDetailsRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBUser.h"

@interface SBGetCurrentUserDetailsResultProcessor : SBResultProcessor

@property (nonatomic, strong) NSString *companyLogin;

- (instancetype)initWithCompanyLogin:(NSString *)companyLogin;

@end

@implementation SBGetCurrentUserDetailsRequest

- (NSString *)method
{
    return @"getCurrentUserDetails";
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]]
            addResultProcessorToChain:[[SBGetCurrentUserDetailsResultProcessor alloc] initWithCompanyLogin:self.companyLogin]];
}

@end

@implementation SBGetCurrentUserDetailsResultProcessor

- (instancetype)initWithCompanyLogin:(NSString *)companyLogin
{
    self = [super init];
    if (self) {
        self.companyLogin = companyLogin;
    }
    return self;
}

- (BOOL)process:(id)result
{
    self.result = [[SBUser alloc] initWithDict:result];
    return [self chainResult:self.result success:YES];
}

@end
