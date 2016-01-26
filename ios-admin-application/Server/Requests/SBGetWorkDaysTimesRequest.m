//
//  SBGetWorkDaysTimesRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 22.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetWorkDaysTimesRequest.h"
#import "NSDateFormatter+ServerParser.h"

@interface SBGetWorkDaysTimesResultProcessor : SBResultProcessor

@end

@interface SBGetWorkDaysTimesRequest ()

@end

@implementation SBGetWorkDaysTimesRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.startDate = self.startDate;
    copy.endDate = self.endDate;
    return copy;
}

- (NSString *)method
{
    return @"getWorkDaysTimes";
}

- (NSArray *)params
{
    return @[[[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.startDate ? self.startDate : [NSDate date]],
             [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.endDate ? self.endDate : [NSDate date]]];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBGetWorkDaysTimesResultProcessor new];
}

@end

@implementation SBGetWorkDaysTimesResultProcessor

- (BOOL)process:(id)result
{
    SBClassCheckProcessor *classCheck = [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]];
    if (![classCheck process:result]) {
        self.error = classCheck.error;
        self.result = result;
        return NO;
    }
    if (![classCheck process:[[result allValues] firstObject]]) {
        self.error = classCheck.error;
        self.result = result;
        return NO;
    }
    self.result = result;
    return YES;
}

@end