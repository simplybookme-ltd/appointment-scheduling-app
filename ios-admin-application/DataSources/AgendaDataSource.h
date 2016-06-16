//
//  AgendaDataSource.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBPerformer.h"
#import "SBBooking.h"
#import "SBBookingStatusesCollection.h"
#import "SBGetBookingsFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface AgendaDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, readonly, strong) NSCalendar *calendar;
@property (nonatomic, readonly, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, readonly, strong) SBGetBookingsFilter *filter;

- (void)setPerformers:(SBPerformersCollection *)performers;
- (void)addBookings:(NSArray <SBBooking *> *)bookings;
- (void)setStatuses:(SBBookingStatusesCollection * _Nullable)statuses;
- (SBBooking *)bookingAtIndexPath:(NSIndexPath *)indexPath;

- (void)configureCollectionView:(UICollectionView *)collectionView;

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                          cellForItemAtIndexPath:(NSIndexPath *)indexPath;
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
                   viewForSupplementaryElementOfKind:(NSString *)kind
                                         atIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END