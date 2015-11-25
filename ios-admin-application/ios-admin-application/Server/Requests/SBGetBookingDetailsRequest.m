//
//  SBGetBookingDetailsRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetBookingDetailsRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBResultProcessor.h"
#import "SBBookingInfo.h"

@interface SBGetBookingDetailsResultProcessor : SBResultProcessor

@end

@implementation SBGetBookingDetailsRequest

- (NSString *)method
{
    return @"getBookingDetails";
}

- (NSArray *)params
{
    return @[self.bookingID];
}

- (id)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.bookingID = self.bookingID;
    return copy;
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]]
            addResultProcessorToChain:[SBGetBookingDetailsResultProcessor new]];
}

@end

@implementation SBGetBookingDetailsResultProcessor

- (BOOL)process:(id)result
{
    self.result = [[SBBookingInfo alloc] initWithDict:result];
    return YES;
}

@end