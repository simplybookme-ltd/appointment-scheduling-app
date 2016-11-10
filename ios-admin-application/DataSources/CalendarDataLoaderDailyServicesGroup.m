//
//  CalendarDataLoaderDailyServicesGroup.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.10.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "CalendarDataLoaderDailyServicesGroup.h"

#import "SBSession.h"
#import "SBRequestsGroup.h"
#import "SBCompanyInfo.h"
#import "SBPluginsRepository.h"
#import "SBPerformer.h"
#import "SBService.h"
#import "SBBooking.h"
#import "CalendarSectionDataSource.h"
#import "SBBookingStatusesCollection.h"
#import "SBWorkingHoursMatrix.h"
#import "SBRequestOperation.h"
#import "SBGetWorkDaysTimesRequest.h"
#import "NSDate+TimeManipulation.h"

@interface CalendarDataLoaderDailyServicesGroup ()
{
    NSMutableSet <NSString *> *pendingRequests;
    SBCompanyInfo *companyInfo;
    NSMutableArray <NSObject <CalendarDataProcessor> *> *dataProcessors;
}

@end

@implementation CalendarDataLoaderDailyServicesGroup

- (instancetype)init
{
    self = [super init];
    if (self) {
        pendingRequests = [NSMutableSet set];
        dataProcessors = [NSMutableArray array];
    }
    return self;
}

- (void)addDataProcessor:(NSObject<CalendarDataProcessor> *)dataProcessor
{
    [dataProcessors addObject:dataProcessor];
}

- (BOOL)recommendsDisplayService
{
    return NO;
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
    
    SBRequest *pluginCheckRequest = [session isPluginActivated:kSBPluginRepositoryGoogleCalendarSyncPlugin callback:^(SBResponse<NSNumber *> * _Nonnull response) {
        if (response.result) {
            [[SBPluginsRepository repository] setPlugin:kSBPluginRepositoryGoogleCalendarSyncPlugin enabled:[response.result boolValue]];
        }
    }];
    [group addRequest:pluginCheckRequest];

    __block NSDictionary *workingHours = nil;
    SBRequest *loadTimeframeRequest = [session getWorkDaysTimesForStartDate:filter.from endDate:[filter.from nextDayDate] type:kSBGetWorkDaysTimesRequest_ServiceType callback:^(SBResponse *response) {
        workingHours = response.result;
    }];
    [group addRequest:loadTimeframeRequest];

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

    NSMutableArray *sections = [NSMutableArray array];
    SBRequest *loadServicesRequest = [session getEventList:^(SBResponse<SBServicesCollection *> * _Nonnull response) {
        [sections removeAllObjects];
        NSPredicate *sectionPredicate = [NSPredicate predicateWithBlock:^BOOL(SBBooking *evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject.eventID isEqualToString:bindings[kCalendarSectionDataSourcePerformerIDBindingKey]];
        }];
        [response.result enumerateUsingBlock:^(NSString * _Nonnull objectID, SBService * _Nonnull service, BOOL * _Nonnull stop) {
            NSDictionary *bindings = @{kCalendarSectionDataSourcePerformerIDBindingKey: objectID};
            CalendarSectionDataSource *section = [[CalendarSectionDataSource alloc] initWithTitle:service.name
                                                                                        predicate:sectionPredicate
                                                                            substitutionVariables:bindings];
            section.sectionID = objectID;
            section.serviceID = objectID;
            section.startDate = filter.from;
            [sections addObject:section];
        }];
    }];
    [group addRequest:loadServicesRequest];

    __block SBBookingStatusesCollection *statuses = nil;
    SBRequest *loadStatusesRequest = [session getStatusesList:^(SBResponse <SBBookingStatusesCollection *> *response) {
        statuses = response.result;
    }];
    [group addRequest:loadStatusesRequest];

    __block NSArray <SBBooking *> *bookings = nil;
    SBRequest *loadBookingsRequest = [[SBSession defaultSession] getBookingsWithFilter:filter callback:^(SBResponse *response) {
        bookings = response.result;
    }];
    loadBookingsRequest.cachePolicy = SBIgnoreCachePolicy;
    [loadBookingsRequest addDependency:loadTimeframeRequest];
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
            SBWorkingHoursMatrix *workingHoursMatrix = [[SBWorkingHoursMatrix alloc] initWithData:workingHours forDate:filter.from];
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

- (void)refreshDataWithFilter:(SBGetBookingsFilter *)filter callback:(void (^)(CalendarDataLoaderResult * _Nonnull))callback
{
    [[SBSession defaultSession] cancelRequests:[pendingRequests allObjects]];
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
