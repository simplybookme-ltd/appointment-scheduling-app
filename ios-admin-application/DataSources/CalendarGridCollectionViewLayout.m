//
//  CalendarCollectionViewLayout.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 14.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "CalendarGridCollectionViewLayout.h"
#import "CalendarGridCollectionViewLayout_Private.h"
#import "CalendarCellDecorationView.h"
#import "SBWorkingHoursMatrix.h"
#import "NSDate+TimeManipulation.h"
#import "CalendarSectionDataSource.h"

NSString *_Nonnull const kVerticalLineDecorationViewKind = @"kVerticalLineDecorationViewKind";
NSString *_Nonnull const kHeadlineBackgroundDecorationViewKind = @"kHeadlineBackgroundDecorationViewKind";
NSString *_Nonnull const kTimeframeBackgroundDecorationViewKind = @"kTimeframeBackgroundDecorationViewKind";
NSString *_Nonnull const kTimeFrameHorizontalLineDecorationViewKind = @"kTimeFrameHorizontalLineDecorationViewKind";
NSString *_Nonnull const kTimeFrameStepHorizontalLineDecorationViewKind = @"kTimeFrameStepHorizontalLineDecorationViewKind";
NSString *_Nonnull const kBreakTimeBackgroundDecorationViewKind = @"kBreakTimeBackgroundDecorationViewKind";

/**
 * sort bookings by two params: first by duration (longer events first) then by start datetime.
 * this kind of sorting is required to simplify grid layout
 */
NSComparator _Nonnull const CalendarGridBookingsLayoutSortingStrategy = ^NSComparisonResult(SBBookingObject *obj1, SBBookingObject *obj2){
    NSTimeInterval obj1duration = (obj1.endDate.timeIntervalSince1970 - obj1.startDate.timeIntervalSince1970) / 60.;
    NSTimeInterval obj2duration = (obj2.endDate.timeIntervalSince1970 - obj2.startDate.timeIntervalSince1970) / 60.;
    NSComparisonResult result = [obj1.startDate compare:obj2.startDate];
    return result == NSOrderedSame ? (obj1duration < obj2duration ? NSOrderedDescending : NSOrderedAscending) : result;
};

const NSUInteger kTimeFrameBackgroundDecorationViewZIndex = 900;
const NSUInteger kHeadlineBackgroundDecorationViewZIndex = 950;
const NSUInteger kItemZIndex = 550;

@interface CalendarGridCollectionViewLayout ()
{
    NSTimeInterval minuteHeight;
}

@property (nonatomic, strong, nonnull) NSArray <NSArray <CalendarLayoutAttributes *> *> *layoutAttributesForItems;
@property (nonatomic, strong, nonnull) NSArray <NSArray <CalendarLayoutAttributes *> *> *layoutAttributesForWorkHoursBreaks;
@property (nonatomic, strong, nonnull) NSArray <NSArray <CalendarLayoutAttributes *> *> *layoutAttributesForGoogleBusyItems;
@property (nonatomic, strong, nonnull) NSArray <CalendarLayoutAttributes *> *layoutAttributesForTimeFrameSupplementaryElements;
@property (nonatomic, strong, nonnull) NSMutableArray <NSNumber *> *columns;
@property (nonatomic) CGFloat columnWidth;
@property (nonatomic, readonly) NSTimeInterval minuteHeight;
@property (nonatomic, strong, nonnull) NSCalendar *calendar;
@property (nonatomic, strong, nullable) NSTimer *timelineTimer;
@property (nonatomic) CGSize contentSize;

@end

@implementation CalendarGridCollectionViewLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeframeWidth = 55;
        self.minColumnWidth = 150;
        self.minRowHeight = 85;
        self.headlineHeight = 33;
        self.timeframeItemInsets = UIEdgeInsetsMake(0, 0, 0, 5);
        self.cellInsets = UIEdgeInsetsMake(1, 2, 2, 0);
        self.contentInsets = UIEdgeInsetsMake(0, 0, 10, 0);
        self.columns = [NSMutableArray array];
        self.layoutAttributesForItems = [NSMutableArray array];
        self.layoutAttributesForWorkHoursBreaks = [NSMutableArray array];
        self.layoutAttributesForGoogleBusyItems = [NSMutableArray array];
        minuteHeight = -1;
        self.timelineTimer = [NSTimer timerWithTimeInterval:60
                                                     target:self selector:@selector(timerHandler:)
                                                   userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timelineTimer forMode:NSRunLoopCommonModes];
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kVerticalLineDecorationViewKind];
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kHorizontalLineDecorationViewKind];
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kHeadlineBackgroundDecorationViewKind];
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kTimeFrameHorizontalLineDecorationViewKind];
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kTimeFrameStepHorizontalLineDecorationViewKind];
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kTimeframeBackgroundDecorationViewKind];
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kBreakTimeBackgroundDecorationViewKind];
    }
    return self;
}

