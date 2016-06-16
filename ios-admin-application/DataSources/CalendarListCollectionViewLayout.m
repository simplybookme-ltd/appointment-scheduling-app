//
//  CalendarListCollectionViewLayout.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 17.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarListCollectionViewLayout.h"
#import "CalendarGridCollectionViewLayout_Private.h"
#import "NSDate+TimeManipulation.h"
#import "CalendarSectionDataSource.h"

@interface CalendarListCollectionViewLayout ()

@property (nonatomic) CGSize itemSize;
@property (nonatomic, strong, nullable) NSMutableArray <NSValue *> *rowHeights;

@end

@implementation CalendarListCollectionViewLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeframeWidth = 55;
        self.minColumnWidth = 120;
        self.minRowHeight = 85;
        self.headlineHeight = 0;
        self.timeframeItemInsets = UIEdgeInsetsMake(0, 0, 0, 5); // -7 for time label to center it vertically
        self.cellInsets = UIEdgeInsetsMake(2, 2, 2, 2);
        self.contentInsets = UIEdgeInsetsMake(10, 0, 10, 0);
    }
    return self;
}

- (nullable NSIndexPath *)indexPathForCellAtPosition:(CGPoint)position
{
    CGRect gridRect = CGRectMake(self.timeframeWidth, self.headlineHeight, self.contentSize.width, self.contentSize.height - self.contentInsets.top - self.contentInsets.bottom);
    if (!CGRectContainsPoint(gridRect, position)) {
        return nil;
    }
    NSInteger section = 0;
    NSInteger item = 0;
    for (NSValue *v in self.rowHeights) {
        if ([v CGRectValue].origin.y < position.y && [v CGRectValue].origin.y + [v CGRectValue].size.height > position.y) {
            break;
        }
        item++;
    }
    return [NSIndexPath indexPathForItem:item inSection:section];
}

- (nonnull NSArray <NSIndexPath *> *)indexPathsForItemsCompetitorsToItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    CalendarLayoutAttributes *attributes = self.layoutAttributesForItems[indexPath.section][indexPath.item];
    NSMutableArray *list = [NSMutableArray array];
    for (NSUInteger section = 0; section < self.layoutAttributesForItems.count; ++section) {
        [self.layoutAttributesForItems[section] enumerateObjectsUsingBlock:^(CalendarLayoutAttributes *obj, NSUInteger idx, BOOL *stop) {
            if (CGRectIntersectsRect(attributes.frame, obj.frame)) {
                [list addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
            }
            /// can optimize this loop only for same section as initial item
            *stop = (attributes.frame.origin.y < obj.frame.origin.y && (section == indexPath.section && idx >= indexPath.item));
        }];
    }
    return list;
}

#pragma mark - Layout Calculations

