//
//  DashboardAbstractWidgetDataSource.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

@import UIKit;
#import <Foundation/Foundation.h>
#import "SBResponse.h"
#import "DashboardWidgetUpdateStrategy.h"

extern NSString * _Nonnull const kDashboardLoadingIndicatorSupplementaryKind;
extern NSString * _Nonnull const kDashboardLoadingIndicatorSupplementaryReuseIdentifier;
extern NSString * _Nonnull const kDashboardErrorMessageSupplementaryKind;
extern NSString * _Nonnull const kDashboardErrorMessageSupplementaryReuseIdentifier;

@class DashboardAbstractWidgetDataSource;

@protocol DashboardAbstractWidgetDataSourceDelegate <NSObject>

- (void)dashboardWidgetDidStartDataLoading:(DashboardAbstractWidgetDataSource * _Nonnull)widget;

@optional
/**
 * because we need to synchronize data state and collection view layout updates widget will apply loaded data
 * by delegate's request
 * flow:
 * widget did load data -> 
 *      -> widget notifies delegate that data loaded ->
 *      -> delegate calls [widget applyDataFromResponse:] to synch widget state and layout
 */
- (void)dashboardWidget:(DashboardAbstractWidgetDataSource * _Nonnull)widget didFinishDataLoadingWithResponse:(SBResponse * _Nonnull)response;

- (void)dashboardWidgetDidStartDataReloading:(DashboardAbstractWidgetDataSource * _Nonnull)widget;
- (void)dashboardWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget didRemoveItemsWithIndexes:(NSIndexSet * _Nonnull)indexes;
- (void)dashboardWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget didInsertItemsWithIndexes:(NSIndexSet * _Nonnull)indexes;
- (void)dashboardWidget:(DashboardAbstractWidgetDataSource *_Nonnull)widget didRefreshItemsAtIndexes:(NSIndexSet * _Nonnull)indexes;
- (void)dashboardWidgetDidRefreshWidgetData:(DashboardAbstractWidgetDataSource * _Nonnull)widget;

@end

@interface DashboardAbstractWidgetDataSource : NSObject

@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) UIColor *color;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;
@property (nonatomic, readonly, getter=isDataLoaded) BOOL dataLoaded;
@property (nonatomic, readonly, getter=isDataEmpty) BOOL dataEmpty;
@property (nonatomic, strong, readonly, nullable) NSError *error;
@property (nonatomic, weak, nullable) NSObject<DashboardAbstractWidgetDataSourceDelegate> *delegate;
@property (nonatomic) CGFloat preferredWidgetHeight;
@property (nonatomic, strong, nullable) DashboardWidgetUpdateStrategy *dataUpdateStrategy;

- (UINib * _Nonnull)nibForViewForSupplementaryElementOfKind:(NSString * _Nonnull)kind;
- (UINib * _Nonnull)nibForItemCellWithReuseIdentifier:(NSString * _Nonnull)reuseIdentifier;
- (void)configureReusableViewsForCollectionView:(UICollectionView * _Nonnull)collectionView;
- (NSString * _Nonnull)reusableIdentifierForSupplementaryViewOnKind:(NSString * _Nonnull)kind;
- (NSString * _Nonnull)reusableIdentifierForItemAtIndexPath:(NSIndexPath * _Nonnull)indexPath;
- (UICollectionReusableView * _Nonnull)viewForSupplementaryElementOfKind:(NSString * _Nonnull)kind atIndexPath:(NSIndexPath * _Nullable)indexPath;
- (void)configureView:(UICollectionReusableView * _Nonnull)view forSupplementaryElementOfKind:(NSString * _Nonnull)kind atIndexPath:(NSIndexPath * _Nullable)indexPath;
- (void)configureCell:(UICollectionViewCell * _Nonnull)cell forItemAtIndexPath:(NSIndexPath * _Nullable)indexPath;

- (void)loadData;
- (NSUInteger)numberOfItems;
- (id _Nullable)itemAtIndexPath:(NSIndexPath * _Nonnull)indexPath;

@end