- (void)dealloc
{
    if (self.timelineTimer) {
        [self.timelineTimer invalidate];
        self.timelineTimer = nil;
    }
}

- (void)finilize
{
    if (self.timelineTimer) {
        [self.timelineTimer invalidate];
        self.timelineTimer = nil;
    }
}

- (void)timerHandler:(NSTimer *)timer
{
    [self invalidateLayoutWithContext:[self invalidationContextForBoundsChange:self.collectionView.bounds]];
}

- (nonnull NSCalendar *)calendar
{
    if (!_calendar) {
        _calendar = [NSCalendar currentCalendar];
        /// Warning: don't set time zone. see usage of this calendar before
    }
    return _calendar;
}

- (CGSize)collectionViewContentSize
{
    if (!self.dataSource) {
        return CGSizeZero;
    }
    return self.contentSize;
}

- (NSTimeInterval)minuteHeight
{
    if (minuteHeight == -1) {
        NSAssert(self.workingHoursMatrix.hours.count > 0, @"working hours matrix is empty");
        minuteHeight = (self.contentSize.height - self.contentInsets.top - self.contentInsets.bottom - self.headlineHeight) / (self.workingHoursMatrix.hours.count * 60.);
    }
    return minuteHeight;
}

#pragma mark - Find Item by Position

- (nullable NSIndexPath *)indexPathForCellAtPosition:(CGPoint)position
{
    CGRect gridRect = CGRectMake(self.timeframeWidth, self.headlineHeight, self.contentSize.width, self.contentSize.height - self.contentInsets.top - self.contentInsets.bottom);
    if (!CGRectContainsPoint(gridRect, position)) {
        return nil;
    }
    NSInteger section = 0;
    for (NSNumber *value in self.columns) {
        if (CGRectContainsPoint(CGRectMake(self.timeframeWidth + value.floatValue, self.headlineHeight, self.columnWidth, gridRect.size.height), position)) {
            break;
        }
        section++;
    }
    NSAssert(section < self.layoutAttributesForWorkHoursBreaks.count, @"");
    if (section >= self.layoutAttributesForWorkHoursBreaks.count) {
        return nil;
    }
    NSArray *breaks = self.layoutAttributesForWorkHoursBreaks[section];
    for (UICollectionViewLayoutAttributes *layoutAttributes in breaks) {
        if (CGRectContainsPoint(layoutAttributes.frame, position)) {
            return nil;
        }
    }
    NSInteger item = ceil((position.y - self.headlineHeight) / self.cellSize.height) - 1;
    return [NSIndexPath indexPathForItem:item inSection:section];
}

- (NSUInteger)timeStepOffsetForCellAtPosition:(CGPoint)position calculatedIndexPath:(NSIndexPath * _Nonnull)indexPath
{
    NSParameterAssert(indexPath != nil);
    NSAssert(self.minuteHeight > 0, @"invalid height value for minute %f", self.minuteHeight);
    CGFloat mins = (position.y - self.headlineHeight - indexPath.item * self.cellSize.height) / self.minuteHeight;
    NSAssert(self.dataSource.timeframeStep != 0, @"Time frame step can't be 0");
    return floor(mins / self.dataSource.timeframeStep);
}

- (NSArray <NSIndexPath *> *)indexPathsForItemsCompetitorsToItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    CalendarLayoutAttributes *attributes = self.layoutAttributesForItems[indexPath.section][indexPath.item];
    NSMutableArray *list = [NSMutableArray array];
    [self.layoutAttributesForItems[indexPath.section] enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                                       usingBlock:^(CalendarLayoutAttributes *obj, NSUInteger idx, BOOL *stop) {
        if (CGRectIntersectsRect(attributes.frame, obj.frame)) {
            [list addObject:[NSIndexPath indexPathForItem:idx inSection:indexPath.section]];
        }
        *stop = (attributes.frame.origin.y < obj.frame.origin.y && idx >= indexPath.item);
    }];
    return list;
}

#pragma mark - Layout Calculations

