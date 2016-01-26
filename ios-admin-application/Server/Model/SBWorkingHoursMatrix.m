//
// Created by Michail Grebionkin on 15.10.15.
// Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBWorkingHoursMatrix.h"
#import "NSDateFormatter+ServerParser.h"
#import "NSDate+TimeManipulation.h"
#import "SBBooking.h"

NSString * const kDefaultWorkHoursRecordID = @"default";

@interface WorkHoursData : NSObject

@property (nonatomic, strong, nonnull) NSDate *start;
@property (nonatomic, strong, nonnull) NSDate *end;
@property (nonatomic, strong, nonnull) NSArray *breaks;
@property (nonatomic, getter=isDayOff) BOOL dayOff;

@end

@interface SBWorkingHoursMatrix ()
{
    NSMutableDictionary <NSObject *, WorkHoursData *> *records;
    NSDate *baseDate;
}

@property (nonatomic, strong, readwrite, nonnull) NSArray <NSDate *> * hours;

@end

@implementation SBWorkingHoursMatrix

- (nullable instancetype)initWithData:(nonnull NSDictionary <NSString *, NSDictionary <NSString *, NSDictionary *> *> *)data
{
    NSParameterAssert(data != nil);
    self = [super init];
    if (self) {
        records = [NSMutableDictionary dictionary];
        [data[kDefaultWorkHoursRecordID] enumerateKeysAndObjectsUsingBlock:^(NSString *dateString, NSDictionary *recordData, BOOL *stop) {
            NSDate *selectedDate = [[NSDateFormatter sb_serverDateFormatter] dateFromString:dateString];
            if (!baseDate) {
                baseDate = selectedDate;
            }
            WorkHoursData *record = [WorkHoursData new];
            record.dayOff = [recordData[@"is_day_off"] boolValue];
            record.start = [self timeFromString:recordData[@"start_time"] baseDate:baseDate];
            record.end = [self timeFromString:recordData[@"end_time"] baseDate:baseDate];
            record.breaks = [self arrayWithDateRangesForBreakTimes:recordData[@"breaktimes"] baseDate:baseDate];
            records[selectedDate] = record;

            if (self.start == nil && ![record isDayOff]) {
                self.start = record.start;
            }
            else {
                NSDate *candidate = [self.start dateByAssigningTimeComponentsFromDate:record.start];
                if ([candidate compare:self.start] == NSOrderedAscending && ![record isDayOff]) {
                    self.start = candidate;
                }
            }
            if (self.end == nil && ![record isDayOff]) {
                self.end = record.end;
            }
            else {
                NSDate *candidate = [self.end dateByAssigningTimeComponentsFromDate:record.end];
                if ([candidate compare:self.end] == NSOrderedDescending && ![record isDayOff]) {
                    self.end = candidate;
                }
            }
        }];
        [self findStartEndTimeInRecordsDefaultRecord:records.allValues.firstObject ignoreRecordsForKeys:@[]
                                            baseDate:baseDate];
        [self calculateHoursWithBaseDate:self.start step:60];
    }
    return self;
}

- (nullable instancetype)initWithData:(nonnull NSDictionary <NSString *, NSDictionary <NSString *, id> *> *)data
                              forDate:(nonnull NSDate *)selectedDate
{
    return [self initWithData:data forDate:selectedDate step:60];
}

