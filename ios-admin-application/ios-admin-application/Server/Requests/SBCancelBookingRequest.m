//
//  SBCancelBookingRequest.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 11.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBCancelBookingRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBCancelBookingRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof(self) copy = [super copyWithToken:token];
    copy.bookingID = self.bookingID;
    return copy;
}

- (SBCachePolicy)cachePolicy
{
    return SBNoCachePolicy;
}

- (NSString *)method
{
    return @"cancelBooking";
}

- (NSArray *)params
{
    return @[self.bookingID];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSNumber class]];
}

@end
