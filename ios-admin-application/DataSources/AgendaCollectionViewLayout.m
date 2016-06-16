//
//  AgendaCollectionViewLayout.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "AgendaCollectionViewLayout.h"
#import "AgendaDataSource.h"
//#import "CalendarCellDecorationView.h"

NSString * const kAgendaHeaderSupplementaryElementKind = @"kAgendaHeaderSupplementaryElementKind";
NSString * const kAgendaNoDataSupplementaryElementKind = @"kAgendaNoDataSupplementaryElementKind";
NSString * const kAgendaSubheaderSupplementaryElementKind = @"kAgendaSubheaderSupplementaryElementKind";
NSString * const kAgendaNoConnectionSupplementaryElementKind = @"kAgendaNoConnectionSupplementaryElementKind";

static const CGFloat kAgendaNoConnectionMessageHeight = 40;

@interface AgendaCollectionViewLayout ()
{
    CGSize itemSize;
    CGSize headerSize;
    CGSize subheaderSize;
    CGFloat columns;
    CGSize contentSize;
    NSMutableDictionary <NSIndexPath *, NSValue *> *itemRects;
    NSMutableArray <NSValue *> *headerRects;
}

@property (nonatomic, weak) AgendaDataSource *dataSource;

@end

@implementation AgendaCollectionViewLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        itemSize = CGSizeZero;
    }
    return self;
}

- (void)setNoConnection:(BOOL)noConnection
{
    _noConnection = noConnection;
    [self invalidateLayout];
}

- (AgendaDataSource *)dataSource
{
    return (AgendaDataSource *)self.collectionView.dataSource;
}

- (CGSize)collectionViewContentSize
{
    return contentSize;
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
    CGFloat minWidth = 256;
    columns = MAX(floor(self.collectionView.frame.size.width / minWidth), 1);
    CGFloat columnWidth = self.collectionView.frame.size.width / columns;
    itemSize = CGSizeMake(self.collectionView.frame.size.width / columns, 50);
    headerSize = CGSizeMake(self.collectionView.frame.size.width, 30);
    subheaderSize = CGSizeMake(self.collectionView.frame.size.width, 25);
    itemRects = [NSMutableDictionary dictionary];
    headerRects = [NSMutableArray array];
    
    NSInteger sections = [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
    CGRect itemRect = CGRectMake(0, 0, itemSize.width, itemSize.height);
    CGRect headerRect = CGRectMake(0, 0, headerSize.width, headerSize.height);
    CGFloat dy = 0, dx = 0;
    UIEdgeInsets itemInsets = UIEdgeInsetsMake(0, 5, 0, 0);
    for (NSInteger section = 0; section < sections; section++) {
        
        [headerRects addObject:[NSValue valueWithCGRect:CGRectOffset(headerRect, 0, dy)]];
        dy += headerSize.height + 3;
        
        NSInteger items = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
        for (NSInteger item = 0; item < items; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            CGRect rect = UIEdgeInsetsInsetRect(CGRectOffset(itemRect, dx, dy), itemInsets);
            itemRects[indexPath] = [NSValue valueWithCGRect:rect];
            if (item % (NSInteger)columns == columns - 1 || item == items - 1) {
                dx = 0;
                dy += itemSize.height + 3;
            } else {
                dx += columnWidth;
            }
        }
        if (items == 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            itemRects[indexPath] = [NSValue valueWithCGRect:CGRectMake(0, dy, self.collectionView.frame.size.width, itemSize.height)];
            dy += itemSize.height;
        }
    }
    contentSize = CGSizeMake(self.collectionView.frame.size.width, dy + (self.noConnection ? kAgendaNoConnectionMessageHeight : 0));
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray <UICollectionViewLayoutAttributes *> *attributes = [NSMutableArray array];
    NSInteger sections = [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
    if (self.noConnection) {
        UICollectionViewLayoutAttributes *headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:kAgendaNoConnectionSupplementaryElementKind
                                                                                                  atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        [attributes addObject:headerAttributes];
    }
    for (NSInteger section = 0; section < sections; section++) {
        
        UICollectionViewLayoutAttributes *headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:kAgendaHeaderSupplementaryElementKind
                                                                                                  atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
        [attributes addObject:headerAttributes];
        
        NSInteger items = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
        for (NSInteger item = 0; item < items; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
        }
        if (items == 0) {
            [attributes addObject:[self layoutAttributesForSupplementaryViewOfKind:kAgendaNoDataSupplementaryElementKind
                                                                       atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]]];
        }
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.frame = [itemRects[indexPath] CGRectValue];
    if (self.noConnection) {
        attributes.frame = CGRectOffset(attributes.frame, 0, kAgendaNoConnectionMessageHeight);
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind
                                                                                                                  withIndexPath:indexPath];
    if ([elementKind isEqualToString:kAgendaHeaderSupplementaryElementKind]) {
        attributes.frame = [headerRects[indexPath.section] CGRectValue];
        attributes.zIndex = 100;
        if (self.collectionView.contentOffset.y > attributes.frame.origin.y) {
            if (indexPath.section + 1 >= headerRects.count) {
                attributes.frame = CGRectOffset(attributes.frame, 0, self.collectionView.contentOffset.y - attributes.frame.origin.y);
            }
            else {
                CGRect nextSection = [headerRects[indexPath.section + 1] CGRectValue];
                if (self.collectionView.contentOffset.y + attributes.frame.size.height < nextSection.origin.y) {
                    attributes.frame = CGRectOffset(attributes.frame, 0, self.collectionView.contentOffset.y - attributes.frame.origin.y);
                }
                else {
                    CGRect frame = attributes.frame;
                    frame.origin.y = nextSection.origin.y - attributes.frame.size.height;
                    attributes.frame = frame;
                }
            }
        }
    }
    else if ([elementKind isEqualToString:kAgendaNoDataSupplementaryElementKind]) {
        attributes.frame = [itemRects[indexPath] CGRectValue];
    }
    else if ([elementKind isEqualToString:kAgendaNoConnectionSupplementaryElementKind]) {
        attributes.frame = CGRectMake(0, self.collectionView.contentOffset.y, self.collectionView.frame.size.width, kAgendaNoConnectionMessageHeight);
        attributes.zIndex = 200;
    }
    if (self.noConnection && ![elementKind isEqualToString:kAgendaNoConnectionSupplementaryElementKind]) {
        attributes.frame = CGRectOffset(attributes.frame, 0, kAgendaNoConnectionMessageHeight);
    }
    return attributes;
}

@end