- (nonnull NSArray <NSArray <CalendarLayoutAttributes *> *> *)calculateLayoutAttributesForItemsWithColumnWidth:(CGFloat)columnWidth
                                                                                                     rowHeight:(CGFloat)rowHeight
{
    NSMutableArray <NSArray <CalendarLayoutAttributes *> *> *layoutAttributesBySections = [NSMutableArray array];
    NSMutableDictionary <NSNumber *, NSMutableArray *> *rows = [NSMutableDictionary dictionary];
    NSMutableDictionary <NSNumber *, NSMutableArray *> *adjustments = [NSMutableDictionary dictionary];

    NSInteger sections = self.collectionView.numberOfSections;
    for (NSUInteger sectionIndex = 0; sectionIndex < sections; sectionIndex++) {
        [rows removeAllObjects];
        [adjustments removeAllObjects];
        NSMutableArray <CalendarLayoutAttributes *> *layoutAttributesForSection = [NSMutableArray array];
        [layoutAttributesBySections addObject:layoutAttributesForSection];
        CalendarSectionDataSource *section = self.dataSource.sections[sectionIndex];
        [[self.dataSource bookingsForSection:sectionIndex] enumerateObjectsUsingBlock:^(NSObject <SBBookingProtocol> *booking, NSUInteger idx, BOOL *stop) {

            NSTimeInterval startOffset = [self startOffsetForDate:booking.startDate fromDate:section.startDate];
            NSTimeInterval duration = (booking.endDate.timeIntervalSince1970 - booking.startDate.timeIntervalSince1970) / 60.;

            CalendarLayoutAttributes *attributes = [CalendarLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:idx
                                                                                                                                      inSection:sectionIndex]];
            attributes.headlineHeight = self.headlineHeight;
            attributes.startOffset = startOffset;
            attributes.duration = duration;
            attributes.frame = CGRectMake(0, startOffset * self.minuteHeight + self.contentInsets.top + self.headlineHeight,
                                          columnWidth, duration * self.minuteHeight);
            attributes.zIndex = kItemZIndex + idx;
            [layoutAttributesForSection addObject:attributes];

            if (!rows[@(startOffset)]) {
                rows[@(startOffset)] = [NSMutableArray array];
            }
            [rows[@(startOffset)] addObject:attributes];

            if (!adjustments[@(startOffset)]) {
                adjustments[@(startOffset)] = [NSMutableArray array];
            }

            [layoutAttributesForSection enumerateObjectsUsingBlock:^(CalendarLayoutAttributes *objAttributes, NSUInteger _idx, BOOL *itemsStop) {
                NSTimeInterval objStartOffset = objAttributes.startOffset;
                NSTimeInterval objDuration = objAttributes.duration;
                if (objAttributes
                    && objAttributes != attributes // do not use isEqual. just check if it is same object
                    && ![adjustments[@(startOffset)] containsObject:objAttributes]
                    && objStartOffset != startOffset)
                {
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

        [[rows.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
            return [obj1 compare:obj2];
        }] enumerateObjectsWithOptions:NSEnumerationConcurrent
                            usingBlock:^(NSNumber *key, NSUInteger idx, BOOL *stop) {
                                [adjustments[key] sortWithOptions:NSSortConcurrent
                                                  usingComparator:^NSComparisonResult(CalendarLayoutAttributes *a1, CalendarLayoutAttributes *a2) {
                                                      return a1.frame.origin.y > a2.frame.origin.y ? NSOrderedAscending : (a1.frame.origin.y == a2.frame.origin.y ? NSOrderedSame : NSOrderedDescending);
                                                  }];
                                CGFloat xOffset = self.timeframeWidth + columnWidth * sectionIndex;
                                __block CGFloat x = xOffset;
                                [adjustments[key] enumerateObjectsUsingBlock:^(CalendarLayoutAttributes *attributes, NSUInteger _idx, BOOL *_stop) {
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
    }
    return layoutAttributesBySections;
}

- (NSArray <CalendarLayoutAttributes *> *)calculateLayoutAttributesForBreakHoursForSection:(NSUInteger)section
{
    NSMutableArray <CalendarLayoutAttributes *> *attributesList = [NSMutableArray array];
    NSObject *sectionID = self.dataSource.sections[section].sectionID;
    NSMutableArray<SBDateRange *> *performerBreakTimes = [NSMutableArray array];
    NSDateComponents *addOneHourComponents = [NSDateComponents new];
    addOneHourComponents.hour = 1;
    if ([self.dataSource.workingHoursMatrix isDayOffForRecordWithID:sectionID]) {
        SBDateRange *dayOff = [SBDateRange dateRangeWithStart:self.dataSource.workingHoursMatrix.start
                                                          end:self.dataSource.workingHoursMatrix.end];
        dayOff.end = [self.calendar dateByAddingComponents:addOneHourComponents toDate:dayOff.end options:0];
        [performerBreakTimes addObject:dayOff];
    }
    else {
        [[self.dataSource.workingHoursMatrix breaksForRecordWithID:sectionID] enumerateObjectsUsingBlock:^(SBDateRange *breakData, NSUInteger idx, BOOL *stop) {
            [performerBreakTimes addObject:breakData];
        }];
        if ([[self.dataSource.workingHoursMatrix startTimeForRecordWithID:sectionID] compare:self.dataSource.workingHoursMatrix.start] == NSOrderedDescending) {
            [performerBreakTimes addObject:[SBDateRange dateRangeWithStart:self.dataSource.workingHoursMatrix.start
                                                                       end:[self.dataSource.workingHoursMatrix startTimeForRecordWithID:sectionID]]];
        }
        if ([[self.dataSource.workingHoursMatrix endTimeForRecordWithID:sectionID] compare:self.dataSource.workingHoursMatrix.end] == NSOrderedAscending) {
            [performerBreakTimes addObject:[SBDateRange dateRangeWithStart:[self.dataSource.workingHoursMatrix endTimeForRecordWithID:sectionID]
                                                                       end:[self.calendar dateByAddingComponents:addOneHourComponents
                                                                                                          toDate:self.dataSource.workingHoursMatrix.end
                                                                                                         options:0]]];
        }
    }
    {
        // because working hours matrix always starts/ends with round hour we need to add not available slots
        if ([self.workingHoursMatrix.hours.firstObject compare:self.dataSource.workingHoursMatrix.start] == NSOrderedAscending) {
            [performerBreakTimes addObject:[SBDateRange dateRangeWithStart:self.workingHoursMatrix.hours.firstObject
                                                                       end:self.dataSource.workingHoursMatrix.start]];
        }
        if ([self.workingHoursMatrix.hours.lastObject compare:self.dataSource.workingHoursMatrix.end] == NSOrderedDescending) {
            [performerBreakTimes addObject:[SBDateRange dateRangeWithStart:self.dataSource.workingHoursMatrix.end
                                                                       end:self.workingHoursMatrix.hours.lastObject]];
        }
    }
    [performerBreakTimes enumerateObjectsUsingBlock:^(SBDateRange *obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:section];
        CalendarLayoutAttributes *attributes = [self layoutAttributesForWorkhoursBreakDecorationViewAtIndexPath:indexPath
                                                                                                      breakData:obj];
        if (attributes) {
            [attributesList addObject:attributes];
        }
    }];
    return attributesList;
}

- (NSArray <CalendarLayoutAttributes *> *)calculateLayoutAttributesForGoogleBusyItemsInSection:(NSUInteger)section
{
    NSMutableArray <CalendarLayoutAttributes *> *attributesList = [NSMutableArray array];
    for (NSInteger item = 0; item < self.dataSource.googleCalendarBusyTime[self.dataSource.sections[section].sectionID].count; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
        CalendarLayoutAttributes *itemAttributes = [self layoutAttributesForSupplementaryViewOfKind:kCalendarDataSourceGoogleBusyTimeElementKind
                                                                                        atIndexPath:indexPath];
        [attributesList addObject:itemAttributes];
    }
    return attributesList;
}

- (nonnull NSArray <CalendarLayoutAttributes *> *)calculateLayoutAttributesForTimeFrameSupplementaryElements
{
    NSMutableArray <CalendarLayoutAttributes *> *attributes = [NSMutableArray array];
    for (NSInteger row = 0; row < self.workingHoursMatrix.hours.count; row++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:0];
        CalendarLayoutAttributes *timeFrameSupplementaryAttributes = [self layoutAttributesForSupplementaryViewOfKind:kCalendarDataSourceTimeframeElementKind
                                                                                                          atIndexPath:indexPath];
        [attributes addObject:timeFrameSupplementaryAttributes];
    }
    return attributes;
}

#pragma mark - Collection View Layout

- (void)invalidateLayout
{
    [super invalidateLayout];
    self.contentSize = CGSizeZero;
    minuteHeight = -1;
}

- (void)prepareLayout
{
    [super prepareLayout];
    if (!CGSizeEqualToSize(self.contentSize, CGSizeZero)) {
        return; // do not recalculate everything on scroll event for performance reason
    }
    NSAssert(self.dataSource != nil, @"Data source not set.");
    if (!self.workingHoursMatrix || !self.workingHoursMatrix.hours.count) {
        return; // nothing to do here
    }

    if (self.dataSource.timeframeStep <= 15) {
        self.timeframeStepHeight = 30;
    }
    else if (self.timeframeStepHeight <= 30) {
        self.timeframeStepHeight = 50;
    }
    else {
        self.timeframeStepHeight = 85;
    }
    self.minRowHeight = self.dataSource.timeframeStep ? (60. / self.dataSource.timeframeStep) * self.timeframeStepHeight : 0;

    NSInteger sections = self.collectionView.numberOfSections;
    self.columnWidth = 0;
    if (sections > 0) {
        self.columnWidth = MAX((self.collectionView.frame.size.width - self.timeframeWidth) / sections, self.minColumnWidth);
    }

    NSInteger rows = self.workingHoursMatrix.hours.count;
    CGFloat rowHeight = 0;
    if (rows > 0) {
        rowHeight = MAX((self.collectionView.frame.size.height - self.headlineHeight) / rows, self.minRowHeight);
    }
    [self.columns removeAllObjects];

    CGFloat contentHeight = rows * rowHeight + self.headlineHeight + self.contentInsets.top + self.contentInsets.bottom;
    self.contentSize = CGSizeMake(0, contentHeight); // set content height to calculate minuteHeight
    self.cellSize = CGSizeMake(self.columnWidth, rowHeight);
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.headlineHeight, self.timeframeWidth, 0, 0);

    self.layoutAttributesForItems = [self calculateLayoutAttributesForItemsWithColumnWidth:self.columnWidth rowHeight:rowHeight];
    self.contentSize = CGSizeMake(self.timeframeWidth + self.columnWidth * sections, contentHeight);

    NSMutableArray *layoutAttributesForWorkHoursBreaks = [NSMutableArray array];
    for (NSUInteger section = 0; section < sections; section++) {
        [self.columns addObject:@(section * self.columnWidth)];
        [layoutAttributesForWorkHoursBreaks addObject:[self calculateLayoutAttributesForBreakHoursForSection:section]];
    }
    self.layoutAttributesForWorkHoursBreaks = layoutAttributesForWorkHoursBreaks;
    self.layoutAttributesForTimeFrameSupplementaryElements = [self calculateLayoutAttributesForTimeFrameSupplementaryElements];
    
    NSMutableArray *layoutAttributesForGoogleBusyItems = [NSMutableArray array];
    for (NSUInteger section = 0; section < sections; section++) {
        [layoutAttributesForGoogleBusyItems addObject:[self calculateLayoutAttributesForGoogleBusyItemsInSection:section]];
    }
    self.layoutAttributesForGoogleBusyItems = layoutAttributesForGoogleBusyItems;
}

+ (Class)layoutAttributesClass
{
    return [CalendarLayoutAttributes class];
}

- (nullable NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *attributes = [NSMutableArray array];
    
    NSInteger sections = self.collectionView.numberOfSections;
    
    if (sections > 0 && self.workingHoursMatrix.hours.count) {
        UICollectionViewLayoutAttributes *headerBackgroundDecoration = [self layoutAttributesForDecorationViewOfKind:kHeadlineBackgroundDecorationViewKind
                                                                                                         atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        [attributes addObject:headerBackgroundDecoration];
        UICollectionViewLayoutAttributes *topLeftCornerMarker = [self layoutAttributesForDecorationViewOfKind:kHeadlineBackgroundDecorationViewKind
                                                                                                  atIndexPath:[NSIndexPath indexPathForItem:-1 inSection:-1]];
        [attributes addObject:topLeftCornerMarker];
    }

    for (NSInteger section = 0; section < sections; section++) {
        
        NSIndexPath *sectionIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        
        UICollectionViewLayoutAttributes *headlineSupplementaryAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                                 atIndexPath:sectionIndexPath];
        if (headlineSupplementaryAttributes) {
            [attributes addObject:headlineSupplementaryAttributes];
        }

        UICollectionViewLayoutAttributes *columnDecoration = [self layoutAttributesForVerticalLineAtIndexPath:sectionIndexPath];
        if (columnDecoration) {
            [attributes addObject:columnDecoration];
        }
        UICollectionViewLayoutAttributes *columnHeaderDecoration = [self layoutAttributesForVerticalLineAtIndexPath:[NSIndexPath indexPathForItem:-1 inSection:section]];
        if (columnHeaderDecoration) {
            [attributes addObject:columnHeaderDecoration];
        }

        if (self.layoutAttributesForWorkHoursBreaks.count > section) {
            [attributes addObjectsFromArray:self.layoutAttributesForWorkHoursBreaks[section]];
        }
        
        if (self.layoutAttributesForGoogleBusyItems.count > section) {
            [attributes addObjectsFromArray:self.layoutAttributesForGoogleBusyItems[section]];
        }

        if (section == 0) {
            for (NSInteger row = 0; row < self.workingHoursMatrix.hours.count; row++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:section];
                UICollectionViewLayoutAttributes *horizontalLineDecoration = [self layoutAttributesForDecorationViewOfKind:kHorizontalLineDecorationViewKind
                                                                                                               atIndexPath:indexPath];
                [attributes addObject:horizontalLineDecoration];
                UICollectionViewLayoutAttributes *timeFrameRowDecoration = [self layoutAttributesForTimeFrameRowDecorationAtIndexPath:indexPath];
                if (timeFrameRowDecoration) {
                    [attributes addObject:timeFrameRowDecoration];
                }
            }
            UICollectionViewLayoutAttributes *timeframeBGDecoration = [self layoutAttributesForDecorationViewOfKind:kTimeframeBackgroundDecorationViewKind
                                                                                                        atIndexPath:sectionIndexPath];
            [attributes addObject:timeframeBGDecoration];
            if (self.showCurrentTimeLine) {
                UICollectionViewLayoutAttributes *timeFrameRowDecoration = [self layoutAttributesForDecorationViewOfKind:kTimeFrameHorizontalLineDecorationViewKind
                                                                                                             atIndexPath:[NSIndexPath indexPathForItem:-1 inSection:-1]];
                [attributes addObject:timeFrameRowDecoration];
            }
        }

        [self.layoutAttributesForTimeFrameSupplementaryElements enumerateObjectsUsingBlock:^(CalendarLayoutAttributes *obj, NSUInteger idx, BOOL *stop) {
            obj.frame = [self frameForTimeframeSupplementaryAtIndexPath:obj.indexPath];
            [attributes addObject:[self correctAttributesGeometry:obj]];
        }];

        NSAssert(self.dataSource.timeframeStep > 0, @"timeframe step not set");
        CGFloat stepsInHour = 60. / self.dataSource.timeframeStep;
        if (stepsInHour > 1) {
            for (NSInteger i = 0; i < self.workingHoursMatrix.hours.count * stepsInHour; ++i) {
                if (fmod(i * self.dataSource.timeframeStep, 60.) != 0) {
                    UICollectionViewLayoutAttributes *timeFrameRowDecoration = [self layoutAttributesForDecorationViewOfKind:kTimeFrameStepHorizontalLineDecorationViewKind
                                                                                                                 atIndexPath:[NSIndexPath indexPathForItem:i inSection:section]];
                    [attributes addObject:timeFrameRowDecoration];
                }
            }
        }
        
        [self.layoutAttributesForItems[section] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:section];
            UICollectionViewLayoutAttributes *itemAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            if (itemAttributes) {
                [attributes addObject:itemAttributes];
            }
        }];
    }
    return attributes;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForTimeFrameRowDecorationAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    UICollectionViewLayoutAttributes *timeFrameRowDecoration = [self layoutAttributesForDecorationViewOfKind:kTimeFrameHorizontalLineDecorationViewKind
                                                                                                 atIndexPath:indexPath];
    return timeFrameRowDecoration;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForVerticalLineAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    UICollectionViewLayoutAttributes *columnDecoration = [self layoutAttributesForDecorationViewOfKind:kVerticalLineDecorationViewKind
                                                                                           atIndexPath:indexPath];
    return columnDecoration;
}

- (nullable CalendarLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(nonnull NSString *)elementKind
                                                                   atIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(elementKind != nil);
    NSParameterAssert(indexPath != nil);
    if ([elementKind isEqualToString:kBreakTimeBackgroundDecorationViewKind]) {
        return self.layoutAttributesForWorkHoursBreaks[indexPath.section][indexPath.item];
    }
    CalendarLayoutAttributes *attributes = [CalendarLayoutAttributes layoutAttributesForDecorationViewOfKind:elementKind
                                                                                               withIndexPath:indexPath];
    if ([elementKind isEqualToString:kTimeframeBackgroundDecorationViewKind]) {
        attributes.backgroundColor = [UIColor whiteColor];
        attributes.frame = CGRectMake(0, 0, self.timeframeWidth, self.contentSize.height);
        attributes.zIndex = kTimeFrameBackgroundDecorationViewZIndex;
        attributes.stickyX = YES;
        attributes.stickyY = YES;
    }
    else if ([elementKind isEqualToString:kHeadlineBackgroundDecorationViewKind]) {
        attributes.backgroundColor = [UIColor whiteColor];
        attributes.frame = CGRectMake(0, 0, self.contentSize.width, self.headlineHeight);
        attributes.zIndex = kHeadlineBackgroundDecorationViewZIndex + 2;
        attributes.stickyX = YES;
        attributes.stickyY = YES;
        if (indexPath.section == -1 && indexPath.row == -1) { // top left corner marker
            attributes.frame = CGRectMake(0, 0, self.timeframeWidth, self.headlineHeight);
            attributes.zIndex = 2000;
//            attributes.zIndex = kTimeFrameBackgroundDecorationViewZIndex;
        }
    }
    else if ([elementKind isEqualToString:kVerticalLineDecorationViewKind]) {
        attributes.backgroundColor = [CalendarCellDecorationView gridColor];
        attributes.frame = [self frameForColumnLine:indexPath];
        attributes.zIndex = kTimeFrameBackgroundDecorationViewZIndex - 1;
        attributes.stickyX = (indexPath.section == 0);
        attributes.stickyY = YES;
        if (indexPath.row == -1) {
            attributes.zIndex = 1000;
        }
    }
    else if ([elementKind isEqualToString:kHorizontalLineDecorationViewKind]) {
        attributes.backgroundColor = [CalendarCellDecorationView gridColor];
        attributes.frame = [self frameForRowLine:indexPath];
        attributes.zIndex = 500;
        attributes.stickyX = YES;
        attributes.stickyY = (indexPath.section == 0 && indexPath.row == 0);
    }
    else if ([elementKind isEqualToString:kTimeFrameHorizontalLineDecorationViewKind]) {
        if (indexPath.section == -1 && indexPath.item == -1) {
            attributes.backgroundColor = [UIColor colorWithRed:1. green:.0 blue:.0 alpha:.75];
            attributes.zIndex = kHeadlineBackgroundDecorationViewZIndex - 1;
            NSDate *now = [NSDate date];
            self.calendar = [NSCalendar currentCalendar];
            NSDateComponents *todayComponents = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute
                                                                 fromDate:now];
            now = [[NSDate sb_calendar] dateFromComponents:todayComponents];
            NSTimeInterval startOffset = [self startOffsetForDate:now];
            attributes.frame = CGRectMake(self.timeframeWidth, self.headlineHeight + startOffset * self.minuteHeight, self.contentSize.width, 1);
        }
        else {
            attributes.backgroundColor = [CalendarCellDecorationView gridColor];
            attributes.zIndex = 950;
            attributes.frame = [self frameForRowTimeFrameLine:indexPath];
        }
        attributes.stickyX = YES;
        attributes.stickyY = (indexPath.section == 0 && indexPath.row == 0);
    }
    else if ([elementKind isEqualToString:kTimeFrameStepHorizontalLineDecorationViewKind]) {
        attributes.backgroundColor = [UIColor colorWithRed:0.909 green:0.901 blue:0.937 alpha:1.000];
        attributes.zIndex = 500;
        attributes.frame = [self frameForRowTimeStepFrameLine:indexPath];
        attributes.stickyX = YES;
    }
    else if ([elementKind isEqualToString:kBreakTimeBackgroundDecorationViewKind]) {
        NSAssert(NO, @"attributes for work hours breaks should be precalculated and stored into self.layoutAttributesForWorkHoursBreaks");
    }

    return [self correctAttributesGeometry:attributes];
}

