//
// Created by Michail Grebionkin on 15.10.15.
// Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBDateRange.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSBWorkingHoursMatrixDefaultRecordID;

@class SBBooking;

@interface SBWorkingHoursMatrix : NSObject

@property (nonatomic, strong, nullable) NSDate *start;
@property (nonatomic, strong, nullable) NSDate *end;
@property (nonatomic, strong, readonly) NSArray <NSDate *> * hours;

/**
 * Calculates `start` and `end` values and breaktimes from server response data. Group records by date.
 * Calculates `hours` list using first date in data as base date.
 */
- (nullable instancetype)initWithData:(nonnull NSDictionary <NSString *, NSDictionary <NSString *, NSDictionary *> *> *)data;

/**
 * Calculates `start` and `end` values and breaktimes from server response data but only for `selectedDate`.
 * Group records by performer ID string. Calculates `hours` list using `selectedDate` as base date.
 *
 * Convenience constructor. Uses `-initWithData:forDate:step:` with 60 minutes for step value.
 */
- (nullable instancetype)initWithData:(NSDictionary *)data forDate:(NSDate *)selectedDate;

/**
 * Calculates `start` and `end` values and breaktimes from server response data but only for `selectedDate`.
 * Group records by performer ID string. Calculates `hours` list using `selectedDate` as base date and step.
 */
- (nullable instancetype)initWithData:(NSDictionary *)data forDate:(NSDate *)selectedDate step:(NSUInteger)minutes;

/**
 * Convenience constructor. Uses `-initWithStartDate:endDate:step:` with 60 minutes for step value.
 */
- (nullable instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

/**
 * Calculates `start` and `end` values from `startDate` to `endDate`. Only default group calculated.
 * No breaktimes calculated. Calculates `hours` list using `startDate` as base date.
 */
- (nullable instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate
                                      step:(NSUInteger)minutes;

- (void)updateDatesUsingBookingsInfo:(NSArray <SBBooking *> *)bookings;
- (BOOL)isDayOff;
- (BOOL)isDayOffForRecordWithID:(NSObject *)recordID;
- (NSArray <SBDateRange *> *)breaksForRecordWithID:(NSObject *)recordID;
- (NSDate *)startTimeForRecordWithID:(NSObject *)recordID;
- (NSDate *)endTimeForRecordWithID:(NSObject *)recordID;

@end

NS_ASSUME_NONNULL_END