//
//  SBGetGoogleCalendarBusyTimeRequests.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 15.02.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBGetGoogleCalendarBusyTimeRequest.h"
#import "SBRequestOperation_Private.h"
#import "NSDateFormatter+ServerParser.h"

@interface SBGetGoogleCalendarBusyTimeResultProcessor : SBResultProcessor

@end

@implementation SBGetGoogleCalendarBusyTimeRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof(self) copy = [super copyWithToken:token];
    copy.startDate = self.startDate;
    copy.endDate = self.endDate;
    copy.unitID = self.unitID;
    return copy;
}

- (NSString *)method
{
    return @"getGoogleCalendarBusyTime";
}

- (NSArray *)params
{
    NSAssert(self.startDate != nil, @"no start date specified");
    NSAssert(self.endDate != nil, @"no end date specified");
    NSAssert(self.unitID != nil, @"");
    return @[self.startDate ? [[NSDateFormatter sb_serverDateTimeFormatter] stringFromDate:self.startDate] : [[NSDateFormatter sb_serverDateTimeFormatter] stringFromDate:[NSDate date]],
             self.endDate ? [[NSDateFormatter sb_serverDateTimeFormatter] stringFromDate:self.endDate] : [[NSDateFormatter sb_serverDateTimeFormatter] stringFromDate:[NSDate date]],
             self.unitID];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBGetGoogleCalendarBusyTimeResultProcessor new];
}

@end

@implementation SBGetGoogleCalendarBusyTimeResultProcessor

- (BOOL)process:(id)result
{
    SBClassCheckProcessor *classCheckProcessor = [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]];
    if (![classCheckProcessor process:result]) {
        self.error = classCheckProcessor.error;
        self.result = classCheckProcessor.result;
        return [self chainResult:self.result success:NO];
    }
    NSMutableArray *list = [NSMutableArray array];
    for (NSDictionary *range in result) {
        NSString *fromDateString = range[@"from"];
        NSString *toDateString = range[@"to"];
        if (fromDateString && toDateString) {
            NSDate *from = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:fromDateString];
            NSDate *to = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:toDateString];
            if (from && to) {
                [list addObject:@{ @"from": from, @"to": to }];
            }
        }
    }
    self.result = list;
    return [self chainResult:self.result success:YES];
}

@end
