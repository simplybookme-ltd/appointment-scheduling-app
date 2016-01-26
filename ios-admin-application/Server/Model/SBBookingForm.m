//
//  SBBookingForm.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBBookingForm.h"
#import "NSDate+TimeManipulation.h"

@interface SBBookingForm ()

@property (nonatomic, copy, readwrite) NSString *eventID;
@property (nonatomic, readwrite) NSUInteger eventDuration;

@end

@implementation SBBookingForm

- (void)setEventID:(NSString *)eventID withDuration:(NSUInteger)duration
{
    self.eventID = eventID;
    self.eventDuration = duration;
}

- (BOOL)isDateRangeValid:(SBDateRange *)dateRange
{
    NSParameterAssert(dateRange != nil);
    NSDate *startDateTime = [dateRange.end dateByAssigningTimeComponentsFromDate:self.startTime];
    NSDate *endDateTime = [dateRange.start dateByAssigningTimeComponentsFromDate:self.endTime];
    return [endDateTime compare:startDateTime] == NSOrderedDescending;
}

- (BOOL)isDateRangeValid
{
    return [self.startTime compare:self.endTime] == NSOrderedDescending;
}

- (void)setStartTime:(NSDate *)startTime
{
//    NSParameterAssert(startTime != nil);
    [self willChangeValueForKey:@"startTime"];
    _startTime = startTime;
    NSUInteger timeframe = (self.eventID && self.eventDuration ? self.eventDuration : self.timeframe);
    self.endTime = [_startTime dateByAddingTimeInterval:timeframe * 60];
    [self didChangeValueForKey:@"startTime"];
}

- (NSDate *)validEndTime
{
    NSUInteger timeframe = (self.eventID && self.eventDuration ? self.eventDuration : self.timeframe);
    return [self.startTime dateByAddingTimeInterval:timeframe * 60];
}

@end
