//
//  SBGetBookingsFilter.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SBDateRange;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSBGetBookingsFilterOrderByRecordDate;
extern NSString * const kSBGetBookingsFilterOrderByStartDate;
extern NSString * const kSBGetBookingsFilterOrderByStartDateAsc;

@interface SBGetBookingsFilter : NSObject <NSCopying>

@property (nonatomic, copy, nullable) NSDate *from;
@property (nonatomic, copy, nullable) NSDate *to;
@property (nonatomic, copy, nullable) NSDate *createdFrom;
@property (nonatomic, copy, nullable) NSDate *createdTo;
@property (nonatomic, copy, nullable) NSString *unitGroupID;
@property (nonatomic, copy, nullable) NSString *eventID;
@property (nonatomic, copy, nullable) NSNumber *clientID;
@property (nonatomic, copy, nullable) NSNumber *upcomingOnly;
@property (nonatomic, copy, nullable) NSString *order;
@property (nonatomic, copy, nullable) NSNumber *limit;
@property (nonatomic, copy) NSNumber *bookingType;

+ (nullable instancetype)todayBookingsFilter;
+ (nullable instancetype)bookingFilterWithDateRange:(SBDateRange *)dateRange;

- (NSDictionary *)encodedObject;
- (void)reset;

- (NSUInteger)numberOfBookingTypeOptions;
- (NSString *)titleForBookingTypeOptionAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
