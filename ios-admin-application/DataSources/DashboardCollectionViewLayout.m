//
//  DashboardCollectionViewLayout.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardCollectionViewLayout.h"
#import "CalendarLayoutAttributes.h"
#import "CalendarCellDecorationView.h"
#import "DashboardAbstractWidgetDataSource.h"
#import "UIColor+SimplyBookColors.h"


NSString * const kDashboardWidgetBackgroundDecorationViewKind = @"kDashboardWidgetBackgroundDecorationViewKind";
NSString * const kDashboardWidgetSeparatorDecorationViewKind = @"kDashboardWidgetSeparatorDecorationViewKind";

@interface DashboardWidgetLayoutParametrs : NSObject

@property (nonatomic) CGRect frame;
@property (nonatomic) CGRect headerFrame;
@property (nonatomic) UIEdgeInsets itemInsets;
@property (nonatomic) DashboardCollectionViewLayoutSectionDirection direction;
@property (nonatomic, strong) NSArray *items;

@end

@interface DashboardCollectionViewLayout ()

@property (nonatomic) CGFloat minSectionHeight;
@property (nonatomic) UIEdgeInsets sectionInsets;
@property (nonatomic, strong) NSMutableArray *sectionsLayout;
@property (nonatomic) CGSize contentSize;
@property (nonatomic) UIEdgeInsets horizontalItemInsets;
@property (nonatomic) UIEdgeInsets verticalItemInsets;

@end

@implementation DashboardCollectionViewLayout

+ (Class)layoutAttributesClass
{
    return [CalendarLayoutAttributes class];
}