- (nullable CalendarLayoutAttributes *)layoutAttributesForWorkhoursBreakDecorationViewAtIndexPath:(nonnull NSIndexPath *)indexPath
                                                                                       breakData:(nonnull SBDateRange *)breakData
{
    NSParameterAssert(indexPath != nil);
    NSParameterAssert(breakData != nil);
    CalendarLayoutAttributes *attributes = [CalendarLayoutAttributes layoutAttributesForDecorationViewOfKind:kBreakTimeBackgroundDecorationViewKind
                                                                                               withIndexPath:indexPath];
    attributes.backgroundColor = [UIColor colorWithWhite:.9 alpha:1];
    attributes.frame = [self frameForBreakTimeBlock:indexPath forBreakData:breakData];
    attributes.zIndex = 200;
    attributes.stickyX = NO;
    attributes.stickyY = NO;
    return attributes;
}

- (nullable CalendarLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(nonnull NSString *)elementKind
                                                                      atIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(elementKind != nil);
    NSParameterAssert(indexPath != nil);
    CalendarLayoutAttributes *attributes = [CalendarLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind
                                                                                                  withIndexPath:indexPath];
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) { // title of column
        attributes.frame = [self frameForPerformerHeaderRowAtIndexPath:indexPath];
        attributes.stickyY = YES;
        attributes.stickyX = NO;
        attributes.zIndex = 1000;
    }
    else if ([elementKind isEqualToString:kCalendarDataSourceTimeframeElementKind]) { // row title
        attributes.frame = [self frameForTimeframeSupplementaryAtIndexPath:indexPath];
        attributes.stickyY = NO;
        attributes.stickyX = YES;
        attributes.zIndex = 2001;
    }
    else if ([elementKind isEqualToString:kCalendarDataSourceGoogleBusyTimeElementKind]) {
        attributes.frame = [self frameForGoogleItemSupplementaryAtIndexPath:indexPath];
    }
    return [self correctAttributesGeometry:attributes];
}

