//
//  CalendarDataSource.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 14.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBBooking.h"
#import "CalendarBookingPresenter.h"
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class SBWorkingHoursMatrix;
@class CalendarSectionDataSource;
@class SBNewBookingPlaceholder;

extern NSString * const kCalendarDataSourceTimeframeElementKind;
extern NSString * const kCalendarDataSourceGoogleBusyTimeElementKind;

@interface CalendarDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, strong) NSArray <CalendarSectionDataSource *> * sections;
@property (nonatomic, readonly, strong) NSCalendar *calendar;
@property (nonatomic, readonly, strong) NSDateFormatter *timeFrameFormatter;
@property (nonatomic, readonly, weak, nullable) UICollectionView *collectionView;
@property (nonatomic, strong) UITraitCollection *traitCollection;
@property (nonatomic) NSTimeInterval timeframeStep;
@property (nonatomic, strong, nullable) SBWorkingHoursMatrix *workingHoursMatrix;
@property (nonatomic, strong, readonly) NSDictionary <NSObject *, NSArray <NSDictionary *> *> * googleCalendarBusyTime;
@property (nonatomic) BOOL displayServiceForWideLayout;
@property (nonatomic) BOOL displayPerformerForWideLayout;

/// order of adding presenters is important
- (void)addPresenter:(NSObject <CalendarBookingPresenter> *)presenter;
- (void)resetPresenters;

- (nullable NSObject<SBBookingProtocol> * )bookingAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray <NSObject<SBBookingProtocol> *> *)bookingsForSection:(NSUInteger)section;
- (void)setBookings:(NSArray <SBBookingObject *> *)bookings sortingStrategy:(nullable NSComparator)sortingStrategy;
- (void)configureCollectionView:(UICollectionView *)collectionView;
- (void)setWorkingHoursMatrix:(SBWorkingHoursMatrix *)workingHoursMatrix;
- (void)setGoogleCalendarBusyTime:(NSArray<NSDictionary *> * _Nonnull)googleCalendarBusyTime forSectionID:(NSObject<NSCopying> *)sectionID;

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
