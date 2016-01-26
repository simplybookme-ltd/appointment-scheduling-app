//
//  SBBookingFormHoursSelectorDataSource.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 10.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SBWorkingHoursMatrix;

@interface SBBookingFormHoursSelectorDataSource : NSObject <UIPickerViewDataSource>

@property (nonatomic, strong, readonly, nullable) SBWorkingHoursMatrix *workingHoursMatrix;
@property (nonatomic, strong, readonly, nullable) NSObject *recordID;
@property (nonatomic, strong, readonly, nullable) NSArray *hours;
@property (nonatomic, strong, nullable) NSDateFormatter *timeFormatter;
@property (nonatomic) NSUInteger timeFrameStep;

- (void)setWorkingHoursMatrix:(nullable SBWorkingHoursMatrix *)matrix recordID:(NSObject *)recordID;
- (void)setStartHoursModeWithStartHour:(NSDate *)startHour;
- (void)setEndHoursModeWithEndHour:(NSDate *)endHour;
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component;

@end

NS_ASSUME_NONNULL_END
