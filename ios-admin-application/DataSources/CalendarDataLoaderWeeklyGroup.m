//
//  CalendarDataLoaderWeeklyGroup.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.10.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "CalendarDataLoaderWeeklyGroup.h"
#import "SBSession.h"
#import "SBRequestsGroup.h"
#import "SBCompanyInfo.h"
#import "SBPluginsRepository.h"
#import "SBPerformer.h"
#import "CalendarSectionDataSource.h"
#import "SBBookingStatusesCollection.h"
#import "SBWorkingHoursMatrix.h"
#import "SBRequestOperation.h"
#import "NSDate+TimeManipulation.h"
#import "SBGetWorkDaysTimesRequest.h"

@interface CalendarDataLoaderWeeklyGroup()
{
    NSMutableSet <NSString *> *pendingRequests;
    SBCompanyInfo *companyInfo;
    NSMutableArray <NSObject <CalendarDataProcessor> *> *dataProcessors;
}

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation CalendarDataLoaderWeeklyGroup

- (instancetype)init
{
    self = [super init];
    if (self) {
        pendingRequests = [NSMutableSet set];
        dataProcessors = [NSMutableArray array];
    }
    return self;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEdM" options:0 locale:[NSLocale currentLocale]];
    }
    return _dateFormatter;
}

- (void)addDataProcessor:(NSObject<CalendarDataProcessor> *)dataProcessor
{
    [dataProcessors addObject:dataProcessor];
}

- (BOOL)recommendsDisplayService
{
    return YES;
}

- (BOOL)recommendsDisplayPerformer
{
    return YES;
}

- (void)loadDataWithFilter:(SBGetBookingsFilter *)filter callback:(void (^)(CalendarDataLoaderResult *result))callback
{
    NSParameterAssert(filter != nil);
    NSAssert(filter.from != nil, @"filter configuration fail: no date selected");

    SBSession *session = [SBSession defaultSession];
    [session cancelRequests:[pendingRequests allObjects]];
    NSAssert(session != nil, @"no active session");

    SBRequestsGroup *group = [SBRequestsGroup new];

    __block NSInteger timeframeStep = 0;
    SBRequest *loadCompanyInfoRequest = [session getCompanyInfoWithCallback:^(SBResponse *response) {
        companyInfo = response.result;
        timeframeStep = [companyInfo.timeframe integerValue];
    }];
    [group addRequest:loadCompanyInfoRequest];

    __block NSDictionary *workingHours = nil;
    SBRequest *loadTimeFrameRequest = [session getWorkDaysTimesForStartDate:filter.from
                                                                    endDate:[filter.to nextDayDate]
                                                                       type:kSBGetWorkDaysTimesRequest_DefaultType
                                                                   callback:^(SBResponse *response) {
                                                                       workingHours = response.result;
                                                                   }];
    [group addRequest:loadTimeFrameRequest];

    NSMutableArray *sections = [NSMutableArray array];
    NSCalendar *calendar = [NSDate sb_calendar];
    NSDateComponents *components = [NSDateComponents new];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEdM" options:0 locale:[NSLocale currentLocale]];
    for (NSInteger day = 0; day < 7; day++) {
        components.day = day + [calendar component:NSCalendarUnitDay fromDate:filter.from];
        components.month = [calendar component:NSCalendarUnitMonth fromDate:filter.from];
        components.year = [calendar component:NSCalendarUnitYear fromDate:filter.from];
        NSDate *date = [calendar dateFromComponents:components];
        components.day = 1;
        components.month = 0;
        components.year = 0;
        NSDate *nextDate = [calendar dateByAddingComponents:components toDate:date options:0];
        NSPredicate *sectionPredicate = [NSPredicate predicateWithBlock:^BOOL(SBBookingObject *booking, NSDictionary *bindings) {
            return ([booking.startDate compare:date] >= NSOrderedSame && [booking.startDate compare:nextDate] == NSOrderedAscending)
            || ([booking.startDate compare:date] == NSOrderedAscending && [booking.endDate compare:date] == NSOrderedDescending);
        }];
        CalendarSectionDataSource *section = [[CalendarSectionDataSource alloc] initWithTitle:[dateFormatter stringFromDate:date]
                                                                                    predicate:sectionPredicate
                                                                        substitutionVariables:nil];
        section.sectionID = date;
        section.startDate = date;
        [sections addObject:section];
    }

    __block SBBookingStatusesCollection *statuses = nil;
    SBRequest *loadStatusesRequest = [session getStatusesList:^(SBResponse *response) {
        statuses = response.result;
    }];
    [group addRequest:loadStatusesRequest];

    __block SBPerformersCollection *performers = nil;
    SBRequest *loadPerformersRequest = [session getUnitList:^(SBResponse<SBPerformersCollection *> *response) {
        SBUser *user = [SBSession defaultSession].user;
        NSAssert(user != nil, @"no user found");
        if ([user hasAccessToACLRule:SBACLRulePerformersFullListAccess]) {
            performers = response.result;
        } else {
            NSAssert(user.associatedPerformerID != nil && ![user.associatedPerformerID isEqualToString:@""], @"invalid associated performer value");
            performers = [response.result collectionWithObjectsPassingTest:^BOOL(SBPerformer * _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
                *stop = [object.performerID isEqualToString:user.associatedPerformerID];
                return *stop;
            }];
        }
    }];
    [group addRequest:loadPerformersRequest];

    __block NSArray <SBBooking *> *bookings = nil;
    SBRequest *loadBookingsRequest = [[SBSession defaultSession] getBookingsWithFilter:filter callback:^(SBResponse *response) {
        bookings = response.result;
    }];
    loadBookingsRequest.cachePolicy = SBIgnoreCachePolicy;
    [loadBookingsRequest addDependency:loadTimeFrameRequest];
    [loadBookingsRequest addDependency:loadStatusesRequest];
    [group addRequest:loadBookingsRequest];

    group.callback = ^(SBResponse *response) {
        [pendingRequests removeObject:response.requestGUID];
        if (response.error) {
            if ([response isCanceled]) {
                NSError *error = [NSError errorWithDomain:SBServerErrorDomain code:SBUserCancelledErrorCode
                                                 userInfo:@{SBServerMessageKey: NSLS(@"Cancelled by user.",@"")}];
                callback([[CalendarDataLoaderResult alloc] initWithError:error]);
            } else {
                callback([[CalendarDataLoaderResult alloc] initWithError:response.error]);
            }
        } else {
            SBWorkingHoursMatrix *workingHoursMatrix = [[SBWorkingHoursMatrix alloc] initWithData:workingHours];
            if (!workingHours || [workingHours count] == 0) {
                NSError *error = [NSError errorWithDomain:SBServerErrorDomain code:SBUnexpectedServerResponseErrorCode
                                                 userInfo:@{SBServerMessageKey: NSLS(@"Unexpected responce from server. Please try to reload data.",@"")}];
                callback([[CalendarDataLoaderResult alloc] initWithError:error]);
            } else {
                [workingHoursMatrix updateDatesUsingBookingsInfo:bookings];
                CalendarDataLoaderResult *result = [[CalendarDataLoaderResult alloc] init];
                result.workingHoursMatrix = workingHoursMatrix;
                result.bookings = bookings;
                result.sections = sections;
                result.timeframeStep = timeframeStep;
                result.performers = performers;
                result.statuses = statuses;
                NSArray <NSObject <CalendarDataProcessor> *> *processors = [NSArray arrayWithArray:dataProcessors];
                [processors enumerateObjectsUsingBlock:^(NSObject<CalendarDataProcessor> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [obj process:result];
                }];
                callback(result);
            }
        }
    };
    [pendingRequests addObject:group.GUID];
    [session performReqeust:group];
}

