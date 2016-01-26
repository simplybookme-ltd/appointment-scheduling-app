//
//  NSDate+TimeManipulation.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (TimeManipulation)

+ (NSCalendar *)sb_calendar;
- (NSDate *)dateByAssigningTimeComponentsFromDate:(NSDate *)timeSourceDate;
- (NSDate *)dateWithZeroTime;
- (NSDate *)nextDayDate;
- (NSDate *)timeDate;
- (BOOL)isToday;

@end
