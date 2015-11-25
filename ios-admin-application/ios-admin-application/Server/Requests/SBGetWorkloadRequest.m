//
//  SBGetWorkloadRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetWorkloadRequest.h"
#import "SBRequestOperation_Private.h"
#import "NSDateFormatter+ServerParser.h"

@interface SBGetWorkloadRequest ()

@end

@implementation SBGetWorkloadRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.startDate = self.startDate;
    copy.endDate = self.endDate;
    copy.performerID = self.performerID;
    return copy;
}

- (NSString *)method
{
    return @"getWorkload";
}

- (NSArray *)params
{
    // start, end, performer id
    return @[(self.startDate ? [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.startDate] : [NSNull null]),
             (self.endDate ? [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.endDate] : [NSNull null]),
             (self.performerID ? self.performerID : [NSNull null])];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]];
}

@end