- (nullable CalendarLayoutAttributes *)layoutAttributesForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    if (indexPath.section >= self.layoutAttributesForItems.count
        || indexPath.item >= self.layoutAttributesForItems[indexPath.section].count) {
        return nil;
    }
    CalendarLayoutAttributes *attributes = self.layoutAttributesForItems[indexPath.section][indexPath.item];

    NSObject<SBBookingProtocol> *booking = [self.dataSource bookingAtIndexPath:indexPath];
    if (!booking.isConfirmed.boolValue) {
//        attributes.zIndex--;
        // TODO: set alpha
    }

    return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    if (!CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size)) { // invalidate layout if orientation/screen size changed
        return YES;
    }
    else if (!CGPointEqualToPoint(self.collectionView.bounds.origin, newBounds.origin)) { // do not invalidate layout on scroll
        [self invalidateLayoutWithContext:[self invalidationContextForBoundsChange:newBounds]];
        return NO;
    }
    return NO;
}

#pragma mark - Geometry

- (NSTimeInterval)startOffsetForDate:(nonnull NSDate *)date
{
    NSParameterAssert(date != nil);
    return [self startOffsetForDate:date fromDate:self.dataSource.workingHoursMatrix.start];
}

- (NSTimeInterval)startOffsetForDate:(nonnull NSDate *)date fromDate:(nonnull NSDate *)startDate
{
    NSParameterAssert(date != nil);
    NSParameterAssert(startDate != nil);
    NSCalendar *calendar = [NSDate sb_calendar];
    NSDateComponents *c = [calendar components:NSCalendarUnitHour fromDate:startDate toDate:date options:0];
    NSTimeInterval bookingStartMins = c.hour * 60 + [calendar component:NSCalendarUnitMinute fromDate:date];
    return bookingStartMins;
}

