//
//  CalendarDataSource.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 14.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBBooking.h"
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class SBWorkingHoursMatrix;
@class CalendarSectionDataSource;
@class SBNewBookingPlaceholder;
@class SBBookingStatusesCollection;

extern NSString * const kCalendarDataSourceTimeframeElementKind;

@interface CalendarDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, strong) NSArray <CalendarSectionDataSource *> * sections;
@property (nonatomic, strong, readonly, nullable) SBBookingStatusesCollection * statuses;
@property (nonatomic, readonly, strong) NSCalendar *calendar;
@property (nonatomic, readonly, strong) NSDateFormatter *timeFrameFormatter;
@property (nonatomic, readonly, weak, nullable) UICollectionView *collectionView;
@property (nonatomic, strong) UITraitCollection *traitCollection;
@property (nonatomic) NSTimeInterval timeframeStep;
@property (nonatomic, strong, nullable) SBWorkingHoursMatrix *workingHoursMatrix;

- (nullable NSObject<SBBookingProtocol> * )bookingAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray <NSObject<SBBookingProtocol> *> *)bookingsForSection:(NSUInteger)section;
- (void)setBookings:(NSArray <SBBookingObject *> *)bookings sortingStrategy:(nullable NSComparator)sortingStrategy;
- (void)configureCollectionView:(UICollectionView *)collectionView;
- (void)setWorkingHoursMatrix:(SBWorkingHoursMatrix *)workingHoursMatrix;
- (void)setStatusesCollection:(SBBookingStatusesCollection *)statuses;

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                          cellForItemAtIndexPath:(NSIndexPath *)indexPath;
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
                   viewForSupplementaryElementOfKind:(NSString *)kind
                                         atIndexPath:(NSIndexPath *)indexPath;

- (void)addNewBookingPlaceholder:(SBNewBookingPlaceholder *)placeholder forSection:(NSUInteger)section;
- (void)clearNewBookingPlaceholderAtIndexPath;

@end

NS_ASSUME_NONNULL_END
