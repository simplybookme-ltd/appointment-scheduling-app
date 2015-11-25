//
//  SBGetBookingCancellationsInfoRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetBookingCancellationsInfoRequest.h"
#import "SBRequestOperation_Private.h"
#import "NSDateFormatter+ServerParser.h"

@interface SBGetBookingCancellationsInfoRequest ()

@end

@implementation SBGetBookingCancellationsInfoRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.startDate = self.startDate;
    copy.endDate = self.endDate;
    return copy;
}

- (NSString *)method
{
    return @"getBookingCancellationsInfo";
}

- (NSArray *)params
{
    if (self.startDate && self.endDate) {
        return @[[[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.startDate],
                [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.endDate]];
    }
    return @[];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]];
}

@end