- (instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate step:(NSUInteger)minutes
{
    NSParameterAssert(startDate != nil);
    NSParameterAssert(endDate != nil);
    NSParameterAssert(0 < minutes && minutes <= 60);
    self = [super init];
    if (self) {
        self.start = startDate;
        self.end = endDate;
        records = [NSMutableDictionary dictionary];
        [self calculateHoursWithBaseDate:startDate step:minutes];
    }
    return self;
}

- (nullable instancetype)initWithStartDate:(nonnull NSDate *)startDate endDate:(nonnull NSDate *)endDate
{
    return [self initWithStartDate:startDate endDate:endDate step:60];
}

- (instancetype)initWithData:(NSDictionary *)data forDate:(NSDate *)selectedDate step:(NSUInteger)minutes
{
    NSParameterAssert(data != nil);
    NSParameterAssert(selectedDate != nil);
    NSParameterAssert(0 < minutes && minutes <= 60);
    self = [super init];
    if (self) {
        records = [NSMutableDictionary dictionary];
        [data enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary <NSString *, id> *obj, BOOL *stop) {
            /// key = [performer_id_string|default]
            NSString *dateString = [[NSDateFormatter sb_serverDateFormatter] stringFromDate:selectedDate];
            if (!obj[dateString]) {
                return;
            }
            baseDate = selectedDate;
            WorkHoursData *record = [WorkHoursData new];
            NSDictionary *recordData = obj[dateString];
            record.dayOff = [recordData[@"is_day_off"] boolValue];
            record.start = [self timeFromString:recordData[@"start_time"] baseDate:baseDate];
            record.end = [self timeFromString:recordData[@"end_time"] baseDate:baseDate];
            record.breaks = [self arrayWithDateRangesForBreakTimes:recordData[@"breaktimes"] baseDate:baseDate];
            records[key] = record;

            if ((self.start == nil && ![record isDayOff])
                || ([record.start compare:self.start] == NSOrderedAscending && ![record isDayOff])) {
                self.start = record.start;
            }
            if ((self.end == nil && ![record isDayOff])
                || ([record.end compare:self.end] == NSOrderedDescending && ![record isDayOff])) {
                self.end = record.end;
            }
        }];
        if ([records[kDefaultWorkHoursRecordID] isDayOff]) {
            self.start = nil;
            self.end = nil;
            [self findStartEndTimeInRecordsDefaultRecord:records[kDefaultWorkHoursRecordID]
                                    ignoreRecordsForKeys:@[kDefaultWorkHoursRecordID]
                                    baseDate:baseDate];
        }
        [self calculateHoursWithBaseDate:baseDate step:60];
    }
    return self;
}

- (nonnull NSArray *)arrayWithDateRangesForBreakTimes:(nullable NSArray <NSDictionary <NSString *, NSString *> *> *)breakTimes
                                             baseDate:(nonnull NSDate *)_baseDate
{
    if (!breakTimes) {
        return @[];
    }
    NSParameterAssert(_baseDate != nil);
    NSMutableArray *_breakTimes = [NSMutableArray array];
    for (NSDictionary <NSString *, NSString *> *breakTimeData in breakTimes) {
        SBDateRange *breakTime = [SBDateRange new];
        breakTime.start = [self timeFromString:breakTimeData[@"start_time"] baseDate:_baseDate];
        breakTime.end = [self timeFromString:breakTimeData[@"end_time"] baseDate:_baseDate];
        [_breakTimes addObject:breakTime];
    }
    return _breakTimes;
}

- (void)findStartEndTimeInRecordsDefaultRecord:(nonnull WorkHoursData *)defaultRecord ignoreRecordsForKeys:(nonnull NSArray <NSObject *> *)keys
                                      baseDate:(nonnull NSDate *)_baseDate
{
    NSParameterAssert(defaultRecord != nil);
    NSParameterAssert(keys != nil);
    NSParameterAssert(_baseDate != nil);
    [records enumerateKeysAndObjectsUsingBlock:^(NSObject * _Nonnull key, WorkHoursData * _Nonnull record, BOOL * _Nonnull stop) {
        if ([keys containsObject:key] || [record isDayOff]) {
            return ;
        }
        if (self.start == nil) {
            self.start = [_baseDate dateByAssigningTimeComponentsFromDate:record.start];
        }
        else {
            NSDate *candidate = [self.start dateByAssigningTimeComponentsFromDate:record.start];
            if ([candidate compare:self.start] == NSOrderedAscending) {
                self.start = candidate;
            }
        }
        if (self.end == nil) {
            self.end = [_baseDate dateByAssigningTimeComponentsFromDate:record.end];
        }
        else {
            NSDate *candidate = [self.end dateByAssigningTimeComponentsFromDate:record.end];
            if ([candidate compare:self.end] == NSOrderedDescending) {
                self.end = candidate;
            }
        }
    }];
    if (self.start == nil) {
        self.start = [defaultRecord start];
    }
    if (self.end == nil) {
        self.end = [defaultRecord end];
    }
}

