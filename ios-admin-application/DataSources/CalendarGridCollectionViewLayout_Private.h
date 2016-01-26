//
//  CalendarGridCollectionViewLayout+Private.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 27.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarGridCollectionViewLayout.h"

extern const NSUInteger kItemZIndex;
extern const NSUInteger kTimeFrameBackgroundDecorationViewZIndex;

@interface CalendarGridCollectionViewLayout (Private)

@property (nonatomic, strong, nonnull) NSArray <NSArray <CalendarLayoutAttributes *> *> *layoutAttributesForItems;
@property (nonatomic, strong, nonnull) NSArray <NSArray <CalendarLayoutAttributes *> *> *layoutAttributesForWorkHoursBreaks;
@property (nonatomic, strong, nonnull) NSArray <CalendarLayoutAttributes *> *layoutAttributesForTimeFrameSupplementaryElements;
@property (nonatomic) CGFloat columnWidth;
@property (nonatomic, readonly) NSTimeInterval minuteHeight;
@property (nonatomic) CGSize contentSize;

- (nonnull CalendarLayoutAttributes *)correctAttributesGeometry:(nonnull CalendarLayoutAttributes *)attributes;
- (NSTimeInterval)startOffsetForDate:(nonnull NSDate *)date;
- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForVerticalLineAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForTimeFrameRowDecorationAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (CGRect)frameForRowLine:(nonnull NSIndexPath *)indexPath;
- (CGRect)frameForTimeframeSupplementaryAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (nonnull NSArray <NSArray <CalendarLayoutAttributes *> *> *)calculateLayoutAttributesForItemsWithColumnWidth:(CGFloat)columnWidth
                                                                                                     rowHeight:(CGFloat)rowHeight;
- (nonnull NSArray <CalendarLayoutAttributes *> *)calculateLayoutAttributesForBreakHoursForSection:(NSUInteger)section;
- (nonnull NSArray <CalendarLayoutAttributes *> *)calculateLayoutAttributesForTimeFrameSupplementaryElements;

- (nullable CalendarLayoutAttributes *)layoutAttributesForWorkhoursBreakDecorationViewAtIndexPath:(nonnull NSIndexPath *)indexPath
                                                                                       breakData:(nonnull SBDateRange *)breakData;
- (nullable CalendarLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(nonnull NSString *)elementKind
                                                                      atIndexPath:(nonnull NSIndexPath *)indexPath;

@end