- (CGSize)collectionViewContentSize
{
    return self.contentSize;
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

- (void)prepareLayout
{
    self.minSectionHeight = 80.;
    self.sectionInsets = UIEdgeInsetsMake(5, 10, 10, 10);
    self.sectionsLayout = [NSMutableArray array];
    self.horizontalItemInsets = UIEdgeInsetsMake(20, 0, 20, 0);
    self.verticalItemInsets = UIEdgeInsetsZero;

    
    CGFloat widgetY = 0, widgetX = 0, rowHeight = 0;
    NSUInteger column = 1;
    for (NSUInteger section = 0; section < [self.dataSource numberOfSectionsInCollectionView:self.collectionView]; section++) {
        CGFloat headerHeight = [self.delegate dashboardViewLayout:self heightForSupplementaryViewOfKind:UICollectionElementKindSectionHeader inSection:section];
        CGSize headerViewSize = CGSizeMake(0, headerHeight);
        CGFloat sectionWidth = self.collectionView.frame.size.width - self.sectionInsets.left - self.sectionInsets.right;
        NSMutableArray *items = [NSMutableArray array];
        
        DashboardCollectionViewLayoutWidgetLayout widgetLayout = [self.delegate dashboardViewLayout:self widgetLayoutForSection:section];
        if (widgetLayout == DashboardCollectionViewLayoutHalfWidthWidgetLayout) {
            sectionWidth = (self.collectionView.frame.size.width - self.sectionInsets.left * 2 - self.sectionInsets.right) / 2.;
        }
        
        DashboardCollectionViewLayoutSectionDirection direction = [self.delegate dashboardViewLayout:self directionForSection:section];
        NSUInteger numberOfItems = [self.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
        CGFloat itemHeight = 0;
        if (numberOfItems > 0 ) {
            CGFloat itemX = 0, itemY = 0;
            for (NSInteger item = 0; item < numberOfItems; item++) {
                NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
                CGRect itemFrame = CGRectZero;
                if (direction == DashboardCollectionViewLayoutVerticalSectionDirection) {
                    itemFrame.origin.x = 0;
                    itemFrame.origin.y = itemY;
                    itemFrame.size.width = sectionWidth;
                    itemFrame.size.height = [self.delegate dashboardViewLayout:self
                                         heightForCellForItemAtIndexPath:itemIndexPath
                                                                maxWidth:itemFrame.size.width];
                    itemHeight += itemFrame.size.height;
                }
                else {
                    itemFrame.origin.x = itemX;
                    itemFrame.origin.y = 0;
                    itemFrame.size.width = sectionWidth / numberOfItems;
                    itemFrame.size.height = [self.delegate dashboardViewLayout:self
                                         heightForCellForItemAtIndexPath:itemIndexPath
                                                                maxWidth:itemFrame.size.width];
                    itemHeight = MAX(itemHeight, itemFrame.size.height);
                }
                itemX += itemFrame.size.width;
                itemY += itemFrame.size.height;
                [items addObject:[NSValue valueWithCGRect:itemFrame]];
            }
        }
        CGFloat sectionHeight = MAX(self.minSectionHeight, itemHeight);
        if (direction == DashboardCollectionViewLayoutVerticalSectionDirection) {
            sectionHeight = MAX(sectionHeight, itemHeight);
        }
        
        DashboardWidgetLayoutParametrs *widgetLayoutParamets = [DashboardWidgetLayoutParametrs new];
        widgetLayoutParamets.frame = CGRectMake(widgetX + self.sectionInsets.left,
                                                widgetY + self.sectionInsets.top,
                                                sectionWidth,
                                                headerViewSize.height + sectionHeight);
        widgetLayoutParamets.headerFrame = CGRectMake(0, 0, widgetLayoutParamets.frame.size.width, headerViewSize.height);
        widgetLayoutParamets.items = items;
        
        widgetLayoutParamets.direction = direction;
        if (widgetLayoutParamets.direction == DashboardCollectionViewLayoutVerticalSectionDirection) {
            widgetLayoutParamets.itemInsets = self.verticalItemInsets;
        }
        else {
            widgetLayoutParamets.itemInsets = self.horizontalItemInsets;
        }
        
        [self.sectionsLayout addObject:widgetLayoutParamets];
        
        rowHeight = MAX(rowHeight, widgetLayoutParamets.frame.size.height);
        
        if (widgetLayout == DashboardCollectionViewLayoutFullWidthWidgetLayout
            || (widgetLayout == DashboardCollectionViewLayoutHalfWidthWidgetLayout && column == 2))
        {
            widgetY = widgetLayoutParamets.frame.origin.y + rowHeight + self.sectionInsets.bottom;
            widgetX = 0;
            column = 1;
            rowHeight = 0;
        }
        else {
            if (column == 1) {
                widgetX = widgetLayoutParamets.frame.origin.x + widgetLayoutParamets.frame.size.width;
            }
            column++;
        }
    }
    self.contentSize = CGSizeMake(self.collectionView.frame.size.width, widgetY);
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *attributes = [NSMutableArray array];
    
    for (NSUInteger section = 0; section < [self.dataSource numberOfSectionsInCollectionView:self.collectionView]; section++) {
        NSIndexPath *sectionIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        
        UICollectionViewLayoutAttributes *sectionHeaderAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                         atIndexPath:sectionIndexPath];
        [attributes addObject:sectionHeaderAttributes];
        
        UICollectionViewLayoutAttributes *sectionBackgroundAttributes = [self layoutAttributesForDecorationViewOfKind:kDashboardWidgetBackgroundDecorationViewKind
                                                                                                          atIndexPath:sectionIndexPath];
        [attributes addObject:sectionBackgroundAttributes];
        
        if ([self.delegate dashboardViewLayout:self shouldDisplayErrorMessageInSection:section]) {
            UICollectionViewLayoutAttributes *errorMessageAttributes = [self layoutAttributesForSupplementaryViewOfKind:kDashboardErrorMessageSupplementaryKind
                                                                                                            atIndexPath:sectionIndexPath];
            [attributes addObject:errorMessageAttributes];
        }
        
        if ([self.delegate dashboardViewLayout:self shouldDisplayActivityIndicatorInSection:section]) {
            UICollectionViewLayoutAttributes *activityIndicatorAttributes = [self layoutAttributesForSupplementaryViewOfKind:kDashboardLoadingIndicatorSupplementaryKind
                                                                                                                 atIndexPath:sectionIndexPath];
            [attributes addObject:activityIndicatorAttributes];
        }
        
        NSUInteger numberOfItems = [[self.sectionsLayout[section] items] count];
        for (NSUInteger item = 0; item < numberOfItems; item++) {
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *itemAttributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
            [attributes addObject:itemAttributes];
            
            if (item) {
                UICollectionViewLayoutAttributes *separatorAttributes = [self layoutAttributesForDecorationViewOfKind:kDashboardWidgetSeparatorDecorationViewKind
                                                                                                          atIndexPath:itemIndexPath];
                [attributes addObject:separatorAttributes];
            }
        }
    }
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind
                                                                                                                  withIndexPath:indexPath];
    DashboardWidgetLayoutParametrs *sectionLayout = self.sectionsLayout[indexPath.section];
    
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        attributes.frame = CGRectMake(sectionLayout.frame.origin.x + sectionLayout.headerFrame.origin.x,
                                      sectionLayout.frame.origin.y + sectionLayout.headerFrame.origin.y,
                                      sectionLayout.headerFrame.size.width,
                                      sectionLayout.headerFrame.size.height);
        attributes.zIndex = 1000;
    }
    else if ([elementKind isEqualToString:kDashboardLoadingIndicatorSupplementaryKind]
             || [elementKind isEqualToString:kDashboardErrorMessageSupplementaryKind])
    {
        attributes.frame = CGRectMake(sectionLayout.frame.origin.x + sectionLayout.headerFrame.origin.x,
                                      sectionLayout.frame.origin.y + sectionLayout.headerFrame.origin.y + sectionLayout.headerFrame.size.height,
                                      sectionLayout.frame.size.width,
                                      sectionLayout.frame.size.height - sectionLayout.headerFrame.size.height);
        attributes.zIndex = 950;
        if ([elementKind isEqualToString:kDashboardErrorMessageSupplementaryKind]) {
            attributes.alpha = ([self.delegate dashboardViewLayout:self shouldDisplayErrorMessageInSection:indexPath.section] ? 1 : 0);
        }
        else if ([elementKind isEqualToString:kDashboardLoadingIndicatorSupplementaryKind]) {
            attributes.alpha = ([self.delegate dashboardViewLayout:self shouldDisplayActivityIndicatorInSection:indexPath.section] ? 1 : 0);
        }
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    CalendarLayoutAttributes *attributes = [CalendarLayoutAttributes layoutAttributesForDecorationViewOfKind:elementKind
                                                                                               withIndexPath:indexPath];
    DashboardWidgetLayoutParametrs *sectionLayout = self.sectionsLayout[indexPath.section];
    if ([elementKind isEqualToString:kDashboardWidgetBackgroundDecorationViewKind]) {
        attributes.frame = sectionLayout.frame;
        attributes.backgroundColor = [UIColor whiteColor];
        attributes.zIndex = 100;
        attributes.cornerRadius = 5;
    }
    else if ([elementKind isEqualToString:kDashboardWidgetSeparatorDecorationViewKind]) {
        if (indexPath.item >= sectionLayout.items.count) {
            if (sectionLayout.direction == DashboardCollectionViewLayoutHorizontalSectionDirection) {
                CGRect frame = CGRectMake(sectionLayout.frame.origin.x,
                                          sectionLayout.frame.origin.y + sectionLayout.headerFrame.size.height,
                                          1,
                                          0);
                attributes.frame = UIEdgeInsetsInsetRect(frame, sectionLayout.itemInsets);
            }
            else {
                CGRect frame = CGRectMake(sectionLayout.frame.origin.x,
                                          sectionLayout.frame.origin.y + sectionLayout.headerFrame.size.height,
                                          sectionLayout.frame.size.width,
                                          0);
                attributes.frame = UIEdgeInsetsInsetRect(frame, sectionLayout.itemInsets);
            }
            attributes.alpha = 0;
        }
        else {
            CGRect itemFrame = [sectionLayout.items[indexPath.item] CGRectValue];
            if (sectionLayout.direction == DashboardCollectionViewLayoutHorizontalSectionDirection) {
                CGRect frame = CGRectMake(sectionLayout.frame.origin.x + itemFrame.origin.x,
                                          sectionLayout.frame.origin.y + sectionLayout.headerFrame.size.height,
                                          1,
                                          itemFrame.size.height);
                attributes.frame = UIEdgeInsetsInsetRect(frame, sectionLayout.itemInsets);
            }
            else {
                CGRect frame = CGRectMake(sectionLayout.frame.origin.x,
                                          sectionLayout.frame.origin.y + sectionLayout.headerFrame.size.height + itemFrame.origin.y,
                                          itemFrame.size.width,
                                          1);
                attributes.frame = UIEdgeInsetsInsetRect(frame, sectionLayout.itemInsets);
            }
            attributes.alpha = 1;
        }
        attributes.backgroundColor = [UIColor sb_gridColor];
        attributes.zIndex = 1000;
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    DashboardWidgetLayoutParametrs *sectionLayout = self.sectionsLayout[indexPath.section];
    NSAssert(indexPath.item < sectionLayout.items.count, @"not existed item");
    CGRect itemFrame = [sectionLayout.items[indexPath.item] CGRectValue];
    CGRect frame = CGRectMake(sectionLayout.frame.origin.x + itemFrame.origin.x,
                              sectionLayout.frame.origin.y + sectionLayout.headerFrame.size.height + itemFrame.origin.y,
                              itemFrame.size.width,
                              itemFrame.size.height);
    attributes.frame = UIEdgeInsetsInsetRect(frame, sectionLayout.itemInsets);
    attributes.zIndex = 1000;
    return attributes;
}

@end

#pragma mark -

@implementation DashboardWidgetLayoutParametrs

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ {frame: %@, header: %@}", NSStringFromClass([self class]), NSStringFromCGRect(self.frame), NSStringFromCGRect(self.headerFrame)];
}

@end
