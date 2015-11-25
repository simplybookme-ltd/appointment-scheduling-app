//
//  CalendarSectionDataSource.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBBooking.h"

NS_ASSUME_NONNULL_BEGIN

@class SBNewBookingPlaceholder;

extern NSString * const kCalendarSectionDataSourcePerformerIDBindingKey;

@interface CalendarSectionDataSource : NSObject

@property (nonatomic, strong, readonly) NSArray <NSObject <SBBookingProtocol> *> * items;
@property (nonatomic, strong, readonly) NSString * title;
@property (nonatomic, strong, nullable) NSObject *sectionID;

- (nullable instancetype)initWithTitle:(NSString *)sectionTitle
                             predicate:(NSPredicate *)predicate
                 substitutionVariables:(nullable NSDictionary <NSString *, id> *)bindings;
- (void)addBooking:(NSObject <SBBookingProtocol> *)booking;
- (void)addBookings:(NSArray <NSObject <SBBookingProtocol> *> *)bookings;
- (void)addNewBookingPlaceholder:(SBNewBookingPlaceholder *)placeholder;
- (void)removeNewBookingPlaceholder;
- (void)resetBookings;

@end

NS_ASSUME_NONNULL_END
