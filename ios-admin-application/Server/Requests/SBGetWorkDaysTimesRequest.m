//
//  SBGetWorkDaysTimesRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 22.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetWorkDaysTimesRequest.h"
#import "NSDateFormatter+ServerParser.h"
#import "NSDate+TimeManipulation.h"

NSString * const kSBGetWorkDaysTimesRequest_PerformerType = @"unit_group";
NSString * const kSBGetWorkDaysTimesRequest_DefaultType = @"unit_group";
NSString * const kSBGetWorkDaysTimesRequest_ServiceType = @"event";

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
    copy.type = self.type;
    return copy;
}

- (NSString *)method
{
    return @"getWorkDaysTimes";
}

- (NSArray *)params
{
    NSAssert(self.startDate != nil, @"start date parameter not specified");
    NSAssert(self.endDate != nil, @"end date parameter not specified");
    NSAssert((self.type != nil && [@[kSBGetWorkDaysTimesRequest_ServiceType, kSBGetWorkDaysTimesRequest_PerformerType] containsObject:self.type]), @"unexpected type parameter value (%@)", self.type);
    if (self.type == nil) {
        self.type = kSBGetWorkDaysTimesRequest_PerformerType;
    }
    return @[[[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.startDate ? self.startDate : [NSDate date]],
             [[NSDateFormatter sb_serverDateFormatter] stringFromDate:self.endDate ? self.endDate : [[NSDate date] nextDayDate]],
             self.type];
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
    if ([result isKindOfClass:[NSArray class]] && [(NSArray *)result count] == 0) {
        self.result = @{};
        return YES;
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
