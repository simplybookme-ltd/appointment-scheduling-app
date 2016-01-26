//
//  CalendarSectionDataSource.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 28.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarSectionDataSource.h"
#import "SBNewBookingPlaceholder.h"

NSString * _Nonnull const kCalendarSectionDataSourcePerformerIDBindingKey = @"kCalendarSectionDataSourcePerformerIDBindingKey";

@interface CalendarSectionDataSource ()

@property (nonatomic, strong, nullable) NSMutableArray <NSObject <SBBookingProtocol> *> * _items;
@property (nonatomic, strong, readwrite, nonnull) NSString * title;
@property (nonatomic, strong, nonnull) NSPredicate * predicate;
@property (nonatomic, strong, nullable) NSDictionary <NSString *, id> * bindings;
@property (nonatomic) NSInteger indexOfNewBookingPlaceholder;

@end

@implementation CalendarSectionDataSource

- (nullable instancetype)initWithTitle:(nonnull NSString *)sectionTitle
                             predicate:(nonnull NSPredicate *)predicate
                 substitutionVariables:(nullable NSDictionary <NSString *, id> *)bindings
{
    NSParameterAssert(sectionTitle != nil);
    NSParameterAssert(predicate != nil);
    self = [super init];
    if (self) {
        self._items = [NSMutableArray array];
        self.title = sectionTitle;
        self.predicate = predicate;
        self.bindings = bindings;
        self.indexOfNewBookingPlaceholder = NSNotFound;
    }
    return self;
}

- (nonnull NSArray *)items
{
    return self._items;
}

- (void)addBookings:(nonnull NSArray <NSObject <SBBookingProtocol> *> *)bookings
{
    NSParameterAssert(bookings != nil);
    [bookings enumerateObjectsUsingBlock:^(NSObject <SBBookingProtocol> *obj, NSUInteger idx, BOOL *stop) {
        [self addBooking:obj];
    }];
}

- (void)addBooking:(nonnull NSObject <SBBookingProtocol> *)booking
{
    NSParameterAssert(booking != nil);
    NSParameterAssert(self.predicate != nil);
    if ([self.predicate evaluateWithObject:booking substitutionVariables:self.bindings]) {
        [self._items addObject:booking];
    }
}

- (void)addNewBookingPlaceholder:(nonnull SBNewBookingPlaceholder *)placeholder
{
    NSParameterAssert(placeholder != nil);
    NSAssert(placeholder.startDate != nil, @"Can't add new booking placeholder without start date");
    NSAssert(placeholder.endDate != nil, @"Can't add new booking placeholder without end date");
    [self._items addObject:placeholder];
    self.indexOfNewBookingPlaceholder = self._items.count - 1;
}

- (void)removeNewBookingPlaceholder
{
    if (self.indexOfNewBookingPlaceholder != NSNotFound && self.indexOfNewBookingPlaceholder < self._items.count) {
        [self._items removeObjectAtIndex:self.indexOfNewBookingPlaceholder];
        self.indexOfNewBookingPlaceholder = NSNotFound;
    }
    else if (self.indexOfNewBookingPlaceholder >= self._items.count) {
        self.indexOfNewBookingPlaceholder = NSNotFound;
    }
}

- (void)resetBookings
{
    [self._items removeAllObjects];
}

@end