- (void)calculateHoursWithBaseDate:(nonnull NSDate *)_baseDate step:(NSUInteger)minutes
{
    NSParameterAssert(_baseDate != nil);
    NSParameterAssert(0 < minutes && minutes <= 60);
    NSAssert(self.start != nil, @"can't calculate hours between %@ and %@", self.start, self.end);
    NSAssert(self.end != nil, @"can't calculate hours between %@ and %@", self.start, self.end);
    NSCalendar *calendar = [NSDate sb_calendar];
    NSInteger start = [calendar component:NSCalendarUnitHour fromDate:self.start];
    NSInteger end = [calendar component:NSCalendarUnitHour fromDate:self.end];
    if (end == 0) {
        end = 23;
    }
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                   fromDate:_baseDate];
    NSMutableArray *hours = [NSMutableArray array];
    for (NSInteger i = start; i <= end; i++) {
        for (NSInteger step = 0; step * minutes < 60; ++step) {
            NSDateComponents *components = [NSDateComponents new];
            components.year = dateComponents.year;
            components.month = dateComponents.month;
            components.day = dateComponents.day;
            components.hour = i;
            components.minute = step * minutes;
            components.second = 0;
            components.timeZone = [NSDateFormatter sb_serverTimeFormatter].timeZone;
            NSDate *sectionDate = [calendar dateFromComponents:components];
            [hours addObject:sectionDate];
        }
    }
    self.hours = [hours sortedArrayUsingComparator:^(NSDate *date1, NSDate *date2) {
        return [date1 compare:date2];
    }];
}

- (nonnull NSDate *)timeFromString:(nonnull NSString *)endTimeString baseDate:(nonnull NSDate *)_baseDate
{
    NSParameterAssert(endTimeString != nil);
    NSParameterAssert(_baseDate != nil);
    if ([endTimeString hasPrefix:@"24"]) { // 24 hours is not valid time value. it is actually next day. so use 23 hours value as end of the day
        NSString *endDayString = [endTimeString stringByReplacingOccurrencesOfString:@"24" withString:@"23"
                                                                             options:0 range:NSMakeRange(0, [@"24" length])];
        NSDate *time = [[NSDateFormatter sb_serverTimeFormatter] dateFromString:endDayString];
        return [_baseDate dateByAssigningTimeComponentsFromDate:time];
    }
    NSDate *time = [[NSDateFormatter sb_serverTimeFormatter] dateFromString:endTimeString];
    return [_baseDate dateByAssigningTimeComponentsFromDate:time];
}

- (void)updateDatesUsingBookingsInfo:(nonnull NSArray <SBBooking *> *)bookings
{
    NSParameterAssert(bookings != nil);
    [bookings enumerateObjectsUsingBlock:^(SBBooking *booking, NSUInteger idx, BOOL *stop) {
        if (self.start == nil) {
            self.start = booking.startDate;
        }
        else {
            NSCalendar *calendar = [NSDate sb_calendar];
            NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                       fromDate:self.start];
            components.hour = [calendar component:NSCalendarUnitHour fromDate:booking.startDate];
            NSDate *candidate = [calendar dateFromComponents:components];
            if ([candidate compare:self.start] == NSOrderedAscending) {
                self.start = candidate;
            }
        }
        if (self.end == nil) {
            self.end = booking.endDate;
        }
        else {
            NSCalendar *calendar = [NSDate sb_calendar];
            NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                       fromDate:self.end];
            components.hour = [calendar component:NSCalendarUnitHour fromDate:booking.endDate];
            NSDate *candidate = [calendar dateFromComponents:components];
            if ([candidate compare:self.end] == NSOrderedDescending) {
                self.end = candidate;
            }
        }
    }];
    [self calculateHoursWithBaseDate:baseDate step:60];
}

- (BOOL)isDayOff {
    return [records[kDefaultWorkHoursRecordID] isDayOff];
}

- (BOOL)isDayOffForRecordWithID:(NSObject *)recordID {
    NSParameterAssert(recordID != nil);
    if (!records[recordID]) {
        return [self isDayOff];
    }
    return [records[recordID] isDayOff];
}

- (nonnull NSArray <SBDateRange *> *)breaksForRecordWithID:(NSObject *)recordID {
    NSParameterAssert(recordID != nil);
    if (!records[recordID]) {
        return [records[kDefaultWorkHoursRecordID] breaks];
    }
    return [records[recordID] breaks];
}

- (nonnull NSDate *)startTimeForRecordWithID:(NSObject *)recordID {
    NSParameterAssert(recordID != nil);
    if (!records[recordID]) {
        return [records[kDefaultWorkHoursRecordID] start];
    }
    return [records[recordID] start];
}

- (nonnull NSDate *)endTimeForRecordWithID:(NSObject *)recordID {
    NSParameterAssert(recordID != nil);
    if (!records[recordID]) {
        return [records[kDefaultWorkHoursRecordID] end];
    }
    return [records[recordID] end];
}

@end

@implementation WorkHoursData

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    if ([self isDayOff]) {
        [description appendString:@"Day Off"];
    }
    else {
        [description appendFormat:@"Start: %@; End: %@; Breaks: ", self.start, self.end];
        [description appendString:[self.breaks description]];
    }
    [description appendString:@">"];
    return description;
}

@end
