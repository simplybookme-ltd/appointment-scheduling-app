//
//  SBAddClientRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBAddClientRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBAddClientRequest

- (NSString *)method
{
    return @"addClient";
}

- (NSArray *)params
{
    return @[ @{@"name" : self.clientName,
                @"email" : (self.email ? self.email : @""),
                @"phone" : (self.phone ? self.phone : @"")} ];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSString class]];
}

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.clientName = self.clientName;
    copy.phone = self.phone;
    copy.email = self.email;
    return copy;
}

- (SBCachePolicy)cachePolicy
{
    return SBNoCachePolicy;
}

@end
