//
//  SBGetUnitWorkdayInfoRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 21.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetUnitWorkdayInfoRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBResultProcessor.h"
#import "NSDateFormatter+ServerParser.h"

@interface SBGetUnitWorkdayInfoResultProcessor : SBResultProcessor

@end

@interface SBGetUnitWorkdayInfoRequest ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation SBGetUnitWorkdayInfoRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.startDate = self.startDate;
    copy.endDate = self.endDate;
    return copy;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return _dateFormatter;
}

- (NSString *)method
{
    return @"getUnitWorkdayInfo";
}

- (NSArray *)params
{
    return @[[self.dateFormatter stringFromDate:self.startDate], [self.dateFormatter stringFromDate:self.endDate]];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBGetUnitWorkdayInfoResultProcessor new];
}

@end

@implementation SBGetUnitWorkdayInfoResultProcessor

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
    NSMutableDictionary *schedule = [NSMutableDictionary dictionary];
    NSDate *startDate = nil, *endDate = nil;
    for (NSString *dateString in [result allKeys]) {
        for (NSString *unitID in [result objectForKey:dateString]) {
            NSDictionary *unitSchedule = [[result objectForKey:dateString] objectForKey:unitID];
            NSDate *start = [[NSDateFormatter sb_serverTimeFormatter] dateFromString:unitSchedule[@"start_time"]];
            NSDate *_end = [[NSDateFormatter sb_serverTimeFormatter] dateFromString:unitSchedule[@"end_time"]];
            if (!startDate) {
                startDate = start;
            } else {
                startDate = ([startDate compare:start] == NSOrderedDescending) ? start : startDate;
            }
            if (!endDate) {
                endDate = _end;
            } else {
                endDate = ([endDate compare:_end] == NSOrderedAscending) ? _end : endDate;
            }
        }
        if (startDate && endDate) {
            NSDate *key = [[NSDateFormatter sb_serverDateFormatter] dateFromString:dateString];
            schedule[key] = @{@"start" : startDate, @"end" : endDate};
        }
        startDate = nil;
        endDate = nil;
    }
    self.result = schedule;
    return YES;
}

@end