- (nonnull CalendarLayoutAttributes *)correctAttributesGeometry:(nonnull CalendarLayoutAttributes *)attributes
{
    NSParameterAssert(attributes != nil);
    if (attributes.stickyX) {
        CGRect frame = attributes.frame;
        frame.origin.x += self.collectionView.contentOffset.x;
        attributes.frame = frame;
    }
    if (attributes.stickyY) {
        CGRect frame = attributes.frame;
        frame.origin.y += self.collectionView.contentOffset.y;
        attributes.frame = frame;
    }
    return attributes;
}

- (CGRect)frameForPerformerHeaderRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    NSNumber *value = self.columns[indexPath.section];
    return CGRectMake(value.floatValue + self.timeframeWidth + 2,
                      3,
                      self.columnWidth - 4, // 2/4 pixel ajustment for culumn line
                      self.headlineHeight - 3);
}

- (CGRect)frameForTimeframeSupplementaryAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    return CGRectMake(self.timeframeItemInsets.left,
                      indexPath.row * self.cellSize.height - self.cellSize.height / 2. + self.headlineHeight + self.contentInsets.top + self.timeframeItemInsets.top,
                      self.timeframeWidth - self.timeframeItemInsets.left - self.timeframeItemInsets.right,
                      self.cellSize.height - 1);
}

