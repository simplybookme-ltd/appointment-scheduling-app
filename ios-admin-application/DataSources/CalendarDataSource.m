//
//  CalendarDataSource.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 14.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarDataSource.h"
#import "BookingCollectionViewCell.h"
#import "TextCollectionReusableView.h"
#import "SBNewBookingPlaceholder.h"
#import "NewBookingPlaceholderCollectionViewCell.h"
#import "UITraitCollection+SimplyBookLayout.h"
#import "UIColor+SimplyBookColors.h"
#import "SBWorkingHoursMatrix.h"
#import "CalendarSectionDataSource.h"
#import "SBBookingStatusesCollection.h"
#import "SBPerformer.h"
#import "SBCollection.h"

NSString * const _Nonnull kCalendarDataSourceTimeframeElementKind = @"kCalendarDataSourceTimeframeElementKind";
NSString * const _Nonnull kCalendarDataSourceGoogleBusyTimeElementKind = @"kCalendarDataSourceGoogleBusyTimeElementKind";

NSString * const _Nonnull kCalendarGridSectionHeaderReuseIdentifier = @"kCalendarGridSectionHeaderReuseIdentifier";
NSString * const _Nonnull kCalendarListSectionHeaderReuseIdentifier = @"kCalendarListSectionHeaderReuseIdentifier";

@interface CalendarDataSource ()

@property (nonatomic, strong) NSDateFormatter *timeFrameFormatter;
@property (nonatomic, strong) NSDateIntervalFormatter *intervalFormatter;
@property (nonatomic, readwrite) NSCalendar *calendar;
@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite, nullable) SBBookingStatusesCollection *statuses;
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSObject *, NSArray<NSDictionary *> *> * _googleCalendarBusyTime;

@end

@implementation CalendarDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        self._googleCalendarBusyTime = [NSMutableDictionary dictionary];
    }
    return self;
}

- (nonnull NSDateFormatter *)timeFrameFormatter
{
    if (_timeFrameFormatter) {
        return _timeFrameFormatter;
    }
    NSString *format = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    const BOOL is24HousFormat = ([format rangeOfString:@"a"].location == NSNotFound);
    _timeFrameFormatter = [NSDateFormatter new];
    [_timeFrameFormatter setDateFormat: (is24HousFormat ? @"HH:mm" : @"h a")];
    return _timeFrameFormatter;
}

- (nonnull NSDateIntervalFormatter *)intervalFormatter
{
    if (_intervalFormatter) {
        return _intervalFormatter;
    }
    _intervalFormatter = [NSDateIntervalFormatter new];
    [_intervalFormatter setDateStyle:NSDateIntervalFormatterNoStyle];
    [_intervalFormatter setTimeStyle:NSDateIntervalFormatterShortStyle];
    return _intervalFormatter;
}

- (nonnull NSCalendar *)calendar
{
    if (_calendar) {
        return _calendar;
    }
    _calendar = [NSCalendar currentCalendar];
    return _calendar;
}

- (NSDictionary<NSObject *,NSArray<NSDictionary *> *> *)googleCalendarBusyTime
{
    return self._googleCalendarBusyTime;
}

#pragma mark -

- (void)setGoogleCalendarBusyTime:(NSArray<NSDictionary *> * _Nonnull)googleCalendarBusyTime forSectionID:(NSObject<NSCopying> *)sectionID
{
    NSParameterAssert(googleCalendarBusyTime != nil);
    if (googleCalendarBusyTime) {
        self._googleCalendarBusyTime[sectionID] = googleCalendarBusyTime;
    }
}

- (void)setWorkingHoursMatrix:(nonnull SBWorkingHoursMatrix *)workingHoursMatrix
{
    NSParameterAssert(workingHoursMatrix != nil);
    NSAssert(workingHoursMatrix.start != nil, @"invalid working hours. no start time.");
    NSAssert(workingHoursMatrix.end != nil, @"invalid working hours. no end time.");
    _workingHoursMatrix = workingHoursMatrix;
}

