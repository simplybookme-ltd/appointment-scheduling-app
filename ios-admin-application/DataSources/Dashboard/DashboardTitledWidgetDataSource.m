//
//  DashboardTitledWidgetDataSource.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "DashboardTitledWidgetDataSource.h"
#import "TitledWidgetHeaderCollectionReusableView.h"
#import "SBRequest.h"

NSString * const kDashboardTitledWidgetHeaderSupplementaryKind = @"kDashboardTitledWidgetHeaderSupplementaryKind";
NSString * const kDashboardTitledWidgetHeaderSupplementaryReuseIdentifier = @"kDashboardTitledWidgetHeaderSupplementaryReuseIdentifier";

@implementation DashboardTitledWidgetDataSource

- (UINib *)nibForViewForSupplementaryElementOfKind:(NSString *_Nonnull)kind
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [UINib nibWithNibName:@"TitledWidgetHeaderCollectionReusableView" bundle:nil];
    }
    return nil;
}

- (void)configureReusableViewsForCollectionView:(UICollectionView *)collectionView
{
    [collectionView registerNib:[self nibForViewForSupplementaryElementOfKind:UICollectionElementKindSectionHeader]
     forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
            withReuseIdentifier:kDashboardTitledWidgetHeaderSupplementaryReuseIdentifier];
}

- (UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UINib *nib = [self nibForViewForSupplementaryElementOfKind:kind];
        return [[nib instantiateWithOwner:self options:nil] firstObject];
    }
    return [super viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

- (NSString *)reusableIdentifierForSupplementaryViewOnKind:(NSString *)kind
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return kDashboardTitledWidgetHeaderSupplementaryReuseIdentifier;
    }
    return [super reusableIdentifierForSupplementaryViewOnKind:kind];
}

- (void)configureView:(TitledWidgetHeaderCollectionReusableView *)view forSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        view.backgroundColor = self.color;
        view.titleLabel.text = self.title;
        [view setTitle:self.title subtitle:self.subtitle];
    }
    else {
        [super configureView:view forSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

- (SBRequest *)dataLoadingRequest
{
    return nil;
}

@end