- (CGRect)frameForGoogleItemSupplementaryAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    if (indexPath.section >= self.dataSource.sections.count
        || indexPath.item >= self.dataSource.googleCalendarBusyTime[self.dataSource.sections[indexPath.section].sectionID].count) {
        return CGRectZero;
    }
    NSObject *sectionID = self.dataSource.sections[indexPath.section].sectionID;
    NSDictionary <NSString *, NSDate *> *data = self.dataSource.googleCalendarBusyTime[sectionID][indexPath.item];
    NSTimeInterval startOffset = [self startOffsetForDate:data[@"from"]];
    NSTimeInterval duration = (data[@"to"].timeIntervalSince1970 - data[@"from"].timeIntervalSince1970) / 60.;
    NSNumber *value = self.columns[indexPath.section];
    return CGRectMake(value.floatValue + self.timeframeWidth + 2, self.headlineHeight + startOffset * self.minuteHeight,
                      self.columnWidth - 4, duration * self.minuteHeight);
}

- (CGRect)frameForColumnLine:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    NSNumber *value = self.columns[indexPath.section];
    return CGRectMake(value.floatValue + self.timeframeWidth,
                      0,
                      1,
                      (indexPath.row == -1 ? self.headlineHeight : self.contentSize.height));
}

- (CGRect)frameForRowLine:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    return CGRectMake(0,
                      indexPath.row * self.cellSize.height + self.headlineHeight + self.contentInsets.top,
                      self.contentSize.width,
                      1);
}

