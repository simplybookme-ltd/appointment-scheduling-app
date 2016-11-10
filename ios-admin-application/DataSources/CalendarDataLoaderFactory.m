//
//  CalendarDataLoader.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.10.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "CalendarDataLoaderFactory.h"
#import "CalendarDataLoaderDailyServicesGroup.h"
#import "CalendarDataLoaderDailyPerformersGroup.h"
#import "CalendarDataLoaderWeeklyGroup.h"

NSString * const kCalendarDataLoader_DailyServicesGroupType = @"kCalendarDataLoader_DailyServicesGroupType";
NSString * const kCalendarDataLoader_DailyPerformersGroupType = @"kCalendarDataLoader_DailyPerformersGroupType";
NSString * const kCalendarDataLoader_WeeklyGroupType = @"kCalendarDataLoader_WeeklyGroupType";

@implementation CalendarDataLoaderFactory

+ (NSObject<CalendarDataLoader> *)dataLoaderForType:(NSString *)type
{
    NSParameterAssert(type != nil);
    NSParameterAssert(([@[kCalendarDataLoader_DailyServicesGroupType, kCalendarDataLoader_DailyPerformersGroupType, kCalendarDataLoader_WeeklyGroupType] containsObject:type]));
    if ([type isEqualToString:kCalendarDataLoader_DailyPerformersGroupType]) {
        return [[CalendarDataLoaderDailyPerformersGroup alloc] init];
    }
    if ([type isEqualToString:kCalendarDataLoader_WeeklyGroupType]) {
        return [[CalendarDataLoaderWeeklyGroup alloc] init];
    }
    if ([type isEqualToString:kCalendarDataLoader_DailyServicesGroupType]) {
        return [[CalendarDataLoaderDailyServicesGroup alloc] init];
    }
    NSAssert(NO, @"unexpected data loader type: %@", type);
    return nil;
}

@end

#pragma mark -

@implementation CalendarDataLoaderResult

- (instancetype)initWithError:(NSError *)error
{
    NSParameterAssert(error != nil);
    self = [super init];
    if (self) {
        self.error = error;
    }
    return self;
}

@end