- (void)refreshDataWithFilter:(SBGetBookingsFilter *)filter callback:(void (^)(CalendarDataLoaderResult *result))callback
{
    SBSession *session = [SBSession defaultSession];
    [session cancelRequests:[pendingRequests allObjects]];
    NSAssert(session != nil, @"no active session");
    SBRequest *request = [[SBSession defaultSession] getBookingsWithFilter:filter callback:^(SBResponse *response) {
        [pendingRequests removeObject:response.requestGUID];
        if (response.error) {
            if ([response isCanceled]) {
                NSError *error = [NSError errorWithDomain:SBServerErrorDomain code:SBUserCancelledErrorCode
                                                 userInfo:@{SBServerMessageKey: NSLS(@"Cancelled by user.",@"")}];
                callback([[CalendarDataLoaderResult alloc] initWithError:error]);
            } else {
                callback([[CalendarDataLoaderResult alloc] initWithError:response.error]);
            }
        } else {
            CalendarDataLoaderResult *result = [[CalendarDataLoaderResult alloc] init];
            result.bookings = response.result;
            NSArray <NSObject <CalendarDataProcessor> *> *processors = [NSArray arrayWithArray:dataProcessors];
            [processors enumerateObjectsUsingBlock:^(NSObject<CalendarDataProcessor> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj process:result];
            }];
            callback(result);
        }
    }];
    request.cachePolicy = SBIgnoreCachePolicy;
    [pendingRequests addObject:request.GUID];
    [[SBSession defaultSession] performReqeust:request];
}

- (BOOL)isLoading
{
    return [pendingRequests count] > 0;
}

- (void)cancelLoading
{
    SBSession *session = [SBSession defaultSession];
    [session cancelRequests:[pendingRequests allObjects]];
}

@end
