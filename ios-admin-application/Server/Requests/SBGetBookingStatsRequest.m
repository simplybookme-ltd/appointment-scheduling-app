//
//  SBGetBookingStatsRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 29.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetBookingStatsRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBGetBookingStatsRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.timePeriod = self.timePeriod;
    return copy;
}

- (NSString *)method
{
    return @"getBookingStats";
}

- (NSArray *)params
{
    return @[self.timePeriod];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]];
}

@end
