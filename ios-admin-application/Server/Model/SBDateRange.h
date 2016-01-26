//
//  SBDateRange.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 06.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SBDateRange : NSObject

@property (nonatomic, copy, nullable) NSDate *start;
@property (nonatomic, copy, nullable) NSDate *end;

+ (nullable instancetype)dateRangeWithStart:(nullable NSDate *)start end:(nullable NSDate *)end;

- (BOOL)containsDate:(NSDate *)date;
- (BOOL)isEmpty;

@end

NS_ASSUME_NONNULL_END