- (nonnull NSArray <NSArray <CalendarLayoutAttributes *> *> *)calculateLayoutAttributesForItemsWithColumnWidth:(CGFloat)columnWidth
                                                                                                     rowHeight:(CGFloat)rowHeight
{
    NSMutableArray <NSMutableArray <CalendarLayoutAttributes *> *> *layoutAttributesBySections = [NSMutableArray array];
    NSMutableDictionary <NSIndexPath *, CalendarLayoutAttributes *> *attributesByIndexPath = [NSMutableDictionary dictionary];
    NSMutableDictionary <NSNumber *, NSMutableArray *> *rows = [NSMutableDictionary dictionary];
    NSMutableDictionary <NSNumber *, NSMutableArray *> *adjustments = [NSMutableDictionary dictionary];

    NSInteger sections = [self.dataSource numberOfSectionsInCollectionView:self.collectionView];
    NSMutableArray <SBBookingObject *> *bookings = [NSMutableArray array];
    NSMutableDictionary <NSString *, NSIndexPath *> *indexes = [NSMutableDictionary dictionary];
    for (NSUInteger sectionIndex = 0; sectionIndex < sections; sectionIndex++) {
        [layoutAttributesBySections addObject:[NSMutableArray array]];
        [[self.dataSource bookingsForSection:sectionIndex] enumerateObjectsWithOptions:0
                                                                            usingBlock:^(SBBookingObject *booking, NSUInteger idx, BOOL *stop) {
                                                                                [bookings addObject:booking];
                                                                                indexes[booking.bookingID] = [NSIndexPath indexPathForItem:idx inSection:sectionIndex];
                                                                                [layoutAttributesBySections addObject:[NSMutableArray array]];
        }];
    }
    [bookings sortWithOptions:NSSortConcurrent usingComparator:CalendarGridBookingsLayoutSortingStrategy];
    [bookings enumerateObjectsUsingBlock:^(SBBookingObject * booking, NSUInteger idx, BOOL *stop) {
        NSTimeInterval startOffset = [self startOffsetForDate:booking.startDate];
        NSTimeInterval duration = (booking.endDate.timeIntervalSince1970 - booking.startDate.timeIntervalSince1970) / 60.;
        
        NSIndexPath *indexPath = indexes[booking.bookingID];
        CalendarLayoutAttributes *attributes = [CalendarLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.startOffset = startOffset;
        attributes.duration = duration;
        attributesByIndexPath[attributes.indexPath] = attributes;
        attributes.frame = CGRectMake(0, startOffset * self.minuteHeight + self.contentInsets.top + self.headlineHeight,
                                      columnWidth, duration * self.minuteHeight);
        attributes.zIndex = kItemZIndex + idx;
        [layoutAttributesBySections[indexPath.section] addObject:attributes];
        
        if (!rows[@(startOffset)]) {
            rows[@(startOffset)] = [NSMutableArray array];
        }
        [rows[@(startOffset)] addObject:attributes];
        
        if (!adjustments[@(startOffset)]) {
            adjustments[@(startOffset)] = [NSMutableArray array];
        }
        
        [layoutAttributesBySections enumerateObjectsWithOptions:0 usingBlock:^(NSMutableArray<CalendarLayoutAttributes *> *list, NSUInteger idx, BOOL *stop)
         {
             [list enumerateObjectsUsingBlock:^(CalendarLayoutAttributes *objAttributes, NSUInteger idx, BOOL *itemsStop) {
                 NSTimeInterval objStartOffset = objAttributes.startOffset;
                 NSTimeInterval objDuration = objAttributes.duration;
                 if (![adjustments[@(startOffset)] containsObject:objAttributes] && objStartOffset != startOffset) {
                     NSRange intersection = NSIntersectionRange(NSMakeRange(objStartOffset, objDuration), NSMakeRange(startOffset, duration));
                     if (!NSEqualRanges(intersection, NSRangeZero)) {
                         [adjustments[@(startOffset)] addObject:objAttributes];
                     }
                 }
                 if (startOffset + duration <= objStartOffset) {
                     *itemsStop = YES;
                 }
             }];
         }];
    }];
    
    [[rows.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj1 compare:obj2];
    }] enumerateObjectsWithOptions:NSEnumerationConcurrent
     usingBlock:^(NSNumber *key, NSUInteger idx, BOOL *stop) {
         [adjustments[key] sortWithOptions:NSSortConcurrent
                           usingComparator:^NSComparisonResult(CalendarLayoutAttributes *a1, CalendarLayoutAttributes *a2) {
                               return a1.frame.origin.y > a2.frame.origin.y ? NSOrderedAscending : (a1.frame.origin.y == a2.frame.origin.y ? NSOrderedSame : NSOrderedDescending);
                           }];
         CGFloat xOffset = self.timeframeWidth;
         __block CGFloat x = self.timeframeWidth;
         [adjustments[key] enumerateObjectsUsingBlock:^(CalendarLayoutAttributes *attributes, NSUInteger idx, BOOL *_stop) {
             if (attributes.startOffset < key.floatValue) {
                 x = (attributes.xAdjusted ? attributes.frame.origin.x : xOffset) + 5;
             }
             else {
                 *_stop = YES;
             }
         }];
         NSArray *list = rows[key];
         CGFloat width = (columnWidth - (x - xOffset)) / list.count;
         [list enumerateObjectsWithOptions:0
                                usingBlock:^(CalendarLayoutAttributes *attributes, NSUInteger idx, BOOL *_stop) {
                                    if (!attributes.xAdjusted) {
                                        CGRect rect = attributes.frame;
                                        rect.origin.x = width * idx + x;
                                        rect.origin.y += 1;
                                        rect.size.width = width - 1;
                                        rect.size.height -= 2;
                                        attributes.frame = rect;
                                        attributes.xAdjusted = YES;
                                    }
                                }];
     }];
    return layoutAttributesBySections;
}

- (NSArray <CalendarLayoutAttributes *> *)calculateLayoutAttributesForBreakHoursForSection:(NSUInteger)section
{
    return @[]; // no break hours visible for one column view
}

#pragma mark - Collection View Layout

- (void)prepareLayout
{
    self.minColumnWidth = self.collectionView.frame.size.width - self.timeframeWidth;
    [super prepareLayout];
    self.itemSize = CGSizeMake(self.collectionView.frame.size.width - self.timeframeWidth - self.cellInsets.left - self.cellInsets.right,
            85);
    self.contentSize = CGSizeMake(self.collectionView.frame.size.width, self.contentSize.height);
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForVerticalLineAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    return nil;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForTimeFrameRowDecorationAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    return nil;
}

- (nullable CalendarLayoutAttributes *)layoutAttributesForWorkhoursBreakDecorationViewAtIndexPath:(nonnull NSIndexPath *)indexPath
                                                                                        breakData:(nonnull SBDateRange *)breakData
{
    NSAssertFail();
    return nil;
}

- (nullable CalendarLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(nonnull NSString *)elementKind
                                                                      atIndexPath:(nonnull NSIndexPath *)indexPath
{
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        return nil;
    }
    return [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
}

#pragma mark - Geometry

- (nonnull CalendarLayoutAttributes *)correctAttributesGeometry:(nonnull CalendarLayoutAttributes *)attributes
{
    NSParameterAssert(attributes != nil);
    // TODO: subclass of CalendarGridCollectionViewLayout should has possibility to change stickX/Y layout attributes before geometry corrections
    return attributes;
}

//- (CGRect)frameForTimeframeSupplementaryAtIndexPath:(nonnull NSIndexPath *)indexPath
//{
//    NSParameterAssert(indexPath != nil);
//    return CGRectMake(self.timeframeItemInsets.left,
//            indexPath.row * self.cellSize.height + self.headlineHeight + self.contentInsets.top + self.timeframeItemInsets.top,
//            self.timeframeWidth - self.timeframeItemInsets.left - self.timeframeItemInsets.right,
//            /*self.cellSize.height / 2. - self.timeframeItemInsets.top - self.timeframeItemInsets.bottom - 30*/30);
//}

@end
