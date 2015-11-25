//
//  CalendarCollectionViewLayout.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 14.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBDateRange.h"
@import UIKit;

#import "CalendarDataSource.h"
#import "CalendarLayoutAttributes.h"

extern NSString * _Nonnull const kHorizontalLineDecorationViewKind;
extern NSComparator _Nonnull const CalendarGridBookingsLayoutSortingStrategy;

@interface CalendarGridCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, weak, nullable) CalendarDataSource *dataSource;
@property (nonatomic) CGFloat timeframeWidth;
@property (nonatomic) UIEdgeInsets timeframeItemInsets;
@property (nonatomic) CGFloat minColumnWidth;
@property (nonatomic) CGFloat minRowHeight;
@property (nonatomic) CGFloat timeframeStepHeight;
@property (nonatomic) CGFloat headlineHeight;
@property (nonatomic) CGSize cellSize;
@property (nonatomic) UIEdgeInsets cellInsets;
@property (nonatomic) UIEdgeInsets contentInsets;
@property (nonatomic) BOOL showCurrentTimeLine;
@property (nonatomic, strong, nullable) SBWorkingHoursMatrix *workingHoursMatrix;

- (nullable NSIndexPath *)indexPathForCellAtPosition:(CGPoint)position;
- (NSUInteger)timeStepOffsetForCellAtPosition:(CGPoint)position calculatedIndexPath:(nonnull NSIndexPath *)indexPath;
- (nonnull NSArray <NSIndexPath *> *)indexPathsForItemsCompetitorsToItemAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (void)finilize;

@end
