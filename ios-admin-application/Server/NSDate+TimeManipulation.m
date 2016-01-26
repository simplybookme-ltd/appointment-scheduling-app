//
//  NSDate+TimeManipulation.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "NSDate+TimeManipulation.h"
#import <objc/runtime.h>

static void * SB_NSDate_zeroTimeDateProperkyKey = &SB_NSDate_zeroTimeDateProperkyKey;

@implementation NSDate (TimeManipulation)

+ (NSCalendar *)sb_calendar
{
    static NSCalendar *sb_calendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sb_calendar = [NSCalendar currentCalendar];
    });
    return sb_calendar;
}

- (NSDate *)dateByAssigningTimeComponentsFromDate:(NSDate *)timeSourceDate
{
    NSParameterAssert(timeSourceDate != nil);
    NSCalendar *calendar = [[self class] sb_calendar];
    NSDateComponents *timeComponents = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:timeSourceDate];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:self];
    dateComponents.hour = timeComponents.hour;
    dateComponents.minute = timeComponents.minute;
    return [calendar dateFromComponents:dateComponents];
}

- (NSDate *)dateWithZeroTime
{
    NSDate *zeroTimeDate = objc_getAssociatedObject(self, SB_NSDate_zeroTimeDateProperkyKey);
    if (!zeroTimeDate) {
        NSCalendar *calendar = [[self class] sb_calendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:self];
        zeroTimeDate = [calendar dateFromComponents:components];
        objc_setAssociatedObject(self, SB_NSDate_zeroTimeDateProperkyKey, zeroTimeDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return zeroTimeDate;
}

- (NSDate *)nextDayDate
{
    NSDateComponents *components = [NSDateComponents new];
    components.day = 1;
    return [[[self class] sb_calendar] dateByAddingComponents:components toDate:self options:0];
}

- (NSDate *)timeDate
{
    NSCalendar *calendar = [[self class] sb_calendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:self];
    components.year = 2000;
    components.month = 1;
    components.day = 1;
    return [calendar dateFromComponents:components];
}

- (BOOL)isToday
{
    NSDateComponents *selfComponents = [[[self class] sb_calendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                                     fromDate:self];
    NSDateComponents *todayComponents = [[[self class] sb_calendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                                      fromDate:[NSDate date]];
    return selfComponents.year == todayComponents.year
            && selfComponents.month == todayComponents.month
            && selfComponents.day == todayComponents.day;
}

@end