- (CGRect)frameForRowTimeFrameLine:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    return CGRectMake(self.timeframeWidth,
            indexPath.row * self.cellSize.height + self.headlineHeight + self.contentInsets.top,
            self.timeframeWidth,
            1);
}

- (CGRect)frameForRowTimeStepFrameLine:(nonnull NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath != nil);
    return CGRectMake(self.timeframeWidth,
            indexPath.row * self.minuteHeight * self.dataSource.timeframeStep + self.headlineHeight + self.contentInsets.top,
            self.contentSize.width,
            1);
}

- (CGRect)frameForBreakTimeBlock:(nonnull NSIndexPath *)indexPath forBreakData:(nonnull SBDateRange *)breakData
{
    NSParameterAssert(indexPath != nil);
    NSParameterAssert(breakData != nil);
    NSNumber *value = self.columns[indexPath.section];
    NSTimeInterval startOffset = [self startOffsetForDate:breakData.start];
    NSTimeInterval duration = (breakData.end.timeIntervalSince1970 - breakData.start.timeIntervalSince1970) / 60.;
    CGFloat heightCorrection = 0;
    if (breakData.start.timeIntervalSince1970 + duration * 60. > self.dataSource.workingHoursMatrix.end.timeIntervalSince1970) {
        heightCorrection = 1000;
    }

    return CGRectMake(value.floatValue + self.timeframeWidth - (indexPath.section == 0 ? 1000 : 0),
            self.headlineHeight + startOffset * self.minuteHeight - (startOffset == 0 ? 1000 : 0),
            self.columnWidth + (indexPath.section == self.dataSource.sections.count-1 || indexPath.section == 0 ? 1000 : 0),
            duration * self.minuteHeight + (startOffset == 0 ? 1000 : 0) + heightCorrection);
}

@end