- (void)setBookings:(nonnull NSArray <SBBookingObject *> *)bookings sortingStrategy:(nullable NSComparator)sortingStrategy;
{
    NSParameterAssert(bookings != nil);
    NSArray *_bookings = (sortingStrategy ? [bookings sortedArrayUsingComparator:sortingStrategy] : bookings);
    [self.sections enumerateObjectsUsingBlock:^(CalendarSectionDataSource *section, NSUInteger idx, BOOL *stop) {
        [section resetBookings];
        [section addBookings:_bookings];
    }];
}

- (void)setStatusesCollection:(SBBookingStatusesCollection *)statuses
{
    NSParameterAssert(statuses != nil);
    self.statuses = statuses;
}

- (void)configureCollectionView:(nonnull UICollectionView *)collectionView
{
    NSParameterAssert(collectionView != nil);
    self.collectionView = collectionView;
    [self.collectionView registerNib:[UINib nibWithNibName:@"BookingCollectionViewCell" bundle:nil]
          forCellWithReuseIdentifier:@"cell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"NewBookingPlaceholderCollectionViewCell" bundle:nil]
          forCellWithReuseIdentifier:@"placeholder"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"TextCollectionReusableView" bundle:nil]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:kCalendarGridSectionHeaderReuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"TextCollectionReusableView" bundle:nil]
          forSupplementaryViewOfKind:kCalendarDataSourceTimeframeElementKind
                 withReuseIdentifier:kCalendarDataSourceTimeframeElementKind];
    [self.collectionView registerNib:[UINib nibWithNibName:@"TextCollectionReusableView" bundle:nil]
          forSupplementaryViewOfKind:kCalendarDataSourceGoogleBusyTimeElementKind
                 withReuseIdentifier:kCalendarDataSourceGoogleBusyTimeElementKind];
}

- (nullable NSObject<SBBookingProtocol> *)bookingAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    if (indexPath.section >= self.sections.count) {
        return nil;
    }
    if (indexPath.item >= self.sections[indexPath.section].items.count) {
        return nil;
    }
    return self.sections[indexPath.section].items[indexPath.item];
}

- (nonnull NSArray <NSObject<SBBookingProtocol> *> *)bookingsForSection:(NSUInteger)section
{
    NSAssert(section < self.sections.count, @"trying to access section with index %ld while data source contains only %lu sections", (unsigned long)section, (unsigned long)self.sections.count);
    return self.sections[section].items;
}

#pragma mark -

- (void)addNewBookingPlaceholder:(nonnull SBNewBookingPlaceholder *)placeholder forSection:(NSUInteger)section
{
    NSParameterAssert(placeholder != nil);
    NSParameterAssert(section < self.sections.count);
    [self clearNewBookingPlaceholderAtIndexPath];
    [self.sections[section] addNewBookingPlaceholder:placeholder];
    [self.collectionView reloadData];
}

- (void)clearNewBookingPlaceholderAtIndexPath
{
    [self.sections enumerateObjectsUsingBlock:^(CalendarSectionDataSource *obj, NSUInteger idx, BOOL *stop) {
        [obj removeNewBookingPlaceholder];
    }];
}

#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(nonnull UICollectionView *)collectionView
{
    NSParameterAssert(collectionView != nil);
    return self.sections.count;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSParameterAssert(collectionView != nil);
    NSAssert(section < self.sections.count, @"trying to access section with index %ld while data source contains only %lu sections", (long)section, (unsigned long)self.sections.count);
    return self.sections[section].items.count;
}

