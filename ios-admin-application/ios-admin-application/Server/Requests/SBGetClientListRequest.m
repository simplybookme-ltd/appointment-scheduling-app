//
//  SBGetClientListRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetClientListRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBGetClientListRequest

- (NSString *)method
{
    return @"getClientList";
}

- (NSArray *)params
{
    return @[self.pattern];
}

- (instancetype)copyWithToken:(NSString *)token
{
    typeof(self) copy = [super copyWithToken:token];
    copy.pattern = self.pattern;
    return copy;
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]];
}

@end
