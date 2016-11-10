//
//  CalendarDataLoaderFactory.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.10.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBBooking.h"
#import "SBPerformer.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kCalendarDataLoader_DailyPerformersGroupType;
extern NSString * const kCalendarDataLoader_DailyServicesGroupType;
extern NSString * const kCalendarDataLoader_WeeklyGroupType;

@class SBGetBookingsFilter;
@class SBWorkingHoursMatrix;
@class CalendarSectionDataSource;
@class SBBookingStatusesCollection;

@interface CalendarDataLoaderResult: NSObject

@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, strong, nullable) SBWorkingHoursMatrix *workingHoursMatrix;
@property (nonatomic, strong, nullable) NSArray <CalendarSectionDataSource *> *sections;
@property (nonatomic, strong, nullable) NSArray <SBBookingObject *> *bookings;
@property (nonatomic) NSTimeInterval timeframeStep;
@property (nonatomic, strong, nullable) SBPerformersCollection *performers;
@property (nonatomic, strong, nullable) SBBookingStatusesCollection *statuses;

- (instancetype)initWithError:(NSError *)error;

@end

@protocol CalendarDataProcessor <NSObject>

- (void)process:(CalendarDataLoaderResult *)result;

@end

@protocol CalendarDataLoader <NSObject>

@property (nonatomic, readonly) BOOL recommendsDisplayPerformer;
@property (nonatomic, readonly) BOOL recommendsDisplayService;

- (void)loadDataWithFilter:(SBGetBookingsFilter *)filter callback:(void (^)(CalendarDataLoaderResult *result))callback;
- (void)refreshDataWithFilter:(SBGetBookingsFilter *)filter callback:(void (^)(CalendarDataLoaderResult *result))callback;
- (BOOL)isLoading;
- (void)cancelLoading;
- (void)addDataProcessor:(NSObject <CalendarDataProcessor> *)dataProcessor;

@end

@interface CalendarDataLoaderFactory : NSObject

+ (nullable NSObject<CalendarDataLoader> *)dataLoaderForType:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