- (nonnull UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(collectionView != nil);
    NSParameterAssert(indexPath != nil);
    NSObject<SBBookingProtocol> *obj = [self bookingAtIndexPath:indexPath];
    NSAssert(obj != nil, @"trying to get collection view cell for item with index path (%@) which not exists", indexPath);
    if ([obj isKindOfClass:[SBBooking class]]) {
        SBBooking *booking = (SBBooking *)obj;
        BookingCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
        UIColor *bgColor = [UIColor sb_defaultBookingColor];
        if (self.performers[booking.performerID].color) {
            bgColor = [UIColor colorFromHEXString:self.performers[booking.performerID].color];
        }
        if (booking.statusID) {
            SBBookingStatus *status = self.statuses[booking.statusID];
            if (status) {
                bgColor = [UIColor colorFromHEXString:status.HEXColor];
            }
        }
        else if (self.statuses.count > 0) {
            bgColor = [UIColor colorFromHEXString:self.statuses.defaultStatus.HEXColor];
        }
        UIColor *statusColor = nil;
        if (booking.paymentStatus) {
            if ([booking.paymentStatus isEqualToString:@"paid"] && [booking.paymentSystem isEqualToString:@"delay"]) {
                statusColor = [UIColor colorWithRed:1. green:221./255. blue:85./255. alpha:1];
            }
            else if (![booking.paymentStatus isEqualToString:@"paid"]) {
                statusColor = [UIColor redColor];
            }
        }
        [cell setBookingColor:bgColor canceled:![booking.isConfirmed boolValue]]; /// set color before text!
        [cell setTimeText:[self.intervalFormatter stringFromDate:booking.startDate toDate:booking.endDate]
                   client:booking.clientName
                performer:([self.traitCollection isWideLayout] ? nil : booking.performerName)
                  setvice:booking.eventTitle
               stausColor:statusColor];
        return cell;
    }
    else if ([obj isKindOfClass:[SBNewBookingPlaceholder class]]) {
        NewBookingPlaceholderCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"placeholder" forIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (nonnull UICollectionReusableView *)collectionView:(nonnull UICollectionView *)collectionView
                   viewForSupplementaryElementOfKind:(nonnull NSString *)kind
                                         atIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(collectionView != nil);
    NSParameterAssert(indexPath != nil);
    NSParameterAssert(kind != nil);
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        NSAssert(indexPath.section < self.sections.count, @"trying to access section with index %ld while data source contains only %lu sections", (long)indexPath.section, (unsigned long)self.sections.count);
        CalendarSectionDataSource *section = self.sections[indexPath.section];
        TextCollectionReusableView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                           withReuseIdentifier:kCalendarGridSectionHeaderReuseIdentifier
                                                                                                  forIndexPath:indexPath];
        supplementaryView.textLabel.textColor = [UIColor darkGrayColor];
        supplementaryView.textLabel.text = section.title;
        supplementaryView.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        return supplementaryView;
    }
    else if ([kind isEqualToString:kCalendarDataSourceTimeframeElementKind]) {
        TextCollectionReusableView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                           withReuseIdentifier:kind
                                                                                                  forIndexPath:indexPath];
        NSAssert(indexPath.item < self.workingHoursMatrix.hours.count,
                @"trying to access hour with index %ld while working hours matrix contains only %lu hours", (long)indexPath.item, (unsigned long)self.workingHoursMatrix.hours.count);
        NSDate *sectionDate = self.workingHoursMatrix.hours[indexPath.item];
        supplementaryView.textLabel.text = [self.timeFrameFormatter stringFromDate:sectionDate];
        supplementaryView.textLabel.textColor = [UIColor lightGrayColor];
        supplementaryView.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        supplementaryView.textLabel.textAlignment = NSTextAlignmentRight;
        return supplementaryView;
    }
    else if ([kind isEqualToString:kCalendarDataSourceGoogleBusyTimeElementKind]) {
        TextCollectionReusableView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                           withReuseIdentifier:kind
                                                                                                  forIndexPath:indexPath];
        supplementaryView.backgroundColor = [UIColor sb_defaultBookingColor];
        supplementaryView.textLabel.text = NSLS(@"Google calendar event",@"");
        supplementaryView.textLabel.textColor = [UIColor lightGrayColor];
        supplementaryView.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        supplementaryView.textLabel.textAlignment = NSTextAlignmentLeft;
        return supplementaryView;
    }
    return nil;
}

@end
