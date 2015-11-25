//
//  PendingBookingsCollectionViewLayout.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "PendingBookingsCollectionViewLayout.h"
#import "CalendarLayoutAttributes.h"
#import "UIColor+SimplyBookColors.h"
#import "CalendarCellDecorationView.h"

NSString * _Nonnull const kPendingBookingsHorizontalListDecorationViewKind = @"kPendingBookingsHorizontalListDecorationViewKind";
NSString * _Nonnull const kPendingBookingsVerticalListDecorationViewKind = @"kPendingBookingsVerticalListDecorationViewKind";

@implementation PendingBookingsCollectionViewLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kPendingBookingsHorizontalListDecorationViewKind];
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kPendingBookingsVerticalListDecorationViewKind];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kPendingBookingsHorizontalListDecorationViewKind];
        [self registerClass:[CalendarCellDecorationView class] forDecorationViewOfKind:kPendingBookingsVerticalListDecorationViewKind];
    }
    return self;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    if (self.pendingBookingsDataSource) {
        NSMutableArray<UICollectionViewLayoutAttributes *> *attributes = [NSMutableArray arrayWithArray:[super layoutAttributesForElementsInRect:rect]];
        for (NSInteger section = 0; section < [self.pendingBookingsDataSource numberOfSectionsInCollectionView:self.collectionView]; section++) {
            for (NSInteger item = 0; item < [self.pendingBookingsDataSource collectionView:self.collectionView numberOfItemsInSection:section]; item++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                UICollectionViewLayoutAttributes *itemAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
                if (!itemAttributes) {
                    continue;
                }
                if (item % 2 == 0) {
                    CalendarLayoutAttributes *verticalLine = [CalendarLayoutAttributes layoutAttributesForDecorationViewOfKind:kPendingBookingsVerticalListDecorationViewKind
                                                                                                                 withIndexPath:indexPath];
                    verticalLine.frame = CGRectMake(CGRectGetMaxX(itemAttributes.frame), CGRectGetMinY(itemAttributes.frame),
                                                    1, CGRectGetHeight(itemAttributes.frame));
                    verticalLine.backgroundColor = [UIColor sb_gridColor];
                    [attributes addObject:verticalLine];
                }
                CalendarLayoutAttributes *horizontalLine = [CalendarLayoutAttributes layoutAttributesForDecorationViewOfKind:kPendingBookingsHorizontalListDecorationViewKind
                                                                                                               withIndexPath:indexPath];
                horizontalLine.frame = CGRectMake(CGRectGetMinX(itemAttributes.frame), CGRectGetMaxY(itemAttributes.frame),
                                                  CGRectGetWidth(itemAttributes.frame), 1);
                horizontalLine.backgroundColor = [UIColor sb_gridColor];
                [attributes addObject:horizontalLine];
            }
        }
        return attributes;
    }
    else {
        return [super layoutAttributesForElementsInRect:rect];
    }
}

@end
