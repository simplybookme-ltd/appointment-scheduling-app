//
//  SBBookingForm.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SBDateRange.h"

@class SBAdditionalField;

@interface SBBookingForm : NSObject

@property (nonatomic, copy, nullable) NSString *bookingID;
@property (nonatomic, copy, readonly, nullable) NSString *eventID;
@property (nonatomic, readonly) NSUInteger eventDuration;
@property (nonatomic, copy, nullable) NSString *unitID;
@property (nonatomic, copy, nullable) NSString *locationID;
@property (nonatomic, copy, nullable) NSDictionary *client;
@property (nonatomic, strong, nullable) NSArray <SBAdditionalField *> *additionalFields;
@property (nonatomic, copy, nullable) NSDate *startDate;
@property (nonatomic, copy, nullable) NSDate *startTime;
@property (nonatomic, copy, nullable) NSDate *endTime;
@property (nonatomic) NSInteger timeframe;
@property (nonatomic, copy, nullable) NSString *comment;

- (void)setEventID:(nullable NSString *)eventID withDuration:(NSUInteger)duration;
- (BOOL)isDateRangeValid;
- (nullable NSDate *)validEndTime;

@end
